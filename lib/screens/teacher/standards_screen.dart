import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';

const _kMaxEstandaresPorAnio = 5;
const _kMaxCompetenciasPorPeriodo = 5;

/// Estándar (por año) → Competencia (por período, una debe ser
/// actitudinal). Las Actividades (hasta 4 por competencia) ya no se crean
/// aquí: se registran directamente desde "Calificaciones", donde el
/// docente hace clic en cada casilla para definir su nombre y fecha antes
/// de calificar — ver grade_entry_screen.dart. El docente sigue siendo
/// quien define los Estándares (antes existía además un mecanismo de
/// "plantilla" en la pantalla del coordinador que no se usaba realmente;
/// se retiró).
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
    final currentUserId = auth.currentUser?.id;
    final teacher = currentUserId == null
        ? null
        : academic.teacherByUserId(currentUserId);

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
            for (var i = 0; i < estandares.length; i++)
              _buildEstandarCard(academic, estandares[i], i + 1),
        ],
      ),
    );
  }

  /// Iteración simple "ESTÁNDAR N. Título" con sus "COMPETENCIA N.M.
  /// Título" indentadas debajo — así el docente ve de un vistazo lo que ya
  /// registró y evita duplicar.
  Widget _buildEstandarCard(
    AcademicProvider academic,
    Estandar estandar,
    int displayNumber,
  ) {
    final competencias = academic.competenciasForEstandarAndPeriod(
      estandar.id,
      _selectedPeriodId!,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'ESTÁNDAR $displayNumber. ${estandar.name}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: () => _showEditEstandarDialog(academic, estandar),
                tooltip: 'Editar estándar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: () => _confirmDeleteEstandar(academic, estandar),
                tooltip: 'Eliminar estándar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (estandar.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                estandar.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 12),
          for (var i = 0; i < competencias.length; i++)
            _buildCompetenciaRow(
              academic,
              estandar,
              competencias[i],
              displayNumber,
              i + 1,
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

  Widget _buildCompetenciaRow(
    AcademicProvider academic,
    Estandar estandar,
    Competencia competencia,
    int estandarDisplayNumber,
    int competenciaDisplayNumber,
  ) {
    final esActitudinal = competencia.tipo == CompetenciaTipo.actitudinal;
    final tipoColor = esActitudinal ? AppColors.warning : AppColors.purple;

    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      'COMPETENCIA $estandarDisplayNumber.$competenciaDisplayNumber. '
                      '${competencia.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
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
                if (competencia.description.isNotEmpty)
                  Text(
                    competencia.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
            onPressed: () =>
                _showEditCompetenciaDialog(academic, estandar, competencia),
            tooltip: 'Editar competencia',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
            onPressed: () => academic.deleteCompetencia(competencia.id),
            tooltip: 'Eliminar competencia',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
                        _showAddEstandarDialog(academic, estandares);
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

  void _showAddEstandarDialog(AcademicProvider academic, List<Estandar> estandares) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // Máximo + 1 en vez de conteo + 1: si se borró un estándar de en medio,
    // el conteo puede repetir un order ya usado por otro y duplicar el
    // número mostrado ("ESTÁNDAR 4" dos veces).
    final nextOrder = estandares.isEmpty
        ? 1
        : estandares.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1;

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
                  order: nextOrder,
                  // El peso ya no lo asigna el docente: se reparte en
                  // partes iguales entre los estándares activos del
                  // período (ver AcademicProvider.equalEstandarWeightPercent).
                  weight: 0,
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
    final estandarDisplayNumber =
        academic.estandaresForSubject(_selectedSubjectId!).indexOf(estandar) + 1;
    // Máximo + 1 en vez de conteo + 1 (mismo motivo que en Estándar: evita
    // duplicar el número mostrado si se borró una competencia de en medio).
    final nextOrder = existentes.isEmpty
        ? 1
        : existentes.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Competencia $estandarDisplayNumber.${existentes.length + 1}'),
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
                    order: nextOrder,
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

}
