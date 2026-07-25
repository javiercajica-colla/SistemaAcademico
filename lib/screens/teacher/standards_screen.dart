import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

const _kMaxEstandaresPorAnio = 5;
const _kMaxCompetenciasPorPeriodo = 5;
const _kMaxActividadesPorCompetencia = 6;

/// Estándar (por año) → Competencia (por período, una debe ser
/// actitudinal) → Actividad (hasta 6, calificadas desde "Calificaciones").
/// Reemplaza el modelo Standard → Indicator → Activity — ver plan de
/// rediseño de evaluación. El docente sigue siendo quien define los
/// Estándares (antes existía además un mecanismo de "plantilla" en la
/// pantalla del coordinador que no se usaba realmente; se retiró).
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
    _selectedPeriodId ??=
        academic.currentOpenPeriod?.id ??
        academic.activePeriods.firstOrNull?.id;
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
    final subjects = academic.subjects
        .where((s) => subjectIds.contains(s.id))
        .toList();

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
              ? const Center(
                  child: Text('Seleccione un periodo y una asignatura.'),
                )
              : _buildEstandaresList(academic),
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
          const Text(
            'Periodo (para las Competencias — los Estándares son del año completo)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
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
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Asignatura',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
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
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEstandaresList(AcademicProvider academic) {
    final estandares = academic.estandaresForSubject(_selectedSubjectId!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Estándares del año (${estandares.length}/$_kMaxEstandaresPorAnio)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showAddChooserDialog(academic, estandares),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (estandares.isEmpty)
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
                  Icon(
                    Icons.checklist_rounded,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Esta asignatura todavía no tiene Estándares definidos para el año.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Presiona "Agregar Estándar" para comenzar.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...estandares.map((e) => _buildEstandarCard(academic, e)),
        ],
      ),
    );
  }

  Widget _buildEstandarCard(AcademicProvider academic, Estandar estandar) {
    final competencias = academic.competenciasForEstandarAndPeriod(
      estandar.id,
      _selectedPeriodId!,
    );
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
          child: const Icon(
            Icons.star_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          estandar.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          estandar.description,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Peso: ${estandar.weight.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              onPressed: () => _showEditEstandarDialog(academic, estandar),
              tooltip: 'Editar estándar',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              onPressed: () => _confirmDeleteEstandar(academic, estandar),
              tooltip: 'Eliminar estándar',
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            'Competencias de este período (${competencias.length}/$_kMaxCompetenciasPorPeriodo)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'No es obligatorio trabajar este estándar en todos los períodos — si no agregas competencias aquí, simplemente no aporta nota en este período.',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          ...competencias.map((c) => _buildCompetenciaCard(academic, estandar, c)),
          if (competencias.isEmpty)
            const Text(
              'Usa el botón "Agregar" de arriba para crear una competencia en este estándar.',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          if (competencias.isNotEmpty &&
              !competencias.any((c) => c.tipo == CompetenciaTipo.actitudinal))
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Falta marcar una competencia como Actitudinal para este período.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompetenciaCard(
    AcademicProvider academic,
    Estandar estandar,
    Competencia competencia,
  ) {
    final actividades = academic.actividadesForCompetencia(competencia.id);
    final esActitudinal = competencia.tipo == CompetenciaTipo.actitudinal;
    final tipoColor = esActitudinal ? AppColors.warning : AppColors.purple;

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
          backgroundColor: tipoColor.withValues(alpha: 0.15),
          child: Text(
            '${competencia.order}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: tipoColor,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                competencia.name,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tipoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                esActitudinal ? 'Actitudinal' : 'Cognitiva',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: tipoColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          competencia.description,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${actividades.length}/$_kMaxActividadesPorCompetencia actividades',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
              onPressed: () =>
                  _showEditCompetenciaDialog(academic, estandar, competencia),
              tooltip: 'Editar competencia',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
              onPressed: () => academic.deleteCompetencia(competencia.id),
              tooltip: 'Eliminar competencia',
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (actividades.isEmpty)
            const Text(
              'Aún no hay actividades registradas para esta competencia.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            ...actividades.map((act) => _buildActividadRow(academic, act)),
          if (actividades.length < _kMaxActividadesPorCompetencia)
            TextButton.icon(
              onPressed: () => _showAddActividadDialog(
                academic,
                competencia.id,
                actividades.length + 1,
              ),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Agregar Actividad'),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Las notas de cada actividad se registran desde el módulo de Calificaciones.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActividadRow(AcademicProvider academic, Actividad actividad) {
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
              child: Text(
                '${actividad.order}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actividad.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (actividad.date != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(actividad.date!),
                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                  ),
                if (actividad.description.isNotEmpty)
                  Text(
                    actividad.description,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            onPressed: () => academic.deleteActividad(actividad.id),
            tooltip: 'Eliminar actividad',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  /// Punto de entrada único para agregar: primero el docente elige si va a
  /// crear un Estándar o una Competencia; para Competencia, primero debe
  /// existir al menos un Estándar y elegir a cuál pertenece — no se puede
  /// crear una Competencia "suelta".
  void _showAddChooserDialog(AcademicProvider academic, List<Estandar> estandares) {
    final puedeAgregarEstandar = estandares.length < _kMaxEstandaresPorAnio;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué deseas agregar?'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                enabled: puedeAgregarEstandar,
                leading: const Icon(
                  Icons.star_outline_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Estándar'),
                subtitle: Text(
                  puedeAgregarEstandar
                      ? 'Válido para todo el año lectivo de esta asignatura.'
                      : 'Ya hay $_kMaxEstandaresPorAnio estándares (máximo).',
                ),
                onTap: puedeAgregarEstandar
                    ? () {
                        Navigator.pop(ctx);
                        _showAddEstandarDialog(academic, estandares.length);
                      }
                    : null,
              ),
              const Divider(),
              ListTile(
                enabled: estandares.isNotEmpty,
                leading: const Icon(
                  Icons.checklist_rtl_rounded,
                  color: AppColors.purple,
                ),
                title: const Text('Competencia'),
                subtitle: Text(
                  estandares.isEmpty
                      ? 'Primero debes crear un Estándar.'
                      : 'Para el período seleccionado, dentro de un Estándar existente.',
                ),
                onTap: estandares.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _showElegirEstandarParaCompetencia(academic, estandares);
                      },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showElegirEstandarParaCompetencia(
    AcademicProvider academic,
    List<Estandar> estandares,
  ) {
    var selectedId = estandares.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('¿A qué Estándar pertenece?'),
          content: SizedBox(
            width: 400,
            child: DropdownButtonFormField<String>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                labelText: 'Estándar',
                border: OutlineInputBorder(),
              ),
              items: estandares
                  .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setDialogState(() => selectedId = v!),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                final estandar = estandares.firstWhere((e) => e.id == selectedId);
                final existentes = academic.competenciasForEstandarAndPeriod(
                  estandar.id,
                  _selectedPeriodId!,
                );
                if (existentes.length >= _kMaxCompetenciasPorPeriodo) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Este estándar ya tiene el máximo de competencias para este período.',
                      ),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                  return;
                }
                _showAddCompetenciaDialog(academic, estandar, existentes);
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEstandarDialog(AcademicProvider academic, int currentCount) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '33');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Nuevo Estándar'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Válido para todo el año lectivo, no solo un período.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del estándar',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              academic.addEstandar(
                Estandar(
                  id: const Uuid().v4(),
                  subjectId: _selectedSubjectId!,
                  academicYearId: academic.activeYear.id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  order: currentCount + 1,
                  weight: double.parse(weightCtrl.text),
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditEstandarDialog(AcademicProvider academic, Estandar estandar) {
    final nameCtrl = TextEditingController(text: estandar.name);
    final descCtrl = TextEditingController(text: estandar.description);
    final weightCtrl = TextEditingController(text: estandar.weight.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Editar Estándar'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del estándar',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Peso (%)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                  ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              academic.updateEstandar(
                estandar.id,
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                weight: double.parse(weightCtrl.text),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEstandar(AcademicProvider academic, Estandar estandar) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Estándar'),
        content: Text(
          '¿Eliminar "${estandar.name}"? Se eliminarán también sus competencias y actividades de todos los períodos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              academic.deleteEstandar(estandar.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddCompetenciaDialog(
    AcademicProvider academic,
    Estandar estandar,
    List<Competencia> existentes,
  ) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final yaHayActitudinal =
        existentes.any((c) => c.tipo == CompetenciaTipo.actitudinal);
    var tipo = yaHayActitudinal
        ? CompetenciaTipo.cognitiva
        : CompetenciaTipo.actitudinal;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Competencia ${existentes.length + 1}'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la competencia',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Cognitiva'),
                          selected: tipo == CompetenciaTipo.cognitiva,
                          onSelected: (_) => setDialogState(
                            () => tipo = CompetenciaTipo.cognitiva,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Actitudinal'),
                          selected: tipo == CompetenciaTipo.actitudinal,
                          onSelected: yaHayActitudinal
                              ? null
                              : (_) => setDialogState(
                                  () => tipo = CompetenciaTipo.actitudinal,
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (yaHayActitudinal)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ya existe una competencia actitudinal para este período.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
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
                academic.addCompetencia(
                  Competencia(
                    id: const Uuid().v4(),
                    estandarId: estandar.id,
                    periodId: _selectedPeriodId!,
                    tipo: tipo,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    order: existentes.length + 1,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCompetenciaDialog(
    AcademicProvider academic,
    Estandar estandar,
    Competencia competencia,
  ) {
    final nameCtrl = TextEditingController(text: competencia.name);
    final descCtrl = TextEditingController(text: competencia.description);
    final formKey = GlobalKey<FormState>();
    final otrasActitudinales = academic
        .competenciasForEstandarAndPeriod(estandar.id, competencia.periodId)
        .where((c) => c.id != competencia.id && c.tipo == CompetenciaTipo.actitudinal)
        .isNotEmpty;
    var tipo = competencia.tipo;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Editar Competencia'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la competencia',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Cognitiva'),
                          selected: tipo == CompetenciaTipo.cognitiva,
                          onSelected: (_) => setDialogState(
                            () => tipo = CompetenciaTipo.cognitiva,
                          ),
                        ),
                        ChoiceChip(
                          label: const Text('Actitudinal'),
                          selected: tipo == CompetenciaTipo.actitudinal,
                          onSelected: otrasActitudinales
                              ? null
                              : (_) => setDialogState(
                                  () => tipo = CompetenciaTipo.actitudinal,
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (otrasActitudinales)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ya existe otra competencia actitudinal para este período.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
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
                academic.updateCompetencia(
                  competencia.id,
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  tipo: tipo,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddActividadDialog(
    AcademicProvider academic,
    String competenciaId,
    int order,
  ) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Actividad $order'),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la actividad',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      selectedDate == null
                          ? 'Elegir fecha (opcional)'
                          : DateFormat('dd/MM/yyyy').format(selectedDate!),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 1),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
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
                academic.addActividad(
                  Actividad(
                    id: const Uuid().v4(),
                    competenciaId: competenciaId,
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    order: order,
                    date: selectedDate,
                  ),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
