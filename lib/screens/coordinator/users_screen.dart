import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/user_avatar.dart';

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
    return _buildTabCard(
      title: 'Docentes (${teachers.length})',
      table: _buildTable(
        columns: const ['Nombre', 'Especialización', 'Asignaturas', 'Estado'],
        rows: teachers.map((t) => [
          _nameCell(t.userId, t.fullName, AppColors.teacher),
          t.specialization,
          '${t.subjectIds.length} asignatura(s)',
          'Activo',
        ]).toList(),
      ),
    );
  }

  Widget _buildStudentsTab(AcademicProvider academic) {
    final students = academic.students.where((s) => s.fullName.toLowerCase().contains(_search)).toList();
    return _buildTabCard(
      title: 'Estudiantes (${students.length})',
      table: _buildTable(
        columns: const ['Nombre', 'Documento', 'Curso', 'Estado'],
        rows: students.map((s) {
          final course = academic.courseById(s.courseId ?? '');
          return [
            _nameCell(s.userId, s.fullName, AppColors.student),
            s.documentId,
            course?.name ?? 'Sin curso',
            'Activo',
          ];
        }).toList(),
      ),
    );
  }

  Widget _buildParentsTab(AcademicProvider academic) {
    final parents = academic.parents.where((p) => p.fullName.toLowerCase().contains(_search)).toList();
    return _buildTabCard(
      title: 'Padres de Familia (${parents.length})',
      table: _buildTable(
        columns: const ['Nombre', 'Documento', 'Teléfono', 'Hijos'],
        rows: parents.map((p) => [
          _nameCell(p.userId, p.fullName, AppColors.parent),
          p.documentId,
          p.phone,
          '${p.studentIds.length} estudiante(s)',
        ]).toList(),
      ),
    );
  }

  Widget _buildAllUsersTab(AcademicProvider academic) {
    final users = academic.users.where((u) => u.name.toLowerCase().contains(_search)).toList();
    return _buildTabCard(
      title: 'Todos los Usuarios (${users.length})',
      table: _buildTable(
        columns: const ['Nombre', 'Email', 'Rol', 'Estado'],
        rows: users.map((u) => [
          _nameCell(u.id, u.name, _roleColor(u.role)),
          u.email,
          _roleLabel(u.role),
          u.isActive ? 'Activo' : 'Inactivo',
        ]).toList(),
      ),
    );
  }

  // Contenedor de tab con altura acotada para evitar overflow vertical
  Widget _buildTabCard({required String title, required Widget table}) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: table),
          ],
        ),
      ),
    );
  }

  Widget _buildTable({
    required List<String> columns,
    required List<List<dynamic>> rows,
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

  Widget _nameCell(String userId, String name, Color color) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            UserAvatar(
              userId: userId,
              name: name,
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.15),
              textColor: color,
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: GestureDetector(
                onTap: () => _pickAvatarForUser(userId),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(Icons.camera_alt, size: 8, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Future<void> _pickAvatarForUser(String userId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result?.files.single.bytes != null && mounted) {
      context.read<AuthProvider>().updateAvatar(userId, result!.files.single.bytes!);
    }
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
    // Leemos el provider ANTES de abrir el diálogo para evitar
    // usar el context dentro del builder y causar rebuilds en conflicto
    final academic = context.read<AcademicProvider>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    final docCtrl = TextEditingController();
    final specializationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationshipCtrl = TextEditingController(text: 'Padre');
    UserRole selectedRole = UserRole.teacher;
    String? selectedCourseId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Nuevo Usuario'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre completo'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo electrónico'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Email válido requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        decoration: const InputDecoration(labelText: 'Contraseña'),
                        validator: (v) => (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: const [
                          DropdownMenuItem(value: UserRole.coordinator, child: Text('Coordinador')),
                          DropdownMenuItem(value: UserRole.teacher,     child: Text('Docente')),
                          DropdownMenuItem(value: UserRole.student,     child: Text('Estudiante')),
                          DropdownMenuItem(value: UserRole.parent,      child: Text('Padre de Familia')),
                        ],
                        onChanged: (v) => setDialogState(() {
                          selectedRole = v!;
                          selectedCourseId = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: docCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Documento de identidad'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                      ),
                      // Campos dinámicos según rol
                      if (selectedRole == UserRole.teacher) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: specializationCtrl,
                          decoration: const InputDecoration(labelText: 'Especialización'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                        ),
                      ],
                      if (selectedRole == UserRole.student) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedCourseId,
                          decoration: const InputDecoration(labelText: 'Curso (opcional)'),
                          items: academic.courses
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (v) => setDialogState(() => selectedCourseId = v),
                        ),
                      ],
                      if (selectedRole == UserRole.parent) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Teléfono'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: relationshipCtrl,
                          decoration: const InputDecoration(labelText: 'Parentesco (Padre, Madre, Tutor...)'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  const uuid = Uuid();
                  final userId = uuid.v4();
                  final parts = nameCtrl.text.trim().split(' ');
                  final firstName = parts.first;
                  final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

                  // Capturamos todos los datos ANTES de cerrar
                  final newUser = AppUser(
                    id: userId,
                    name: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim().toLowerCase(),
                    password: passCtrl.text,
                    role: selectedRole,
                  );
                  final role = selectedRole;
                  final doc = docCtrl.text.trim();
                  final spec = specializationCtrl.text.trim();
                  final courseId = selectedCourseId;
                  final phone = phoneCtrl.text.trim();
                  final rel = relationshipCtrl.text.trim();
                  final userName = newUser.name;

                  // 1° Cerrar el diálogo ANTES de notifyListeners
                  Navigator.pop(ctx);

                  // 2° Actualizar el provider (dispara rebuilds ya sin el diálogo)
                  academic.addUser(newUser);
                  switch (role) {
                    case UserRole.teacher:
                      academic.addTeacher(Teacher(
                        id: uuid.v4(),
                        userId: userId,
                        firstName: firstName,
                        lastName: lastName,
                        documentId: doc,
                        specialization: spec,
                      ));
                    case UserRole.student:
                      academic.addStudent(Student(
                        id: uuid.v4(),
                        userId: userId,
                        firstName: firstName,
                        lastName: lastName,
                        documentId: doc,
                        birthDate: DateTime(2010),
                        courseId: courseId,
                      ));
                    case UserRole.parent:
                      academic.addParent(Parent(
                        id: uuid.v4(),
                        userId: userId,
                        firstName: firstName,
                        lastName: lastName,
                        documentId: doc,
                        phone: phone,
                        relationship: rel,
                      ));
                    case UserRole.coordinator:
                      break;
                  }

                  // 3° Mostrar confirmación
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Usuario "$userName" creado exitosamente'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                child: const Text('Crear Usuario'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      passCtrl.dispose();
      docCtrl.dispose();
      specializationCtrl.dispose();
      phoneCtrl.dispose();
      relationshipCtrl.dispose();
    });
  }

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.coordinator: return AppColors.coordinator;
      case UserRole.teacher: return AppColors.teacher;
      case UserRole.student: return AppColors.student;
      case UserRole.parent: return AppColors.parent;
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
