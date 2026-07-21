import 'models.dart';

enum ConversationType { individual, group, institutional }

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final UserRole senderRole;
  final String content;
  final DateTime sentAt;
  final List<String> readBy;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.sentAt,
    List<String>? readBy,
  }) : readBy = List.from(readBy ?? []);

  bool isReadBy(String userId) => senderId == userId || readBy.contains(userId);
}

class Conversation {
  final String id;
  final ConversationType type;
  String title;
  final List<String> participantIds;
  Message? lastMessage;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.type,
    required this.title,
    required this.participantIds,
    this.lastMessage,
    required this.createdAt,
  });

  int unreadCount(String userId, List<Message> allMessages) => allMessages
      .where(
        (m) =>
            m.conversationId == id &&
            m.senderId != userId &&
            !m.isReadBy(userId),
      )
      .length;
}
