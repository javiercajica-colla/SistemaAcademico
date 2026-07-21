import '../../models/models.dart';
import '../auth_repository.dart';
import 'mock_backend.dart';

/// Implementación de [AuthRepository] con datos falsos en memoria — no
/// depende de Firebase. Valida contra las credenciales sembradas en
/// mock_seed_data.dart y simula latencia de red con Future.delayed.
class MockAuthRepository implements AuthRepository {
  final _backend = MockBackend.instance;

  @override
  Future<AppUser> signIn(String email, String password) async {
    await MockBackend.delay(500);
    final normalized = email.trim().toLowerCase();
    final expected = _backend.credentials[normalized];
    if (expected == null || expected != password) {
      throw AuthException('Email o contraseña incorrectos');
    }
    final user = _backend.users.value.firstWhere(
      (u) => u.email.toLowerCase() == normalized,
      orElse: () => throw AuthException('Usuario no encontrado en el sistema'),
    );
    if (!user.isActive) throw AuthException('Cuenta desactivada');
    _backend.currentUser = user;
    return user;
  }

  @override
  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    await MockBackend.delay(400);
    final normalized = email.trim().toLowerCase();
    if (_backend.credentials.containsKey(normalized)) {
      throw AuthException('Este correo ya está registrado');
    }
    final user = AppUser(
      id: 'mock_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      email: email.trim(),
      password: '',
      role: role,
      isActive: true,
    );
    _backend.credentials[normalized] = password;
    _backend.users.add(user);
    return user;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await MockBackend.delay(300);
    final user = _backend.currentUser;
    if (user == null) throw AuthException('No hay una sesión activa');
    final normalized = user.email.toLowerCase();
    if (_backend.credentials[normalized] != currentPassword) {
      throw AuthException('Email o contraseña incorrectos');
    }
    _backend.credentials[normalized] = newPassword;
  }

  @override
  Future<void> signOut() async {
    await MockBackend.delay(150);
    _backend.currentUser = null;
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    await MockBackend.delay(150);
    final current = _backend.currentUser;
    if (current == null) return null;
    return _backend.users.value.firstWhere(
      (u) => u.id == current.id,
      orElse: () => current,
    );
  }
}
