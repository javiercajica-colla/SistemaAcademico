import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/message_provider.dart';
import '../../providers/academic_provider.dart';

// ─── Bottom-sheet para nuevo mensaje ──────────────────────────────────────

class NewMessageSheet extends StatefulWidget {
  final AppUser currentUser;
  final void Function(String conversationId) onConversationCreated;

  const NewMessageSheet({
    super.key,
    required this.currentUser,
    required this.onConversationCreated,
  });

  @override
  State<NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<NewMessageSheet> {
  _MsgType _type = _MsgType.individual;
  AppUser? _selectedRecipient;
  String? _selectedCourseId;
  _GroupTarget _groupTarget = _GroupTarget.students;
  String _title = '';
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final isCoordinator = user.role == UserRole.coordinator || user.role == UserRole.admin;
    final isTeacher = user.role == UserRole.teacher;
    final mq = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
          children: [
            _handle(),
            _header(user),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + mq.viewInsets.bottom),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo de mensaje
                    if (isCoordinator || isTeacher)
                      _typeSelector(isCoordinator, isTeacher),
                    const SizedBox(height: 16),
                    // Selector de destinatario(s)
                    if (_type == _MsgType.individual)
                      _recipientSelector(context)
                    else if (_type == _MsgType.group && isTeacher)
                      _groupSelector(context)
                    else if (_type == _MsgType.institutional && isCoordinator)
                      _institutionalForm(),
                    const SizedBox(height: 16),
                    _label('Mensaje'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bodyCtrl,
                      minLines: 4,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _inputDecoration('Escribe tu mensaje aquí...'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _canSend() && !_sending ? _doSend : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                        label: Text(
                          _sending ? 'Enviando...' : 'Enviar mensaje',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────────────

  Widget _handle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _header(AppUser user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Nuevo mensaje',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _typeSelector(bool isCoordinator, bool isTeacher) {
    final options = <_MsgType, String>{
      _MsgType.individual: 'Individual',
      if (isTeacher || isCoordinator) _MsgType.group: 'Grupal',
      if (isCoordinator) _MsgType.institutional: 'Institucional',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Tipo de mensaje'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.entries.map((e) {
            final sel = _type == e.key;
            return ChoiceChip(
              label: Text(e.value),
              selected: sel,
              onSelected: (_) => setState(() {
                _type = e.key;
                _selectedRecipient = null;
                _selectedCourseId = null;
              }),
              selectedColor: AppColors.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: sel ? AppColors.primary : AppColors.textSecondary,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: sel ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _recipientSelector(BuildContext context) {
    final recipients = _buildRecipients(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Para'),
        const SizedBox(height: 8),
        DropdownButtonFormField<AppUser>(
          value: _selectedRecipient,
          itemHeight: 60,
          hint: const Text('Seleccionar destinatario',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          items: recipients.map((u) {
            return DropdownMenuItem(
              value: u,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        _roleColor(u.role).withValues(alpha: 0.15),
                    child: Text(u.name[0],
                        style: TextStyle(
                            color: _roleColor(u.role),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(u.name,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        Text(_roleLabel(u.role),
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (u) => setState(() => _selectedRecipient = u),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _groupSelector(BuildContext context) {
    final academic = context.read<AcademicProvider>();
    final teacher = _getTeacher(context);
    if (teacher == null) return const SizedBox.shrink();

    // Courses taught by this teacher
    final courseIds = academic.assignments
        .where((a) => a.teacherId == teacher.id)
        .map((a) => a.courseId)
        .toSet()
        .toList();
    final courses =
        academic.courses.where((c) => courseIds.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Curso'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCourseId,
          hint: const Text('Seleccionar curso',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          items: courses
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name,
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _selectedCourseId = v),
          decoration: _dropdownDecoration(),
          isExpanded: true,
        ),
        const SizedBox(height: 12),
        _label('Enviar a'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Estudiantes'),
              selected: _groupTarget == _GroupTarget.students,
              onSelected: (_) =>
                  setState(() => _groupTarget = _GroupTarget.students),
              selectedColor: AppColors.teacher.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: _groupTarget == _GroupTarget.students
                    ? AppColors.teacher
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            ChoiceChip(
              label: const Text('Padres de familia'),
              selected: _groupTarget == _GroupTarget.parents,
              onSelected: (_) =>
                  setState(() => _groupTarget = _GroupTarget.parents),
              selectedColor: AppColors.teacher.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: _groupTarget == _GroupTarget.parents
                    ? AppColors.teacher
                    : AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _institutionalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.parent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppColors.parent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Se enviará a toda la comunidad educativa (solo lectura para los receptores)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _label('Título del comunicado'),
        const SizedBox(height: 6),
        TextField(
          onChanged: (v) => setState(() => _title = v),
          decoration: _inputDecoration('Ej: Cierre de período, Reunión de padres...'),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  InputDecoration _dropdownDecoration() => InputDecoration(
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );

  bool _canSend() {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) return false;
    switch (_type) {
      case _MsgType.individual:
        return _selectedRecipient != null;
      case _MsgType.group:
        return _selectedCourseId != null;
      case _MsgType.institutional:
        return _title.trim().isNotEmpty;
    }
  }

  List<AppUser> _buildRecipients(BuildContext context) {
    final academic = context.read<AcademicProvider>();
    final user = widget.currentUser;
    final allUsers = academic.users;

    switch (user.role) {
      case UserRole.coordinator:
      case UserRole.admin:
        return allUsers.where((u) => u.id != user.id).toList();

      case UserRole.teacher:
        final teacher = _getTeacher(context);
        if (teacher == null) return [];
        final courseIds = academic.assignments
            .where((a) => a.teacherId == teacher.id)
            .map((a) => a.courseId)
            .toSet();
        final studentIds = academic.students
            .where((s) => courseIds.contains(s.courseId))
            .map((s) => s.userId)
            .toSet();
        final parentIds = academic.students
            .where((s) => courseIds.contains(s.courseId))
            .expand((s) => s.parentIds)
            .map((pid) {
          try {
            return academic.parents
                .firstWhere((p) => p.id == pid)
                .userId;
          } catch (_) {
            return '';
          }
        }).where((id) => id.isNotEmpty).toSet();
        final coordinatorIds =
            allUsers.where((u) => u.role == UserRole.coordinator || u.role == UserRole.admin).map((u) => u.id).toSet();
        final teacherIds =
            allUsers.where((u) => u.role == UserRole.teacher && u.id != user.id).map((u) => u.id).toSet();
        final allowed = {...studentIds, ...parentIds, ...coordinatorIds, ...teacherIds};
        return allUsers.where((u) => allowed.contains(u.id)).toList();

      case UserRole.parent:
        final parent = _getParent(context);
        if (parent == null) return [];
        final childCourseIds = academic.students
            .where((s) => parent.studentIds.contains(s.id))
            .map((s) => s.courseId)
            .whereType<String>()
            .toSet();
        final teacherIds = academic.assignments
            .where((a) => childCourseIds.contains(a.courseId))
            .map((a) => a.teacherId)
            .toSet();
        final teacherUserIds = academic.teachers
            .where((t) => teacherIds.contains(t.id))
            .map((t) => t.userId)
            .toSet();
        final coordinatorIds =
            allUsers.where((u) => u.role == UserRole.coordinator || u.role == UserRole.admin).map((u) => u.id).toSet();
        final allowed = {...teacherUserIds, ...coordinatorIds};
        return allUsers.where((u) => allowed.contains(u.id)).toList();

      case UserRole.student:
        final student = _getStudent(context);
        if (student == null) return [];
        final assignmentTeacherIds = student.courseId != null
            ? academic.assignments
                .where((a) => a.courseId == student.courseId)
                .map((a) => a.teacherId)
                .toSet()
            : <String>{};
        final teacherUserIds = academic.teachers
            .where((t) => assignmentTeacherIds.contains(t.id))
            .map((t) => t.userId)
            .toSet();
        final coordinatorIds =
            allUsers.where((u) => u.role == UserRole.coordinator || u.role == UserRole.admin).map((u) => u.id).toSet();
        final allowed = {...teacherUserIds, ...coordinatorIds};
        return allUsers.where((u) => allowed.contains(u.id)).toList();
    }
  }

  Teacher? _getTeacher(BuildContext context) {
    final academic = context.read<AcademicProvider>();
    try {
      return academic.teachers
          .firstWhere((t) => t.userId == widget.currentUser.id);
    } catch (_) {
      return null;
    }
  }

  Parent? _getParent(BuildContext context) {
    final academic = context.read<AcademicProvider>();
    try {
      return academic.parents
          .firstWhere((p) => p.userId == widget.currentUser.id);
    } catch (_) {
      return null;
    }
  }

  Student? _getStudent(BuildContext context) {
    final academic = context.read<AcademicProvider>();
    try {
      return academic.students
          .firstWhere((s) => s.userId == widget.currentUser.id);
    } catch (_) {
      return null;
    }
  }

  void _doSend() async {
    setState(() => _sending = true);
    final msgProv = context.read<MessageProvider>();
    final user = widget.currentUser;
    final body = _bodyCtrl.text.trim();
    final academic = context.read<AcademicProvider>();

    String convId;

    switch (_type) {
      case _MsgType.individual:
        final conv = msgProv.openIndividual(
          currentUserId: user.id,
          otherUserId: _selectedRecipient!.id,
          otherUserName: _selectedRecipient!.name,
        );
        msgProv.sendMessage(
          conversationId: conv.id,
          senderId: user.id,
          senderName: user.name,
          senderRole: user.role,
          content: body,
        );
        convId = conv.id;
        break;

      case _MsgType.group:
        final courseId = _selectedCourseId!;
        List<String> participantIds = [user.id];
        if (_groupTarget == _GroupTarget.students) {
          final studentUserIds = academic.students
              .where((s) => s.courseId == courseId)
              .map((s) => s.userId)
              .toList();
          participantIds.addAll(studentUserIds);
          final course =
              academic.courses.firstWhere((c) => c.id == courseId);
          final conv = msgProv.createGroup(
            senderId: user.id,
            title: 'Grupo ${course.name}',
            participantIds: participantIds,
          );
          msgProv.sendMessage(
            conversationId: conv.id,
            senderId: user.id,
            senderName: user.name,
            senderRole: user.role,
            content: body,
          );
          convId = conv.id;
        } else {
          // parents
          final parentUserIds = academic.students
              .where((s) => s.courseId == courseId)
              .expand((s) => s.parentIds)
              .map((pid) {
            try {
              return academic.parents.firstWhere((p) => p.id == pid).userId;
            } catch (_) {
              return '';
            }
          }).where((id) => id.isNotEmpty).toList();
          participantIds.addAll(parentUserIds);
          final course =
              academic.courses.firstWhere((c) => c.id == courseId);
          final conv = msgProv.createGroup(
            senderId: user.id,
            title: 'Padres de familia ${course.name}',
            participantIds: participantIds,
          );
          msgProv.sendMessage(
            conversationId: conv.id,
            senderId: user.id,
            senderName: user.name,
            senderRole: user.role,
            content: body,
          );
          convId = conv.id;
        }
        break;

      case _MsgType.institutional:
        final allIds = academic.users.map((u) => u.id).toList();
        final conv = msgProv.createInstitutional(
          title: _title.trim(),
          allUserIds: allIds,
        );
        msgProv.sendMessage(
          conversationId: conv.id,
          senderId: user.id,
          senderName: user.name,
          senderRole: user.role,
          content: body,
        );
        convId = conv.id;
        break;
    }

    setState(() => _sending = false);
    widget.onConversationCreated(convId);
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.coordinator:
        return AppColors.coordinator;
      case UserRole.admin:
        return AppColors.purple;
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
        return 'Coordinador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.teacher:
        return 'Docente';
      case UserRole.student:
        return 'Estudiante';
      case UserRole.parent:
        return 'Padre/Madre';
    }
  }
}

enum _MsgType { individual, group, institutional }

enum _GroupTarget { students, parents }
