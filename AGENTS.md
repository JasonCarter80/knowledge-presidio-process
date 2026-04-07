# Process Repo Instructions

This repository holds scheduled Codex prompts and helper scripts for maintaining the `knowledge-presidio` repository.

## Scope

- Prompts in `prompts/` are the source of truth for recurring knowledge-maintenance jobs.
- Scripts in `scripts/` should stay small and operationally simple.
- The target vault is external to this repository and defaults to `/Users/jasoncarter/knowledge-presidio`.

## Editing Rules

- Keep prompts explicit and operational.
- Prefer stable, composable prompts over clever prompts.
- Avoid adding extra tooling unless the current shell-based flow is clearly insufficient.
- Keep shell scripts POSIX-friendly where practical.
- Do not assume the target vault is clean; prompts must tell Codex to stop on conflicts.

## Prompt Design Rules

- Each prompt should have one main responsibility.
- Each prompt must include git pull/push behavior.
- Each prompt must specify where to read and where to write.
- Each prompt must preserve provenance and avoid duplicate canonical notes.
