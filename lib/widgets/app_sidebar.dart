import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/academic_provider.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    return Container(
      width: 260,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          _buildHeader(context, user),
          const SizedBox(height: 8),
          Expanded(child: _buildNavItems(context, user.role)),
          _buildFooter(context, auth),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser user) {
    final roleColor = _roleColor(user.role);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: roleColor.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.split(' ').take(2).join(' '),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _roleLabel(user.role),
                        style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSchoolBadge(),
        ],
      ),
    );
  }

  Widget _buildSchoolBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Colegio San José', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                Text('Año lectivo 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems(BuildContext context, UserRole role) {
    final items = _navItems(role);
    final currentPath = GoRouterState.of(context).matchedLocation;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item == null) return _buildSectionDivider();
        final isActive = currentPath.startsWith(item.path);
        return _NavTile(item: item, isActive: isActive);
      },
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 1,
      color: const Color(0xFF1E293B),
    );
  }

  Widget _buildFooter(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.logout_rounded, color: Color(0xFF64748B), size: 20),
        title: const Text('Cerrar Sesión', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        onTap: () {
          auth.logout();
          context.go('/login');
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: const Color(0xFF1E293B),
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.coordinator:
        return AppColors.coordinator;
      case UserRole.teacher:
        return AppColors.teacher;
      case UserRole.student:
        return AppColors.student;
      case UserRole.parent:
        return AppColors.parent;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.coordinator:
        return 'COORDINADOR';
      case UserRole.teacher:
        return 'DOCENTE';
      case UserRole.student:
        return 'ESTUDIANTE';
      case UserRole.parent:
        return 'PADRE/MADRE';
    }
  }

  List<_NavItem?> _navItems(UserRole role) {
    switch (role) {
      case UserRole.coordinator:
        return [
          _NavItem('Dashboard', Icons.dashboard_rounded, '/coordinator/dashboard'),
          null,
          _NavItem('Usuarios', Icons.people_rounded, '/coordinator/users'),
          _NavItem('Docentes', Icons.person_rounded, '/coordinator/users'),
          null,
          _NavItem('Config. Académica', Icons.calendar_month_rounded, '/coordinator/academic-config'),
          _NavItem('Asignaturas', Icons.book_rounded, '/coordinator/subjects'),
          _NavItem('Cursos / Grupos', Icons.class_rounded, '/coordinator/courses'),
          _NavItem('Config. Evaluación', Icons.assessment_rounded, '/coordinator/grades-config'),
          null,
          _NavItem('Reportes y Boletines', Icons.summarize_rounded, '/coordinator/reports'),
        ];
      case UserRole.teacher:
        return [
          _NavItem('Dashboard', Icons.dashboard_rounded, '/teacher/dashboard'),
          null,
          _NavItem('Mis Cursos', Icons.class_rounded, '/teacher/courses'),
          _NavItem('Calificaciones', Icons.grade_rounded, '/teacher/grades'),
          _NavItem('Asistencia', Icons.fact_check_rounded, '/teacher/attendance'),
          _NavItem('Observaciones', Icons.edit_note_rounded, '/teacher/observations'),
        ];
      case UserRole.student:
        return [
          _NavItem('Mi Dashboard', Icons.dashboard_rounded, '/student/dashboard'),
          null,
          _NavItem('Calificaciones', Icons.grade_rounded, '/student/grades'),
          _NavItem('Asistencia', Icons.fact_check_rounded, '/student/attendance'),
        ];
      case UserRole.parent:
        return [
          _NavItem('Dashboard', Icons.dashboard_rounded, '/parent/dashboard'),
          null,
          _NavItem('Mis Hijos', Icons.family_restroom_rounded, '/parent/children'),
        ];
    }
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem(this.label, this.icon, this.path);
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  const _NavTile({required this.item, required this.isActive});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.item.path),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withOpacity(0.15)
                : _hovering
                    ? const Color(0xFF1E293B)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 18,
                color: active ? AppColors.primary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: TextStyle(
                    color: active ? AppColors.primary : const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (active)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
