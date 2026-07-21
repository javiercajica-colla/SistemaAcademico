import 'package:cloud_functions/cloud_functions.dart';

class AdminCredentialsService {
  static final AdminCredentialsService _instance =
      AdminCredentialsService._internal();
  factory AdminCredentialsService() => _instance;
  AdminCredentialsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Llama a la Cloud Function adminResetUserPassword. Firebase nunca permite
  // leer la contraseña original de un usuario, así que esto genera y aplica
  // una contraseña NUEVA en su lugar, devolviéndola una sola vez para que el
  // administrador la copie/imprima.
  Future<String> resetUserPassword(String targetUserId) async {
    try {
      final callable = _functions.httpsCallable('adminResetUserPassword');
      final result = await callable.call<Map<String, dynamic>>({
        'targetUserId': targetUserId,
      });
      return result.data['password'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        e.message ?? 'Error al restablecer la contraseña (${e.code})',
      );
    }
  }
}
