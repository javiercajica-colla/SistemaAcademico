import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/auth_repository.dart';
import '../repositories/repository_provider.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  final Map<String, Uint8List> _avatarMap = {};

  final AuthRepository _authService = authRepository;
  final _store = dataRepository;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.createUser(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    if (_currentUser == null) return;
    _currentUser = AppUser(
      id: _currentUser!.id,
      name: name,
      email: email,
      password: '',
      role: _currentUser!.role,
      avatar: _currentUser!.avatar,
      isActive: _currentUser!.isActive,
    );
    await _store.saveUser(_currentUser!.id, _currentUser!);
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final refreshed = await _authService.reloadCurrentUser();
    if (refreshed != null) {
      _currentUser = refreshed;
      notifyListeners();
    }
  }

  Uint8List? getAvatarBytes(String userId) => _avatarMap[userId];

  void updateAvatar(String userId, Uint8List bytes) {
    _avatarMap[userId] = bytes;
    notifyListeners();
  }

  String get roleDisplayName {
    switch (_currentUser?.role) {
      case UserRole.coordinator:
        return 'Coordinador Académico';
      case UserRole.admin:
        return 'Administrador del Sistema';
      case UserRole.teacher:
        return 'Docente';
      case UserRole.student:
        return 'Estudiante';
      case UserRole.parent:
        return 'Padre de Familia';
      default:
        return '';
    }
  }
}
