#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-agent-input.env}"

ok() { printf "OK   %s\n" "$*"; }
warn() { printf "WARN %s\n" "$*"; }
fail() { printf "FAIL %s\n" "$*"; }

need_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "command found: $1"
  else
    fail "missing command: $1"
    return 1
  fi
}

status=0
for cmd in bash python3 curl ssh scp; do
  need_cmd "$cmd" || status=1
done

if [ "$(uname -s)" = "Darwin" ]; then
  need_cmd networksetup || status=1
  if command -v dscacheutil >/dev/null 2>&1; then
    ok "command found: dscacheutil"
  else
    warn "dscacheutil missing; corporate DNS probes will be limited"
  fi
else
  warn "non-macOS host detected; install-local-macos.sh is macOS-only"
fi

if command -v mihomo >/dev/null 2>&1 || pgrep -f mihomo >/dev/null 2>&1; then
  ok "mihomo binary or process detected"
else
  warn "mihomo not detected; install it before starting the local router"
fi

if [ ! -f "$ENV_FILE" ]; then
  fail "missing $ENV_FILE; copy agent-input.example.env first"
  exit 1
fi

python3 tools/render-config.py --env "$ENV_FILE" --out /tmp/agent-route-kit-prereq-render >/dev/null
ok "input contract can render configs"

set -a
# shellcheck disable=SC1090
. "$ENV_FILE"
set +a

if [ -n "${RELAY_SSH_TARGET:-}" ]; then
  if ssh -o BatchMode=yes -o ConnectTimeout=5 "$RELAY_SSH_TARGET" "echo ok" >/dev/null 2>&1; then
    ok "relay SSH reachable: $RELAY_SSH_TARGET"
  else
    warn "relay SSH not reachable with batch auth: $RELAY_SSH_TARGET"
  fi
fi

exit "$status"
