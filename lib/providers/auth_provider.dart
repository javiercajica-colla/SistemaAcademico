import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

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
