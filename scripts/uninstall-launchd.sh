#!/usr/bin/env bash
set -euo pipefail

AGENT_DIR="${HOME}/Library/LaunchAgents"

for label in \
  "com.jasoncarter.knowledgepresidio.daily-ingest" \
  "com.jasoncarter.knowledgepresidio.weekly-synthesis" \
  "com.jasoncarter.knowledgepresidio.weekly-promotion" \
  "com.jasoncarter.knowledgepresidio.monthly-lint"
do
  plist_path="${AGENT_DIR}/${label}.plist"
  if [[ -f "$plist_path" ]]; then
    launchctl unload "$plist_path" >/dev/null 2>&1 || true
    rm -f "$plist_path"
    echo "removed ${label}"
  fi
done
