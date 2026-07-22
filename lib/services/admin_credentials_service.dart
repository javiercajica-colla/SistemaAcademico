import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';

class AdminCredentialsService {
  static final AdminCredentialsService _instance =
      AdminCredentialsService._internal();
  factory AdminCredentialsService() => _instance;
  AdminCredentialsService._internal();

  Uri _resetPasswordEndpoint() {
    final base = Env.apiBaseUrl.isNotEmpty ? Env.apiBaseUrl : Uri.base.origin;
    return Uri.parse(base).resolve('/api/admin/reset-password');
  }

  // Llama al backend propio (server/, alojado junto al frontend en Railway).
  // Firebase nunca permite leer la contraseña original de un usuario, así
  // que esto genera y aplica una contraseña NUEVA en su lugar, devolviéndola
  // una sola vez para que el administrador la copie/imprima.
  Future<String> resetUserPassword(String targetUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Debes iniciar sesión.');
    }

    http.Response response;
    try {
      final idToken = await currentUser.getIdToken();
      response = await http.post(
        _resetPasswordEndpoint(),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'targetUserId': targetUserId.trim()}),
      );
    } catch (_) {
      throw Exception('No se pudo conectar con el servidor. Intenta de nuevo.');
    }

    Map<String, dynamic> body;
    try {
      body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = <String, dynamic>{};
    }

    if (response.statusCode != 200) {
      final message = body['error'];
      throw Exception(
        message is String && message.isNotEmpty
            ? message
            : 'Error al restablecer la contraseña (${response.statusCode}).',
      );
    }

    final password = body['password'];
    if (password is! String || password.isEmpty) {
      throw Exception('No se recibió una contraseña válida del servidor.');
    }

    return password;
  }
}
