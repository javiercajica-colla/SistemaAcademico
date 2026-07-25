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
  bool _started = false;
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Map<String, Map<String, FocusNode>> _focusNodes = {};
  final ScrollController _hScrollController = ScrollController();

  @override
  void dispose() {
    _clearControllers();
    _hScrollController.dispose();
    super.dispose();
  }

  /// Descarta los controladores y focus nodes de la grilla actual. Se debe
  /// llamar al volver al selector de curso/asignatura/periodo (además de en
  /// `dispose`): de lo contrario, los controladores quedan indexados solo
  /// por estudiante+celda y sobreviven al cambio de periodo dentro de la
  /// misma pantalla, mostrando (y permitiendo guardar) las notas del
  /// periodo anterior como si fueran del nuevo.
  void _clearControllers() {
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
    _controllers.clear();
    _focusNodes.clear();
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

  double? _competenciaPreview(String studentId, List<Actividad> actividades) {
    final vals = <double>[];
    for (final act in actividades) {
      final v = double.tryParse(_getController(studentId, act.id).text);
      if (v != null) vals.add(v);
    }
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  double? _estandarPreview(
    String studentId,
    List<Competencia> competencias,
    Map<String, List<Actividad>> actividadesByCompetencia,
  ) {
    final vals = competencias
        .map(
          (c) => _competenciaPreview(
            studentId,
            actividadesByCompetencia[c.id] ?? const [],
          ),
        )
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
    final estandares = academic.estandaresForSubject(_selectedSubject!);
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
              onPressed: () => setState(() {
                _clearControllers();
                _started = false;
              }),
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
        if (estandares.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Esta asignatura todavía no tiene Estándares definidos. '
              'Ve a "Estándares" para crearlos antes de calificar.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          _buildGradeTable(context, students, estandares, evalConfig, academic),
      ],
    );
  }

  Widget _buildGradeTable(
    BuildContext context,
    List<Student> students,
    List<Estandar> estandares,
    EvaluationConfig? evalConfig,
    AcademicProvider academic,
  ) {
    final sw = evalConfig?.standardsWeight ?? 70;
    final fw = evalConfig?.finalExamWeight ?? 30;

    final competenciasByEstandar = {
      for (final e in estandares)
        e.id: academic.competenciasForEstandarAndPeriod(e.id, _selectedPeriod!),
    };
    final actividadesByCompetencia = <String, List<Actividad>>{
      for (final comps in competenciasByEstandar.values)
        for (final c in comps) c.id: academic.actividadesForCompetencia(c.id),
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
            onPressed: () => _saveGrades(context, academic, estandares),
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
              for (var ei = 0; ei < estandares.length; ei++) ...[
                if ((competenciasByEstandar[estandares[ei].id] ??
                        const <Competencia>[])
                    .isEmpty)
                  DataColumn(
                    label: _groupHeader(
                      'EST${ei + 1}',
                      '${estandares[ei].weight.toStringAsFixed(0)}%',
                      'Sin competencias este período',
                      tooltip: estandares[ei].name,
                    ),
                  )
                else ...[
                  for (final comp in competenciasByEstandar[estandares[ei].id]!) ...[
                    for (final act in actividadesByCompetencia[comp.id]!)
                      DataColumn(
                        label: _actividadHeader(estandares[ei], ei + 1, comp, act),
                      ),
                    if (actividadesByCompetencia[comp.id]!.isEmpty)
                      DataColumn(
                        label: _groupHeader(
                          'EST${ei + 1}',
                          'C${comp.order}',
                          'Sin actividades',
                          tooltip:
                              '${estandares[ei].name} — ${comp.name} (definir actividades en Estándares)',
                        ),
                      ),
                    DataColumn(
                      label: _groupHeader(
                        'EST${ei + 1}',
                        'C${comp.order}',
                        'Prom.',
                        italic: true,
                        tipoColor: comp.tipo == CompetenciaTipo.actitudinal
                            ? AppColors.warning
                            : AppColors.purple,
                        tooltip:
                            '${estandares[ei].name} — ${comp.name}'
                            '${comp.tipo == CompetenciaTipo.actitudinal ? " (Actitudinal)" : " (Cognitiva)"}',
                      ),
                    ),
                  ],
                  DataColumn(
                    label: _groupHeader(
                      'EST${ei + 1}',
                      'Prom. Estándar',
                      '${estandares[ei].weight.toStringAsFixed(0)}%',
                      bold: true,
                      tooltip: estandares[ei].name,
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
              for (final comps in competenciasByEstandar.values) {
                for (final comp in comps) {
                  for (final act in actividadesByCompetencia[comp.id] ?? const <Actividad>[]) {
                    final ctrl = _getController(student.id, act.id);
                    if (ctrl.text.isEmpty) {
                      try {
                        final g = existingGrades.firstWhere(
                          (g) => g.actividadId == act.id,
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
                    (g) => g.estandarId == null,
                  );
                  finalCtrl.text = g.value.toString();
                } catch (_) {}
              }

              double weightedSum = 0;
              double totalWeight = 0;
              for (final e in estandares) {
                final comps = competenciasByEstandar[e.id] ?? const <Competencia>[];
                final score = _estandarPreview(
                  student.id,
                  comps,
                  actividadesByCompetencia,
                );
                if (score != null) {
                  weightedSum += score * e.weight;
                  totalWeight += e.weight;
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
                  for (final e in estandares) ...[
                    if ((competenciasByEstandar[e.id] ?? const <Competencia>[])
                        .isEmpty)
                      const DataCell(
                        Text(
                          '-',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      )
                    else ...[
                      for (final comp in competenciasByEstandar[e.id]!) ...[
                        for (final act in actividadesByCompetencia[comp.id]!)
                          DataCell(
                            _buildActividadCell(students, rowIndex, act),
                          ),
                        if (actividadesByCompetencia[comp.id]!.isEmpty)
                          const DataCell(
                            Text(
                              '-',
                              style: TextStyle(color: AppColors.textTertiary),
                            ),
                          ),
                        DataCell(
                          _previewChip(
                            _competenciaPreview(
                              student.id,
                              actividadesByCompetencia[comp.id]!,
                            ),
                          ),
                        ),
                      ],
                      DataCell(
                        _previewChip(
                          _estandarPreview(
                            student.id,
                            competenciasByEstandar[e.id]!,
                            actividadesByCompetencia,
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
    Color? tipoColor,
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
            color: bold
                ? AppColors.secondary
                : (tipoColor ?? AppColors.textPrimary),
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

  Widget _actividadHeader(
    Estandar estandar,
    int estNum,
    Competencia comp,
    Actividad act,
  ) {
    final tipoColor = comp.tipo == CompetenciaTipo.actitudinal
        ? AppColors.warning
        : AppColors.purple;
    return Tooltip(
      message:
          '${estandar.name} — ${comp.name} '
          '(${comp.tipo == CompetenciaTipo.actitudinal ? "Actitudinal" : "Cognitiva"}) — '
          '${act.name}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EST$estNum',
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'C${comp.order}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: tipoColor,
            ),
          ),
          Text(
            'Act${act.order}',
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActividadCell(
    List<Student> students,
    int rowIndex,
    Actividad actividad,
  ) {
    final student = students[rowIndex];
    final ctrl = _getController(student.id, actividad.id);
    return SizedBox(
      width: 64,
      child: Focus(
        onKeyEvent: (node, event) =>
            _handleVerticalNav(event, students, rowIndex, actividad.id),
        child: TextField(
          controller: ctrl,
          focusNode: _getFocusNode(student.id, actividad.id),
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

  void _saveGrades(
    BuildContext context,
    AcademicProvider academic,
    List<Estandar> estandares,
  ) {
    const uuid = Uuid();
    int saved = 0;
    final competenciasByEstandar = {
      for (final e in estandares)
        e.id: academic.competenciasForEstandarAndPeriod(e.id, _selectedPeriod!),
    };
    for (final entry in _controllers.entries) {
      final studentId = entry.key;
      for (final e in estandares) {
        for (final comp in competenciasByEstandar[e.id] ?? const <Competencia>[]) {
          for (final act in academic.actividadesForCompetencia(comp.id)) {
            final v = double.tryParse(entry.value[act.id]?.text ?? '');
            if (v != null && v >= 0 && v <= 5) {
              academic.addGrade(
                Grade(
                  id: uuid.v4(),
                  studentId: studentId,
                  subjectId: _selectedSubject!,
                  periodId: _selectedPeriod!,
                  estandarId: e.id,
                  competenciaId: comp.id,
                  actividadId: act.id,
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
