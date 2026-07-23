import 'package:sistema_academico/core/utils/download_helper.dart';

import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_scale.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';

/// Reporte de notas definitivas y puesto por curso: una fila por
/// estudiante, una columna por asignatura con la nota definitiva del
/// período, más Promedio y Puesto. Usado tanto por coordinador/admin
/// (todos los cursos) como por docentes (solo los cursos que dirigen).
class CourseDefinitiveReportView extends StatefulWidget {
  final List<Course> courses;
  final Color accentColor;
  final String emptyCoursesMessage;

  const CourseDefinitiveReportView({
    super.key,
    required this.courses,
    this.accentColor = AppColors.primary,
    this.emptyCoursesMessage = 'No hay cursos disponibles.',
  });

  @override
  State<CourseDefinitiveReportView> createState() =>
      _CourseDefinitiveReportViewState();
}

class _CourseDefinitiveReportViewState
    extends State<CourseDefinitiveReportView> {
  String? _selectedCourseId;
  String? _selectedPeriodId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final academic = context.read<AcademicProvider>();
    _selectedCourseId ??= widget.courses.firstOrNull?.id;
    _selectedPeriodId ??=
        academic.currentOpenPeriod?.id ??
        academic.activePeriods.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();

    if (widget.courses.isEmpty) {
      return Center(
        child: Text(
          widget.emptyCoursesMessage,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final course = widget.courses.firstWhere(
      (c) => c.id == _selectedCourseId,
      orElse: () => widget.courses.first,
    );
    final period = _selectedPeriodId != null
        ? academic.periodById(_selectedPeriodId!)
        : null;
    final subjects = academic.subjectsForCourse(course.id);
    final rows = period != null
        ? academic.courseDefinitiveReport(course.id, period.id)
        : <CourseReportRow>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(academic, course, period, subjects, rows),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: _ReportPage(
                course: course,
                period: period,
                subjects: subjects,
                rows: rows,
                accentColor: widget.accentColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(
    AcademicProvider academic,
    Course course,
    AcademicPeriod? period,
    List<Subject> subjects,
    List<CourseReportRow> rows,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCourseId,
              decoration: const InputDecoration(labelText: 'Curso'),
              items: widget.courses
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCourseId = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedPeriodId,
              decoration: const InputDecoration(labelText: 'Período'),
              items: academic.activePeriods
                  .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPeriodId = v),
            ),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('PDF'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: period == null || rows.isEmpty
                ? null
                : () => _exportPDF(course, period, subjects, rows),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.table_chart_rounded, size: 16),
            label: const Text('Excel'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            onPressed: period == null || rows.isEmpty
                ? null
                : () => _exportExcel(course, period, subjects, rows),
          ),
        ],
      ),
    );
  }

  // ─── PDF export ────────────────────────────────────────────────────────

  Future<void> _exportPDF(
    Course course,
    AcademicPeriod period,
    List<Subject> subjects,
    List<CourseReportRow> rows,
  ) async {
    final doc = pw.Document();
    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();

    const navy = PdfColor(0.118, 0.227, 0.541);
    const altRow = PdfColor(0.973, 0.984, 1.0);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        header: (_) => _pdfPageHeader(bold, regular, navy, course, period),
        build: (ctx) => [
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
            columnWidths: {
              0: const pw.FixedColumnWidth(18),
              1: const pw.FixedColumnWidth(150),
              for (int i = 0; i < subjects.length; i++)
                i + 2: const pw.FixedColumnWidth(42),
              subjects.length + 2: const pw.FixedColumnWidth(50),
              subjects.length + 3: const pw.FixedColumnWidth(40),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: navy),
                children: [
                  _pCell('#', bold, PdfColors.white, center: true),
                  _pCell('Apellidos y Nombres', bold, PdfColors.white),
                  ...subjects.map(
                    (s) => _pCell(s.code, bold, PdfColors.white, center: true),
                  ),
                  _pCell('Promedio', bold, PdfColors.white, center: true),
                  _pCell('Puesto', bold, PdfColors.white, center: true),
                ],
              ),
              ...rows.asMap().entries.map((e) {
                final bg = e.key.isEven ? PdfColors.white : altRow;
                final row = e.value;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _pCell('${e.key + 1}', regular, PdfColors.black, center: true),
                    _pCell(row.student.fullName, regular, PdfColors.black),
                    ...subjects.map((s) {
                      final g = row.gradeBySubjectId[s.id] ?? 0.0;
                      return _pCell(
                        g > 0 ? g.toStringAsFixed(1) : '-',
                        regular,
                        PdfColors.black,
                        center: true,
                      );
                    }),
                    _pCell(
                      row.average.toStringAsFixed(1),
                      bold,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell('${row.rank}°', bold, navy, center: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'notas_definitivas_${course.name}_${period.name}.pdf',
    );
  }

  pw.Widget _pdfPageHeader(
    pw.Font bold,
    pw.Font regular,
    PdfColor navy,
    Course course,
    AcademicPeriod period,
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
            'NOTAS DEFINITIVAS Y PUESTO POR CURSO',
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
              _pHeaderInfo(bold, regular, 'CURSO', course.name),
              _pHeaderInfo(bold, regular, 'PERÍODO', period.name),
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

  // ─── Excel export ──────────────────────────────────────────────────────

  Future<void> _exportExcel(
    Course course,
    AcademicPeriod period,
    List<Subject> subjects,
    List<CourseReportRow> rows,
  ) async {
    final xls = Excel.createExcel();
    xls.rename('Sheet1', 'Notas Definitivas');
    final sheet = xls['Notas Definitivas'];

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

    _xlCell(sheet, 0, 0, 'COLEGIO SAN JOSÉ', style: titleStyle);
    _xlCell(
      sheet,
      1,
      0,
      'NOTAS DEFINITIVAS Y PUESTO POR CURSO',
      style: subtitleStyle,
    );
    _xlCell(sheet, 3, 0, 'Curso:', style: labelStyle);
    _xlCell(sheet, 3, 1, course.name, style: valueStyle);
    _xlCell(sheet, 3, 4, 'Período:', style: labelStyle);
    _xlCell(sheet, 3, 5, period.name, style: valueStyle);

    const hr = 5;
    _xlCell(sheet, hr, 0, '#', style: headerStyle);
    _xlCell(
      sheet,
      hr,
      1,
      'Apellidos y Nombres del Estudiante',
      style: headerStyle,
    );
    for (int c = 0; c < subjects.length; c++) {
      _xlCell(sheet, hr, c + 2, subjects[c].code, style: headerStyle);
    }
    _xlCell(sheet, hr, subjects.length + 2, 'Promedio', style: headerStyle);
    _xlCell(sheet, hr, subjects.length + 3, 'Puesto', style: headerStyle);

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 32);
    for (int c = 2; c < subjects.length + 2; c++) {
      sheet.setColumnWidth(c, 10);
    }
    sheet.setColumnWidth(subjects.length + 2, 12);
    sheet.setColumnWidth(subjects.length + 3, 10);

    for (int r = 0; r < rows.length; r++) {
      final row = hr + 1 + r;
      final bg = r.isEven ? '#FFFFFF' : '#F8FAFC';
      final rowStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString(bg),
        fontColorHex: ExcelColor.fromHexString('#1E293B'),
      );
      final data = rows[r];
      _xlCell(sheet, row, 0, '${r + 1}', style: rowStyle);
      _xlCell(sheet, row, 1, data.student.fullName, style: rowStyle);
      for (int c = 0; c < subjects.length; c++) {
        final g = data.gradeBySubjectId[subjects[c].id] ?? 0.0;
        _xlCell(
          sheet,
          row,
          c + 2,
          g > 0 ? g.toStringAsFixed(1) : '-',
          style: rowStyle,
        );
      }
      _xlCell(
        sheet,
        row,
        subjects.length + 2,
        data.average.toStringAsFixed(1),
        style: rowStyle,
      );
      _xlCell(sheet, row, subjects.length + 3, '${data.rank}', style: rowStyle);
    }

    final bytes = xls.encode();
    if (bytes != null) {
      downloadBytes(
        bytes,
        'notas_definitivas_${course.name}_${period.name}.xlsx',
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
}

// ─── Screen preview (Flutter widgets) ───────────────────────────────────────

class _ReportPage extends StatelessWidget {
  const _ReportPage({
    required this.course,
    required this.period,
    required this.subjects,
    required this.rows,
    required this.accentColor,
  });

  final Course course;
  final AcademicPeriod? period;
  final List<Subject> subjects;
  final List<CourseReportRow> rows;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final width = 300 + subjects.length * 60.0 + 140;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: width,
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
            _header(),
            _infoBlock(),
            const Divider(height: 1, color: Color(0xFFCBD5E1)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: _table(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
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
        children: const [
          Text(
            'COLEGIO SAN JOSÉ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'NOTAS DEFINITIVAS Y PUESTO POR CURSO',
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
          _infoItem('CURSO', course.name),
          _infoItem('PERÍODO', period?.name ?? '—'),
          _infoItem('ESTUDIANTES', '${rows.length}'),
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

  Widget _table() {
    const headerColor = Color(0xFF1E3A8A);
    const headerTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    const cellTextStyle = TextStyle(color: Color(0xFF1E293B), fontSize: 11);
    const borderColor = Color(0xFFCBD5E1);

    if (period == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Selecciona un período para ver el reporte.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: borderColor, width: 0.5),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: headerColor),
          children: [
            _cell('#', headerTextStyle, 32, center: true),
            _cell('Apellidos y Nombres del Estudiante', headerTextStyle, 230),
            ...subjects.map(
              (s) => _cell(s.code, headerTextStyle, 60, center: true),
            ),
            _cell('Promedio', headerTextStyle, 76, center: true),
            _cell('Puesto', headerTextStyle, 64, center: true),
          ],
        ),
        ...rows.asMap().entries.map((e) {
          final bg = e.key.isEven ? Colors.white : const Color(0xFFF8FAFC);
          final row = e.value;
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              _cell('${e.key + 1}', cellTextStyle, 32, bg: bg, center: true),
              _cell(row.student.fullName, cellTextStyle, 230, bg: bg),
              ...subjects.map((s) {
                final g = row.gradeBySubjectId[s.id] ?? 0.0;
                return _cell(
                  g > 0 ? g.toStringAsFixed(1) : '-',
                  TextStyle(color: performanceColor(g), fontSize: 11),
                  60,
                  bg: bg,
                  center: true,
                );
              }),
              _cell(
                row.average.toStringAsFixed(1),
                cellTextStyle.copyWith(fontWeight: FontWeight.w700),
                76,
                bg: bg,
                center: true,
              ),
              _cell(
                '${row.rank}°',
                const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                64,
                bg: bg,
                center: true,
              ),
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
}
