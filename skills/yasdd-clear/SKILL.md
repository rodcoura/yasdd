---
name: yasdd-clear
description: Clears all yasdd features and resets PROJECT-STATE.md. Also removes CONVENTIONS.md and any legacy .yasdd/memory files if present.
---
# yasdd-clear

Run in the MAIN session. Destructive — confirm with the user first.

## Process
1. Confirm with the user (question tool): "This removes all features, quick-wins, CHANGES/, and resets PROJECT-STATE.md. Continue?"
2. Remove `.yasdd/features/` (all features, including their `CHANGES/`).
3. Remove `.yasdd/quick-wins/` (all quick wins).
4. Remove `.yasdd/CONVENTIONS.md` (project-wide conventions; will be re-seeded on next feature).
5. Reset `.yasdd/PROJECT-STATE.md` to an empty Features list.
6. Keep `.yasdd/config.yml`.

## Rules
- Never delete config.yml.
- Only clear features, quick-wins, CHANGES, and CONVENTIONS.md; do not touch implementation code.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
