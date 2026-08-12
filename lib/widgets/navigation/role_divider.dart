import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Línea de tres segmentos centrada, debajo del título de cada pantalla
/// (docs/prompt_diseno_visual_pantallas.md §2.2).
class RoleDivider extends StatelessWidget {
  const RoleDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 36, height: 2, color: AppColors.primaryBlue),
        const SizedBox(width: 2),
        Container(width: 16, height: 2, color: AppColors.accentRed),
        const SizedBox(width: 2),
        Container(width: 36, height: 2, color: AppColors.primaryBlue),
      ],
    );
  }
}
