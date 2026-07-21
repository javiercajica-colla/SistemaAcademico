import '../models/models.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

/// Abstracción de autenticación (login, logout, usuario actual, creación de
/// cuentas). Implementada por [FirebaseAuthRepository] (real) y
/// [MockAuthRepository] (datos falsos en memoria) — ver
/// lib/repositories/repository_provider.dart para el mecanismo que elige
/// cuál usar.
abstract class AuthRepository {
  Future<AppUser> signIn(String email, String password);

  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> signOut();

  Future<AppUser?> reloadCurrentUser();
}
