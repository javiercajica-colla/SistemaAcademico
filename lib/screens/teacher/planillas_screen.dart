import 'package:flutter/material.dart';

import '../../widgets/navigation/nav_grid.dart';
import '../../widgets/navigation/role_screen_scaffold.dart';

/// Agrupa las herramientas de planillas del docente (antes 4 íconos sueltos
/// en el panel de inicio) bajo un solo ícono "Planillas" — mismas rutas ya
/// existentes, solo un nivel extra de agrupación visual.
class PlanillasScreen extends StatelessWidget {
  const PlanillasScreen({super.key});

  static const _navItems = [
    NavGridItem(
      icon: Icons.table_view_rounded,
      label: 'Planilla de Notas',
      route: '/teacher/grade-sheet',
    ),
    NavGridItem(
      icon: Icons.print_rounded,
      label: 'Formato de Notas',
      route: '/teacher/grade-format',
    ),
    NavGridItem(
      icon: Icons.emoji_events_rounded,
      label: 'Notas Definitivas',
      route: '/teacher/definitive-report',
    ),
    NavGridItem(
      icon: Icons.grid_view_rounded,
      label: 'Consolidado',
      route: '/teacher/consolidated-report',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const RoleScreenScaffold(
      title: 'PLANILLAS',
      subtitle: 'Notas, formatos y consolidados',
      content: NavGrid(items: _navItems),
    );
  }
}
