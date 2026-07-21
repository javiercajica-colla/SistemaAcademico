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

class GradeSheetScreen extends StatefulWidget {
  const GradeSheetScreen({super.key});

  @override
  State<GradeSheetScreen> createState() => _GradeSheetScreenState();
}

class _GradeSheetScreenState extends State<GradeSheetScreen> {
  String? _selectedCourseId;
  String? _selectedPeriodId;
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final academic = context.read<AcademicProvider>();
    _selectedPeriodId ??=
        academic.currentOpenPeriod?.id ??
        academic.activePeriods.firstOrNull?.id;
  }

  List<Course> _availableCourses(AcademicProvider academic, AuthProvider auth) {
    if (auth.currentUser?.role == UserRole.coordinator ||
        auth.currentUser?.role == UserRole.admin) {
      return academic.courses;
    }
    final teacher = academic.teacherByUserId(auth.currentUser!.id);
    if (teacher == null) return [];
    final ids = academic
        .assignmentsForTeacher(teacher.id)
        .map((a) => a.courseId)
        .toSet();
    return academic.courses.where((c) => ids.contains(c.id)).toList();
  }

  List<Subject> _subjectsForSheet(
    AcademicProvider academic,
    AuthProvider auth,
  ) {
    if (_selectedCourseId == null) return [];
    if (auth.currentUser?.role == UserRole.coordinator ||
        auth.currentUser?.role == UserRole.admin) {
      return academic.subjectsForCourse(_selectedCourseId!);
    }
    final teacher = academic.teacherByUserId(auth.currentUser!.id);
    if (teacher == null) return [];
    return academic.subjectsForCourseAndTeacher(_selectedCourseId!, teacher.id);
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    final courses = _availableCourses(academic, auth);

    if (_selectedCourseId == null && courses.isNotEmpty) {
      _selectedCourseId = courses.first.id;
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildHeader(academic, auth, courses),
            const Divider(height: 1),
            Expanded(
              child: _selectedCourseId == null || _selectedPeriodId == null
                  ? const Center(
                      child: Text('Seleccione un curso y un período.'),
                    )
                  : _buildTable(academic, auth),
            ),
          ],
        ),
        if (_exporting)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Generando archivo...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(
    AcademicProvider academic,
    AuthProvider auth,
    List<Course> courses,
  ) {
    final periods = academic.activePeriods;
    final canExport = _selectedCourseId != null && _selectedPeriodId != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: AppColors.surface,
      child: Wrap(
        spacing: 32,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Curso',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCourseId,
                    hint: const Text('Seleccionar curso'),
                    isDense: true,
                    items: courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCourseId = v),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Período',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: periods.map((p) {
                  final selected = p.id == _selectedPeriodId;
                  return ChoiceChip(
                    label: Text(p.name),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedPeriodId = p.id),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Exportar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: canExport
                        ? () => _exportPDF(academic, auth)
                        : null,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: canExport
                        ? () => _exportExcel(academic, auth)
                        : null,
                    icon: const Icon(Icons.table_chart_rounded, size: 16),
                    label: const Text('Excel'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
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

  Widget _buildTable(AcademicProvider academic, AuthProvider auth) {
    final students = academic.studentsInCourse(_selectedCourseId!);
    final subjects = _subjectsForSheet(academic, auth);

    if (students.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No hay estudiantes en este curso.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (subjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'No hay asignaturas asignadas.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend
            Row(
              children: [
                Container(width: 14, height: 14, color: Colors.red.shade100),
                const SizedBox(width: 6),
                const Text(
                  'Nota por debajo de 6.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Table
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder(
                  horizontalInside: BorderSide(color: AppColors.border),
                  verticalInside: BorderSide(color: AppColors.border),
                  top: BorderSide(color: AppColors.border),
                  bottom: BorderSide(color: AppColors.border),
                  left: BorderSide(color: AppColors.border),
                  right: BorderSide(color: AppColors.border),
                ),
                children: [
                  _buildHeaderRow(subjects),
                  ...students.asMap().entries.map(
                    (e) => _buildStudentRow(
                      e.value,
                      subjects,
                      academic,
                      e.key.isEven,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(List<Subject> subjects) {
    return TableRow(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      children: [
        _cell('Estudiante', isHeader: true, width: 220),
        ...subjects.map((s) => _cell(s.name, isHeader: true, width: 110)),
        _cell('Promedio', isHeader: true, width: 100),
      ],
    );
  }

  TableRow _buildStudentRow(
    Student student,
    List<Subject> subjects,
    AcademicProvider academic,
    bool isEven,
  ) {
    final grades = subjects
        .map(
          (s) => academic.calculateSubjectPeriodGrade(
            student.id,
            s.id,
            _selectedPeriodId!,
          ),
        )
        .toList();
    final valid = grades.where((g) => g > 0).toList();
    final avg = valid.isEmpty
        ? 0.0
        : valid.reduce((a, b) => a + b) / valid.length;

    return TableRow(
      decoration: BoxDecoration(
        color: isEven ? AppColors.background : AppColors.surface,
      ),
      children: [
        _cell(student.fullName, width: 220, align: TextAlign.left),
        ...grades.map((g) => _gradeCell(g)),
        _gradeCell(avg, isBold: true),
      ],
    );
  }

  Widget _cell(
    String text, {
    bool isHeader = false,
    double width = 110,
    TextAlign align = TextAlign.center,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _gradeCell(double grade, {bool isBold = false}) {
    final isLow = grade > 0 && grade < 6.0;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: isLow ? Colors.red.shade50 : null,
      child: Text(
        grade > 0 ? grade.toStringAsFixed(1) : '—',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: isLow ? Colors.red.shade700 : AppColors.textPrimary,
        ),
      ),
    );
  }

  // ─── PDF ──────────────────────────────────────────────────────────────────

  Future<void> _exportPDF(AcademicProvider academic, AuthProvider auth) async {
    setState(() => _exporting = true);
    try {
      final students = academic.studentsInCourse(_selectedCourseId!);
      final subjects = _subjectsForSheet(academic, auth);
      final course = academic.courseById(_selectedCourseId!)!;
      final period = academic.activePeriods.firstWhere(
        (p) => p.id == _selectedPeriodId,
      );

      final doc = pw.Document();
      final bold = pw.Font.helveticaBold();
      final regular = pw.Font.helvetica();

      const headerBg = PdfColor(0.118, 0.227, 0.541);
      const redBg = PdfColor(1.0, 0.8, 0.82);
      const redText = PdfColor(0.78, 0.16, 0.16);
      const greenBg = PdfColor(0.91, 0.98, 0.91);
      const greenText = PdfColor(0.18, 0.49, 0.2);

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) => [
            pw.Text(
              'Planilla de Notas — ${course.name} — ${period.name}',
              style: pw.TextStyle(font: bold, fontSize: 13),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Notas en rojo: por debajo de 6.0',
              style: pw.TextStyle(
                font: regular,
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FixedColumnWidth(130),
                for (int i = 1; i <= subjects.length + 1; i++)
                  i: const pw.FixedColumnWidth(56),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: headerBg),
                  children: [
                    _pdfCell(
                      'Estudiante',
                      font: bold,
                      textColor: PdfColors.white,
                    ),
                    ...subjects.map(
                      (s) => _pdfCell(
                        s.name,
                        font: bold,
                        textColor: PdfColors.white,
                      ),
                    ),
                    _pdfCell(
                      'Promedio',
                      font: bold,
                      textColor: PdfColors.white,
                    ),
                  ],
                ),
                // Data rows
                ...students.asMap().entries.map((entry) {
                  final student = entry.value;
                  final idx = entry.key;
                  final grades = subjects
                      .map(
                        (s) => academic.calculateSubjectPeriodGrade(
                          student.id,
                          s.id,
                          _selectedPeriodId!,
                        ),
                      )
                      .toList();
                  final valid = grades.where((g) => g > 0).toList();
                  final avg = valid.isEmpty
                      ? 0.0
                      : valid.reduce((a, b) => a + b) / valid.length;

                  final rowBg = idx.isEven
                      ? const PdfColor(0.97, 0.98, 0.99)
                      : PdfColors.white;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowBg),
                    children: [
                      _pdfCell(student.fullName, font: regular),
                      ...grades.map((g) {
                        final low = g > 0 && g < 6.0;
                        return _pdfCell(
                          g > 0 ? g.toStringAsFixed(1) : '—',
                          font: low ? bold : regular,
                          bgColor: low ? redBg : null,
                          textColor: low ? redText : PdfColors.black,
                          align: pw.TextAlign.center,
                        );
                      }),
                      _pdfCell(
                        avg > 0 ? avg.toStringAsFixed(1) : '—',
                        font: bold,
                        bgColor: avg > 0 && avg < 6.0 ? redBg : greenBg,
                        textColor: avg > 0 && avg < 6.0 ? redText : greenText,
                        align: pw.TextAlign.center,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'planilla_${course.name}_${period.name}.pdf',
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _pdfCell(
    String text, {
    required pw.Font font,
    PdfColor? bgColor,
    PdfColor textColor = PdfColors.black,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    pw.Widget content = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: 2,
        style: pw.TextStyle(font: font, fontSize: 8, color: textColor),
      ),
    );

    if (bgColor != null) {
      content = pw.Container(color: bgColor, child: content);
    }
    return content;
  }

  // ─── Excel ────────────────────────────────────────────────────────────────

  Future<void> _exportExcel(
    AcademicProvider academic,
    AuthProvider auth,
  ) async {
    setState(() => _exporting = true);
    try {
      final students = academic.studentsInCourse(_selectedCourseId!);
      final subjects = _subjectsForSheet(academic, auth);
      final course = academic.courseById(_selectedCourseId!)!;
      final period = academic.activePeriods.firstWhere(
        (p) => p.id == _selectedPeriodId,
      );

      final excel = Excel.createExcel();
      excel.rename('Sheet1', 'Notas');
      final sheet = excel['Notas'];

      final headerStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
        horizontalAlign: HorizontalAlign.Center,
      );

      // Header row
      _excelCell(sheet, 0, 0, 'Estudiante', style: headerStyle);
      for (int c = 0; c < subjects.length; c++) {
        _excelCell(sheet, 0, c + 1, subjects[c].name, style: headerStyle);
      }
      _excelCell(sheet, 0, subjects.length + 1, 'Promedio', style: headerStyle);

      // Column widths
      sheet.setColumnWidth(0, 28);
      for (int c = 1; c <= subjects.length + 1; c++) {
        sheet.setColumnWidth(c, 14);
      }

      // Data rows
      for (int r = 0; r < students.length; r++) {
        final student = students[r];
        _excelCell(sheet, r + 1, 0, student.fullName);

        final grades = <double>[];
        for (int c = 0; c < subjects.length; c++) {
          final g = academic.calculateSubjectPeriodGrade(
            student.id,
            subjects[c].id,
            _selectedPeriodId!,
          );
          grades.add(g);
          if (g > 0) {
            final low = g < 6.0;
            _excelCell(
              sheet,
              r + 1,
              c + 1,
              double.parse(g.toStringAsFixed(1)),
              style: low
                  ? CellStyle(
                      backgroundColorHex: ExcelColor.fromHexString('#FFCDD2'),
                      fontColorHex: ExcelColor.fromHexString('#C62828'),
                      bold: true,
                      horizontalAlign: HorizontalAlign.Center,
                    )
                  : CellStyle(horizontalAlign: HorizontalAlign.Center),
            );
          } else {
            _excelCell(sheet, r + 1, c + 1, '—');
          }
        }

        final valid = grades.where((g) => g > 0).toList();
        final avg = valid.isEmpty
            ? 0.0
            : valid.reduce((a, b) => a + b) / valid.length;
        final avgLow = avg > 0 && avg < 6.0;
        if (avg > 0) {
          _excelCell(
            sheet,
            r + 1,
            subjects.length + 1,
            double.parse(avg.toStringAsFixed(1)),
            style: CellStyle(
              backgroundColorHex: avgLow
                  ? ExcelColor.fromHexString('#FFCDD2')
                  : ExcelColor.fromHexString('#C8E6C9'),
              fontColorHex: avgLow
                  ? ExcelColor.fromHexString('#C62828')
                  : ExcelColor.fromHexString('#2E7D32'),
              bold: true,
              horizontalAlign: HorizontalAlign.Center,
            ),
          );
        }
      }

      final bytes = excel.encode();
      if (bytes != null) {
        _downloadBytes(bytes, 'planilla_${course.name}_${period.name}.xlsx');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _excelCell(
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
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    }
    if (style != null) cell.cellStyle = style;
  }

  void _downloadBytes(List<int> bytes, String filename) {
    downloadBytes(bytes, filename);
  }
}
