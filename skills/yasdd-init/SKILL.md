---
name: yasdd-init
description: Initializes the yasdd framework for a project: creates .yasdd/ + config (autoMode false + maxParallelism + maxSpecs), creates PROJECT-STATE.md, and updates AGENTS.md with yasdd guidance.
---
# yasdd-init

Run in the MAIN session. Initialize yasdd for this project.

## Process
1. Create `.yasdd/`.
2. Write/merge `.yasdd/config.yml`:
   ```yaml
   autoMode: false
   maxParallelism: 3
   maxSpecs: 5
   ```
   (Merge: set `maxParallelism: 3` if missing; set `maxSpecs: 5` if missing or `< 1`; keep `autoMode` as-is.)
3. Create `.yasdd/PROJECT-STATE.md` if missing with content:
   ```md
   # Project State

   ## Features
   ```
4. Update/create `AGENTS.md` in the project root with a brief `## yasdd` section:
   - yasdd workflow pointer (`.yasdd/`, `/yasdd`, `/yasdd-implement`, `/yasdd-init`, `/yasdd-goback`, `/yasdd-clear`, `/yasdd-doubt`, `/yasdd-status`).
   - Scoped reads, no overthinking, pragmatic decisions.

## Rules
- Super brief, high quality — an index, not a doc.
- Idempotent: re-running refreshes scaffolding only.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
