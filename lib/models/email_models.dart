enum EmailFolder { inbox, sent, drafts, starred, trash }

class InternalEmail {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String subject;
  final String body;
  final DateTime timestamp;
  bool isRead;
  bool isStarred;
  bool isDeleted;
  bool isDraft;
  final String? replyToId;

  InternalEmail({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.subject,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.isStarred = false,
    this.isDeleted = false,
    this.isDraft = false,
    this.replyToId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'receiverId': receiverId,
    'receiverName': receiverName,
    'subject': subject,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'isStarred': isStarred,
    'isDeleted': isDeleted,
    'isDraft': isDraft,
    'replyToId': replyToId,
  };

  factory InternalEmail.fromMap(Map<String, dynamic> map) => InternalEmail(
    id: map['id'] as String,
    senderId: map['senderId'] as String,
    senderName: map['senderName'] as String,
    receiverId: map['receiverId'] as String,
    receiverName: map['receiverName'] as String,
    subject: map['subject'] as String,
    body: map['body'] as String,
    timestamp: DateTime.parse(map['timestamp'] as String),
    isRead: (map['isRead'] as bool?) ?? false,
    isStarred: (map['isStarred'] as bool?) ?? false,
    isDeleted: (map['isDeleted'] as bool?) ?? false,
    isDraft: (map['isDraft'] as bool?) ?? false,
    replyToId: map['replyToId'] as String?,
  );

  InternalEmail copyWith({
    String? subject,
    String? body,
    String? receiverId,
    String? receiverName,
    bool? isRead,
    bool? isStarred,
    bool? isDeleted,
    bool? isDraft,
  }) => InternalEmail(
    id: id,
    senderId: senderId,
    senderName: senderName,
    receiverId: receiverId ?? this.receiverId,
    receiverName: receiverName ?? this.receiverName,
    subject: subject ?? this.subject,
    body: body ?? this.body,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    isStarred: isStarred ?? this.isStarred,
    isDeleted: isDeleted ?? this.isDeleted,
    isDraft: isDraft ?? this.isDraft,
    replyToId: replyToId,
  );
}
