// Activa/desactiva la advertencia nativa del navegador al cerrar o
// recargar la pestaña ("¿Seguro que quieres salir? Los cambios que
// hayas hecho no se guardarán") mientras haya cambios sin guardar. No-op
// fuera de la web. Mismo patrón de export condicional que download_helper.dart.
export 'beforeunload_helper_stub.dart'
    if (dart.library.html) 'beforeunload_helper_web.dart';
