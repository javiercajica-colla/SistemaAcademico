import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Registro temporal (solo en este navegador) de las credenciales generadas
// al crear usuarios nuevos. Las contraseñas NUNCA se guardan en Firestore —
// solo existen aquí, de forma local, hasta que el coordinador las exporta y
// limpia el registro manualmente.
class CredentialLogEntry {
  final String firstName;
  final String lastName;
  final String documentId;
  final String username;
  final String password;
  final String roleLabel;
  final DateTime createdAt;

  CredentialLogEntry({
    required this.firstName,
    required this.lastName,
    required this.documentId,
    required this.username,
    required this.password,
    required this.roleLabel,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'documentId': documentId,
        'username': username,
        'password': password,
        'roleLabel': roleLabel,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CredentialLogEntry.fromJson(Map<String, dynamic> json) => CredentialLogEntry(
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        documentId: json['documentId'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        roleLabel: json['roleLabel'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class CredentialLogService {
  static const _key = 'credential_log_v1';

  Future<List<CredentialLogEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CredentialLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(CredentialLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getAll();
    current.add(entry);
    await prefs.setString(
      _key,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
