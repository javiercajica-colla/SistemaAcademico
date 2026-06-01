import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class StudentGradesScreen extends StatefulWidget {
  const StudentGradesScreen({super.key});

  @override
  State<StudentGradesScreen> createState() => _StudentGradesScreenState();
}

class _StudentGradesScreenState extends State<StudentGradesScreen> {
  String _selectedPeriod = 'ap1';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final student = academic.studentByUserId(auth.currentUser!.id);
    if (student == null) return const Center(child: Text('Perfil no encontrado'));

    final subjects = academic.subjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Mis Calificaciones', subtitle: 'Consulta tus notas por asignatura y período'),
          const SizedBox(height: 20),
          _buildPeriodSelector(academic),
          const SizedBox(height: 20),
          _buildOverallSummary(student.id, academic),
          const SizedBox(height: 16),
          ...subjects.map((s) => _buildSubjectCard(student.id, s.id, s.name, academic)),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(AcademicProvider academic) {
    return Row(
      children: academic.activePeriods.map((p) {
        final isSelected = p.id == _selectedPeriod;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(p.name),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedPeriod = p.id),
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOverallSummary(String studentId, AcademicProvider academic) {
    final avg = academic.calculateOverallAverage(studentId, _selectedPeriod);
    final color = avg >= 4.0 ? AppColors.secondary : avg >= 3.0 ? AppColors.warning : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Promedio del período', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(avg > 0 ? avg.toStringAsFixed(2) : 'Sin calificaciones', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
            child: Text(
              avg >= 4.6 ? 'Superior' : avg >= 4.0 ? 'Alto' : avg >= 3.0 ? 'Básico' : 'Bajo',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(String studentId, String subjectId, String subjectName, AcademicProvider academic) {
    final standards = academic.standardsForSubject(subjectId);
    final gradesList = academic.gradesForStudentSubjectPeriod(studentId, subjectId, _selectedPeriod);
    final avg = academic.calculateSubjectPeriodGrade(studentId, subjectId, _selectedPeriod);
    final config = academic.evalConfigFor(subjectId, _selectedPeriod);
    final sw = config?.standardsWeight ?? 70;
    final fw = config?.finalExamWeight ?? 30;

    if (gradesList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 8),
          title: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.student.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.book_rounded, color: AppColors.student, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
              avg > 0 ? GradeChip(grade: avg) : const Text('Sin nota', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    children: [
                      _weightBadge('Estándares', sw),
                      const SizedBox(width: 8),
                      _weightBadge('Evaluación Final', fw),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...standards.map((std) {
                    try {
                      final g = gradesList.firstWhere((gr) => gr.standardId == std.id);
                      return _gradeRow(std.name, g.value, '${std.weight.toStringAsFixed(0)}%');
                    } catch (_) {
                      return _gradeRow(std.name, null, '${std.weight.toStringAsFixed(0)}%');
                    }
                  }),
                  const Divider(),
                  Builder(builder: (_) {
                    try {
                      final fg = gradesList.firstWhere((g) => g.standardId == null);
                      return _gradeRow('Evaluación Final', fg.value, '${fw.toStringAsFixed(0)}%');
                    } catch (_) {
                      return _gradeRow('Evaluación Final', null, '${fw.toStringAsFixed(0)}%');
                    }
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeRow(String label, double? value, String weight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(weight, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          value != null ? GradeChip(grade: value, compact: true) : const Text('—', style: TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _weightBadge(String label, double weight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
      child: Text('$label: ${weight.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
    );
  }
}
