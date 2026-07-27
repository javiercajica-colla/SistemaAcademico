import 'package:flutter/foundation.dart';
import '../core/utils/beforeunload_helper.dart';

/// Registro global de "cambios sin guardar". Las pantallas donde el
/// docente edita datos localmente antes de un guardado explícito
/// (Calificaciones, Comportamiento, Asistencia) se registran aquí
/// mientras tengan cambios pendientes, para poder advertir antes de
/// navegar a otra sección del menú lateral o cerrar/recargar la pestaña.
class UnsavedChangesProvider extends ChangeNotifier {
  String? _message;
  VoidCallback? _onSave;
  VoidCallback? _onDiscard;

  bool get hasUnsavedChanges => _message != null;
  String get message => _message ?? '';

  void markDirty({
    required String message,
    required VoidCallback onSave,
    required VoidCallback onDiscard,
  }) {
    final wasClean = _message == null;
    _message = message;
    _onSave = onSave;
    _onDiscard = onDiscard;
    if (wasClean) setBeforeUnloadWarning(true);
    notifyListeners();
  }

  void markClean() {
    if (_message == null) return;
    _message = null;
    _onSave = null;
    _onDiscard = null;
    setBeforeUnloadWarning(false);
    notifyListeners();
  }

  /// Ejecuta el guardado registrado por la pantalla activa y limpia el
  /// estado. No hace nada si no hay cambios pendientes.
  void save() {
    _onSave?.call();
    markClean();
  }

  /// Descarta los cambios (la pantalla que se abandona ya no persiste su
  /// estado local, así que normalmente no hay nada que deshacer) y limpia
  /// el estado.
  void discard() {
    _onDiscard?.call();
    markClean();
  }
}
