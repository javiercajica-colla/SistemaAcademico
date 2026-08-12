import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tarjeta de nivel 3 (acción específica), pensada para un `GridView` de 2
/// columnas (docs/prompt_diseno_visual_pantallas.md §2.3). Marca
/// [isHighlighted] solo en acciones de aprobación o que impliquen la
/// separación clínica/pedagógica del PIAR.
class GridActionCard extends StatelessWidget {
  const GridActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isHighlighted ? AppColors.accentRed : AppColors.cardBorder,
              width: isHighlighted ? 2 : 0.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryBlue,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              const Icon(
                Icons.open_in_new_rounded,
                color: AppColors.accentRed,
                size: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
