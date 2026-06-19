import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/credential_export.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/credential_log_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/user_credential_generator.dart';
import '../../widgets/bulk_import_dialog.dart';
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
          PopupMenuButton<String>(
            tooltip: 'Exportar credenciales generadas en esta sesión',
            icon: const Icon(Icons.download_rounded),
            onSelected: (value) {
              switch (value) {
                case 'pdf':
                  _exportCredentialsPdf(context);
                case 'excel':
                  _exportCredentialsExcel(context);
                case 'clear':
                  _confirmClearCredentialLog(context);
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(children: [
                  Icon(Icons.picture_as_pdf_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Exportar credenciales (PDF)'),
                ]),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(children: [
                  Icon(Icons.grid_on_rounded, size: 18),
                  SizedBox(width: 8),
                  Text('Exportar credenciales (Excel)'),
                ]),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'clear',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Limpiar registro', style: TextStyle(color: AppColors.error)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.upload_file_rounded, size: 18),
            label: const Text('Importar desde Excel/CSV'),
            onPressed: () => BulkImportDialog.show(context),
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
        columns: const ['Nombre', 'Especialización', 'Asignaturas', 'Estado', ''],
        rows: teachers.map((t) {
          final assignmentCount = academic.assignmentsForTeacher(t.id).length;
          final directedCourse = academic.courses.firstWhere(
            (c) => c.directorTeacherId == t.id,
            orElse: () => const Course(id: '', name: '', grade: '', section: '', academicYearId: ''),
          );
          return [
            _nameCell(t.userId, t.fullName, AppColors.teacher),
            t.specialization,
            directedCourse.id.isEmpty
                ? '$assignmentCount asignatura(s)'
                : '$assignmentCount asignatura(s) · Dir. ${directedCourse.name}',
            'Activo',
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              tooltip: 'Editar asignaturas y dirección de grupo',
              onPressed: () => _showEditTeacherDialog(context, t),
            ),
          ];
        }).toList(),
      ),
    );
  }

  Widget _buildStudentsTab(AcademicProvider academic) {
    final students = academic.students.where((s) => s.fullName.toLowerCase().contains(_search)).toList();
    return _buildTabCard(
      title: 'Estudiantes (${students.length})',
      table: _buildTable(
        columns: const ['Nombre', 'Documento', 'Curso', 'Estado', ''],
        rows: students.map((s) {
          final course = academic.courseById(s.courseId ?? '');
          final parentCount = s.parentIds.length;
          return [
            _nameCell(s.userId, s.fullName, AppColors.student),
            s.documentId,
            '${course?.name ?? "Sin curso"}${parentCount > 0 ? ' · $parentCount acudiente(s)' : ''}',
            'Activo',
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
              tooltip: 'Editar estudiante',
              onPressed: () => _showEditStudentDialog(context, s),
            ),
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
        columnWidths: const {0: FlexColumnWidth(2.5), 1: FlexColumnWidth(2), 2: FlexColumnWidth(1.5), 3: FlexColumnWidth(1), 4: FixedColumnWidth(48)},
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

  Future<void> _exportCredentialsPdf(BuildContext context, {List<CredentialLogEntry>? entriesOverride}) async {
    final entries = entriesOverride ?? await CredentialLogService().getAll();
    if (entries.isEmpty) {
      if (mounted) _showEmptyLogMessage(context);
      return;
    }
    await exportCredentialsPdf(entries);
  }

  Future<void> _exportCredentialsExcel(BuildContext context, {List<CredentialLogEntry>? entriesOverride}) async {
    final entries = entriesOverride ?? await CredentialLogService().getAll();
    if (entries.isEmpty) {
      if (mounted) _showEmptyLogMessage(context);
      return;
    }
    await exportCredentialsExcel(entries);
  }

  void _showEmptyLogMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay credenciales generadas en esta sesión todavía')),
    );
  }

  void _confirmClearCredentialLog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpiar registro de credenciales'),
        content: const Text(
          'Esto borrará el registro local de usuarios y contraseñas generados en este navegador. '
          'Asegúrate de haberlos exportado o compartido antes de continuar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await CredentialLogService().clear();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registro de credenciales eliminado')),
                );
              }
            },
            child: const Text('Limpiar'),
          ),
        ],
      ),
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
    final docCtrl = TextEditingController();
    final specializationCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationshipCtrl = TextEditingController(text: 'Padre');
    UserRole selectedRole = UserRole.teacher;
    String? selectedCourseId;
    bool creating = false;
    String? errorMsg;
    String username = '';
    String password = UserCredentialGenerator.generatePassword();
    final List<(String subjectId, String courseId)> pendingAssignments = [];
    String? pendingSubjectId;
    String? pendingCourseId;
    String? selectedDirectorCourseId;

    String computeUsername() {
      final parts = nameCtrl.text.trim().split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.isEmpty) return '';
      final firstName = parts.first;
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final existing = academic.users.map((u) => u.email.split('@').first);
      return UserCredentialGenerator.generateUsername(firstName, lastName, existing);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          username = computeUsername();
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
                      if (errorMsg != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                          ),
                          child: Text(errorMsg!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre completo'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Credenciales generadas automáticamente',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            _credentialRow(
                              label: 'Usuario',
                              value: username.isEmpty ? '—' : username,
                              onCopy: username.isEmpty ? null : () => _copyToClipboard(context, username),
                            ),
                            const SizedBox(height: 6),
                            _credentialRow(
                              label: 'Contraseña',
                              value: password,
                              onCopy: () => _copyToClipboard(context, password),
                              trailing: IconButton(
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                tooltip: 'Generar otra contraseña',
                                onPressed: () => setDialogState(() {
                                  password = UserCredentialGenerator.generatePassword();
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedRole,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: const [
                          DropdownMenuItem(value: UserRole.coordinator, child: Text('Coordinador')),
                          DropdownMenuItem(value: UserRole.admin,       child: Text('Administrador')),
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
                        const SizedBox(height: 16),
                        const Text('Asignaturas y cursos a cargo (opcional)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        if (pendingAssignments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: pendingAssignments.map((p) {
                                final subj = academic.subjectById(p.$1);
                                final course = academic.courseById(p.$2);
                                return Chip(
                                  label: Text('${subj?.name ?? ''} · ${course?.name ?? ''}', style: const TextStyle(fontSize: 12)),
                                  onDeleted: () => setDialogState(() => pendingAssignments.remove(p)),
                                );
                              }).toList(),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: pendingSubjectId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Asignatura', isDense: true),
                                items: academic.subjects
                                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) => setDialogState(() => pendingSubjectId = v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: pendingCourseId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Curso', isDense: true),
                                items: academic.courses
                                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (v) => setDialogState(() => pendingCourseId = v),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                              tooltip: 'Agregar asignación',
                              onPressed: (pendingSubjectId == null || pendingCourseId == null)
                                  ? null
                                  : () => setDialogState(() {
                                        final pair = (pendingSubjectId!, pendingCourseId!);
                                        if (!pendingAssignments.contains(pair)) {
                                          pendingAssignments.add(pair);
                                        }
                                        pendingSubjectId = null;
                                        pendingCourseId = null;
                                      }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          initialValue: selectedDirectorCourseId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Director de grupo (opcional)'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Ninguno')),
                            ...academic.courses.where((c) => c.directorTeacherId == null).map(
                                  (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                                ),
                          ],
                          onChanged: (v) => setDialogState(() => selectedDirectorCourseId = v),
                        ),
                        if (academic.courses.every((c) => c.directorTeacherId != null))
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('Todos los cursos ya tienen director de grupo asignado.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                onPressed: creating
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() {
                          creating = true;
                          errorMsg = null;
                        });

                        const uuid = Uuid();
                        final parts = nameCtrl.text.trim().split(' ');
                        final firstName = parts.first;
                        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
                        final role = selectedRole;
                        final doc = docCtrl.text.trim();
                        final spec = specializationCtrl.text.trim();
                        final courseId = selectedCourseId;
                        final phone = phoneCtrl.text.trim();
                        final rel = relationshipCtrl.text.trim();
                        final generatedUsername = username;
                        final generatedPassword = password;

                        try {
                          // Crea la cuenta real en Firebase Auth (sin afectar
                          // la sesión del coordinador) y su perfil en Firestore.
                          final newUser = await FirebaseAuthService().createUser(
                            email: '$generatedUsername@colegio.edu.co',
                            password: generatedPassword,
                            name: nameCtrl.text.trim(),
                            role: role,
                          );
                          final userId = newUser.id;
                          final userName = newUser.name;

                          switch (role) {
                            case UserRole.teacher:
                              final teacherId = uuid.v4();
                              academic.addTeacher(Teacher(
                                id: teacherId,
                                userId: userId,
                                firstName: firstName,
                                lastName: lastName,
                                documentId: doc,
                                specialization: spec,
                                subjectIds: pendingAssignments.map((p) => p.$1).toSet().toList(),
                              ));
                              for (final pa in pendingAssignments) {
                                academic.addAssignment(SubjectAssignment(
                                  id: uuid.v4(),
                                  teacherId: teacherId,
                                  subjectId: pa.$1,
                                  courseId: pa.$2,
                                  academicYearId: academic.activeYear.id,
                                ));
                              }
                              if (selectedDirectorCourseId != null) {
                                academic.setCourseDirector(selectedDirectorCourseId!, teacherId);
                              }
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
                            case UserRole.admin:
                              break;
                          }

                          await CredentialLogService().add(CredentialLogEntry(
                            firstName: firstName,
                            lastName: lastName,
                            documentId: doc,
                            username: generatedUsername,
                            password: generatedPassword,
                            roleLabel: _roleLabel(role),
                            createdAt: DateTime.now(),
                          ));

                          Navigator.pop(ctx);
                          if (mounted) {
                            _showSuccessDialog(
                              context,
                              userName: userName,
                              username: generatedUsername,
                              password: generatedPassword,
                            );
                          }
                        } on AuthException catch (e) {
                          setDialogState(() {
                            creating = false;
                            errorMsg = e.message;
                          });
                        }
                      },
                child: creating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear Usuario'),
              ),
            ],
          );
        },
      ),
    ).then((_) {
      nameCtrl.dispose();
      docCtrl.dispose();
      specializationCtrl.dispose();
      phoneCtrl.dispose();
      relationshipCtrl.dispose();
    });
  }

  Widget _credentialRow({
    required String label,
    required String value,
    VoidCallback? onCopy,
    Widget? trailing,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text('$label:', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16),
            tooltip: 'Copiar',
            onPressed: onCopy,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ?trailing,
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado al portapapeles'), duration: Duration(seconds: 1)),
    );
  }

  void _showSuccessDialog(
    BuildContext context, {
    required String userName,
    required String username,
    required String password,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.check_circle_rounded, color: AppColors.secondary),
          SizedBox(width: 8),
          Text('Usuario creado'),
        ]),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('La cuenta de "$userName" fue creada exitosamente.'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _credentialRow(
                      label: 'Usuario',
                      value: username,
                      onCopy: () => _copyToClipboard(ctx, username),
                    ),
                    const SizedBox(height: 8),
                    _credentialRow(
                      label: 'Contraseña',
                      value: password,
                      onCopy: () => _copyToClipboard(ctx, password),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta contraseña no se puede recuperar después. Cópiala y compártela con el usuario ahora.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(BuildContext context, Student student) {
    final academic = context.read<AcademicProvider>();
    final docCtrl = TextEditingController(text: student.documentId);
    String? selectedCourseId = student.courseId;
    DateTime birthDate = student.birthDate;
    String? pendingParentId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentStudent = academic.studentById(student.id) ?? student;
          final linkedParents = currentStudent.parentIds.map(academic.parentById).whereType<Parent>().toList();
          final availableParents = academic.parents.where((p) => !currentStudent.parentIds.contains(p.id)).toList();

          return AlertDialog(
            title: Text('Editar — ${student.fullName}'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: docCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Documento de identidad'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: birthDate,
                          firstDate: DateTime(1990),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setDialogState(() => birthDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Fecha de nacimiento'),
                        child: Text('${birthDate.day}/${birthDate.month}/${birthDate.year}'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedCourseId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Curso'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Sin curso')),
                        ...academic.courses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setDialogState(() => selectedCourseId = v),
                    ),
                    const SizedBox(height: 16),
                    const Text('Acudientes (padres de familia)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    if (linkedParents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Sin acudiente asignado aún.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: linkedParents.map((p) {
                            return Chip(
                              label: Text('${p.fullName} (${p.relationship})', style: const TextStyle(fontSize: 12)),
                              onDeleted: () {
                                academic.unlinkParentFromStudent(student.id, p.id);
                                setDialogState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: pendingParentId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Agregar acudiente', isDense: true),
                            items: availableParents
                                .map((p) => DropdownMenuItem(value: p.id, child: Text('${p.fullName} (${p.relationship})', overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setDialogState(() => pendingParentId = v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                          tooltip: 'Vincular acudiente',
                          onPressed: pendingParentId == null
                              ? null
                              : () {
                                  academic.linkParentToStudent(student.id, pendingParentId!);
                                  setDialogState(() => pendingParentId = null);
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () {
                  academic.updateStudent(Student(
                    id: student.id,
                    userId: student.userId,
                    firstName: student.firstName,
                    lastName: student.lastName,
                    documentId: docCtrl.text.trim(),
                    birthDate: birthDate,
                    courseId: selectedCourseId,
                    parentIds: currentStudent.parentIds,
                  ));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cambios guardados para ${student.fullName}'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTeacherDialog(BuildContext context, Teacher teacher) {
    final academic = context.read<AcademicProvider>();
    String? pendingSubjectId;
    String? pendingCourseId;
    final currentDirectorCourse = academic.courses.firstWhere(
      (c) => c.directorTeacherId == teacher.id,
      orElse: () => const Course(id: '', name: '', grade: '', section: '', academicYearId: ''),
    );
    String? selectedDirectorCourseId = currentDirectorCourse.id.isEmpty ? null : currentDirectorCourse.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final assignments = academic.assignmentsForTeacher(teacher.id);
          return AlertDialog(
            title: Text('Editar — ${teacher.fullName}'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Especialización: ${teacher.specialization}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    const Text('Asignaturas y cursos a cargo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    if (assignments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text('Sin asignaturas asignadas aún.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: assignments.map((a) {
                            final subj = academic.subjectById(a.subjectId);
                            final course = academic.courseById(a.courseId);
                            return Chip(
                              label: Text('${subj?.name ?? ''} · ${course?.name ?? ''}', style: const TextStyle(fontSize: 12)),
                              onDeleted: () {
                                academic.deleteAssignment(a.id);
                                setDialogState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: pendingSubjectId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Asignatura', isDense: true),
                            items: academic.subjects
                                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setDialogState(() => pendingSubjectId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: pendingCourseId,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Curso', isDense: true),
                            items: academic.courses
                                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (v) => setDialogState(() => pendingCourseId = v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                          tooltip: 'Agregar asignación',
                          onPressed: (pendingSubjectId == null || pendingCourseId == null)
                              ? null
                              : () {
                                  final alreadyExists = assignments.any(
                                    (a) => a.subjectId == pendingSubjectId && a.courseId == pendingCourseId,
                                  );
                                  if (!alreadyExists) {
                                    academic.addAssignment(SubjectAssignment(
                                      id: const Uuid().v4(),
                                      teacherId: teacher.id,
                                      subjectId: pendingSubjectId!,
                                      courseId: pendingCourseId!,
                                      academicYearId: academic.activeYear.id,
                                    ));
                                  }
                                  setDialogState(() {
                                    pendingSubjectId = null;
                                    pendingCourseId = null;
                                  });
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Director de grupo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      initialValue: selectedDirectorCourseId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Curso a dirigir (opcional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Ninguno')),
                        ...academic.courses.map((c) {
                          final hasOtherDirector = c.directorTeacherId != null && c.directorTeacherId != teacher.id;
                          final otherDirector = hasOtherDirector ? academic.teacherById(c.directorTeacherId!) : null;
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              hasOtherDirector ? '${c.name} (actual: ${otherDirector?.fullName ?? "—"})' : c.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) => setDialogState(() => selectedDirectorCourseId = v),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Si el curso elegido ya tiene director, será reemplazado por este docente.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () {
                  // Quitar la dirección anterior si cambió de curso o se quitó
                  if (currentDirectorCourse.id.isNotEmpty && currentDirectorCourse.id != selectedDirectorCourseId) {
                    academic.setCourseDirector(currentDirectorCourse.id, null);
                  }
                  if (selectedDirectorCourseId != null) {
                    academic.setCourseDirector(selectedDirectorCourseId!, teacher.id);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cambios guardados para ${teacher.fullName}'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _roleColor(UserRole r) {
    switch (r) {
      case UserRole.coordinator: return AppColors.coordinator;
      case UserRole.admin: return AppColors.purple;
      case UserRole.teacher: return AppColors.teacher;
      case UserRole.student: return AppColors.student;
      case UserRole.parent: return AppColors.parent;
    }
  }


  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.coordinator: return 'Coordinador';
      case UserRole.admin: return 'Administrador';
      case UserRole.teacher: return 'Docente';
      case UserRole.student: return 'Estudiante';
      case UserRole.parent: return 'Padre de Familia';
    }
  }
}
