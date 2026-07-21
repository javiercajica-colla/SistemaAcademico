import 'env.dart';

// Interruptor único para alternar entre datos falsos (en memoria) y Firebase
// real. Con `true`, la app funciona 100% offline usando los repositorios
// mock (ver lib/repositories/mock/), útil para trabajar en UI/navegación
// sin depender de la conexión a Firebase.
//
// El valor por defecto vive en código (`Env.useMockData`, por ahora `true`
// para seguir en modo mock localmente); el build de producción lo fuerza a
// `false` vía --dart-define=USE_MOCK_DATA=false sin tocar este archivo (ver
// Dockerfile). Para cambiar el default local, edita `Env.useMockData` en
// lib/core/config/env.dart.
const bool useMockData = Env.useMockData;
