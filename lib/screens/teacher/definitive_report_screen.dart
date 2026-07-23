import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/course_definitive_report.dart';

/// Reporte de notas definitivas y puesto, visible para el docente solo en
/// los cursos de los que es director (director de curso consolida las
/// notas de todas las asignaturas, a diferencia de un docente de área).
class DefinitiveReportScreen extends StatelessWidget {
  const DefinitiveReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);

    if (teacher == null) {
      return const Center(child: Text('No se encontró el perfil de docente.'));
    }

    final directedCourses = academic.courses
        .where((c) => c.directorTeacherId == teacher.id)
        .toList();

    return CourseDefinitiveReportView(
      courses: directedCourses,
      accentColor: AppColors.teacher,
      emptyCoursesMessage:
          'No eres director de ningún curso. Este reporte solo está disponible para el director de curso.',
    );
  }
}
