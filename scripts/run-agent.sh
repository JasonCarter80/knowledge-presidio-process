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
JOB_TIMEOUT_SECONDS="${JOB_TIMEOUT_SECONDS:-900}"

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

  local payload
  payload="$(python3 - <<'PY' "$content"
import json, sys
print(json.dumps({"content": sys.argv[1]}))
PY
)"

  curl -sS -o /dev/null -w '%{http_code}' \
    -X POST "$DISCORD_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    --data "$payload" | {
      read -r status
      if [[ "$status" != "204" ]]; then
        echo "discord notification failed: http ${status}" >&2
      fi
    } || true
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

CMD=("$CODEX_BIN" exec "--cd" "$VAULT_PATH" "--dangerously-bypass-approvals-and-sandbox")

if [[ -n "$CODEX_MODEL" ]]; then
  CMD+=("--model" "$CODEX_MODEL")
fi

BEFORE_HEAD="$(git -C "$VAULT_PATH" rev-parse HEAD 2>/dev/null || true)"

set +e
python3 - <<'PY' "$JOB_TIMEOUT_SECONDS" "${CMD[@]}" "$(cat "$TMP_PROMPT")"
import subprocess
import sys

timeout = int(sys.argv[1])
cmd = sys.argv[2:]

try:
    completed = subprocess.run(cmd, timeout=timeout)
    raise SystemExit(completed.returncode)
except subprocess.TimeoutExpired:
    print(f"codex job timed out after {timeout} seconds", file=sys.stderr)
    raise SystemExit(124)
PY
STATUS=$?
set -e

AFTER_HEAD="$(git -C "$VAULT_PATH" rev-parse HEAD 2>/dev/null || true)"

if [[ $STATUS -ne 0 ]]; then
  if [[ $STATUS -eq 124 ]]; then
    notify_discord "Knowledge job timed out: \`${AGENT}\` on \`${TODAY}\` after ${JOB_TIMEOUT_SECONDS}s. Check local logs on this machine."
  else
    notify_discord "Knowledge job failed: \`${AGENT}\` on \`${TODAY}\`. Check local logs on this machine."
  fi
  exit $STATUS
fi

if [[ -n "$BEFORE_HEAD" && -n "$AFTER_HEAD" && "$BEFORE_HEAD" != "$AFTER_HEAD" ]]; then
  COMMIT_SUBJECT="$(git -C "$VAULT_PATH" log -1 --pretty=%s)"
  FILE_COUNT="$(git -C "$VAULT_PATH" show --pretty='' --name-only HEAD | sed '/^$/d' | wc -l | tr -d ' ')"
  notify_discord "Knowledge job complete: \`${AGENT}\` on \`${TODAY}\`. Pushed \`${COMMIT_SUBJECT}\` affecting ${FILE_COUNT} file(s)."
else
  notify_discord "Knowledge job complete: \`${AGENT}\` on \`${TODAY}\`. No material changes were committed."
fi
