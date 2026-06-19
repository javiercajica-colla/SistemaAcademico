import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/seed_dialog.dart';

class CoordinatorDashboard extends StatelessWidget {
  const CoordinatorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => SeedDialog.show(context),
              icon: const Icon(Icons.cloud_upload_rounded, size: 16),
              label: const Text('Inicializar datos Firebase'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildStats(academic),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildPerformanceChart(academic)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildCourseRanking(academic)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPeriodProgress(academic)),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentObservations(academic)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AcademicProvider academic) {
    final avg = academic.institutionalAverage;
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
        StatCard(title: 'Total Estudiantes', value: '${academic.totalStudents}', subtitle: 'Matriculados 2026', icon: Icons.people_rounded, color: AppColors.primary),
        StatCard(title: 'Total Docentes', value: '${academic.totalTeachers}', subtitle: 'Activos', icon: Icons.school_rounded, color: AppColors.secondary),
        StatCard(title: 'Promedio Institucional', value: avg.toStringAsFixed(1), subtitle: avg >= 3.5 ? 'Rendimiento Bueno' : 'Requiere atención', icon: Icons.bar_chart_rounded, color: avg >= 3.5 ? AppColors.secondary : AppColors.warning),
        StatCard(title: 'Cursos Activos', value: '${academic.totalCourses}', subtitle: 'Año lectivo 2026', icon: Icons.class_rounded, color: AppColors.purple),
      ],
    );
  }

  Widget _buildPerformanceChart(AcademicProvider academic) {
    final subjects = academic.subjects.take(6).toList();
    return AppCard(
      title: 'Rendimiento por Asignatura',
      titleAction: _periodBadge('Período 1'),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 5,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => AppColors.textPrimary,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${subjects[groupIndex].name}\n${rod.toY.toStringAsFixed(1)}',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= subjects.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(subjects[value.toInt()].code, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(subjects.length, (i) {
              double avg = 3.5 + (i % 3) * 0.3;
              final color = avg >= 4.0 ? AppColors.secondary : avg >= 3.0 ? AppColors.warning : AppColors.error;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: avg, color: color, width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              ]);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseRanking(AcademicProvider academic) {
    final courses = academic.courses;
    return AppCard(
      title: 'Ranking por Curso',
      child: Column(
        children: List.generate(courses.length, (i) {
          final avg = 3.2 + (courses.length - i) * 0.15;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: i < 3 ? AppColors.warning.withValues(alpha: 0.15) : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: i < 3 ? AppColors.warning : AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(courses[i].name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                GradeChip(grade: avg, compact: true),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPeriodProgress(AcademicProvider academic) {
    final periods = academic.activePeriods;
    return AppCard(
      title: 'Períodos Académicos',
      child: Column(
        children: periods.map((p) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.isOpen ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.isOpen ? 'Abierto' : 'Cerrado',
                      style: TextStyle(fontSize: 11, color: p.isOpen ? AppColors.secondary : AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${p.weight.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: p.isOpen ? 0.65 : (periods.indexOf(p) < periods.indexWhere((x) => x.isOpen) ? 1.0 : 0.0),
                backgroundColor: AppColors.border,
                color: p.isOpen ? AppColors.primary : AppColors.secondary,
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildRecentObservations(AcademicProvider academic) {
    final obs = academic.observations.take(4).toList();
    return AppCard(
      title: 'Observaciones Recientes',
      child: Column(
        children: obs.map((o) {
          final Color c;
          final IconData ic;
          switch (o.type) {
            case ObservationType.positive:
              c = AppColors.secondary; ic = Icons.thumb_up_rounded; break;
            case ObservationType.academic:
              c = AppColors.warning; ic = Icons.edit_note_rounded; break;
            case ObservationType.disciplinary:
              c = AppColors.error; ic = Icons.warning_rounded; break;
          }
          final student = academic.students.firstWhere((s) => s.id == o.studentId, orElse: () => academic.students.first);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: c.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(ic, color: c, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(o.title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _periodBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
