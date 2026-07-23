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

/// Informe consolidado de áreas por curso: una fila por estudiante, una
/// columna por área (nota + código BJ/BS/AT/SP), totales (aprobadas, no
/// aprobadas, conteo por nivel, promedio, puesto) y un cuadro de Juicios
/// Valorativos por área. Solo se genera para períodos ya cerrados. Usado
/// tanto por coordinador/admin (todos los cursos) como por el docente
/// director de curso (solo los cursos que dirige).
class CourseConsolidatedReportView extends StatefulWidget {
  final List<Course> courses;
  final Color accentColor;
  final String emptyCoursesMessage;

  const CourseConsolidatedReportView({
    super.key,
    required this.courses,
    this.accentColor = AppColors.primary,
    this.emptyCoursesMessage = 'No hay cursos disponibles.',
  });

  @override
  State<CourseConsolidatedReportView> createState() =>
      _CourseConsolidatedReportViewState();
}

class _CourseConsolidatedReportViewState
    extends State<CourseConsolidatedReportView> {
  String? _selectedCourseId;
  String? _selectedPeriodId;

  List<AcademicPeriod> _closedPeriods(AcademicProvider academic) =>
      academic.activePeriods.where((p) => !p.isOpen).toList();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final academic = context.read<AcademicProvider>();
    _selectedCourseId ??= widget.courses.firstOrNull?.id;
    _selectedPeriodId ??= _closedPeriods(academic).firstOrNull?.id;
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

    final closedPeriods = _closedPeriods(academic);
    final course = widget.courses.firstWhere(
      (c) => c.id == _selectedCourseId,
      orElse: () => widget.courses.first,
    );
    final period = _selectedPeriodId != null
        ? academic.periodById(_selectedPeriodId!)
        : null;
    final areas = academic.subjectsByArea(course.id);
    final rows = period != null
        ? academic.courseAreaConsolidatedReport(course.id, period.id)
        : <CourseAreaReportRow>[];
    final director = course.directorTeacherId != null
        ? academic.teacherById(course.directorTeacherId!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(academic, closedPeriods, course, period, areas, rows),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: _ReportPage(
                course: course,
                period: period,
                areas: areas,
                rows: rows,
                director: director,
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
    List<AcademicPeriod> closedPeriods,
    Course course,
    AcademicPeriod? period,
    Map<String, List<Subject>> areas,
    List<CourseAreaReportRow> rows,
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
              decoration: const InputDecoration(
                labelText: 'Período (cerrado)',
              ),
              items: closedPeriods
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
                : () => _exportPDF(course, period, areas, rows),
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
                : () => _exportExcel(course, period, areas, rows),
          ),
        ],
      ),
    );
  }

  // ─── Cálculos de totales/juicios compartidos entre pantalla y exportación ─

  static int _apr(CourseAreaReportRow row) => row.gradeByArea.values
      .where((g) => g > 0 && g >= GradeScale.basico)
      .length;

  static int _nApr(CourseAreaReportRow row) => row.gradeByArea.values
      .where((g) => g > 0 && g < GradeScale.basico)
      .length;

  static int _countCode(CourseAreaReportRow row, String code) =>
      row.gradeByArea.values.where((g) => performanceCode(g) == code).length;

  static Map<String, Map<String, int>> _juiciosValorativos(
    Map<String, List<Subject>> areas,
    List<CourseAreaReportRow> rows,
  ) {
    final result = <String, Map<String, int>>{};
    for (final area in areas.keys) {
      final counts = {'BJ': 0, 'BS': 0, 'AT': 0, 'SP': 0};
      for (final row in rows) {
        final code = performanceCode(row.gradeByArea[area] ?? 0.0);
        if (counts.containsKey(code)) counts[code] = counts[code]! + 1;
      }
      result[area] = counts;
    }
    return result;
  }

  static double _courseAverage(List<CourseAreaReportRow> rows) {
    final avgs = rows.map((r) => r.average).where((a) => a > 0).toList();
    return avgs.isEmpty ? 0.0 : avgs.reduce((a, b) => a + b) / avgs.length;
  }

  // ─── PDF export ────────────────────────────────────────────────────────

  Future<void> _exportPDF(
    Course course,
    AcademicPeriod period,
    Map<String, List<Subject>> areas,
    List<CourseAreaReportRow> rows,
  ) async {
    final doc = pw.Document();
    final bold = pw.Font.helveticaBold();
    final regular = pw.Font.helvetica();

    const navy = PdfColor(0.118, 0.227, 0.541);
    const altRow = PdfColor(0.973, 0.984, 1.0);
    final areaNames = areas.keys.toList();

    PdfColor pColor(double g) {
      if (g <= 0) return PdfColors.grey600;
      if (g >= GradeScale.superior) return const PdfColor(0.145, 0.388, 0.922);
      if (g >= GradeScale.alto) return const PdfColor(0.063, 0.725, 0.506);
      if (g >= GradeScale.basico) return const PdfColor(0.961, 0.620, 0.043);
      return const PdfColor(0.937, 0.267, 0.267);
    }

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
              1: const pw.FixedColumnWidth(130),
              for (int i = 0; i < areaNames.length; i++)
                i + 2: const pw.FixedColumnWidth(40),
              for (int i = 0; i < 6; i++)
                areaNames.length + 2 + i: const pw.FixedColumnWidth(28),
              areaNames.length + 8: const pw.FixedColumnWidth(34),
              areaNames.length + 9: const pw.FixedColumnWidth(28),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: navy),
                children: [
                  _pCell('#', bold, PdfColors.white, center: true),
                  _pCell('Apellidos y Nombres', bold, PdfColors.white),
                  ...areaNames.map(
                    (a) => _pCell(a, bold, PdfColors.white, center: true),
                  ),
                  _pCell('Apr', bold, PdfColors.white, center: true),
                  _pCell('NApr', bold, PdfColors.white, center: true),
                  _pCell('BJ', bold, PdfColors.white, center: true),
                  _pCell('BS', bold, PdfColors.white, center: true),
                  _pCell('AT', bold, PdfColors.white, center: true),
                  _pCell('SP', bold, PdfColors.white, center: true),
                  _pCell('Pr', bold, PdfColors.white, center: true),
                  _pCell('Pu', bold, PdfColors.white, center: true),
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
                    ...areaNames.map((a) {
                      final g = row.gradeByArea[a] ?? 0.0;
                      return _pCell(
                        g > 0
                            ? '${g.toStringAsFixed(1)} ${performanceCode(g)}'
                            : '-',
                        regular,
                        pColor(g),
                        center: true,
                      );
                    }),
                    _pCell('${_apr(row)}', regular, PdfColors.black, center: true),
                    _pCell(
                      '${_nApr(row)}',
                      regular,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell(
                      '${_countCode(row, 'BJ')}',
                      regular,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell(
                      '${_countCode(row, 'BS')}',
                      regular,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell(
                      '${_countCode(row, 'AT')}',
                      regular,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell(
                      '${_countCode(row, 'SP')}',
                      regular,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell(
                      row.average.toStringAsFixed(2),
                      bold,
                      PdfColors.black,
                      center: true,
                    ),
                    _pCell('${row.rank}', bold, navy, center: true),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'JUICIOS VALORATIVOS',
            style: pw.TextStyle(font: bold, fontSize: 9, color: navy, letterSpacing: 0.8),
          ),
          pw.SizedBox(height: 4),
          _pdfJuiciosTable(bold, regular, areaNames, _juiciosValorativos(areas, rows)),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: const PdfColor(0.941, 0.965, 1.0),
              border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'PROMEDIO DEL CURSO EN EL PERÍODO: ',
                  style: pw.TextStyle(font: bold, fontSize: 9, color: navy),
                ),
                pw.Text(
                  _courseAverage(rows).toStringAsFixed(2),
                  style: pw.TextStyle(font: bold, fontSize: 11, color: navy),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'consolidado_${course.name}_${period.name}.pdf',
    );
  }

  pw.Widget _pdfJuiciosTable(
    pw.Font bold,
    pw.Font regular,
    List<String> areaNames,
    Map<String, Map<String, int>> juicios,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FixedColumnWidth(70),
        for (int i = 0; i < areaNames.length; i++)
          i + 1: const pw.FixedColumnWidth(40),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor(0.118, 0.227, 0.541)),
          children: [
            _pCell('Nivel', bold, PdfColors.white),
            ...areaNames.map((a) => _pCell(a, bold, PdfColors.white, center: true)),
          ],
        ),
        for (final level in ['BJ', 'BS', 'AT', 'SP'])
          pw.TableRow(
            children: [
              _pCell(
                {'BJ': 'BAJO', 'BS': 'BÁSICO', 'AT': 'ALTO', 'SP': 'SUPERIOR'}[level]!,
                bold,
                PdfColors.black,
              ),
              ...areaNames.map(
                (a) => _pCell(
                  '${juicios[a]?[level] ?? 0}',
                  regular,
                  PdfColors.black,
                  center: true,
                ),
              ),
            ],
          ),
      ],
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
            style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.white, letterSpacing: 2),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'INFORME CONSOLIDADO DE ÁREAS',
            style: pw.TextStyle(font: regular, fontSize: 8, color: const PdfColor(0.749, 0.851, 1.0), letterSpacing: 1),
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

  pw.Widget _pHeaderInfo(pw.Font bold, pw.Font regular, String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: pw.TextStyle(font: bold, fontSize: 7, color: const PdfColor(0.58, 0.77, 1.0), letterSpacing: 0.5)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 9, color: PdfColors.white)),
      ],
    );
  }

  pw.Widget _pCell(String text, pw.Font font, PdfColor color, {bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: 2,
        style: pw.TextStyle(font: font, fontSize: 7, color: color),
      ),
    );
  }

  // ─── Excel export ──────────────────────────────────────────────────────

  Future<void> _exportExcel(
    Course course,
    AcademicPeriod period,
    Map<String, List<Subject>> areas,
    List<CourseAreaReportRow> rows,
  ) async {
    final xls = Excel.createExcel();
    xls.rename('Sheet1', 'Consolidado');
    final sheet = xls['Consolidado'];
    final areaNames = areas.keys.toList();

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
    _xlCell(sheet, 1, 0, 'INFORME CONSOLIDADO DE ÁREAS', style: subtitleStyle);
    _xlCell(sheet, 3, 0, 'Curso:', style: labelStyle);
    _xlCell(sheet, 3, 1, course.name, style: valueStyle);
    _xlCell(sheet, 3, 4, 'Período:', style: labelStyle);
    _xlCell(sheet, 3, 5, period.name, style: valueStyle);

    const hr = 5;
    final totalsHeaders = ['Apr', 'NApr', 'BJ', 'BS', 'AT', 'SP', 'Pr', 'Pu'];
    _xlCell(sheet, hr, 0, '#', style: headerStyle);
    _xlCell(sheet, hr, 1, 'Apellidos y Nombres del Estudiante', style: headerStyle);
    for (int c = 0; c < areaNames.length; c++) {
      _xlCell(sheet, hr, c + 2, areaNames[c], style: headerStyle);
    }
    for (int c = 0; c < totalsHeaders.length; c++) {
      _xlCell(sheet, hr, areaNames.length + 2 + c, totalsHeaders[c], style: headerStyle);
    }

    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 32);
    for (int c = 2; c < areaNames.length + 10; c++) {
      sheet.setColumnWidth(c, 12);
    }

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
      for (int c = 0; c < areaNames.length; c++) {
        final g = data.gradeByArea[areaNames[c]] ?? 0.0;
        _xlCell(
          sheet,
          row,
          c + 2,
          g > 0 ? '${g.toStringAsFixed(1)} ${performanceCode(g)}' : '-',
          style: rowStyle,
        );
      }
      final totals = [
        '${_apr(data)}',
        '${_nApr(data)}',
        '${_countCode(data, 'BJ')}',
        '${_countCode(data, 'BS')}',
        '${_countCode(data, 'AT')}',
        '${_countCode(data, 'SP')}',
        data.average.toStringAsFixed(2),
        '${data.rank}',
      ];
      for (int c = 0; c < totals.length; c++) {
        _xlCell(sheet, row, areaNames.length + 2 + c, totals[c], style: rowStyle);
      }
    }

    final juiciosRow = hr + 1 + rows.length + 2;
    _xlCell(sheet, juiciosRow, 0, 'JUICIOS VALORATIVOS', style: labelStyle);
    final juicios = _juiciosValorativos(areas, rows);
    final levels = {'BJ': 'BAJO', 'BS': 'BÁSICO', 'AT': 'ALTO', 'SP': 'SUPERIOR'};
    var lr = juiciosRow + 1;
    for (final entry in levels.entries) {
      _xlCell(sheet, lr, 0, entry.value, style: valueStyle);
      for (int c = 0; c < areaNames.length; c++) {
        _xlCell(sheet, lr, c + 2, '${juicios[areaNames[c]]?[entry.key] ?? 0}', style: labelStyle);
      }
      lr++;
    }

    _xlCell(sheet, lr + 1, 0, 'Promedio del curso en el período:', style: labelStyle);
    _xlCell(sheet, lr + 1, 1, _courseAverage(rows).toStringAsFixed(2), style: valueStyle);

    final bytes = xls.encode();
    if (bytes != null) {
      downloadBytes(bytes, 'consolidado_${course.name}_${period.name}.xlsx');
    }
  }

  void _xlCell(Sheet sheet, int row, int col, dynamic value, {CellStyle? style}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
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
    required this.areas,
    required this.rows,
    required this.director,
    required this.accentColor,
  });

  final Course course;
  final AcademicPeriod? period;
  final Map<String, List<Subject>> areas;
  final List<CourseAreaReportRow> rows;
  final Teacher? director;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final width = 300 + areas.length * 64.0 + 6 * 40.0 + 120;
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
            if (period != null && rows.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _juiciosBlock(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _courseAverageBlock(),
              ),
            ],
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
            'INFORME CONSOLIDADO DE ÁREAS',
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
          _infoItem('DIRECTOR', director?.fullName ?? '—'),
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
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );
    const cellTextStyle = TextStyle(color: Color(0xFF1E293B), fontSize: 11);
    const borderColor = Color(0xFFCBD5E1);
    final areaNames = areas.keys.toList();

    if (period == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Selecciona un período cerrado para ver el consolidado.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Este curso no tiene estudiantes.',
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
            _cell('#', headerTextStyle, 30, center: true),
            _cell('Apellidos y Nombres', headerTextStyle, 210),
            ...areaNames.map((a) => _cell(a, headerTextStyle, 64, center: true)),
            _cell('Apr', headerTextStyle, 34, center: true),
            _cell('NApr', headerTextStyle, 38, center: true),
            _cell('BJ', headerTextStyle, 30, center: true),
            _cell('BS', headerTextStyle, 30, center: true),
            _cell('AT', headerTextStyle, 30, center: true),
            _cell('SP', headerTextStyle, 30, center: true),
            _cell('Pr', headerTextStyle, 48, center: true),
            _cell('Pu', headerTextStyle, 34, center: true),
          ],
        ),
        ...rows.asMap().entries.map((e) {
          final bg = e.key.isEven ? Colors.white : const Color(0xFFF8FAFC);
          final row = e.value;
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              _cell('${e.key + 1}', cellTextStyle, 30, bg: bg, center: true),
              _cell(row.student.fullName, cellTextStyle, 210, bg: bg),
              ...areaNames.map((a) {
                final g = row.gradeByArea[a] ?? 0.0;
                return _cell(
                  g > 0 ? '${g.toStringAsFixed(1)} ${performanceCode(g)}' : '-',
                  TextStyle(color: performanceColor(g), fontSize: 10, fontWeight: FontWeight.w600),
                  64,
                  bg: bg,
                  center: true,
                );
              }),
              _cell(
                '${_CourseConsolidatedReportViewState._apr(row)}',
                cellTextStyle,
                34,
                bg: bg,
                center: true,
              ),
              _cell(
                '${_CourseConsolidatedReportViewState._nApr(row)}',
                cellTextStyle,
                38,
                bg: bg,
                center: true,
              ),
              _cell(
                '${_CourseConsolidatedReportViewState._countCode(row, 'BJ')}',
                cellTextStyle,
                30,
                bg: bg,
                center: true,
              ),
              _cell(
                '${_CourseConsolidatedReportViewState._countCode(row, 'BS')}',
                cellTextStyle,
                30,
                bg: bg,
                center: true,
              ),
              _cell(
                '${_CourseConsolidatedReportViewState._countCode(row, 'AT')}',
                cellTextStyle,
                30,
                bg: bg,
                center: true,
              ),
              _cell(
                '${_CourseConsolidatedReportViewState._countCode(row, 'SP')}',
                cellTextStyle,
                30,
                bg: bg,
                center: true,
              ),
              _cell(
                row.average.toStringAsFixed(2),
                cellTextStyle.copyWith(fontWeight: FontWeight.w700),
                48,
                bg: bg,
                center: true,
              ),
              _cell(
                '${row.rank}',
                const TextStyle(color: Color(0xFF1E3A8A), fontSize: 11, fontWeight: FontWeight.w700),
                34,
                bg: bg,
                center: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _juiciosBlock() {
    final areaNames = areas.keys.toList();
    final juicios = _CourseConsolidatedReportViewState._juiciosValorativos(areas, rows);
    const headerTextStyle = TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700);
    const cellTextStyle = TextStyle(color: Color(0xFF1E293B), fontSize: 11);
    final levels = {'BJ': 'BAJO', 'BS': 'BÁSICO', 'AT': 'ALTO', 'SP': 'SUPERIOR'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'JUICIOS VALORATIVOS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
        ),
        Table(
          border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.5),
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              children: [
                _cell('Nivel', headerTextStyle, 90),
                ...areaNames.map((a) => _cell(a, headerTextStyle, 64, center: true)),
              ],
            ),
            for (final entry in levels.entries)
              TableRow(
                children: [
                  _cell(entry.value, cellTextStyle.copyWith(fontWeight: FontWeight.w700), 90),
                  ...areaNames.map(
                    (a) => _cell('${juicios[a]?[entry.key] ?? 0}', cellTextStyle, 64, center: true),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _courseAverageBlock() {
    final avg = _CourseConsolidatedReportViewState._courseAverage(rows);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Text(
            'PROMEDIO DEL CURSO EN EL PERÍODO',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
          ),
          const Spacer(),
          Text(
            avg > 0 ? avg.toStringAsFixed(2) : '—',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A)),
          ),
        ],
      ),
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
      height: 28,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        text,
        style: style,
        textAlign: center ? TextAlign.center : TextAlign.left,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
