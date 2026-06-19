import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Nombres de colecciones ────────────────────────────────────────────────
  static const _kUsers = 'users';
  static const _kStudents = 'students';
  static const _kTeachers = 'teachers';
  static const _kParents = 'parents';
  static const _kCourses = 'courses';
  static const _kSubjects = 'subjects';
  static const _kYears = 'academic_years';
  static const _kPeriods = 'academic_periods';
  static const _kStandards = 'standards';
  static const _kGrades = 'grades';
  static const _kAttendance = 'attendance';
  static const _kObservations = 'observations';
  static const _kNotifications = 'notifications';
  static const _kAssignments = 'subject_assignments';
  static const _kIndicators = 'indicators';
  static const _kActivities = 'activities';
  static const _kEvalConfigs = 'evaluation_configs';

  // ══════════════════════════════════════════════════════════════════════════
  // USUARIOS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<AppUser>> usersStream() => _db
      .collection(_kUsers)
      .snapshots()
      .map((s) => s.docs.map(_userFromDoc).toList());

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection(_kUsers).doc(uid).get();
    return doc.exists ? _userFromDoc(doc) : null;
  }

  Future<void> saveUser(String uid, AppUser user) => _db
      .collection(_kUsers)
      .doc(uid)
      .set(_userToMap(user), SetOptions(merge: true));

  Future<void> updateUserStatus(String uid, {required bool isActive}) =>
      _db.collection(_kUsers).doc(uid).update({'isActive': isActive});

  // ══════════════════════════════════════════════════════════════════════════
  // ESTUDIANTES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Student>> studentsStream() => _db
      .collection(_kStudents)
      .snapshots()
      .map((s) => s.docs.map(_studentFromDoc).toList());

  Future<Student?> getStudent(String id) async {
    final doc = await _db.collection(_kStudents).doc(id).get();
    return doc.exists ? _studentFromDoc(doc) : null;
  }

  Future<Student?> getStudentByUserId(String userId) async {
    final q = await _db
        .collection(_kStudents)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty ? _studentFromDoc(q.docs.first) : null;
  }

  Future<List<Student>> getStudentsByCourse(String courseId) async {
    final q = await _db
        .collection(_kStudents)
        .where('courseId', isEqualTo: courseId)
        .get();
    return q.docs.map(_studentFromDoc).toList();
  }

  Future<void> saveStudent(Student student) => _db
      .collection(_kStudents)
      .doc(student.id)
      .set(_studentToMap(student), SetOptions(merge: true));

  Future<void> deleteStudent(String id) =>
      _db.collection(_kStudents).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // DOCENTES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Teacher>> teachersStream() => _db
      .collection(_kTeachers)
      .snapshots()
      .map((s) => s.docs.map(_teacherFromDoc).toList());

  Future<Teacher?> getTeacher(String id) async {
    final doc = await _db.collection(_kTeachers).doc(id).get();
    return doc.exists ? _teacherFromDoc(doc) : null;
  }

  Future<Teacher?> getTeacherByUserId(String userId) async {
    final q = await _db
        .collection(_kTeachers)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty ? _teacherFromDoc(q.docs.first) : null;
  }

  Future<void> saveTeacher(Teacher teacher) => _db
      .collection(_kTeachers)
      .doc(teacher.id)
      .set(_teacherToMap(teacher), SetOptions(merge: true));

  Future<void> deleteTeacher(String id) =>
      _db.collection(_kTeachers).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // PADRES DE FAMILIA
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Parent>> parentsStream() => _db
      .collection(_kParents)
      .snapshots()
      .map((s) => s.docs.map(_parentFromDoc).toList());

  Future<Parent?> getParentByUserId(String userId) async {
    final q = await _db
        .collection(_kParents)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return q.docs.isNotEmpty ? _parentFromDoc(q.docs.first) : null;
  }

  Future<void> saveParent(Parent parent) => _db
      .collection(_kParents)
      .doc(parent.id)
      .set(_parentToMap(parent), SetOptions(merge: true));

  // ══════════════════════════════════════════════════════════════════════════
  // CURSOS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Course>> coursesStream() => _db
      .collection(_kCourses)
      .snapshots()
      .map((s) => s.docs.map(_courseFromDoc).toList());

  Future<void> saveCourse(Course course) => _db
      .collection(_kCourses)
      .doc(course.id)
      .set(_courseToMap(course), SetOptions(merge: true));

  Future<void> deleteCourse(String id) =>
      _db.collection(_kCourses).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // ASIGNATURAS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Subject>> subjectsStream() => _db
      .collection(_kSubjects)
      .snapshots()
      .map((s) => s.docs.map(_subjectFromDoc).toList());

  Future<void> saveSubject(Subject subject) => _db
      .collection(_kSubjects)
      .doc(subject.id)
      .set(_subjectToMap(subject), SetOptions(merge: true));

  Future<void> deleteSubject(String id) =>
      _db.collection(_kSubjects).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // AÑOS Y PERÍODOS ACADÉMICOS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<AcademicYear>> academicYearsStream() => _db
      .collection(_kYears)
      .snapshots()
      .map((s) => s.docs.map(_yearFromDoc).toList());

  Future<void> saveAcademicYear(AcademicYear year) => _db
      .collection(_kYears)
      .doc(year.id)
      .set({'year': year.year, 'isActive': year.isActive}, SetOptions(merge: true));

  Stream<List<AcademicPeriod>> periodsStream({String? academicYearId}) {
    Query<Map<String, dynamic>> q = _db.collection(_kPeriods);
    if (academicYearId != null) {
      q = q.where('academicYearId', isEqualTo: academicYearId);
    }
    return q.snapshots().map((s) => s.docs.map(_periodFromDoc).toList());
  }

  Future<void> savePeriod(AcademicPeriod period) => _db
      .collection(_kPeriods)
      .doc(period.id)
      .set(_periodToMap(period), SetOptions(merge: true));

  // ══════════════════════════════════════════════════════════════════════════
  // ESTÁNDARES DE EVALUACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Standard>> standardsStream({String? subjectId}) {
    Query<Map<String, dynamic>> q = _db.collection(_kStandards);
    if (subjectId != null) q = q.where('subjectId', isEqualTo: subjectId);
    return q.snapshots().map((s) => s.docs.map(_standardFromDoc).toList());
  }

  Future<void> saveStandard(Standard standard) => _db
      .collection(_kStandards)
      .doc(standard.id)
      .set(_standardToMap(standard), SetOptions(merge: true));

  Future<void> deleteStandard(String id) =>
      _db.collection(_kStandards).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // CALIFICACIONES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Grade>> gradesStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  }) {
    Query<Map<String, dynamic>> q = _db.collection(_kGrades);
    if (studentId != null) q = q.where('studentId', isEqualTo: studentId);
    if (subjectId != null) q = q.where('subjectId', isEqualTo: subjectId);
    if (periodId != null) q = q.where('periodId', isEqualTo: periodId);
    return q.snapshots().map((s) => s.docs.map(_gradeFromDoc).toList());
  }

  Future<void> saveGrade(Grade grade) => _db
      .collection(_kGrades)
      .doc(grade.id)
      .set(_gradeToMap(grade), SetOptions(merge: true));

  Future<void> deleteGrade(String id) =>
      _db.collection(_kGrades).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // ASISTENCIA
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<AttendanceRecord>> attendanceStream({
    String? studentId,
    String? subjectId,
    String? periodId,
  }) {
    Query<Map<String, dynamic>> q = _db.collection(_kAttendance);
    if (studentId != null) q = q.where('studentId', isEqualTo: studentId);
    if (subjectId != null) q = q.where('subjectId', isEqualTo: subjectId);
    if (periodId != null) q = q.where('periodId', isEqualTo: periodId);
    return q.snapshots().map((s) => s.docs.map(_attendanceFromDoc).toList());
  }

  Future<void> saveAttendance(AttendanceRecord record) => _db
      .collection(_kAttendance)
      .doc(record.id)
      .set(_attendanceToMap(record), SetOptions(merge: true));

  Future<void> deleteAttendance(String id) =>
      _db.collection(_kAttendance).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // OBSERVACIONES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Observation>> observationsStream({String? studentId}) {
    Query<Map<String, dynamic>> q =
        _db.collection(_kObservations).orderBy('date', descending: true);
    if (studentId != null) q = q.where('studentId', isEqualTo: studentId);
    return q.snapshots().map((s) => s.docs.map(_observationFromDoc).toList());
  }

  Future<void> saveObservation(Observation obs) => _db
      .collection(_kObservations)
      .doc(obs.id)
      .set(_observationToMap(obs), SetOptions(merge: true));

  Future<void> deleteObservation(String id) =>
      _db.collection(_kObservations).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // INDICADORES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Indicator>> indicatorsStream({String? standardId}) {
    Query<Map<String, dynamic>> q = _db.collection(_kIndicators);
    if (standardId != null) q = q.where('standardId', isEqualTo: standardId);
    return q.snapshots().map((s) => s.docs.map(_indicatorFromDoc).toList());
  }

  Future<void> saveIndicator(Indicator ind) => _db
      .collection(_kIndicators)
      .doc(ind.id)
      .set(_indicatorToMap(ind), SetOptions(merge: true));

  Future<void> deleteIndicator(String id) =>
      _db.collection(_kIndicators).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // ACTIVIDADES
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<Activity>> activitiesStream({String? indicatorId}) {
    Query<Map<String, dynamic>> q = _db.collection(_kActivities);
    if (indicatorId != null) q = q.where('indicatorId', isEqualTo: indicatorId);
    return q.snapshots().map((s) => s.docs.map(_activityFromDoc).toList());
  }

  Future<void> saveActivity(Activity act) => _db
      .collection(_kActivities)
      .doc(act.id)
      .set(_activityToMap(act), SetOptions(merge: true));

  Future<void> deleteActivity(String id) =>
      _db.collection(_kActivities).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // CONFIGURACIÓN DE EVALUACIÓN
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<EvaluationConfig>> evalConfigsStream() => _db
      .collection(_kEvalConfigs)
      .snapshots()
      .map((s) => s.docs.map(_evalConfigFromDoc).toList());

  Future<void> saveEvalConfig(EvaluationConfig ec) => _db
      .collection(_kEvalConfigs)
      .doc(ec.id)
      .set(_evalConfigToMap(ec), SetOptions(merge: true));

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICACIONES  (subcolección por usuario)
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<AppNotification>> notificationsStream(String userId) => _db
      .collection(_kNotifications)
      .doc(userId)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(_notificationFromDoc).toList());

  Future<void> saveNotification(AppNotification notif) => _db
      .collection(_kNotifications)
      .doc(notif.userId)
      .collection('items')
      .doc(notif.id)
      .set(_notificationToMap(notif), SetOptions(merge: true));

  Future<void> markNotificationRead(String userId, String notifId) => _db
      .collection(_kNotifications)
      .doc(userId)
      .collection('items')
      .doc(notifId)
      .update({'isRead': true});

  // ══════════════════════════════════════════════════════════════════════════
  // ASIGNACIONES DE ASIGNATURAS
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<SubjectAssignment>> assignmentsStream({String? teacherId}) {
    Query<Map<String, dynamic>> q = _db.collection(_kAssignments);
    if (teacherId != null) q = q.where('teacherId', isEqualTo: teacherId);
    return q.snapshots().map((s) => s.docs.map(_assignmentFromDoc).toList());
  }

  Future<void> saveAssignment(SubjectAssignment a) => _db
      .collection(_kAssignments)
      .doc(a.id)
      .set(_assignmentToMap(a), SetOptions(merge: true));

  Future<void> deleteAssignment(String id) =>
      _db.collection(_kAssignments).doc(id).delete();

  // ══════════════════════════════════════════════════════════════════════════
  // SERIALIZACIÓN PRIVADA
  // ══════════════════════════════════════════════════════════════════════════

  AppUser _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppUser(
      id: doc.id,
      name: d['name'] as String,
      email: d['email'] as String,
      password: '',
      role: UserRole.values.firstWhere(
        (r) => r.name == d['role'],
        orElse: () => UserRole.student,
      ),
      avatar: d['avatar'] as String?,
      isActive: d['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _userToMap(AppUser u) => {
        'name': u.name,
        'email': u.email,
        'role': u.role.name,
        'avatar': u.avatar,
        'isActive': u.isActive,
      };

  Student _studentFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Student(
      id: doc.id,
      userId: d['userId'] as String,
      firstName: d['firstName'] as String,
      lastName: d['lastName'] as String,
      documentId: d['documentId'] as String,
      birthDate: (d['birthDate'] as Timestamp).toDate(),
      courseId: d['courseId'] as String?,
      parentIds: List<String>.from(d['parentIds'] ?? []),
    );
  }

  Map<String, dynamic> _studentToMap(Student s) => {
        'userId': s.userId,
        'firstName': s.firstName,
        'lastName': s.lastName,
        'documentId': s.documentId,
        'birthDate': Timestamp.fromDate(s.birthDate),
        'courseId': s.courseId,
        'parentIds': s.parentIds,
      };

  Teacher _teacherFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Teacher(
      id: doc.id,
      userId: d['userId'] as String,
      firstName: d['firstName'] as String,
      lastName: d['lastName'] as String,
      documentId: d['documentId'] as String,
      specialization: d['specialization'] as String,
      subjectIds: List<String>.from(d['subjectIds'] ?? []),
    );
  }

  Map<String, dynamic> _teacherToMap(Teacher t) => {
        'userId': t.userId,
        'firstName': t.firstName,
        'lastName': t.lastName,
        'documentId': t.documentId,
        'specialization': t.specialization,
        'subjectIds': t.subjectIds,
      };

  Parent _parentFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Parent(
      id: doc.id,
      userId: d['userId'] as String,
      firstName: d['firstName'] as String,
      lastName: d['lastName'] as String,
      documentId: d['documentId'] as String,
      phone: d['phone'] as String,
      relationship: d['relationship'] as String,
      studentIds: List<String>.from(d['studentIds'] ?? []),
    );
  }

  Map<String, dynamic> _parentToMap(Parent p) => {
        'userId': p.userId,
        'firstName': p.firstName,
        'lastName': p.lastName,
        'documentId': p.documentId,
        'phone': p.phone,
        'relationship': p.relationship,
        'studentIds': p.studentIds,
      };

  Course _courseFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Course(
      id: doc.id,
      name: d['name'] as String,
      grade: d['grade'] as String,
      section: d['section'] as String,
      academicYearId: d['academicYearId'] as String,
      directorTeacherId: d['directorTeacherId'] as String?,
    );
  }

  Map<String, dynamic> _courseToMap(Course c) => {
        'name': c.name,
        'grade': c.grade,
        'section': c.section,
        'academicYearId': c.academicYearId,
        'directorTeacherId': c.directorTeacherId,
      };

  Subject _subjectFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Subject(
      id: doc.id,
      code: d['code'] as String,
      name: d['name'] as String,
      area: d['area'] as String,
      hoursPerWeek: d['hoursPerWeek'] as int,
      teacherId: d['teacherId'] as String?,
    );
  }

  Map<String, dynamic> _subjectToMap(Subject s) => {
        'code': s.code,
        'name': s.name,
        'area': s.area,
        'hoursPerWeek': s.hoursPerWeek,
        'teacherId': s.teacherId,
      };

  AcademicYear _yearFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AcademicYear(
      id: doc.id,
      year: d['year'] as int,
      isActive: d['isActive'] as bool? ?? false,
    );
  }

  AcademicPeriod _periodFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AcademicPeriod(
      id: doc.id,
      academicYearId: d['academicYearId'] as String,
      name: d['name'] as String,
      startDate: (d['startDate'] as Timestamp).toDate(),
      endDate: (d['endDate'] as Timestamp).toDate(),
      weight: (d['weight'] as num).toDouble(),
      isOpen: d['isOpen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _periodToMap(AcademicPeriod p) => {
        'academicYearId': p.academicYearId,
        'name': p.name,
        'startDate': Timestamp.fromDate(p.startDate),
        'endDate': Timestamp.fromDate(p.endDate),
        'weight': p.weight,
        'isOpen': p.isOpen,
      };

  Standard _standardFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Standard(
      id: doc.id,
      subjectId: d['subjectId'] as String,
      periodId: d['periodId'] as String?,
      name: d['name'] as String,
      description: d['description'] as String,
      weight: (d['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> _standardToMap(Standard s) => {
        'subjectId': s.subjectId,
        'periodId': s.periodId,
        'name': s.name,
        'description': s.description,
        'weight': s.weight,
      };

  Grade _gradeFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Grade(
      id: doc.id,
      studentId: d['studentId'] as String,
      subjectId: d['subjectId'] as String,
      periodId: d['periodId'] as String,
      standardId: d['standardId'] as String?,
      indicatorId: d['indicatorId'] as String?,
      slot: d['slot'] as int?,
      value: (d['value'] as num).toDouble(),
      note: d['note'] as String?,
      registeredAt: (d['registeredAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _gradeToMap(Grade g) => {
        'studentId': g.studentId,
        'subjectId': g.subjectId,
        'periodId': g.periodId,
        'standardId': g.standardId,
        'indicatorId': g.indicatorId,
        'slot': g.slot,
        'value': g.value,
        'note': g.note,
        'registeredAt': Timestamp.fromDate(g.registeredAt),
      };

  AttendanceRecord _attendanceFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AttendanceRecord(
      id: doc.id,
      studentId: d['studentId'] as String,
      subjectId: d['subjectId'] as String,
      periodId: d['periodId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      status: AttendanceStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => AttendanceStatus.present,
      ),
      note: d['note'] as String?,
    );
  }

  Map<String, dynamic> _attendanceToMap(AttendanceRecord r) => {
        'studentId': r.studentId,
        'subjectId': r.subjectId,
        'periodId': r.periodId,
        'date': Timestamp.fromDate(r.date),
        'status': r.status.name,
        'note': r.note,
      };

  Observation _observationFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Observation(
      id: doc.id,
      studentId: d['studentId'] as String,
      teacherId: d['teacherId'] as String,
      subjectId: d['subjectId'] as String?,
      type: ObservationType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => ObservationType.academic,
      ),
      title: d['title'] as String,
      description: d['description'] as String,
      date: (d['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _observationToMap(Observation o) => {
        'studentId': o.studentId,
        'teacherId': o.teacherId,
        'subjectId': o.subjectId,
        'type': o.type.name,
        'title': o.title,
        'description': o.description,
        'date': Timestamp.fromDate(o.date),
      };

  AppNotification _notificationFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppNotification(
      id: doc.id,
      userId: d['userId'] as String,
      title: d['title'] as String,
      message: d['message'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => NotificationType.general,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isRead: d['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _notificationToMap(AppNotification n) => {
        'userId': n.userId,
        'title': n.title,
        'message': n.message,
        'type': n.type.name,
        'createdAt': Timestamp.fromDate(n.createdAt),
        'isRead': n.isRead,
      };

  SubjectAssignment _assignmentFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SubjectAssignment(
      id: doc.id,
      teacherId: d['teacherId'] as String,
      subjectId: d['subjectId'] as String,
      courseId: d['courseId'] as String,
      academicYearId: d['academicYearId'] as String,
    );
  }

  Map<String, dynamic> _assignmentToMap(SubjectAssignment a) => {
        'teacherId': a.teacherId,
        'subjectId': a.subjectId,
        'courseId': a.courseId,
        'academicYearId': a.academicYearId,
      };

  Indicator _indicatorFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Indicator(
      id: doc.id,
      standardId: d['standardId'] as String,
      name: d['name'] as String,
      description: d['description'] as String,
      order: d['order'] as int,
    );
  }

  Map<String, dynamic> _indicatorToMap(Indicator i) => {
        'standardId': i.standardId,
        'name': i.name,
        'description': i.description,
        'order': i.order,
      };

  Activity _activityFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Activity(
      id: doc.id,
      indicatorId: d['indicatorId'] as String,
      name: d['name'] as String,
      description: d['description'] as String,
      order: d['order'] as int,
      isProgrammed: d['isProgrammed'] as bool? ?? false,
      gradeValue: (d['gradeValue'] as num?)?.toDouble(),
      date: (d['date'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> _activityToMap(Activity a) => {
        'indicatorId': a.indicatorId,
        'name': a.name,
        'description': a.description,
        'order': a.order,
        'isProgrammed': a.isProgrammed,
        'gradeValue': a.gradeValue,
        'date': a.date == null ? null : Timestamp.fromDate(a.date!),
      };

  EvaluationConfig _evalConfigFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return EvaluationConfig(
      id: doc.id,
      subjectId: d['subjectId'] as String,
      periodId: d['periodId'] as String,
      standardsWeight: (d['standardsWeight'] as num).toDouble(),
      finalExamWeight: (d['finalExamWeight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> _evalConfigToMap(EvaluationConfig ec) => {
        'subjectId': ec.subjectId,
        'periodId': ec.periodId,
        'standardsWeight': ec.standardsWeight,
        'finalExamWeight': ec.finalExamWeight,
      };
}
