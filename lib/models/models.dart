enum UserRole { coordinator, teacher, student, parent, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? avatar;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.avatar,
    this.isActive = true,
  });
}

class AcademicYear {
  final String id;
  final int year;
  final bool isActive;

  const AcademicYear({
    required this.id,
    required this.year,
    this.isActive = true,
  });
}

class AcademicPeriod {
  final String id;
  final String academicYearId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double weight;
  bool isOpen;

  AcademicPeriod({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.weight,
    this.isOpen = true,
  });
}

class Subject {
  final String id;
  final String code;
  final String name;
  final String area;
  final int hoursPerWeek;
  final String? teacherId;

  const Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.area,
    required this.hoursPerWeek,
    this.teacherId,
  });
}

// ─── Estándar → Competencia → Actividad ──────────────────────────────────

enum CompetenciaTipo { cognitiva, actitudinal }

/// Hasta 5 por asignatura, definidos una vez por año lectivo (no por período).
class Estandar {
  final String id;
  final String subjectId;
  final String academicYearId;
  final String name;
  final String description;
  final int order;
  final double weight;

  const Estandar({
    required this.id,
    required this.subjectId,
    required this.academicYearId,
    required this.name,
    required this.description,
    required this.order,
    required this.weight,
  });
}

/// Hasta 5 por Estándar, asignadas por período — no es obligatorio que un
/// Estándar tenga competencias en todos los períodos. Exactamente una de
/// las competencias de un mismo (estandarId, periodId) debe ser
/// `actitudinal`; el resto son `cognitiva`. Se valida en la UI de
/// creación/edición (`standards_screen.dart`), no aquí — los datos
/// migrados desde el modelo viejo quedan exentos de esta regla.
class Competencia {
  final String id;
  final String estandarId;
  final String periodId;
  final CompetenciaTipo tipo;
  final String name;
  final String description;
  final int order;

  const Competencia({
    required this.id,
    required this.estandarId,
    required this.periodId,
    required this.tipo,
    required this.name,
    required this.description,
    required this.order,
  });
}

/// Hasta 6 por Competencia. Es la hoja donde realmente se registra nota
/// (1.0-5.0, mismo `GradeScale` de siempre) — reemplaza el mecanismo de
/// hasta 3 "casillas" (`Grade.slot`) por indicador del modelo viejo.
class Actividad {
  final String id;
  final String competenciaId;
  final String name;
  final String description;
  final int order;
  final DateTime? date;

  const Actividad({
    required this.id,
    required this.competenciaId,
    required this.name,
    required this.description,
    required this.order,
    this.date,
  });
}

class Course {
  final String id;
  final String name;
  final String grade;
  final String section;
  final String academicYearId;
  final String? directorTeacherId;

  const Course({
    required this.id,
    required this.name,
    required this.grade,
    required this.section,
    required this.academicYearId,
    this.directorTeacherId,
  });
}

class Student {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String documentId;
  final DateTime birthDate;
  final String? courseId;
  final List<String> parentIds;

  const Student({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.documentId,
    required this.birthDate,
    this.courseId,
    this.parentIds = const [],
  });

  String get fullName => '$firstName $lastName';
}

class Teacher {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String documentId;
  final String specialization;
  final List<String> subjectIds;

  const Teacher({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.documentId,
    required this.specialization,
    this.subjectIds = const [],
  });

  String get fullName => '$firstName $lastName';
}

class Parent {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String documentId;
  final String phone;
  final String relationship;
  final List<String> studentIds;

  const Parent({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.documentId,
    required this.phone,
    required this.relationship,
    this.studentIds = const [],
  });

  String get fullName => '$firstName $lastName';
}

class Grade {
  final String id;
  final String studentId;
  final String subjectId;
  final String periodId;
  // Referencias al modelo Estándar → Competencia → Actividad. Los tres
  // null = nota de Evaluación Final.
  final String? estandarId;
  final String? competenciaId;
  final String? actividadId;
  final double value;
  final String? note;
  final DateTime registeredAt;

  const Grade({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.periodId,
    this.estandarId,
    this.competenciaId,
    this.actividadId,
    required this.value,
    this.note,
    required this.registeredAt,
  });
}

class AttendanceRecord {
  final String id;
  final String studentId;
  final String subjectId;
  final String periodId;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.periodId,
    required this.date,
    required this.status,
    this.note,
  });
}

enum AttendanceStatus { present, absent, late, excused }

class Observation {
  final String id;
  final String studentId;
  final String teacherId;
  final String? subjectId;
  final ObservationType type;
  final String title;
  final String description;
  final DateTime date;

  const Observation({
    required this.id,
    required this.studentId,
    required this.teacherId,
    this.subjectId,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
  });
}

enum ObservationType { academic, disciplinary, positive }

/// Evaluación de comportamiento de un estudiante en un período, registrada
/// por el docente director de curso (no confundir con [Observation], que
/// son notas puntuales de cualquier docente).
class BehaviorAssessment {
  final String id;
  final String studentId;
  final String periodId;
  final String teacherId;
  final String performanceLevel;
  final String description;
  final DateTime registeredAt;

  const BehaviorAssessment({
    required this.id,
    required this.studentId,
    required this.periodId,
    required this.teacherId,
    required this.performanceLevel,
    required this.description,
    required this.registeredAt,
  });
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });
}

enum NotificationType {
  grade,
  attendance,
  observation,
  period,
  report,
  general,
}

class SubjectAssignment {
  final String id;
  // `null` = asignatura del curso todavía sin docente asignado (ej. cuando
  // se agrega por grado desde Cursos, antes de definir quién la dicta en
  // cada sección).
  final String? teacherId;
  final String subjectId;
  final String courseId;
  final String academicYearId;

  const SubjectAssignment({
    required this.id,
    this.teacherId,
    required this.subjectId,
    required this.courseId,
    required this.academicYearId,
  });
}

class EvaluationConfig {
  final String id;
  final String subjectId;
  final String periodId;
  final double standardsWeight;
  final double finalExamWeight;

  const EvaluationConfig({
    required this.id,
    required this.subjectId,
    required this.periodId,
    required this.standardsWeight,
    required this.finalExamWeight,
  });
}

// ─── Hoja de Vida ──────────────────────────────────────────────────────────

class AcademicRecord {
  final String id;
  String nombreColegio;
  String grado;
  String anio;
  bool esColegioActual;

  AcademicRecord({
    required this.id,
    required this.nombreColegio,
    required this.grado,
    required this.anio,
    this.esColegioActual = false,
  });
}

class ExtendedProfile {
  // Personal
  String tipoDocumento;
  String? ciudadExpedicion;
  String? segundoNombre;
  String? segundoApellido;
  String? ciudadNacimiento;
  String? fechaNacimiento;
  String? tipoSangre;
  String? sexo;
  String? estadoCivil;
  String? numHijos;

  // Ubicación
  String? direccion;
  String? barrio;
  String? telefono;
  String? celular;
  String? email;
  String? ciudadUbicacion;

  // Salud
  String? sistemaSalud;
  String? regimen;
  String? epsArs;

  // Emergencia
  String? emergenciaNombre;
  String? emergenciaParentesco;
  String? emergenciaTelefono;
  String? emergenciaCelular;

  // Docente — Datos Institucionales
  String? fechaVinculacionMagisterio;
  String? decretoVinculacionMagisterio;
  String? claseFuncionario;
  String? escalafon;
  String? estadoDocente;
  String? maxCargaHoraria;
  String? fechaVinculacionColegio;
  String? fechaRetiroColegio;
  String? decretoVinculacionColegio;
  String? areaEnsenanza;
  String? tipoNombramiento;
  String? horarioLaboral;
  String? anosFormacionSuperior;

  // Estudiante — Historial Académico
  List<AcademicRecord> historialAcademico;

  ExtendedProfile({
    this.tipoDocumento = 'CC',
    this.ciudadExpedicion,
    this.segundoNombre,
    this.segundoApellido,
    this.ciudadNacimiento,
    this.fechaNacimiento,
    this.tipoSangre,
    this.sexo,
    this.estadoCivil,
    this.numHijos,
    this.direccion,
    this.barrio,
    this.telefono,
    this.celular,
    this.email,
    this.ciudadUbicacion,
    this.sistemaSalud,
    this.regimen,
    this.epsArs,
    this.emergenciaNombre,
    this.emergenciaParentesco,
    this.emergenciaTelefono,
    this.emergenciaCelular,
    this.fechaVinculacionMagisterio,
    this.decretoVinculacionMagisterio,
    this.claseFuncionario,
    this.escalafon,
    this.estadoDocente,
    this.maxCargaHoraria,
    this.fechaVinculacionColegio,
    this.fechaRetiroColegio,
    this.decretoVinculacionColegio,
    this.areaEnsenanza,
    this.tipoNombramiento,
    this.horarioLaboral,
    this.anosFormacionSuperior,
    List<AcademicRecord>? historialAcademico,
  }) : historialAcademico = historialAcademico ?? [];
}
