import '../../models/models.dart';
import '../../services/firebase_auth_service.dart';
import '../auth_repository.dart';

/// Implementación real de [AuthRepository]: delega en [FirebaseAuthService]
/// (Firebase Auth + Firestore), sin cambiar su comportamiento. Solo aísla
/// el código de Firebase detrás de la interfaz de repositorio para poder
/// alternarlo con [MockAuthRepository] mediante `useMockData`.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthService _service = FirebaseAuthService();

  @override
  Future<AppUser> signIn(String email, String password) =>
      _service.signIn(email, password);

  @override
  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) => _service.createUser(
    email: email,
    password: password,
    name: name,
    role: role,
  );

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _service.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  @override
  Future<void> signOut() => _service.signOut();

  @override
  Future<AppUser?> reloadCurrentUser() => _service.reloadCurrentUser();
}
