#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[build-frontend] $*"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$BACKEND_DIR/.." && pwd)"
PUBLIC_DIR="${PUBLIC_DIR:-$BACKEND_DIR/public}"
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if [ -d "$REPO_ROOT/frontend" ]; then
  FRONTEND_DIR="$REPO_ROOT/frontend"
elif [ -d "$BACKEND_DIR/../frontend" ]; then
  FRONTEND_DIR="$(cd "$BACKEND_DIR/../frontend" && pwd)"
elif [ -d "/app/frontend" ]; then
  FRONTEND_DIR="/app/frontend"
else
  FRONTEND_DIR="$REPO_ROOT/frontend"
fi

log "Current working directory: $(pwd)"
log "SCRIPT_DIR: $SCRIPT_DIR"
log "BACKEND_DIR: $BACKEND_DIR"
log "REPO_ROOT: $REPO_ROOT"
log "FRONTEND_DIR: $FRONTEND_DIR"
log "Contents of REPO_ROOT ($REPO_ROOT):"
ls -la "$REPO_ROOT" || true
log "Contents of BACKEND_DIR parent ($(dirname "$BACKEND_DIR")):"
ls -la "$(dirname "$BACKEND_DIR")" || true

if [ ! -d "$FRONTEND_DIR" ]; then
  echo "Frontend directory not found at $FRONTEND_DIR" >&2
  echo "Checked $REPO_ROOT/frontend, $BACKEND_DIR/../frontend, and /app/frontend." >&2
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
flutter build web --release --base-href / \
  --dart-define="API_BASE_URL=${API_BASE_URL:-}" \
  --dart-define="SUPABASE_URL=${SUPABASE_URL:-}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}" \
  --dart-define="SUPABASE_PRODUCT_BUCKET=${SUPABASE_PRODUCT_BUCKET:-product-images}" \
  --dart-define="SUPABASE_CATEGORY_BUCKET=${SUPABASE_CATEGORY_BUCKET:-category-images}" \
  --dart-define="SUPABASE_PAYMENT_SLIP_BUCKET=${SUPABASE_PAYMENT_SLIP_BUCKET:-payment-slips}"
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

log "Confirm index.html exists at $PUBLIC_DIR/index.html"
log "Confirm main.dart.js exists at $PUBLIC_DIR/main.dart.js"
