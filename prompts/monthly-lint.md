You are maintaining the Presidio knowledge repository.

Target repository:
- https://github.com/JasonCarter80/knowledge-presidio

Your job:
1. Confirm the target repo exists at the provided local vault path.
2. Check repo status. If the worktree is dirty or a rebase/merge is already in progress, stop and report the issue.
3. Pull latest safely with `git pull --rebase`.
4. Review the repository for knowledge-quality issues.
5. Produce or update one monthly maintenance note at:
   - `Logs/Maintenance/YYYY-MM.md`
6. Check for:
   - duplicate canonical notes
   - stale notes
   - notes with weak provenance
   - unresolved contradictions
   - missing high-value canonical notes
   - source-heavy areas with no promotion into `Wiki/`
7. Perform safe low-risk fixes where appropriate.
8. Append a short run entry to `Logs/log.md`.
9. If files materially changed:
   - commit with a concise message like `docs(monthly-lint): 2026-04`
   - push to origin

Rules:
- Prefer diagnosis plus small fixes.
- Preserve history and mark notes as superseded instead of deleting aggressively.
- Never force push.
- If git conflicts occur, stop and report them.
- After finishing the work, provide a brief final summary and then stop. Do not continue exploring once the commit/push decision is complete.
