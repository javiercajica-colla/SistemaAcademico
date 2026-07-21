import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/email_models.dart';
import '../models/models.dart';
import '../services/email_service.dart';
import '../services/mock_email_service.dart';

class EmailProvider extends ChangeNotifier {
  final EmailService _service;

  EmailProvider({EmailService? service})
    : _service = service ?? MockEmailService();

  List<InternalEmail> _inbox = [];
  List<InternalEmail> _sent = [];
  List<InternalEmail> _drafts = [];
  List<InternalEmail> _trash = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  List<InternalEmail> get inbox => _inbox;
  List<InternalEmail> get sent => _sent;
  List<InternalEmail> get drafts => _drafts;
  List<InternalEmail> get trash => _trash;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _inbox.where((e) => !e.isRead).length;
  int get draftsCount => _drafts.length;

  int countUnread(String userId) => _service.countUnread(userId);

  List<InternalEmail> getFolder(EmailFolder folder) {
    switch (folder) {
      case EmailFolder.inbox:
        return _inbox;
      case EmailFolder.sent:
        return _sent;
      case EmailFolder.drafts:
        return _drafts;
      case EmailFolder.starred:
        return [..._inbox, ..._sent].where((e) => e.isStarred).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      case EmailFolder.trash:
        return _trash;
    }
  }

  Future<void> init(String userId) async {
    if (_currentUserId == userId && (_inbox.isNotEmpty || _sent.isNotEmpty)) {
      return;
    }
    _currentUserId = userId;
    await _loadAll(userId);
  }

  Future<void> reload() async {
    if (_currentUserId != null) await _loadAll(_currentUserId!);
  }

  Future<void> _loadAll(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getInbox(userId),
        _service.getSent(userId),
        _service.getDrafts(userId),
        _service.getTrash(userId),
      ]);
      _inbox = results[0];
      _sent = results[1];
      _drafts = results[2];
      _trash = results[3];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> enviarCorreo({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String subject,
    required String body,
    String? replyToId,
  }) async {
    const uuid = Uuid();
    final email = InternalEmail(
      id: uuid.v4(),
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      subject: subject,
      body: body,
      timestamp: DateTime.now(),
      isRead: true,
      replyToId: replyToId,
    );
    await _service.sendEmail(email);
    await reload();
  }

  Future<void> marcarComoLeido(String emailId) async {
    await _service.markAsRead(emailId);
    _patchEmail(emailId, (e) => e.isRead = true);
    notifyListeners();
  }

  Future<void> marcarComoNoLeido(String emailId) async {
    await _service.markAsUnread(emailId);
    _patchEmail(emailId, (e) => e.isRead = false);
    notifyListeners();
  }

  Future<void> eliminarCorreo(String emailId) async {
    await _service.moveToTrash(emailId);
    await reload();
  }

  Future<void> restaurarCorreo(String emailId) async {
    await _service.restoreFromTrash(emailId);
    await reload();
  }

  Future<void> eliminarPermanente(String emailId) async {
    await _service.permanentlyDelete(emailId);
    await reload();
  }

  Future<List<AppUser>> getRecipients(String userId, List<AppUser> allUsers) =>
      _service.getAvailableRecipients(userId, allUsers);

  void _patchEmail(String emailId, void Function(InternalEmail) patch) {
    for (final list in [_inbox, _sent, _drafts, _trash]) {
      final idx = list.indexWhere((e) => e.id == emailId);
      if (idx != -1) patch(list[idx]);
    }
  }
}
