import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/unsaved_changes_provider.dart';

/// Si hay cambios sin guardar registrados en [UnsavedChangesProvider],
/// muestra un diálogo preguntando si guardar, descartar o cancelar antes
/// de ejecutar [onProceed] (típicamente una navegación). Si no hay
/// cambios pendientes, ejecuta [onProceed] de inmediato.
Future<void> guardNavigation(BuildContext context, VoidCallback onProceed) async {
  final unsaved = context.read<UnsavedChangesProvider>();
  if (!unsaved.hasUnsavedChanges) {
    onProceed();
    return;
  }

  final action = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cambios sin guardar'),
      content: Text(unsaved.message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'cancel'),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'discard'),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Descartar cambios'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'save'),
          child: const Text('Guardar y continuar'),
        ),
      ],
    ),
  );

  if (action == 'save') {
    unsaved.save();
    onProceed();
  } else if (action == 'discard') {
    unsaved.discard();
    onProceed();
  }
  // 'cancel' o diálogo cerrado sin elegir (Esc / clic afuera): no hacer nada.
}
