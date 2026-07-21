import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/message_models.dart';
import '../data/mock_messages.dart';

class MessageProvider extends ChangeNotifier {
  final List<Conversation> _conversations = MockMessages.conversations;
  final List<Message> _messages = MockMessages.messages;
  final _uuid = const Uuid();

  // ─── Queries ──────────────────────────────────────────────────────────────

  List<Conversation> conversationsForUser(String userId) {
    final convs = _conversations
        .where((c) => c.participantIds.contains(userId))
        .toList();
    for (final c in convs) {
      final msgs = _messages.where((m) => m.conversationId == c.id).toList()
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      c.lastMessage = msgs.isNotEmpty ? msgs.first : null;
    }
    convs.sort((a, b) {
      final at = a.lastMessage?.sentAt ?? a.createdAt;
      final bt = b.lastMessage?.sentAt ?? b.createdAt;
      return bt.compareTo(at);
    });
    return convs;
  }

  List<Message> messagesForConversation(String conversationId) =>
      _messages.where((m) => m.conversationId == conversationId).toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  Conversation? conversationById(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  int unreadCount(String userId) => _messages
      .where(
        (m) =>
            m.senderId != userId &&
            !m.isReadBy(userId) &&
            _conversations.any(
              (c) =>
                  c.id == m.conversationId && c.participantIds.contains(userId),
            ),
      )
      .length;

  // Returns the display title for a conversation from a given user's perspective.
  String conversationTitle(
    Conversation conv,
    String currentUserId,
    List<AppUser> allUsers,
  ) {
    if (conv.type != ConversationType.individual) return conv.title;
    final otherId = conv.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return conv.title;
    try {
      return allUsers.firstWhere((u) => u.id == otherId).name;
    } catch (_) {
      return conv.title;
    }
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void markConversationAsRead(String conversationId, String userId) {
    bool changed = false;
    for (final m in _messages) {
      if (m.conversationId == conversationId &&
          m.senderId != userId &&
          !m.readBy.contains(userId)) {
        m.readBy.add(userId);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required UserRole senderRole,
    required String content,
  }) {
    _messages.add(
      Message(
        id: _uuid.v4(),
        conversationId: conversationId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        sentAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Finds an existing 1-to-1 conversation or creates a new one.
  Conversation openIndividual({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
  }) {
    try {
      return _conversations.firstWhere(
        (c) =>
            c.type == ConversationType.individual &&
            c.participantIds.length == 2 &&
            c.participantIds.contains(currentUserId) &&
            c.participantIds.contains(otherUserId),
      );
    } catch (_) {
      final conv = Conversation(
        id: _uuid.v4(),
        type: ConversationType.individual,
        title: otherUserName,
        participantIds: [currentUserId, otherUserId],
        createdAt: DateTime.now(),
      );
      _conversations.add(conv);
      notifyListeners();
      return conv;
    }
  }

  /// Creates a new group conversation (teacher → course/parents).
  Conversation createGroup({
    required String senderId,
    required String title,
    required List<String> participantIds,
  }) {
    final conv = Conversation(
      id: _uuid.v4(),
      type: ConversationType.group,
      title: title,
      participantIds: participantIds,
      createdAt: DateTime.now(),
    );
    _conversations.add(conv);
    notifyListeners();
    return conv;
  }

  /// Creates an institutional broadcast (coordinator only).
  Conversation createInstitutional({
    required String title,
    required List<String> allUserIds,
  }) {
    final conv = Conversation(
      id: _uuid.v4(),
      type: ConversationType.institutional,
      title: title,
      participantIds: allUserIds,
      createdAt: DateTime.now(),
    );
    _conversations.add(conv);
    notifyListeners();
    return conv;
  }

  // ─── Recipient helpers ────────────────────────────────────────────────────

  /// Returns all AppUsers that [currentUser] is allowed to message individually.
  List<AppUser> availableIndividualRecipients({
    required AppUser currentUser,
    required List<AppUser> allUsers,
    // Pre-computed sets based on academic data (passed from screen)
    Set<String>? allowedUserIds,
  }) {
    if (allowedUserIds != null) {
      return allUsers
          .where((u) => u.id != currentUser.id && allowedUserIds.contains(u.id))
          .toList();
    }
    // Coordinator can message everyone
    return allUsers.where((u) => u.id != currentUser.id).toList();
  }
}
