# knowledge-presidio-process

Scheduled Codex CLI workflows for maintaining the `knowledge-presidio` repository as a living knowledge base.

## Purpose

This repo contains:

- reusable agent prompts
- a small wrapper script for `codex exec`
- operating instructions for running daily, weekly, and monthly knowledge maintenance jobs

The target knowledge repo is:

- `https://github.com/JasonCarter80/knowledge-presidio`

The default local vault path is:

- `/Users/jasoncarter/knowledge-presidio`

## Jobs

- `daily-ingest`: normalize and summarize new source material
- `weekly-synthesis`: synthesize the last 7 days of source notes
- `weekly-promotion`: promote durable knowledge into canonical `Wiki/` notes
- `monthly-lint`: detect duplicates, stale notes, weak provenance, and missing canonicals

## Requirements

- `codex` CLI installed and authenticated
- `git` configured with push access to `JasonCarter80/knowledge-presidio`
- local checkout of `knowledge-presidio`

## Usage

Run a job:

```bash
./scripts/run-agent.sh daily-ingest
./scripts/run-agent.sh weekly-synthesis
./scripts/run-agent.sh weekly-promotion
./scripts/run-agent.sh monthly-lint
```

Override the vault path:

```bash
VAULT_PATH=/path/to/knowledge-presidio ./scripts/run-agent.sh weekly-synthesis
```

Print the final prompt without running Codex:

```bash
PRINT_ONLY=1 ./scripts/run-agent.sh monthly-lint
```

Override the model:

```bash
CODEX_MODEL=gpt-5.4 ./scripts/run-agent.sh weekly-promotion
```

Override the maximum runtime in seconds:

```bash
JOB_TIMEOUT_SECONDS=1200 ./scripts/run-agent.sh daily-ingest
```

## Discord Notifications

Optional Discord summaries can be sent after each run.

Create a local config file on this machine:

```bash
mkdir -p ~/.config
cat > ~/.config/knowledge-presidio-process.env <<'EOF'
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
EOF
chmod 600 ~/.config/knowledge-presidio-process.env
```

The webhook is read locally by `scripts/run-agent.sh` and is not stored in git.

Notification behavior:

- success with changes: includes the new commit subject and changed file count
- success with no material changes: indicates no commit was created
- failure: indicates the job failed and points to local logs
- timeout: indicates the Codex run exceeded the local watchdog limit

## Scheduling

Example cron entries:

```cron
0 18 * * * cd /Users/jasoncarter/code/knowledge-presidio-process && ./scripts/run-agent.sh daily-ingest >> /tmp/knowledge-presidio-daily.log 2>&1
0 20 * * 0 cd /Users/jasoncarter/code/knowledge-presidio-process && ./scripts/run-agent.sh weekly-synthesis >> /tmp/knowledge-presidio-weekly-synthesis.log 2>&1
0 9 * * 1 cd /Users/jasoncarter/code/knowledge-presidio-process && ./scripts/run-agent.sh weekly-promotion >> /tmp/knowledge-presidio-weekly-promotion.log 2>&1
0 10 1 * * cd /Users/jasoncarter/code/knowledge-presidio-process && ./scripts/run-agent.sh monthly-lint >> /tmp/knowledge-presidio-monthly-lint.log 2>&1
```

Suggested cadence:

- daily ingest: end of each workday
- weekly synthesis: Sunday evening
- weekly promotion: Monday morning
- monthly lint: first day of the month

For macOS, `launchd` is the preferred scheduler. Install the launch agents with:

```bash
./scripts/install-launchd.sh
```

Unload them with:

```bash
./scripts/uninstall-launchd.sh
```

Installed schedules:

- daily ingest: every day at `18:00`
- weekly synthesis: Sunday at `20:00`
- weekly promotion: Monday at `09:00`
- monthly lint: day `1` of each month at `10:00`

## Safety Rules

The prompts instruct Codex to:

- pull latest with `git pull --rebase` before writing
- stop on conflicts or dirty-worktree issues
- make small commits
- push after successful material changes
- never force push

## Repo Layout

```text
prompts/
  daily-ingest.md
  weekly-synthesis.md
  weekly-promotion.md
  monthly-lint.md
scripts/
  run-agent.sh
  install-launchd.sh
  uninstall-launchd.sh
AGENTS.md
```
