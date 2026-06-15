#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FRONTEND_DIR="${REPO_ROOT}/frontend"
BACKEND_PUBLIC_DIR="${REPO_ROOT}/backend/public"
FRONTEND_BUILD_DIR="${FRONTEND_DIR}/build/web"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter is required to build the frontend bundle" >&2
  exit 127
fi

cd "${FRONTEND_DIR}"
flutter pub get
flutter build web --release --base-href /

mkdir -p "${BACKEND_PUBLIC_DIR}"

# Remove only previously copied Flutter web build artifacts. Keep Laravel-required
# files such as .htaccess, index.php, robots.txt, favicon.ico, and any storage
# symlink that may exist in public/.
find "${BACKEND_PUBLIC_DIR}" -mindepth 1 -maxdepth 1 \
  ! -name '.htaccess' \
  ! -name 'index.php' \
  ! -name 'robots.txt' \
  ! -name 'favicon.ico' \
  ! -name 'storage' \
  -exec rm -rf {} +

cp -a "${FRONTEND_BUILD_DIR}/." "${BACKEND_PUBLIC_DIR}/"

if [[ ! -f "${BACKEND_PUBLIC_DIR}/index.html" ]]; then
  echo "Expected ${BACKEND_PUBLIC_DIR}/index.html to exist after copying Flutter build" >&2
  exit 1
fi

if [[ ! -f "${BACKEND_PUBLIC_DIR}/main.dart.js" ]]; then
  echo "Expected ${BACKEND_PUBLIC_DIR}/main.dart.js to exist after copying Flutter build" >&2
  exit 1
fi

echo "Flutter web build copied into ${BACKEND_PUBLIC_DIR}"
