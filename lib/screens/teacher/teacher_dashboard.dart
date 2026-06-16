import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);

    if (teacher == null) return const Center(child: Text('Perfil de docente no encontrado'));

    final myAssignments = academic.assignmentsForTeacher(teacher.id);
    final myCourseIds = myAssignments.map((a) => a.courseId).toSet();
    final myCourses = academic.courses.where((c) => myCourseIds.contains(c.id)).toList();
    final totalStudents = myCourses.fold(0, (sum, c) => sum + academic.studentsInCourse(c.id).length);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcome(auth.currentUser!.name),
          const SizedBox(height: 20),
          _buildStats(myCourses.length, totalStudents, myAssignments.length),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildMyCourses(context, myCourses, academic, teacher.id)),
              const SizedBox(width: 16),
              Expanded(child: _buildPendingTasks(academic, teacher.id)),
            ],
          ),
          const SizedBox(height: 16),
          _buildPerformanceChart(myCourses, academic),
        ],
      ),
    );
  }

  Widget _buildWelcome(String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.teacher, Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido, ${name.split(' ').first}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Año Lectivo 2026 • ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(int courses, int students, int assignments) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 90,
      ),
      children: [
        StatCard(title: 'Mis Cursos', value: '$courses', icon: Icons.class_rounded, color: AppColors.teacher),
        StatCard(title: 'Total Estudiantes', value: '$students', subtitle: 'A mi cargo', icon: Icons.people_rounded, color: AppColors.primary),
        StatCard(title: 'Asignaturas', value: '$assignments', icon: Icons.book_rounded, color: AppColors.purple),
      ],
    );
  }

  Widget _buildMyCourses(BuildContext context, List myCourses, AcademicProvider academic, String teacherId) {
    return AppCard(
      title: 'Mis Cursos y Asignaturas',
      child: myCourses.isEmpty
          ? const Center(child: Text('Sin cursos asignados'))
          : Column(
              children: myCourses.map((c) {
                final students = academic.studentsInCourse(c.id);
                final courseAssignments = academic.assignments.where((a) => a.courseId == c.id && a.teacherId == teacherId).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: AppColors.teacher.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Center(child: Text(c.grade, style: const TextStyle(color: AppColors.teacher, fontWeight: FontWeight.bold, fontSize: 15))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${students.length} estudiantes', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (courseAssignments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: courseAssignments.map((sa) {
                              final sub = academic.subjectById(sa.subjectId);
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(sub?.name ?? '', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPendingTasks(AcademicProvider academic, String teacherId) {
    final period = academic.currentOpenPeriod;
    return AppCard(
      title: 'Tareas Pendientes',
      child: Column(
        children: [
          _taskItem('Registrar calificaciones P2', period?.name ?? '', Icons.grade_rounded, AppColors.warning, true),
          _taskItem('Tomar asistencia hoy', 'Matemáticas 6°A', Icons.fact_check_rounded, AppColors.primary, false),
          _taskItem('Observaciones pendientes', '3 estudiantes', Icons.edit_note_rounded, AppColors.purple, false),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('3 tareas completadas esta semana', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskItem(String title, String subtitle, IconData icon, Color color, bool urgent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (urgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: const Text('Urgente', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(List myCourses, AcademicProvider academic) {
    if (myCourses.isEmpty) return const SizedBox.shrink();
    return AppCard(
      title: 'Rendimiento por Curso',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 5,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i >= myCourses.length) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 4), child: Text(myCourses[i].name, style: const TextStyle(fontSize: 10)));
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10)))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(myCourses.length, (i) => BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: 3.5 + i * 0.1, color: AppColors.teacher, width: 28, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            ])),
          ),
        ),
      ),
    );
  }
}
