import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../data_repository.dart';

/// Implementación real de [DataRepository]: delega en [FirestoreService]
/// (Cloud Firestore), sin cambiar su comportamiento. Solo aísla el código
/// de Firebase detrás de la interfaz de repositorio para poder alternarlo
/// con [MockDataRepository] mediante `useMockData`.
class FirebaseDataRepository implements DataRepository {
  final FirestoreService _store = FirestoreService();

  // ── Usuarios ─────────────────────────────────────────────────────────────
  @override
  Stream<List<AppUser>> usersStream() => _store.usersStream();
  @override
  Future<AppUser?> getUser(String uid) => _store.getUser(uid);
  @override
  Future<void> saveUser(String uid, AppUser user) => _store.saveUser(uid, user);
  @override
  Future<void> updateUserStatus(String uid, {required bool isActive}) =>
      _store.updateUserStatus(uid, isActive: isActive);
  @override
  Future<void> deleteUser(String uid) => _store.deleteUser(uid);

  // ── Estudiantes ──────────────────────────────────────────────────────────
  @override
  Stream<List<Student>> studentsStream() => _store.studentsStream();
  @override
  Future<Student?> getStudent(String id) => _store.getStudent(id);
  @override
  Future<Student?> getStudentByUserId(String userId) =>
      _store.getStudentByUserId(userId);
  @override
  Future<List<Student>> getStudentsByCourse(String courseId) =>
      _store.getStudentsByCourse(courseId);
  @override
  Future<void> saveStudent(Student student) => _store.saveStudent(student);
  @override
  Future<void> deleteStudent(String id) => _store.deleteStudent(id);

  // ── Docentes ─────────────────────────────────────────────────────────────
  @override
  Stream<List<Teacher>> teachersStream() => _store.teachersStream();
  @override
  Future<Teacher?> getTeacher(String id) => _store.getTeacher(id);
  @override
  Future<Teacher?> getTeacherByUserId(String userId) =>
      _store.getTeacherByUserId(userId);
  @override
  Future<void> saveTeacher(Teacher teacher) => _store.saveTeacher(teacher);
  @override
  Future<void> deleteTeacher(String id) => _store.deleteTeacher(id);

  // ── Padres de familia ────────────────────────────────────────────────────
  @override
  Stream<List<Parent>> parentsStream() => _store.parentsStream();
  @override
  Future<Parent?> getParentByUserId(String userId) =>
      _store.getParentByUserId(userId);
  @override
  Future<void> saveParent(Parent parent) => _store.saveParent(parent);
  @override
  Future<void> deleteParent(String id) => _store.deleteParent(id);

  // ── Cursos ───────────────────────────────────────────────────────────────
  @override
  Stream<List<Course>> coursesStream() => _store.coursesStream();
  @override
  Future<void> saveCourse(Course course) => _store.saveCourse(course);
  @override
  Future<void> deleteCourse(String id) => _store.deleteCourse(id);

  // ── Asignaturas ──────────────────────────────────────────────────────────
  @override
  Stream<List<Subject>> subjectsStream() => _store.subjectsStream();
  @override
  Future<void> saveSubject(Subject subject) => _store.saveSubject(subject);
  @override
  Future<void> deleteSubject(String id) => _store.deleteSubject(id);

  // ── Años y períodos académicos ───────────────────────────────────────────
  @override
  Stream<List<AcademicYear>> academicYearsStream() =>
      _store.academicYearsStream();
  @override
  Future<void> saveAcademicYear(AcademicYear year) =>
      _store.saveAcademicYear(year);

  @override
  Stream<List<AcademicPeriod>> periodsStream({String? academicYearId}) =>
      _store.periodsStream(academicYearId: academicYearId);
  @override
  Future<void> savePeriod(AcademicPeriod period) => _store.savePeriod(period);

  // ── Estándares de evaluación ─────────────────────────────────────────────
  @override
  Stream<List<Standard>> standardsStream({String? subjectId}) =>
      _store.standardsStream(subjectId: subjectId);
  @override
  Future<void> saveStandard(Standard standard) => _store.saveStandard(standard);
  @override
  Future<void> deleteStandard(String id) => _store.deleteStandard(id);

  // ── Calificaciones ───────────────────────────────────────────────────────
  @override
  Stream<List<Grade>> gradesStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  }) => _store.gradesStream(
    studentId: studentId,
    subjectId: subjectId,
    periodId: periodId,
  );
  @override
  Future<void> saveGrade(Grade grade) => _store.saveGrade(grade);
  @override
  Future<void> deleteGrade(String id) => _store.deleteGrade(id);

  // ── Asistencia ───────────────────────────────────────────────────────────
  @override
  Stream<List<AttendanceRecord>> attendanceStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  }) => _store.attendanceStream(
    studentId: studentId,
    subjectId: subjectId,
    periodId: periodId,
  );
  @override
  Future<void> saveAttendance(AttendanceRecord record) =>
      _store.saveAttendance(record);
  @override
  Future<void> deleteAttendance(String id) => _store.deleteAttendance(id);

  // ── Observaciones ────────────────────────────────────────────────────────
  @override
  Stream<List<Observation>> observationsStream({String? studentId}) =>
      _store.observationsStream(studentId: studentId);
  @override
  Future<void> saveObservation(Observation obs) => _store.saveObservation(obs);
  @override
  Future<void> deleteObservation(String id) => _store.deleteObservation(id);

  // ── Indicadores ──────────────────────────────────────────────────────────
  @override
  Stream<List<Indicator>> indicatorsStream({String? standardId}) =>
      _store.indicatorsStream(standardId: standardId);
  @override
  Future<void> saveIndicator(Indicator ind) => _store.saveIndicator(ind);
  @override
  Future<void> deleteIndicator(String id) => _store.deleteIndicator(id);

  // ── Actividades ──────────────────────────────────────────────────────────
  @override
  Stream<List<Activity>> activitiesStream({String? indicatorId}) =>
      _store.activitiesStream(indicatorId: indicatorId);
  @override
  Future<void> saveActivity(Activity act) => _store.saveActivity(act);
  @override
  Future<void> deleteActivity(String id) => _store.deleteActivity(id);

  // ── Configuración de evaluación ──────────────────────────────────────────
  @override
  Stream<List<EvaluationConfig>> evalConfigsStream() =>
      _store.evalConfigsStream();
  @override
  Future<void> saveEvalConfig(EvaluationConfig ec) => _store.saveEvalConfig(ec);

  // ── Notificaciones ───────────────────────────────────────────────────────
  @override
  Stream<List<AppNotification>> notificationsStream(String userId) =>
      _store.notificationsStream(userId);
  @override
  Future<void> saveNotification(AppNotification notif) =>
      _store.saveNotification(notif);
  @override
  Future<void> markNotificationRead(String userId, String notifId) =>
      _store.markNotificationRead(userId, notifId);

  // ── Asignaciones de asignaturas ──────────────────────────────────────────
  @override
  Stream<List<SubjectAssignment>> assignmentsStream({String? teacherId}) =>
      _store.assignmentsStream(teacherId: teacherId);
  @override
  Future<void> saveAssignment(SubjectAssignment a) => _store.saveAssignment(a);
  @override
  Future<void> deleteAssignment(String id) => _store.deleteAssignment(id);
}
