import '../models/email_models.dart';
import '../models/models.dart';

abstract class EmailService {
  int countUnread(String userId);
  Future<List<InternalEmail>> getInbox(String userId);
  Future<List<InternalEmail>> getSent(String userId);
  Future<List<InternalEmail>> getDrafts(String userId);
  Future<List<InternalEmail>> getTrash(String userId);
  Future<void> sendEmail(InternalEmail email);
  Future<void> saveDraft(InternalEmail draft);
  Future<void> markAsRead(String emailId);
  Future<void> markAsUnread(String emailId);
  Future<void> moveToTrash(String emailId);
  Future<void> restoreFromTrash(String emailId);
  Future<void> permanentlyDelete(String emailId);
  Future<List<AppUser>> getAvailableRecipients(
    String currentUserId,
    List<AppUser> allUsers,
  );
}
