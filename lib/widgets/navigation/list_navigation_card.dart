import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Tarjeta de nivel 2 (seleccionar entre varios elementos), una por fila
/// (docs/prompt_diseno_visual_pantallas.md §2.4). Pasa [icon] para
/// categorías del menú (círculo azul) o [initials] para personas (círculo
/// `avatarBg` con iniciales) — se debe dar exactamente uno de los dos.
class ListNavigationCard extends StatelessWidget {
  const ListNavigationCard({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.initials,
  }) : assert(
         (icon == null) != (initials == null),
         'ListNavigationCard: pasa icon (categorías) o initials (personas), no ambos ni ninguno.',
       );

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Row(
            children: [
              if (icon != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials!,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.accentRed,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
