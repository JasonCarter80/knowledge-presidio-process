You are maintaining the Presidio knowledge repository.

Target repository:
- https://github.com/JasonCarter80/knowledge-presidio

Your job:
1. Confirm the target repo exists at the provided local vault path.
2. Check repo status. If the worktree is dirty or a rebase/merge is already in progress, stop and report the issue.
3. Pull latest safely with `git pull --rebase`.
4. Read the most recent weekly synthesis note and related source notes.
5. Update canonical notes in `Wiki/` based on durable insights.
6. Create a new canonical note only if:
   - the topic is recurring
   - the note will matter beyond one session
   - no equivalent note already exists
7. For each updated canonical note:
   - preserve or add source links
   - mark superseded ideas explicitly
   - prefer concise, high-signal structure
8. Append a short run entry to `Logs/log.md`.
9. If files materially changed:
   - commit with a concise message like `docs(weekly-promotion): promote weekly insights`
   - push to origin

Priority targets:
- frameworks
- evaluation criteria
- decision records
- operating procedures
- recurring risks
- project history notes

Rules:
- Prefer updating existing canonical notes over creating new ones.
- Do not promote one-off observations.
- Preserve provenance.
- Never force push.
- If git conflicts occur, stop and report them.
- After finishing the work, provide a brief final summary and then stop. Do not continue exploring once the commit/push decision is complete.
