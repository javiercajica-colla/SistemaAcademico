import '../core/config/app_config.dart';
import 'auth_repository.dart';
import 'data_repository.dart';
import 'firebase/firebase_auth_repository.dart';
import 'firebase/firebase_data_repository.dart';
import 'mock/mock_auth_repository.dart';
import 'mock/mock_data_repository.dart';

// Único punto de conmutación entre Firebase real y datos mock. Todo el
// resto de la app (providers, pantallas) debe depender de `authRepository`
// / `dataRepository`, nunca de FirebaseAuthService/FirestoreService ni de
// MockAuthRepository/MockDataRepository directamente.
//
// Para volver a Firebase real: cambia `useMockData` a `false` en
// lib/core/config/app_config.dart (o compila con
// --dart-define=USE_MOCK_DATA=false, ver lib/core/config/env.dart).
final AuthRepository authRepository = useMockData
    ? MockAuthRepository()
    : FirebaseAuthRepository();

final DataRepository dataRepository = useMockData
    ? MockDataRepository()
    : FirebaseDataRepository();
