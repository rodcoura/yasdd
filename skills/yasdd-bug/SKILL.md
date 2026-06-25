---
name: yasdd-bug
description: "Start a bug fix: investigate (root cause + git blame + blast radius) → user accepts FIX.md → fix by component → manual test gate → unit test + impacted tests → verify (writes SUMMARY.md). Bug fixing pipeline entry point for yasdd. Handles config bootstrap and continuation."
disable-model-invocation: true
---
# yasdd-bug

You are the bug fixing pipeline entry point. The user may also call specific skills manually if they want.

## Entry logic

1. **CONFIG BOOTSTRAP:** read `.yasdd/config.yml`. If missing, create it with:
   ```yaml
   autoMode: false
   maxParallelism: 3
   ```
   Keep `autoMode` and `maxParallelism` in context.

2. **MODE DETECTION:**
   - If `$ARGUMENTS` matches an existing bug folder (`.yasdd/bugs/<slug>/` exists) → **CONTINUATION** (step 3).
   - Else → **NEW BUG**: derive a kebab-case slug from `$ARGUMENTS`, create `.yasdd/bugs/<slug>/`, run from INVESTIGATE (step 4).

3. **CONTINUATION DETECTION:** inspect `.yasdd/bugs/<slug>/`:
   - FIX.md missing or root cause not confirmed → resume at **INVESTIGATE** (step 4).
   - FIX.md done, no SUMMARY.md, no implemented files (git diff empty for the bug's paths) → resume at **FIX** (step 6).
   - FIX.md done, files implemented, no SUMMARY.md → ask the user: "Bug `<slug>` has a fix but no SUMMARY.md. Where did it stop? (manual test / test / verify)" → resume at the chosen step.
   - SUMMARY.md exists → skip (done).

## Pipeline

4. **INVESTIGATE** (MAIN session, skill `yasdd-investigator`): load the skill `yasdd-investigator` (skill tool; if unavailable, read `~/.agents/skills/yasdd-investigator/SKILL.md`) and run it. It parses the bug report, traces the data flow backward from the entry point to the root cause, runs `git blame` to identify which commit introduced the bug (Caused By), assesses the blast radius (level 1–5), and writes `FIX.md` (root cause + fix steps `[M#]` + inline parallelism markers + Rules/Cases/Acceptance with anchors + Test impact). It validates the investigation and presents FIX.md to the user for acceptance. Loop until the user accepts. Then proceed.

5. **GATE:** the investigator presents FIX.md to the user. The user reads the root cause analysis + recommended fix approach and either accepts or raises concerns.
   - On concerns → route back to the investigator to re-investigate or adjust FIX.md → re-validate → re-present. Loop until the user accepts the root cause and fix approach.
   - On accept → proceed to FIX (step 6).

6. **FIX** (parallel per step, code-only, no checks):
   a. `todowrite`: one todo per fix component `[M#]`.
   b. Read FIX.md's `## Fix Steps`. For steps with `*parallel with N*`: launch up to `maxParallelism` implementer subagents in PARALLEL, one per component `[M#]`. For steps with `*depends on N*`: run sequentially after the dependency returns. Each implementer gets the component ID `[M#]` + FIX.md path + config values.
   c. Each implementer returns `FINISHED` + conformance table + changed-files manifest, or `ISSUES`. Collect manifests + conformance tables in-memory for the tester.
      - `FINISHED` → proceed.
      - `ISSUES` → `autoMode: false`: surface to the user and pause for direction. `autoMode: true`: mark blocked, proceed.
   d. **Mid-flight conflict reconciliation:** if two components in the same parallel group report the same file in their changed-files manifests, re-run the overlapping components sequentially (re-launch them one at a time, in `[M#]` order, so each sees the previous one's output; in-memory only — no FIX.md rewrite). Flag to the user.
   (Verification is deferred to step 8 — ONE bug-level pass.)

7. **MANUAL TEST GATE:**
   - `autoMode: true` → skip, proceed to TEST (step 8).
   - `autoMode: false` → present the fix to the user — what was changed, how to reproduce the original bug (from FIX.md's reproduction steps), and the Acceptance `[A#]` to verify the fix. Ask the user to manually exercise the running system and confirm the bug is fixed, or report issues.
     - **If issues reported → vibe-coding fix loop:** route each issue to the implementer for the affected component `[M#]` (via the changed-files manifest → `[M#]` mapping). Spawn `yasdd-implementer` subagent(s) (code-only), passing the issue + FIX.md path + affected component ID `[M#]`. On `FINISHED` → re-present the fix for manual re-test → loop until the user says "no more issues". No cap. Informal. User drives.
     - **If "no more issues"** → proceed to TEST (step 8).

8. **TEST** (only if ≥1 component was fixed; runs ONCE for the whole bug): launch ONE `yasdd-tester` subagent with the bug slug + FIX.md path (as the plan artifact) + CONVENTIONS.md path + the aggregated conformance tables + changed-files manifest + config values + a flag that this is a bug-fix context (regression tests expected). It reads `CONVENTIONS.md` (for check commands) + `FIX.md` (Acceptance `[A#]` / Cases `[C#]` / Rules `[R#]` / Test impact) + the manifest + conformance tables, writes **UNIT TESTS ONLY** (regression tests for the bug — one test per Acceptance case proving the bug is fixed; update existing tests if the fix changes behavior), confirms IMPACTED existing tests stay green, and runs checks ONCE (lint/typecheck/unit tests via bash, whole bug; commands from CONVENTIONS.md, falling back to runtime detection). It returns `FINISHED` + summary, or `ISSUES` + classified findings (test-bug vs impl-bug vs impl-bug-impacted, attributed to components `[M#]`).
   - `FINISHED` → proceed to VERIFY (step 9).
   - `ISSUES` → FIX-LOOP: read FIX.md + classified findings. Write a fix-plan INLINE in the implementer prompt (no file). Route findings to components via the changed-files manifest → `[M#]` mapping. Spawn `yasdd-implementer` subagent(s) for the affected component(s), passing the fix-plan + FIX.md path + affected component ID `[M#]` + prompt-injected "Run ALL checks: typecheck, compile, unit tests. Fix until green. Prefer check commands from CONVENTIONS.md; fall back to detection only if empty." On `FINISHED` → re-run the TESTER → loop until the tester returns `FINISHED` (cap **3 rounds for the whole bug**).
   - After 3 rounds with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → proceed to VERIFY (step 9) with a note.

9. **VERIFY** (only if ≥1 component was fixed; runs ONCE for the whole bug): launch ONE `yasdd-verifier` subagent with the bug slug + FIX.md path (as the plan artifact) + CONVENTIONS.md path + config values + a flag that this is a bug-fix context. It runs checks ONCE (unconditional rerun; commands from CONVENTIONS.md, falling back to runtime detection) across all changed files (code + tests) and reviews the whole bug diff for conformance against FIX.md (Rules/Cases/Acceptance by component `[M#]`) + code review (security/perf/logic/deadcode in one pass) + test coverage (NEW regression tests + IMPACTED tests confirmed green). It returns high-confidence findings (each attributed to a component `[M#]`, or `bug-wide`) or `NO_FINDINGS`. **It writes SUMMARY.md** at `.yasdd/bugs/<slug>/SUMMARY.md` (Business/Implemented/Files).
   - `NO_FINDINGS` → done (SUMMARY.md written clean).
   - Findings → group by the attributed component(s); ignore components already blocked. Re-launch `yasdd-implementer` **once per affected component, in `[M#]` order**, passing FIX.md path + the component ID `[M#]` + the findings routed to it + prompt-injected "Run ALL checks. Prefer check commands from CONVENTIONS.md; fall back to detection only if empty." Then re-run VERIFY over the whole bug. Loop until `NO_FINDINGS` (cap **3 rounds for the whole bug**).
   - After 3 rounds with remaining findings: write SUMMARY.md with a blocked note under `## Business` → done.

## Rules
- Handoffs are file references (pass slug/paths/component IDs, not big text). Stay terse.
- For skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
- Disable watchers/git hooks during parallel implementation (disjoint file sets prevent write races, but watchers may contend).
- The bug orchestrator owns config bootstrap and continuation — there is no separate init/continue skill.
- When passing FIX.md to subagents (implementer/tester/verifier), pass it as the "plan artifact path" — those skills read it the same way they read PLAN.md (the `[M#]`/`[R#]`/`[C#]`/`[A#]` anchors and `Test impact` section are identical in structure).
- The SUMMARY.md path is `.yasdd/bugs/<slug>/SUMMARY.md` — pass this explicitly to the verifier.

## Arguments

$ARGUMENTS
