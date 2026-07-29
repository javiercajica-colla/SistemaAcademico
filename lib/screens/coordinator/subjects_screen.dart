import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  String? _selectedSubject;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final subjects = academic.subjects
        .where((s) => s.name.toLowerCase().contains(_search))
        .toList();

    return Row(
      children: [
        SizedBox(
          width: 300,
          child: Container(
            color: AppColors.surface,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) =>
                            setState(() => _search = v.toLowerCase()),
                        decoration: const InputDecoration(
                          hintText: 'Buscar asignatura...',
                          prefixIcon: Icon(Icons.search_rounded, size: 18),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Nueva Asignatura'),
                          onPressed: () => _showSubjectDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (_, i) {
                      final s = subjects[i];
                      final isSelected = s.id == _selectedSubject;
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: AppColors.primary.withValues(
                          alpha: 0.08,
                        ),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              s.code.substring(
                                0,
                                s.code.length > 2 ? 2 : s.code.length,
                              ),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          s.area,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => setState(() => _selectedSubject = s.id),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _selectedSubject == null
              ? _buildEmptyState()
              : _buildSubjectDetail(context, academic),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.book_outlined, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'Selecciona una asignatura',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'para ver sus detalles y estándares',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDetail(BuildContext context, AcademicProvider academic) {
    final subject = academic.subjectById(_selectedSubject!);
    if (subject == null) return _buildEmptyState();
    final teacher = academic.teacherById(subject.teacherId ?? '');
    final courseAssignments = academic.assignments
        .where((a) => a.subjectId == subject.id)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subject.area} • ${subject.hoursPerWeek}h/semana • Código: ${subject.code}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Editar'),
                onPressed: () =>
                    _showEditSubjectDialog(context, academic, subject),
              ),
            ],
          ),
          if (teacher != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teacher.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.teacher.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_rounded,
                    color: AppColors.teacher,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Docente responsable: ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      teacher.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Cursos donde se dicta',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (courseAssignments.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Aún no se ha asignado a ningún curso. Usa "Editar" para '
                'agregarla a uno o varios grados.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: courseAssignments.asMap().entries.map((entry) {
                  final isLast = entry.key == courseAssignments.length - 1;
                  final a = entry.value;
                  final course = academic.courseById(a.courseId);
                  final assignedTeacherId = a.teacherId;
                  final assignedTeacher = assignedTeacherId == null
                      ? null
                      : academic.teacherById(assignedTeacherId);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(
                              bottom: BorderSide(color: AppColors.border),
                            ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            course?.name ?? '—',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (assignedTeacher != null)
                          Chip(
                            label: Text(
                              assignedTeacher.fullName,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: AppColors.teacher.withValues(
                              alpha: 0.08,
                            ),
                          )
                        else
                          const Text(
                            'Sin docente asignado',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        TextButton(
                          onPressed: () => _showAssignTeacherDialog(
                            context,
                            academic,
                            a,
                            course?.name ?? '',
                          ),
                          child: Text(
                            assignedTeacher != null ? 'Cambiar' : 'Asignar',
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            'Estándares Evaluativos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Los Estándares (hasta 5 por año), sus Competencias por '
                    'período y las Actividades se definen desde el módulo '
                    '"Estándares" del docente asignado a esta asignatura.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubjectDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();
    final hoursCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Asignatura'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código (ej: MAT)',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: areaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Área (ej: Ciencias Exactas)',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Horas por semana',
                      suffixText: 'h',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Ingresa un número válido';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final academic = context.read<AcademicProvider>();
              const uuid = Uuid();
              final newSubject = Subject(
                id: uuid.v4(),
                code: codeCtrl.text.trim().toUpperCase(),
                name: nameCtrl.text.trim(),
                area: areaCtrl.text.trim(),
                hoursPerWeek: int.parse(hoursCtrl.text.trim()),
              );
              final subjectName = newSubject.name;
              final subjectId = newSubject.id;
              // 1° Cerrar el diálogo ANTES de notifyListeners
              Navigator.pop(ctx);
              // 2° Diferir la mutación del provider al siguiente microtask para
              // evitar el assertion "_dependents.isEmpty" al chocar con el cierre
              // del diálogo en el mismo frame.
              Future.microtask(() {
                academic.addSubject(newSubject);
                if (!mounted) return;
                setState(() => _selectedSubject = subjectId);
                // El analyzer no reconoce el guard `mounted` cuando el
                // BuildContext se usa dentro de un Future.microtask (solo
                // rastrea gaps de `await`); el chequeo de arriba ya lo cubre.
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Asignatura "$subjectName" creada'),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              });
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) {
      codeCtrl.dispose();
      nameCtrl.dispose();
      areaCtrl.dispose();
      hoursCtrl.dispose();
    });
  }

  void _showAssignTeacherDialog(
    BuildContext context,
    AcademicProvider academic,
    SubjectAssignment assignment,
    String courseName,
  ) {
    String? selectedTeacherId = assignment.teacherId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Docente — $courseName'),
          content: SizedBox(
            width: 360,
            child: DropdownButtonFormField<String?>(
              initialValue: selectedTeacherId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Docente'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sin asignar'),
                ),
                ...academic.teachers.map(
                  (t) => DropdownMenuItem<String?>(
                    value: t.id,
                    child: Text(t.fullName, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setDialogState(() => selectedTeacherId = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final teacherId = selectedTeacherId;
                // Cerrar el diálogo ANTES de mutar el provider y diferir la
                // mutación al siguiente microtask evita el assertion
                // "_dependents.isEmpty" al chocar con el cierre del diálogo
                // en el mismo frame.
                Navigator.pop(ctx);
                Future.microtask(() {
                  academic.addAssignment(
                    SubjectAssignment(
                      id: assignment.id,
                      teacherId: teacherId,
                      subjectId: assignment.subjectId,
                      courseId: assignment.courseId,
                      academicYearId: assignment.academicYearId,
                    ),
                  );
                });
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Editar datos básicos de la asignatura y, ya que se abre esta misma
  // pantalla, dejar agregarla de una vez a otros grados completos (todas sus
  // secciones) sin tener que repetirlo curso por curso desde Cursos.
  void _showEditSubjectDialog(
    BuildContext context,
    AcademicProvider academic,
    Subject subject,
  ) {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController(text: subject.code);
    final nameCtrl = TextEditingController(text: subject.name);
    final areaCtrl = TextEditingController(text: subject.area);
    final hoursCtrl = TextEditingController(text: '${subject.hoursPerWeek}');
    final gradosOrdenados = academic.courses.map((c) => c.grade).toSet().toList()
      ..sort(
        (a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0),
      );
    final selectedGrados = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentAssignments = academic.assignments
              .where((a) => a.subjectId == subject.id)
              .toList();
          return AlertDialog(
            title: const Text('Editar Asignatura'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código (ej: MAT)',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: areaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Área (ej: Ciencias Exactas)',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Campo requerido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: hoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Horas por semana',
                          suffixText: 'h',
                        ),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n < 1) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Grados donde se dicta',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Text(
                        'Marca un grado para agregar la asignatura a todas '
                        'sus secciones.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (gradosOrdenados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'No hay cursos creados todavía.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...gradosOrdenados.map((grado) {
                          final sections = academic.courses
                              .where((c) => c.grade == grado)
                              .toList();
                          final assignedSections = sections
                              .where(
                                (c) => currentAssignments.any(
                                  (a) => a.courseId == c.id,
                                ),
                              )
                              .toList();
                          final fullyAssigned =
                              sections.isNotEmpty &&
                              assignedSections.length == sections.length;
                          final label = fullyAssigned
                              ? 'Grado $grado° (ya asignada)'
                              : assignedSections.isEmpty
                              ? 'Grado $grado°'
                              : 'Grado $grado° (parcial: '
                                    '${assignedSections.length}/${sections.length})';
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              label,
                              style: const TextStyle(fontSize: 13),
                            ),
                            value: fullyAssigned
                                ? true
                                : selectedGrados.contains(grado),
                            onChanged: fullyAssigned
                                ? null
                                : (v) => setDialogState(() {
                                    if (v == true) {
                                      selectedGrados.add(grado);
                                    } else {
                                      selectedGrados.remove(grado);
                                    }
                                  }),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  final updatedSubject = Subject(
                    id: subject.id,
                    code: codeCtrl.text.trim().toUpperCase(),
                    name: nameCtrl.text.trim(),
                    area: areaCtrl.text.trim(),
                    hoursPerWeek: int.parse(hoursCtrl.text.trim()),
                    teacherId: subject.teacherId,
                  );
                  final gradosToAdd = Set<String>.of(selectedGrados);
                  // Cerrar el diálogo ANTES de mutar el provider y diferir
                  // la mutación al siguiente microtask evita el assertion
                  // "_dependents.isEmpty" al chocar con el cierre del
                  // diálogo en el mismo frame.
                  Navigator.pop(ctx);
                  Future.microtask(() {
                    academic.addSubject(updatedSubject);
                    var added = 0;
                    for (final grado in gradosToAdd) {
                      for (final c in academic.courses.where(
                        (c) => c.grade == grado,
                      )) {
                        final exists = academic.assignments.any(
                          (a) =>
                              a.courseId == c.id && a.subjectId == subject.id,
                        );
                        if (exists) continue;
                        academic.addAssignment(
                          SubjectAssignment(
                            id: const Uuid().v4(),
                            subjectId: subject.id,
                            courseId: c.id,
                            academicYearId: c.academicYearId,
                          ),
                        );
                        added++;
                      }
                    }
                    if (!mounted || added == 0) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Asignatura agregada a $added sección(es) nueva(s).',
                        ),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                  });
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      codeCtrl.dispose();
      nameCtrl.dispose();
      areaCtrl.dispose();
      hoursCtrl.dispose();
    });
  }
}
