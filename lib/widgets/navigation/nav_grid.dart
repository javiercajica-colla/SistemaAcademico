import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../unsaved_changes_guard.dart';
import 'grid_action_card.dart';

/// Una entrada de [NavGrid]: una herramienta ya existente en la app (mismo
/// ícono/etiqueta/ruta que ya usa `AppSidebar`), no una funcionalidad nueva.
class NavGridItem {
  const NavGridItem({
    required this.icon,
    required this.label,
    required this.route,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isHighlighted;
}

/// Grilla de 2 columnas de [GridActionCard], una por herramienta — usada
/// como contenido principal de los paneles de inicio de cada rol
/// (docs/prompt_diseno_visual_pantallas.md §3, nivel 1).
class NavGrid extends StatelessWidget {
  const NavGrid({super.key, required this.items});

  final List<NavGridItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 560 ? 4 : (width >= 380 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.92,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            return GridActionCard(
              icon: item.icon,
              label: item.label,
              isHighlighted: item.isHighlighted,
              onTap: () =>
                  guardNavigation(context, () => context.go(item.route)),
            );
          },
        );
      },
    );
  }
}
