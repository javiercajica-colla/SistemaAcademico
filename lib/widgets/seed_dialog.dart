import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/seed_service.dart';

class SeedDialog extends StatefulWidget {
  const SeedDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SeedDialog(),
    );
  }

  @override
  State<SeedDialog> createState() => _SeedDialogState();
}

class _SeedDialogState extends State<SeedDialog> {
  bool _running = false;
  bool _done = false;
  bool _error = false;
  String _status = 'Listo para inicializar los datos del sistema.';
  final List<String> _log = [];

  Future<void> _runSeed() async {
    setState(() {
      _running = true;
      _error = false;
      _log.clear();
    });

    try {
      await SeedService().seedAll((msg) {
        if (mounted) {
          setState(() {
            _status = msg;
            _log.add(msg);
          });
        }
      });

      // Refrescar el usuario actual en el AuthProvider
      if (mounted) {
        await context.read<AuthProvider>().refreshCurrentUser();
        setState(() {
          _done = true;
          _running = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _running = false;
          _error = true;
          _status = 'Error: $e';
          _log.add('✗ Error: $e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cloud_upload_rounded, color: Color(0xFF1976D2)),
          const SizedBox(width: 10),
          const Text('Inicializar datos en Firebase'),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_running && !_done && !_error) ...[
              const Text(
                'Esto creará en Firebase Auth y Firestore todos los usuarios, '
                'cursos, asignaturas, calificaciones y datos del sistema de demostración.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ejecutar solo una vez. Si ya existe algún usuario, '
                        'ese paso se omitirá automáticamente.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_running || _done || _error) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: _log.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _log[i],
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: _log[i].startsWith('✓')
                            ? Colors.greenAccent
                            : _log[i].startsWith('✗')
                                ? Colors.redAccent
                                : Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              if (_running) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_status,
                          style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
              ],
              if (_done) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Base de datos inicializada correctamente.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: Colors.green),
                    ),
                  ],
                ),
              ],
              if (_error) ...[
                const SizedBox(height: 8),
                Text(_status,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (!_running) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (!_done)
            FilledButton.icon(
              onPressed: _runSeed,
              icon: const Icon(Icons.rocket_launch_rounded, size: 16),
              label: Text(_error ? 'Reintentar' : 'Inicializar'),
            ),
        ],
      ],
    );
  }
}
