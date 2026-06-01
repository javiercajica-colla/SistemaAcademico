import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';
import 'app_sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          const AppSidebar(),
          Expanded(
            child: Column(
              children: [
                _AppHeader(),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final user = auth.currentUser!;
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
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          _buildPeriodBadge(academic),
          const SizedBox(width: 16),
          _buildNotifButton(context, unread, user.id, academic),
          const SizedBox(width: 8),
          _buildProfileChip(context, user.name, auth),
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
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(period.name, style: const TextStyle(color: AppColors.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const Text(' • Abierto', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNotifButton(BuildContext context, int unread, String userId, AcademicProvider academic) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
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
              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
              child: Center(
                child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileChip(BuildContext context, String name, AuthProvider auth) {
    return GestureDetector(
      onTap: () {},
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
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name.split(' ').take(2).join(' '),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, String userId, AcademicProvider academic) {
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
                for (final n in notifs) academic.markNotificationRead(n.id);
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = notifs[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _notifColor(n.type).withValues(alpha: 0.15),
                        child: Icon(_notifIcon(n.type), color: _notifColor(n.type), size: 18),
                      ),
                      title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w600, fontSize: 13)),
                      subtitle: Text(n.message, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: !n.isRead
                          ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
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
      case 'NotificationType.grade': return AppColors.primary;
      case 'NotificationType.attendance': return AppColors.warning;
      case 'NotificationType.observation': return AppColors.purple;
      case 'NotificationType.report': return AppColors.secondary;
      default: return AppColors.info;
    }
  }

  IconData _notifIcon(dynamic type) {
    switch (type.toString()) {
      case 'NotificationType.grade': return Icons.grade_rounded;
      case 'NotificationType.attendance': return Icons.event_busy_rounded;
      case 'NotificationType.observation': return Icons.edit_note_rounded;
      case 'NotificationType.report': return Icons.summarize_rounded;
      default: return Icons.notifications_rounded;
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
    if (route.contains('teacher/grades')) return 'Registro de Calificaciones';
    if (route.contains('teacher/courses')) return 'Mis Cursos';
    if (route.contains('attendance')) return 'Control de Asistencia';
    if (route.contains('observations')) return 'Observaciones';
    if (route.contains('student/grades')) return 'Mis Calificaciones';
    if (route.contains('parent/children')) return 'Información de Mis Hijos';
    return 'Sistema Académico';
  }
}
