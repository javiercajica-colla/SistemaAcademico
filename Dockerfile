# syntax=docker/dockerfile:1
# ─────────────────────────────────────────────────────────────────────────
# Etapa 1: compila Flutter Web en modo release.
# Imagen mantenida por Cirrus Labs con el SDK de Flutter preinstalado
# (evita tener que instalar Flutter a mano en una imagen Debian genérica).
# ─────────────────────────────────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copiar primero solo pubspec.* aprovecha la cache de capas de Docker: si
# las dependencias no cambian, `flutter pub get` no se vuelve a ejecutar
# aunque cambie el código fuente.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Config de Firebase / modo de datos parametrizable por build (ver
# lib/core/config/env.dart). USE_MOCK_DATA se fija en "false" para que la
# imagen de producción NUNCA sirva datos falsos, sin importar el valor por
# defecto en el código fuente (pensado para desarrollo local).
#
# Cada ARG tiene como default el mismo valor que ya está hardcodeado en
# lib/core/config/env.dart (proyecto sistema-academico-81c58) — si Railway
# no define estas Build Variables (caso normal, mismo proyecto de Firebase),
# el build igual queda con la config real. Sin un default aquí, un ARG vacío
# se pasaría como --dart-define=FIREBASE_API_KEY= (vacío), lo que PISA el
# defaultValue de String.fromEnvironment en Dart (el default de Dart solo
# aplica si el --dart-define no se pasa en absoluto, no si se pasa vacío).
ARG FIREBASE_API_KEY=AIzaSyDHBY1kKqMkWylQMTFVwzJEi674qAhz_gw
ARG FIREBASE_APP_ID=1:651724277271:web:337186d40512348490be52
ARG FIREBASE_MESSAGING_SENDER_ID=651724277271
ARG FIREBASE_PROJECT_ID=sistema-academico-81c58
ARG FIREBASE_AUTH_DOMAIN=sistema-academico-81c58.firebaseapp.com
ARG FIREBASE_STORAGE_BUCKET=sistema-academico-81c58.firebasestorage.app
ARG FIREBASE_MEASUREMENT_ID=G-31LRRFE2PS
ARG USE_MOCK_DATA=false

RUN flutter build web --release \
    --dart-define=FIREBASE_API_KEY=${FIREBASE_API_KEY} \
    --dart-define=FIREBASE_APP_ID=${FIREBASE_APP_ID} \
    --dart-define=FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID} \
    --dart-define=FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID} \
    --dart-define=FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN} \
    --dart-define=FIREBASE_STORAGE_BUCKET=${FIREBASE_STORAGE_BUCKET} \
    --dart-define=FIREBASE_MEASUREMENT_ID=${FIREBASE_MEASUREMENT_ID} \
    --dart-define=USE_MOCK_DATA=${USE_MOCK_DATA}

# ─────────────────────────────────────────────────────────────────────────
# Etapa 2: sirve el build estático con Nginx (imagen final pequeña, no
# lleva el SDK de Flutter).
# ─────────────────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# nginx:alpine ejecuta automáticamente, al iniciar, envsubst sobre cualquier
# archivo *.template en /etc/nginx/templates/ y lo escribe (sin la
# extensión) en /etc/nginx/conf.d/ — así ${PORT} (que Railway inyecta en
# runtime) se resuelve sin necesidad de un entrypoint propio.
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=builder /app/build/web /usr/share/nginx/html

ENV PORT=80
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD wget -q --spider http://127.0.0.1:${PORT}/ || exit 1
