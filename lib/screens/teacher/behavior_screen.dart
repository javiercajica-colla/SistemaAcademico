import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/unsaved_changes_provider.dart';
import '../../widgets/unsaved_changes_guard.dart';

const _kPerformanceLevels = ['Bajo', 'Básico', 'Alto', 'Superior'];

/// Registro de comportamiento por período, exclusivo del docente director
/// de curso (mismo alcance que DefinitiveReportScreen: solo ve los cursos
/// donde figura como Course.directorTeacherId).
class BehaviorScreen extends StatelessWidget {
  const BehaviorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);

    if (teacher == null) {
      return const Center(child: Text('No se encontró el perfil de docente.'));
    }

    final directedCourses = academic.courses
        .where((c) => c.directorTeacherId == teacher.id)
        .toList();

    if (directedCourses.isEmpty) {
      return const Center(
        child: Text(
          'No eres director de ningún curso. El registro de comportamiento '
          'solo está disponible para el director de curso.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return _BehaviorCourseView(courses: directedCourses, teacher: teacher);
  }
}

class _BehaviorCourseView extends StatefulWidget {
  const _BehaviorCourseView({required this.courses, required this.teacher});

  final List<Course> courses;
  final Teacher teacher;

  @override
  State<_BehaviorCourseView> createState() => _BehaviorCourseViewState();
}

class _BehaviorCourseViewState extends State<_BehaviorCourseView> {
  String? _selectedCourseId;
  String? _selectedPeriodId;
  // studentId -> función de guardado de esa fila, mientras tenga cambios
  // sin guardar. Cada _StudentBehaviorRow reporta aquí su propio _save al
  // volverse "sucia", y null al guardarse — así el diálogo de "cambios sin
  // guardar" del sidebar puede guardar todas las filas pendientes de una vez.
  final Map<String, VoidCallback> _dirtySaves = {};
  UnsavedChangesProvider? _unsavedChanges;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final academic = context.read<AcademicProvider>();
    _selectedCourseId ??= widget.courses.firstOrNull?.id;
    _selectedPeriodId ??=
        academic.currentOpenPeriod?.id ??
        academic.activePeriods.firstOrNull?.id;
    _unsavedChanges = context.read<UnsavedChangesProvider>();
  }

  @override
  void dispose() {
    _unsavedChanges?.markClean();
    super.dispose();
  }

  void _handleRowDirty(String studentId, VoidCallback? saveFn) {
    final wasEmpty = _dirtySaves.isEmpty;
    if (saveFn != null) {
      _dirtySaves[studentId] = saveFn;
    } else {
      _dirtySaves.remove(studentId);
    }
    final isEmptyNow = _dirtySaves.isEmpty;
    if (wasEmpty && !isEmptyNow) {
      _unsavedChanges?.markDirty(
        message:
            'Tienes observaciones de comportamiento sin guardar. '
            '¿Deseas guardarlas antes de salir?',
        onSave: _saveAllDirty,
        onDiscard: () {},
      );
    } else if (!wasEmpty && isEmptyNow) {
      _unsavedChanges?.markClean();
    }
  }

  void _saveAllDirty() {
    for (final save in _dirtySaves.values.toList()) {
      save();
    }
    _dirtySaves.clear();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final course = widget.courses.firstWhere(
      (c) => c.id == _selectedCourseId,
      orElse: () => widget.courses.first,
    );
    final students = academic.studentsInCourse(course.id)
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCourseId,
                  decoration: const InputDecoration(labelText: 'Curso'),
                  items: widget.courses
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => guardNavigation(
                    context,
                    () => setState(() => _selectedCourseId = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedPeriodId,
                  decoration: const InputDecoration(labelText: 'Período'),
                  items: academic.activePeriods
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => guardNavigation(
                    context,
                    () => setState(() => _selectedPeriodId = v),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _selectedPeriodId == null
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: students.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StudentBehaviorRow(
                      key: ValueKey('${students[i].id}_$_selectedPeriodId'),
                      student: students[i],
                      periodId: _selectedPeriodId!,
                      teacher: widget.teacher,
                      onDirtyChanged: (saveFn) =>
                          _handleRowDirty(students[i].id, saveFn),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _StudentBehaviorRow extends StatefulWidget {
  const _StudentBehaviorRow({
    super.key,
    required this.student,
    required this.periodId,
    required this.teacher,
    required this.onDirtyChanged,
  });

  final Student student;
  final String periodId;
  final Teacher teacher;
  // Reporta hacia la pantalla padre: la función de guardado de esta fila
  // mientras tenga cambios sin guardar, o null cuando vuelve a estar
  // limpia (recién guardada o recién cargada).
  final void Function(VoidCallback? saveFn) onDirtyChanged;

  @override
  State<_StudentBehaviorRow> createState() => _StudentBehaviorRowState();
}

class _StudentBehaviorRowState extends State<_StudentBehaviorRow> {
  late final TextEditingController _controller;
  String? _level;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final existing = context.read<AcademicProvider>().behaviorFor(
      widget.student.id,
      widget.periodId,
    );
    _controller = TextEditingController(text: existing?.description ?? '');
    _level = existing?.performanceLevel;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_dirty) return;
    setState(() => _dirty = true);
    widget.onDirtyChanged(_save);
  }

  void _save() {
    final academic = context.read<AcademicProvider>();
    final existing = academic.behaviorFor(widget.student.id, widget.periodId);
    academic.saveBehaviorAssessment(
      BehaviorAssessment(
        id: existing?.id ?? const Uuid().v4(),
        studentId: widget.student.id,
        periodId: widget.periodId,
        teacherId: widget.teacher.id,
        performanceLevel: _level ?? 'Básico',
        description: _controller.text.trim(),
        registeredAt: DateTime.now(),
      ),
    );
    if (mounted) setState(() => _dirty = false);
    widget.onDirtyChanged(null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comportamiento guardado — ${widget.student.fullName}'),
          backgroundColor: AppColors.teacher,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                widget.student.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Desempeño'),
              items: _kPerformanceLevels
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) {
                setState(() => _level = v);
                _markDirty();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _controller,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observación de comportamiento',
              ),
              onChanged: (_) => _markDirty(),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: FilledButton.icon(
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.teacher),
              onPressed: (_dirty && _level != null) ? _save : null,
            ),
          ),
        ],
      ),
    );
  }
}
