import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/coordinator/coordinator_dashboard.dart';
import '../../screens/coordinator/users_screen.dart';
import '../../screens/coordinator/academic_config_screen.dart';
import '../../screens/coordinator/subjects_screen.dart';
import '../../screens/coordinator/courses_screen.dart';
import '../../screens/coordinator/reports_screen.dart';
import '../../screens/coordinator/piar/piar_screen.dart';
import '../../screens/coordinator/grades_config_screen.dart';
import '../../screens/coordinator/password_admin_screen.dart';
import '../../screens/teacher/teacher_dashboard.dart';
import '../../screens/teacher/my_courses_screen.dart';
import '../../screens/teacher/grade_entry_screen.dart';
import '../../screens/teacher/attendance_screen.dart';
import '../../screens/teacher/observations_screen.dart';
import '../../screens/teacher/standards_screen.dart';
import '../../screens/teacher/grade_format_screen.dart';
import '../../screens/teacher/definitive_report_screen.dart';
import '../../screens/teacher/behavior_screen.dart';
import '../../screens/teacher/consolidated_report_screen.dart';
import '../../screens/teacher/piar/piar_teacher_screen.dart';
import '../../screens/teacher/hoja_de_vida_teacher_screen.dart';
import '../../screens/student/hoja_de_vida_student_screen.dart';
import '../../screens/shared/grade_sheet_screen.dart';
import '../../screens/student/student_dashboard.dart';
import '../../screens/student/student_grades_screen.dart';
import '../../screens/student/student_attendance_screen.dart';
import '../../screens/parent/parent_dashboard.dart';
import '../../screens/parent/children_screen.dart';
import '../../screens/parent/bulletin_screen.dart';
import '../../screens/email/email_screen.dart';
import '../../widgets/main_layout.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = auth.isAuthenticated;
      final isLoginPage = state.matchedLocation == '/login';
      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) {
        switch (auth.currentUser!.role) {
          case UserRole.coordinator:
          case UserRole.admin:
            return '/coordinator/dashboard';
          case UserRole.teacher:
            return '/teacher/dashboard';
          case UserRole.student:
            return '/student/dashboard';
          case UserRole.parent:
            return '/parent/dashboard';
        }
      }
      return null;
    },
    refreshListenable: auth,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      ShellRoute(
        navigatorKey: _shellKey,
        redirect: (context, state) {
          if (!auth.isAuthenticated) return '/login';
          final roleStr = switch (auth.currentUser!.role) {
            UserRole.coordinator => 'coordinator',
            UserRole.admin => 'coordinator',
            UserRole.teacher => 'teacher',
            UserRole.student => 'student',
            UserRole.parent => 'parent',
          };
          final path = state.matchedLocation;
          const roles = ['coordinator', 'teacher', 'student', 'parent'];
          for (final r in roles) {
            if (r != roleStr && path.startsWith('/$r/')) {
              return '/$roleStr/dashboard';
            }
          }
          return null;
        },
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Coordinator routes
          GoRoute(
            path: '/coordinator/dashboard',
            builder: (_, _) => const CoordinatorDashboard(),
          ),
          GoRoute(
            path: '/coordinator/users',
            builder: (_, _) => const UsersScreen(),
          ),
          GoRoute(
            path: '/coordinator/academic-config',
            builder: (_, _) => const AcademicConfigScreen(),
          ),
          GoRoute(
            path: '/coordinator/subjects',
            builder: (_, _) => const SubjectsScreen(),
          ),
          GoRoute(
            path: '/coordinator/courses',
            builder: (_, _) => const CoursesScreen(),
          ),
          GoRoute(
            path: '/coordinator/grades-config',
            builder: (_, _) => const GradesConfigScreen(),
          ),
          GoRoute(
            path: '/coordinator/reports',
            builder: (_, _) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/coordinator/piar',
            builder: (_, _) => const PiarScreen(),
          ),
          GoRoute(
            path: '/coordinator/password-admin',
            builder: (_, _) => const PasswordAdminScreen(),
          ),
          // Teacher routes
          GoRoute(
            path: '/teacher/dashboard',
            builder: (_, _) => const TeacherDashboard(),
          ),
          GoRoute(
            path: '/teacher/courses',
            builder: (_, _) => const MyCoursesScreen(),
          ),
          GoRoute(
            path: '/teacher/grades',
            builder: (_, _) => const GradeEntryScreen(),
          ),
          GoRoute(
            path: '/teacher/attendance',
            builder: (_, _) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/teacher/observations',
            builder: (_, _) => const ObservationsScreen(),
          ),
          GoRoute(
            path: '/teacher/standards',
            builder: (_, _) => const StandardsScreen(),
          ),
          GoRoute(
            path: '/teacher/grade-sheet',
            builder: (_, _) => const GradeSheetScreen(),
          ),
          GoRoute(
            path: '/teacher/grade-format',
            builder: (_, _) => const GradeFormatScreen(),
          ),
          GoRoute(
            path: '/teacher/definitive-report',
            builder: (_, _) => const DefinitiveReportScreen(),
          ),
          GoRoute(
            path: '/teacher/behavior',
            builder: (_, _) => const BehaviorScreen(),
          ),
          GoRoute(
            path: '/teacher/consolidated-report',
            builder: (_, _) => const ConsolidatedReportScreen(),
          ),
          GoRoute(
            path: '/teacher/piar',
            builder: (_, _) => const PiarTeacherScreen(),
          ),
          GoRoute(
            path: '/teacher/hoja-de-vida',
            builder: (_, _) => const HojaDeVidaTeacherScreen(),
          ),
          GoRoute(
            path: '/coordinator/grade-sheet',
            builder: (_, _) => const GradeSheetScreen(),
          ),
          // Student routes
          GoRoute(
            path: '/student/dashboard',
            builder: (_, _) => const StudentDashboard(),
          ),
          GoRoute(
            path: '/student/grades',
            builder: (_, _) => const StudentGradesScreen(),
          ),
          GoRoute(
            path: '/student/attendance',
            builder: (_, _) => const StudentAttendanceScreen(),
          ),
          GoRoute(
            path: '/student/hoja-de-vida',
            builder: (_, _) => const HojaDeVidaStudentScreen(),
          ),
          // Parent routes
          GoRoute(
            path: '/parent/dashboard',
            builder: (_, _) => const ParentDashboard(),
          ),
          GoRoute(
            path: '/parent/bulletin',
            builder: (_, _) => const BulletinScreen(),
          ),
          GoRoute(
            path: '/parent/children',
            builder: (_, _) => const ChildrenScreen(),
          ),
          // Email routes (all roles)
          GoRoute(
            path: '/coordinator/email',
            builder: (_, _) => const EmailScreen(),
          ),
          GoRoute(
            path: '/teacher/email',
            builder: (_, _) => const EmailScreen(),
          ),
          GoRoute(
            path: '/student/email',
            builder: (_, _) => const EmailScreen(),
          ),
          GoRoute(
            path: '/parent/email',
            builder: (_, _) => const EmailScreen(),
          ),
        ],
      ),
    ],
  );
}
