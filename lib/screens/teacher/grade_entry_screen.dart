import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  bool _started = false;
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Map<String, Map<String, FocusNode>> _focusNodes = {};
  final ScrollController _hScrollController = ScrollController();

  @override
  void dispose() {
    for (final m in _controllers.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    for (final m in _focusNodes.values) {
      for (final n in m.values) {
        n.dispose();
      }
    }
    _hScrollController.dispose();
    super.dispose();
  }

  TextEditingController _getController(String studentId, String key) {
    _controllers[studentId] ??= {};
    _controllers[studentId]![key] ??= TextEditingController();
    return _controllers[studentId]![key]!;
  }

  FocusNode _getFocusNode(String studentId, String key) {
    _focusNodes[studentId] ??= {};
    _focusNodes[studentId]![key] ??= FocusNode();
    return _focusNodes[studentId]![key]!;
  }

  // Permite moverse a la misma columna del estudiante siguiente/anterior
  // con las flechas arriba/abajo, sin interferir con el cursor de texto.
  KeyEventResult _handleVerticalNav(
    KeyEvent event,
    List<Student> students,
    int rowIndex,
    String colKey,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    int targetIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      targetIndex = rowIndex + 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      targetIndex = rowIndex - 1;
    } else {
      return KeyEventResult.ignored;
    }
    if (targetIndex < 0 || targetIndex >= students.length) {
      return KeyEventResult.ignored;
    }
    _getFocusNode(students[targetIndex].id, colKey).requestFocus();
    return KeyEventResult.handled;
  }

  String _slotKey(String indicatorId, int slot) => '${indicatorId}_$slot';

  double? _indicatorPreview(String studentId, Indicator ind) {
    final vals = <double>[];
    for (var slot = 1; slot <= 3; slot++) {
      final v = double.tryParse(
        _getController(studentId, _slotKey(ind.id, slot)).text,
      );
      if (v != null) vals.add(v);
    }
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? _standardPreview(String studentId, List<Indicator> indicators) {
    final vals = indicators
        .map((i) => _indicatorPreview(studentId, i))
        .whereType<double>()
        .toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_started) ...[
            const SectionHeader(
              title: 'Gestionar Calificaciones',
              subtitle:
                  'Seleccione el curso, la asignatura y el periodo en el que va a registrar calificaciones',
            ),
            const SizedBox(height: 24),
            _buildSelector(myCourses, academic, availableSubjectIds),
          ] else
            _buildEntryStep(context, academic),
        ],
      ),
    );
  }

  Widget _buildSelector(
    List myCourses,
    AcademicProvider academic,
    List<String> subjectIds,
  ) {
    final canContinue =
        _selectedCourse != null &&
        _selectedSubject != null &&
        _selectedPeriod != null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourse,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Curso *'),
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
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSubject,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Asignatura *',
                        ),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedPeriod,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Periodo Académico *',
                        ),
                        items: academic.activePeriods
                            .map(
                              (p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedPeriod = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: canContinue
                        ? () => setState(() => _started = true)
                        : null,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEntryStep(BuildContext context, AcademicProvider academic) {
    final students = academic.studentsInCourse(_selectedCourse!);
    final standards = academic.standardsForSubjectAndPeriod(
      _selectedSubject!,
      _selectedPeriod!,
    );
    final evalConfig = academic.evalConfigFor(
      _selectedSubject!,
      _selectedPeriod!,
    );
    final course = academic.courses.firstWhere((c) => c.id == _selectedCourse);
    final subject = academic.subjectById(_selectedSubject!);
    final period = academic.periodById(_selectedPeriod!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Cambiar curso, asignatura o periodo',
              onPressed: () => setState(() => _started = false),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestionar Calificaciones',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${course.name} • ${subject?.name ?? ''} • ${period?.name ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGradeTable(context, students, standards, evalConfig, academic),
      ],
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

    final indicatorsByStandard = {
      for (final std in standards)
        std.id: academic.indicatorsForStandard(std.id),
    };

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
      child: Scrollbar(
        controller: _hScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _hScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 12),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
            headingRowHeight: 56,
            border: TableBorder(
              horizontalInside: const BorderSide(color: AppColors.border),
              verticalInside: const BorderSide(
                color: AppColors.border,
                width: 0.5,
              ),
            ),
            columns: [
              const DataColumn(
                label: Text(
                  'Estudiante',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
              for (var si = 0; si < standards.length; si++) ...[
                if ((indicatorsByStandard[standards[si].id] ??
                        const <Indicator>[])
                    .isEmpty)
                  DataColumn(
                    label: _groupHeader(
                      'EST${si + 1}',
                      '${standards[si].weight.toStringAsFixed(0)}%',
                      'Sin competencias',
                      tooltip: standards[si].name,
                    ),
                  )
                else ...[
                  for (final ind
                      in indicatorsByStandard[standards[si].id]!) ...[
                    for (var slot = 1; slot <= 3; slot++)
                      DataColumn(
                        label: _slotHeader(
                          context,
                          academic,
                          standards[si],
                          si + 1,
                          ind,
                          slot,
                        ),
                      ),
                    DataColumn(
                      label: _groupHeader(
                        'EST${si + 1}',
                        'I${ind.order}',
                        'Prom.',
                        italic: true,
                        tooltip: '${standards[si].name} — ${ind.name}',
                      ),
                    ),
                  ],
                  DataColumn(
                    label: _groupHeader(
                      'EST${si + 1}',
                      'Prom. Estándar',
                      '${standards[si].weight.toStringAsFixed(0)}%',
                      bold: true,
                      tooltip: standards[si].name,
                    ),
                  ),
                ],
              ],
              const DataColumn(
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eval. Final',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
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
              const DataColumn(
                label: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nota Final',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '(sin Ev. Final)',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            rows: List.generate(students.length, (rowIndex) {
              final student = students[rowIndex];
              final existingGrades = academic.gradesForStudentSubjectPeriod(
                student.id,
                _selectedSubject!,
                _selectedPeriod!,
              );
              for (final std in standards) {
                for (final ind
                    in indicatorsByStandard[std.id] ?? const <Indicator>[]) {
                  for (var slot = 1; slot <= 3; slot++) {
                    final ctrl = _getController(
                      student.id,
                      _slotKey(ind.id, slot),
                    );
                    if (ctrl.text.isEmpty) {
                      try {
                        final g = existingGrades.firstWhere(
                          (g) => g.indicatorId == ind.id && g.slot == slot,
                        );
                        ctrl.text = g.value.toString();
                      } catch (_) {}
                    }
                  }
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

              double weightedSum = 0;
              double totalWeight = 0;
              for (final std in standards) {
                final inds =
                    indicatorsByStandard[std.id] ?? const <Indicator>[];
                final score = _standardPreview(student.id, inds);
                if (score != null) {
                  weightedSum += score * std.weight;
                  totalWeight += std.weight;
                }
              }
              // Si falta alguna nota (estándar o evaluación final), esa parte
              // simplemente no se tiene en cuenta, en vez de contarse como 0.
              final standardsAvg = totalWeight > 0
                  ? weightedSum / totalWeight
                  : null;
              final fv = double.tryParse(finalCtrl.text);
              final double avg;
              if (standardsAvg != null && fv != null) {
                avg = (standardsAvg * sw / 100) + (fv * fw / 100);
              } else if (standardsAvg != null) {
                avg = standardsAvg;
              } else if (fv != null) {
                avg = fv;
              } else {
                avg = 0.0;
              }

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
                  for (final std in standards) ...[
                    if ((indicatorsByStandard[std.id] ?? const <Indicator>[])
                        .isEmpty)
                      const DataCell(
                        Text(
                          '-',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      )
                    else ...[
                      for (final ind in indicatorsByStandard[std.id]!) ...[
                        for (var slot = 1; slot <= 3; slot++)
                          DataCell(
                            _buildSlotCell(
                              context,
                              academic,
                              students,
                              rowIndex,
                              ind,
                              slot,
                            ),
                          ),
                        DataCell(
                          _previewChip(_indicatorPreview(student.id, ind)),
                        ),
                      ],
                      DataCell(
                        _previewChip(
                          _standardPreview(
                            student.id,
                            indicatorsByStandard[std.id]!,
                          ),
                          bold: true,
                        ),
                      ),
                    ],
                  ],
                  DataCell(
                    SizedBox(
                      width: 70,
                      child: Focus(
                        onKeyEvent: (node, event) => _handleVerticalNav(
                          event,
                          students,
                          rowIndex,
                          'final',
                        ),
                        child: TextField(
                          controller: finalCtrl,
                          focusNode: _getFocusNode(student.id, 'final'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'),
                            ),
                          ],
                          style: const TextStyle(fontSize: 13),
                          decoration: _gradeDecoration(finalCtrl.text),
                          onChanged: (_) => setState(() {}),
                        ),
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
                  DataCell(
                    standardsAvg != null && standardsAvg > 0
                        ? GradeChip(grade: standardsAvg, compact: true)
                        : const Text(
                            '-',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _groupHeader(
    String line1,
    String line2,
    String line3, {
    bool bold = false,
    bool italic = false,
    String? tooltip,
  }) {
    final column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line1,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          line2,
          style: TextStyle(
            fontSize: 10,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: bold ? AppColors.secondary : AppColors.textPrimary,
          ),
        ),
        Text(
          line3,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textSecondary,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
    if (tooltip == null) return column;
    return Tooltip(message: tooltip, child: column);
  }

  Widget _slotHeader(
    BuildContext context,
    AcademicProvider academic,
    Standard std,
    int stdNum,
    Indicator ind,
    int slot,
  ) {
    final activities = academic.activitiesForIndicator(ind.id);
    final existing = activities.length >= slot ? activities[slot - 1] : null;
    final tooltipMsg = existing != null
        ? '${std.name} — ${ind.name} — ${existing.name}'
        : '${std.name} — ${ind.name} — (sin definir, clic para registrar)';
    return InkWell(
      onTap: () =>
          _showActivityDialog(context, academic, ind, slot, existing: existing),
      child: Tooltip(
        message: tooltipMsg,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EST$stdNum',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'I${ind.order}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            Text(
              'Act$slot',
              style: TextStyle(
                fontSize: 9,
                color: existing == null
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontStyle: existing == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCell(
    BuildContext context,
    AcademicProvider academic,
    List<Student> students,
    int rowIndex,
    Indicator ind,
    int slot,
  ) {
    final activities = academic.activitiesForIndicator(ind.id);
    final defined = activities.length >= slot;
    if (!defined) {
      return SizedBox(
        width: 64,
        height: 36,
        child: InkWell(
          onTap: () => _showActivityDialog(context, academic, ind, slot),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }
    final student = students[rowIndex];
    final colKey = _slotKey(ind.id, slot);
    final ctrl = _getController(student.id, colKey);
    return SizedBox(
      width: 64,
      child: Focus(
        onKeyEvent: (node, event) =>
            _handleVerticalNav(event, students, rowIndex, colKey),
        child: TextField(
          controller: ctrl,
          focusNode: _getFocusNode(student.id, colKey),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: const TextStyle(fontSize: 13),
          decoration: _gradeDecoration(ctrl.text),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  void _showActivityDialog(
    BuildContext context,
    AcademicProvider academic,
    Indicator ind,
    int slot, {
    Activity? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? date = existing?.date;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Actividad'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Diligencie el formulario para registrar la actividad por forma de evaluación',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setDialogState(() => date = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                              ),
                            ),
                            child: Text(
                              date == null
                                  ? 'dd/mm/aaaa'
                                  : DateFormat('dd/MM/yyyy').format(date!),
                              style: TextStyle(
                                color: date == null
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                academic.addActivity(
                  Activity(
                    id: existing?.id ?? const Uuid().v4(),
                    indicatorId: ind.id,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    order: slot,
                    date: date,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Registrar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewChip(double? value, {bool bold = false}) {
    if (value == null) {
      return const Text(
        '-',
        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
      );
    }
    return Text(
      value.toStringAsFixed(1),
      style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        color: AppColors.secondary,
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
    final standards = academic.standardsForSubjectAndPeriod(
      _selectedSubject!,
      _selectedPeriod!,
    );
    for (final entry in _controllers.entries) {
      final studentId = entry.key;
      for (final std in standards) {
        final indicators = academic.indicatorsForStandard(std.id);
        for (final ind in indicators) {
          for (var slot = 1; slot <= 3; slot++) {
            final v = double.tryParse(
              entry.value[_slotKey(ind.id, slot)]?.text ?? '',
            );
            if (v != null && v >= 0 && v <= 5) {
              academic.addGrade(
                Grade(
                  id: uuid.v4(),
                  studentId: studentId,
                  subjectId: _selectedSubject!,
                  periodId: _selectedPeriod!,
                  standardId: std.id,
                  indicatorId: ind.id,
                  slot: slot,
                  value: v,
                  registeredAt: DateTime.now(),
                ),
              );
              saved++;
            }
          }
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
