import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/credential_export.dart';
import '../core/utils/download_helper.dart';
import '../models/models.dart';
import '../providers/academic_provider.dart';
import '../services/bulk_user_import_service.dart';
import '../services/credential_log_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/user_credential_generator.dart';

enum _Stage { idle, preview, processing, done }

class BulkImportDialog extends StatefulWidget {
  const BulkImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BulkImportDialog(),
    );
  }

  @override
  State<BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends State<BulkImportDialog> {
  _Stage _stage = _Stage.idle;
  String? _fileName;
  String? _pickError;
  List<ParsedUserRow> _rows = [];
  final List<String> _log = [];
  String _status = '';
  final List<CredentialLogEntry> _createdEntries = [];
  final List<(ParsedUserRow, String)> _failedRows = [];

  void _downloadTemplate() {
    final bytes = BulkUserImportService.generateTemplateXlsxBytes();
    downloadBytes(bytes, 'plantilla_importacion_usuarios.xlsx');
  }

  Future<void> _pickFile() async {
    setState(() => _pickError = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) return;

    try {
      final ext = (file!.extension ?? '').toLowerCase();
      final rows = ext == 'csv'
          ? BulkUserImportService.parseCsvBytes(file.bytes!)
          : BulkUserImportService.parseExcelBytes(file.bytes!);
      if (rows.isEmpty) {
        setState(() => _pickError = 'El archivo no contiene filas de datos.');
        return;
      }
      setState(() {
        _fileName = file.name;
        _rows = rows;
        _stage = _Stage.preview;
      });
    } catch (e) {
      setState(() => _pickError = 'No se pudo leer el archivo: $e');
    }
  }

  Future<void> _processImport() async {
    final academic = context.read<AcademicProvider>();
    final validRows = _rows.where((r) => r.isValid).toList();
    final usedUsernames = academic.users.map((u) => u.email.split('@').first.toLowerCase()).toSet();
    const uuid = Uuid();

    setState(() {
      _stage = _Stage.processing;
      _log.clear();
      _createdEntries.clear();
      _failedRows.clear();
    });

    for (var i = 0; i < validRows.length; i++) {
      final row = validRows[i];
      if (mounted) setState(() => _status = 'Procesando fila ${i + 1} de ${validRows.length}: ${row.fullName}');

      try {
        final username = UserCredentialGenerator.generateUsername(row.firstName, row.lastName, usedUsernames);
        usedUsernames.add(username.toLowerCase());
        final password = UserCredentialGenerator.generatePassword();

        final newUser = await FirebaseAuthService().createUser(
          email: '$username@colegio.edu.co',
          password: password,
          name: row.fullName,
          role: row.role!,
        );
        final userId = newUser.id;

        switch (row.role!) {
          case UserRole.teacher:
            academic.addTeacher(Teacher(
              id: uuid.v4(),
              userId: userId,
              firstName: row.firstName,
              lastName: row.lastName,
              documentId: row.documentId,
              specialization: row.specialization ?? '',
            ));
          case UserRole.student:
            final course = row.courseName == null ? null : _matchCourse(academic, row.courseName!);
            academic.addStudent(Student(
              id: uuid.v4(),
              userId: userId,
              firstName: row.firstName,
              lastName: row.lastName,
              documentId: row.documentId,
              birthDate: DateTime(2010),
              courseId: course?.id,
            ));
          case UserRole.parent:
            academic.addParent(Parent(
              id: uuid.v4(),
              userId: userId,
              firstName: row.firstName,
              lastName: row.lastName,
              documentId: row.documentId,
              phone: row.phone ?? '',
              relationship: row.relationship ?? 'Acudiente',
            ));
          case UserRole.coordinator:
          case UserRole.admin:
            break;
        }

        final entry = CredentialLogEntry(
          firstName: row.firstName,
          lastName: row.lastName,
          documentId: row.documentId,
          username: username,
          password: password,
          roleLabel: _roleLabel(row.role!),
          createdAt: DateTime.now(),
        );
        await CredentialLogService().add(entry);
        if (mounted) {
          setState(() {
            _createdEntries.add(entry);
            _log.add('✓ Fila ${row.rowNumber}: ${row.fullName} → $username');
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _failedRows.add((row, e.toString()));
            _log.add('✗ Fila ${row.rowNumber}: ${row.fullName} → Error: $e');
          });
        }
      }
    }

    if (mounted) setState(() => _stage = _Stage.done);
  }

  Course? _matchCourse(AcademicProvider academic, String name) {
    for (final c in academic.courses) {
      if (c.name.toLowerCase() == name.toLowerCase()) return c;
    }
    return null;
  }

  String _roleLabel(UserRole r) {
    switch (r) {
      case UserRole.coordinator: return 'Coordinador';
      case UserRole.admin: return 'Administrador';
      case UserRole.teacher: return 'Docente';
      case UserRole.student: return 'Estudiante';
      case UserRole.parent: return 'Padre de Familia';
    }
  }

  void _copyAllToClipboard() {
    final lines = ['Nombre\tApellido\tDocumento\tRol\tUsuario\tContraseña'];
    for (final e in _createdEntries) {
      lines.add('${e.firstName}\t${e.lastName}\t${e.documentId}\t${e.roleLabel}\t${e.username}\t${e.password}');
    }
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciales copiadas al portapapeles')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.upload_file_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          const Text('Registro Masivo de Usuarios'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(child: _buildBody()),
      ),
      actions: _buildActions(),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.idle:
        return _buildIdleBody();
      case _Stage.preview:
        return _buildPreviewBody();
      case _Stage.processing:
        return _buildProcessingBody();
      case _Stage.done:
        return _buildDoneBody();
    }
  }

  Widget _buildIdleBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona un archivo .xlsx o .csv con las columnas: nombres, apellidos, '
          'rol (docente, estudiante, padre) y documento. Según el rol puedes incluir '
          'también: especializacion (docente), curso (estudiante), telefono/parentesco (padre).',
        ),
        const SizedBox(height: 16),
        if (_pickError != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Text(_pickError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
          const SizedBox(height: 12),
        ],
        Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Descargar plantilla'),
                onPressed: _downloadTemplate,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Seleccionar archivo'),
                onPressed: _pickFile,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewBody() {
    final validCount = _rows.where((r) => r.isValid).length;
    final errorCount = _rows.length - validCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Archivo: $_fileName', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 16),
            const SizedBox(width: 4),
            Text('$validCount válidos', style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 16),
            if (errorCount > 0) ...[
              const Icon(Icons.error_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: 4),
              Text('$errorCount con error', style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final row = _rows[i];
              return ListTile(
                dense: true,
                leading: Icon(
                  row.isValid ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: row.isValid ? AppColors.secondary : AppColors.error,
                  size: 18,
                ),
                title: Text('Fila ${row.rowNumber}: ${row.fullName}', style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  row.isValid ? _roleLabel(row.role!) : row.error!,
                  style: TextStyle(fontSize: 12, color: row.isValid ? AppColors.textSecondary : AppColors.error),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: _log.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                _log[i],
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _log[i].startsWith('✓') ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 10),
            Expanded(child: Text(_status, style: const TextStyle(fontSize: 12))),
          ],
        ),
      ],
    );
  }

  Widget _buildDoneBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              '${_createdEntries.length} usuario(s) creados correctamente'
              '${_failedRows.isNotEmpty ? ', ${_failedRows.length} con error' : ''}.',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_createdEntries.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _createdEntries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = _createdEntries[i];
                return ListTile(
                  dense: true,
                  title: Text('${e.firstName} ${e.lastName} (${e.roleLabel})', style: const TextStyle(fontSize: 13)),
                  subtitle: Text(
                    'Usuario: ${e.username}  ·  Contraseña: ${e.password}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar todo'),
                onPressed: _copyAllToClipboard,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('Exportar PDF'),
                onPressed: () => exportCredentialsPdf(_createdEntries),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.grid_on_rounded, size: 16),
                label: const Text('Exportar Excel'),
                onPressed: () => exportCredentialsExcel(_createdEntries),
              ),
            ],
          ),
        ],
        if (_failedRows.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Filas con error:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.error)),
          const SizedBox(height: 6),
          ..._failedRows.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Fila ${f.$1.rowNumber}: ${f.$1.fullName} — ${f.$2}',
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              )),
        ],
      ],
    );
  }

  List<Widget> _buildActions() {
    switch (_stage) {
      case _Stage.idle:
        return [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ];
      case _Stage.preview:
        final validCount = _rows.where((r) => r.isValid).length;
        return [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded, size: 16),
            label: const Text('Procesar e importar'),
            onPressed: validCount == 0 ? null : _processImport,
          ),
        ];
      case _Stage.processing:
        return [];
      case _Stage.done:
        return [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ];
    }
  }
}
