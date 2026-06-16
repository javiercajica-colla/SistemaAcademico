import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

class StandardsScreen extends StatefulWidget {
  const StandardsScreen({super.key});

  @override
  State<StandardsScreen> createState() => _StandardsScreenState();
}

class _StandardsScreenState extends State<StandardsScreen> {
  String? _selectedPeriodId;
  String? _selectedSubjectId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final academic = context.read<AcademicProvider>();
    _selectedPeriodId ??= academic.currentOpenPeriod?.id ?? academic.activePeriods.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final auth = context.watch<AuthProvider>();
    final teacher = academic.teacherByUserId(auth.currentUser!.id);

    if (teacher == null) {
      return const Center(child: Text('No se encontró el perfil de docente.'));
    }

    final periods = academic.activePeriods;
    final assignments = academic.assignmentsForTeacher(teacher.id);
    final subjectIds = assignments.map((a) => a.subjectId).toSet().toList();
    final subjects = academic.subjects.where((s) => subjectIds.contains(s.id)).toList();

    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilters(periods, subjects),
        const Divider(height: 1),
        Expanded(
          child: _selectedPeriodId == null || _selectedSubjectId == null
              ? const Center(child: Text('Seleccione un periodo y una asignatura.'))
              : _buildStandardsList(academic, teacher.id),
        ),
      ],
    );
  }

  Widget _buildFilters(List<AcademicPeriod> periods, List<Subject> subjects) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Periodo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: periods.map((p) {
              final selected = p.id == _selectedPeriodId;
              return ChoiceChip(
                label: Text(p.name),
                selected: selected,
                onSelected: (_) => setState(() => _selectedPeriodId = p.id),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 13),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Asignatura', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: subjects.map((s) {
              final selected = s.id == _selectedSubjectId;
              return ChoiceChip(
                label: Text(s.name),
                selected: selected,
                onSelected: (_) => setState(() => _selectedSubjectId = s.id),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontSize: 13),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardsList(AcademicProvider academic, String teacherId) {
    final standards = academic.standardsForSubjectAndPeriod(
      _selectedSubjectId!,
      _selectedPeriodId!,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estándares (${standards.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddStandardDialog(academic),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar Estándar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (standards.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.checklist_rounded, size: 48, color: AppColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No hay estándares para este periodo y asignatura.',
                      style: TextStyle(color: AppColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('Presiona "Agregar Estándar" para comenzar.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            )
          else
            ...standards.map((s) => _buildStandardCard(academic, s)),
        ],
      ),
    );
  }

  Widget _buildStandardCard(AcademicProvider academic, Standard standard) {
    final indicators = academic.indicatorsForStandard(standard.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.star_outline_rounded, color: AppColors.primary, size: 20),
        ),
        title: Text(standard.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(standard.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Peso: ${standard.weight.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
              onPressed: () => _confirmDeleteStandard(academic, standard),
              tooltip: 'Eliminar estándar',
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...indicators.map((ind) => _buildIndicatorCard(academic, ind)),
          if (indicators.length < 3)
            TextButton.icon(
              onPressed: () => _showAddIndicatorDialog(academic, standard.id, indicators.length + 1),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Agregar Indicador'),
            ),
          if (indicators.length >= 3)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Máximo 3 indicadores por estándar.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(AcademicProvider academic, Indicator indicator) {
    final activities = academic.activitiesForIndicator(indicator.id);
    final grade = academic.calculateIndicatorGrade(indicator.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.purple.withValues(alpha: 0.15),
          child: Text(
            '${indicator.order}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple),
          ),
        ),
        title: Text(indicator.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        subtitle: grade != null
            ? Text('Promedio: ${grade.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600))
            : const Text('Sin calificaciones programadas', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${activities.length}/4 actividades',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              onPressed: () => academic.deleteIndicator(indicator.id),
              tooltip: 'Eliminar indicador',
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...activities.map((act) => _buildActivityRow(academic, act)),
          if (activities.length < 4)
            TextButton.icon(
              onPressed: () => _showAddActivityDialog(academic, indicator.id, activities.length + 1),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Agregar Actividad', style: TextStyle(fontSize: 12)),
            ),
          if (activities.length >= 4)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Máximo 4 actividades por indicador.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(AcademicProvider academic, Activity activity) {
    final gradeCtrl = TextEditingController(
      text: activity.gradeValue?.toStringAsFixed(1) ?? '',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text('${activity.order}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.info)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (activity.description.isNotEmpty)
                  Text(activity.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Programada', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Switch(
                value: activity.isProgrammed,
                onChanged: (_) => academic.toggleActivityProgrammed(activity.id),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (activity.isProgrammed) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: gradeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Nota',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
                onSubmitted: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  academic.setActivityGrade(activity.id, parsed);
                },
              ),
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            onPressed: () => academic.deleteActivity(activity.id),
            tooltip: 'Eliminar actividad',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  void _showAddStandardDialog(AcademicProvider academic) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '33');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.star_outline_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Nuevo Estándar'),
        ]),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del estándar', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Peso (%)', border: OutlineInputBorder(), suffixText: '%'),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d <= 0 || d > 100) return 'Valor entre 1 y 100';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              academic.addStandard(Standard(
                id: const Uuid().v4(),
                subjectId: _selectedSubjectId!,
                periodId: _selectedPeriodId!,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                weight: double.parse(weightCtrl.text),
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddIndicatorDialog(AcademicProvider academic, String standardId, int order) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.purple.withValues(alpha: 0.15),
            child: Text('$order', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.purple)),
          ),
          const SizedBox(width: 8),
          Text('Indicador $order'),
        ]),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre del indicador', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              academic.addIndicator(Indicator(
                id: const Uuid().v4(),
                standardId: standardId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                order: order,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog(AcademicProvider academic, String indicatorId, int order) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
            child: Center(child: Text('$order', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.info))),
          ),
          const SizedBox(width: 8),
          Text('Actividad $order'),
        ]),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre de la actividad', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              academic.addActivity(Activity(
                id: const Uuid().v4(),
                indicatorId: indicatorId,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                order: order,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStandard(AcademicProvider academic, Standard standard) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Estándar'),
        content: Text('¿Eliminar "${standard.name}"? Se eliminarán también sus indicadores y actividades.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              academic.deleteStandard(standard.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
