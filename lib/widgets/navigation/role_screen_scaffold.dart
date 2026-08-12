import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'curved_footer.dart';
import 'role_divider.dart';

/// Combina título/subtítulo, divisor de tres colores, el contenido de la
/// pantalla y el footer curvo (docs/prompt_diseno_visual_pantallas.md
/// §2.6). NO incluye `CurvedHeader`: a diferencia del mockup original, el
/// header curvo se centralizó en `MainLayout` (una sola vez para toda la
/// app, ver `_AppHeader`) en vez de repetirse pantalla por pantalla —
/// evita apilar dos headers azules cuando cada pantalla de rol vive
/// dentro del área de contenido de `MainLayout`.
///
/// `content` debe poder medirse dentro de un `SingleChildScrollView`: si es
/// un `GridView`/`ListView`, pásalo con `shrinkWrap: true` y
/// `physics: NeverScrollableScrollPhysics()`.
class RoleScreenScaffold extends StatelessWidget {
  const RoleScreenScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  final String title;
  final String subtitle;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              const RoleDivider(),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: content,
              ),
              const SizedBox(height: 20),
              const CurvedFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
