import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

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
    final standards = academic.standardsForSubject(subject.id);
    final teacher = academic.teacherById(subject.teacherId ?? '');
    final totalWeight = standards.fold(0.0, (sum, s) => sum + s.weight);

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
                onPressed: () {},
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estándares Evaluativos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              _weightBadge(totalWeight),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Agregar Estándar'),
                onPressed: () => _showStandardDialog(context, subject.id),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (standards.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No hay estándares configurados'),
              ),
            )
          else
            ...standards.map(
              (std) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${std.weight.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              std.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              std.description,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          value: std.weight / 100,
                          color: AppColors.primary,
                          backgroundColor: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _weightBadge(double total) {
    final ok = total == 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ok
            ? AppColors.secondary.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ok
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            size: 14,
            color: ok ? AppColors.secondary : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            '${total.toStringAsFixed(0)}% / 100%',
            style: TextStyle(
              fontSize: 12,
              color: ok ? AppColors.secondary : AppColors.warning,
              fontWeight: FontWeight.w600,
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

  void _showStandardDialog(BuildContext context, String subjectId) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weightCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Estándar Evaluativo'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del estándar',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Porcentaje (%)',
                      suffixText: '%',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0 || n > 100) {
                        return 'Ingresa un valor entre 1 y 100';
                      }
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
              final newStandard = Standard(
                id: uuid.v4(),
                subjectId: subjectId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                weight: double.parse(weightCtrl.text.trim()),
              );
              final standardName = newStandard.name;
              // 1° Cerrar ANTES de notifyListeners
              Navigator.pop(ctx);
              // 2° Diferir la mutación del provider para evitar el assertion
              // "_dependents.isEmpty" al chocar con el cierre del diálogo.
              Future.microtask(() {
                academic.addStandard(newStandard);
                if (!mounted) return;
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Estándar "$standardName" agregado'),
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
      nameCtrl.dispose();
      descCtrl.dispose();
      weightCtrl.dispose();
    });
  }
}
