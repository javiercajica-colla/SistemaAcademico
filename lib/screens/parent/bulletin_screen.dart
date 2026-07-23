import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/grade_scale.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../shared/student_bulletin_dialog.dart';

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
                    performanceColor(avg),
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
          final perf = performanceLabel(g);
          final col = performanceColor(g);
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
    StudentBulletinDialog.show(
      context,
      student: student,
      course: course,
      period: period,
    );
  }
}
