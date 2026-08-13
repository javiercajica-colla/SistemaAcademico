import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';

// Sube la foto de perfil al backend propio (server/, alojado en Railway —
// mismo patrón de autenticación que AdminCredentialsService). No usa
// Firebase Storage: el proyecto se quedó deliberadamente en el plan Spark
// (gratuito) de Firebase (ver comentario en server/server.js), y Storage
// exige el plan Blaze para proyectos creados después de oct/2024.
class AvatarStorageService {
  String _backendOrigin() =>
      Env.apiBaseUrl.isNotEmpty ? Env.apiBaseUrl : Uri.base.origin;

  Future<String> uploadAvatar(String userId, Uint8List bytes) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Debes iniciar sesión.');
    }

    http.Response response;
    try {
      final idToken = await currentUser.getIdToken();
      final uri = Uri.parse(
        _backendOrigin(),
      ).resolve('/api/avatar/$userId');
      response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/octet-stream',
          'Authorization': 'Bearer $idToken',
        },
        body: bytes,
      );
    } catch (_) {
      throw Exception('No se pudo conectar con el servidor. Intenta de nuevo.');
    }

    if (response.statusCode != 200) {
      throw Exception('No se pudo subir la foto (${response.statusCode}).');
    }

    // El nombre de archivo no cambia entre subidas (siempre .../avatars/id),
    // así que sin el parámetro `v` NetworkImage seguiría mostrando la copia
    // cacheada de la foto anterior tras un reemplazo.
    return Uri.parse(_backendOrigin())
        .resolve('/avatars/$userId?v=${DateTime.now().millisecondsSinceEpoch}')
        .toString();
  }
}
