import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../models/piar_models.dart';
import '../repositories/repository_provider.dart';

/// Resultado de intentar crear/activar una inscripción PIAR — evita tener
/// que lanzar excepciones para un caso de negocio esperado (ya existe una
/// inscripción activa) que la pantalla necesita mostrar como mensaje, no
/// como error inesperado.
enum PiarAccionResultado { ok, yaExisteInscripcionActiva, noElegible }

/// Agrupación de [PiarValoracion] a 3 niveles para la matriz de decisión
/// (ver [sugerirDecisionAjuste]) — el modelo de datos guarda la valoración
/// completa de 4 valores, pero la matriz que precarga la decisión cruza
/// solo 3x3 (aplicación x nivel de logro), como se acordó en el plan de la
/// Fase 7.
enum _NivelLogro { logrado, enProceso, sinAvance }

_NivelLogro _nivelDeLogro(PiarValoracion v) => switch (v) {
  PiarValoracion.logradoAutonomia || PiarValoracion.logradoConApoyo =>
    _NivelLogro.logrado,
  PiarValoracion.enProceso => _NivelLogro.enProceso,
  PiarValoracion.sinAvance => _NivelLogro.sinAvance,
};

/// Matriz de decisión 3x3 (aplicación x nivel de logro) que precarga
/// [PiarSeguimiento.decisionAjuste] — el docente siempre puede cambiarla
/// antes de guardar, esto es solo una sugerencia inicial:
///
/// |              | Logrado   | En proceso | Sin avance |
/// |--------------|-----------|------------|------------|
/// | Completo     | Mantener  | Mantener   | Modificar  |
/// | Parcial      | Mantener  | Modificar  | Modificar  |
/// | No aplicado  | Escalar   | Escalar    | Escalar    |
///
/// Si el ajuste no se pudo aplicar, la valoración de ese período no es
/// confiable (no se probó de verdad) — siempre se sugiere escalar a
/// coordinación en vez de interpretar el resultado.
PiarDecisionAjuste sugerirDecisionAjuste(
  PiarAplicacion aplicacion,
  PiarValoracion valoracion,
) {
  if (aplicacion == PiarAplicacion.noAplicado) return PiarDecisionAjuste.escalar;
  final nivel = _nivelDeLogro(valoracion);
  if (nivel == _NivelLogro.logrado) return PiarDecisionAjuste.mantener;
  if (aplicacion == PiarAplicacion.completo && nivel == _NivelLogro.enProceso) {
    return PiarDecisionAjuste.mantener;
  }
  return PiarDecisionAjuste.modificar;
}

/// Una competencia ya registrada (Standard) en una asignatura de la carga
/// académica del estudiante, para la que se debe crear la tarea pendiente
/// de ajuste al activar la inscripción. Lo resuelve la pantalla (que tiene
/// acceso a AcademicProvider) y lo entrega ya armado — PiarProvider no
/// depende de AcademicProvider, solo persiste y notifica.
typedef PiarCompetenciaPendiente = ({
  String subjectId,
  String standardId,
  String competenciaTextoOriginal,
  String docenteResponsableId, // Teacher.id
});

/// Un docente de la carga académica del curso, con su uid de Firebase Auth
/// (para autorizarlo a ver el perfil de apoyo y para notificarlo).
typedef PiarDocenteCarga = ({String teacherId, String userId});

class PiarProvider extends ChangeNotifier {
  final _store = dataRepository;

  List<PiarInscripcion> _inscripciones = [];
  List<PiarSoporteExterno> _soportesExternos = [];
  List<PiarPerfilApoyo> _perfilesApoyo = [];
  List<PiarCatalogoApoyo> _catalogoApoyos = [];
  List<PiarAjuste> _ajustes = [];
  List<PiarSeguimiento> _seguimientos = [];
  List<PiarActaAcuerdo> _actasAcuerdo = [];
  List<PiarDiagnosticoFinal> _diagnosticosFinales = [];
  List<PiarAlerta> _alertas = [];
  /// Solo para resolver a qué uids notificar en las alertas automáticas
  /// (Fase 8) — coordinadores/admin. No se expone fuera del provider.
  List<AppUser> _users = [];

  final List<StreamSubscription> _subs = [];

  PiarProvider() {
    _subs.addAll([
      _store.piarInscripcionesStream().listen((v) {
        _inscripciones = v;
        notifyListeners();
        _revisarAlertasAutomaticas();
      }),
      _store.piarSoportesExternosStream().listen((v) {
        _soportesExternos = v;
        notifyListeners();
        _revisarAlertasAutomaticas();
      }),
      _store.piarPerfilesApoyoStream().listen((v) {
        _perfilesApoyo = v;
        notifyListeners();
      }),
      _store.piarCatalogoApoyosStream().listen((v) {
        _catalogoApoyos = v;
        notifyListeners();
      }),
      _store.piarAjustesStream().listen((v) {
        _ajustes = v;
        notifyListeners();
        _revisarAlertasAutomaticas();
      }),
      _store.piarSeguimientosStream().listen((v) {
        _seguimientos = v;
        notifyListeners();
      }),
      _store.piarActasAcuerdoStream().listen((v) {
        _actasAcuerdo = v;
        notifyListeners();
        _revisarAlertasAutomaticas();
      }),
      _store.piarDiagnosticosFinalesStream().listen((v) {
        _diagnosticosFinales = v;
        notifyListeners();
      }),
      _store.piarAlertasStream().listen((v) {
        _alertas = v;
        notifyListeners();
      }),
      _store.usersStream().listen((v) {
        _users = v;
        _revisarAlertasAutomaticas();
      }),
    ]);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  // ── Getters ────────────────────────────────────────────────────────────

  List<PiarInscripcion> get inscripciones => _inscripciones;
  List<PiarCatalogoApoyo> get catalogoApoyos =>
      _catalogoApoyos.where((a) => a.activo).toList();

  PiarInscripcion? inscripcionById(String id) {
    try {
      return _inscripciones.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Inscripción activa (si existe) de un estudiante en un año lectivo.
  PiarInscripcion? inscripcionActivaDe(String studentId, String academicYearId) {
    try {
      return _inscripciones.firstWhere(
        (i) =>
            i.studentId == studentId &&
            i.academicYearId == academicYearId &&
            i.estado != PiarEstadoInscripcion.cerrado,
      );
    } catch (_) {
      return null;
    }
  }

  List<PiarSoporteExterno> soportesFor(String inscripcionId) => _soportesExternos
      .where((s) => s.inscripcionId == inscripcionId)
      .toList();

  PiarPerfilApoyo? perfilFor(String inscripcionId) {
    try {
      return _perfilesApoyo.firstWhere((p) => p.inscripcionId == inscripcionId);
    } catch (_) {
      return null;
    }
  }

  List<PiarAjuste> ajustesFor(String inscripcionId) =>
      _ajustes.where((a) => a.inscripcionId == inscripcionId).toList();

  /// Ajustes de una inscripción a cargo de un docente concreto
  /// (`Teacher.id`) — lo único que el docente puede ver/editar de esa
  /// inscripción, nunca soportes externos ni el resto de asignaturas.
  List<PiarAjuste> ajustesForDocente(String inscripcionId, String teacherId) =>
      _ajustes
          .where(
            (a) =>
                a.inscripcionId == inscripcionId &&
                a.docenteResponsableId == teacherId &&
                a.eliminadoEn == null,
          )
          .toList();

  /// Inscripciones activas con al menos un ajuste a cargo de este docente
  /// — "Mis estudiantes con PIAR" (Fase 5). Se deriva de la carga
  /// académica ya resuelta al activar la inscripción (Fase 4), nunca de
  /// una asignación manual.
  List<PiarInscripcion> misEstudiantesPiar(String teacherId) => _inscripciones
      .where(
        (i) =>
            i.estado == PiarEstadoInscripcion.activo &&
            i.eliminadoEn == null &&
            _ajustes.any(
              (a) =>
                  a.inscripcionId == i.id &&
                  a.docenteResponsableId == teacherId &&
                  a.eliminadoEn == null,
            ),
      )
      .toList();

  /// Nº de ajustes de esta inscripción, a cargo de este docente, que aún
  /// no tienen respuesta (`requiereAjuste == null`) — para el badge de
  /// "pendientes" en el listado del docente.
  int ajustesPendientesDeDocente(String inscripcionId, String teacherId) =>
      ajustesForDocente(
        inscripcionId,
        teacherId,
      ).where((a) => a.requiereAjuste == null).length;

  PiarAjuste? ajusteById(String id) {
    try {
      return _ajustes.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Bandeja de avales (Fase 6): todos los ajustes significativos enviados
  /// por un docente y a la espera de aval de coordinación/directivo, sin
  /// importar a qué inscripción pertenezcan — es una cola única, no una
  /// vista por estudiante. Los más antiguos primero.
  List<PiarAjuste> get ajustesPendientesDeAval =>
      _ajustes.where((a) {
        return a.estado == PiarEstadoAjuste.pendienteAval &&
            a.eliminadoEn == null;
      }).toList()
        ..sort((a, b) => a.creadoEn.compareTo(b.creadoEn));

  /// El ajuste equivalente (misma asignatura y estándar) del período
  /// inmediatamente anterior dentro de la misma inscripción, si existe —
  /// para "Copiar del período anterior". Se toma el más reciente por
  /// `creadoEn` distinto del propio ajuste.
  PiarAjuste? ajusteAnteriorPara(PiarAjuste actual) {
    final candidatos =
        _ajustes.where(
          (a) =>
              a.id != actual.id &&
              a.inscripcionId == actual.inscripcionId &&
              a.subjectId == actual.subjectId &&
              a.standardId == actual.standardId &&
              a.eliminadoEn == null &&
              a.creadoEn.isBefore(actual.creadoEn),
        ).toList()
          ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return candidatos.firstOrNull;
  }

  /// Alertas abiertas (sin leer) de esta inscripción — tanto las
  /// asociadas directamente a ella como las de cualquiera de sus ajustes
  /// (Fase 8: docente sin responder, aplicación sin avance, etc.).
  int alertasAbiertasFor(String inscripcionId) {
    final ajusteIds = ajustesFor(inscripcionId).map((a) => a.id).toSet();
    return _alertas
        .where(
          (a) =>
              a.eliminadoEn == null &&
              a.estadoLectura == PiarEstadoLectura.noLeida &&
              ((a.entidadRelacionadaTipo == 'inscripcion' &&
                      a.entidadRelacionadaId == inscripcionId) ||
                  (a.entidadRelacionadaTipo == 'ajuste' &&
                      ajusteIds.contains(a.entidadRelacionadaId))),
        )
        .length;
  }

  PiarActaAcuerdo? actaFor(String inscripcionId) {
    try {
      return _actasAcuerdo.firstWhere((a) => a.inscripcionId == inscripcionId);
    } catch (_) {
      return null;
    }
  }

  PiarCatalogoApoyo? apoyoById(String id) {
    try {
      return _catalogoApoyos.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Requisito para pasar de borrador a activo: al menos un soporte
  /// externo vigente y el perfil de apoyo completo.
  bool puedeActivar(String inscripcionId) {
    final tieneSoporteVigente = soportesFor(
      inscripcionId,
    ).any((s) => s.eliminadoEn == null && s.vigente);
    final perfil = perfilFor(inscripcionId);
    return tieneSoporteVigente && (perfil?.estaCompleto ?? false);
  }

  // ── Inscripción ────────────────────────────────────────────────────────

  Future<(PiarAccionResultado, PiarInscripcion?)> crearInscripcion({
    required String studentId,
    required String academicYearId,
    required String courseId,
    required String coordinadorUid,
    List<String> padresAutorizadosIds = const [],
    String? inscripcionAnteriorId,
  }) async {
    if (inscripcionActivaDe(studentId, academicYearId) != null) {
      return (PiarAccionResultado.yaExisteInscripcionActiva, null);
    }
    final now = DateTime.now();
    final inscripcion = PiarInscripcion(
      id: const Uuid().v4(),
      studentId: studentId,
      academicYearId: academicYearId,
      courseId: courseId,
      fechaInscripcion: now,
      coordinadorId: coordinadorUid,
      estado: PiarEstadoInscripcion.borrador,
      inscripcionAnteriorId: inscripcionAnteriorId,
      padresAutorizadosIds: padresAutorizadosIds,
      creadoPor: coordinadorUid,
      creadoEn: now,
      actualizadoPor: coordinadorUid,
      actualizadoEn: now,
    );
    await _store.savePiarInscripcion(inscripcion);
    return (PiarAccionResultado.ok, inscripcion);
  }

  /// Transición borrador → activo. Toma el candado de unicidad en
  /// servidor (ver Fase 2) — si ya existe otra inscripción activa para
  /// este estudiante y año, falla de forma controlada.
  ///
  /// Además resuelve automáticamente la carga académica del estudiante
  /// (ya calculada por la pantalla, que tiene acceso a AcademicProvider):
  /// autoriza a esos docentes a ver el perfil de apoyo, crea una tarea
  /// pendiente de ajuste (borrador, sin responder) por cada competencia ya
  /// registrada en cada asignatura, y notifica a cada docente una sola vez.
  Future<PiarAccionResultado> activarInscripcion(
    String inscripcionId,
    String actorUid, {
    required List<PiarDocenteCarga> docentesDeLaCarga,
    required List<PiarCompetenciaPendiente> competenciasPendientes,
    required String periodId,
  }) async {
    final insc = inscripcionById(inscripcionId);
    if (insc == null) return PiarAccionResultado.noElegible;
    if (!puedeActivar(inscripcionId)) return PiarAccionResultado.noElegible;

    final lockObtenido = await _store.tryLockPiarInscripcionActiva(
      insc.studentId,
      insc.academicYearId,
    );
    if (!lockObtenido) return PiarAccionResultado.yaExisteInscripcionActiva;

    final now = DateTime.now();
    final docentesUids = docentesDeLaCarga.map((d) => d.userId).toSet().toList();

    await _store.savePiarInscripcion(
      PiarInscripcion(
        id: insc.id,
        studentId: insc.studentId,
        academicYearId: insc.academicYearId,
        courseId: insc.courseId,
        fechaInscripcion: insc.fechaInscripcion,
        coordinadorId: insc.coordinadorId,
        estado: PiarEstadoInscripcion.activo,
        inscripcionAnteriorId: insc.inscripcionAnteriorId,
        docentesAutorizadosIds: docentesUids,
        padresAutorizadosIds: insc.padresAutorizadosIds,
        creadoPor: insc.creadoPor,
        creadoEn: insc.creadoEn,
        actualizadoPor: actorUid,
        actualizadoEn: now,
        eliminadoEn: insc.eliminadoEn,
      ),
    );

    for (final c in competenciasPendientes) {
      await _store.savePiarAjuste(
        PiarAjuste(
          id: const Uuid().v4(),
          inscripcionId: insc.id,
          subjectId: c.subjectId,
          standardId: c.standardId,
          periodId: periodId,
          competenciaTextoOriginal: c.competenciaTextoOriginal,
          requiereAjuste: null,
          metaMinima: c.competenciaTextoOriginal,
          docenteResponsableId: c.docenteResponsableId,
          estado: PiarEstadoAjuste.borrador,
          creadoPor: actorUid,
          creadoEn: now,
          actualizadoPor: actorUid,
          actualizadoEn: now,
        ),
      );
    }

    for (final uid in docentesUids) {
      await _store.saveNotification(
        AppNotification(
          id: const Uuid().v4(),
          userId: uid,
          title: 'PIAR activado en tu clase',
          message:
              'Un estudiante de tu carga académica activó su PIAR. Revisa los ajustes pendientes en tu asignatura.',
          type: NotificationType.general,
          createdAt: now,
        ),
      );
    }

    return PiarAccionResultado.ok;
  }

  // ── Soportes externos ─────────────────────────────────────────────────

  Future<void> guardarSoporteExterno(PiarSoporteExterno soporte) =>
      _store.savePiarSoporteExterno(soporte);

  // ── Perfil de apoyo ───────────────────────────────────────────────────

  Future<void> guardarPerfilApoyo(PiarPerfilApoyo perfil) =>
      _store.savePiarPerfilApoyo(perfil);

  // ── Ajustes (pantalla del docente, Fase 5) ────────────────────────────

  Future<void> guardarAjuste(PiarAjuste ajuste) => _store.savePiarAjuste(ajuste);

  // ── Seguimiento y matriz de decisión (Fase 7) ──────────────────────────

  /// Todos los registros de seguimiento de un ajuste (el original y, si
  /// los hay, sus rectificaciones), del más reciente al más antiguo.
  List<PiarSeguimiento> seguimientosForAjuste(String ajusteId) =>
      _seguimientos.where((s) => s.ajusteId == ajusteId && s.eliminadoEn == null).toList()
        ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

  /// El registro vigente a mostrar/editar: el más reciente (si hubo una
  /// rectificación, esa es la que manda) — `null` si el docente todavía no
  /// ha registrado ningún seguimiento para este ajuste.
  PiarSeguimiento? seguimientoActualPara(String ajusteId) =>
      seguimientosForAjuste(ajusteId).firstOrNull;

  Future<void> guardarSeguimiento(PiarSeguimiento seguimiento) async {
    await _store.savePiarSeguimiento(seguimiento);
    await _evaluarReglasDeSeguimiento(seguimiento);
  }

  // ── Bandeja de avales (Fase 6) ─────────────────────────────────────────

  /// El `docenteUid` lo resuelve la pantalla (que tiene acceso a
  /// AcademicProvider para pasar de `Teacher.id` a su uid de Firebase Auth)
  /// — mismo patrón que `activarInscripcion`, PiarProvider no depende de
  /// AcademicProvider.
  Future<void> avalarAjuste(
    String ajusteId,
    String actorUid, {
    required String docenteUid,
  }) async {
    final a = ajusteById(ajusteId);
    if (a == null) return;
    final now = DateTime.now();
    await _store.savePiarAjuste(
      _copiarConEstado(a, PiarEstadoAjuste.avalado, actorUid, now),
    );
    await _store.saveNotification(
      AppNotification(
        id: const Uuid().v4(),
        userId: docenteUid,
        title: 'Ajuste PIAR avalado',
        message: 'Coordinación avaló el ajuste significativo que enviaste.',
        type: NotificationType.general,
        createdAt: now,
      ),
    );
  }

  /// Devuelve el ajuste al docente para que lo corrija. `motivo` queda
  /// visible para el docente en `observaciones` (no hay un campo dedicado
  /// en el modelo para esto — se antepone al texto que ya hubiera, sin
  /// perder lo que el docente había escrito).
  Future<void> devolverAjuste(
    String ajusteId,
    String actorUid,
    String motivo, {
    required String docenteUid,
  }) async {
    final a = ajusteById(ajusteId);
    if (a == null) return;
    final now = DateTime.now();
    final notaCoordinacion = 'Coordinación: $motivo';
    final observaciones = (a.observaciones == null || a.observaciones!.trim().isEmpty)
        ? notaCoordinacion
        : '$notaCoordinacion\n${a.observaciones}';
    await _store.savePiarAjuste(
      _copiarConEstado(
        a,
        PiarEstadoAjuste.devuelto,
        actorUid,
        now,
        observaciones: observaciones,
      ),
    );
    await _store.saveNotification(
      AppNotification(
        id: const Uuid().v4(),
        userId: docenteUid,
        title: 'Ajuste PIAR devuelto',
        message: 'Coordinación devolvió un ajuste para que lo revises: $motivo',
        type: NotificationType.general,
        createdAt: now,
      ),
    );
  }

  PiarAjuste _copiarConEstado(
    PiarAjuste a,
    PiarEstadoAjuste estado,
    String actorUid,
    DateTime now, {
    String? observaciones,
  }) {
    return PiarAjuste(
      id: a.id,
      inscripcionId: a.inscripcionId,
      subjectId: a.subjectId,
      standardId: a.standardId,
      periodId: a.periodId,
      competenciaTextoOriginal: a.competenciaTextoOriginal,
      requiereAjuste: a.requiereAjuste,
      tiposAjuste: a.tiposAjuste,
      descripcionAjuste: a.descripcionAjuste,
      metaMinima: a.metaMinima,
      justificacionSignificativo: a.justificacionSignificativo,
      evidenciaEsperada: a.evidenciaEsperada,
      apoyosAUtilizarIds: a.apoyosAUtilizarIds,
      observaciones: observaciones ?? a.observaciones,
      docenteResponsableId: a.docenteResponsableId,
      estado: estado,
      sinRevisar: a.sinRevisar,
      creadoPor: a.creadoPor,
      creadoEn: a.creadoEn,
      actualizadoPor: actorUid,
      actualizadoEn: now,
      eliminadoEn: a.eliminadoEn,
    );
  }

  // ── Alertas automáticas (Fase 8) ───────────────────────────────────────

  /// Alertas abiertas (sin leer), de la más reciente a la más antigua —
  /// bandeja de alertas de coordinación.
  List<PiarAlerta> get alertasAbiertas =>
      _alertas.where((a) => a.eliminadoEn == null && a.estadoLectura == PiarEstadoLectura.noLeida).toList()
        ..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

  Future<void> marcarAlertaLeida(String id) => _store.marcarPiarAlertaLeida(id);

  /// Sin umbral configurable en el modelo de datos (no se pidió agregar
  /// uno) — valores razonables fijados aquí: 7 días sin que el docente
  /// responda si necesita ajuste, y 30 días de inscripción activa sin acta
  /// firmada.
  static const _diasDocenteSinResponder = 7;
  static const _diasParaActaSinFirmar = 30;

  Future<void> _crearAlertaSiNoExiste({
    required PiarTipoAlerta tipo,
    required String entidadTipo,
    required String entidadId,
    required String mensaje,
  }) async {
    final destinatarios = _users
        .where((u) => u.role == UserRole.coordinator || u.role == UserRole.admin)
        .map((u) => u.id);
    for (final uid in destinatarios) {
      final yaExiste = _alertas.any(
        (a) =>
            a.tipo == tipo &&
            a.entidadRelacionadaTipo == entidadTipo &&
            a.entidadRelacionadaId == entidadId &&
            a.destinatarioUserId == uid &&
            a.estadoLectura == PiarEstadoLectura.noLeida &&
            a.eliminadoEn == null,
      );
      if (yaExiste) continue;
      final now = DateTime.now();
      await _store.savePiarAlerta(
        PiarAlerta(
          id: const Uuid().v4(),
          tipo: tipo,
          destinatarioUserId: uid,
          mensaje: mensaje,
          entidadRelacionadaTipo: entidadTipo,
          entidadRelacionadaId: entidadId,
          creadoPor: 'sistema',
          creadoEn: now,
          actualizadoPor: 'sistema',
          actualizadoEn: now,
        ),
      );
    }
  }

  /// Barrido de las reglas 1, 5 y 6 (docente sin responder, soporte
  /// vencido, acta sin firmar) — se reevalúa cada vez que llega una
  /// actualización de inscripciones, ajustes, actas o usuarios. Es
  /// deliberadamente reactivo en el cliente en vez de un job programado:
  /// no hay Cloud Functions activas en este proyecto (plan Spark, ver
  /// SeedService), así que esto es lo más cercano a "automático" sin un
  /// backend con scheduler.
  Future<void> _revisarAlertasAutomaticas() async {
    if (_users.isEmpty) return;
    final ahora = DateTime.now();

    for (final a in _ajustes) {
      if (a.eliminadoEn != null || a.requiereAjuste != null) continue;
      if (ahora.difference(a.creadoEn).inDays < _diasDocenteSinResponder) continue;
      await _crearAlertaSiNoExiste(
        tipo: PiarTipoAlerta.docenteSinAjustes,
        entidadTipo: 'ajuste',
        entidadId: a.id,
        mensaje:
            'Un docente lleva más de $_diasDocenteSinResponder días sin '
            'responder si un estudiante necesita ajuste en una competencia.',
      );
    }

    for (final insc in _inscripciones) {
      if (insc.estado != PiarEstadoInscripcion.activo || insc.eliminadoEn != null) {
        continue;
      }

      final soportes = soportesFor(insc.id).where((s) => s.eliminadoEn == null);
      if (soportes.isNotEmpty && !soportes.any((s) => s.vigente)) {
        await _crearAlertaSiNoExiste(
          tipo: PiarTipoAlerta.soporteVencido,
          entidadTipo: 'inscripcion',
          entidadId: insc.id,
          mensaje:
              'El soporte externo de este estudiante venció. Es necesario '
              'actualizarlo.',
        );
      }

      if (ahora.difference(insc.fechaInscripcion).inDays >= _diasParaActaSinFirmar) {
        final acta = actaFor(insc.id);
        if (acta == null || !acta.firmadaCompleta) {
          await _crearAlertaSiNoExiste(
            tipo: PiarTipoAlerta.actaNoFirmada,
            entidadTipo: 'inscripcion',
            entidadId: insc.id,
            mensaje:
                'Han pasado más de $_diasParaActaSinFirmar días desde la '
                'inscripción y el acta de acuerdo no está firmada.',
          );
        }
      }
    }
  }

  /// Reglas 2, 3 y 4 (aplicación completa sin avance, no aplicado
  /// repetido, logrado con autonomía repetido) — se evalúan justo al
  /// guardar un seguimiento, que es el único momento en que estas
  /// condiciones pueden volverse ciertas.
  Future<void> _evaluarReglasDeSeguimiento(PiarSeguimiento s) async {
    if (_users.isEmpty) return;

    if (s.aplicacion == PiarAplicacion.completo &&
        s.valoracion == PiarValoracion.sinAvance) {
      await _crearAlertaSiNoExiste(
        tipo: PiarTipoAlerta.aplicacionCompletaSinAvance,
        entidadTipo: 'ajuste',
        entidadId: s.ajusteId,
        mensaje:
            'Un ajuste se aplicó completo pero el estudiante no muestra '
            'avance. Revisa si sigue siendo el ajuste adecuado.',
      );
    }

    // El stream de seguimientos puede no haber traído todavía este mismo
    // registro de vuelta — se arma el historial a mano incluyéndolo, para
    // no depender de ese round-trip.
    final historial =
        [
          s,
          ..._seguimientos.where(
            (x) => x.ajusteId == s.ajusteId && x.id != s.id && x.eliminadoEn == null,
          ),
        ]..sort((a, b) => b.creadoEn.compareTo(a.creadoEn));

    if (historial.length < 2) return;
    final ultimos2 = historial.take(2);

    if (ultimos2.every((h) => h.aplicacion == PiarAplicacion.noAplicado)) {
      await _crearAlertaSiNoExiste(
        tipo: PiarTipoAlerta.noAplicadoRepetido,
        entidadTipo: 'ajuste',
        entidadId: s.ajusteId,
        mensaje:
            'Un ajuste lleva dos períodos seguidos sin aplicarse. Revisa si '
            'es viable en la práctica.',
      );
    }
    if (ultimos2.every((h) => h.valoracion == PiarValoracion.logradoAutonomia)) {
      await _crearAlertaSiNoExiste(
        tipo: PiarTipoAlerta.logradoAutonomiaRepetido,
        entidadTipo: 'ajuste',
        entidadId: s.ajusteId,
        mensaje:
            'Un estudiante logró la competencia con autonomía dos períodos '
            'seguidos. Evalúa si el ajuste todavía es necesario.',
      );
    }
  }

  // ── Consolidado, diagnóstico final y cierre de año (Fase 9) ────────────

  List<PiarDiagnosticoFinal> diagnosticosFor(String inscripcionId) =>
      _diagnosticosFinales
          .where((d) => d.inscripcionId == inscripcionId && d.eliminadoEn == null)
          .toList();

  PiarDiagnosticoFinal? diagnosticoFinalPara(String inscripcionId, String standardId) {
    try {
      return _diagnosticosFinales.firstWhere(
        (d) =>
            d.inscripcionId == inscripcionId &&
            d.standardId == standardId &&
            d.eliminadoEn == null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> guardarDiagnosticoFinal(PiarDiagnosticoFinal d) =>
      _store.savePiarDiagnosticoFinal(d);

  /// Cierre de año: solo procede si todos los docentes ya respondieron si
  /// necesitaban ajuste (ninguna tarea pendiente) y cada ajuste con
  /// `requiereAjuste == true` ya tiene diagnóstico final registrado —
  /// evita cerrar un año con tareas sin resolver o competencias sin
  /// valoración de cierre. No crea automáticamente la inscripción del año
  /// siguiente: eso lo hace coordinación desde "Inscribir estudiante"
  /// cuando corresponda, vinculándola con `inscripcionAnteriorId`.
  Future<PiarAccionResultado> cerrarAnio(String inscripcionId, String actorUid) async {
    final insc = inscripcionById(inscripcionId);
    if (insc == null || insc.estado != PiarEstadoInscripcion.activo) {
      return PiarAccionResultado.noElegible;
    }

    final ajustesDeLaInscripcion = ajustesFor(
      inscripcionId,
    ).where((a) => a.eliminadoEn == null);
    final hayPendientesSinResponder = ajustesDeLaInscripcion.any(
      (a) => a.requiereAjuste == null,
    );
    if (hayPendientesSinResponder) return PiarAccionResultado.noElegible;
    final faltanDiagnosticos = ajustesDeLaInscripcion
        .where((a) => a.requiereAjuste == true)
        .any((a) => diagnosticoFinalPara(inscripcionId, a.standardId) == null);
    if (faltanDiagnosticos) return PiarAccionResultado.noElegible;

    final now = DateTime.now();
    await _store.savePiarInscripcion(
      PiarInscripcion(
        id: insc.id,
        studentId: insc.studentId,
        academicYearId: insc.academicYearId,
        courseId: insc.courseId,
        fechaInscripcion: insc.fechaInscripcion,
        coordinadorId: insc.coordinadorId,
        estado: PiarEstadoInscripcion.cerrado,
        inscripcionAnteriorId: insc.inscripcionAnteriorId,
        docentesAutorizadosIds: insc.docentesAutorizadosIds,
        padresAutorizadosIds: insc.padresAutorizadosIds,
        creadoPor: insc.creadoPor,
        creadoEn: insc.creadoEn,
        actualizadoPor: actorUid,
        actualizadoEn: now,
        eliminadoEn: insc.eliminadoEn,
      ),
    );
    return PiarAccionResultado.ok;
  }
}
