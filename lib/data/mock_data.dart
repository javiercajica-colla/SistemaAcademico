import '../models/models.dart';

class MockData {
  static final List<AppUser> users = [
    const AppUser(
      id: 'u1',
      name: 'Dra. Patricia Morales',
      email: 'coordinador@colegio.edu.co',
      password: '123456',
      role: UserRole.coordinator,
    ),
    const AppUser(
      id: 'u2',
      name: 'Prof. Carlos Rodríguez',
      email: 'docente@colegio.edu.co',
      password: '123456',
      role: UserRole.teacher,
    ),
    const AppUser(
      id: 'u3',
      name: 'Prof. Ana Martínez',
      email: 'ana.martinez@colegio.edu.co',
      password: '123456',
      role: UserRole.teacher,
    ),
    const AppUser(
      id: 'u4',
      name: 'Juan Pérez García',
      email: 'estudiante@colegio.edu.co',
      password: '123456',
      role: UserRole.student,
    ),
    const AppUser(
      id: 'u5',
      name: 'María González López',
      email: 'maria.gonzalez@colegio.edu.co',
      password: '123456',
      role: UserRole.student,
    ),
    const AppUser(
      id: 'u6',
      name: 'Laura García Torres',
      email: 'laura.garcia@colegio.edu.co',
      password: '123456',
      role: UserRole.student,
    ),
    const AppUser(
      id: 'u7',
      name: 'Roberto Pérez',
      email: 'padre@colegio.edu.co',
      password: '123456',
      role: UserRole.parent,
    ),
    const AppUser(
      id: 'u8',
      name: 'Prof. Miguel Sánchez',
      email: 'miguel.sanchez@colegio.edu.co',
      password: '123456',
      role: UserRole.teacher,
    ),
    const AppUser(
      id: 'u9',
      name: 'Prof. Sofia Vargas',
      email: 'sofia.vargas@colegio.edu.co',
      password: '123456',
      role: UserRole.teacher,
    ),
    const AppUser(
      id: 'u10',
      name: 'Andrés Torres',
      email: 'andres.torres@colegio.edu.co',
      password: '123456',
      role: UserRole.student,
    ),
  ];

  static final List<AcademicYear> academicYears = [
    const AcademicYear(id: 'ay1', year: 2026, isActive: true),
    const AcademicYear(id: 'ay2', year: 2025, isActive: false),
  ];

  static final List<AcademicPeriod> academicPeriods = [
    AcademicPeriod(
      id: 'ap1',
      academicYearId: 'ay1',
      name: 'Período 1',
      startDate: DateTime(2026, 1, 15),
      endDate: DateTime(2026, 3, 28),
      weight: 25,
      isOpen: false,
    ),
    AcademicPeriod(
      id: 'ap2',
      academicYearId: 'ay1',
      name: 'Período 2',
      startDate: DateTime(2026, 4, 1),
      endDate: DateTime(2026, 6, 20),
      weight: 25,
      isOpen: true,
    ),
    AcademicPeriod(
      id: 'ap3',
      academicYearId: 'ay1',
      name: 'Período 3',
      startDate: DateTime(2026, 7, 15),
      endDate: DateTime(2026, 9, 25),
      weight: 25,
      isOpen: false,
    ),
    AcademicPeriod(
      id: 'ap4',
      academicYearId: 'ay1',
      name: 'Período 4',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 11, 30),
      weight: 25,
      isOpen: false,
    ),
  ];

  static final List<Subject> subjects = [
    const Subject(id: 's1', code: 'MAT', name: 'Matemáticas', area: 'Ciencias Exactas', hoursPerWeek: 5, teacherId: 't1'),
    const Subject(id: 's2', code: 'ESP', name: 'Español', area: 'Lenguaje', hoursPerWeek: 4, teacherId: 't2'),
    const Subject(id: 's3', code: 'CN', name: 'Ciencias Naturales', area: 'Ciencias', hoursPerWeek: 3, teacherId: 't3'),
    const Subject(id: 's4', code: 'CS', name: 'Ciencias Sociales', area: 'Sociales', hoursPerWeek: 3, teacherId: 't1'),
    const Subject(id: 's5', code: 'ING', name: 'Inglés', area: 'Idiomas', hoursPerWeek: 4, teacherId: 't2'),
    const Subject(id: 's6', code: 'TEC', name: 'Tecnología', area: 'Tecnología', hoursPerWeek: 2, teacherId: 't4'),
    const Subject(id: 's7', code: 'EF', name: 'Educación Física', area: 'Educación Física', hoursPerWeek: 2, teacherId: 't3'),
    const Subject(id: 's8', code: 'ART', name: 'Artes', area: 'Artística', hoursPerWeek: 2, teacherId: 't4'),
  ];

  static final List<Standard> standards = [
    const Standard(id: 'st1', subjectId: 's1', name: 'Razonamiento lógico', description: 'Capacidad de razonar y argumentar matemáticamente', weight: 30),
    const Standard(id: 'st2', subjectId: 's1', name: 'Resolución de problemas', description: 'Plantear y resolver problemas matemáticos', weight: 25),
    const Standard(id: 'st3', subjectId: 's1', name: 'Pensamiento numérico', description: 'Comprensión y uso de los números', weight: 25),
    const Standard(id: 'st4', subjectId: 's1', name: 'Pensamiento geométrico', description: 'Comprensión del espacio y las figuras', weight: 20),
    const Standard(id: 'st5', subjectId: 's2', name: 'Comprensión lectora', description: 'Capacidad de leer y comprender textos', weight: 35),
    const Standard(id: 'st6', subjectId: 's2', name: 'Producción textual', description: 'Habilidad para escribir y comunicar ideas', weight: 35),
    const Standard(id: 'st7', subjectId: 's2', name: 'Literatura', description: 'Análisis de obras literarias', weight: 30),
    const Standard(id: 'st8', subjectId: 's3', name: 'Indagación científica', description: 'Metodología científica e investigación', weight: 40),
    const Standard(id: 'st9', subjectId: 's3', name: 'Conocimiento del entorno', description: 'Comprensión del mundo natural', weight: 35),
    const Standard(id: 'st10', subjectId: 's3', name: 'Ciencia, tecnología y sociedad', description: 'Relación entre ciencia y sociedad', weight: 25),
    const Standard(id: 'st11', subjectId: 's5', name: 'Listening & Speaking', description: 'Comprensión auditiva y expresión oral', weight: 40),
    const Standard(id: 'st12', subjectId: 's5', name: 'Reading & Writing', description: 'Comprensión lectora y escritura', weight: 35),
    const Standard(id: 'st13', subjectId: 's5', name: 'Grammar & Vocabulary', description: 'Gramática y vocabulario inglés', weight: 25),
  ];

  static final List<Course> courses = [
    const Course(id: 'c1', name: '6° A', grade: '6', section: 'A', academicYearId: 'ay1', directorTeacherId: 't1'),
    const Course(id: 'c2', name: '6° B', grade: '6', section: 'B', academicYearId: 'ay1', directorTeacherId: 't2'),
    const Course(id: 'c3', name: '7° A', grade: '7', section: 'A', academicYearId: 'ay1', directorTeacherId: 't3'),
    const Course(id: 'c4', name: '8° A', grade: '8', section: 'A', academicYearId: 'ay1', directorTeacherId: 't4'),
    const Course(id: 'c5', name: '9° A', grade: '9', section: 'A', academicYearId: 'ay1'),
    const Course(id: 'c6', name: '10° A', grade: '10', section: 'A', academicYearId: 'ay1', directorTeacherId: 't1'),
    const Course(id: 'c7', name: '11° A', grade: '11', section: 'A', academicYearId: 'ay1', directorTeacherId: 't2'),
  ];

  static final List<Teacher> teachers = [
    const Teacher(id: 't1', userId: 'u2', firstName: 'Carlos', lastName: 'Rodríguez', documentId: '12345678', specialization: 'Matemáticas', subjectIds: ['s1', 's4']),
    const Teacher(id: 't2', userId: 'u3', firstName: 'Ana', lastName: 'Martínez', documentId: '87654321', specialization: 'Lenguaje', subjectIds: ['s2', 's5']),
    const Teacher(id: 't3', userId: 'u8', firstName: 'Miguel', lastName: 'Sánchez', documentId: '11223344', specialization: 'Ciencias', subjectIds: ['s3', 's7']),
    const Teacher(id: 't4', userId: 'u9', firstName: 'Sofia', lastName: 'Vargas', documentId: '55667788', specialization: 'Tecnología', subjectIds: ['s6', 's8']),
  ];

  static final List<Student> students = [
    Student(id: 'st1', userId: 'u4', firstName: 'Juan', lastName: 'Pérez García', documentId: '1000001', birthDate: DateTime(2012, 3, 15), courseId: 'c1', parentIds: ['p1']),
    Student(id: 'st2', userId: 'u5', firstName: 'María', lastName: 'González López', documentId: '1000002', birthDate: DateTime(2012, 7, 22), courseId: 'c1', parentIds: ['p1']),
    Student(id: 'st3', userId: 'u6', firstName: 'Laura', lastName: 'García Torres', documentId: '1000003', birthDate: DateTime(2011, 11, 8), courseId: 'c1', parentIds: []),
    Student(id: 'st4', userId: 'u10', firstName: 'Andrés', lastName: 'Torres', documentId: '1000004', birthDate: DateTime(2012, 5, 3), courseId: 'c1', parentIds: []),
    Student(id: 'st5', userId: 'u4', firstName: 'Carlos', lastName: 'Mora Ruiz', documentId: '1000005', birthDate: DateTime(2012, 9, 18), courseId: 'c1', parentIds: []),
    Student(id: 'st6', userId: 'u4', firstName: 'Valentina', lastName: 'Cruz Peña', documentId: '1000006', birthDate: DateTime(2011, 12, 25), courseId: 'c2', parentIds: []),
    Student(id: 'st7', userId: 'u4', firstName: 'Diego', lastName: 'Herrera Silva', documentId: '1000007', birthDate: DateTime(2010, 4, 14), courseId: 'c3', parentIds: []),
    Student(id: 'st8', userId: 'u4', firstName: 'Isabella', lastName: 'Ramírez Castro', documentId: '1000008', birthDate: DateTime(2010, 8, 30), courseId: 'c3', parentIds: []),
    Student(id: 'st9', userId: 'u4', firstName: 'Sebastián', lastName: 'López Vargas', documentId: '1000009', birthDate: DateTime(2009, 2, 11), courseId: 'c4', parentIds: []),
    Student(id: 'st10', userId: 'u4', firstName: 'Camila', lastName: 'Jiménez Mora', documentId: '1000010', birthDate: DateTime(2009, 6, 7), courseId: 'c4', parentIds: []),
  ];

  static final List<Parent> parents = [
    const Parent(
      id: 'p1',
      userId: 'u7',
      firstName: 'Roberto',
      lastName: 'Pérez',
      documentId: '5000001',
      phone: '3001234567',
      relationship: 'Padre',
      studentIds: ['st1', 'st2'],
    ),
  ];

  static final List<SubjectAssignment> assignments = [
    const SubjectAssignment(id: 'sa1', teacherId: 't1', subjectId: 's1', courseId: 'c1', academicYearId: 'ay1'),
    const SubjectAssignment(id: 'sa2', teacherId: 't2', subjectId: 's2', courseId: 'c1', academicYearId: 'ay1'),
    const SubjectAssignment(id: 'sa3', teacherId: 't3', subjectId: 's3', courseId: 'c1', academicYearId: 'ay1'),
    const SubjectAssignment(id: 'sa4', teacherId: 't2', subjectId: 's5', courseId: 'c1', academicYearId: 'ay1'),
    const SubjectAssignment(id: 'sa5', teacherId: 't4', subjectId: 's6', courseId: 'c1', academicYearId: 'ay1'),
    const SubjectAssignment(id: 'sa6', teacherId: 't3', subjectId: 's7', courseId: 'c1', academicYearId: 'ay1'),
    const SubjectAssignment(id: 'sa7', teacherId: 't1', subjectId: 's1', courseId: 'c2', academicYearId: 'ay1'),
    const SubjectAssignment(id: 'sa8', teacherId: 't2', subjectId: 's2', courseId: 'c2', academicYearId: 'ay1'),
  ];

  static final List<Grade> grades = [
    Grade(id: 'g1', studentId: 'st1', subjectId: 's1', periodId: 'ap1', standardId: 'st1', value: 4.2, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g2', studentId: 'st1', subjectId: 's1', periodId: 'ap1', standardId: 'st2', value: 3.8, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g3', studentId: 'st1', subjectId: 's1', periodId: 'ap1', standardId: 'st3', value: 4.5, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g4', studentId: 'st1', subjectId: 's1', periodId: 'ap1', standardId: 'st4', value: 4.0, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g5', studentId: 'st1', subjectId: 's1', periodId: 'ap1', value: 4.1, registeredAt: DateTime(2026, 3, 25)),
    Grade(id: 'g6', studentId: 'st1', subjectId: 's2', periodId: 'ap1', standardId: 'st5', value: 4.8, registeredAt: DateTime(2026, 3, 12)),
    Grade(id: 'g7', studentId: 'st1', subjectId: 's2', periodId: 'ap1', standardId: 'st6', value: 4.5, registeredAt: DateTime(2026, 3, 12)),
    Grade(id: 'g8', studentId: 'st1', subjectId: 's2', periodId: 'ap1', standardId: 'st7', value: 4.6, registeredAt: DateTime(2026, 3, 12)),
    Grade(id: 'g9', studentId: 'st1', subjectId: 's2', periodId: 'ap1', value: 4.7, registeredAt: DateTime(2026, 3, 26)),
    Grade(id: 'g10', studentId: 'st1', subjectId: 's3', periodId: 'ap1', standardId: 'st8', value: 3.5, registeredAt: DateTime(2026, 3, 15)),
    Grade(id: 'g11', studentId: 'st1', subjectId: 's3', periodId: 'ap1', standardId: 'st9', value: 3.8, registeredAt: DateTime(2026, 3, 15)),
    Grade(id: 'g12', studentId: 'st1', subjectId: 's3', periodId: 'ap1', value: 3.6, registeredAt: DateTime(2026, 3, 27)),
    Grade(id: 'g13', studentId: 'st1', subjectId: 's5', periodId: 'ap1', standardId: 'st11', value: 3.2, registeredAt: DateTime(2026, 3, 18)),
    Grade(id: 'g14', studentId: 'st1', subjectId: 's5', periodId: 'ap1', standardId: 'st12', value: 3.5, registeredAt: DateTime(2026, 3, 18)),
    Grade(id: 'g15', studentId: 'st1', subjectId: 's5', periodId: 'ap1', value: 3.3, registeredAt: DateTime(2026, 3, 28)),
    Grade(id: 'g16', studentId: 'st2', subjectId: 's1', periodId: 'ap1', standardId: 'st1', value: 3.5, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g17', studentId: 'st2', subjectId: 's1', periodId: 'ap1', standardId: 'st2', value: 3.2, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g18', studentId: 'st2', subjectId: 's2', periodId: 'ap1', standardId: 'st5', value: 4.0, registeredAt: DateTime(2026, 3, 12)),
    Grade(id: 'g19', studentId: 'st3', subjectId: 's1', periodId: 'ap1', standardId: 'st1', value: 4.8, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g20', studentId: 'st3', subjectId: 's1', periodId: 'ap1', standardId: 'st2', value: 4.6, registeredAt: DateTime(2026, 3, 10)),
    Grade(id: 'g21', studentId: 'st1', subjectId: 's1', periodId: 'ap2', standardId: 'st1', value: 4.4, registeredAt: DateTime(2026, 5, 10)),
    Grade(id: 'g22', studentId: 'st1', subjectId: 's1', periodId: 'ap2', standardId: 'st2', value: 4.0, registeredAt: DateTime(2026, 5, 10)),
    Grade(id: 'g23', studentId: 'st1', subjectId: 's2', periodId: 'ap2', standardId: 'st5', value: 4.9, registeredAt: DateTime(2026, 5, 12)),
  ];

  static final List<AttendanceRecord> attendance = [
    AttendanceRecord(id: 'att1', studentId: 'st1', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 1, 20), status: AttendanceStatus.present),
    AttendanceRecord(id: 'att2', studentId: 'st1', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 1, 22), status: AttendanceStatus.present),
    AttendanceRecord(id: 'att3', studentId: 'st1', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 1, 27), status: AttendanceStatus.absent),
    AttendanceRecord(id: 'att4', studentId: 'st1', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 1, 29), status: AttendanceStatus.present),
    AttendanceRecord(id: 'att5', studentId: 'st1', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 2, 3), status: AttendanceStatus.late),
    AttendanceRecord(id: 'att6', studentId: 'st1', subjectId: 's2', periodId: 'ap1', date: DateTime(2026, 1, 20), status: AttendanceStatus.present),
    AttendanceRecord(id: 'att7', studentId: 'st1', subjectId: 's2', periodId: 'ap1', date: DateTime(2026, 1, 22), status: AttendanceStatus.present),
    AttendanceRecord(id: 'att8', studentId: 'st2', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 1, 20), status: AttendanceStatus.absent),
    AttendanceRecord(id: 'att9', studentId: 'st2', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 1, 22), status: AttendanceStatus.absent),
    AttendanceRecord(id: 'att10', studentId: 'st3', subjectId: 's1', periodId: 'ap1', date: DateTime(2026, 1, 20), status: AttendanceStatus.present),
  ];

  static final List<Observation> observations = [
    Observation(
      id: 'obs1',
      studentId: 'st1',
      teacherId: 't1',
      subjectId: 's1',
      type: ObservationType.positive,
      title: 'Excelente desempeño',
      description: 'Juan demostró gran habilidad en la resolución de ecuaciones cuadráticas. Participó activamente y ayudó a sus compañeros.',
      date: DateTime(2026, 2, 15),
    ),
    Observation(
      id: 'obs2',
      studentId: 'st1',
      teacherId: 't2',
      subjectId: 's2',
      type: ObservationType.academic,
      title: 'Dificultad en comprensión lectora',
      description: 'Se recomienda reforzar la lectura crítica. El estudiante muestra dificultades para analizar textos argumentativos.',
      date: DateTime(2026, 2, 20),
    ),
    Observation(
      id: 'obs3',
      studentId: 'st2',
      teacherId: 't1',
      type: ObservationType.disciplinary,
      title: 'Comportamiento en clase',
      description: 'La estudiante interrumpió la clase en múltiples ocasiones. Se habló con ella y se comprometió a mejorar su comportamiento.',
      date: DateTime(2026, 3, 5),
    ),
    Observation(
      id: 'obs4',
      studentId: 'st3',
      teacherId: 't1',
      subjectId: 's1',
      type: ObservationType.positive,
      title: 'Mejor puntaje en evaluación',
      description: 'Laura obtuvo el mejor puntaje en el examen de geometría del período. Demuestra excelentes capacidades matemáticas.',
      date: DateTime(2026, 3, 10),
    ),
  ];

  static final List<AppNotification> notifications = [
    AppNotification(
      id: 'n1',
      userId: 'u4',
      title: 'Calificaciones registradas',
      message: 'Se han registrado las calificaciones del Período 1 para la asignatura Matemáticas.',
      type: NotificationType.grade,
      createdAt: DateTime(2026, 3, 25),
      isRead: false,
    ),
    AppNotification(
      id: 'n2',
      userId: 'u4',
      title: 'Inasistencia registrada',
      message: 'Se registró una inasistencia el día 27 de enero en Matemáticas.',
      type: NotificationType.attendance,
      createdAt: DateTime(2026, 1, 27),
      isRead: true,
    ),
    AppNotification(
      id: 'n3',
      userId: 'u7',
      title: 'Boletín disponible',
      message: 'El boletín del Período 1 de Juan Pérez ya está disponible para descargar.',
      type: NotificationType.report,
      createdAt: DateTime(2026, 3, 28),
      isRead: false,
    ),
    AppNotification(
      id: 'n4',
      userId: 'u7',
      title: 'Observación académica',
      message: 'El docente registró una observación académica para su hijo Juan Pérez en la asignatura Español.',
      type: NotificationType.observation,
      createdAt: DateTime(2026, 2, 20),
      isRead: false,
    ),
  ];

  static final List<EvaluationConfig> evalConfigs = [
    const EvaluationConfig(id: 'ec1', subjectId: 's1', periodId: 'ap1', standardsWeight: 70, finalExamWeight: 30),
    const EvaluationConfig(id: 'ec2', subjectId: 's2', periodId: 'ap1', standardsWeight: 70, finalExamWeight: 30),
    const EvaluationConfig(id: 'ec3', subjectId: 's3', periodId: 'ap1', standardsWeight: 70, finalExamWeight: 30),
    const EvaluationConfig(id: 'ec4', subjectId: 's5', periodId: 'ap1', standardsWeight: 60, finalExamWeight: 40),
    const EvaluationConfig(id: 'ec5', subjectId: 's1', periodId: 'ap2', standardsWeight: 70, finalExamWeight: 30),
    const EvaluationConfig(id: 'ec6', subjectId: 's2', periodId: 'ap2', standardsWeight: 70, finalExamWeight: 30),
  ];
}
