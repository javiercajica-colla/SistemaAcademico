import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class AcademicProvider extends ChangeNotifier {
  List<AcademicYear> _years = List.from(MockData.academicYears);
  List<AcademicPeriod> _periods = List.from(MockData.academicPeriods);
  List<Subject> _subjects = List.from(MockData.subjects);
  List<Standard> _standards = List.from(MockData.standards);
  List<Course> _courses = List.from(MockData.courses);
  List<Teacher> _teachers = List.from(MockData.teachers);
  List<Student> _students = List.from(MockData.students);
  List<Parent> _parents = List.from(MockData.parents);
  List<Grade> _grades = List.from(MockData.grades);
  List<AttendanceRecord> _attendance = List.from(MockData.attendance);
  List<Observation> _observations = List.from(MockData.observations);
  List<AppNotification> _notifications = List.from(MockData.notifications);
  List<SubjectAssignment> _assignments = List.from(MockData.assignments);
  List<EvaluationConfig> _evalConfigs = List.from(MockData.evalConfigs);
  List<AppUser> _users = List.from(MockData.users);

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

  AcademicYear get activeYear => _activeYear ?? _years.firstWhere((y) => y.isActive, orElse: () => _years.first);

  List<AcademicPeriod> get activePeriods => _periods.where((p) => p.academicYearId == activeYear.id).toList();

  AcademicPeriod? get currentOpenPeriod {
    try {
      return activePeriods.firstWhere((p) => p.isOpen);
    } catch (_) {
      return null;
    }
  }

  List<Student> studentsInCourse(String courseId) => _students.where((s) => s.courseId == courseId).toList();

  List<Grade> gradesForStudent(String studentId) => _grades.where((g) => g.studentId == studentId).toList();

  List<Grade> gradesForStudentSubjectPeriod(String studentId, String subjectId, String periodId) =>
      _grades.where((g) => g.studentId == studentId && g.subjectId == subjectId && g.periodId == periodId).toList();

  List<AttendanceRecord> attendanceForStudent(String studentId) => _attendance.where((a) => a.studentId == studentId).toList();

  List<Observation> observationsForStudent(String studentId) => _observations.where((o) => o.studentId == studentId).toList();

  List<AppNotification> notificationsForUser(String userId) => _notifications.where((n) => n.userId == userId).toList();

  List<SubjectAssignment> assignmentsForTeacher(String teacherId) => _assignments.where((a) => a.teacherId == teacherId).toList();

  List<Standard> standardsForSubject(String subjectId) => _standards.where((s) => s.subjectId == subjectId).toList();

  EvaluationConfig? evalConfigFor(String subjectId, String periodId) {
    try {
      return _evalConfigs.firstWhere((ec) => ec.subjectId == subjectId && ec.periodId == periodId);
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

  double calculateSubjectPeriodGrade(String studentId, String subjectId, String periodId) {
    final config = evalConfigFor(subjectId, periodId);
    final subjectStandards = standardsForSubject(subjectId);
    final gradesList = gradesForStudentSubjectPeriod(studentId, subjectId, periodId);

    if (gradesList.isEmpty) return 0.0;

    final finalExamGrade = gradesList.firstWhere((g) => g.standardId == null, orElse: () => Grade(
      id: '', studentId: studentId, subjectId: subjectId, periodId: periodId,
      value: 0, registeredAt: DateTime.now(),
    ));

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
    final assignedSubjects = subjects.where((s) => students.any((st) => st.id == studentId && st.courseId != null)).toList();
    if (assignedSubjects.isEmpty) return 0.0;
    double total = 0.0;
    int count = 0;
    for (final sub in assignedSubjects.take(6)) {
      final g = calculateSubjectPeriodGrade(studentId, sub.id, periodId);
      if (g > 0) {
        total += g;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  int get totalStudents => _students.length;
  int get totalTeachers => _teachers.length;
  int get totalCourses => _courses.length;
  int get totalSubjects => _subjects.length;

  double get institutionalAverage {
    double total = 0;
    int count = 0;
    for (final student in _students) {
      final avg = calculateOverallAverage(student.id, 'ap1');
      if (avg > 0) {
        total += avg;
        count++;
      }
    }
    return count > 0 ? total / count : 0.0;
  }

  void addGrade(Grade grade) {
    _grades.removeWhere((g) =>
        g.studentId == grade.studentId &&
        g.subjectId == grade.subjectId &&
        g.periodId == grade.periodId &&
        g.standardId == grade.standardId);
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
