import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class AcademicConfigScreen extends StatefulWidget {
  const AcademicConfigScreen({super.key});

  @override
  State<AcademicConfigScreen> createState() => _AcademicConfigScreenState();
}

class _AcademicConfigScreenState extends State<AcademicConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Años Lectivos'),
              Tab(text: 'Períodos Académicos'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [_buildYearsTab(context), _buildPeriodsTab(context)],
          ),
        ),
      ],
    );
  }

  Widget _buildYearsTab(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Años Lectivos',
            subtitle: 'Gestiona los años académicos de la institución',
            action: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuevo Año'),
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              children: academic.years
                  .map(
                    (y) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: y.isActive
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: y.isActive
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                      title: Text(
                        'Año Lectivo ${y.year}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        y.isActive ? 'Año activo actual' : 'Año anterior',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (y.isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Activo',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodsTab(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    final fmt = DateFormat('dd/MM/yyyy');
    final periods = academic.activePeriods;
    final totalWeight = periods.fold(0.0, (sum, p) => sum + p.weight);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Períodos Académicos - ${academic.activeYear.year}',
            subtitle: 'Configura los períodos del año lectivo activo',
            action: ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nuevo Período'),
              onPressed: () => _showPeriodDialog(context),
            ),
          ),
          const SizedBox(height: 12),
          _buildWeightSummary(totalWeight),
          const SizedBox(height: 16),
          ...periods.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: p.isOpen
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          p.name.split(' ').last,
                          style: TextStyle(
                            color: p.isOpen
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.date_range_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${fmt.format(p.startDate)} – ${fmt.format(p.endDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${p.weight.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: p.isOpen
                                ? AppColors.secondary.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.isOpen ? 'Abierto' : 'Cerrado',
                            style: TextStyle(
                              color: p.isOpen
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onSelected: (v) {
                        if (v == 'toggle') setState(() => p.isOpen = !p.isOpen);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            p.isOpen ? 'Cerrar período' : 'Abrir período',
                          ),
                        ),
                      ],
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

  Widget _buildWeightSummary(double total) {
    final ok = total == 100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ok
            ? AppColors.secondary.withValues(alpha: 0.08)
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ok
              ? AppColors.secondary.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: ok ? AppColors.secondary : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            ok
                ? 'La suma de porcentajes es correcta (100%)'
                : 'La suma de porcentajes es ${total.toStringAsFixed(0)}% — debe ser 100%',
            style: TextStyle(
              color: ok ? AppColors.secondary : AppColors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Período Académico'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TextField(
                  decoration: InputDecoration(labelText: 'Nombre del período'),
                ),
                const SizedBox(height: 12),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Fecha inicio',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Fecha fin',
                    suffixIcon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Porcentaje (%)',
                    suffixText: '%',
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
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
