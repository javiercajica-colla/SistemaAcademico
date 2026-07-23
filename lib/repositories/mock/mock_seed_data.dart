import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../models/piar_models.dart';

// Datos falsos iniciales para el modo `useMockData = true` (ver
// lib/core/config/app_config.dart). Reutiliza lib/data/mock_data.dart — el mismo
// dataset que ya usa SeedService para poblar Firebase real — para que los
// accesos directos de la pantalla de login (login_screen.dart, contraseña
// "123456" para todos) funcionen igual en modo mock y en modo real.
//
// Cuentas de acceso directo (email → password, todas "123456"):
//   coordinador@colegio.edu.co  (coordinator — Dra. Patricia Morales)
//   admin@colegio.edu.co        (admin — Ing. Andrés Salazar)
//   docente@colegio.edu.co      (teacher — Prof. Carlos Rodríguez)
//   estudiante@colegio.edu.co   (student — Juan Pérez García)
//   padre@colegio.edu.co        (parent — Roberto Pérez)
// Ver lib/data/mock_data.dart para el resto de usuarios de ejemplo
// (más docentes, estudiantes y un segundo acudiente), todos con "123456".

Map<String, String> get mockCredentials => {
  for (final u in MockData.users) u.email.trim().toLowerCase(): u.password,
};

List<AppUser> seedUsers() => List.of(MockData.users);
List<AcademicYear> seedYears() => List.of(MockData.academicYears);
List<AcademicPeriod> seedPeriods() => List.of(MockData.academicPeriods);
List<Course> seedCourses() => List.of(MockData.courses);
List<Subject> seedSubjects() => List.of(MockData.subjects);
List<Teacher> seedTeachers() => List.of(MockData.teachers);
List<Student> seedStudents() => List.of(MockData.students);
List<Parent> seedParents() => List.of(MockData.parents);
List<Standard> seedStandards() => List.of(MockData.standards);
List<Grade> seedGrades() => List.of(MockData.grades);
List<AttendanceRecord> seedAttendance() => List.of(MockData.attendance);
List<Observation> seedObservations() => List.of(MockData.observations);
List<BehaviorAssessment> seedBehaviorAssessments() => const [];
List<SubjectAssignment> seedAssignments() => List.of(MockData.assignments);
List<EvaluationConfig> seedEvalConfigs() => List.of(MockData.evalConfigs);
List<AppNotification> seedNotifications() => List.of(MockData.notifications);

List<Indicator> seedIndicators() => List.of(MockData.indicators);

// Actividades son un módulo posterior a mock_data.dart y no tienen datos
// de ejemplo allí; se dejan vacías (la app las maneja bien sin datos).
List<Activity> seedActivities() => const [];

// PIAR: el catálogo de apoyos viene precargado, además de un caso de
// ejemplo ya activo (María González López, ver mock_data.dart) para que la
// pantalla del docente (Fase 5) tenga contenido real sin depender de que
// coordinación registre uno primero en cada sesión de prueba. El resto
// (seguimientos, evidencias, actas, diagnósticos, alertas) arranca vacío —
// se crean desde la propia app.
List<PiarCatalogoApoyo> seedPiarCatalogoApoyos() =>
    List.of(MockData.piarCatalogoApoyos);
List<PiarInscripcion> seedPiarInscripciones() =>
    List.of(MockData.piarInscripcionesDemo);
List<PiarSoporteExterno> seedPiarSoportesExternos() =>
    List.of(MockData.piarSoportesExternosDemo);
List<PiarPerfilApoyo> seedPiarPerfilesApoyo() =>
    List.of(MockData.piarPerfilesApoyoDemo);
List<PiarAjuste> seedPiarAjustes() => List.of(MockData.piarAjustesDemo);
