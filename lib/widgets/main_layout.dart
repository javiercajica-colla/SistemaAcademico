import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import 'app_sidebar.dart';
import 'user_avatar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // En web siempre sidebar permanente; en móvil/APK usar Drawer ocultable
    final usePermanentSidebar =
        kIsWeb || MediaQuery.of(context).size.width >= 768;

    if (usePermanentSidebar) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            const AppSidebar(),
            Expanded(
              child: Column(
                children: [
                  _AppHeader(showMenuButton: false),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Móvil / APK: sidebar como Drawer deslizable
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        width: 260,
        backgroundColor: AppColors.sidebarBg,
        child: const AppSidebar(),
      ),
      body: Column(
        children: [
          _AppHeader(showMenuButton: true),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  final bool showMenuButton;
  const _AppHeader({this.showMenuButton = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final user = auth.currentUser;
    if (user == null) return const SizedBox(height: 64);
    final unread = academic.unreadNotificationsCount(user.id);
    final route = GoRouterState.of(context).matchedLocation;
    final title = _titleForRoute(route);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded,
                    color: AppColors.textSecondary),
                tooltip: 'Menú',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          _buildPeriodBadge(academic),
          const SizedBox(width: 16),
          _buildNotifButton(context, unread, user.id, academic),
          const SizedBox(width: 8),
          _buildProfileChip(context, user, auth),
        ],
      ),
    );
  }

  Widget _buildPeriodBadge(AcademicProvider academic) {
    final period = academic.currentOpenPeriod;
    if (period == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            period.name,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            ' • Abierto',
            style: TextStyle(color: AppColors.secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifButton(
    BuildContext context,
    int unread,
    String userId,
    AcademicProvider academic,
  ) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () => _showNotifications(context, userId, academic),
          tooltip: 'Notificaciones',
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileChip(
    BuildContext context,
    AppUser user,
    AuthProvider auth,
  ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (value) {
        switch (value) {
          case 'perfil':
            _showProfileDialog(context, user, auth);
          case 'configuracion':
            _navigateToConfig(context, user);
          case 'logout':
            auth.logout();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'perfil',
          child: Row(children: [
            Icon(Icons.person_outline, size: 18),
            SizedBox(width: 10),
            Text('Mi Perfil'),
          ]),
        ),
        const PopupMenuItem(
          value: 'configuracion',
          child: Row(children: [
            Icon(Icons.settings_outlined, size: 18),
            SizedBox(width: 10),
            Text('Configuración'),
          ]),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [
            Icon(Icons.logout, size: 18, color: Colors.red),
            SizedBox(width: 10),
            Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserAvatar(
              userId: user.id,
              name: user.name,
              radius: 14,
              backgroundColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              user.name.split(' ').take(2).join(' '),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
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
          title: const Row(children: [
            Icon(Icons.person_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Mi Perfil'),
          ]),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(child: Column(
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
                              : null,
                          child: previewBytes == null
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
              ],
            )),
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

  void _navigateToConfig(BuildContext context, AppUser user) {
    switch (user.role) {
      case UserRole.coordinator:
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

  String _titleForRoute(String route) {
    if (route.contains('dashboard')) return 'Dashboard';
    if (route.contains('users')) return 'Gestión de Usuarios';
    if (route.contains('academic-config')) return 'Configuración Académica';
    if (route.contains('subjects')) return 'Asignaturas';
    if (route.contains('courses')) return 'Cursos y Grupos';
    if (route.contains('grades-config')) return 'Configuración de Evaluación';
    if (route.contains('reports')) return 'Reportes y Boletines';
    if (route.contains('teacher/standards')) return 'Estándares e Indicadores';
    if (route.contains('grade-sheet')) return 'Planilla de Notas';
    if (route.contains('grade-format')) return 'Formato de Notas';
    if (route.contains('hoja-de-vida')) return 'Hoja de Vida';
    if (route.contains('teacher/grades')) return 'Registro de Calificaciones';
    if (route.contains('teacher/courses')) return 'Mis Cursos';
    if (route.contains('attendance')) return 'Control de Asistencia';
    if (route.contains('observations')) return 'Observaciones';
    if (route.contains('student/grades')) return 'Mis Calificaciones';
    if (route.contains('parent/children')) return 'Información de Mis Hijos';
    if (route.contains('parent/bulletin')) return 'Boletín de Notas';
    if (route.contains('/email')) return 'Correo Interno';
    return 'Sistema Académico';
  }
}
