---
name: yasdd-clear
description: Clears all yasdd features and resets PROJECT-STATE.md. Also removes any legacy .yasdd/memory files if present.
---
# yasdd-clear

Run in the MAIN session. Destructive — confirm with the user first.

## Process
1. Confirm with the user (question tool): "This removes all features and resets PROJECT-STATE.md. Continue?"
2. Remove `.yasdd/features/` (all features).
3. Reset `.yasdd/PROJECT-STATE.md` to an empty Features list.
4. Keep `.yasdd/config.yml`.

## Rules
- Never delete config.yml.
- Only clear features and project state; do not touch implementation code.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the spec.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
