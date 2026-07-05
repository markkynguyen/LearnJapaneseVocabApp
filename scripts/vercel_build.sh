#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_URL:-}" ]]; then
  echo "Missing required Vercel environment variable: SUPABASE_URL" >&2
  exit 1
fi

if [[ -z "${SUPABASE_PUBLISHABLE_KEY:-}" ]]; then
  echo "Missing required Vercel environment variable: SUPABASE_PUBLISHABLE_KEY" >&2
  exit 1
fi

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.2}"
FLUTTER_DIR="${HOME}/flutter-${FLUTTER_VERSION}"

if [[ ! -x "${FLUTTER_DIR}/bin/flutter" ]]; then
  git clone \
    --depth 1 \
    --branch "${FLUTTER_VERSION}" \
    https://github.com/flutter/flutter.git \
    "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

flutter --disable-analytics
dart --disable-analytics
flutter config --enable-web
flutter pub get
flutter build web \
  --release \
  --no-wasm-dry-run \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}"
