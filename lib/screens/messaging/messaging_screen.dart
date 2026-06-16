import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../models/message_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../providers/academic_provider.dart';
import 'new_message_screen.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _rolePath(UserRole role) {
    switch (role) {
      case UserRole.coordinator:
        return 'coordinator';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.student:
        return 'student';
      case UserRole.parent:
        return 'parent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser!;
    final msgProv = context.watch<MessageProvider>();
    final allUsers = context.read<AcademicProvider>().users;

    final allConvs = msgProv.conversationsForUser(user.id);
    final filtered = _search.isEmpty
        ? allConvs
        : allConvs.where((c) {
            final title =
                msgProv.conversationTitle(c, user.id, allUsers).toLowerCase();
            return title.contains(_search.toLowerCase()) ||
                (c.lastMessage?.content
                        .toLowerCase()
                        .contains(_search.toLowerCase()) ??
                    false);
          }).toList();

    final inbox = filtered;
    final sent = filtered
        .where((c) =>
            c.lastMessage != null && c.lastMessage!.senderId == user.id)
        .toList();

    final roleColor = _roleColor(user.role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context, user, roleColor, msgProv),
          _buildSearch(),
          _buildTabBar(roleColor),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _ConversationList(
                  convs: inbox,
                  currentUserId: user.id,
                  rolePath: _rolePath(user.role),
                  msgProv: msgProv,
                  allUsers: allUsers,
                  emptyLabel: 'No hay mensajes en la bandeja',
                ),
                _ConversationList(
                  convs: sent,
                  currentUserId: user.id,
                  rolePath: _rolePath(user.role),
                  msgProv: msgProv,
                  allUsers: allUsers,
                  emptyLabel: 'No has enviado mensajes aún',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewMessage(context, user),
        backgroundColor: roleColor,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Nuevo mensaje',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppUser user, Color roleColor,
      MessageProvider msgProv) {
    final unread = msgProv.unreadCount(user.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.chat_rounded, color: roleColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mensajería',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text('Comunicación interna',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (unread > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$unread sin leer',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _search = v),
        decoration: InputDecoration(
          hintText: 'Buscar conversaciones...',
          hintStyle:
              const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textSecondary, size: 20),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTabBar(Color roleColor) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabs,
        labelColor: roleColor,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: roleColor,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Bandeja de entrada'),
          Tab(text: 'Enviados'),
        ],
      ),
    );
  }

  void _openNewMessage(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewMessageSheet(
        currentUser: user,
        onConversationCreated: (convId) {
          Navigator.pop(context);
          final role = _rolePath(user.role);
          context.go('/$role/messages/$convId');
        },
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
}

// ─── Conversation list ────────────────────────────────────────────────────

class _ConversationList extends StatelessWidget {
  final List<Conversation> convs;
  final String currentUserId;
  final String rolePath;
  final MessageProvider msgProv;
  final List<AppUser> allUsers;
  final String emptyLabel;

  const _ConversationList({
    required this.convs,
    required this.currentUserId,
    required this.rolePath,
    required this.msgProv,
    required this.allUsers,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (convs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyLabel,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: convs.length,
      separatorBuilder: (_, i) =>
          Divider(height: 1, indent: 72, color: Colors.grey.shade100),
      itemBuilder: (context, i) => _ConversationTile(
        conv: convs[i],
        currentUserId: currentUserId,
        rolePath: rolePath,
        msgProv: msgProv,
        allUsers: allUsers,
      ),
    );
  }
}

// ─── Conversation tile ────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Conversation conv;
  final String currentUserId;
  final String rolePath;
  final MessageProvider msgProv;
  final List<AppUser> allUsers;

  const _ConversationTile({
    required this.conv,
    required this.currentUserId,
    required this.rolePath,
    required this.msgProv,
    required this.allUsers,
  });

  @override
  Widget build(BuildContext context) {
    final title = msgProv.conversationTitle(conv, currentUserId, allUsers);
    final msgs = msgProv.messagesForConversation(conv.id);
    final unread = conv.unreadCount(currentUserId, msgs);
    final last = conv.lastMessage;
    final isMine = last?.senderId == currentUserId;

    return Material(
      color: unread > 0
          ? AppColors.primary.withValues(alpha: 0.03)
          : Colors.white,
      child: InkWell(
        onTap: () => context.go('/$rolePath/messages/${conv.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _avatar(conv, title),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (last != null)
                          Text(
                            _formatTime(last.sentAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: unread > 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (isMine)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.done_all_rounded,
                                size: 14, color: AppColors.primary),
                          ),
                        Expanded(
                          child: Text(
                            last != null
                                ? (isMine ? 'Tú: ${last.content}' : last.content)
                                : 'Sin mensajes',
                            style: TextStyle(
                              fontSize: 12,
                              color: unread > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: unread > 0
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(Conversation conv, String title) {
    IconData icon;
    Color color;
    switch (conv.type) {
      case ConversationType.individual:
        icon = Icons.person_rounded;
        color = AppColors.primary;
        break;
      case ConversationType.group:
        icon = Icons.group_rounded;
        color = AppColors.teacher;
        break;
      case ConversationType.institutional:
        icon = Icons.campaign_rounded;
        color = AppColors.parent;
        break;
    }
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(
            title.isNotEmpty ? title[0].toUpperCase() : '?',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(icon, size: 9, color: Colors.white),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(msgDay).inDays;
    if (diff == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } else if (diff == 1) {
      return 'Ayer';
    } else if (diff < 7) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}
