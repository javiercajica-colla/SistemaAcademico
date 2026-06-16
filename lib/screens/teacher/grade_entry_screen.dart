import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  String? _selectedCourse;
  String? _selectedSubject;
  String? _selectedPeriod;
  final Map<String, Map<String, TextEditingController>> _controllers = {};

  @override
  void dispose() {
    for (final m in _controllers.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  TextEditingController _getController(String studentId, String key) {
    _controllers[studentId] ??= {};
    _controllers[studentId]![key] ??= TextEditingController();
    return _controllers[studentId]![key]!;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);

    if (teacher == null) {
      return const Center(child: Text('Perfil no encontrado'));
    }

    final myAssignments = academic.assignmentsForTeacher(teacher.id);
    final myCourseIds = myAssignments.map((a) => a.courseId).toSet();
    final myCourses = academic.courses
        .where((c) => myCourseIds.contains(c.id))
        .toList();

    List<String> availableSubjectIds = [];
    if (_selectedCourse != null) {
      availableSubjectIds = myAssignments
          .where((a) => a.courseId == _selectedCourse)
          .map((a) => a.subjectId)
          .toList();
    }

    final students = _selectedCourse != null
        ? academic.studentsInCourse(_selectedCourse!)
        : <Student>[];
    final standards = _selectedSubject != null
        ? academic.standardsForSubject(_selectedSubject!)
        : <Standard>[];
    final evalConfig = (_selectedSubject != null && _selectedPeriod != null)
        ? academic.evalConfigFor(_selectedSubject!, _selectedPeriod!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Registro de Calificaciones',
            subtitle: 'Ingresa las notas por estándar evaluativo',
          ),
          const SizedBox(height: 20),
          _buildFilters(myCourses, academic, availableSubjectIds),
          const SizedBox(height: 20),
          if (_selectedCourse != null &&
              _selectedSubject != null &&
              _selectedPeriod != null)
            _buildGradeTable(context, students, standards, evalConfig, academic)
          else
            _buildSelectPrompt(),
        ],
      ),
    );
  }

  Widget _buildFilters(
    List myCourses,
    AcademicProvider academic,
    List<String> subjectIds,
  ) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCourse,
            decoration: const InputDecoration(labelText: 'Curso'),
            items: myCourses
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _selectedCourse = v;
              _selectedSubject = null;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(labelText: 'Asignatura'),
            items: subjectIds.map((sid) {
              final sub = academic.subjectById(sid);
              return DropdownMenuItem(
                value: sid,
                child: Text(sub?.name ?? sid),
              );
            }).toList(),
            onChanged: _selectedCourse == null
                ? null
                : (v) => setState(() => _selectedSubject = v),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _selectedPeriod,
            decoration: const InputDecoration(labelText: 'Período'),
            items: academic.activePeriods
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPeriod = v),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectPrompt() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grade_outlined, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text(
              'Selecciona curso, asignatura y período',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
            SizedBox(height: 4),
            Text(
              'para registrar calificaciones',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeTable(
    BuildContext context,
    List<Student> students,
    List<Standard> standards,
    EvaluationConfig? evalConfig,
    AcademicProvider academic,
  ) {
    final sw = evalConfig?.standardsWeight ?? 70;
    final fw = evalConfig?.finalExamWeight ?? 30;

    return AppCard(
      title:
          'Calificaciones — ${academic.subjectById(_selectedSubject!)?.name ?? ''} • ${academic.periodById(_selectedPeriod!)?.name ?? ''}',
      titleAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Estándares ${sw.toStringAsFixed(0)}% | Final ${fw.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.save_rounded, size: 16),
            label: const Text('Guardar'),
            onPressed: () => _saveGrades(context, academic),
          ),
        ],
      ),
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
          border: TableBorder(
            horizontalInside: const BorderSide(color: AppColors.border),
          ),
          columns: [
            const DataColumn(
              label: Text(
                'Estudiante',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            ...standards.map(
              (std) => DataColumn(
                label: Tooltip(
                  message: std.description,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        std.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${std.weight.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const DataColumn(
              label: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eval. Final',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                  Text(
                    '30%',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const DataColumn(
              label: Text(
                'Promedio',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
              ),
            ),
          ],
          rows: students.map((student) {
            final existingGrades = academic.gradesForStudentSubjectPeriod(
              student.id,
              _selectedSubject!,
              _selectedPeriod!,
            );
            double total = 0;
            int cnt = 0;
            for (final std in standards) {
              final ctrl = _getController(student.id, std.id);
              if (ctrl.text.isEmpty) {
                try {
                  final g = existingGrades.firstWhere(
                    (g) => g.standardId == std.id,
                  );
                  ctrl.text = g.value.toString();
                } catch (_) {}
              }
            }
            final finalCtrl = _getController(student.id, 'final');
            if (finalCtrl.text.isEmpty) {
              try {
                final g = existingGrades.firstWhere(
                  (g) => g.standardId == null,
                );
                finalCtrl.text = g.value.toString();
              } catch (_) {}
            }

            for (final std in standards) {
              final v = double.tryParse(
                _getController(student.id, std.id).text,
              );
              if (v != null) {
                total += v * std.weight / 100;
                cnt++;
              }
            }
            final fv = double.tryParse(finalCtrl.text);
            final avg = cnt > 0
                ? (total * sw / 100) + ((fv ?? 0) * fw / 100)
                : 0.0;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.teacher.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          student.firstName.substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.teacher,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ...standards.map(
                  (std) => DataCell(
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: _getController(student.id, std.id),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        style: const TextStyle(fontSize: 13),
                        decoration: _gradeDecoration(_getController(student.id, std.id).text),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: finalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      style: const TextStyle(fontSize: 13),
                      decoration: _gradeDecoration(finalCtrl.text),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                DataCell(
                  avg > 0
                      ? GradeChip(grade: avg, compact: true)
                      : const Text(
                          '-',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  InputDecoration _gradeDecoration(String text) {
    final v = double.tryParse(text);
    final isInvalid = text.isNotEmpty && (v == null || v < 0 || v > 5);
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      hintText: '0.0',
      hintStyle: const TextStyle(color: AppColors.textTertiary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: isInvalid ? AppColors.error : AppColors.border,
          width: isInvalid ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(
          color: isInvalid ? AppColors.error : AppColors.primary,
          width: 1.5,
        ),
      ),
      errorText: isInvalid ? '0–5' : null,
      errorStyle: const TextStyle(fontSize: 9, height: 0.8),
    );
  }

  void _saveGrades(BuildContext context, AcademicProvider academic) {
    const uuid = Uuid();
    int saved = 0;
    for (final entry in _controllers.entries) {
      final studentId = entry.key;
      final standards = academic.standardsForSubject(_selectedSubject!);
      for (final std in standards) {
        final v = double.tryParse(entry.value[std.id]?.text ?? '');
        if (v != null && v >= 0 && v <= 5) {
          academic.addGrade(
            Grade(
              id: uuid.v4(),
              studentId: studentId,
              subjectId: _selectedSubject!,
              periodId: _selectedPeriod!,
              standardId: std.id,
              value: v,
              registeredAt: DateTime.now(),
            ),
          );
          saved++;
        }
      }
      final fv = double.tryParse(entry.value['final']?.text ?? '');
      if (fv != null && fv >= 0 && fv <= 5) {
        academic.addGrade(
          Grade(
            id: uuid.v4(),
            studentId: studentId,
            subjectId: _selectedSubject!,
            periodId: _selectedPeriod!,
            value: fv,
            registeredAt: DateTime.now(),
          ),
        );
        saved++;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$saved calificaciones guardadas exitosamente'),
        backgroundColor: AppColors.secondary,
      ),
    );
    setState(() {});
  }
}
