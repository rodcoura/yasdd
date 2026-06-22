---
name: yasdd-init
description: Initializes the yasdd framework for a project: creates .yasdd/ + config (autoMode false + maxParallelism + maxSpecs + gate commands), creates PROJECT-STATE.md, and updates AGENTS.md with yasdd guidance.
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
   # Gate commands — detected once at init, reused by tester/verifier/fix-loop.
   # Leave empty or remove to force runtime detection.
   gate:
     testCmd: ""
     lintCmd: ""
     typecheckCmd: ""
   ```
   (Merge: set `maxParallelism: 3` if missing; set `maxSpecs: 5` if missing or `< 1`; keep `autoMode` as-is. Add the `gate:` block if missing, but never overwrite non-empty existing values.)
3. **Detect gate commands** from the repo's tooling and fill empty `gate.*Cmd` values in `.yasdd/config.yml`. Only fill values that are empty; do not override existing values. Detection order:
   - Read `package.json` scripts (if it exists): map `test`/`test:*` to `testCmd`, `lint`/`lint:*` to `lintCmd`, `typecheck`/`tsc`/`check-types` to `typecheckCmd`.
   - Else read `Makefile` for `test`, `lint`, `typecheck` targets.
   - Else read `AGENTS.md` for explicit gate command hints.
   - Persist the first usable command per slot (e.g. `npm test`, `npm run lint`, `npm run typecheck`), leaving the slot empty if none is found.
4. Create `.yasdd/PROJECT-STATE.md` if missing with content:
   ```md
   # Project State

   ## Features
   ```
5. Update/create `AGENTS.md` in the project root with a brief `## yasdd` section:
   - yasdd workflow pointer (`.yasdd/`, `/yasdd`, `/yasdd-implement`, `/yasdd-init`, `/yasdd-goback`, `/yasdd-clear`, `/yasdd-doubt`, `/yasdd-status`).
   - Scoped reads, no overthinking, pragmatic decisions.

## Rules
- Super brief, high quality — an index, not a doc.
- Idempotent: re-running refreshes scaffolding only.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
