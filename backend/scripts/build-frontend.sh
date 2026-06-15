#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
FRONTEND_DIR="$REPO_DIR/frontend"
PUBLIC_DIR="$BACKEND_DIR/public"
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "Frontend directory not found at $FRONTEND_DIR" >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  export FLUTTER_HOME="${FLUTTER_HOME:-/tmp/flutter}"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    echo "Installing Flutter SDK ($FLUTTER_VERSION) to $FLUTTER_HOME"
    rm -rf "$FLUTTER_HOME"
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

cd "$FRONTEND_DIR"
flutter config --enable-web
flutter pub get
flutter build web --release --base-href / --dart-define="API_BASE_URL=${API_BASE_URL:-}"

rm -rf "$PUBLIC_DIR/flutter_assets" \
       "$PUBLIC_DIR/assets" \
       "$PUBLIC_DIR/canvaskit" \
       "$PUBLIC_DIR/icons" \
       "$PUBLIC_DIR/favicon.png" \
       "$PUBLIC_DIR/flutter.js" \
       "$PUBLIC_DIR/flutter_bootstrap.js" \
       "$PUBLIC_DIR/flutter_service_worker.js" \
       "$PUBLIC_DIR/index.html" \
       "$PUBLIC_DIR/main.dart.js" \
       "$PUBLIC_DIR/manifest.json" \
       "$PUBLIC_DIR/version.json"

cp -R build/web/. "$PUBLIC_DIR/"
echo "Hello Homes Flutter web build copied to $PUBLIC_DIR"
