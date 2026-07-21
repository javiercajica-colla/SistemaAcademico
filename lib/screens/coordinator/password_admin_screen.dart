import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/download_helper.dart';
import '../../models/models.dart';
import '../../providers/academic_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_credentials_service.dart';
import '../../services/credential_log_service.dart';

class _RosterEntry {
  final AppUser user;
  final String firstName;
  final String lastName;
  final String documentId;
  final String courseName;
  final String username;
  final String roleLabel;
  String? password;

  _RosterEntry({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.documentId,
    required this.courseName,
    required this.username,
    required this.roleLabel,
    this.password,
  });
}

class PasswordAdminScreen extends StatefulWidget {
  const PasswordAdminScreen({super.key});

  @override
  State<PasswordAdminScreen> createState() => _PasswordAdminScreenState();
}

class _PasswordAdminScreenState extends State<PasswordAdminScreen> {
  String _search = '';
  Map<String, String> _passwordsByUsername = {};
  bool _loadingLog = true;
  final Set<String> _resetting = {};

  @override
  void initState() {
    super.initState();
    _loadCredentialLog();
  }

  Future<void> _loadCredentialLog() async {
    final entries = await CredentialLogService().getAll();
    if (!mounted) return;
    setState(() {
      _passwordsByUsername = {
        for (final e in entries) e.username.toLowerCase(): e.password,
      };
      _loadingLog = false;
    });
  }

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.coordinator:
        return 'Coordinador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.teacher:
        return 'Docente';
      case UserRole.student:
        return 'Estudiante';
      case UserRole.parent:
        return 'Padre de Familia';
    }
  }

  List<_RosterEntry> _buildRoster(AcademicProvider academic) {
    return academic.users.map((u) {
      final username = u.email.split('@').first;
      final nameParts = u.name.trim().split(' ');
      var firstName = nameParts.isNotEmpty ? nameParts.first : u.name;
      var lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      var documentId = '-';
      var courseName = '-';

      switch (u.role) {
        case UserRole.teacher:
          final t = academic.teacherByUserId(u.id);
          if (t != null) {
            firstName = t.firstName;
            lastName = t.lastName;
            documentId = t.documentId;
          }
        case UserRole.student:
          final s = academic.studentByUserId(u.id);
          if (s != null) {
            firstName = s.firstName;
            lastName = s.lastName;
            documentId = s.documentId;
            courseName = s.courseId == null
                ? 'Sin curso'
                : (academic.courseById(s.courseId!)?.name ?? 'Sin curso');
          }
        case UserRole.parent:
          final p = academic.parentByUserId(u.id);
          if (p != null) {
            firstName = p.firstName;
            lastName = p.lastName;
            documentId = p.documentId;
          }
        case UserRole.coordinator:
        case UserRole.admin:
          break;
      }

      return _RosterEntry(
        user: u,
        firstName: firstName,
        lastName: lastName,
        documentId: documentId,
        courseName: courseName,
        username: username,
        roleLabel: _roleLabel(u.role),
        password: _passwordsByUsername[username.toLowerCase()],
      );
    }).toList();
  }

  Future<void> _resetPassword(_RosterEntry entry) async {
    setState(() => _resetting.add(entry.user.id));
    try {
      final newPassword = await AdminCredentialsService().resetUserPassword(
        entry.user.id,
      );
      await CredentialLogService().add(
        CredentialLogEntry(
          firstName: entry.firstName,
          lastName: entry.lastName,
          documentId: entry.documentId,
          username: entry.username,
          password: newPassword,
          roleLabel: entry.roleLabel,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _passwordsByUsername[entry.username.toLowerCase()] = newPassword;
        _resetting.remove(entry.user.id);
      });
      _showResetSuccessDialog(entry, newPassword);
    } catch (e) {
      if (!mounted) return;
      setState(() => _resetting.remove(entry.user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showResetSuccessDialog(_RosterEntry entry, String newPassword) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('Contraseña restablecida'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry.firstName} ${entry.lastName} (${entry.roleLabel})'),
              const SizedBox(height: 12),
              _credentialRow('Usuario', entry.username),
              const SizedBox(height: 6),
              _credentialRow('Contraseña nueva', newPassword),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'La contraseña anterior dejó de funcionar. Comparte esta nueva con el usuario.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar'),
            onPressed: () {
              Clipboard.setData(
                ClipboardData(
                  text: 'Usuario: ${entry.username}\nContraseña: $newPassword',
                ),
              );
              Navigator.pop(ctx);
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _credentialRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _exportRoster(List<_RosterEntry> roster) {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Usuarios');
    final sheet = excel['Usuarios'];

    final headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
    );
    const headers = [
      'Rol',
      'Nombre',
      'Apellido',
      'Documento',
      'Curso',
      'Username',
      'Password',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidth(c, 18);
    }

    for (var r = 0; r < roster.length; r++) {
      final e = roster[r];
      final values = [
        e.roleLabel,
        e.firstName,
        e.lastName,
        e.documentId,
        e.courseName,
        e.username,
        e.password ?? 'No disponible',
      ];
      for (var c = 0; c < values.length; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1))
            .value = TextCellValue(
          values[c],
        );
      }
    }

    final bytes = excel.encode();
    if (bytes != null) {
      downloadBytes(
        bytes,
        'usuarios_credenciales_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final academic = context.watch<AcademicProvider>();
    final role = auth.currentUser?.role;

    if (role != UserRole.admin && role != UserRole.coordinator) {
      return const Center(child: Text('Acceso restringido a Administradores.'));
    }

    if (_loadingLog) {
      return const Center(child: CircularProgressIndicator());
    }

    final roster = _buildRoster(academic)
        .where(
          (e) => '${e.firstName} ${e.lastName} ${e.username}'
              .toLowerCase()
              .contains(_search),
        )
        .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre o usuario...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.grid_on_rounded, size: 18),
                label: const Text('Exportar Excel'),
                onPressed: () => _exportRoster(roster),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: AppColors.border),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(2.2),
                  2: FlexColumnWidth(1.4),
                  3: FlexColumnWidth(1.4),
                  4: FlexColumnWidth(1.6),
                  5: FlexColumnWidth(1.6),
                  6: FixedColumnWidth(140),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                    ),
                    children:
                        [
                              'Rol',
                              'Nombre',
                              'Documento',
                              'Curso',
                              'Usuario',
                              'Contraseña',
                              '',
                            ]
                            .map(
                              (c) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Text(
                                  c,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  ...roster.map((e) {
                    final isResetting = _resetting.contains(e.user.id);
                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            e.roleLabel,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            '${e.firstName} ${e.lastName}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            e.documentId,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            e.courseName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            e.username,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            e.password ?? 'No disponible',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: e.password == null
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontStyle: e.password == null
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: isResetting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : TextButton.icon(
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Restablecer',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => _resetPassword(e),
                                ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
