/// Modelos del módulo PIAR (Plan Individual de Ajustes Razonables,
/// Decreto 1421 de 2017). Viven en un archivo aparte de `models.dart` por
/// tamaño y para mantener el módulo aislado del resto del dominio.
///
/// Todas las entidades referencian datos académicos ya existentes
/// (Student, Subject, Standard, AcademicPeriod, AcademicYear, Course) por
/// id — el módulo no los redefine. Todas llevan auditoría
/// (creadoPor/creadoEn/actualizadoPor/actualizadoEn) y borrado lógico
/// (eliminadoEn == null significa "vigente").
library;

// ─── Catálogos cerrados ──────────────────────────────────────────────────

enum PiarEstadoInscripcion { borrador, activo, cerrado }

enum PiarTipoSoporte {
  informePsicologico,
  valoracionMedica,
  terapiaOcupacional,
  fonoaudiologia,
  neuropsicologia,
  certificadoDiscapacidad,
  otro,
}

/// De acceso, metodológico, evaluativo o significativo. Un ajuste puede
/// tener varios a la vez (conjunto, no valor único).
enum PiarTipoAjuste { acceso, metodologico, evaluativo, significativo }

enum PiarEstadoAjuste { borrador, enviado, pendienteAval, avalado, devuelto }

enum PiarAplicacion { completo, parcial, noAplicado }

enum PiarCausaNoAplicacion {
  faltaMaterialORecurso,
  faltaTiempoEnClase,
  inasistenciaEstudiante,
  ajusteNoPertinente,
  otra,
}

enum PiarValoracion { logradoAutonomia, logradoConApoyo, enProceso, sinAvance }

enum PiarDecisionAjuste { mantener, modificar, retirar, escalar }

enum PiarTipoAlerta {
  docenteSinAjustes,
  aplicacionCompletaSinAvance,
  noAplicadoRepetido,
  logradoAutonomiaRepetido,
  soporteVencido,
  actaNoFirmada,
}

enum PiarEstadoLectura { noLeida, leida }

// ─── piar_inscripcion — contenedor por estudiante y año lectivo ─────────

class PiarInscripcion {
  final String id;
  final String studentId;
  final String academicYearId;
  final String courseId;
  final DateTime fechaInscripcion;
  final String coordinadorId;
  final PiarEstadoInscripcion estado;
  /// Referencia opcional a la inscripción del año lectivo anterior, para
  /// heredar el diagnóstico final al cierre de año (fase 9).
  final String? inscripcionAnteriorId;

  /// Uids de Firebase Auth (no `Teacher.id`) de los docentes actualmente
  /// autorizados a ver el perfil de apoyo de este estudiante — resuelto
  /// automáticamente desde la carga académica al activar la inscripción
  /// (fase 4) y usado directamente por las Firestore rules (fase 2), que
  /// no pueden ejecutar queries y necesitan esta lista ya materializada
  /// para verificar pertenencia sin dar por hecho ninguna otra colección.
  final List<String> docentesAutorizadosIds;

  /// Uids de Firebase Auth de los padres/acudientes del estudiante,
  /// resuelto desde `Student.parentIds` al crear la inscripción. Mismo
  /// motivo que `docentesAutorizadosIds`: hace verificable en servidor
  /// que un padre solo vea el PIAR de su propio hijo.
  final List<String> padresAutorizadosIds;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarInscripcion({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.courseId,
    required this.fechaInscripcion,
    required this.coordinadorId,
    required this.estado,
    this.inscripcionAnteriorId,
    this.docentesAutorizadosIds = const [],
    this.padresAutorizadosIds = const [],
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });
}

// ─── piar_soporte_externo — visibilidad coordinación/orientación ────────

class PiarSoporteExterno {
  final String id;
  final String inscripcionId;
  final PiarTipoSoporte tipo;
  final String entidadEmisora;
  final String profesional;
  final String numeroRegistroProfesional;
  final DateTime fechaEmision;
  final DateTime vigenciaHasta;
  /// Referencia/URL del adjunto. Sin subida real de archivo binario en
  /// esta entrega (decisión de Fase 0 — Firebase Storage queda fuera de
  /// alcance).
  final String? archivoAdjunto;
  final String? observaciones;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarSoporteExterno({
    required this.id,
    required this.inscripcionId,
    required this.tipo,
    required this.entidadEmisora,
    required this.profesional,
    required this.numeroRegistroProfesional,
    required this.fechaEmision,
    required this.vigenciaHasta,
    this.archivoAdjunto,
    this.observaciones,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });

  bool get vigente => vigenciaHasta.isAfter(DateTime.now());
}

// ─── piar_perfil_apoyo — capa visible al docente, una por inscripción ───

class PiarPerfilApoyo {
  final String id;
  final String inscripcionId;
  final String fortalezas;
  final String comoAprendeMejor;
  final String barrerasIdentificadas;
  final String canalAccesoPreferente;
  final String formaRespuestaPreferente;
  final int tiempoAtencionSostenidaMinutos;
  /// Referencias a `piar_catalogo_apoyo`.
  final List<String> apoyosRequeridosIds;
  /// Solo información operativa de aula (crisis, medicación en jornada,
  /// posicionamiento, restricciones físicas). Nunca diagnósticos.
  final String? alertasAula;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarPerfilApoyo({
    required this.id,
    required this.inscripcionId,
    required this.fortalezas,
    required this.comoAprendeMejor,
    required this.barrerasIdentificadas,
    required this.canalAccesoPreferente,
    required this.formaRespuestaPreferente,
    required this.tiempoAtencionSostenidaMinutos,
    this.apoyosRequeridosIds = const [],
    this.alertasAula,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });

  /// Perfil completo = todos los campos de texto obligatorios diligenciados.
  /// Usado para decidir si una inscripción puede pasar a `activo`.
  bool get estaCompleto =>
      fortalezas.trim().isNotEmpty &&
      comoAprendeMejor.trim().isNotEmpty &&
      barrerasIdentificadas.trim().isNotEmpty &&
      canalAccesoPreferente.trim().isNotEmpty &&
      formaRespuestaPreferente.trim().isNotEmpty;
}

// ─── piar_catalogo_apoyo — catálogo de apoyos disponibles ───────────────

class PiarCatalogoApoyo {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  const PiarCatalogoApoyo({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.activo = true,
  });
}

// ─── piar_ajuste — el núcleo ─────────────────────────────────────────────

class PiarAjuste {
  final String id;
  final String inscripcionId;
  final String subjectId;
  /// Estándar/competencia existente que se está ajustando (se referencia,
  /// no se duplica).
  final String standardId;
  /// Período del ajuste. Independiente de si el `Standard` referenciado
  /// tiene `periodId` asignado o no — el ajuste siempre queda fechado a
  /// un período académico concreto.
  final String periodId;
  /// Copia congelada del texto de la competencia en el momento de crear
  /// el ajuste. No se vuelve a leer de `Standard` — si el estándar cambia
  /// después, este texto no se altera.
  final String competenciaTextoOriginal;
  /// Sin valor por defecto: el docente debe responder explícitamente.
  /// `null` = tarea pendiente, todavía sin responder (el estado en que el
  /// sistema crea el ajuste automáticamente al activar la inscripción o
  /// al resolver una nueva competencia en la asignatura). La pantalla del
  /// docente (Fase 5) exige que sea no-nulo antes de poder enviar.
  final bool? requiereAjuste;
  final Set<PiarTipoAjuste> tiposAjuste;
  final String descripcionAjuste;
  /// Si `tiposAjuste` no incluye `significativo`, debe ser idéntico a
  /// `competenciaTextoOriginal` e inmutable (regla aplicada en servidor,
  /// ver Firestore rules de la Fase 2).
  final String metaMinima;
  /// Obligatorio si `tiposAjuste` incluye `significativo`.
  final String? justificacionSignificativo;
  final String evidenciaEsperada;
  /// Referencias a `piar_catalogo_apoyo`.
  final List<String> apoyosAUtilizarIds;
  final String? observaciones;
  final String docenteResponsableId;
  final PiarEstadoAjuste estado;
  /// Marca de "Copiar del período anterior" (fase 5): filas copiadas
  /// quedan `true` hasta que el docente las confirma una por una.
  final bool sinRevisar;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarAjuste({
    required this.id,
    required this.inscripcionId,
    required this.subjectId,
    required this.standardId,
    required this.periodId,
    required this.competenciaTextoOriginal,
    required this.requiereAjuste,
    this.tiposAjuste = const {},
    this.descripcionAjuste = '',
    required this.metaMinima,
    this.justificacionSignificativo,
    this.evidenciaEsperada = '',
    this.apoyosAUtilizarIds = const [],
    this.observaciones,
    required this.docenteResponsableId,
    required this.estado,
    this.sinRevisar = false,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });

  bool get esSignificativo => tiposAjuste.contains(PiarTipoAjuste.significativo);
}

// ─── piar_seguimiento — uno por ajuste y período ────────────────────────

class PiarSeguimiento {
  final String id;
  final String ajusteId;
  /// Copiado del `PiarAjuste.docenteResponsableId` en el momento de crear
  /// el seguimiento — permite a las Firestore rules (fase 2) verificar
  /// pertenencia con una sola lectura directa, sin encadenar `get()` al
  /// ajuste padre en cada evaluación de regla.
  final String docenteResponsableId;
  final String periodId;
  final PiarAplicacion aplicacion;
  /// Obligatorio si `aplicacion != completo`.
  final PiarCausaNoAplicacion? causaNoAplicacion;
  final PiarValoracion valoracion;
  /// Referencias a `piar_catalogo_apoyo`. Obligatorio si
  /// `valoracion == logradoConApoyo`.
  final List<String>? apoyosEfectivamenteUsadosIds;
  final String queLogro;
  final String conQueApoyo;
  final String queSigue;
  final PiarDecisionAjuste decisionAjuste;
  /// Obligatorio si `decisionAjuste == modificar`.
  final String? nuevaRedaccion;
  /// Período cerrado = solo lectura. Las correcciones se hacen creando un
  /// registro nuevo con `esRectificacion = true` y
  /// `rectificaARegistroId` apuntando al original — nunca se sobrescribe
  /// un registro de período cerrado.
  final bool esRectificacion;
  final String? rectificaARegistroId;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarSeguimiento({
    required this.id,
    required this.ajusteId,
    required this.docenteResponsableId,
    required this.periodId,
    required this.aplicacion,
    this.causaNoAplicacion,
    required this.valoracion,
    this.apoyosEfectivamenteUsadosIds,
    required this.queLogro,
    required this.conQueApoyo,
    required this.queSigue,
    required this.decisionAjuste,
    this.nuevaRedaccion,
    this.esRectificacion = false,
    this.rectificaARegistroId,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });
}

// ─── piar_evidencia — adjuntos del seguimiento ──────────────────────────

class PiarEvidencia {
  final String id;
  final String seguimientoId;
  /// Copiado del `PiarSeguimiento.docenteResponsableId` — mismo motivo
  /// que en `PiarSeguimiento`: evita encadenar `get()` en las rules.
  final String docenteResponsableId;
  /// Referencia/URL del adjunto (sin subida real, ver nota en
  /// `PiarSoporteExterno.archivoAdjunto`).
  final String archivo;
  final String descripcionBreve;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarEvidencia({
    required this.id,
    required this.seguimientoId,
    required this.docenteResponsableId,
    required this.archivo,
    required this.descripcionBreve,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });
}

// ─── piar_acta_acuerdo — firmas de familia, docentes y directivo ────────

class PiarActaAcuerdo {
  final String id;
  final String inscripcionId;
  final DateTime fecha;
  final String? archivo;
  final bool firmadaFamilia;
  final bool firmadaDocentes;
  final bool firmadaDirectivo;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarActaAcuerdo({
    required this.id,
    required this.inscripcionId,
    required this.fecha,
    this.archivo,
    this.firmadaFamilia = false,
    this.firmadaDocentes = false,
    this.firmadaDirectivo = false,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });

  bool get firmadaCompleta => firmadaFamilia && firmadaDocentes && firmadaDirectivo;
}

// ─── piar_diagnostico_final — por inscripción y competencia ─────────────

class PiarDiagnosticoFinal {
  final String id;
  final String inscripcionId;
  final String standardId;
  final PiarValoracion valoracionFinal;
  final bool tuvoAjusteSignificativo;
  final String observacion;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarDiagnosticoFinal({
    required this.id,
    required this.inscripcionId,
    required this.standardId,
    required this.valoracionFinal,
    required this.tuvoAjusteSignificativo,
    required this.observacion,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });
}

// ─── piar_alerta — cola de alertas generadas por el sistema ─────────────

class PiarAlerta {
  final String id;
  final PiarTipoAlerta tipo;
  /// Usuario específico al que se dirige la alerta (se resuelve en el
  /// momento de generarla; para alertas "a coordinación" se crea una
  /// instancia por cada usuario coordinador/admin activo).
  final String destinatarioUserId;
  final String mensaje;
  /// Tipo de entidad relacionada: 'inscripcion' | 'ajuste' | 'seguimiento'
  /// | 'soporte_externo' | 'acta_acuerdo'.
  final String? entidadRelacionadaTipo;
  final String? entidadRelacionadaId;
  final PiarEstadoLectura estadoLectura;

  final String creadoPor;
  final DateTime creadoEn;
  final String actualizadoPor;
  final DateTime actualizadoEn;
  final DateTime? eliminadoEn;

  const PiarAlerta({
    required this.id,
    required this.tipo,
    required this.destinatarioUserId,
    required this.mensaje,
    this.entidadRelacionadaTipo,
    this.entidadRelacionadaId,
    this.estadoLectura = PiarEstadoLectura.noLeida,
    required this.creadoPor,
    required this.creadoEn,
    required this.actualizadoPor,
    required this.actualizadoEn,
    this.eliminadoEn,
  });
}
