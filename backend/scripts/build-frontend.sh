#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[build-frontend] $*"
}

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
FRONTEND_DIR="${FRONTEND_DIR:-$REPO_DIR/frontend}"
PUBLIC_DIR="${PUBLIC_DIR:-$BACKEND_DIR/public}"
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "Frontend directory not found at $FRONTEND_DIR" >&2
  echo "Railway should build from the backend directory with the repository root available one level up, so ../frontend exists." >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  export FLUTTER_HOME="${FLUTTER_HOME:-/tmp/flutter}"
  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    log "Installing Flutter SDK ($FLUTTER_VERSION) to $FLUTTER_HOME"
    rm -rf "$FLUTTER_HOME"
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

log "Starting Flutter build"
cd "$FRONTEND_DIR"
flutter config --enable-web
flutter pub get
flutter build web --release --base-href / --dart-define="API_BASE_URL=${API_BASE_URL:-}"
log "Flutter build completed"

if [ ! -f "$FRONTEND_DIR/build/web/index.html" ]; then
  echo "Flutter build did not produce $FRONTEND_DIR/build/web/index.html" >&2
  exit 1
fi

if [ ! -f "$FRONTEND_DIR/build/web/main.dart.js" ]; then
  echo "Flutter build did not produce $FRONTEND_DIR/build/web/main.dart.js" >&2
  exit 1
fi

log "Copying Flutter build to backend/public"
mkdir -p "$PUBLIC_DIR"
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

cp -R "$FRONTEND_DIR/build/web/." "$PUBLIC_DIR/"

if [ ! -f "$PUBLIC_DIR/index.html" ]; then
  echo "Flutter index.html was not copied to $PUBLIC_DIR/index.html" >&2
  exit 1
fi

if [ ! -f "$PUBLIC_DIR/main.dart.js" ]; then
  echo "main.dart.js was not copied to $PUBLIC_DIR/main.dart.js" >&2
  exit 1
fi

log "Confirm main.dart.js exists at $PUBLIC_DIR/main.dart.js"
