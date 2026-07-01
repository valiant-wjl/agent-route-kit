#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${1:-build}"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.config/agent-route-kit}"
MIHOMO_CONFIG_DIR="${MIHOMO_CONFIG_DIR:-$HOME/.config/mihomo}"
AI_TOOL_CONFIG_DIR="${AI_TOOL_CONFIG_DIR:-$HOME/.claude}"
LAUNCH_AGENT_ID="${LAUNCH_AGENT_ID:-com.agent-route-kit.mihomo}"
LAUNCH_AGENT_PATH="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_ID.plist"
LOG_DIR="$HOME/Library/Logs/agent-route-kit"

if [ ! -f "$BUILD_DIR/mihomo/config.yaml" ]; then
  echo "missing $BUILD_DIR/mihomo/config.yaml; run tools/render-config.py first" >&2
  exit 2
fi

if [ "$(uname -s)" != "Darwin" ]; then
  echo "install-local-macos.sh only supports macOS" >&2
  exit 2
fi

MIHOMO_BIN="${MIHOMO_BIN:-$(command -v mihomo || true)}"
if [ -z "$MIHOMO_BIN" ]; then
  if command -v brew >/dev/null 2>&1; then
    brew install mihomo
    MIHOMO_BIN="$(command -v mihomo || true)"
  fi
fi
if [ -z "$MIHOMO_BIN" ]; then
  echo "mihomo binary not found; install mihomo or set MIHOMO_BIN=/path/to/mihomo" >&2
  exit 2
fi

mkdir -p "$INSTALL_DIR" "$MIHOMO_CONFIG_DIR" "$AI_TOOL_CONFIG_DIR" "$HOME/Library/LaunchAgents" "$LOG_DIR"
cp "$BUILD_DIR/mihomo/config.yaml" "$MIHOMO_CONFIG_DIR/config.yaml"
cp "$BUILD_DIR/claude-code/settings.json" "$AI_TOOL_CONFIG_DIR/settings.json.agent-route-kit"
cp "$BUILD_DIR/deployment-metadata.json" "$INSTALL_DIR/deployment-metadata.json"

"$MIHOMO_BIN" -t -d "$MIHOMO_CONFIG_DIR"

cat > "$LAUNCH_AGENT_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LAUNCH_AGENT_ID</string>
  <key>ProgramArguments</key>
  <array>
    <string>$MIHOMO_BIN</string>
    <string>-d</string>
    <string>$MIHOMO_CONFIG_DIR</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/mihomo.out.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/mihomo.err.log</string>
</dict>
</plist>
PLIST

launchctl unload "$LAUNCH_AGENT_PATH" >/dev/null 2>&1 || true
launchctl load "$LAUNCH_AGENT_PATH"
launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_ID" >/dev/null 2>&1 || true

echo "installed mihomo config: $MIHOMO_CONFIG_DIR/config.yaml"
echo "installed AI tool settings snippet: $AI_TOOL_CONFIG_DIR/settings.json.agent-route-kit"
echo "installed launch agent: $LAUNCH_AGENT_PATH"
echo "next: run tools/net status"
