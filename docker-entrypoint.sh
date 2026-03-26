#!/bin/sh
set -eu

APP_DIR="${APP_DIR:-/app}"
CERT_FILE="${CERT_FILE:-$APP_DIR/cert.pem}"
KEY_FILE="${KEY_FILE:-$APP_DIR/key.pem}"
TLS_SECRET_DIR="${TLS_SECRET_DIR:-}"
TLS_CERT_CN="${TLS_CERT_CN:-localhost}"
TLS_CERT_DAYS="${TLS_CERT_DAYS:-3650}"

mkdir -p "$(dirname "$CERT_FILE")" "$(dirname "$KEY_FILE")"

if [ -n "$TLS_SECRET_DIR" ] && [ -f "$TLS_SECRET_DIR/cert.pem" ] && [ -f "$TLS_SECRET_DIR/key.pem" ]; then
  cp "$TLS_SECRET_DIR/cert.pem" "$CERT_FILE"
  cp "$TLS_SECRET_DIR/key.pem" "$KEY_FILE"
fi

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  echo "[entrypoint] Kein TLS-Zertifikat gefunden – erzeuge Self-Signed-Zertifikat für CN=$TLS_CERT_CN"
  openssl req -x509 -nodes -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$TLS_CERT_DAYS" \
    -subj "/CN=$TLS_CERT_CN"
fi

exec python /app/server_noise_monitor.py

