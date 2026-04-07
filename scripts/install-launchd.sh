#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENT_DIR="${HOME}/Library/LaunchAgents"
LOG_DIR="${HOME}/Library/Logs/knowledge-presidio-process"
RUN_SCRIPT="${ROOT_DIR}/scripts/run-agent.sh"

mkdir -p "$AGENT_DIR" "$LOG_DIR"

install_agent() {
  local label="$1"
  local agent="$2"
  local plist_path="${AGENT_DIR}/${label}.plist"
  local stdout_path="${LOG_DIR}/${agent}.out.log"
  local stderr_path="${LOG_DIR}/${agent}.err.log"

  cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${RUN_SCRIPT}</string>
    <string>${agent}</string>
  </array>
  <key>WorkingDirectory</key>
  <string>${ROOT_DIR}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    <key>VAULT_PATH</key>
    <string>/Users/jasoncarter/knowledge-presidio</string>
  </dict>
  <key>StandardOutPath</key>
  <string>${stdout_path}</string>
  <key>StandardErrorPath</key>
  <string>${stderr_path}</string>
EOF

  case "$agent" in
    daily-ingest)
      cat >> "$plist_path" <<EOF
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>18</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
EOF
      ;;
    weekly-synthesis)
      cat >> "$plist_path" <<EOF
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>0</integer>
    <key>Hour</key>
    <integer>20</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
EOF
      ;;
    weekly-promotion)
      cat >> "$plist_path" <<EOF
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>9</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
EOF
      ;;
    monthly-lint)
      cat >> "$plist_path" <<EOF
  <key>StartCalendarInterval</key>
  <dict>
    <key>Day</key>
    <integer>1</integer>
    <key>Hour</key>
    <integer>10</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
EOF
      ;;
    *)
      echo "unknown agent: $agent" >&2
      exit 1
      ;;
  esac

  cat >> "$plist_path" <<EOF
  <key>RunAtLoad</key>
  <false/>
</dict>
</plist>
EOF

  launchctl unload "$plist_path" >/dev/null 2>&1 || true
  launchctl load "$plist_path"
  echo "installed ${label}"
}

chmod +x "$RUN_SCRIPT"

install_agent "com.jasoncarter.knowledgepresidio.daily-ingest" "daily-ingest"
install_agent "com.jasoncarter.knowledgepresidio.weekly-synthesis" "weekly-synthesis"
install_agent "com.jasoncarter.knowledgepresidio.weekly-promotion" "weekly-promotion"
install_agent "com.jasoncarter.knowledgepresidio.monthly-lint" "monthly-lint"

echo "launch agents installed in ${AGENT_DIR}"
echo "logs will be written to ${LOG_DIR}"
