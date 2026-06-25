---
name: yasdd-feature
description: "Start a lean SDD feature: plan (grill + explore) → user accepts → implement by component → manual test gate → unit test + impacted tests → verify (writes SUMMARY.md). Feature pipeline entry point for yasdd. Handles config bootstrap and continuation."
disable-model-invocation: true
---
# yasdd-feature

You are the feature pipeline entry point. The user may also call specific skills manually if they want.

## Entry logic

1. **CONFIG BOOTSTRAP:** read `.yasdd/config.yml`. If missing, create it with:
   ```yaml
   autoMode: false
   maxParallelism: 3
   ```
   Keep `autoMode` and `maxParallelism` in context.

2. **MODE DETECTION:**
   - If `$ARGUMENTS` matches an existing feature folder (`.yasdd/features/<slug>/` exists) → **CONTINUATION** (step 3).
   - Else → **NEW FEATURE**: derive a kebab-case slug from `$ARGUMENTS`, create `.yasdd/features/<slug>/`, run from PLAN (step 4).

3. **CONTINUATION DETECTION:** inspect `.yasdd/features/<slug>/`:
   - PLAN.md missing or has `## Open questions` non-empty → resume at **PLAN** (step 4).
   - PLAN.md done, no SUMMARY.md, no implemented files (git diff empty for the feature's paths) → resume at **IMPLEMENT** (step 5).
   - PLAN.md done, files implemented, no SUMMARY.md → ask the user: "Feature `<slug>` has implementation but no SUMMARY.md. Where did it stop? (manual test / test / verify)" → resume at the chosen step.
   - SUMMARY.md exists → skip (done).

## Pipeline

4. **PLAN** (MAIN session, skill `yasdd-plan`): load the skill `yasdd-plan` (skill tool; if unavailable, read `~/.agents/skills/yasdd-plan/SKILL.md`) and run it. It grills the user (one question at a time with recommended answer), launches `yasdd-spy` subagents for codebase investigation, detects impacted existing tests, and writes `PLAN.md` (components `[M#]` + inline parallelism markers + Rules/Cases/Acceptance with anchors + Test impact). It seeds `CONVENTIONS.md` if absent (greenfield: from user decisions; brownfield: detected from `package.json`/`Makefile`/`AGENTS.md`). It validates the plan and presents it to the user for acceptance. Loop until the user accepts. Then return to the feature orchestrator, which proceeds to IMPLEMENT.

5. **IMPLEMENT** (parallel per step, code-only, no checks):
   a. `todowrite`: one todo per component `[M#]`.
   b. Read PLAN.md's `## Steps`. For steps with `*parallel with N*`: launch up to `maxParallelism` implementer subagents in PARALLEL, one per component `[M#]`. For steps with `*depends on N*`: run sequentially after the dependency returns. Each implementer gets the component ID `[M#]` + PLAN.md path + config values.
   c. Each implementer returns `FINISHED` + conformance table + changed-files manifest, or `ISSUES`. Collect manifests + conformance tables in-memory for the tester.
      - `FINISHED` → proceed.
      - `ISSUES` → `autoMode: false`: surface to the user and pause for direction. `autoMode: true`: mark blocked, proceed.
   d. **Mid-flight conflict reconciliation:** if two components in the same parallel group report the same file in their changed-files manifests, re-run the overlapping components sequentially (re-launch them one at a time, in `[M#]` order, so each sees the previous one's output; in-memory only — no PLAN.md rewrite). Flag to the user.
   (Verification is deferred to step 7 — ONE feature-level pass.)

6. **MANUAL TEST GATE:**
   - `autoMode: true` → skip, proceed to TEST (step 7).
   - `autoMode: false` → present the feature to the user — what was implemented, how to run it (entry points from PLAN.md's Interfaces), and the Acceptance `[A#]` to verify. Ask the user to manually exercise the running system and report issues, or say "no more issues" to proceed.
     - **If issues reported → vibe-coding fix loop:** route each issue to the implementer for the affected component `[M#]` (via the changed-files manifest → `[M#]` mapping). Spawn `yasdd-implementer` subagent(s) (code-only), passing the issue + PLAN.md path + affected component ID `[M#]`. On `FINISHED` → re-present the feature for manual re-test → loop until the user says "no more issues". No cap. Informal. User drives.
     - **If "no more issues"** → proceed to TEST (step 7).

7. **TEST** (only if ≥1 component was implemented; runs ONCE for the whole feature): launch ONE `yasdd-tester` subagent with the feature slug + PLAN.md path + CONVENTIONS.md path + the aggregated conformance tables + changed-files manifest + config values. It reads `CONVENTIONS.md` (for check commands) + `PLAN.md` (Acceptance `[A#]` / Cases `[C#]` / Rules `[R#]` / Test impact) + the manifest + conformance tables, writes **UNIT TESTS ONLY** (no e2e, no integration — unit tests chain real functions to cover the business flow), confirms IMPACTED existing tests stay green, and runs checks ONCE (lint/typecheck/unit tests via bash, whole feature; commands from CONVENTIONS.md, falling back to runtime detection). It returns `FINISHED` + summary, or `ISSUES` + classified findings (test-bug vs impl-bug vs impl-bug-impacted, attributed to components `[M#]`).
   - `FINISHED` → proceed to VERIFY (step 8).
   - `ISSUES` → FIX-LOOP: read PLAN.md + classified findings. Write a fix-plan INLINE in the implementer prompt (no file). Route findings to components via the changed-files manifest → `[M#]` mapping. Spawn `yasdd-implementer` subagent(s) for the affected component(s), passing the fix-plan + PLAN.md path + affected component ID `[M#]` + prompt-injected "Run ALL checks: typecheck, compile, unit tests. Fix until green. Prefer check commands from CONVENTIONS.md; fall back to detection only if empty." On `FINISHED` → re-run the TESTER → loop until the tester returns `FINISHED` (cap **3 rounds for the whole feature**).
   - After 3 rounds with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → proceed to VERIFY (step 8) with a note.

8. **VERIFY** (only if ≥1 component was implemented; runs ONCE for the whole feature): launch ONE `yasdd-verifier` subagent with the feature slug + PLAN.md path + CONVENTIONS.md path + config values. It runs checks ONCE (unconditional rerun; commands from CONVENTIONS.md, falling back to runtime detection) across all changed files (code + tests) and reviews the whole feature diff for conformance against PLAN.md (Rules/Cases/Acceptance by component `[M#]`) + code review (security/perf/logic/deadcode in one pass) + test coverage (NEW + IMPACTED tests confirmed green). It returns high-confidence findings (each attributed to a component `[M#]`, or `feature-wide`) or `NO_FINDINGS`. **It writes SUMMARY.md** at `.yasdd/features/<slug>/SUMMARY.md` (Business/Implemented/Files).
   - `NO_FINDINGS` → done (SUMMARY.md written clean).
   - Findings → group by the attributed component(s); ignore components already blocked. Re-launch `yasdd-implementer` **once per affected component, in `[M#]` order**, passing PLAN.md path + the component ID `[M#]` + the findings routed to it + prompt-injected "Run ALL checks. Prefer check commands from CONVENTIONS.md; fall back to detection only if empty." Then re-run VERIFY over the whole feature. Loop until `NO_FINDINGS` (cap **3 rounds for the whole feature**).
   - After 3 rounds with remaining findings: write SUMMARY.md with a blocked note under `## Business` → done.

## Rules
- Handoffs are file references (pass slug/paths/component IDs, not big text). Stay terse.
- For skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
- Disable watchers/git hooks during parallel implementation (disjoint file sets prevent write races, but watchers may contend).
- The feature orchestrator owns config bootstrap and continuation — there is no separate init/continue skill.

## Arguments

$ARGUMENTS
