import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import '../models/models.dart';
import '../repositories/auth_repository.dart' show AuthException;
import 'firestore_service.dart';

// AuthException vive en lib/repositories/auth_repository.dart (compartida
// con la capa de abstracción de repositorios). Se re-exporta aquí para no
// romper el código existente que la importaba desde este archivo.
export '../repositories/auth_repository.dart' show AuthException;

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirestoreService _store = FirestoreService();

  Future<AppUser> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw AuthException('Error al iniciar sesión');

      final user = await _store.getUser(uid);
      if (user == null) {
        throw AuthException('Usuario no encontrado en el sistema');
      }
      if (!user.isActive) throw AuthException('Cuenta desactivada');
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on AuthException {
      rethrow;
    } on FirebaseException catch (e) {
      throw AuthException('Error de Firestore (${e.code}): ${e.message}');
    } catch (e) {
      throw AuthException('Error inesperado al iniciar sesión: $e');
    }
  }

  // Crea un usuario nuevo SIN cerrar la sesión del usuario actual (p. ej. el
  // coordinador). createUserWithEmailAndPassword inicia sesión automáticamente
  // como el usuario creado en la app por defecto, así que usamos una app
  // secundaria de Firebase exclusivamente para esta operación y la destruimos
  // al terminar.
  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondary-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = fb.FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) throw AuthException('Error al crear usuario');

      final user = AppUser(
        id: uid,
        name: name,
        email: email.trim(),
        password: '',
        role: role,
        isActive: true,
      );
      await _store.saveUser(uid, user);
      await secondaryAuth.signOut();
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    } on AuthException {
      rethrow;
    } finally {
      await secondaryApp.delete();
    }
  }

  // Permite a un usuario YA autenticado cambiar su propia contraseña.
  // Firebase exige una sesión "reciente" para esta operación, así que
  // reautenticamos con la contraseña actual antes de aplicar la nueva.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw AuthException('No hay una sesión activa');
    }
    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> reloadCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _store.getUser(uid);
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email o contraseña incorrectos';
      case 'user-disabled':
        return 'Esta cuenta ha sido desactivada';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta más tarde';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      default:
        return 'Error de autenticación ($code)';
    }
  }
}
