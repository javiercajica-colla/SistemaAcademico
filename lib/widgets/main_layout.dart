import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/repository_provider.dart';
import '../services/user_credential_generator.dart';
import 'navigation/curved_header.dart';
import 'unsaved_changes_guard.dart';

// Navegación por íconos + botón "volver" (sin barra lateral, ver
// docs/prompt_diseno_visual_pantallas.md §3, nivel 1): la mayoría de rutas
// de herramienta viven un nivel por debajo del dashboard del rol, así que
// "volver" apunta ahí por defecto. Las pocas rutas agrupadas bajo un ícono
// "hub" (ej. Planillas) están dos niveles por debajo — _parentOverrides
// hace que esas vuelvan al hub en vez de saltarse directo al dashboard.
class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  static const _parentOverrides = {
    '/teacher/grade-sheet': '/teacher/planillas',
    '/teacher/grade-format': '/teacher/planillas',
    '/teacher/definitive-report': '/teacher/planillas',
    '/teacher/consolidated-report': '/teacher/planillas',
  };

  static String _dashboardPathFor(UserRole role) {
    return switch (role) {
      UserRole.coordinator || UserRole.admin => '/coordinator/dashboard',
      UserRole.teacher => '/teacher/dashboard',
      UserRole.student => '/student/dashboard',
      UserRole.parent => '/parent/dashboard',
    };
  }

  static String _backTargetFor(UserRole role, String currentPath) {
    return _parentOverrides[currentPath] ?? _dashboardPathFor(role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [_AppHeader(), Expanded(child: child)],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final GlobalKey _avatarKey = GlobalKey();
  _AppHeader();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();
    academic.listenNotificationsFor(user.id);
    final unread = academic.unreadNotificationsCount(user.id);

    final dashboardPath = MainLayout._dashboardPathFor(user.role);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final isDashboard = currentPath == dashboardPath;
    final backTarget = MainLayout._backTargetFor(user.role, currentPath);

    return CurvedHeader(
      leadingIcon: isDashboard ? null : Icons.arrow_back_rounded,
      onLeadingTap: isDashboard
          ? null
          : () => guardNavigation(context, () => context.go(backTarget)),
      hasNotification: unread > 0,
      avatarKey: _avatarKey,
      avatarBytes: auth.getAvatarBytes(user.id),
      avatarUrl: user.avatar,
      onAvatarTap: () =>
          _showAccountMenu(context, user, auth, academic, unread),
    );
  }

  // Consolida notificaciones + perfil + configuración + cerrar sesión en un
  // solo menú anclado al avatar (antes eran dos elementos separados —
  // campana de notificaciones y chip de perfil — en el header blanco).
  Future<void> _showAccountMenu(
    BuildContext context,
    AppUser user,
    AuthProvider auth,
    AcademicProvider academic,
    int unread,
  ) async {
    final box = _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null) return;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(offset.dx, offset.dy + size.height, size.width, 0),
        Offset.zero & overlayBox.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      items: [
        PopupMenuItem(
          value: 'notifications',
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined, size: 18),
              const SizedBox(width: 10),
              Text(unread > 0 ? 'Notificaciones ($unread)' : 'Notificaciones'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'perfil',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 18),
              SizedBox(width: 10),
              Text('Mi Perfil'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'configuracion',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 18),
              SizedBox(width: 10),
              Text('Configuración'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
    if (!context.mounted) return;
    switch (selected) {
      case 'notifications':
        _showNotifications(context, user.id, academic);
      case 'perfil':
        _showProfileDialog(context, user, auth);
      case 'configuracion':
        _navigateToConfig(context, user);
      case 'logout':
        auth.logout();
    }
  }

  void _showProfileDialog(
    BuildContext context,
    AppUser user,
    AuthProvider auth,
  ) {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    Uint8List? previewBytes = auth.getAvatarBytes(user.id);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Mi Perfil'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        withData: true,
                      );
                      if (result?.files.single.bytes != null) {
                        setDialogState(
                          () => previewBytes = result!.files.single.bytes,
                        );
                      }
                    },
                    child: Tooltip(
                      message: 'Cambiar foto',
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary,
                            backgroundImage: previewBytes != null
                                ? MemoryImage(previewBytes!)
                                : (user.avatar != null &&
                                      user.avatar!.isNotEmpty)
                                ? NetworkImage(user.avatar!)
                                : null,
                            child:
                                (previewBytes == null &&
                                    (user.avatar?.isEmpty ?? true))
                                ? Text(
                                    user.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toca para cambiar foto',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.roleDisplayName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: const Text('Cambiar contraseña'),
                      onPressed: () => _showChangePasswordDialog(context),
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
                if (previewBytes != null) {
                  auth.updateAvatar(user.id, previewBytes!);
                }
                auth.updateProfile(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
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

  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool saving = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Cambiar contraseña'),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (errorMsg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          errorMsg!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: currentCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Contraseña actual',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setDialogState(
                            () => obscureCurrent = !obscureCurrent,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) =>
                          UserCredentialGenerator.validatePasswordStrength(
                            v ?? '',
                          ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Mínimo 10 caracteres, con mayúscula, minúscula, número y carácter especial.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmCtrl,
                      obscureText: obscureNew,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar nueva contraseña',
                        prefixIcon: Icon(Icons.key_rounded),
                      ),
                      validator: (v) => (v != newCtrl.text)
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        saving = true;
                        errorMsg = null;
                      });
                      try {
                        await authRepository.changePassword(
                          currentPassword: currentCtrl.text,
                          newPassword: newCtrl.text,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Contraseña actualizada correctamente',
                              ),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                        }
                      } on AuthException catch (e) {
                        setDialogState(() {
                          saving = false;
                          errorMsg = e.message;
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToConfig(BuildContext context, AppUser user) {
    switch (user.role) {
      case UserRole.coordinator:
      case UserRole.admin:
        context.go('/coordinator/academic-config');
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración no disponible para su rol'),
          ),
        );
    }
  }

  void _showNotifications(
    BuildContext context,
    String userId,
    AcademicProvider academic,
  ) {
    final notifs = academic.notificationsForUser(userId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Notificaciones'),
            const Spacer(),
            TextButton(
              onPressed: () {
                for (final n in notifs) {
                  academic.markNotificationRead(n.id);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Marcar todas leídas'),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: notifs.isEmpty
              ? const Center(child: Text('Sin notificaciones'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: notifs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _notifColor(
                          n.type,
                        ).withValues(alpha: 0.15),
                        child: Icon(
                          _notifIcon(n.type),
                          color: _notifColor(n.type),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        n.message,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: !n.isRead
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                      onTap: () => academic.markNotificationRead(n.id),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Color _notifColor(dynamic type) {
    switch (type.toString()) {
      case 'NotificationType.grade':
        return AppColors.primary;
      case 'NotificationType.attendance':
        return AppColors.warning;
      case 'NotificationType.observation':
        return AppColors.purple;
      case 'NotificationType.report':
        return AppColors.secondary;
      default:
        return AppColors.info;
    }
  }

  IconData _notifIcon(dynamic type) {
    switch (type.toString()) {
      case 'NotificationType.grade':
        return Icons.grade_rounded;
      case 'NotificationType.attendance':
        return Icons.event_busy_rounded;
      case 'NotificationType.observation':
        return Icons.edit_note_rounded;
      case 'NotificationType.report':
        return Icons.summarize_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

}
