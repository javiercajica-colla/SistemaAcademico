import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


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
    apiKey: 'AIzaSyDHBY1kKqMkWylQMTFVwzJEi674qAhz_gw',
    appId: '1:651724277271:web:337186d40512348490be52',
    messagingSenderId: '651724277271',
    projectId: 'sistema-academico-81c58',
    authDomain: 'sistema-academico-81c58.firebaseapp.com',
    storageBucket: 'sistema-academico-81c58.firebasestorage.app',
    measurementId: 'G-31LRRFE2PS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDHBY1kKqMkWylQMTFVwzJEi674qAhz_gw',
    appId: '1:651724277271:web:337186d40512348490be52',
    messagingSenderId: '651724277271',
    projectId: 'sistema-academico-81c58',
    storageBucket: 'sistema-academico-81c58.firebasestorage.app',
  );
}
