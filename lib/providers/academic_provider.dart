import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class AcademicProvider extends ChangeNotifier {
  final List<AcademicYear> _years = List.from(MockData.academicYears);
  final List<AcademicPeriod> _periods = List.from(MockData.academicPeriods);
  final List<Subject> _subjects = List.from(MockData.subjects);
  final List<Standard> _standards = List.from(MockData.standards);
  final List<Course> _courses = List.from(MockData.courses);
  final List<Teacher> _teachers = List.from(MockData.teachers);
  final List<Student> _students = List.from(MockData.students);
  final List<Parent> _parents = List.from(MockData.parents);
  final List<Grade> _grades = List.from(MockData.grades);
  final List<AttendanceRecord> _attendance = List.from(MockData.attendance);
  final List<Observation> _observations = List.from(MockData.observations);
  final List<AppNotification> _notifications = List.from(
    MockData.notifications,
  );
  final List<SubjectAssignment> _assignments = List.from(MockData.assignments);
  final List<EvaluationConfig> _evalConfigs = List.from(MockData.evalConfigs);
  final List<AppUser> _users = List.from(MockData.users);
  final List<Indicator> _indicators = [];
  final List<Activity> _activities = [];
  final Map<String, ExtendedProfile> _profiles = {};

  AcademicYear? _activeYear;

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

  void addStandard(Standard s) {
    _standards.add(s);
    notifyListeners();
  }

  void deleteStandard(String id) {
    _standards.removeWhere((s) => s.id == id);
    final indicatorIds = _indicators
        .where((i) => i.standardId == id)
        .map((i) => i.id)
        .toList();
    _indicators.removeWhere((i) => i.standardId == id);
    _activities.removeWhere((a) => indicatorIds.contains(a.indicatorId));
    notifyListeners();
  }

  void addIndicator(Indicator ind) {
    _indicators.add(ind);
    notifyListeners();
  }

  void deleteIndicator(String id) {
    _indicators.removeWhere((i) => i.id == id);
    _activities.removeWhere((a) => a.indicatorId == id);
    notifyListeners();
  }

  void addActivity(Activity act) {
    _activities.add(act);
    notifyListeners();
  }

  void deleteActivity(String id) {
    _activities.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void toggleActivityProgrammed(String id) {
    final act = _activities.firstWhere((a) => a.id == id);
    act.isProgrammed = !act.isProgrammed;
    if (!act.isProgrammed) act.gradeValue = null;
    notifyListeners();
  }

  void setActivityGrade(String id, double? grade) {
    final act = _activities.firstWhere((a) => a.id == id);
    act.gradeValue = grade;
    notifyListeners();
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
    final subjectStandards = standardsForSubject(subjectId);
    final gradesList = gradesForStudentSubjectPeriod(
      studentId,
      subjectId,
      periodId,
    );

    if (gradesList.isEmpty) return 0.0;

    final finalExamGrade = gradesList.firstWhere(
      (g) => g.standardId == null,
      orElse: () => Grade(
        id: '',
        studentId: studentId,
        subjectId: subjectId,
        periodId: periodId,
        value: 0,
        registeredAt: DateTime.now(),
      ),
    );

    double standardsAvg = 0.0;
    if (subjectStandards.isNotEmpty) {
      double weightedSum = 0.0;
      double totalWeight = 0.0;
      for (final std in subjectStandards) {
        try {
          final g = gradesList.firstWhere((gr) => gr.standardId == std.id);
          weightedSum += g.value * std.weight;
          totalWeight += std.weight;
        } catch (_) {}
      }
      if (totalWeight > 0) standardsAvg = weightedSum / totalWeight;
    }

    final sw = config?.standardsWeight ?? 70;
    final fw = config?.finalExamWeight ?? 30;
    return (standardsAvg * sw / 100) + (finalExamGrade.value * fw / 100);
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
    _subjects.add(subject);
    notifyListeners();
  }

  void addUser(AppUser user) {
    _users.add(user);
    notifyListeners();
  }

  void addTeacher(Teacher teacher) {
    _teachers.add(teacher);
    notifyListeners();
  }

  void addStudent(Student student) {
    _students.add(student);
    notifyListeners();
  }

  void addParent(Parent parent) {
    _parents.add(parent);
    notifyListeners();
  }

  void addGrade(Grade grade) {
    _grades.removeWhere(
      (g) =>
          g.studentId == grade.studentId &&
          g.subjectId == grade.subjectId &&
          g.periodId == grade.periodId &&
          g.standardId == grade.standardId,
    );
    _grades.add(grade);
    notifyListeners();
  }

  void addObservation(Observation obs) {
    _observations.add(obs);
    notifyListeners();
  }

  void addAttendance(AttendanceRecord record) {
    _attendance.add(record);
    notifyListeners();
  }

  void markNotificationRead(String notificationId) {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
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
