import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/env.dart';

// Los valores por defecto (proyecto Firebase "sistema-academico-81c58")
// viven en lib/core/config/env.dart y se pueden sobreescribir en build time
// con --dart-define, por ejemplo para apuntar a otro proyecto de Firebase
// sin tocar código (ver Dockerfile).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: Env.firebaseApiKey,
    appId: Env.firebaseAppId,
    messagingSenderId: Env.firebaseMessagingSenderId,
    projectId: Env.firebaseProjectId,
    authDomain: Env.firebaseAuthDomain,
    storageBucket: Env.firebaseStorageBucket,
    measurementId: Env.firebaseMeasurementId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: Env.firebaseApiKey,
    appId: Env.firebaseAppId,
    messagingSenderId: Env.firebaseMessagingSenderId,
    projectId: Env.firebaseProjectId,
    storageBucket: Env.firebaseStorageBucket,
  );
}
