---
name: yasdd-orchestrator
description: "Start a lean SDD feature: elicitation -> architecture (with self-check + batches + testing) -> gate -> implement by component -> test -> verify."
disable-model-invocation: true
---
# yasdd-orchestrator

Load the skill `yasdd-elicitation` (skill tool) and run the Elicitation phase for a new feature.

You are the orchestrator. Read `.yasdd/config.yml` once at the start (create it with `autoMode: false`, `maxParallelism: 3` if missing — you are one of the few skills allowed to create it; the others are `yasdd-init`, `yasdd-status`, and `yasdd-quick-win`). `autoMode` drives the gate at step 3; `maxParallelism` caps parallel subagent calls per step (ELICITATION's yasdd-spy, IMPLEMENT batch size, verifier tracks).

Subagents are launched ONLY for the IMPLEMENT (step 4), TEST (step 5), FIX-LOOP (step 5b), and FINAL VERIFY (step 6) phases. ELICITATION (step 1) and ARCHITECTURE (step 2) run in the MAIN session, reusing the codebase context loaded during elicitation — zero re-exploration. For each subagent role, launch the harness's existing subagent (Task tool, `subagent_type: general`) with a prompt: "Load the skill `yasdd-<role>` (skill tool; if unavailable, read `~/.agents/skills/yasdd-<role>/SKILL.md`) and follow it. Inputs: <slug + paths + component ID [M#]>. Config values from `.yasdd/config.yml`: `autoMode=<value>`, `maxParallelism=<value>`. Use these values; do not re-read `config.yml`." After each subagent, briefly report its outcome to the user.

## Pipeline
0. Read `.yasdd/config.yml` (create with `autoMode: false`, `maxParallelism: 3` if missing) and keep its values in context.
0a. **Capture the request:** as the very first action, confirm the feature slug (this is the first sub-step of ELICITATION below). Once the slug is known, write the original `$ARGUMENTS` (the user's feature request, verbatim) to `.yasdd/features/<slug>/REQUEST.md`. This preserves the raw user request for later reference. Skip the write if `$ARGUMENTS` is empty.
0b. **CONVENTIONS check:** if `.yasdd/CONVENTIONS.md` is absent, the architect will seed it (greenfield: elicitation decides; brownfield: architect detects from package.json/Makefile/AGENTS.md). No action here — just note its absence for the architect.
1. **ELICITATION** (main session, skill `yasdd-elicitation`): run the tiered grilling elicitation (core 8 + extended 10 if complex/greenfield) until gaps closed. The skill may launch up to `maxParallelism` `yasdd-spy` subagents in parallel for codebase-first investigation. Greenfield detection via yasdd-spy; if greenfield, the skill seeds `CONVENTIONS.md`. Writes `ELICITATION.md`. Create `.yasdd/` and `PROJECT-STATE.md` (with `# Project State` heading and empty `## Features`) if missing (config.yml is already created at step 0).
2. **ARCHITECTURE** (main session, skill `yasdd-architect`): reuse elicitation context; load skill `yasdd-architect`, read `ELICITATION.md` (already in context), do targeted reads only. Writes `ARCHITECTURE.md` (components `[M#]` + parallel batches + testing section + Rules/Cases/Acceptance with anchors). Inherits Testing fields from `CONVENTIONS.md` if present; if absent, detects + writes `CONVENTIONS.md`. Runs the 10-point self-check (cap 3 iterations). Initializes `STATE.md` (per-component impl/test/verify status) + updates `PROJECT-STATE.md`.
3. **GATE**:
   - `autoMode: true` → proceed straight to implementation (no pause).
   - `autoMode: false` → ask user: "Architecture ready. Can I proceed to implementation?"
4. **IMPLEMENT LOOP** (parallel per batch, code-only, no checks):
   a. `todowrite`: one todo per component `[M#]`.
   b. Read `ARCHITECTURE.md`'s `Parallel batches` section. For each batch: launch up to `maxParallelism` implementer subagents (skill `yasdd-implementer`) in PARALLEL, one per component `[M#]` in the batch. Each implementer gets the component ID `[M#]` + ARCHITECTURE.md path. Each returns `FINISHED` + one-line summary + conformance table (functioning DEFERRED) + changed-files manifest, or `ISSUES` + brief issues. The implementer already updates `SUMMARY.md` on either outcome (bullets on `FINISHED`, blocked note on `ISSUES`). File ownership is disjoint within a batch (no write races).
      - `FINISHED` → set `impl: done` in `STATE.md` (top-level marker stays `[ ]` until impl+test+verify are all done), bump count, update `PROJECT-STATE.md`. Collect the manifest + conformance table for the tester.
      - `ISSUES` → `autoMode: false`: surface the issues to the user and pause for direction. `autoMode: true`: mark component as blocked in `STATE.md` (set `impl: blocked`, use `[~]`), proceed.
   c. Next batch (sequential across batches, parallel within a batch).
   d. **Aggregate** manifests + conformance tables across all batches. **Mid-flight batch update (in-memory):** if two components in the same batch report the same file in their changed-files manifests (file conflict the architect didn't foresee), re-run the overlapping components sequentially (re-launch them one at a time, in `STATE.md` order, so each sees the previous one's output; in-memory only — no ARCHITECTURE.md rewrite). Flag to the user: "M2 and M3 both modified `utils/auth.ts` — re-ran sequentially to reconcile." The reconciled manifest + conformance tables become the tester's input.
   (Verification is deferred to step 5 — ONE feature-level pass.)
5. **TEST** (only if ≥1 component was implemented; runs ONCE for the whole feature): launch ONE `yasdd-tester` subagent with the feature slug + ARCHITECTURE.md path + the aggregated conformance tables (with file:line) + changed-files manifest + config values. It reads `ARCHITECTURE.md` (Testing section + Acceptance `[A#]`) + the manifest + conformance tables, writes unit + e2e tests, and runs checks ONCE (lint/typecheck/tests via bash, whole feature; commands from ARCHITECTURE's Testing section inherited from CONVENTIONS.md, falling back to runtime detection). It returns `FINISHED` + test manifest, or `ISSUES` + classified findings (test-bug vs impl-bug, attributed to components `[M#]`).
   - `FINISHED` → proceed to FINAL VERIFY (step 6).
   - `ISSUES` → FIX-LOOP (step 5b).
5b. **FIX-LOOP** (if tester returned ISSUES): read ARCHITECTURE + classified findings. Write a fix-plan INLINE in the implementer prompt (no FIX-PLAN.md file). Route findings to components via the changed-files manifest → `[M#]` mapping. Spawn `yasdd-implementer` subagent(s) for the affected component(s), passing: the fix-plan (inline text) + ARCHITECTURE.md path + affected component ID `[M#]` + prompt-injected "Run ALL checks: typecheck, compile, smoke test, e2e, unit tests. Fix until green. Prefer check commands from ARCHITECTURE's Testing section; fall back to detection only if empty." Route `impl-bug`s to the implementer for the attributed component; `test-bug`s to the implementer too (it can fix both code + tests during fix-loops). If a bug spans multiple components, route to all affected components in order. On `FINISHED` → re-run the TESTER → loop until the tester returns `FINISHED` (cap **3 rounds for the whole feature**).
   - After 3 rounds with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `SUMMARY.md` (feature blocked after 3 test rounds), mark still-failing components `test: FAIL (N impl-bugs)` in `STATE.md`, proceed to WRAP UP.
6. **FINAL VERIFY** (only if ≥1 component was implemented; runs ONCE for the whole feature): launch ONE `yasdd-verifier` subagent with the feature slug + ARCHITECTURE.md path + config values. It runs checks ONCE (unconditional rerun; commands from ARCHITECTURE's Testing section inherited from CONVENTIONS.md, falling back to runtime detection) across all changed files (code + tests) and reviews the whole feature diff for conformance against ARCHITECTURE.md (Rules/Cases/Acceptance by component `[M#]`) + full multi-track code review (including the tests written by the tester). It returns high-confidence findings (each attributed to a component `[M#]`, or `feature-wide`) or `NO_FINDINGS`.
   - `NO_FINDINGS` → proceed to WRAP UP (step 7).
   - Findings → group by the attributed component(s); ignore components already blocked. Re-launch `yasdd-implementer` **once per affected component, in `STATE.md` order**, passing ARCHITECTURE.md path + the component ID `[M#]` + the findings routed to it + prompt-injected "Run ALL checks. Prefer check commands from ARCHITECTURE's Testing section; fall back to detection only if empty." Then re-run FINAL VERIFY over the whole feature. Loop until `NO_FINDINGS` (cap **3 rounds for the whole feature**).
      - After 3 rounds with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `SUMMARY.md` (feature blocked after 3 verify rounds), mark still-failing components `verify: FAIL` in `STATE.md`, proceed to WRAP UP.
7. **WRAP UP**: read the final `STATE.md`. If there are implemented components:
   - Update `PROJECT-STATE.md` status (e.g., `done`) and add a SUMMARY link: `— SUMMARY: .yasdd/features/<slug>/SUMMARY.md`.

## Rules
- Handoffs are file references (pass slug/paths/component IDs, not big text). Stay terse.
- For skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
- Disable watchers/git hooks during parallel implementation (disjoint file sets prevent write races, but watchers may contend).

## Arguments

$ARGUMENTS
