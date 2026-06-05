import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;
  final Map<String, Uint8List> _avatarMap = {};

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final user = MockData.users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password && u.isActive,
        orElse: () => throw Exception('Credenciales incorrectas'),
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Email o contraseña incorrectos';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Uint8List? getAvatarBytes(String userId) => _avatarMap[userId];

  void updateAvatar(String userId, Uint8List bytes) {
    _avatarMap[userId] = bytes;
    notifyListeners();
  }

  void updateProfile({required String name, required String email}) {
    if (_currentUser == null) return;
    _currentUser = AppUser(
      id: _currentUser!.id,
      name: name,
      email: email,
      password: _currentUser!.password,
      role: _currentUser!.role,
      avatar: _currentUser!.avatar,
      isActive: _currentUser!.isActive,
    );
    notifyListeners();
  }

  String get roleDisplayName {
    switch (_currentUser?.role) {
      case UserRole.coordinator:
        return 'Coordinador Académico';
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
