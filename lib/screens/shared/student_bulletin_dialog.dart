import 'package:sistema_academico/core/utils/download_helper.dart';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_scale.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';

/// Boletín / informe de evaluación de un estudiante en un período,
/// agrupado por área (con I.H. y bullets de indicadores por asignatura),
/// comportamiento y promedios. Usado por el padre/madre (bulletin_screen)
/// y por coordinador/administrador (reports_screen), con datos reales.
class StudentBulletinDialog extends StatelessWidget {
  const StudentBulletinDialog({
    super.key,
    required this.student,
    required this.course,
    required this.period,
    required this.areas,
    required this.areaAverages,
    required this.grades,
    required this.avg,
    required this.rank,
    required this.courseAvg,
    required this.behavior,
  });

  final Student student;
  final Course course;
  final AcademicPeriod period;
  final Map<String, List<Subject>> areas;
  final Map<String, double> areaAverages;
  final Map<String, double> grades;
  final double avg;
  final int rank;
  final double courseAvg;
  final BehaviorAssessment? behavior;

  /// Calcula todos los datos del boletín desde el provider y lo muestra.
  static void show(
    BuildContext context, {
    required Student student,
    required Course course,
    required AcademicPeriod period,
  }) {
    final academic = context.read<AcademicProvider>();
    final subjects = academic.subjectsForCourse(course.id);

    final grades = {
      for (final s in subjects)
        s.id: academic.calculateSubjectPeriodGrade(student.id, s.id, period.id),
    };

    final areas = academic.subjectsByArea(course.id);
    final areaAverages = {
      for (final e in areas.entries)
        e.key: academic.areaGradeForStudent(student.id, period.id, e.value),
    };

    final avg = academic.overallAverageForPeriod(
      student.id,
      course.id,
      period.id,
    );
    final rank = academic.rankInCourse(student.id, course.id, period.id);

    final courseReport = academic.courseDefinitiveReport(course.id, period.id);
    final courseAvgs = courseReport
        .map((r) => r.average)
        .where((a) => a > 0)
        .toList();
    final courseAvg = courseAvgs.isEmpty
        ? 0.0
        : courseAvgs.reduce((a, b) => a + b) / courseAvgs.length;

    final behavior = academic.behaviorFor(student.id, period.id);

    showDialog(
      context: context,
      builder: (_) => StudentBulletinDialog(
        student: student,
        course: course,
        period: period,
        areas: areas,
        areaAverages: areaAverages,
        grades: grades,
        avg: avg,
        rank: rank,
        courseAvg: courseAvg,
        behavior: behavior,
      ),
    );
  }

  List<({Standard standard, double? grade, List<String> indicatorDescriptions})>
  _standardBreakdown(BuildContext context, Subject subject) {
    final academic = context.read<AcademicProvider>();
    final standards = academic.standardsForSubjectAndPeriod(
      subject.id,
      period.id,
    );
    return [
      for (final std in standards)
        (
          standard: std,
          grade: academic.standardGradeForStudent(
            student.id,
            subject.id,
            period.id,
            std.id,
          ),
          indicatorDescriptions: [
            for (final ind in academic.indicatorsForStandard(std.id))
              ind.description,
          ],
        ),
    ];
  }

  int _areaHours(List<Subject> subjects) =>
      subjects.fold(0, (a, s) => a + s.hoursPerWeek);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          children: [
            _dialogHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Center(child: _buildPage(context)),
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
            onPressed: () => _exportPDF(context),
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

  static const _colName = 240.0;
  static const _colIH = 50.0;
  static const _colGrade = 70.0;
  static const _colPerf = 80.0;

  Widget _buildPage(BuildContext context) {
    return Container(
      width: _colName + _colIH + _colGrade + _colPerf + 48,
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
          _gradesSection(context),
          _behaviorBlock(),
          _summaryBlock(),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COLEGIO SAN JOSÉ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'INFORME DE EVALUACIÓN — ${period.name.toUpperCase()}',
                    style: const TextStyle(
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
      child: Wrap(
        spacing: 28,
        runSpacing: 8,
        children: [
          _infoItem('ESTUDIANTE', student.fullName),
          _infoItem('DOCUMENTO', student.documentId),
          _infoItem('CURSO', course.name),
          _infoItem('PERÍODO', period.name),
          _infoItem('PUESTO EN EL CURSO', avg > 0 ? '$rank°' : '—'),
        ],
      ),
    );
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

  Widget _gradesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tableHeaderRow(),
          const Divider(height: 1, color: Color(0xFFCBD5E1)),
          for (final entry in areas.entries) _areaBlock(context, entry),
        ],
      ),
    );
  }

  Widget _tableHeaderRow() {
    return Container(
      color: const Color(0xFF1E3A8A),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: _colName,
            child: const Text(
              'Asignatura',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(
            width: _colIH,
            child: const Text(
              'I.H.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(
            width: _colGrade,
            child: const Text(
              'Definitiva',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          SizedBox(
            width: _colPerf,
            child: const Text(
              'Desempeño',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaBlock(BuildContext context, MapEntry<String, List<Subject>> e) {
    final areaAvg = areaAverages[e.key] ?? 0.0;
    final areaColor = performanceColor(areaAvg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: const Color(0xFFEEF2FF),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: _colName,
                child: Text(
                  e.key.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
              SizedBox(
                width: _colIH,
                child: Text(
                  '${_areaHours(e.value)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: _colGrade,
                child: Text(
                  areaAvg > 0 ? areaAvg.toStringAsFixed(1) : '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: areaColor,
                  ),
                ),
              ),
              SizedBox(
                width: _colPerf,
                child: Text(
                  performanceLabel(areaAvg),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: areaColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final s in e.value) _subjectBlock(context, s),
      ],
    );
  }

  Widget _subjectBlock(BuildContext context, Subject s) {
    final g = grades[s.id] ?? 0.0;
    final color = performanceColor(g);
    final standards = _standardBreakdown(context, s);
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: _colName,
                child: Text(s.name, style: const TextStyle(fontSize: 12)),
              ),
              SizedBox(
                width: _colIH,
                child: Text(
                  '${s.hoursPerWeek}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              SizedBox(
                width: _colGrade,
                child: Text(
                  g > 0 ? g.toStringAsFixed(1) : '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              SizedBox(
                width: _colPerf,
                child: Text(
                  g > 0 ? performanceLabel(g) : '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (standards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: standards
                    .map((std) => _standardRow(std))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _standardRow(
    ({Standard standard, double? grade, List<String> indicatorDescriptions})
    std,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  std.standard.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              Text(
                std.grade != null ? std.grade!.toStringAsFixed(1) : '—',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: std.grade != null
                      ? performanceColor(std.grade!)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (std.indicatorDescriptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: std.indicatorDescriptions
                    .map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '•  $b',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _behaviorBlock() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COMPORTAMIENTO',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              if (behavior != null)
                Text(
                  behavior!.performanceLevel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: performanceColor(
                      behavior!.performanceLevel == 'Superior'
                          ? GradeScale.max
                          : behavior!.performanceLevel == 'Alto'
                          ? GradeScale.alto
                          : behavior!.performanceLevel == 'Básico'
                          ? GradeScale.basico
                          : GradeScale.min,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            behavior?.description.isNotEmpty == true
                ? behavior!.description
                : 'Sin registro de comportamiento para este período.',
            style: TextStyle(
              fontSize: 12,
              color: behavior != null
                  ? const Color(0xFF1E293B)
                  : AppColors.textSecondary,
              fontStyle: behavior != null ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBlock() {
    final perfColor = performanceColor(avg);
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
            'PROM. ESTUDIANTE',
            avg > 0 ? avg.toStringAsFixed(2) : '—',
            perfColor,
          ),
          Container(width: 1, height: 44, color: const Color(0xFFCBD5E1)),
          _statBox('DESEMPEÑO', avg > 0 ? performanceLabel(avg) : '—', perfColor),
          Container(width: 1, height: 44, color: const Color(0xFFCBD5E1)),
          _statBox(
            'PUESTO EN EL CURSO',
            avg > 0 ? '$rank°' : '—',
            AppColors.parent,
          ),
          Container(width: 1, height: 44, color: const Color(0xFFCBD5E1)),
          _statBox(
            'PROM. CURSO',
            courseAvg > 0 ? courseAvg.toStringAsFixed(2) : '—',
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

  Future<void> _exportPDF(BuildContext context) async {
    final doc = pw.Document();
    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();
    final italic = pw.Font.helveticaOblique();

    const navy = PdfColor(0.118, 0.227, 0.541);
    const lightBg = PdfColor(0.941, 0.965, 1.0);
    const areaBg = PdfColor(0.933, 0.945, 1.0);
    const borderC = PdfColors.grey400;

    PdfColor pColor(double g) {
      if (g <= 0) return PdfColors.grey600;
      if (g >= GradeScale.superior) return const PdfColor(0.145, 0.388, 0.922);
      if (g >= GradeScale.alto) return const PdfColor(0.063, 0.725, 0.506);
      if (g >= GradeScale.basico) return const PdfColor(0.961, 0.620, 0.043);
      return const PdfColor(0.937, 0.267, 0.267);
    }

    // La fuente Base14 (Helvetica) del paquete `pdf` no incluye glifos para
    // "—" (em dash) ni "•" (bullet); se usan equivalentes ASCII para evitar
    // cuadros rotos en el PDF (la vista en pantalla sí puede usar los
    // originales porque Flutter usa las fuentes del sistema).
    const pdfDash = '-';
    String pdfLabel(double g) {
      final l = performanceLabel(g);
      return l == '—' ? pdfDash : l;
    }

    final standardsBySubject = <
      Subject,
      List<({Standard standard, double? grade, List<String> indicatorDescriptions})>
    >{
      for (final list in areas.values)
        for (final s in list) s: _standardBreakdown(context, s),
    };

    pw.Widget rowCell(String text, double w, {bool center = false, pw.Font? font, PdfColor? color, double size = 9}) {
      return pw.Container(
        width: w,
        child: pw.Text(
          text,
          textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(font: font ?? regular, fontSize: size, color: color ?? PdfColors.black),
        ),
      );
    }

    const colName = 220.0, colIH = 45.0, colGrade = 60.0, colPerf = 70.0;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Container(
            decoration: const pw.BoxDecoration(color: navy),
            padding: const pw.EdgeInsets.all(14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'COLEGIO SAN JOSÉ',
                  style: pw.TextStyle(font: bold, fontSize: 16, color: PdfColors.white, letterSpacing: 2),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'INFORME DE EVALUACIÓN - ${period.name.toUpperCase()}',
                  style: pw.TextStyle(font: regular, fontSize: 9, color: const PdfColor(0.749, 0.851, 1.0), letterSpacing: 1.2),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(color: lightBg, border: pw.Border.all(color: borderC, width: 0.5)),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                _pInfoItem(bold, 'ESTUDIANTE', student.fullName),
                _pInfoItem(bold, 'DOCUMENTO', student.documentId),
                _pInfoItem(bold, 'CURSO', course.name),
                _pInfoItem(bold, 'PERÍODO', period.name),
                _pInfoItem(bold, 'PUESTO', avg > 0 ? '$rank°' : pdfDash),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            color: navy,
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: pw.Row(
              children: [
                rowCell('Asignatura', colName, font: bold, color: PdfColors.white),
                rowCell('I.H.', colIH, center: true, font: bold, color: PdfColors.white),
                rowCell('Definitiva', colGrade, center: true, font: bold, color: PdfColors.white),
                rowCell('Desempeño', colPerf, center: true, font: bold, color: PdfColors.white),
              ],
            ),
          ),
          for (final entry in areas.entries) ...[
            pw.Container(
              color: areaBg,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: pw.Row(
                children: [
                  rowCell(entry.key.toUpperCase(), colName, font: bold, color: navy),
                  rowCell('${_areaHours(entry.value)}', colIH, center: true, font: bold),
                  rowCell(
                    (areaAverages[entry.key] ?? 0.0) > 0
                        ? (areaAverages[entry.key] ?? 0.0).toStringAsFixed(1)
                        : pdfDash,
                    colGrade,
                    center: true,
                    font: bold,
                    color: pColor(areaAverages[entry.key] ?? 0.0),
                  ),
                  rowCell(
                    pdfLabel(areaAverages[entry.key] ?? 0.0),
                    colPerf,
                    center: true,
                    font: bold,
                    color: pColor(areaAverages[entry.key] ?? 0.0),
                  ),
                ],
              ),
            ),
            for (final s in entry.value)
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: borderC, width: 0.4)),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        rowCell(s.name, colName),
                        rowCell('${s.hoursPerWeek}', colIH, center: true),
                        rowCell(
                          (grades[s.id] ?? 0) > 0 ? grades[s.id]!.toStringAsFixed(1) : pdfDash,
                          colGrade,
                          center: true,
                          font: bold,
                          color: pColor(grades[s.id] ?? 0),
                        ),
                        rowCell(
                          (grades[s.id] ?? 0) > 0 ? pdfLabel(grades[s.id]!) : pdfDash,
                          colPerf,
                          center: true,
                          font: bold,
                          color: pColor(grades[s.id] ?? 0),
                        ),
                      ],
                    ),
                    if ((standardsBySubject[s] ?? []).isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 6, top: 3),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: (standardsBySubject[s] ?? [])
                              .map(
                                (std) => pw.Padding(
                                  padding: const pw.EdgeInsets.only(bottom: 2),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Row(
                                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Text(
                                            std.standard.name,
                                            style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.grey800),
                                          ),
                                          pw.Text(
                                            std.grade != null ? std.grade!.toStringAsFixed(1) : pdfDash,
                                            style: pw.TextStyle(
                                              font: bold,
                                              fontSize: 8,
                                              color: std.grade != null ? pColor(std.grade!) : PdfColors.grey600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      for (final b in std.indicatorDescriptions)
                                        pw.Padding(
                                          padding: const pw.EdgeInsets.only(left: 6, top: 1),
                                          child: pw.Text(
                                            '-  $b',
                                            style: pw.TextStyle(font: regular, fontSize: 7.5, color: PdfColors.grey700),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
          ],
          pw.SizedBox(height: 10),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(color: borderC, width: 0.5)),
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'COMPORTAMIENTO',
                      style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.grey600, letterSpacing: 0.8),
                    ),
                    if (behavior != null)
                      pw.Text(
                        behavior!.performanceLevel.toUpperCase(),
                        style: pw.TextStyle(font: bold, fontSize: 9, color: navy),
                      ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  behavior?.description.isNotEmpty == true
                      ? behavior!.description
                      : 'Sin registro de comportamiento para este período.',
                  style: pw.TextStyle(
                    font: behavior != null ? regular : italic,
                    fontSize: 9,
                    color: behavior != null ? PdfColors.black : PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            decoration: pw.BoxDecoration(color: lightBg, border: pw.Border.all(color: borderC, width: 0.5)),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _pStat(bold, regular, 'PROM. ESTUDIANTE', avg > 0 ? avg.toStringAsFixed(2) : pdfDash, pColor(avg)),
                _pStat(bold, regular, 'DESEMPEÑO', avg > 0 ? pdfLabel(avg) : pdfDash, pColor(avg)),
                _pStat(bold, regular, 'PUESTO EN EL CURSO', avg > 0 ? '$rank°' : pdfDash, const PdfColor(0.404, 0.227, 0.718)),
                _pStat(bold, regular, 'PROM. CURSO', courseAvg > 0 ? courseAvg.toStringAsFixed(2) : pdfDash, navy),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
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
    );

    final bytes = await doc.save();
    final filename =
        'boletin_${student.fullName.replaceAll(' ', '_')}_${period.name.replaceAll(' ', '_')}.pdf';
    downloadBytes(bytes, filename);
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  pw.Widget _pInfoItem(pw.Font bold, String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 7, color: PdfColors.grey600, letterSpacing: 0.5)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 10, color: const PdfColor(0.118, 0.227, 0.541))),
      ],
    );
  }

  pw.Widget _pStat(pw.Font bold, pw.Font regular, String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 14, color: color)),
        pw.SizedBox(height: 3),
        pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(font: regular, fontSize: 7, color: PdfColors.grey600, letterSpacing: 0.5),
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
        pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 7.5, color: PdfColors.grey600)),
      ],
    );
  }
}
