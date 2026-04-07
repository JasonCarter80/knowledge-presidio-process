#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 {daily-ingest|weekly-synthesis|weekly-promotion|monthly-lint}" >&2
  exit 1
fi

AGENT="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="$ROOT_DIR/prompts/$AGENT.md"
VAULT_PATH="${VAULT_PATH:-/Users/jasoncarter/knowledge-presidio}"
CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_MODEL="${CODEX_MODEL:-}"
PRINT_ONLY="${PRINT_ONLY:-0}"
LOCAL_ENV_FILE="${HOME}/.config/knowledge-presidio-process.env"

if [[ -f "$LOCAL_ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$LOCAL_ENV_FILE"
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "unknown agent: $AGENT" >&2
  exit 1
fi

if [[ ! -d "$VAULT_PATH" ]]; then
  echo "vault path does not exist: $VAULT_PATH" >&2
  exit 1
fi

notify_discord() {
  local content="$1"
  if [[ -z "${DISCORD_WEBHOOK_URL:-}" ]]; then
    return 0
  fi

  python3 - <<'PY' "$DISCORD_WEBHOOK_URL" "$content"
import json, sys, urllib.request
url = sys.argv[1]
content = sys.argv[2]
data = json.dumps({"content": content}).encode("utf-8")
req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
urllib.request.urlopen(req, timeout=15).read()
PY
}

TODAY="$(date +%F)"
TMP_PROMPT="$(mktemp)"
trap 'rm -f "$TMP_PROMPT"' EXIT

cat > "$TMP_PROMPT" <<EOF
Current date: $TODAY
Local vault path: $VAULT_PATH
Run this job against the local git checkout at that path.
Use absolute paths when useful.

$(cat "$PROMPT_FILE")
EOF

if [[ "$PRINT_ONLY" == "1" ]]; then
  cat "$TMP_PROMPT"
  exit 0
fi

CMD=("$CODEX_BIN" exec "--cwd" "$VAULT_PATH" "--sandbox" "danger-full-access" "--ask-for-approval" "never")

if [[ -n "$CODEX_MODEL" ]]; then
  CMD+=("--model" "$CODEX_MODEL")
fi

BEFORE_HEAD="$(git -C "$VAULT_PATH" rev-parse HEAD 2>/dev/null || true)"

set +e
"${CMD[@]}" "$(cat "$TMP_PROMPT")"
STATUS=$?
set -e

AFTER_HEAD="$(git -C "$VAULT_PATH" rev-parse HEAD 2>/dev/null || true)"

if [[ $STATUS -ne 0 ]]; then
  notify_discord "Knowledge job failed: \`${AGENT}\` on \`${TODAY}\`. Check local logs on this machine."
  exit $STATUS
fi

if [[ -n "$BEFORE_HEAD" && -n "$AFTER_HEAD" && "$BEFORE_HEAD" != "$AFTER_HEAD" ]]; then
  COMMIT_SUBJECT="$(git -C "$VAULT_PATH" log -1 --pretty=%s)"
  FILE_COUNT="$(git -C "$VAULT_PATH" show --pretty='' --name-only HEAD | sed '/^$/d' | wc -l | tr -d ' ')"
  notify_discord "Knowledge job complete: \`${AGENT}\` on \`${TODAY}\`. Pushed \`${COMMIT_SUBJECT}\` affecting ${FILE_COUNT} file(s)."
else
  notify_discord "Knowledge job complete: \`${AGENT}\` on \`${TODAY}\`. No material changes were committed."
fi
