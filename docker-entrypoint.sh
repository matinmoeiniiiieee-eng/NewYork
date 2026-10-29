#!/bin/sh
# Startup script for Deplexo (works on any Docker host).
# - Deplexo root filesystem is read-only; only /data (persistent volume) and /tmp are writable.
# - Deplexo injects PORT from run.port in deplexo.yaml.
set -e

DATA_DIR="${DATA_DIR:-/data}"
if mkdir -p "$DATA_DIR" 2>/dev/null && touch "$DATA_DIR/.write_test" 2>/dev/null; then
  rm -f "$DATA_DIR/.write_test"
else
  echo "[deplexo] WARNING: $DATA_DIR is not writable; falling back to /tmp/gateway-data (state will NOT survive redeploys)."
  DATA_DIR="/tmp/gateway-data"
  mkdir -p "$DATA_DIR"
fi
export DATA_DIR

# main.py reads RAILWAY_PUBLIC_DOMAIN as a fallback host (e.g. for Telegram bot links).
# On Deplexo set PUBLIC_DOMAIN (e.g. myapp.de.deplexo.com or your custom domain) instead.
if [ -z "${RAILWAY_PUBLIC_DOMAIN:-}" ] && [ -n "${PUBLIC_DOMAIN:-}" ]; then
  export RAILWAY_PUBLIC_DOMAIN="$PUBLIC_DOMAIN"
fi

PORT="${PORT:-8000}"
echo "[deplexo] starting Gateway on 0.0.0.0:$PORT (DATA_DIR=$DATA_DIR)"

exec uvicorn main:app \
  --host 0.0.0.0 \
  --port "$PORT" \
  --workers 1 \
  --proxy-headers \
  --forwarded-allow-ips "*" \
  --log-level info
