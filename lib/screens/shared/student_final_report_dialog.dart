import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_scale.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';

/// Resumen anual de UN estudiante: nota promedio de cada asignatura (los 4
/// períodos del año), promedio general, puesto en el curso y qué
/// asignaturas quedaron reprobadas. Se calcula para todo el curso a la vez
/// (`computeFinalReportForCourse`) porque el puesto depende de comparar a
/// todos los estudiantes entre sí, igual que en el informe por período.
class StudentFinalSummary {
  final Map<String, double> subjectYearGrades;
  final double overallAvg;
  final int rank;
  final List<Subject> failedSubjects;

  const StudentFinalSummary({
    required this.subjectYearGrades,
    required this.overallAvg,
    required this.rank,
    required this.failedSubjects,
  });
}

/// Promedia las notas de los períodos del año activo por asignatura
/// (ignorando períodos sin nota, igual que el resto de promedios de la
/// app), y con eso arma puesto y asignaturas reprobadas para cada
/// estudiante del curso.
Map<String, StudentFinalSummary> computeFinalReportForCourse(
  AcademicProvider academic,
  Course course,
) {
  final subjects = academic.subjectsForCourse(course.id);
  final periods = academic.activePeriods;
  final students = academic.studentsInCourse(course.id);

  double subjectYearAvg(String studentId, String subjectId) {
    final grades = periods
        .map(
          (p) => academic.calculateSubjectPeriodGrade(studentId, subjectId, p.id),
        )
        .where((g) => g > 0)
        .toList();
    if (grades.isEmpty) return 0.0;
    return grades.reduce((a, b) => a + b) / grades.length;
  }

  final gradesByStudent = <String, Map<String, double>>{};
  final overallByStudent = <String, double>{};
  for (final s in students) {
    final grades = {
      for (final subj in subjects) subj.id: subjectYearAvg(s.id, subj.id),
    };
    gradesByStudent[s.id] = grades;
    final vals = grades.values.where((g) => g > 0).toList();
    overallByStudent[s.id] = vals.isEmpty
        ? 0.0
        : vals.reduce((a, b) => a + b) / vals.length;
  }

  final sortedDesc = overallByStudent.values.where((v) => v > 0).toList()
    ..sort((a, b) => b.compareTo(a));

  return {
    for (final s in students)
      s.id: StudentFinalSummary(
        subjectYearGrades: gradesByStudent[s.id]!,
        overallAvg: overallByStudent[s.id]!,
        rank: overallByStudent[s.id]! > 0
            ? sortedDesc.indexOf(overallByStudent[s.id]!) + 1
            : 0,
        failedSubjects: subjects
            .where(
              (subj) =>
                  (gradesByStudent[s.id]![subj.id] ?? 0.0) < GradeScale.basico,
            )
            .toList(),
      ),
  };
}

enum _PromotionResult { promoted, recovery, repeats }

class StudentFinalReportDialog extends StatelessWidget {
  const StudentFinalReportDialog({
    super.key,
    required this.student,
    required this.course,
    required this.year,
    required this.areas,
    required this.subjectEstandares,
    required this.summary,
  });

  final Student student;
  final Course course;
  final int year;
  final Map<String, List<Subject>> areas;
  final Map<String, List<Estandar>> subjectEstandares;
  final StudentFinalSummary summary;

  static void show(
    BuildContext context, {
    required Student student,
    required Course course,
  }) {
    final academic = context.read<AcademicProvider>();
    final subjects = academic.subjectsForCourse(course.id);
    final yearEntry = academic.years.where((y) => y.id == course.academicYearId);
    final year = yearEntry.isEmpty ? DateTime.now().year : yearEntry.first.year;
    final summaries = computeFinalReportForCourse(academic, course);
    final summary =
        summaries[student.id] ??
        const StudentFinalSummary(
          subjectYearGrades: {},
          overallAvg: 0,
          rank: 0,
          failedSubjects: [],
        );

    showDialog(
      context: context,
      builder: (_) => StudentFinalReportDialog(
        student: student,
        course: course,
        year: year,
        areas: academic.subjectsByArea(course.id),
        subjectEstandares: {
          for (final s in subjects) s.id: academic.estandaresForSubject(s.id),
        },
        summary: summary,
      ),
    );
  }

  int _areaHours(List<Subject> subjects) =>
      subjects.fold(0, (a, s) => a + s.hoursPerWeek);

  double _areaAverage(List<Subject> subjects) {
    final vals = subjects
        .map((s) => summary.subjectYearGrades[s.id] ?? 0.0)
        .where((g) => g > 0)
        .toList();
    return vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
  }

  _PromotionResult get _promotion {
    final failed = summary.failedSubjects.length;
    if (failed == 0) return _PromotionResult.promoted;
    if (failed <= 2) return _PromotionResult.recovery;
    return _PromotionResult.repeats;
  }

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
          const Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.parent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informe Final — ${student.fullName}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${course.name} · Año $year',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildPage() {
    return Container(
      // +48 = padding horizontal de _gradesSection (24 c/lado); +16 =
      // padding horizontal de las filas de la tabla (8px c/lado) — sin ese
      // margen el Row de columnas de ancho fijo desborda por 16px (ver
      // mismo ajuste en student_bulletin_dialog.dart).
      width: _colName + _colIH + _colGrade + _colPerf + 48 + 16,
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
          _gradesSection(),
          _promotionBlock(),
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
                    'INFORME FINAL — AÑO LECTIVO $year',
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
          _infoItem('AÑO LECTIVO', '$year'),
          _infoItem(
            'PROMEDIO ANUAL',
            summary.overallAvg > 0 ? summary.overallAvg.toStringAsFixed(2) : '—',
          ),
          _infoItem(
            'PUESTO EN EL CURSO',
            summary.overallAvg > 0 ? '${summary.rank}°' : '—',
          ),
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

  Widget _gradesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tableHeaderRow(),
          const Divider(height: 1, color: Color(0xFFCBD5E1)),
          for (final entry in areas.entries) _areaBlock(entry),
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
              'Nota Final',
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

  Widget _areaBlock(MapEntry<String, List<Subject>> e) {
    final areaAvg = _areaAverage(e.value);
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
        for (final s in e.value) _subjectBlock(s),
      ],
    );
  }

  Widget _subjectBlock(Subject s) {
    final g = summary.subjectYearGrades[s.id] ?? 0.0;
    final color = performanceColor(g);
    final estandares = subjectEstandares[s.id] ?? const [];
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
          if (estandares.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: estandares
                    .map(
                      (est) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '•  ${est.name}',
                          style: const TextStyle(
                            fontSize: 11,
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

  Widget _promotionBlock() {
    final isGraduating = course.grade == '11';
    final nextGrade = (int.tryParse(course.grade) ?? 0) + 1;

    late final String title;
    late final String? subtitle;
    late final Color color;
    late final IconData icon;

    switch (_promotion) {
      case _PromotionResult.promoted:
        title = isGraduating
            ? 'Culminó la Educación Media'
            : 'Promovido a Grado $nextGrade°';
        subtitle = null;
        color = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
      case _PromotionResult.recovery:
        title = 'Pendiente — Debe presentar Pruebas de Recuperación';
        subtitle =
            'Asignaturas: '
            '${summary.failedSubjects.map((s) => s.name).join(', ')}. '
            '${isGraduating ? 'Si las aprueba, culmina la Educación Media.' : 'Si las aprueba, será promovido a Grado $nextGrade°.'}';
        color = const Color(0xFFF59E0B);
        icon = Icons.warning_rounded;
      case _PromotionResult.repeats:
        title = 'No Promovido — Repite Grado ${course.grade}°';
        subtitle =
            'Asignaturas reprobadas: '
            '${summary.failedSubjects.map((s) => s.name).join(', ')}.';
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                  ),
                ],
              ],
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
        children: [
          Expanded(child: _sigLine('Firma Director(a) de Grupo')),
          const SizedBox(width: 12),
          Expanded(child: _sigLine('Firma Coordinador(a)')),
          const SizedBox(width: 12),
          Expanded(child: _sigLine('Firma Padre/Madre/Acudiente')),
        ],
      ),
    );
  }

  Widget _sigLine(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
