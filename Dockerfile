# ---- Build stage: compile the Flutter web app ----
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y \
    git curl unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install the Flutter SDK
RUN git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter --version && flutter config --enable-web

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Build the app
COPY . .
RUN flutter build web --release

# ---- Runtime stage: serve the static build output ----
FROM caddy:2-alpine AS runtime

COPY --from=build /app/build/web /usr/share/caddy

# Bind Caddy to Railway's $PORT on 0.0.0.0 and serve the SPA
CMD ["sh", "-c", "caddy file-server --listen 0.0.0.0:${PORT:-80} --root /usr/share/caddy"]
