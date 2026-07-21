// Configuración parametrizable en tiempo de compilación (--dart-define).
// Cada valor tiene como `defaultValue` el que ya usa el proyecto hoy, así
// que `flutter run` / `flutter build apk` siguen funcionando exactamente
// igual sin pasar ningún flag nuevo. El build de producción (Docker/Railway,
// ver Dockerfile) sí pasa `--dart-define` para poder apuntar a otro proyecto
// de Firebase o forzar datos reales sin tocar código fuente.
//
// La API key de Firebase Web NO es un secreto en el sentido tradicional:
// Firebase la trata como pública por diseño (queda embebida en cualquier
// build de una SPA) y la seguridad real la dan las reglas de Firestore/Auth
// más las restricciones de la key en Google Cloud Console (dominios
// permitidos, APIs habilitadas). Parametrizarla aquí es para poder desplegar
// el mismo código contra distintos proyectos de Firebase, no para "ocultarla".
class Env {
  const Env._();

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDHBY1kKqMkWylQMTFVwzJEi674qAhz_gw',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:651724277271:web:337186d40512348490be52',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '651724277271',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'sistema-academico-81c58',
  );

  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'sistema-academico-81c58.firebaseapp.com',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'sistema-academico-81c58.firebasestorage.app',
  );

  static const String firebaseMeasurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-31LRRFE2PS',
  );

  // Interruptor entre datos mock (en memoria) y Firebase real — ver
  // lib/core/config/app_config.dart. El build de producción lo fuerza a
  // `false` vía --dart-define=USE_MOCK_DATA=false (ver Dockerfile).
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
}
