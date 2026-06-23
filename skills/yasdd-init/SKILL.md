---
name: yasdd-init
description: Initializes the yasdd framework for a project: creates .yasdd/ + config (autoMode false + maxParallelism), creates PROJECT-STATE.md, and updates AGENTS.md with yasdd guidance. Does NOT create CONVENTIONS.md (seeded by elicitation/architect on first feature).
---
# yasdd-init

Run in the MAIN session. Initialize yasdd for this project.

## Process
1. Create `.yasdd/`.
2. Write/merge `.yasdd/config.yml`:
   ```yaml
   autoMode: false
   maxParallelism: 3
   ```
   (Merge: set `maxParallelism: 3` if missing; keep `autoMode` as-is. Remove `maxSpecs` if present — removed in v2.)
3. Create `.yasdd/PROJECT-STATE.md` if missing with content:
   ```md
   # Project State

   ## Features
   ```
4. Update/create `AGENTS.md` in the project root with a brief `## yasdd` section:
   - yasdd workflow pointer (`.yasdd/`, `/yasdd`, `/yasdd-implement`, `/yasdd-init`, `/yasdd-goback`, `/yasdd-clear`, `/yasdd-doubt`, `/yasdd-status`).
   - Scoped reads, no overthinking, pragmatic decisions.
5. **Do NOT create `CONVENTIONS.md`** — it is seeded by the elicitation skill (greenfield) or the architect skill (brownfield) on the first feature, then inherited by all subsequent features.

## Rules
- Super brief, high quality — an index, not a doc.
- Idempotent: re-running refreshes scaffolding only.
- Never create CONVENTIONS.md at init time — init doesn't know the tech stack yet.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
