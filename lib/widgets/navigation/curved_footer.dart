import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'curved_clippers.dart';

/// Franja azul decorativa al final de la pantalla, curva hacia arriba —
/// puramente decorativa, sin contenido interactivo (docs/prompt_diseno_visual_pantallas.md §2.5).
class CurvedFooter extends StatelessWidget {
  const CurvedFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const CurvedTopClipper(curveHeight: 12),
      child: Container(
        height: 20,
        width: double.infinity,
        color: AppColors.primaryBlue,
      ),
    );
  }
}
