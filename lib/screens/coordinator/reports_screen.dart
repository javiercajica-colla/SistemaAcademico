import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _selectedCourse;
  String? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
                  items: academic.activePeriods
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
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
                    final avg = academic.calculateOverallAverage(
                      s.id,
                      _selectedPeriod ?? 'ap1',
                    );
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
                          _buildBtnGroup(context, s.fullName),
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

  Widget _buildBtnGroup(BuildContext context, String studentName) {
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
          onPressed: () => _showBoletinPreview(context, studentName),
        ),
        const SizedBox(width: 6),
        ElevatedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 14),
          label: const Text('PDF', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
          ),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Descargando boletín de $studentName...'),
              backgroundColor: AppColors.primary,
            ),
          ),
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

  void _showBoletinPreview(BuildContext context, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'INSTITUCIÓN EDUCATIVA COLEGIO SAN JOSÉ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Boletín de Calificaciones',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Estudiante: $studentName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Calificaciones período 1 — Año 2026',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: AppColors.border),
                children: [
                  const TableRow(
                    decoration: BoxDecoration(color: AppColors.surfaceVariant),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Asignatura',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Nota P1',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...[
                    'Matemáticas',
                    'Español',
                    'Ciencias Naturales',
                    'Inglés',
                  ].map(
                    (s) => TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(s, style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            (3.5 + 0.5).toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Descargar PDF'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
