import '../models/models.dart';

/// Abstracción de acceso a datos (equivalente a las colecciones de
/// Firestore usadas por la app). Implementada por [FirebaseDataRepository]
/// (real) y [MockDataRepository] (datos falsos en memoria) — ver
/// lib/repositories/repository_provider.dart para el mecanismo que elige
/// cuál usar.
abstract class DataRepository {
  // ── Usuarios ─────────────────────────────────────────────────────────────
  Stream<List<AppUser>> usersStream();
  Future<AppUser?> getUser(String uid);
  Future<void> saveUser(String uid, AppUser user);
  Future<void> updateUserStatus(String uid, {required bool isActive});
  Future<void> deleteUser(String uid);

  // ── Estudiantes ──────────────────────────────────────────────────────────
  Stream<List<Student>> studentsStream();
  Future<Student?> getStudent(String id);
  Future<Student?> getStudentByUserId(String userId);
  Future<List<Student>> getStudentsByCourse(String courseId);
  Future<void> saveStudent(Student student);
  Future<void> deleteStudent(String id);

  // ── Docentes ─────────────────────────────────────────────────────────────
  Stream<List<Teacher>> teachersStream();
  Future<Teacher?> getTeacher(String id);
  Future<Teacher?> getTeacherByUserId(String userId);
  Future<void> saveTeacher(Teacher teacher);
  Future<void> deleteTeacher(String id);

  // ── Padres de familia ────────────────────────────────────────────────────
  Stream<List<Parent>> parentsStream();
  Future<Parent?> getParentByUserId(String userId);
  Future<void> saveParent(Parent parent);
  Future<void> deleteParent(String id);

  // ── Cursos ───────────────────────────────────────────────────────────────
  Stream<List<Course>> coursesStream();
  Future<void> saveCourse(Course course);
  Future<void> deleteCourse(String id);

  // ── Asignaturas ──────────────────────────────────────────────────────────
  Stream<List<Subject>> subjectsStream();
  Future<void> saveSubject(Subject subject);
  Future<void> deleteSubject(String id);

  // ── Años y períodos académicos ───────────────────────────────────────────
  Stream<List<AcademicYear>> academicYearsStream();
  Future<void> saveAcademicYear(AcademicYear year);

  Stream<List<AcademicPeriod>> periodsStream({String? academicYearId});
  Future<void> savePeriod(AcademicPeriod period);

  // ── Estándares de evaluación ─────────────────────────────────────────────
  Stream<List<Standard>> standardsStream({String? subjectId});
  Future<void> saveStandard(Standard standard);
  Future<void> deleteStandard(String id);

  // ── Calificaciones ───────────────────────────────────────────────────────
  Stream<List<Grade>> gradesStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  });
  Future<void> saveGrade(Grade grade);
  Future<void> deleteGrade(String id);

  // ── Asistencia ───────────────────────────────────────────────────────────
  Stream<List<AttendanceRecord>> attendanceStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  });
  Future<void> saveAttendance(AttendanceRecord record);
  Future<void> deleteAttendance(String id);

  // ── Observaciones ────────────────────────────────────────────────────────
  Stream<List<Observation>> observationsStream({String? studentId});
  Future<void> saveObservation(Observation obs);
  Future<void> deleteObservation(String id);

  // ── Indicadores ──────────────────────────────────────────────────────────
  Stream<List<Indicator>> indicatorsStream({String? standardId});
  Future<void> saveIndicator(Indicator ind);
  Future<void> deleteIndicator(String id);

  // ── Actividades ──────────────────────────────────────────────────────────
  Stream<List<Activity>> activitiesStream({String? indicatorId});
  Future<void> saveActivity(Activity act);
  Future<void> deleteActivity(String id);

  // ── Configuración de evaluación ──────────────────────────────────────────
  Stream<List<EvaluationConfig>> evalConfigsStream();
  Future<void> saveEvalConfig(EvaluationConfig ec);

  // ── Notificaciones (por usuario) ─────────────────────────────────────────
  Stream<List<AppNotification>> notificationsStream(String userId);
  Future<void> saveNotification(AppNotification notif);
  Future<void> markNotificationRead(String userId, String notifId);

  // ── Asignaciones de asignaturas ──────────────────────────────────────────
  Stream<List<SubjectAssignment>> assignmentsStream({String? teacherId});
  Future<void> saveAssignment(SubjectAssignment a);
  Future<void> deleteAssignment(String id);
}
