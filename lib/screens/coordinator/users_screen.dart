import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../widgets/stat_card.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicProvider>();
    return Column(
      children: [
        _buildToolbar(context),
        _buildTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _buildTeachersTab(academic),
              _buildStudentsTab(academic),
              _buildParentsTab(academic),
              _buildAllUsersTab(academic),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Buscar usuarios...',
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Nuevo Usuario'),
            onPressed: () => _showUserDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'Docentes'),
          Tab(text: 'Estudiantes'),
          Tab(text: 'Padres de Familia'),
          Tab(text: 'Todos'),
        ],
      ),
    );
  }

  Widget _buildTeachersTab(AcademicProvider academic) {
    final teachers = academic.teachers.where((t) => t.fullName.toLowerCase().contains(_search)).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        title: 'Docentes (${teachers.length})',
        child: _buildTable(
          columns: const ['Nombre', 'Especialización', 'Asignaturas', 'Estado'],
          rows: teachers.map((t) => [
            _nameCell(t.fullName, Icons.school_rounded, AppColors.teacher),
            t.specialization,
            '${t.subjectIds.length} asignatura(s)',
            'Activo',
          ]).toList(),
          rowColors: teachers.map((_) => null).toList(),
        ),
      ),
    );
  }

  Widget _buildStudentsTab(AcademicProvider academic) {
    final students = academic.students.where((s) => s.fullName.toLowerCase().contains(_search)).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        title: 'Estudiantes (${students.length})',
        child: _buildTable(
          columns: const ['Nombre', 'Documento', 'Curso', 'Estado'],
          rows: students.map((s) {
            final course = academic.courseById(s.courseId ?? '');
            return [
              _nameCell(s.fullName, Icons.person_rounded, AppColors.student),
              s.documentId,
              course?.name ?? 'Sin curso',
              'Activo',
            ];
          }).toList(),
          rowColors: students.map((_) => null).toList(),
        ),
      ),
    );
  }

  Widget _buildParentsTab(AcademicProvider academic) {
    final parents = academic.parents.where((p) => p.fullName.toLowerCase().contains(_search)).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        title: 'Padres de Familia (${parents.length})',
        child: _buildTable(
          columns: const ['Nombre', 'Documento', 'Teléfono', 'Hijos'],
          rows: parents.map((p) => [
            _nameCell(p.fullName, Icons.family_restroom_rounded, AppColors.parent),
            p.documentId,
            p.phone,
            '${p.studentIds.length} estudiante(s)',
          ]).toList(),
          rowColors: parents.map((_) => null).toList(),
        ),
      ),
    );
  }

  Widget _buildAllUsersTab(AcademicProvider academic) {
    final users = academic.users.where((u) => u.name.toLowerCase().contains(_search)).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        title: 'Todos los Usuarios (${users.length})',
        child: _buildTable(
          columns: const ['Nombre', 'Email', 'Rol', 'Estado'],
          rows: users.map((u) => [
            _nameCell(u.name, _roleIcon(u.role), _roleColor(u.role)),
            u.email,
            _roleLabel(u.role),
            u.isActive ? 'Activo' : 'Inactivo',
          ]).toList(),
          rowColors: users.map((_) => null).toList(),
        ),
      ),
    );
  }

  Widget _buildTable({
    required List<String> columns,
    required List<List<dynamic>> rows,
    required List<Color?> rowColors,
  }) {
    if (rows.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No hay datos que mostrar')));
    }
    return SingleChildScrollView(
      child: Table(
        border: TableBorder(horizontalInside: BorderSide(color: AppColors.border)),
        columnWidths: const {0: FlexColumnWidth(2.5), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1)},
        children: [
          TableRow(
            decoration: const BoxDecoration(color: AppColors.surfaceVariant),
            children: columns.map((c) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            )).toList(),
          ),
          ...rows.map((row) => TableRow(
            children: row.map((cell) {
              if (cell is Widget) return Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: cell);
              final text = cell.toString();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: text == 'Activo'
                    ? _statusBadge(true)
                    : text == 'Inactivo'
                        ? _statusBadge(false)
                        : Text(text, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
          )),
        ],
      ),
    );
  }

  Widget _nameCell(String name, IconData icon, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _statusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(active ? 'Activo' : 'Inactivo',
          style: TextStyle(color: active ? AppColors.secondary : AppColors.error, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  void _showUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Usuario'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Nombre completo')),
              const SizedBox(height: 12),
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(value: 'coordinator', child: Text('Coordinador')),
                  DropdownMenuItem(value: 'teacher', child: Text('Docente')),
                  DropdownMenuItem(value: 'student', child: Text('Estudiante')),
                  DropdownMenuItem(value: 'parent', child: Text('Padre de Familia')),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Crear')),
        ],
      ),
    );
  }

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.coordinator: return AppColors.coordinator;
      case UserRole.teacher: return AppColors.teacher;
      case UserRole.student: return AppColors.student;
      case UserRole.parent: return AppColors.parent;
    }
  }

  IconData _roleIcon(UserRole r) {
    switch (r) {
      case UserRole.coordinator: return Icons.admin_panel_settings_rounded;
      case UserRole.teacher: return Icons.school_rounded;
      case UserRole.student: return Icons.person_rounded;
      case UserRole.parent: return Icons.family_restroom_rounded;
    }
  }

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.coordinator: return 'Coordinador';
      case UserRole.teacher: return 'Docente';
      case UserRole.student: return 'Estudiante';
      case UserRole.parent: return 'Padre de Familia';
    }
  }
}
