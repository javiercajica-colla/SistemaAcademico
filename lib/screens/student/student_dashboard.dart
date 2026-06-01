import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final student = academic.studentByUserId(auth.currentUser!.id);

    if (student == null) return const Center(child: Text('Perfil de estudiante no encontrado'));

    final course = academic.courseById(student.courseId ?? '');
    final avgP1 = academic.calculateOverallAverage(student.id, 'ap1');
    final avgP2 = academic.calculateOverallAverage(student.id, 'ap2');
    final myGrades = academic.gradesForStudent(student.id);
    final myAttendance = academic.attendanceForStudent(student.id);
    final myObs = academic.observationsForStudent(student.id);
    final absents = myAttendance.where((a) => a.status == AttendanceStatus.absent).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(student.fullName, course?.name ?? 'Sin curso', avgP1),
          const SizedBox(height: 20),
          _buildStatCards(avgP1, myGrades.length, myAttendance.length, absents),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildEvolutionChart(avgP1, avgP2)),
              const SizedBox(width: 16),
              Expanded(child: _buildSubjectSummary(student.id, academic)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRecentObs(myObs)),
              const SizedBox(width: 16),
              Expanded(child: _buildAttendanceSummary(myAttendance.length, absents)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String name, String course, double avg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.student, AppColors.student.withValues(alpha: 0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, ${name.split(' ').first}!', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Curso: $course • Año lectivo 2026', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                const Text('¡Sigue esforzándote para alcanzar tus metas!', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(avg > 0 ? avg.toStringAsFixed(1) : '-', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                const Text('Promedio', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(double avg, int grades, int attTotal, int absents) {
    final pct = attTotal > 0 ? ((attTotal - absents) / attTotal * 100) : 100.0;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 90,
      ),
      children: [
        StatCard(title: 'Promedio General', value: avg > 0 ? avg.toStringAsFixed(1) : '-', icon: Icons.bar_chart_rounded, color: avg >= 4.0 ? AppColors.secondary : AppColors.warning),
        StatCard(title: 'Calificaciones', value: '$grades', subtitle: 'registradas', icon: Icons.grade_rounded, color: AppColors.primary),
        StatCard(title: 'Asistencia', value: '${pct.toStringAsFixed(0)}%', subtitle: '$absents inasistencias', icon: Icons.fact_check_rounded, color: pct >= 90 ? AppColors.secondary : AppColors.warning),
        StatCard(title: 'Período Activo', value: 'P2', subtitle: 'En curso', icon: Icons.calendar_today_rounded, color: AppColors.purple),
      ],
    );
  }

  Widget _buildEvolutionChart(double avgP1, double avgP2) {
    return AppCard(
      title: 'Evolución Académica',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
                final labels = ['P1', 'P2', 'P3', 'P4'];
                final i = v.toInt();
                if (i >= labels.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: const TextStyle(fontSize: 11)));
              })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 28, getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10)))),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minY: 0, maxY: 5,
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, avgP1 > 0 ? avgP1 : 3.8),
                  FlSpot(1, avgP2 > 0 ? avgP2 : 4.0),
                  FlSpot(2, 4.1),
                  FlSpot(3, 4.3),
                ],
                isCurved: true,
                color: AppColors.student,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: true, color: AppColors.student.withValues(alpha: 0.1)),
              ),
              LineChartBarData(
                spots: const [FlSpot(0, 3.0), FlSpot(1, 3.0), FlSpot(2, 3.0), FlSpot(3, 3.0)],
                isCurved: false,
                color: AppColors.error.withValues(alpha: 0.4),
                barWidth: 1,
                dotData: const FlDotData(show: false),
                dashArray: [5, 5],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectSummary(String studentId, AcademicProvider academic) {
    final subjects = academic.subjects.take(5).toList();
    return AppCard(
      title: 'Por Asignatura',
      child: Column(
        children: subjects.map((s) {
          final avg = academic.calculateSubjectPeriodGrade(studentId, s.id, 'ap1');
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: Text(s.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: LinearProgressIndicator(
                    value: avg / 5,
                    color: avg >= 4.0 ? AppColors.secondary : avg >= 3.0 ? AppColors.warning : AppColors.error,
                    backgroundColor: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(width: 32, child: Text(avg > 0 ? avg.toStringAsFixed(1) : '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentObs(List observations) {
    return AppCard(
      title: 'Observaciones',
      child: observations.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Sin observaciones', style: TextStyle(color: AppColors.textSecondary))))
          : Column(
              children: observations.take(3).map((o) {
                final Color c = o.type == ObservationType.positive ? AppColors.secondary : o.type == ObservationType.disciplinary ? AppColors.error : AppColors.warning;
                final IconData ic = o.type == ObservationType.positive ? Icons.thumb_up_rounded : o.type == ObservationType.disciplinary ? Icons.warning_rounded : Icons.book_rounded;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 28, height: 28, decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(ic, color: c, size: 14)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(o.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildAttendanceSummary(int total, int absents) {
    final pct = total > 0 ? ((total - absents) / total * 100) : 100.0;
    return AppCard(
      title: 'Resumen de Asistencia',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _attItem('Clases', '$total', AppColors.primary),
              const SizedBox(width: 20),
              _attItem('Presentes', '${total - absents}', AppColors.secondary),
              const SizedBox(width: 20),
              _attItem('Ausentes', '$absents', AppColors.error),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: pct / 100,
            color: pct >= 80 ? AppColors.secondary : AppColors.warning,
            backgroundColor: AppColors.border,
            borderRadius: BorderRadius.circular(4),
            minHeight: 10,
          ),
          const SizedBox(height: 6),
          Text('${pct.toStringAsFixed(0)}% de asistencia',
              style: TextStyle(color: pct >= 80 ? AppColors.secondary : AppColors.warning, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _attItem(String label, String val, Color color) {
    return Column(children: [
      Text(val, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}
