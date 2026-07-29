import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/utils/grade_scale.dart';
import '../models/models.dart';
import '../repositories/repository_provider.dart';

class CourseReportRow {
  final Student student;
  final Map<String, double> gradeBySubjectId;
  final double average;
  final int rank;

  const CourseReportRow({
    required this.student,
    required this.gradeBySubjectId,
    required this.average,
    required this.rank,
  });
}

class CourseAreaReportRow {
  final Student student;
  final Map<String, double> gradeByArea;
  final double average;
  final int rank;

  const CourseAreaReportRow({
    required this.student,
    required this.gradeByArea,
    required this.average,
    required this.rank,
  });
}

class AcademicProvider extends ChangeNotifier {
  final _store = dataRepository;

  List<AcademicYear> _years = [];
  List<AcademicPeriod> _periods = [];
  List<Subject> _subjects = [];
  List<Course> _courses = [];
  List<Teacher> _teachers = [];
  List<Student> _students = [];
  List<Parent> _parents = [];
  List<Grade> _grades = [];
  List<AttendanceRecord> _attendance = [];
  List<Observation> _observations = [];
  List<BehaviorAssessment> _behaviorAssessments = [];
  final List<AppNotification> _notifications = [];
  List<SubjectAssignment> _assignments = [];
  List<EvaluationConfig> _evalConfigs = [];
  List<AppUser> _users = [];
  List<Estandar> _estandares = [];
  List<Competencia> _competencias = [];
  List<Actividad> _actividades = [];
  final Map<String, ExtendedProfile> _profiles = {};

  AcademicYear? _activeYear;
  String? _notifUserId;
  StreamSubscription? _notifSub;
  final List<StreamSubscription> _subs = [];

  AcademicProvider() {
    _subs.addAll([
      _store.academicYearsStream().listen((v) {
        _years = v;
        notifyListeners();
      }),
      _store.periodsStream().listen((v) {
        _periods = v;
        notifyListeners();
      }),
      _store.subjectsStream().listen((v) {
        _subjects = v;
        notifyListeners();
      }),
      _store.coursesStream().listen((v) {
        _courses = v;
        notifyListeners();
      }),
      _store.teachersStream().listen((v) {
        _teachers = v;
        notifyListeners();
      }),
      _store.studentsStream().listen((v) {
        _students = v;
        notifyListeners();
      }),
      _store.parentsStream().listen((v) {
        _parents = v;
        notifyListeners();
      }),
      _store.gradesStream().listen((v) {
        _grades = v;
        notifyListeners();
      }),
      _store.attendanceStream().listen((v) {
        _attendance = v;
        notifyListeners();
      }),
      _store.observationsStream().listen((v) {
        _observations = v;
        notifyListeners();
      }),
      _store.behaviorAssessmentsStream().listen((v) {
        _behaviorAssessments = v;
        notifyListeners();
      }),
      _store.assignmentsStream().listen((v) {
        _assignments = v;
        notifyListeners();
      }),
      _store.evalConfigsStream().listen((v) {
        _evalConfigs = v;
        notifyListeners();
      }),
      _store.usersStream().listen((v) {
        _users = v;
        notifyListeners();
      }),
      _store.estandaresStream().listen((v) {
        _estandares = v;
        notifyListeners();
      }),
      _store.competenciasStream().listen((v) {
        _competencias = v;
        notifyListeners();
      }),
      _store.actividadesStream().listen((v) {
        _actividades = v;
        notifyListeners();
      }),
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
  List<Course> get courses => _courses;
  List<Teacher> get teachers => _teachers;
  List<Student> get students => _students;
  List<Parent> get parents => _parents;
  List<Grade> get grades => _grades;
  List<AttendanceRecord> get attendance => _attendance;
  List<Observation> get observations => _observations;
  List<BehaviorAssessment> get behaviorAssessments => _behaviorAssessments;
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
        (p) =>
            p.isOpen && !p.startDate.isAfter(now) && !p.endDate.isBefore(now),
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
    final ids = _assignments
        .where((a) => a.courseId == courseId)
        .map((a) => a.subjectId)
        .toSet();
    return _subjects.where((s) => ids.contains(s.id)).toList();
  }

  List<Subject> subjectsForCourseAndTeacher(String courseId, String teacherId) {
    final ids = _assignments
        .where((a) => a.courseId == courseId && a.teacherId == teacherId)
        .map((a) => a.subjectId)
        .toSet();
    return _subjects.where((s) => ids.contains(s.id)).toList();
  }

  // ── Estándar → Competencia → Actividad ───────────────────────────────────
  // Un Estándar se define una vez por año lectivo
  // (no por período); sus Competencias sí son por período y no es
  // obligatorio que un Estándar tenga competencias en todos los períodos.

  List<Estandar> estandaresForSubject(String subjectId) =>
      _estandares
          .where(
            (e) => e.subjectId == subjectId && e.academicYearId == activeYear.id,
          )
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<Competencia> competenciasForEstandarAndPeriod(
    String estandarId,
    String periodId,
  ) =>
      _competencias
          .where((c) => c.estandarId == estandarId && c.periodId == periodId)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  List<Competencia> competenciasForSubjectAndPeriod(
    String subjectId,
    String periodId,
  ) {
    final estandarIds = estandaresForSubject(subjectId).map((e) => e.id).toSet();
    return _competencias
        .where((c) => estandarIds.contains(c.estandarId) && c.periodId == periodId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  List<Actividad> actividadesForCompetencia(String competenciaId) =>
      _actividades.where((a) => a.competenciaId == competenciaId).toList()
        ..sort((a, b) => a.order.compareTo(b.order));

  // Promedio de las notas (hasta 6 actividades) que un estudiante tiene
  // registradas para una competencia, ignorando actividades sin nota.
  double? competenciaGradeForStudent(
    String studentId,
    String subjectId,
    String periodId,
    String competenciaId,
  ) {
    final values = _grades
        .where(
          (g) =>
              g.studentId == studentId &&
              g.subjectId == subjectId &&
              g.periodId == periodId &&
              g.competenciaId == competenciaId,
        )
        .map((g) => g.value)
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// `null` = todavía sin notas suficientes para decidir. La competencia se
  /// considera alcanzada si su promedio llega al menos a `GradeScale.basico`.
  bool? competenciaAlcanzada(
    String studentId,
    String subjectId,
    String periodId,
    String competenciaId,
  ) {
    final grade = competenciaGradeForStudent(
      studentId,
      subjectId,
      periodId,
      competenciaId,
    );
    if (grade == null) return null;
    return grade >= GradeScale.basico;
  }

  // Promedio simple de las competencias que el docente sí asignó a este
  // estándar en este período — si no asignó ninguna, `null` (no cuenta
  // como cero: "no es obligatorio trabajar todos los estándares en todos
  // los períodos").
  double? estandarGradeForStudent(
    String studentId,
    String subjectId,
    String periodId,
    String estandarId,
  ) {
    final competencias = competenciasForEstandarAndPeriod(estandarId, periodId);
    if (competencias.isEmpty) return null;
    final scores = competencias
        .map(
          (c) => competenciaGradeForStudent(studentId, subjectId, periodId, c.id),
        )
        .whereType<double>()
        .toList();
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Porcentaje que le corresponde a cada Estándar dentro del bloque de
  /// "Estándares" de la nota (el reparto entre Estándares y Evaluación
  /// Final lo define coordinación en EvaluationConfig). El docente ya no
  /// asigna un peso individual: se reparte en partes iguales entre los
  /// Estándares que tienen al menos una Competencia en este período. `0`
  /// si ninguno tiene competencias todavía.
  double equalEstandarWeightPercent(String subjectId, String periodId) {
    final activos = estandaresForSubject(subjectId)
        .where(
          (e) => competenciasForEstandarAndPeriod(e.id, periodId).isNotEmpty,
        )
        .length;
    return activos == 0 ? 0 : 100 / activos;
  }

  void addEstandar(Estandar e) => _store.saveEstandar(e);

  void updateEstandar(
    String id, {
    required String name,
    required String description,
  }) {
    final old = _estandares.firstWhere((e) => e.id == id);
    _store.saveEstandar(
      Estandar(
        id: old.id,
        subjectId: old.subjectId,
        academicYearId: old.academicYearId,
        name: name,
        description: description,
        order: old.order,
        weight: old.weight,
      ),
    );
  }

  void deleteEstandar(String id) {
    final competenciaIds = _competencias
        .where((c) => c.estandarId == id)
        .map((c) => c.id)
        .toList();
    for (final compId in competenciaIds) {
      for (final act in _actividades.where((a) => a.competenciaId == compId)) {
        _store.deleteActividad(act.id);
      }
      _store.deleteCompetencia(compId);
    }
    _store.deleteEstandar(id);
  }

  void addCompetencia(Competencia c) => _store.saveCompetencia(c);

  void updateCompetencia(
    String id, {
    required String name,
    required String description,
    required CompetenciaTipo tipo,
  }) {
    final old = _competencias.firstWhere((c) => c.id == id);
    _store.saveCompetencia(
      Competencia(
        id: old.id,
        estandarId: old.estandarId,
        periodId: old.periodId,
        tipo: tipo,
        name: name,
        description: description,
        order: old.order,
      ),
    );
  }

  void deleteCompetencia(String id) {
    for (final act in _actividades.where((a) => a.competenciaId == id)) {
      _store.deleteActividad(act.id);
    }
    _store.deleteCompetencia(id);
  }

  void addActividad(Actividad a) => _store.saveActividad(a);

  void updateActividad(
    String id, {
    required String name,
    required String description,
    DateTime? date,
  }) {
    final old = _actividades.firstWhere((a) => a.id == id);
    _store.saveActividad(
      Actividad(
        id: old.id,
        competenciaId: old.competenciaId,
        name: name,
        description: description,
        order: old.order,
        date: date,
      ),
    );
  }

  void deleteActividad(String id) => _store.deleteActividad(id);

  EvaluationConfig? evalConfigFor(String subjectId, String periodId) {
    try {
      return _evalConfigs.firstWhere(
        (ec) => ec.subjectId == subjectId && ec.periodId == periodId,
      );
    } catch (_) {
      return null;
    }
  }

  // Crea o actualiza la ponderación Estándares/Evaluación Final de una
  // asignatura en un período (reutiliza el id existente si ya había config).
  Future<void> saveEvalConfig(
    String subjectId,
    String periodId,
    double standardsWeight,
    double finalExamWeight,
  ) {
    final existing = evalConfigFor(subjectId, periodId);
    return _store.saveEvalConfig(
      EvaluationConfig(
        id: existing?.id ?? '${subjectId}_$periodId',
        subjectId: subjectId,
        periodId: periodId,
        standardsWeight: standardsWeight,
        finalExamWeight: finalExamWeight,
      ),
    );
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
    final subjectEstandares = estandaresForSubject(subjectId);
    final gradesList = gradesForStudentSubjectPeriod(
      studentId,
      subjectId,
      periodId,
    );

    if (gradesList.isEmpty) return 0.0;

    double? finalExamValue;
    try {
      finalExamValue = gradesList.firstWhere((g) => g.estandarId == null).value;
    } catch (_) {
      finalExamValue = null;
    }

    // El peso de cada Estándar ya no lo asigna el docente: el porcentaje de
    // Estándares (definido por coordinación en EvaluationConfig) se reparte
    // en partes iguales entre los estándares que sí tienen nota este
    // período — si faltan notas de alguno, simplemente no cuenta (no se
    // asume 0), igual que antes.
    double? standardsAvg;
    if (subjectEstandares.isNotEmpty) {
      final scores = subjectEstandares
          .map(
            (e) => estandarGradeForStudent(studentId, subjectId, periodId, e.id),
          )
          .whereType<double>()
          .toList();
      if (scores.isNotEmpty) {
        standardsAvg = scores.reduce((a, b) => a + b) / scores.length;
      }
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

  double overallAverageForPeriod(
    String studentId,
    String courseId,
    String periodId,
  ) {
    final subjects = subjectsForCourse(courseId);
    final gs = subjects
        .map((s) => calculateSubjectPeriodGrade(studentId, s.id, periodId))
        .where((g) => g > 0)
        .toList();
    return gs.isEmpty ? 0.0 : gs.reduce((a, b) => a + b) / gs.length;
  }

  List<CourseReportRow> courseDefinitiveReport(String courseId, String periodId) {
    final students = studentsInCourse(courseId);
    final subjects = subjectsForCourse(courseId);

    final entries = students.map((student) {
      final gradeBySubjectId = <String, double>{
        for (final subject in subjects)
          subject.id: calculateSubjectPeriodGrade(
            student.id,
            subject.id,
            periodId,
          ),
      };
      final validGrades = gradeBySubjectId.values.where((g) => g > 0);
      final average = validGrades.isEmpty
          ? 0.0
          : validGrades.reduce((a, b) => a + b) / validGrades.length;
      return (student: student, gradeBySubjectId: gradeBySubjectId, average: average);
    }).toList();

    entries.sort((a, b) => b.average.compareTo(a.average));

    return List.generate(entries.length, (i) {
      final e = entries[i];
      return CourseReportRow(
        student: e.student,
        gradeBySubjectId: e.gradeBySubjectId,
        average: e.average,
        rank: i + 1,
      );
    });
  }

  Map<String, List<Subject>> subjectsByArea(String courseId) {
    final areas = <String, List<Subject>>{};
    for (final s in subjectsForCourse(courseId)) {
      areas.putIfAbsent(s.area, () => []).add(s);
    }
    return areas;
  }

  double areaGradeForStudent(
    String studentId,
    String periodId,
    List<Subject> subjectsInArea,
  ) {
    double weightedSum = 0;
    double totalWeight = 0;
    for (final s in subjectsInArea) {
      final g = calculateSubjectPeriodGrade(studentId, s.id, periodId);
      if (g > 0) {
        weightedSum += g * s.hoursPerWeek;
        totalWeight += s.hoursPerWeek;
      }
    }
    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  List<CourseAreaReportRow> courseAreaConsolidatedReport(
    String courseId,
    String periodId,
  ) {
    final students = studentsInCourse(courseId);
    final areas = subjectsByArea(courseId);

    final entries = students.map((student) {
      final gradeByArea = <String, double>{
        for (final e in areas.entries)
          e.key: areaGradeForStudent(student.id, periodId, e.value),
      };
      final validGrades = gradeByArea.values.where((g) => g > 0);
      final average = validGrades.isEmpty
          ? 0.0
          : validGrades.reduce((a, b) => a + b) / validGrades.length;
      return (student: student, gradeByArea: gradeByArea, average: average);
    }).toList();

    entries.sort((a, b) => b.average.compareTo(a.average));

    return List.generate(entries.length, (i) {
      final e = entries[i];
      return CourseAreaReportRow(
        student: e.student,
        gradeByArea: e.gradeByArea,
        average: e.average,
        rank: i + 1,
      );
    });
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
      final avg = overallAverageForPeriod(
        student.id,
        student.courseId!,
        period.id,
      );
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

  void addCourse(Course course) {
    _store.saveCourse(course);
  }

  void deleteAssignment(String id) {
    _store.deleteAssignment(id);
  }

  // Asigna (o quita, con teacherId = null) la dirección de grupo de un curso.
  void setCourseDirector(String courseId, String? teacherId) {
    final course = courseById(courseId);
    if (course == null) return;
    _store.saveCourse(
      Course(
        id: course.id,
        name: course.name,
        grade: course.grade,
        section: course.section,
        academicYearId: course.academicYearId,
        directorTeacherId: teacherId,
      ),
    );
  }

  void addStudent(Student student) {
    _store.saveStudent(student);
  }

  void addParent(Parent parent) {
    _store.saveParent(parent);
  }

  void deleteParent(String id) {
    _store.deleteParent(id);
  }

  // Elimina por completo el perfil de un usuario: su registro específico de
  // rol (docente/estudiante/padre, con limpieza de referencias cruzadas) y
  // su documento en la colección users. No elimina la cuenta en Firebase
  // Auth (ver comentario en FirestoreService.deleteUser), así que la cuenta
  // queda inutilizable pero no borrada del todo del lado de autenticación.
  void deleteUserAccount(AppUser user) {
    switch (user.role) {
      case UserRole.teacher:
        final t = teacherByUserId(user.id);
        if (t != null) {
          for (final a in _assignments.where((a) => a.teacherId == t.id)) {
            _store.deleteAssignment(a.id);
          }
          for (final c in _courses.where((c) => c.directorTeacherId == t.id)) {
            setCourseDirector(c.id, null);
          }
          _store.deleteTeacher(t.id);
        }
      case UserRole.student:
        final s = studentByUserId(user.id);
        if (s != null) {
          for (final parentId in s.parentIds) {
            final p = parentById(parentId);
            if (p != null) {
              _store.saveParent(
                Parent(
                  id: p.id,
                  userId: p.userId,
                  firstName: p.firstName,
                  lastName: p.lastName,
                  documentId: p.documentId,
                  phone: p.phone,
                  relationship: p.relationship,
                  studentIds: p.studentIds.where((id) => id != s.id).toList(),
                ),
              );
            }
          }
          _store.deleteStudent(s.id);
        }
      case UserRole.parent:
        final p = parentByUserId(user.id);
        if (p != null) {
          for (final studentId in p.studentIds) {
            final s = studentById(studentId);
            if (s != null) {
              _store.saveStudent(
                Student(
                  id: s.id,
                  userId: s.userId,
                  firstName: s.firstName,
                  lastName: s.lastName,
                  documentId: s.documentId,
                  birthDate: s.birthDate,
                  courseId: s.courseId,
                  parentIds: s.parentIds.where((id) => id != p.id).toList(),
                ),
              );
            }
          }
          _store.deleteParent(p.id);
        }
      case UserRole.coordinator:
      case UserRole.admin:
        break;
    }
    _store.deleteUser(user.id);
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
      _store.saveStudent(
        Student(
          id: student.id,
          userId: student.userId,
          firstName: student.firstName,
          lastName: student.lastName,
          documentId: student.documentId,
          birthDate: student.birthDate,
          courseId: student.courseId,
          parentIds: [...student.parentIds, parentId],
        ),
      );
    }
    if (!parent.studentIds.contains(studentId)) {
      _store.saveParent(
        Parent(
          id: parent.id,
          userId: parent.userId,
          firstName: parent.firstName,
          lastName: parent.lastName,
          documentId: parent.documentId,
          phone: parent.phone,
          relationship: parent.relationship,
          studentIds: [...parent.studentIds, studentId],
        ),
      );
    }
  }

  void unlinkParentFromStudent(String studentId, String parentId) {
    final student = studentById(studentId);
    final parent = parentById(parentId);
    if (student != null && student.parentIds.contains(parentId)) {
      _store.saveStudent(
        Student(
          id: student.id,
          userId: student.userId,
          firstName: student.firstName,
          lastName: student.lastName,
          documentId: student.documentId,
          birthDate: student.birthDate,
          courseId: student.courseId,
          parentIds: student.parentIds.where((id) => id != parentId).toList(),
        ),
      );
    }
    if (parent != null && parent.studentIds.contains(studentId)) {
      _store.saveParent(
        Parent(
          id: parent.id,
          userId: parent.userId,
          firstName: parent.firstName,
          lastName: parent.lastName,
          documentId: parent.documentId,
          phone: parent.phone,
          relationship: parent.relationship,
          studentIds: parent.studentIds.where((id) => id != studentId).toList(),
        ),
      );
    }
  }

  void addGrade(Grade grade) {
    final existing = _grades
        .where(
          (g) =>
              g.studentId == grade.studentId &&
              g.subjectId == grade.subjectId &&
              g.periodId == grade.periodId &&
              g.estandarId == grade.estandarId &&
              g.competenciaId == grade.competenciaId &&
              g.actividadId == grade.actividadId,
        )
        .toList();
    for (final g in existing) {
      if (g.id != grade.id) _store.deleteGrade(g.id);
    }
    _store.saveGrade(grade);
  }

  void addObservation(Observation obs) {
    _store.saveObservation(obs);
  }

  BehaviorAssessment? behaviorFor(String studentId, String periodId) {
    try {
      return _behaviorAssessments.firstWhere(
        (b) => b.studentId == studentId && b.periodId == periodId,
      );
    } catch (_) {
      return null;
    }
  }

  void saveBehaviorAssessment(BehaviorAssessment b) {
    _store.saveBehaviorAssessment(b);
  }

  void addAttendance(AttendanceRecord record) {
    _store.saveAttendance(record);
  }

  void markNotificationRead(String notificationId) {
    final n = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => AppNotification(
        id: '',
        userId: '',
        title: '',
        message: '',
        type: NotificationType.general,
        createdAt: DateTime.now(),
      ),
    );
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

  Estandar? estandarById(String id) {
    try {
      return _estandares.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Competencia? competenciaById(String id) {
    try {
      return _competencias.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
