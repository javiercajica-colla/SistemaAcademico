import 'package:sistema_academico/core/utils/download_helper.dart';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

class GradeFormatScreen extends StatefulWidget {
  const GradeFormatScreen({super.key});

  @override
  State<GradeFormatScreen> createState() => _GradeFormatScreenState();
}

class _GradeFormatScreenState extends State<GradeFormatScreen> {
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
    final teacher = academic.teacherByUserId(auth.currentUser!.id);

    if (teacher == null) {
      return const Center(child: Text('No se encontró el perfil de docente.'));
    }

    final assignments = academic.assignmentsForTeacher(teacher.id);
    final periods = academic.activePeriods;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(periods),
        const Divider(height: 1),
        Expanded(
          child: assignments.isEmpty
              ? const Center(
                  child: Text(
                    'No tiene asignaturas asignadas.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : _buildList(academic, teacher, assignments),
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
              final selected = p.id == _selectedPeriodId;
              return ChoiceChip(
                label: Text(p.name),
                selected: selected,
                onSelected: (_) => setState(() => _selectedPeriodId = p.id),
                selectedColor: AppColors.teacher,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    AcademicProvider academic,
    Teacher teacher,
    List<SubjectAssignment> assignments,
  ) {
    // Deduplicate by subjectId+courseId
    final seen = <String>{};
    final unique = assignments.where((a) {
      final key = '${a.subjectId}__${a.courseId}';
      return seen.add(key);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: unique.length,
      itemBuilder: (context, i) {
        final a = unique[i];
        final subject = academic.subjectById(a.subjectId);
        final course = academic.courseById(a.courseId);
        if (subject == null || course == null) return const SizedBox.shrink();

        final students = academic.studentsInCourse(course.id)
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
        final standards = _selectedPeriodId != null
            ? academic.standardsForSubjectAndPeriod(
                subject.id,
                _selectedPeriodId!,
              )
            : academic.standardsForSubject(subject.id);
        final period = _selectedPeriodId != null
            ? academic.periodById(_selectedPeriodId!)
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _AssignmentCard(
            teacher: teacher,
            subject: subject,
            course: course,
            period: period,
            students: students,
            standards: standards,
          ),
        );
      },
    );
  }
}

// ─── Card ──────────────────────────────────────────────────────────────────

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.teacher,
    required this.subject,
    required this.course,
    required this.period,
    required this.students,
    required this.standards,
  });

  final Teacher teacher;
  final Subject subject;
  final Course course;
  final AcademicPeriod? period;
  final List<Student> students;
  final List<Standard> standards;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.teacher.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppColors.teacher,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _chip(Icons.class_rounded, course.name),
                    _chip(
                      Icons.people_rounded,
                      '${students.length} estudiantes',
                    ),
                    _chip(
                      Icons.checklist_rounded,
                      standards.isEmpty
                          ? 'Sin estándares (4 columnas gen.)'
                          : '${standards.length} estándares',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            icon: const Icon(Icons.preview_rounded, size: 16),
            label: const Text('Vista Previa'),
            onPressed: () => _openPreview(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.teacher),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _openPreview(BuildContext context) {
    final cols = standards.isNotEmpty
        ? standards.map((s) => s.name).toList()
        : ['Nota 1', 'Nota 2', 'Nota 3', 'Nota 4'];

    showDialog(
      context: context,
      builder: (_) => _PreviewDialog(
        teacher: teacher,
        subject: subject,
        course: course,
        period: period,
        students: students,
        standards: standards,
        cols: cols,
      ),
    );
  }
}

// ─── Preview Dialog ────────────────────────────────────────────────────────

class _PreviewDialog extends StatelessWidget {
  const _PreviewDialog({
    required this.teacher,
    required this.subject,
    required this.course,
    required this.period,
    required this.students,
    required this.standards,
    required this.cols,
  });

  final Teacher teacher;
  final Subject subject;
  final Course course;
  final AcademicPeriod? period;
  final List<Student> students;
  final List<Standard> standards;
  final List<String> cols;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.92,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Column(
          children: [
            _buildDialogHeader(context),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(child: _buildPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.surface,
      child: Row(
        children: [
          const Icon(Icons.preview_rounded, color: AppColors.teacher, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subject.name}  ·  ${course.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Período: ${period?.name ?? "—"}  ·  ${students.length} estudiantes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                label: const Text('PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onPressed: () => _exportPDF(),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.table_chart_rounded, size: 15),
                label: const Text('Excel'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onPressed: () => _exportExcel(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Flutter page preview ─────────────────────────────────────────────

  Widget _buildPage() {
    return Container(
      width: 920,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pageHeader(),
          _infoBlock(),
          const Divider(height: 1, color: Color(0xFFCBD5E1)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _studentTable(),
          ),
          _pageFooter(),
        ],
      ),
    );
  }

  Widget _pageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'COLEGIO SAN JOSÉ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'FORMATO DE REGISTRO DE NOTAS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFBFD9FF),
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock() {
    return Container(
      color: const Color(0xFFF0F4FF),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Wrap(
        spacing: 32,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _infoItem('ASIGNATURA', subject.name),
          _infoItem('CURSO', course.name),
          _infoItem('PERÍODO', period?.name ?? '—'),
          _infoItem('DOCENTE', teacher.fullName),
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

  Widget _studentTable() {
    const headerColor = Color(0xFF1E3A8A);
    const headerTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    const cellTextStyle = TextStyle(color: Color(0xFF1E293B), fontSize: 11);
    const borderColor = Color(0xFFCBD5E1);

    return Table(
      border: TableBorder.all(color: borderColor, width: 0.5),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: headerColor),
          children: [
            _cell('#', headerTextStyle, 32, center: true),
            _cell('Apellidos y Nombres del Estudiante', headerTextStyle, 230),
            ...cols.map((c) => _cell(c, headerTextStyle, 80, center: true)),
            _cell('Promedio', headerTextStyle, 76, center: true),
            _cell('Observación', headerTextStyle, 100),
          ],
        ),
        // Rows
        ...students.asMap().entries.map((e) {
          final bg = e.key.isEven ? Colors.white : const Color(0xFFF8FAFC);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              _cell('${e.key + 1}', cellTextStyle, 32, bg: bg, center: true),
              _cell(e.value.fullName, cellTextStyle, 230, bg: bg),
              ...List.generate(
                cols.length,
                (_) => _cell('', cellTextStyle, 80, bg: bg),
              ),
              _cell('', cellTextStyle, 76, bg: bg),
              _cell('', cellTextStyle, 100, bg: bg),
            ],
          );
        }),
      ],
    );
  }

  Widget _cell(
    String text,
    TextStyle style,
    double width, {
    Color bg = Colors.white,
    bool center = false,
  }) {
    return Container(
      width: width,
      height: 26,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(
        text,
        style: style,
        textAlign: center ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _pageFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sigLine('Firma del Docente', 200),
          _sigLine('VoBo Coordinación', 200),
          Text(
            'Total estudiantes: ${students.length}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _sigLine(String label, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: width, height: 1, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  // ─── PDF export ────────────────────────────────────────────────────────

  Future<void> _exportPDF() async {
    final doc = pw.Document();
    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();

    const navy = PdfColor(0.118, 0.227, 0.541);
    const lightBlue = PdfColor(0.94, 0.965, 1.0);
    const altRow = PdfColor(0.973, 0.984, 1.0);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (_) => _pdfPageHeader(bold, regular, navy, lightBlue),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FixedColumnWidth(18),
              1: const pw.FixedColumnWidth(150),
              for (int i = 0; i < cols.length; i++)
                i + 2: const pw.FixedColumnWidth(58),
              cols.length + 2: const pw.FixedColumnWidth(52),
              cols.length + 3: const pw.FixedColumnWidth(70),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: navy),
                children: [
                  _pCell('#', bold, PdfColors.white, center: true),
                  _pCell('Apellidos y Nombres', bold, PdfColors.white),
                  ...cols.map(
                    (c) => _pCell(c, bold, PdfColors.white, center: true),
                  ),
                  _pCell('Promedio', bold, PdfColors.white, center: true),
                  _pCell('Observación', bold, PdfColors.white),
                ],
              ),
              ...students.asMap().entries.map((e) {
                final bg = e.key.isEven ? PdfColors.white : altRow;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _pCell(
                      '${e.key + 1}',
                      regular,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell(e.value.fullName, regular, PdfColors.black),
                    ...List.generate(
                      cols.length + 2,
                      (_) => _pCell('', regular, PdfColors.black),
                    ),
                    _pCell('', regular, PdfColors.black),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pSigLine(regular, 'Firma del Docente', 150),
              _pSigLine(regular, 'VoBo Coordinación', 150),
              pw.Text(
                'Total estudiantes: ${students.length}',
                style: pw.TextStyle(
                  font: regular,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          'formato_notas_${subject.name}_${course.name}_${period?.name ?? "sin_periodo"}.pdf',
    );
  }

  pw.Widget _pdfPageHeader(
    pw.Font bold,
    pw.Font regular,
    PdfColor navy,
    PdfColor lightBlue,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(color: navy),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'COLEGIO SAN JOSÉ',
            style: pw.TextStyle(
              font: bold,
              fontSize: 14,
              color: PdfColors.white,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'FORMATO DE REGISTRO DE NOTAS',
            style: pw.TextStyle(
              font: regular,
              fontSize: 8,
              color: const PdfColor(0.749, 0.851, 1.0),
              letterSpacing: 1,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _pHeaderInfo(bold, regular, 'ASIGNATURA', subject.name),
              _pHeaderInfo(bold, regular, 'CURSO', course.name),
              _pHeaderInfo(bold, regular, 'PERÍODO', period?.name ?? '—'),
              _pHeaderInfo(bold, regular, 'DOCENTE', teacher.fullName),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pHeaderInfo(
    pw.Font bold,
    pw.Font regular,
    String label,
    String value,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: bold,
            fontSize: 7,
            color: const PdfColor(0.58, 0.77, 1.0),
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white),
        ),
      ],
    );
  }

  pw.Widget _pCell(
    String text,
    pw.Font font,
    PdfColor color, {
    bool center = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: 2,
        style: pw.TextStyle(font: font, fontSize: 7.5, color: color),
      ),
    );
  }

  pw.Widget _pSigLine(pw.Font font, String label, double width) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: width, height: 0.5, color: PdfColors.grey600),
        pw.SizedBox(height: 3),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 7.5,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  // ─── Excel export ──────────────────────────────────────────────────────

  Future<void> _exportExcel() async {
    final xls = Excel.createExcel();
    xls.rename('Sheet1', 'Formato');
    final sheet = xls['Formato'];

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final subtitleStyle = CellStyle(
      bold: false,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#475569'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final labelStyle = CellStyle(
      bold: false,
      fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#64748B'),
    );
    final valueStyle = CellStyle(
      bold: true,
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#1E3A8A'),
    );
    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
      horizontalAlign: HorizontalAlign.Center,
    );

    // ── Info rows ──
    _xlCell(sheet, 0, 0, 'COLEGIO SAN JOSÉ', style: titleStyle);
    _xlCell(sheet, 1, 0, 'FORMATO DE REGISTRO DE NOTAS', style: subtitleStyle);
    _xlCell(sheet, 3, 0, 'Asignatura:', style: labelStyle);
    _xlCell(sheet, 3, 1, subject.name, style: valueStyle);
    _xlCell(sheet, 3, 4, 'Curso:', style: labelStyle);
    _xlCell(sheet, 3, 5, course.name, style: valueStyle);
    _xlCell(sheet, 4, 0, 'Período:', style: labelStyle);
    _xlCell(sheet, 4, 1, period?.name ?? '—', style: valueStyle);
    _xlCell(sheet, 4, 4, 'Docente:', style: labelStyle);
    _xlCell(sheet, 4, 5, teacher.fullName, style: valueStyle);

    // ── Table header (row 6) ──
    const hr = 6;
    _xlCell(sheet, hr, 0, '#', style: headerStyle);
    _xlCell(
      sheet,
      hr,
      1,
      'Apellidos y Nombres del Estudiante',
      style: headerStyle,
    );
    for (int c = 0; c < cols.length; c++) {
      _xlCell(sheet, hr, c + 2, cols[c], style: headerStyle);
    }
    _xlCell(sheet, hr, cols.length + 2, 'Promedio', style: headerStyle);
    _xlCell(sheet, hr, cols.length + 3, 'Observación', style: headerStyle);

    // ── Column widths ──
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 32);
    for (int c = 2; c < cols.length + 2; c++) {
      sheet.setColumnWidth(c, 14);
    }
    sheet.setColumnWidth(cols.length + 2, 13);
    sheet.setColumnWidth(cols.length + 3, 20);

    // ── Student rows ──
    for (int r = 0; r < students.length; r++) {
      final row = hr + 1 + r;
      final bg = r.isEven ? '#FFFFFF' : '#F8FAFC';
      final rowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(bg),
        fontColorHex: ExcelColor.fromHexString('#1E293B'),
      );
      _xlCell(sheet, row, 0, '${r + 1}', style: rowStyle);
      _xlCell(sheet, row, 1, students[r].fullName, style: rowStyle);
      for (int c = 2; c <= cols.length + 3; c++) {
        _xlCell(sheet, row, c, '', style: rowStyle);
      }
    }

    // ── Signature rows ──
    final sigRow = hr + 1 + students.length + 2;
    _xlCell(
      sheet,
      sigRow,
      0,
      'Firma Docente: ________________________________',
      style: labelStyle,
    );
    _xlCell(
      sheet,
      sigRow,
      cols.length + 1,
      'VoBo Coordinación: ________________________________',
      style: labelStyle,
    );

    final bytes = xls.encode();
    if (bytes != null) {
      _downloadBytes(
        bytes,
        'formato_notas_${subject.name}_${course.name}_${period?.name ?? "sin_periodo"}.xlsx',
      );
    }
  }

  void _xlCell(
    Sheet sheet,
    int row,
    int col,
    dynamic value, {
    CellStyle? style,
  }) {
    final cell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row),
    );
    if (value is String) {
      cell.value = TextCellValue(value);
    } else if (value is int) {
      cell.value = TextCellValue(value.toString());
    }
    if (style != null) cell.cellStyle = style;
  }

  void _downloadBytes(List<int> bytes, String filename) {
    downloadBytes(bytes, filename);
  }
}
