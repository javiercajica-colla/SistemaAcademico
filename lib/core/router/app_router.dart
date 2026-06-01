import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/coordinator/coordinator_dashboard.dart';
import '../../screens/coordinator/users_screen.dart';
import '../../screens/coordinator/academic_config_screen.dart';
import '../../screens/coordinator/subjects_screen.dart';
import '../../screens/coordinator/courses_screen.dart';
import '../../screens/coordinator/reports_screen.dart';
import '../../screens/coordinator/grades_config_screen.dart';
import '../../screens/teacher/teacher_dashboard.dart';
import '../../screens/teacher/my_courses_screen.dart';
import '../../screens/teacher/grade_entry_screen.dart';
import '../../screens/teacher/attendance_screen.dart';
import '../../screens/teacher/observations_screen.dart';
import '../../screens/student/student_dashboard.dart';
import '../../screens/student/student_grades_screen.dart';
import '../../screens/student/student_attendance_screen.dart';
import '../../screens/parent/parent_dashboard.dart';
import '../../screens/parent/children_screen.dart';
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
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Coordinator routes
          GoRoute(path: '/coordinator/dashboard', builder: (_, __) => const CoordinatorDashboard()),
          GoRoute(path: '/coordinator/users', builder: (_, __) => const UsersScreen()),
          GoRoute(path: '/coordinator/academic-config', builder: (_, __) => const AcademicConfigScreen()),
          GoRoute(path: '/coordinator/subjects', builder: (_, __) => const SubjectsScreen()),
          GoRoute(path: '/coordinator/courses', builder: (_, __) => const CoursesScreen()),
          GoRoute(path: '/coordinator/grades-config', builder: (_, __) => const GradesConfigScreen()),
          GoRoute(path: '/coordinator/reports', builder: (_, __) => const ReportsScreen()),
          // Teacher routes
          GoRoute(path: '/teacher/dashboard', builder: (_, __) => const TeacherDashboard()),
          GoRoute(path: '/teacher/courses', builder: (_, __) => const MyCoursesScreen()),
          GoRoute(path: '/teacher/grades', builder: (_, __) => const GradeEntryScreen()),
          GoRoute(path: '/teacher/attendance', builder: (_, __) => const AttendanceScreen()),
          GoRoute(path: '/teacher/observations', builder: (_, __) => const ObservationsScreen()),
          // Student routes
          GoRoute(path: '/student/dashboard', builder: (_, __) => const StudentDashboard()),
          GoRoute(path: '/student/grades', builder: (_, __) => const StudentGradesScreen()),
          GoRoute(path: '/student/attendance', builder: (_, __) => const StudentAttendanceScreen()),
          // Parent routes
          GoRoute(path: '/parent/dashboard', builder: (_, __) => const ParentDashboard()),
          GoRoute(path: '/parent/children', builder: (_, __) => const ChildrenScreen()),
        ],
      ),
    ],
  );
}
