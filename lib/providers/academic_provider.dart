import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class AcademicProvider extends ChangeNotifier {
  final FirestoreService _store = FirestoreService();

  List<AcademicYear> _years = [];
  List<AcademicPeriod> _periods = [];
  List<Subject> _subjects = [];
  List<Standard> _standards = [];
  List<Course> _courses = [];
  List<Teacher> _teachers = [];
  List<Student> _students = [];
  List<Parent> _parents = [];
  List<Grade> _grades = [];
  List<AttendanceRecord> _attendance = [];
  List<Observation> _observations = [];
  final List<AppNotification> _notifications = [];
  List<SubjectAssignment> _assignments = [];
  List<EvaluationConfig> _evalConfigs = [];
  List<AppUser> _users = [];
  List<Indicator> _indicators = [];
  List<Activity> _activities = [];
  final Map<String, ExtendedProfile> _profiles = {};

  AcademicYear? _activeYear;
  String? _notifUserId;
  StreamSubscription? _notifSub;
  final List<StreamSubscription> _subs = [];

  AcademicProvider() {
    _subs.addAll([
      _store.academicYearsStream().listen((v) { _years = v; notifyListeners(); }),
      _store.periodsStream().listen((v) { _periods = v; notifyListeners(); }),
      _store.subjectsStream().listen((v) { _subjects = v; notifyListeners(); }),
      _store.standardsStream().listen((v) { _standards = v; notifyListeners(); }),
      _store.coursesStream().listen((v) { _courses = v; notifyListeners(); }),
      _store.teachersStream().listen((v) { _teachers = v; notifyListeners(); }),
      _store.studentsStream().listen((v) { _students = v; notifyListeners(); }),
      _store.parentsStream().listen((v) { _parents = v; notifyListeners(); }),
      _store.gradesStream().listen((v) { _grades = v; notifyListeners(); }),
      _store.attendanceStream().listen((v) { _attendance = v; notifyListeners(); }),
      _store.observationsStream().listen((v) { _observations = v; notifyListeners(); }),
      _store.assignmentsStream().listen((v) { _assignments = v; notifyListeners(); }),
      _store.evalConfigsStream().listen((v) { _evalConfigs = v; notifyListeners(); }),
      _store.usersStream().listen((v) { _users = v; notifyListeners(); }),
      _store.indicatorsStream().listen((v) { _indicators = v; notifyListeners(); }),
      _store.activitiesStream().listen((v) { _activities = v; notifyListeners(); }),
    ]);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _notifSub?.cancel();
    super.dispose();
  }

  // Suscribe (una sola vez por usuario) a las notificaciones del usuario
  // autenticado. Las notificaciones viven en una subcolección por usuario
  // en Firestore, por lo que requieren saber qué usuario está activo.
  void listenNotificationsFor(String userId) {
    if (_notifUserId == userId) return;
    _notifUserId = userId;
    _notifSub?.cancel();
    _notifSub = _store.notificationsStream(userId).listen((list) {
      _notifications.removeWhere((n) => n.userId == userId);
      _notifications.addAll(list);
      notifyListeners();
    });
  }

  List<AcademicYear> get years => _years;
  List<AcademicPeriod> get periods => _periods;
  List<Subject> get subjects => _subjects;
  List<Standard> get standards => _standards;
  List<Course> get courses => _courses;
  List<Teacher> get teachers => _teachers;
  List<Student> get students => _students;
  List<Parent> get parents => _parents;
  List<Grade> get grades => _grades;
  List<AttendanceRecord> get attendance => _attendance;
  List<Observation> get observations => _observations;
  List<AppNotification> get notifications => _notifications;
  List<SubjectAssignment> get assignments => _assignments;
  List<EvaluationConfig> get evalConfigs => _evalConfigs;
  List<AppUser> get users => _users;

  AcademicYear get activeYear =>
      _activeYear ??
      _years.firstWhere((y) => y.isActive, orElse: () => _years.first);

  List<AcademicPeriod> get activePeriods =>
      _periods.where((p) => p.academicYearId == activeYear.id).toList();

  AcademicPeriod? get currentOpenPeriod {
    final now = DateTime.now();
    // Preferir el período abierto cuyas fechas incluyan la fecha actual
    try {
      return activePeriods.firstWhere(
        (p) => p.isOpen && !p.startDate.isAfter(now) && !p.endDate.isBefore(now),
      );
    } catch (_) {}
    // Fallback: cualquier período abierto
    try {
      return activePeriods.firstWhere((p) => p.isOpen);
    } catch (_) {
      return null;
    }
  }

  List<Student> studentsInCourse(String courseId) =>
      _students.where((s) => s.courseId == courseId).toList();

  List<Grade> gradesForStudent(String studentId) =>
      _grades.where((g) => g.studentId == studentId).toList();

  List<Grade> gradesForStudentSubjectPeriod(
    String studentId,
    String subjectId,
    String periodId,
  ) => _grades
      .where(
        (g) =>
            g.studentId == studentId &&
            g.subjectId == subjectId &&
            g.periodId == periodId,
      )
      .toList();

  List<AttendanceRecord> attendanceForStudent(String studentId) =>
      _attendance.where((a) => a.studentId == studentId).toList();

  List<Observation> observationsForStudent(String studentId) =>
      _observations.where((o) => o.studentId == studentId).toList();

  List<AppNotification> notificationsForUser(String userId) =>
      _notifications.where((n) => n.userId == userId).toList();

  List<SubjectAssignment> assignmentsForTeacher(String teacherId) =>
      _assignments.where((a) => a.teacherId == teacherId).toList();

  List<Subject> subjectsForCourse(String courseId) {
    final ids = _assignments.where((a) => a.courseId == courseId).map((a) => a.subjectId).toSet();
    return _subjects.where((s) => ids.contains(s.id)).toList();
  }

  List<Subject> subjectsForCourseAndTeacher(String courseId, String teacherId) {
    final ids = _assignments
        .where((a) => a.courseId == courseId && a.teacherId == teacherId)
        .map((a) => a.subjectId)
        .toSet();
    return _subjects.where((s) => ids.contains(s.id)).toList();
  }

  List<Standard> standardsForSubject(String subjectId) =>
      _standards.where((s) => s.subjectId == subjectId).toList();

  List<Standard> standardsForSubjectAndPeriod(
    String subjectId,
    String periodId,
  ) => _standards
      .where((s) => s.subjectId == subjectId && s.periodId == periodId)
      .toList();

  List<Indicator> indicatorsForStandard(String standardId) =>
      _indicators.where((i) => i.standardId == standardId).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<Activity> activitiesForIndicator(String indicatorId) =>
      _activities.where((a) => a.indicatorId == indicatorId).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  double? calculateIndicatorGrade(String indicatorId) {
    final programmed = _activities
        .where((a) => a.indicatorId == indicatorId && a.isProgrammed && a.gradeValue != null)
        .toList();
    if (programmed.isEmpty) return null;
    return programmed.map((a) => a.gradeValue!).reduce((a, b) => a + b) / programmed.length;
  }

  // Promedio de las notas (hasta 3 casillas) que un estudiante tiene
  // registradas para un indicador, ignorando las casillas no diligenciadas.
  double? indicatorGradeForStudent(
    String studentId,
    String subjectId,
    String periodId,
    String indicatorId,
  ) {
    final values = _grades
        .where(
          (g) =>
              g.studentId == studentId &&
              g.subjectId == subjectId &&
              g.periodId == periodId &&
              g.indicatorId == indicatorId,
        )
        .map((g) => g.value)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // Promedio simple de los indicadores de un estándar para un estudiante,
  // ignorando los indicadores que aún no tienen ninguna nota registrada.
  double? standardGradeForStudent(
    String studentId,
    String subjectId,
    String periodId,
    String standardId,
  ) {
    final indicators = indicatorsForStandard(standardId);
    if (indicators.isEmpty) return null;
    final scores = indicators
        .map(
          (ind) =>
              indicatorGradeForStudent(studentId, subjectId, periodId, ind.id),
        )
        .whereType<double>()
        .toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  void addStandard(Standard s) {
    _store.saveStandard(s);
  }

  void updateStandard(String id, {required String name, required String description, required double weight}) {
    final old = _standards.firstWhere((s) => s.id == id, orElse: () => Standard(id: id, subjectId: '', name: '', description: '', weight: 0));
    _store.saveStandard(Standard(
      id: old.id,
      subjectId: old.subjectId,
      periodId: old.periodId,
      name: name,
      description: description,
      weight: weight,
    ));
  }

  void updateIndicator(String id, {required String name, required String description}) {
    final old = _indicators.firstWhere((i) => i.id == id, orElse: () => Indicator(id: id, standardId: '', name: '', description: '', order: 0));
    _store.saveIndicator(Indicator(
      id: old.id,
      standardId: old.standardId,
      name: name,
      description: description,
      order: old.order,
    ));
  }

  void deleteStandard(String id) {
    final indicatorIds = _indicators.where((i) => i.standardId == id).map((i) => i.id).toList();
    for (final indId in indicatorIds) {
      for (final act in _activities.where((a) => a.indicatorId == indId)) {
        _store.deleteActivity(act.id);
      }
      _store.deleteIndicator(indId);
    }
    _store.deleteStandard(id);
  }

  void addIndicator(Indicator ind) {
    _store.saveIndicator(ind);
  }

  void deleteIndicator(String id) {
    for (final act in _activities.where((a) => a.indicatorId == id)) {
      _store.deleteActivity(act.id);
    }
    _store.deleteIndicator(id);
  }

  void addActivity(Activity act) {
    _store.saveActivity(act);
  }

  void deleteActivity(String id) {
    _store.deleteActivity(id);
  }

  void toggleActivityProgrammed(String id) {
    final act = _activities.firstWhere((a) => a.id == id);
    final newProgrammed = !act.isProgrammed;
    _store.saveActivity(Activity(
      id: act.id,
      indicatorId: act.indicatorId,
      name: act.name,
      description: act.description,
      order: act.order,
      isProgrammed: newProgrammed,
      gradeValue: newProgrammed ? act.gradeValue : null,
    ));
  }

  void setActivityGrade(String id, double? grade) {
    final act = _activities.firstWhere((a) => a.id == id);
    _store.saveActivity(Activity(
      id: act.id,
      indicatorId: act.indicatorId,
      name: act.name,
      description: act.description,
      order: act.order,
      isProgrammed: act.isProgrammed,
      gradeValue: grade,
    ));
  }

  EvaluationConfig? evalConfigFor(String subjectId, String periodId) {
    try {
      return _evalConfigs.firstWhere(
        (ec) => ec.subjectId == subjectId && ec.periodId == periodId,
      );
    } catch (_) {
      return null;
    }
  }

  Teacher? teacherByUserId(String userId) {
    try {
      return _teachers.firstWhere((t) => t.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Student? studentByUserId(String userId) {
    try {
      return _students.firstWhere((s) => s.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Parent? parentByUserId(String userId) {
    try {
      return _parents.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  double calculateSubjectPeriodGrade(
    String studentId,
    String subjectId,
    String periodId,
  ) {
    final config = evalConfigFor(subjectId, periodId);
    final subjectStandards = standardsForSubjectAndPeriod(subjectId, periodId);
    final gradesList = gradesForStudentSubjectPeriod(
      studentId,
      subjectId,
      periodId,
    );

    if (gradesList.isEmpty) return 0.0;

    double? finalExamValue;
    try {
      finalExamValue = gradesList.firstWhere((g) => g.standardId == null).value;
    } catch (_) {
      finalExamValue = null;
    }

    double? standardsAvg;
    if (subjectStandards.isNotEmpty) {
      double weightedSum = 0.0;
      double totalWeight = 0.0;
      for (final std in subjectStandards) {
        final score = standardGradeForStudent(
          studentId,
          subjectId,
          periodId,
          std.id,
        );
        if (score != null) {
          weightedSum += score * std.weight;
          totalWeight += std.weight;
        }
      }
      if (totalWeight > 0) standardsAvg = weightedSum / totalWeight;
    }

    final sw = config?.standardsWeight ?? 70;
    final fw = config?.finalExamWeight ?? 30;

    // Si falta la nota de estándares o la de evaluación final, esa parte no
    // se tiene en cuenta (no se asume 0) y se usa solo la parte disponible.
    if (standardsAvg != null && finalExamValue != null) {
      return (standardsAvg * sw / 100) + (finalExamValue * fw / 100);
    } else if (standardsAvg != null) {
      return standardsAvg;
    } else if (finalExamValue != null) {
      return finalExamValue;
    }
    return 0.0;
  }

  double calculateOverallAverage(String studentId, String periodId) {
    Student? student;
    try {
      student = _students.firstWhere((s) => s.id == studentId);
    } catch (_) {
      return 0.0;
    }
    if (student.courseId == null) return 0.0;
    final courseSubjects = subjectsForCourse(student.courseId!);
    if (courseSubjects.isEmpty) return 0.0;
    double total = 0.0;
    int count = 0;
    for (final sub in courseSubjects) {
      final g = calculateSubjectPeriodGrade(studentId, sub.id, periodId);
      if (g > 0) {
        total += g;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  int rankInCourse(String studentId, String courseId, String periodId) {
    final courseStudents = studentsInCourse(courseId);
    final courseSubjects = subjectsForCourse(courseId);

    double avgFor(String sid) {
      final gs = courseSubjects
          .map((s) => calculateSubjectPeriodGrade(sid, s.id, periodId))
          .where((g) => g > 0)
          .toList();
      return gs.isEmpty ? 0.0 : gs.reduce((a, b) => a + b) / gs.length;
    }

    final sorted = courseStudents.toList()
      ..sort((a, b) => avgFor(b.id).compareTo(avgFor(a.id)));
    final idx = sorted.indexWhere((s) => s.id == studentId);
    return idx < 0 ? courseStudents.length : idx + 1;
  }

  double overallAverageForPeriod(String studentId, String courseId, String periodId) {
    final subjects = subjectsForCourse(courseId);
    final gs = subjects
        .map((s) => calculateSubjectPeriodGrade(studentId, s.id, periodId))
        .where((g) => g > 0)
        .toList();
    return gs.isEmpty ? 0.0 : gs.reduce((a, b) => a + b) / gs.length;
  }

  List<Student> studentsForParent(String parentId) =>
      _students.where((s) => s.parentIds.contains(parentId)).toList();

  ExtendedProfile profileFor(String entityId) =>
      _profiles[entityId] ??= ExtendedProfile();

  void saveProfile(String entityId, ExtendedProfile profile) {
    _profiles[entityId] = profile;
    notifyListeners();
  }

  int get totalStudents => _students.length;
  int get totalTeachers => _teachers.length;
  int get totalCourses => _courses.length;
  int get totalSubjects => _subjects.length;

  double get institutionalAverage {
    final period = currentOpenPeriod;
    if (period == null) return 0.0;
    double total = 0;
    int count = 0;
    for (final student in _students) {
      if (student.courseId == null) continue;
      final avg = overallAverageForPeriod(student.id, student.courseId!, period.id);
      if (avg > 0) {
        total += avg;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  void addSubject(Subject subject) {
    _store.saveSubject(subject);
  }

  void addUser(AppUser user) {
    _store.saveUser(user.id, user);
  }

  void addTeacher(Teacher teacher) {
    _store.saveTeacher(teacher);
  }

  void addAssignment(SubjectAssignment assignment) {
    _store.saveAssignment(assignment);
  }

  void deleteAssignment(String id) {
    _store.deleteAssignment(id);
  }

  // Asigna (o quita, con teacherId = null) la dirección de grupo de un curso.
  void setCourseDirector(String courseId, String? teacherId) {
    final course = courseById(courseId);
    if (course == null) return;
    _store.saveCourse(Course(
      id: course.id,
      name: course.name,
      grade: course.grade,
      section: course.section,
      academicYearId: course.academicYearId,
      directorTeacherId: teacherId,
    ));
  }

  void addStudent(Student student) {
    _store.saveStudent(student);
  }

  void addParent(Parent parent) {
    _store.saveParent(parent);
  }

  Student? studentById(String id) {
    try {
      return _students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Parent? parentById(String id) {
    try {
      return _parents.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Actualiza datos básicos de un estudiante ya registrado (documento,
  // fecha de nacimiento, curso), preservando sus vínculos con acudientes.
  void updateStudent(Student student) {
    _store.saveStudent(student);
  }

  // Vincula un acudiente (padre/madre/tutor) con un estudiante en ambos
  // sentidos, ya que Student.parentIds y Parent.studentIds se mantienen
  // por separado en Firestore.
  void linkParentToStudent(String studentId, String parentId) {
    final student = studentById(studentId);
    final parent = parentById(parentId);
    if (student == null || parent == null) return;
    if (!student.parentIds.contains(parentId)) {
      _store.saveStudent(Student(
        id: student.id,
        userId: student.userId,
        firstName: student.firstName,
        lastName: student.lastName,
        documentId: student.documentId,
        birthDate: student.birthDate,
        courseId: student.courseId,
        parentIds: [...student.parentIds, parentId],
      ));
    }
    if (!parent.studentIds.contains(studentId)) {
      _store.saveParent(Parent(
        id: parent.id,
        userId: parent.userId,
        firstName: parent.firstName,
        lastName: parent.lastName,
        documentId: parent.documentId,
        phone: parent.phone,
        relationship: parent.relationship,
        studentIds: [...parent.studentIds, studentId],
      ));
    }
  }

  void unlinkParentFromStudent(String studentId, String parentId) {
    final student = studentById(studentId);
    final parent = parentById(parentId);
    if (student != null && student.parentIds.contains(parentId)) {
      _store.saveStudent(Student(
        id: student.id,
        userId: student.userId,
        firstName: student.firstName,
        lastName: student.lastName,
        documentId: student.documentId,
        birthDate: student.birthDate,
        courseId: student.courseId,
        parentIds: student.parentIds.where((id) => id != parentId).toList(),
      ));
    }
    if (parent != null && parent.studentIds.contains(studentId)) {
      _store.saveParent(Parent(
        id: parent.id,
        userId: parent.userId,
        firstName: parent.firstName,
        lastName: parent.lastName,
        documentId: parent.documentId,
        phone: parent.phone,
        relationship: parent.relationship,
        studentIds: parent.studentIds.where((id) => id != studentId).toList(),
      ));
    }
  }

  void addGrade(Grade grade) {
    final existing = _grades.where(
      (g) =>
          g.studentId == grade.studentId &&
          g.subjectId == grade.subjectId &&
          g.periodId == grade.periodId &&
          g.standardId == grade.standardId &&
          g.indicatorId == grade.indicatorId &&
          g.slot == grade.slot,
    ).toList();
    for (final g in existing) {
      if (g.id != grade.id) _store.deleteGrade(g.id);
    }
    _store.saveGrade(grade);
  }

  void addObservation(Observation obs) {
    _store.saveObservation(obs);
  }

  void addAttendance(AttendanceRecord record) {
    _store.saveAttendance(record);
  }

  void markNotificationRead(String notificationId) {
    final n = _notifications.firstWhere((n) => n.id == notificationId, orElse: () => AppNotification(id: '', userId: '', title: '', message: '', type: NotificationType.general, createdAt: DateTime.now()));
    if (n.id.isEmpty) return;
    n.isRead = true;
    notifyListeners();
    _store.markNotificationRead(n.userId, notificationId);
  }

  int unreadNotificationsCount(String userId) =>
      _notifications.where((n) => n.userId == userId && !n.isRead).length;

  Subject? subjectById(String id) {
    try {
      return _subjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Course? courseById(String id) {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Teacher? teacherById(String id) {
    try {
      return _teachers.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  AcademicPeriod? periodById(String id) {
    try {
      return _periods.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
