import 'dart:html' as html;

html.EventListener? _listener;

/// Registra (o quita) el listener de `beforeunload` del navegador. Los
/// navegadores modernos ignoran el mensaje personalizado y muestran su
/// propio diálogo genérico — basta con que el evento tenga `returnValue`
/// asignado para que aparezca.
void setBeforeUnloadWarning(bool enabled) {
  if (enabled && _listener == null) {
    _listener = (event) {
      (event as html.BeforeUnloadEvent).returnValue = '';
    };
    html.window.addEventListener('beforeunload', _listener!);
  } else if (!enabled && _listener != null) {
    html.window.removeEventListener('beforeunload', _listener!);
    _listener = null;
  }
}
