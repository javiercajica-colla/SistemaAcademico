import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/email_models.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/academic_provider.dart';
import '../../providers/email_provider.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  EmailFolder _folder = EmailFolder.inbox;
  InternalEmail? _selectedEmail;
  final Set<String> _selectedIds = {};
  bool _showUnreadOnly = false;
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) context.read<EmailProvider>().init(user.id);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final emailProv = context.watch<EmailProvider>();
    final user = auth.currentUser!;

    var emails = emailProv.getFolder(_folder);
    if (_showUnreadOnly) emails = emails.where((e) => !e.isRead).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      emails = emails
          .where((e) =>
              e.senderName.toLowerCase().contains(q) ||
              e.receiverName.toLowerCase().contains(q) ||
              e.subject.toLowerCase().contains(q) ||
              e.body.toLowerCase().contains(q))
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          _FolderPanel(
            folder: _folder,
            unreadCount: emailProv.unreadCount,
            draftsCount: emailProv.draftsCount,
            showSearch: _showSearch,
            onFolderChanged: (f) => setState(() {
              _folder = f;
              _selectedEmail = null;
              _selectedIds.clear();
            }),
            onToggleSearch: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            }),
            onCompose: () => _openCompose(context, emailProv, user, null),
          ),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: _selectedEmail != null
                ? _EmailDetailPane(
                    key: ValueKey(_selectedEmail!.id),
                    email: _selectedEmail!,
                    folder: _folder,
                    onBack: () => setState(() => _selectedEmail = null),
                    onReply: (email) =>
                        _openCompose(context, emailProv, user, email),
                    onDelete: (email) async {
                      if (_folder == EmailFolder.trash) {
                        await emailProv.eliminarPermanente(email.id);
                      } else {
                        await emailProv.eliminarCorreo(email.id);
                      }
                      setState(() => _selectedEmail = null);
                    },
                    onRestore: (email) async {
                      await emailProv.restaurarCorreo(email.id);
                      setState(() => _selectedEmail = null);
                    },
                    onToggleRead: (email) async {
                      if (email.isRead) {
                        await emailProv.marcarComoNoLeido(email.id);
                      } else {
                        await emailProv.marcarComoLeido(email.id);
                      }
                      setState(() {});
                    },
                    onToggleStar: (email) =>
                        setState(() => email.isStarred = !email.isStarred),
                  )
                : _EmailListPane(
                    emails: emails,
                    folder: _folder,
                    selectedIds: _selectedIds,
                    showUnreadOnly: _showUnreadOnly,
                    searchCtrl: _searchCtrl,
                    showSearch: _showSearch,
                    isLoading: emailProv.isLoading,
                    onSelectAll: (all) => setState(() {
                      if (all) {
                        _selectedIds.addAll(emails.map((e) => e.id));
                      } else {
                        _selectedIds.clear();
                      }
                    }),
                    onToggleSelect: (id) => setState(() {
                      if (_selectedIds.contains(id)) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    }),
                    onTapEmail: (email) async {
                      if (!email.isRead) {
                        await emailProv.marcarComoLeido(email.id);
                      }
                      setState(() => _selectedEmail = email);
                    },
                    onToggleUnread: (v) =>
                        setState(() => _showUnreadOnly = v),
                    onSearchChanged: (v) =>
                        setState(() => _searchQuery = v),
                    onBulkDelete: () => _bulkAction(emailProv, 'delete'),
                    onBulkRead: () => _bulkAction(emailProv, 'read'),
                    onBulkUnread: () => _bulkAction(emailProv, 'unread'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkAction(EmailProvider emailProv, String action) async {
    final ids = Set<String>.from(_selectedIds);
    for (final id in ids) {
      switch (action) {
        case 'delete':
          await emailProv.eliminarCorreo(id);
        case 'read':
          await emailProv.marcarComoLeido(id);
        case 'unread':
          await emailProv.marcarComoNoLeido(id);
      }
    }
    setState(() => _selectedIds.clear());
  }

  void _openCompose(
    BuildContext context,
    EmailProvider emailProv,
    AppUser user,
    InternalEmail? replyTo,
  ) {
    final academic = context.read<AcademicProvider>();
    final messenger = ScaffoldMessenger.of(context);

    // Acudientes solo pueden escribir a docentes y coordinadores
    final availableRecipients = user.role == UserRole.parent
        ? academic.users
            .where((u) =>
                u.role == UserRole.teacher ||
                u.role == UserRole.coordinator ||
                u.role == UserRole.admin)
            .toList()
        : academic.users;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ComposeDialog(
        currentUser: user,
        replyTo: replyTo,
        allUsers: availableRecipients,
        onSend: (to, subject, body) async {
          await emailProv.enviarCorreo(
            senderId: user.id,
            senderName: user.name,
            receiverId: to.id,
            receiverName: to.name,
            subject: subject,
            body: body,
            replyToId: replyTo?.id,
          );
          if (ctx.mounted) Navigator.of(ctx).pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Correo enviado exitosamente'),
              backgroundColor: AppColors.secondary,
            ),
          );
        },
      ),
    );
  }
}

// ─── Folder navigation panel ──────────────────────────────────────────────────

class _FolderPanel extends StatelessWidget {
  final EmailFolder folder;
  final int unreadCount;
  final int draftsCount;
  final bool showSearch;
  final ValueChanged<EmailFolder> onFolderChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onCompose;

  const _FolderPanel({
    required this.folder,
    required this.unreadCount,
    required this.draftsCount,
    required this.showSearch,
    required this.onFolderChanged,
    required this.onToggleSearch,
    required this.onCompose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: const Color(0xFFF4F6F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'MENSAJERÍA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 1.4,
              ),
            ),
          ),
          // Search
          _FolderTile(
            icon: Icons.search_rounded,
            label: 'Buscar',
            isActive: showSearch,
            onTap: onToggleSearch,
          ),
          // Compose
          _FolderTile(
            icon: Icons.edit_rounded,
            label: 'Escribir Mensaje',
            onTap: onCompose,
          ),
          const SizedBox(height: 4),
          Divider(height: 1, thickness: 1, color: AppColors.border, indent: 12, endIndent: 12),
          const SizedBox(height: 4),
          // Inbox
          _FolderTile(
            icon: Icons.inbox_rounded,
            label: 'Bandeja de Entrada',
            isActive: folder == EmailFolder.inbox,
            badge: unreadCount,
            onTap: () => onFolderChanged(EmailFolder.inbox),
          ),
          // Sent
          _FolderTile(
            icon: Icons.send_rounded,
            label: 'Mensajes Enviados',
            isActive: folder == EmailFolder.sent,
            onTap: () => onFolderChanged(EmailFolder.sent),
          ),
          // Drafts
          _FolderTile(
            icon: Icons.description_outlined,
            label: 'Borradores',
            isActive: folder == EmailFolder.drafts,
            badge: draftsCount,
            onTap: () => onFolderChanged(EmailFolder.drafts),
          ),
          // Starred
          _FolderTile(
            icon: Icons.star_border_rounded,
            label: 'Destacados',
            isActive: folder == EmailFolder.starred,
            onTap: () => onFolderChanged(EmailFolder.starred),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, thickness: 1, color: AppColors.border, indent: 12, endIndent: 12),
          const SizedBox(height: 4),
          // Trash
          _FolderTile(
            icon: Icons.delete_outline_rounded,
            label: 'Papelera',
            isActive: folder == EmailFolder.trash,
            onTap: () => onFolderChanged(EmailFolder.trash),
          ),
        ],
      ),
    );
  }
}

class _FolderTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badge;
  final VoidCallback? onTap;

  const _FolderTile({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.badge = 0,
    this.onTap,
  });

  @override
  State<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<_FolderTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.1)
                : _hovered
                    ? AppColors.border
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: active ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.badge > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Email list pane ──────────────────────────────────────────────────────────

class _EmailListPane extends StatelessWidget {
  final List<InternalEmail> emails;
  final EmailFolder folder;
  final Set<String> selectedIds;
  final bool showUnreadOnly;
  final bool showSearch;
  final bool isLoading;
  final TextEditingController searchCtrl;
  final ValueChanged<bool> onSelectAll;
  final ValueChanged<String> onToggleSelect;
  final ValueChanged<InternalEmail> onTapEmail;
  final ValueChanged<bool> onToggleUnread;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBulkDelete;
  final VoidCallback onBulkRead;
  final VoidCallback onBulkUnread;

  const _EmailListPane({
    required this.emails,
    required this.folder,
    required this.selectedIds,
    required this.showUnreadOnly,
    required this.showSearch,
    required this.isLoading,
    required this.searchCtrl,
    required this.onSelectAll,
    required this.onToggleSelect,
    required this.onTapEmail,
    required this.onToggleUnread,
    required this.onSearchChanged,
    required this.onBulkDelete,
    required this.onBulkRead,
    required this.onBulkUnread,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIds.isNotEmpty;
    final allSelected =
        emails.isNotEmpty && selectedIds.length == emails.length;

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _ToolbarBtn(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Eliminar seleccionados',
                enabled: hasSelection,
                onTap: onBulkDelete,
              ),
              const SizedBox(width: 4),
              _ToolbarBtn(
                icon: Icons.folder_outlined,
                tooltip: 'Archivar',
                enabled: hasSelection,
                onTap: () {},
              ),
              const SizedBox(width: 4),
              _ToolbarBtn(
                icon: Icons.check_circle_outline_rounded,
                tooltip: 'Marcar como leído',
                enabled: hasSelection,
                onTap: onBulkRead,
              ),
              const SizedBox(width: 4),
              _ToolbarBtn(
                icon: Icons.mail_outline_rounded,
                tooltip: 'Marcar como no leído',
                enabled: hasSelection,
                onTap: onBulkUnread,
              ),
              const Spacer(),
              Text(
                'No leídos',
                style: TextStyle(
                  fontSize: 13,
                  color: showUnreadOnly
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: showUnreadOnly
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: showUnreadOnly,
                onChanged: onToggleUnread,
                activeThumbColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
        // Search bar (expandable)
        if (showSearch)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            color: AppColors.surface,
            child: TextField(
              controller: searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar en correos...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: onSearchChanged,
            ),
          ),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surfaceVariant,
            border: Border(
              top: BorderSide(color: AppColors.border),
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Checkbox(
                  value: allSelected
                      ? true
                      : selectedIds.isNotEmpty
                          ? null
                          : false,
                  tristate: true,
                  onChanged: (v) => onSelectAll(v == true),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                flex: 3,
                child: Text(
                  'De',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Expanded(
                flex: 5,
                child: Text(
                  'Asunto',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(
                width: 72,
                child: Text(
                  'Fecha',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : emails.isEmpty
                  ? _EmptyState(folder: folder, filtered: showUnreadOnly)
                  : ListView.separated(
                      itemCount: emails.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, thickness: 1),
                      itemBuilder: (context, i) => _EmailRow(
                        email: emails[i],
                        folder: folder,
                        isSelected: selectedIds.contains(emails[i].id),
                        onToggleSelect: onToggleSelect,
                        onTap: () => onTapEmail(emails[i]),
                      ),
                    ),
        ),
      ],
    );
  }
}

class _EmailRow extends StatefulWidget {
  final InternalEmail email;
  final EmailFolder folder;
  final bool isSelected;
  final ValueChanged<String> onToggleSelect;
  final VoidCallback onTap;

  const _EmailRow({
    required this.email,
    required this.folder,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onTap,
  });

  @override
  State<_EmailRow> createState() => _EmailRowState();
}

class _EmailRowState extends State<_EmailRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    final unread = !email.isRead;
    final isSentFolder = widget.folder == EmailFolder.sent ||
        widget.folder == EmailFolder.drafts;

    final bgColor = widget.isSelected
        ? AppColors.primary.withValues(alpha: 0.08)
        : _hovered
            ? AppColors.surfaceVariant
            : unread
                ? const Color(0xFFF0F4FF)
                : AppColors.surface;

    final nameLabel =
        isSentFolder ? 'Para: ${email.receiverName}' : email.senderName;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: bgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Unread indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: unread ? AppColors.primary : Colors.transparent,
                ),
              ),
              // Checkbox
              SizedBox(
                width: 22,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: (_) => widget.onToggleSelect(email.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              // From/To
              Expanded(
                flex: 3,
                child: Text(
                  nameLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        unread ? FontWeight.w700 : FontWeight.w400,
                    color: unread
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              // Subject
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Icon(
                      Icons.mail_outline_rounded,
                      size: 13,
                      color: unread
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              unread ? FontWeight.w600 : FontWeight.w400,
                          color: unread
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (email.isStarred) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 13, color: AppColors.warning),
                    ],
                  ],
                ),
              ),
              // Date
              SizedBox(
                width: 72,
                child: Text(
                  _shortDate(email.timestamp),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: unread
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight:
                        unread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      final h = dt.hour == 0
          ? 12
          : dt.hour > 12
              ? dt.hour - 12
              : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? "pm" : "am"}';
    }
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    if (dt.year == now.year) return '${months[dt.month - 1]} ${dt.day}';
    return '${dt.day}/${dt.month}/${dt.year.toString().substring(2)}';
  }
}

// ─── Email detail pane ────────────────────────────────────────────────────────

class _EmailDetailPane extends StatelessWidget {
  final InternalEmail email;
  final EmailFolder folder;
  final VoidCallback onBack;
  final ValueChanged<InternalEmail> onReply;
  final ValueChanged<InternalEmail> onDelete;
  final ValueChanged<InternalEmail> onRestore;
  final ValueChanged<InternalEmail> onToggleRead;
  final ValueChanged<InternalEmail> onToggleStar;

  const _EmailDetailPane({
    super.key,
    required this.email,
    required this.folder,
    required this.onBack,
    required this.onReply,
    required this.onDelete,
    required this.onRestore,
    required this.onToggleRead,
    required this.onToggleStar,
  });

  @override
  Widget build(BuildContext context) {
    final isInbox = folder == EmailFolder.inbox;
    final isTrash = folder == EmailFolder.trash;

    return Column(
      children: [
        // Detail toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                tooltip: 'Volver a la lista',
                onPressed: onBack,
                style: IconButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
              if (isInbox)
                _ToolbarBtn(
                  icon: Icons.reply_rounded,
                  tooltip: 'Responder',
                  enabled: true,
                  onTap: () => onReply(email),
                ),
              if (isInbox) const SizedBox(width: 4),
              _ToolbarBtn(
                icon: isTrash
                    ? Icons.delete_forever_outlined
                    : Icons.delete_outline_rounded,
                tooltip: isTrash ? 'Eliminar permanentemente' : 'Mover a papelera',
                enabled: true,
                onTap: () => onDelete(email),
              ),
              if (isTrash) ...[
                const SizedBox(width: 4),
                _ToolbarBtn(
                  icon: Icons.restore_from_trash_rounded,
                  tooltip: 'Restaurar de papelera',
                  enabled: true,
                  onTap: () => onRestore(email),
                ),
              ],
              if (isInbox) ...[
                const SizedBox(width: 4),
                _ToolbarBtn(
                  icon: email.isRead
                      ? Icons.mail_outline_rounded
                      : Icons.drafts_rounded,
                  tooltip: email.isRead
                      ? 'Marcar como no leído'
                      : 'Marcar como leído',
                  enabled: true,
                  onTap: () => onToggleRead(email),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: Icon(
                  email.isStarred
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color:
                      email.isStarred ? AppColors.warning : AppColors.textTertiary,
                  size: 20,
                ),
                tooltip: email.isStarred ? 'Quitar destacado' : 'Destacar',
                onPressed: () => onToggleStar(email),
              ),
            ],
          ),
        ),
        // Email content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject
                Text(
                  email.subject,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                // Metadata card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _MetaRow(label: 'De:', value: email.senderName),
                      const SizedBox(height: 6),
                      _MetaRow(label: 'Para:', value: email.receiverName),
                      const SizedBox(height: 6),
                      _MetaRow(
                        label: 'Fecha:',
                        value: _fullDate(email.timestamp),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),
                // Body
                SelectableText(
                  email.body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.75,
                  ),
                ),
                const SizedBox(height: 32),
                // Reply button
                if (isInbox)
                  OutlinedButton.icon(
                    onPressed: () => onReply(email),
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: const Text('Responder'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fullDate(DateTime dt) {
    const days = [
      'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo'
    ];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final day = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    final h = dt.hour == 0 ? 12 : dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'p.m.' : 'a.m.';
    return '$day ${dt.day} de $month de ${dt.year}, $h:$m $period';
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final EmailFolder folder;
  final bool filtered;
  const _EmptyState({required this.folder, required this.filtered});

  @override
  Widget build(BuildContext context) {
    final (label, icon) = filtered
        ? ('No hay correos no leídos', Icons.drafts_rounded)
        : switch (folder) {
            EmailFolder.inbox => (
                'Bandeja de entrada vacía',
                Icons.inbox_rounded
              ),
            EmailFolder.sent => ('No has enviado correos', Icons.send_rounded),
            EmailFolder.drafts => (
                'No tienes borradores',
                Icons.description_outlined
              ),
            EmailFolder.starred => (
                'No tienes correos destacados',
                Icons.star_border_rounded
              ),
            EmailFolder.trash => ('La papelera está vacía', Icons.delete_outline_rounded),
          };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: AppColors.textTertiary),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Shared toolbar button ────────────────────────────────────────────────────

class _ToolbarBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ToolbarBtn> createState() => _ToolbarBtnState();
}

class _ToolbarBtnState extends State<_ToolbarBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? AppColors.surfaceVariant
                  : const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: widget.enabled
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Compose dialog ───────────────────────────────────────────────────────────

class _ComposeDialog extends StatefulWidget {
  final AppUser currentUser;
  final InternalEmail? replyTo;
  final List<AppUser> allUsers;
  final Future<void> Function(AppUser to, String subject, String body) onSend;

  const _ComposeDialog({
    required this.currentUser,
    required this.replyTo,
    required this.allUsers,
    required this.onSend,
  });

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  AppUser? _recipient;
  bool _sending = false;

  late final List<AppUser> _recipients;

  @override
  void initState() {
    super.initState();
    _recipients = widget.allUsers
        .where((u) => u.id != widget.currentUser.id)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (widget.replyTo != null) {
      final rt = widget.replyTo!;
      _subjectCtrl.text = rt.subject.startsWith('Re:')
          ? rt.subject
          : 'Re: ${rt.subject}';
      _bodyCtrl.text =
          '\n\n────────────────\nDe: ${rt.senderName}\nFecha: ${_dateStr(rt.timestamp)}\nAsunto: ${rt.subject}\n\n${rt.body}';
      try {
        _recipient = _recipients.firstWhere((u) => u.id == rt.senderId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReply = widget.replyTo != null;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isReply ? Icons.reply_rounded : Icons.edit_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isReply ? 'Responder mensaje' : 'Nuevo Mensaje',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recipient dropdown
                      DropdownButtonFormField<AppUser>(
                        initialValue: _recipient,
                        decoration: const InputDecoration(
                          labelText: 'Para',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              size: 18),
                        ),
                        items: _recipients
                            .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    '${u.name} — ${_roleLabel(u.role)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ))
                            .toList(),
                        onChanged: (u) => setState(() => _recipient = u),
                        validator: (v) =>
                            v == null ? 'Selecciona un destinatario' : null,
                      ),
                      const SizedBox(height: 12),
                      // Subject
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Asunto',
                          prefixIcon:
                              Icon(Icons.subject_rounded, size: 18),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'El asunto no puede estar vacío'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      // Body
                      TextFormField(
                        controller: _bodyCtrl,
                        maxLines: 10,
                        minLines: 8,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Mensaje',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 130),
                            child: Icon(Icons.notes_rounded, size: 18),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'El mensaje no puede estar vacío'
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
                    label: Text(_sending ? 'Enviando...' : 'Enviar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_recipient == null) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(
        _recipient!,
        _subjectCtrl.text.trim(),
        _bodyCtrl.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.coordinator => 'Coordinador',
        UserRole.admin => 'Administrador',
        UserRole.teacher => 'Docente',
        UserRole.student => 'Estudiante',
        UserRole.parent => 'Padre/Madre',
      };

  String _dateStr(DateTime dt) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month - 1]}. ${dt.year}';
  }
}
