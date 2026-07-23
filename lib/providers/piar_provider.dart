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
  List<PiarActaAcuerdo> _actasAcuerdo = [];
  List<PiarAlerta> _alertas = [];

  final List<StreamSubscription> _subs = [];

  PiarProvider() {
    _subs.addAll([
      _store.piarInscripcionesStream().listen((v) {
        _inscripciones = v;
        notifyListeners();
      }),
      _store.piarSoportesExternosStream().listen((v) {
        _soportesExternos = v;
        notifyListeners();
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
      }),
      _store.piarActasAcuerdoStream().listen((v) {
        _actasAcuerdo = v;
        notifyListeners();
      }),
      _store.piarAlertasStream().listen((v) {
        _alertas = v;
        notifyListeners();
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

  /// Alertas abiertas (sin leer) directamente asociadas a la inscripción.
  /// No cuenta todavía alertas generadas sobre un ajuste/seguimiento
  /// puntual de esta inscripción — eso se conecta en la Fase 8, que es
  /// cuando el sistema empieza a generar alertas reales.
  int alertasAbiertasFor(String inscripcionId) => _alertas
      .where(
        (a) =>
            a.eliminadoEn == null &&
            a.estadoLectura == PiarEstadoLectura.noLeida &&
            a.entidadRelacionadaTipo == 'inscripcion' &&
            a.entidadRelacionadaId == inscripcionId,
      )
      .length;

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
}
