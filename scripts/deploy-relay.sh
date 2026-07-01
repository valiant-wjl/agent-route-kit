#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build}"
ENV_FILE="${ENV_FILE:-agent-input.env}"

if [ ! -f "$ENV_FILE" ]; then
  echo "missing $ENV_FILE" >&2
  exit 2
fi

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

if [ ! -f "$BUILD_DIR/sing-box/config.json" ]; then
  echo "missing $BUILD_DIR/sing-box/config.json; run tools/render-config.py first" >&2
  exit 2
fi

: "${RELAY_SSH_TARGET:?missing RELAY_SSH_TARGET}"
: "${RELAY_SING_BOX_CONFIG_PATH:?missing RELAY_SING_BOX_CONFIG_PATH}"
: "${RELAY_SING_BOX_SERVICE:?missing RELAY_SING_BOX_SERVICE}"

REMOTE_TMP="/tmp/agent-route-kit-sing-box.json"

scp "$BUILD_DIR/sing-box/config.json" "$RELAY_SSH_TARGET:$REMOTE_TMP"
ssh "$RELAY_SSH_TARGET" "
  set -e
  sudo mkdir -p /etc/sing-box/cert
  if [ ! -f /etc/sing-box/cert/cert.pem ] || [ ! -f /etc/sing-box/cert/key.pem ]; then
    sudo openssl req -x509 -newkey rsa:2048 -nodes \
      -keyout /etc/sing-box/cert/key.pem \
      -out /etc/sing-box/cert/cert.pem \
      -days 3650 \
      -subj '/CN=${HY2_SNI}'
    sudo chmod 600 /etc/sing-box/cert/key.pem
  fi
  sudo install -m 600 -o root -g root '$REMOTE_TMP' '$RELAY_SING_BOX_CONFIG_PATH'
  if command -v sing-box >/dev/null 2>&1; then
    sudo sing-box check -c '$RELAY_SING_BOX_CONFIG_PATH'
  fi
  sudo systemctl restart '$RELAY_SING_BOX_SERVICE'
  sudo systemctl is-active '$RELAY_SING_BOX_SERVICE'
"

echo "relay deployed and service is active"
