import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';
import '../shared/course_definitive_report.dart';
import '../shared/course_consolidated_report.dart';
import '../shared/student_bulletin_dialog.dart';
import '../shared/student_final_report_dialog.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  static const _finalReportValue = '__final__';

  late TabController _tabs;
  String? _selectedCourse;
  String? _selectedPeriod;
  String _teacherSearch = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Boletines'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Notas Definitivas y Puesto'),
              Tab(text: 'Consolidado de Áreas'),
              Tab(text: 'Carga Docente'),
              Tab(text: 'Exportar'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildBolettinesTab(academic),
              _buildStatsTab(academic),
              CourseDefinitiveReportView(courses: academic.courses),
              CourseConsolidatedReportView(courses: academic.courses),
              _buildTeacherLoadTab(academic),
              _buildExportTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBolettinesTab(AcademicProvider academic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Curso'),
                  items: academic.courses
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCourse = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Período'),
                  items: [
                    ...academic.activePeriods.map(
                      (p) =>
                          DropdownMenuItem(value: p.id, child: Text(p.name)),
                    ),
                    const DropdownMenuItem(
                      value: _finalReportValue,
                      child: Text('Informe Final'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _selectedPeriod = v),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Generar Todos'),
                onPressed: () => _showGenerateDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppCard(
            title: 'Boletines de Estudiantes',
            child: Column(
              children: academic.students
                  .where(
                    (s) =>
                        _selectedCourse == null ||
                        s.courseId == _selectedCourse,
                  )
                  .map((s) {
                    final course = academic.courseById(s.courseId ?? '');
                    final isFinal = _selectedPeriod == _finalReportValue;
                    final periodId = isFinal
                        ? null
                        : (_selectedPeriod ??
                              academic.currentOpenPeriod?.id ??
                              academic.activePeriods.firstOrNull?.id);
                    final period = periodId != null
                        ? academic.periodById(periodId)
                        : null;
                    final finalSummary = (isFinal && course != null)
                        ? computeFinalReportForCourse(academic, course)[s.id]
                        : null;
                    final avg = finalSummary != null
                        ? finalSummary.overallAvg
                        : periodId != null
                        ? academic.calculateOverallAverage(s.id, periodId)
                        : 0.0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.student.withValues(
                              alpha: 0.1,
                            ),
                            child: Text(
                              s.firstName.substring(0, 1),
                              style: const TextStyle(
                                color: AppColors.student,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  course?.name ?? 'Sin curso',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          avg > 0
                              ? GradeChip(grade: avg, compact: true)
                              : const SizedBox.shrink(),
                          const SizedBox(width: 12),
                          _buildBtnGroup(context, s, course, period, isFinal),
                        ],
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBtnGroup(
    BuildContext context,
    Student student,
    Course? course,
    AcademicPeriod? period,
    bool isFinal,
  ) {
    final enabled = course != null && (isFinal || period != null);
    void openBulletin() => isFinal
        ? StudentFinalReportDialog.show(
            context,
            student: student,
            course: course!,
          )
        : StudentBulletinDialog.show(
            context,
            student: student,
            course: course!,
            period: period!,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.visibility_rounded, size: 14),
          label: const Text('Ver', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
          ),
          onPressed: enabled ? openBulletin : null,
        ),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 14),
          label: const Text('PDF', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
          ),
          onPressed: enabled ? openBulletin : null,
        ),
      ],
    );
  }

  Widget _buildStatsTab(AcademicProvider academic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAverageBySubjectChart(academic)),
              const SizedBox(width: 16),
              Expanded(child: _buildGradeDistChart()),
            ],
          ),
          const SizedBox(height: 16),
          _buildInstitutionalStats(academic),
        ],
      ),
    );
  }

  Widget _buildAverageBySubjectChart(AcademicProvider academic) {
    final subjects = academic.subjects.take(6).toList();
    return AppCard(
      title: 'Promedio por Asignatura',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: AppColors.border, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (v, m) => Text(
                    v.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, m) {
                    final i = v.toInt();
                    if (i >= subjects.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subjects[i].code,
                        style: const TextStyle(fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 5,
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  subjects.length,
                  (i) => FlSpot(i.toDouble(), 3.2 + (i * 0.2)),
                ),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeDistChart() {
    return AppCard(
      title: 'Distribución de Notas',
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: 15,
                color: AppColors.secondary,
                title: 'Superior\n15%',
                radius: 70,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PieChartSectionData(
                value: 40,
                color: AppColors.primary,
                title: 'Alto\n40%',
                radius: 70,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PieChartSectionData(
                value: 30,
                color: AppColors.warning,
                title: 'Básico\n30%',
                radius: 70,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              PieChartSectionData(
                value: 15,
                color: AppColors.error,
                title: 'Bajo\n15%',
                radius: 70,
                titleStyle: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionalStats(AcademicProvider academic) {
    return AppCard(
      title: 'Resumen Institucional',
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 90,
        ),
        children: [
          StatCard(
            title: 'Promedio General',
            value: academic.institutionalAverage.toStringAsFixed(1),
            icon: Icons.bar_chart_rounded,
            color: AppColors.primary,
          ),
          StatCard(
            title: 'Estudiantes Aprobados',
            value: '78%',
            icon: Icons.check_circle_rounded,
            color: AppColors.secondary,
          ),
          StatCard(
            title: 'En riesgo académico',
            value: '12',
            icon: Icons.warning_rounded,
            color: AppColors.warning,
          ),
          StatCard(
            title: 'Asistencia promedio',
            value: '92%',
            icon: Icons.fact_check_rounded,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    final options = [
      (
        'Boletines en PDF',
        'Genera todos los boletines del período actual',
        Icons.picture_as_pdf_rounded,
        AppColors.error,
      ),
      (
        'Consolidado en Excel',
        'Exporta todas las calificaciones en formato Excel',
        Icons.table_chart_rounded,
        AppColors.secondary,
      ),
      (
        'Listado de estudiantes',
        'Excel con información completa de estudiantes',
        Icons.people_rounded,
        AppColors.primary,
      ),
      (
        'Reporte de asistencia',
        'PDF con el registro de asistencia del período',
        Icons.fact_check_rounded,
        AppColors.warning,
      ),
      (
        'Estadísticas institucionales',
        'PDF con gráficos y análisis del desempeño',
        Icons.analytics_rounded,
        AppColors.purple,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Exportar Reportes',
            subtitle: 'Descarga reportes en diferentes formatos',
          ),
          const SizedBox(height: 20),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 90,
            ),
            children: options
                .map((o) => _buildExportCard(o.$1, o.$2, o.$3, o.$4))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generando: $title...'), backgroundColor: color),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.download_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  void _showGenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Generar Boletines'),
          ],
        ),
        content: const Text(
          '¿Deseas generar los boletines para todos los estudiantes del período seleccionado?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generando boletines...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: const Text('Generar'),
          ),
        ],
      ),
    );
  }

  // ─── Carga Docente ──────────────────────────────────────────────────────

  Widget _buildTeacherLoadTab(AcademicProvider academic) {
    final query = _teacherSearch.toLowerCase();
    final teachers = academic.teachers
        .where((t) => t.fullName.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Carga Académica de Docentes',
            subtitle: 'Cursos y asignaturas a cargo de cada docente',
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _teacherSearch = v),
            decoration: const InputDecoration(
              hintText: 'Buscar docente...',
              prefixIcon: Icon(Icons.search_rounded, size: 18),
              isDense: true,
            ),
          ),
          const SizedBox(height: 20),
          if (teachers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No hay docentes registrados.')),
            )
          else
            ...teachers.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _teacherLoadCard(academic, t),
              ),
            ),
        ],
      ),
    );
  }

  Widget _teacherLoadCard(AcademicProvider academic, Teacher teacher) {
    final assignments = academic.assignmentsForTeacher(teacher.id);
    final byCourse = <String, List<SubjectAssignment>>{};
    for (final a in assignments) {
      byCourse.putIfAbsent(a.courseId, () => []).add(a);
    }
    final courseIds = byCourse.keys.toList()
      ..sort((a, b) {
        final ca = academic.courseById(a);
        final cb = academic.courseById(b);
        return (ca?.name ?? '').compareTo(cb?.name ?? '');
      });

    final totalHours = assignments.fold<int>(0, (sum, a) {
      final subj = academic.subjectById(a.subjectId);
      return sum + (subj?.hoursPerWeek ?? 0);
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.teacher.withValues(alpha: 0.12),
                  child: Text(
                    teacher.firstName.isNotEmpty
                        ? teacher.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.teacher,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        teacher.specialization.isEmpty
                            ? 'Sin especialización registrada'
                            : teacher.specialization,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _loadStat(
                  '${courseIds.length}',
                  courseIds.length == 1 ? 'Curso' : 'Cursos',
                ),
                const SizedBox(width: 16),
                _loadStat('$totalHours', 'Horas/sem'),
              ],
            ),
          ),
          if (courseIds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sin asignaturas ni cursos asignados todavía.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: courseIds.map((courseId) {
                  final course = academic.courseById(courseId);
                  final subjects = byCourse[courseId]!
                      .map(
                        (a) => academic.subjectById(a.subjectId)?.name ?? '—',
                      )
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            course?.name ?? 'Curso eliminado',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: subjects
                                .map(
                                  (name) => Chip(
                                    label: Text(
                                      name,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor: AppColors.primary
                                        .withValues(alpha: 0.08),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _loadStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
