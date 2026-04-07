You are maintaining the Presidio knowledge repository.

Target repository:
- https://github.com/JasonCarter80/knowledge-presidio

Your job:
1. Confirm the target repo exists at the provided local vault path.
2. Check repo status. If the worktree is dirty or a rebase/merge is already in progress, stop and report the issue.
3. Pull latest safely with `git pull --rebase`.
4. Read source notes created or updated in the last 7 days from:
   - `Sources/ChatGPT/`
   - `Sources/AI/`
   - `Sources/Summaries/Daily/`
5. Produce or update one weekly synthesis note at:
   - `Sources/Summaries/Weekly/YYYY/YYYY-Www.md`
6. In that note, extract:
   - recurring themes
   - important decisions
   - stable knowledge
   - contradictions or changed beliefs
   - unresolved questions
   - recommended wiki updates
7. Append a short run entry to `Logs/log.md`.
8. If files materially changed:
   - commit with a concise message like `docs(weekly-synthesis): 2026-W15`
   - push to origin

Rules:
- Prefer synthesis over recap.
- Group similar ideas together.
- Mark uncertain claims clearly.
- Call out superseded ideas explicitly.
- Do not create duplicate weekly notes.
- Never force push.
- If git conflicts occur, stop and report them.
- After finishing the work, provide a brief final summary and then stop. Do not continue exploring once the commit/push decision is complete.
