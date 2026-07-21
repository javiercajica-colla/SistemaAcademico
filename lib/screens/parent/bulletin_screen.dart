import 'package:sistema_academico/core/utils/download_helper.dart';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

class BulletinScreen extends StatefulWidget {
  const BulletinScreen({super.key});

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  String? _selectedPeriodId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final academic = context.read<AcademicProvider>();
    _selectedPeriodId ??=
        academic.currentOpenPeriod?.id ??
        academic.activePeriods.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    final parent = academic.parentByUserId(auth.currentUser!.id);

    if (parent == null) {
      return const Center(
        child: Text('No se encontró el perfil de padre/madre.'),
      );
    }

    final children = academic.studentsForParent(parent.id);
    final periods = academic.activePeriods;

    return Column(
      children: [
        _buildHeader(periods),
        const Divider(height: 1),
        Expanded(
          child: children.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: children.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildStudentCard(
                      context,
                      academic,
                      parent,
                      children[i],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(List<AcademicPeriod> periods) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      color: AppColors.surface,
      child: Row(
        children: [
          const Text(
            'Período:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 8,
            children: periods.map((p) {
              final sel = p.id == _selectedPeriodId;
              return ChoiceChip(
                label: Text(p.name),
                selected: sel,
                onSelected: (_) => setState(() => _selectedPeriodId = p.id),
                selectedColor: AppColors.parent,
                labelStyle: TextStyle(
                  color: sel ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text(
            'No tiene estudiantes registrados.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    AcademicProvider academic,
    Parent parent,
    Student student,
  ) {
    final course = student.courseId != null
        ? academic.courseById(student.courseId!)
        : null;
    final period = _selectedPeriodId != null
        ? academic.periodById(_selectedPeriodId!)
        : null;

    final subjects = course != null
        ? academic.subjectsForCourse(course.id)
        : <Subject>[];

    final avg = (course != null && _selectedPeriodId != null)
        ? academic.overallAverageForPeriod(
            student.id,
            course.id,
            _selectedPeriodId!,
          )
        : 0.0;
    final rank = (course != null && _selectedPeriodId != null)
        ? academic.rankInCourse(student.id, course.id, _selectedPeriodId!)
        : 0;
    final total = course != null
        ? academic.studentsInCourse(course.id).length
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.parent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: const Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.parent.withValues(alpha: 0.15),
                  child: Text(
                    student.firstName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.parent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${course?.name ?? "Sin curso"} · ${period?.name ?? "—"}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Summary chips
                if (avg > 0) ...[
                  _summaryChip(
                    avg.toStringAsFixed(1),
                    'Promedio',
                    _performanceColor(avg),
                  ),
                  const SizedBox(width: 8),
                  _summaryChip('$rank°', 'Puesto', AppColors.parent),
                ],
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.article_rounded, size: 15),
                  label: const Text('Ver Boletín'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.parent,
                  ),
                  onPressed: (course != null && period != null)
                      ? () => _showBulletin(
                          context,
                          academic,
                          parent,
                          student,
                          course,
                          period,
                          subjects,
                          avg,
                          rank,
                          total,
                        )
                      : null,
                ),
              ],
            ),
          ),
          // Mini grade table preview
          if (subjects.isNotEmpty && _selectedPeriodId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: _buildMiniTable(academic, student, subjects),
            ),
        ],
      ),
    );
  }

  Widget _summaryChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTable(
    AcademicProvider academic,
    Student student,
    List<Subject> subjects,
  ) {
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder.all(color: AppColors.border, width: 0.5),
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: AppColors.parent.withValues(alpha: 0.08),
          ),
          children: [
            _tCell('Asignatura', isHeader: true, flex: true),
            _tCell('Nota', isHeader: true, center: true),
            _tCell('Desempeño', isHeader: true, center: true),
          ],
        ),
        ...subjects.map((s) {
          final g = academic.calculateSubjectPeriodGrade(
            student.id,
            s.id,
            _selectedPeriodId!,
          );
          final perf = _performanceLabel(g);
          final col = _performanceColor(g);
          return TableRow(
            children: [
              _tCell(s.name, flex: true),
              _tCell(
                g > 0 ? g.toStringAsFixed(1) : '—',
                center: true,
                color: g > 0 ? col : null,
              ),
              _tCell(
                g > 0 ? perf : '—',
                center: true,
                color: g > 0 ? col : null,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tCell(
    String text, {
    bool isHeader = false,
    bool flex = false,
    bool center = false,
    Color? color,
  }) {
    final w = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          color: color ?? AppColors.textPrimary,
        ),
      ),
    );
    return flex ? w : SizedBox(width: center ? 80 : 120, child: w);
  }

  // ─── Bulletin dialog ───────────────────────────────────────────────────────

  void _showBulletin(
    BuildContext context,
    AcademicProvider academic,
    Parent parent,
    Student student,
    Course course,
    AcademicPeriod period,
    List<Subject> subjects,
    double avg,
    int rank,
    int total,
  ) {
    final grades = {
      for (final s in subjects)
        s.id: academic.calculateSubjectPeriodGrade(student.id, s.id, period.id),
    };

    showDialog(
      context: context,
      builder: (_) => _BulletinDialog(
        parent: parent,
        student: student,
        course: course,
        period: period,
        subjects: subjects,
        grades: grades,
        avg: avg,
        rank: rank,
        total: total,
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static Color _performanceColor(double g) {
    if (g <= 0) return AppColors.textSecondary;
    if (g >= 9.0) return const Color(0xFF1565C0); // Superior - azul
    if (g >= 7.5) return const Color(0xFF2E7D32); // Alto - verde
    if (g >= 6.0) return const Color(0xFFE65100); // Básico - naranja
    return const Color(0xFFC62828); // Bajo - rojo
  }

  static String _performanceLabel(double g) {
    if (g <= 0) return '—';
    if (g >= 9.0) return 'Superior';
    if (g >= 7.5) return 'Alto';
    if (g >= 6.0) return 'Básico';
    return 'Bajo';
  }
}

// ─── Bulletin Dialog ────────────────────────────────────────────────────────

class _BulletinDialog extends StatelessWidget {
  const _BulletinDialog({
    required this.parent,
    required this.student,
    required this.course,
    required this.period,
    required this.subjects,
    required this.grades,
    required this.avg,
    required this.rank,
    required this.total,
  });

  final Parent parent;
  final Student student;
  final Course course;
  final AcademicPeriod period;
  final List<Subject> subjects;
  final Map<String, double> grades;
  final double avg;
  final int rank;
  final int total;

  static Color _perfColor(double g) {
    if (g <= 0) return AppColors.textSecondary;
    if (g >= 9.0) return const Color(0xFF1565C0);
    if (g >= 7.5) return const Color(0xFF2E7D32);
    if (g >= 6.0) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  static String _perfLabel(double g) {
    if (g <= 0) return '—';
    if (g >= 9.0) return 'Superior';
    if (g >= 7.5) return 'Alto';
    if (g >= 6.0) return 'Básico';
    return 'Bajo';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          children: [
            _dialogHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Center(child: _buildPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.article_rounded, color: AppColors.parent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boletín — ${student.fullName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${course.name} · ${period.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
            label: const Text('Descargar PDF'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: _exportPDF,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ─── Flutter page preview ────────────────────────────────────────────────

  Widget _buildPage() {
    return Container(
      width: 680,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeader(),
          _infoBlock(),
          _gradesTable(),
          _summaryBlock(),
          _observationsBlock(),
          _footerBlock(),
        ],
      ),
    );
  }

  Widget _pageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COLEGIO SAN JOSÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'BOLETÍN DE CALIFICACIONES',
                    style: TextStyle(
                      color: Color(0xFFBFD9FF),
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBlock() {
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
      child: Row(
        children: [
          Expanded(
            child: _infoRow([
              _infoItem('ESTUDIANTE', student.fullName),
              _infoItem('DOCUMENTO', student.documentId),
            ]),
          ),
          Container(width: 1, height: 48, color: const Color(0xFFCBD5E1)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _infoRow([
                _infoItem('CURSO', course.name),
                _infoItem('PERÍODO', period.name),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(List<Widget> items) {
    return Wrap(spacing: 24, runSpacing: 8, children: items);
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E3A8A),
          ),
        ),
      ],
    );
  }

  Widget _gradesTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'CALIFICACIONES POR ASIGNATURA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
          ),
          Table(
            border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.5),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FixedColumnWidth(70),
              2: FixedColumnWidth(100),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
                children: [
                  _th('Asignatura'),
                  _th('Nota', center: true),
                  _th('Desempeño', center: true),
                ],
              ),
              ...subjects.map((s) {
                final g = grades[s.id] ?? 0.0;
                final col = _perfColor(g);
                return TableRow(
                  children: [
                    _td(s.name),
                    _tdColored(
                      g > 0 ? g.toStringAsFixed(1) : '—',
                      col,
                      center: true,
                    ),
                    _tdColored(g > 0 ? _perfLabel(g) : '—', col, center: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _th(String text, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _td(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
      ),
    );
  }

  Widget _tdColored(String text, Color color, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _summaryBlock() {
    final perfColor = _perfColor(avg);
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statBox(
            'PROMEDIO GENERAL',
            avg > 0 ? avg.toStringAsFixed(2) : '—',
            perfColor,
          ),
          Container(width: 1, height: 44, color: const Color(0xFFCBD5E1)),
          _statBox('DESEMPEÑO', avg > 0 ? _perfLabel(avg) : '—', perfColor),
          Container(width: 1, height: 44, color: const Color(0xFFCBD5E1)),
          _statBox(
            'PUESTO EN EL CURSO',
            avg > 0 ? '$rank°' : '—',
            AppColors.parent,
          ),
          Container(width: 1, height: 44, color: const Color(0xFFCBD5E1)),
          _statBox(
            'TOTAL ASIGNATURAS',
            '${subjects.length}',
            AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _observationsBlock() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OBSERVACIONES GENERALES',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 48,
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFCBD5E1))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerBlock() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sigLine('Firma Director(a) de Grupo', 180),
          _sigLine('Firma Coordinador(a)', 180),
          _sigLine('Firma Padre/Madre/Acudiente', 180),
        ],
      ),
    );
  }

  Widget _sigLine(String label, double width) {
    return Column(
      children: [
        Container(width: width, height: 1, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ─── PDF Export ───────────────────────────────────────────────────────────

  Future<void> _exportPDF() async {
    final doc = pw.Document();
    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();

    const navy = PdfColor(0.118, 0.227, 0.541);
    const lightBg = PdfColor(0.941, 0.965, 1.0);
    const borderC = PdfColors.grey400;

    // Performance helpers
    PdfColor pColor(double g) {
      if (g <= 0) return PdfColors.grey600;
      if (g >= 9.0) return const PdfColor(0.082, 0.396, 0.753);
      if (g >= 7.5) return const PdfColor(0.18, 0.49, 0.20);
      if (g >= 6.0) return const PdfColor(0.90, 0.32, 0.0);
      return const PdfColor(0.78, 0.16, 0.16);
    }

    String pLabel(double g) {
      if (g <= 0) return '—';
      if (g >= 9.0) return 'Superior';
      if (g >= 7.5) return 'Alto';
      if (g >= 6.0) return 'Básico';
      return 'Bajo';
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            pw.Container(
              decoration: const pw.BoxDecoration(color: navy),
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'COLEGIO SAN JOSÉ',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 16,
                      color: PdfColors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'BOLETÍN DE CALIFICACIONES',
                    style: pw.TextStyle(
                      font: regular,
                      fontSize: 9,
                      color: const PdfColor(0.749, 0.851, 1.0),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            // ── Info block ──
            pw.Container(
              decoration: pw.BoxDecoration(
                color: lightBg,
                border: pw.Border.all(color: borderC, width: 0.5),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pInfoItem(bold, regular, 'ESTUDIANTE', student.fullName),
                  _pInfoItem(bold, regular, 'DOCUMENTO', student.documentId),
                  _pInfoItem(bold, regular, 'CURSO', course.name),
                  _pInfoItem(bold, regular, 'PERÍODO', period.name),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            // ── Section label ──
            pw.Text(
              'CALIFICACIONES POR ASIGNATURA',
              style: pw.TextStyle(
                font: bold,
                fontSize: 8,
                color: PdfColors.grey600,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 4),
            // ── Grades table ──
            pw.Table(
              border: pw.TableBorder.all(width: 0.4, color: borderC),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FixedColumnWidth(55),
                2: pw.FixedColumnWidth(80),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: navy),
                  children: [
                    _pTh(bold, 'Asignatura'),
                    _pTh(bold, 'Nota', center: true),
                    _pTh(bold, 'Desempeño', center: true),
                  ],
                ),
                ...subjects.asMap().entries.map((e) {
                  final s = e.value;
                  final g = grades[s.id] ?? 0.0;
                  final alt = e.key.isEven
                      ? PdfColors.white
                      : const PdfColor(0.973, 0.984, 1.0);
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: alt),
                    children: [
                      _pTd(regular, s.name),
                      _pTdC(
                        bold,
                        g > 0 ? g.toStringAsFixed(1) : '—',
                        pColor(g),
                      ),
                      _pTdC(bold, pLabel(g), pColor(g)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
            // ── Summary block ──
            pw.Container(
              decoration: pw.BoxDecoration(
                color: lightBg,
                border: pw.Border.all(color: borderC, width: 0.5),
              ),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pStat(
                    bold,
                    regular,
                    'PROMEDIO GENERAL',
                    avg > 0 ? avg.toStringAsFixed(2) : '—',
                    pColor(avg),
                  ),
                  _pStat(
                    bold,
                    regular,
                    'DESEMPEÑO',
                    avg > 0 ? pLabel(avg) : '—',
                    pColor(avg),
                  ),
                  _pStat(
                    bold,
                    regular,
                    'PUESTO EN EL CURSO',
                    avg > 0 ? '$rank°' : '—',
                    const PdfColor(0.404, 0.227, 0.718),
                  ),
                  _pStat(
                    bold,
                    regular,
                    'TOTAL ASIGNATURAS',
                    '${subjects.length}',
                    navy,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            // ── Observations ──
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: borderC, width: 0.5),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'OBSERVACIONES GENERALES',
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 8,
                      color: PdfColors.grey600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: borderC, thickness: 0.5),
                ],
              ),
            ),
            pw.Spacer(),
            // ── Signatures ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pSig(regular, 'Firma Director(a) de Grupo', 140),
                _pSig(regular, 'Firma Coordinador(a)', 140),
                _pSig(regular, 'Firma Padre/Madre/Acudiente', 140),
              ],
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    _downloadBytes(
      bytes,
      'boletin_${student.fullName.replaceAll(' ', '_')}_${period.name}.pdf',
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'boletin_${student.fullName.replaceAll(' ', '_')}_${period.name}.pdf',
    );
  }

  pw.Widget _pInfoItem(
    pw.Font bold,
    pw.Font regular,
    String label,
    String value,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: bold,
            fontSize: 7,
            color: PdfColors.grey600,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: bold,
            fontSize: 10,
            color: const PdfColor(0.118, 0.227, 0.541),
          ),
        ),
      ],
    );
  }

  pw.Widget _pTh(pw.Font bold, String text, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white),
      ),
    );
  }

  pw.Widget _pTd(pw.Font regular, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: regular,
          fontSize: 8.5,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _pTdC(
    pw.Font bold,
    String text,
    PdfColor color, {
    bool center = true,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(font: bold, fontSize: 8.5, color: color),
      ),
    );
  }

  pw.Widget _pStat(
    pw.Font bold,
    pw.Font regular,
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(font: bold, fontSize: 14, color: color),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            font: regular,
            fontSize: 7,
            color: PdfColors.grey600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  pw.Widget _pSig(pw.Font regular, String label, double width) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: width, height: 0.5, color: PdfColors.grey600),
        pw.SizedBox(height: 3),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regular,
            fontSize: 7.5,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  void _downloadBytes(List<int> bytes, String filename) {
    downloadBytes(bytes, filename);
  }
}
