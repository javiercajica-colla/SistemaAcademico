import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'curved_clippers.dart';

/// Header azul con borde inferior curvo (docs/prompt_diseno_visual_pantallas.md
/// §2.1). `leadingIcon` es `Icons.arrow_back` en cualquier pantalla que no
/// sea el panel de inicio del rol, o `null` en el panel de inicio (no hay a
/// dónde volver); `onLeadingTap` decide qué hacer (este widget no asume
/// Navigator.pop).
class CurvedHeader extends StatelessWidget {
  const CurvedHeader({
    super.key,
    required this.leadingIcon,
    required this.onLeadingTap,
    this.hasNotification = false,
    this.onAvatarTap,
    this.avatarKey,
    this.avatarBytes,
    this.avatarUrl,
  });

  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final bool hasNotification;
  // Foto de perfil recién elegida en esta sesión, aún no subida o ya
  // cacheada localmente (ver AuthProvider.getAvatarBytes) — tiene
  // prioridad sobre avatarUrl porque no depende de red.
  final Uint8List? avatarBytes;
  // Foto de perfil persistida en Cloud Storage (AppUser.avatar). Se usa
  // cuando no hay avatarBytes en memoria, p. ej. justo después de recargar
  // la página. Si ambos son null se muestra el ícono de persona.
  final String? avatarUrl;
  // Callback opcional para que el llamador (MainLayout) abra un menú de
  // cuenta/notificaciones al tocar el avatar; `avatarKey` permite ubicar
  // ese menú justo debajo del avatar con showMenu().
  final VoidCallback? onAvatarTap;
  final Key? avatarKey;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const CurvedBottomClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 12, 16, 40),
        color: AppColors.primaryBlue,
        child: Row(
          children: [
            leadingIcon == null
                ? const SizedBox(width: 48)
                : IconButton(
                    icon: Icon(leadingIcon, color: Colors.white),
                    onPressed: onLeadingTap,
                  ),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            GestureDetector(
              key: avatarKey,
              onTap: onAvatarTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarBytes != null
                        ? MemoryImage(avatarBytes!)
                        : (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarBytes == null && (avatarUrl?.isEmpty ?? true))
                        ? const Icon(
                            Icons.person_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          )
                        : null,
                  ),
                  if (hasNotification)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accentRed,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
