import '../../models/models.dart';
import '../data_repository.dart';
import 'mock_backend.dart';

/// Implementación de [DataRepository] con datos falsos en memoria — no
/// depende de Firestore. Los datos iniciales viven en mock_seed_data.dart;
/// las escrituras simulan latencia de red con Future.delayed.
class MockDataRepository implements DataRepository {
  final _backend = MockBackend.instance;

  // ── Usuarios ─────────────────────────────────────────────────────────────
  @override
  Stream<List<AppUser>> usersStream() => _backend.users.stream;

  @override
  Future<AppUser?> getUser(String uid) async {
    await MockBackend.delay();
    try {
      return _backend.users.value.firstWhere((u) => u.id == uid);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUser(String uid, AppUser user) async {
    await MockBackend.delay();
    _backend.users.upsert(user, (u) => u.id == uid);
  }

  @override
  Future<void> updateUserStatus(String uid, {required bool isActive}) async {
    await MockBackend.delay();
    final old = _backend.users.value.firstWhere((u) => u.id == uid);
    _backend.users.upsert(
      AppUser(
        id: old.id,
        name: old.name,
        email: old.email,
        password: '',
        role: old.role,
        avatar: old.avatar,
        isActive: isActive,
      ),
      (u) => u.id == uid,
    );
  }

  @override
  Future<void> deleteUser(String uid) async {
    await MockBackend.delay();
    _backend.users.removeWhere((u) => u.id == uid);
  }

  // ── Estudiantes ──────────────────────────────────────────────────────────
  @override
  Stream<List<Student>> studentsStream() => _backend.students.stream;

  @override
  Future<Student?> getStudent(String id) async {
    await MockBackend.delay();
    try {
      return _backend.students.value.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Student?> getStudentByUserId(String userId) async {
    await MockBackend.delay();
    try {
      return _backend.students.value.firstWhere((s) => s.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Student>> getStudentsByCourse(String courseId) async {
    await MockBackend.delay();
    return _backend.students.value
        .where((s) => s.courseId == courseId)
        .toList();
  }

  @override
  Future<void> saveStudent(Student student) async {
    await MockBackend.delay();
    _backend.students.upsert(student, (s) => s.id == student.id);
  }

  @override
  Future<void> deleteStudent(String id) async {
    await MockBackend.delay();
    _backend.students.removeWhere((s) => s.id == id);
  }

  // ── Docentes ─────────────────────────────────────────────────────────────
  @override
  Stream<List<Teacher>> teachersStream() => _backend.teachers.stream;

  @override
  Future<Teacher?> getTeacher(String id) async {
    await MockBackend.delay();
    try {
      return _backend.teachers.value.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Teacher?> getTeacherByUserId(String userId) async {
    await MockBackend.delay();
    try {
      return _backend.teachers.value.firstWhere((t) => t.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTeacher(Teacher teacher) async {
    await MockBackend.delay();
    _backend.teachers.upsert(teacher, (t) => t.id == teacher.id);
  }

  @override
  Future<void> deleteTeacher(String id) async {
    await MockBackend.delay();
    _backend.teachers.removeWhere((t) => t.id == id);
  }

  // ── Padres de familia ────────────────────────────────────────────────────
  @override
  Stream<List<Parent>> parentsStream() => _backend.parents.stream;

  @override
  Future<Parent?> getParentByUserId(String userId) async {
    await MockBackend.delay();
    try {
      return _backend.parents.value.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveParent(Parent parent) async {
    await MockBackend.delay();
    _backend.parents.upsert(parent, (p) => p.id == parent.id);
  }

  @override
  Future<void> deleteParent(String id) async {
    await MockBackend.delay();
    _backend.parents.removeWhere((p) => p.id == id);
  }

  // ── Cursos ───────────────────────────────────────────────────────────────
  @override
  Stream<List<Course>> coursesStream() => _backend.courses.stream;

  @override
  Future<void> saveCourse(Course course) async {
    await MockBackend.delay();
    _backend.courses.upsert(course, (c) => c.id == course.id);
  }

  @override
  Future<void> deleteCourse(String id) async {
    await MockBackend.delay();
    _backend.courses.removeWhere((c) => c.id == id);
  }

  // ── Asignaturas ──────────────────────────────────────────────────────────
  @override
  Stream<List<Subject>> subjectsStream() => _backend.subjects.stream;

  @override
  Future<void> saveSubject(Subject subject) async {
    await MockBackend.delay();
    _backend.subjects.upsert(subject, (s) => s.id == subject.id);
  }

  @override
  Future<void> deleteSubject(String id) async {
    await MockBackend.delay();
    _backend.subjects.removeWhere((s) => s.id == id);
  }

  // ── Años y períodos académicos ───────────────────────────────────────────
  @override
  Stream<List<AcademicYear>> academicYearsStream() => _backend.years.stream;

  @override
  Future<void> saveAcademicYear(AcademicYear year) async {
    await MockBackend.delay();
    _backend.years.upsert(year, (y) => y.id == year.id);
  }

  @override
  Stream<List<AcademicPeriod>> periodsStream({String? academicYearId}) {
    if (academicYearId == null) return _backend.periods.stream;
    return _backend.periods.stream.map(
      (list) => list.where((p) => p.academicYearId == academicYearId).toList(),
    );
  }

  @override
  Future<void> savePeriod(AcademicPeriod period) async {
    await MockBackend.delay();
    _backend.periods.upsert(period, (p) => p.id == period.id);
  }

  // ── Estándares de evaluación ─────────────────────────────────────────────
  @override
  Stream<List<Standard>> standardsStream({String? subjectId}) {
    if (subjectId == null) return _backend.standards.stream;
    return _backend.standards.stream.map(
      (list) => list.where((s) => s.subjectId == subjectId).toList(),
    );
  }

  @override
  Future<void> saveStandard(Standard standard) async {
    await MockBackend.delay();
    _backend.standards.upsert(standard, (s) => s.id == standard.id);
  }

  @override
  Future<void> deleteStandard(String id) async {
    await MockBackend.delay();
    _backend.standards.removeWhere((s) => s.id == id);
  }

  // ── Calificaciones ───────────────────────────────────────────────────────
  @override
  Stream<List<Grade>> gradesStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  }) {
    return _backend.grades.stream.map(
      (list) => list
          .where((g) => studentId == null || g.studentId == studentId)
          .where((g) => subjectId == null || g.subjectId == subjectId)
          .where((g) => periodId == null || g.periodId == periodId)
          .toList(),
    );
  }

  @override
  Future<void> saveGrade(Grade grade) async {
    await MockBackend.delay();
    _backend.grades.upsert(grade, (g) => g.id == grade.id);
  }

  @override
  Future<void> deleteGrade(String id) async {
    await MockBackend.delay();
    _backend.grades.removeWhere((g) => g.id == id);
  }

  // ── Asistencia ───────────────────────────────────────────────────────────
  @override
  Stream<List<AttendanceRecord>> attendanceStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  }) {
    return _backend.attendance.stream.map(
      (list) => list
          .where((a) => studentId == null || a.studentId == studentId)
          .where((a) => subjectId == null || a.subjectId == subjectId)
          .where((a) => periodId == null || a.periodId == periodId)
          .toList(),
    );
  }

  @override
  Future<void> saveAttendance(AttendanceRecord record) async {
    await MockBackend.delay();
    _backend.attendance.upsert(record, (a) => a.id == record.id);
  }

  @override
  Future<void> deleteAttendance(String id) async {
    await MockBackend.delay();
    _backend.attendance.removeWhere((a) => a.id == id);
  }

  // ── Observaciones ────────────────────────────────────────────────────────
  @override
  Stream<List<Observation>> observationsStream({String? studentId}) {
    final stream = _backend.observations.stream.map((list) {
      final sorted = List<Observation>.from(list)
        ..sort((a, b) => b.date.compareTo(a.date));
      return sorted;
    });
    if (studentId == null) return stream;
    return stream.map(
      (list) => list.where((o) => o.studentId == studentId).toList(),
    );
  }

  @override
  Future<void> saveObservation(Observation obs) async {
    await MockBackend.delay();
    _backend.observations.upsert(obs, (o) => o.id == obs.id);
  }

  @override
  Future<void> deleteObservation(String id) async {
    await MockBackend.delay();
    _backend.observations.removeWhere((o) => o.id == id);
  }

  // ── Comportamiento ───────────────────────────────────────────────────────
  @override
  Stream<List<BehaviorAssessment>> behaviorAssessmentsStream({
    String? studentId,
    String? periodId,
  }) {
    return _backend.behaviorAssessments.stream.map((list) {
      return list
          .where((b) => studentId == null || b.studentId == studentId)
          .where((b) => periodId == null || b.periodId == periodId)
          .toList();
    });
  }

  @override
  Future<void> saveBehaviorAssessment(BehaviorAssessment b) async {
    await MockBackend.delay();
    _backend.behaviorAssessments.upsert(b, (x) => x.id == b.id);
  }

  @override
  Future<void> deleteBehaviorAssessment(String id) async {
    await MockBackend.delay();
    _backend.behaviorAssessments.removeWhere((b) => b.id == id);
  }

  // ── Indicadores ──────────────────────────────────────────────────────────
  @override
  Stream<List<Indicator>> indicatorsStream({String? standardId}) {
    if (standardId == null) return _backend.indicators.stream;
    return _backend.indicators.stream.map(
      (list) => list.where((i) => i.standardId == standardId).toList(),
    );
  }

  @override
  Future<void> saveIndicator(Indicator ind) async {
    await MockBackend.delay();
    _backend.indicators.upsert(ind, (i) => i.id == ind.id);
  }

  @override
  Future<void> deleteIndicator(String id) async {
    await MockBackend.delay();
    _backend.indicators.removeWhere((i) => i.id == id);
  }

  // ── Actividades ──────────────────────────────────────────────────────────
  @override
  Stream<List<Activity>> activitiesStream({String? indicatorId}) {
    if (indicatorId == null) return _backend.activities.stream;
    return _backend.activities.stream.map(
      (list) => list.where((a) => a.indicatorId == indicatorId).toList(),
    );
  }

  @override
  Future<void> saveActivity(Activity act) async {
    await MockBackend.delay();
    _backend.activities.upsert(act, (a) => a.id == act.id);
  }

  @override
  Future<void> deleteActivity(String id) async {
    await MockBackend.delay();
    _backend.activities.removeWhere((a) => a.id == id);
  }

  // ── Configuración de evaluación ──────────────────────────────────────────
  @override
  Stream<List<EvaluationConfig>> evalConfigsStream() =>
      _backend.evalConfigs.stream;

  @override
  Future<void> saveEvalConfig(EvaluationConfig ec) async {
    await MockBackend.delay();
    _backend.evalConfigs.upsert(ec, (e) => e.id == ec.id);
  }

  // ── Notificaciones ───────────────────────────────────────────────────────
  @override
  Stream<List<AppNotification>> notificationsStream(String userId) =>
      _backend.notificationsFor(userId).stream;

  @override
  Future<void> saveNotification(AppNotification notif) async {
    await MockBackend.delay();
    _backend
        .notificationsFor(notif.userId)
        .upsert(notif, (n) => n.id == notif.id);
  }

  @override
  Future<void> markNotificationRead(String userId, String notifId) async {
    await MockBackend.delay();
    final list = _backend.notificationsFor(userId);
    final old = list.value.firstWhere((n) => n.id == notifId);
    old.isRead = true;
    list.upsert(old, (n) => n.id == notifId);
  }

  // ── Asignaciones de asignaturas ──────────────────────────────────────────
  @override
  Stream<List<SubjectAssignment>> assignmentsStream({String? teacherId}) {
    if (teacherId == null) return _backend.assignments.stream;
    return _backend.assignments.stream.map(
      (list) => list.where((a) => a.teacherId == teacherId).toList(),
    );
  }

  @override
  Future<void> saveAssignment(SubjectAssignment a) async {
    await MockBackend.delay();
    _backend.assignments.upsert(a, (x) => x.id == a.id);
  }

  @override
  Future<void> deleteAssignment(String id) async {
    await MockBackend.delay();
    _backend.assignments.removeWhere((a) => a.id == id);
  }
}
