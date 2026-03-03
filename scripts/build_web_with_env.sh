#!/usr/bin/env bash
set -euo pipefail

if [[ ! -f .env ]]; then
  echo "Manca file .env (usa .env.example come base)."
  exit 1
fi

BASE_HREF="${1:-/}"

set -a
source .env
set +a

flutter build web --release --base-href "$BASE_HREF" \
  --dart-define=FIREBASE_WEB_API_KEY="${FIREBASE_WEB_API_KEY:-}" \
  --dart-define=FIREBASE_WEB_APP_ID="${FIREBASE_WEB_APP_ID:-}" \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID="${FIREBASE_WEB_MESSAGING_SENDER_ID:-}" \
  --dart-define=FIREBASE_WEB_PROJECT_ID="${FIREBASE_WEB_PROJECT_ID:-}" \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN="${FIREBASE_WEB_AUTH_DOMAIN:-}" \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET="${FIREBASE_WEB_STORAGE_BUCKET:-}" \
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID="${FIREBASE_WEB_MEASUREMENT_ID:-}"
