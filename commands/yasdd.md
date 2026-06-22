---
description: Start a lean SDD feature: discuss -> design -> testing -> specs -> state, then offer to implement.
---
# /yasdd

Load the skill `yasdd-discuss` (skill tool) and run the Discuss phase for a new feature.

You are the orchestrator. Read `.yasdd/config.yml` once at the start (create it with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5`, and an empty `gate: { testCmd: "", lintCmd: "", typecheckCmd: "" }` block if missing). `autoMode` drives steps 4-7; `maxParallelism` caps parallel subagent calls per step (DISCUSS yasdd-spy, IMPLEMENT batch size, verifier tracks); `maxSpecs` caps specs generated in step 3.

Subagents are launched ONLY for the IMPLEMENT (step 5), TEST (step 6), FIX-LOOP (step 6b), and FINAL VERIFY (step 7) phases. DESIGN (step 2), TESTING (step 2b), and SPECS (step 3) run in the MAIN session, reusing the codebase context loaded during DISCUSS — zero re-exploration. For each subagent role, launch the harness's existing subagent (Task tool, `subagent_type: general`) with a prompt: "Load the skill `yasdd-<role>` (skill tool; if unavailable, read `~/.agents/skills/yasdd-<role>/SKILL.md`) and follow it. Inputs: <slug + paths>. Config values from `.yasdd/config.yml`: `autoMode=<value>`, `maxParallelism=<value>`, `maxSpecs=<value>`, `gate.testCmd=<value>`, `gate.lintCmd=<value>`, `gate.typecheckCmd=<value>`. Use these values; do not re-read `config.yml`." After each subagent, briefly report its outcome to the user.

## Pipeline
0. Read `.yasdd/config.yml` (create with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5`, and an empty `gate: { testCmd: "", lintCmd: "", typecheckCmd: "" }` block if missing) and keep its values in context.
1. **DISCUSS** (main session, skill `yasdd-discuss`): run the grilling elicitation until gaps closed. The skill may launch up to `maxParallelism` `yasdd-spy` subagents in parallel for codebase-first investigation. Writes `DISCUSS.md`. Create `.yasdd/`, `config.yml`, and `PROJECT-STATE.md` (with `# Project State` heading and empty `## Features`) if missing.
2. **DESIGN** (main session, skill `yasdd-designer`): reuse DISCUSS context; load skill `yasdd-designer`, read `DISCUSS.md` (already in context), do targeted reads only. Writes `DESIGN.md` (partitions specs by module/file boundaries; declares file ownership per anticipated spec in `Components`).
2b. **TESTING** (main session, skill `yasdd-test-design`): reuse DESIGN context; load skill `yasdd-test-design`, read `DESIGN.md` (already in context), do targeted reads of test files for accuracy. Writes `TESTING.md` (test-architecture handoff: framework, runner cmd, unit test location, fixture strategy, e2e scope, acceptance mapping).
3. **SPECS** (main session, skill `yasdd-specs`): reuse DESIGN context; load skill `yasdd-specs`, read `DESIGN.md` (already in context), do targeted reads only. Writes 1 to `maxSpecs` specs (each spec's `Refs` declares its module/file scope for parallel batch computation) + `MANIFEST.md` + `STATE.md` + updates `PROJECT-STATE.md`.
4. **PLAN IMPLEMENTATION**:
   - `autoMode: false`: read `STATE.md`, list unimplemented specs, ask the user (question tool) how many/which to implement now; chosen set = selection.
   - `autoMode: true`: implement ALL specs (no question); chosen set = every spec in `STATE.md`, in order.
   - **Compute parallel batches** using `.yasdd/features/<slug>/MANIFEST.md` first: read its `Spec`, `File`, `Dependencies` columns; specs with disjoint `File` sets AND no `Dependencies` edge between them → same batch (cap at `maxParallelism`). If the manifest is missing or stale, fall back to computing inline from spec `Refs` + DESIGN's `Components`. If no parallelism possible → single-spec batches (sequential, same as today). After each batch, update the manifest's `Status` column. Present the batch plan to the user.
   - **Gate command handoff:** pass the `gate.*Cmd` values from `.yasdd/config.yml` (if non-empty) to each implementer/tester/verifier subagent so they do not re-detect commands.
5. **IMPLEMENT LOOP** (parallel per batch, code-only, no gate):
   a. `todowrite`: one todo per chosen spec.
   b. For each batch: launch up to `maxParallelism` implementer subagents (skill `yasdd-implementer`) in PARALLEL, one per spec in the batch. Each implementer returns `FINISHED` + one-line summary + spec-conformance table (functioning DEFERRED) + changed-files manifest, or `ISSUES` + brief issues. The implementer already increments `SUMMARY.md` on either outcome. File ownership is disjoint within a batch (no write races).
      - `FINISHED` → mark spec `[x]` in `STATE.md`, update `MANIFEST.md` Status to `done`, bump count, update `PROJECT-STATE.md`. Collect the manifest + conformance table for the tester.
      - `ISSUES` → `autoMode: false`: surface the issues to the user and pause for direction. `autoMode: true`: mark spec as blocked in `STATE.md` (use `- [~]`), update `MANIFEST.md` Status to `blocked`, bump count, proceed.
   c. Next batch (sequential across batches, parallel within a batch).
   d. **Aggregate** manifests + conformance tables across all batches. **Validate disjointness**: no two specs in the same batch report the same file → if overlap detected, flag a partition violation (DESIGN failed to partition) and re-run those specs sequentially. The aggregated manifest + conformance tables become the tester's input.
   (Verification is deferred to step 6 — ONE feature-level pass.)
6. **TEST** (only if ≥1 spec was implemented; runs ONCE for the whole feature): launch ONE `yasdd-tester` subagent with the feature slug + the aggregated conformance tables (with file:line) + changed-files manifest + config values. It reads `TESTING.md` + the manifest + conformance tables + specs' Acceptance cases, writes unit + e2e tests, and runs the gate ONCE (lint/typecheck/tests via bash, whole feature). It returns `FINISHED` + test manifest, or `ISSUES` + classified findings (test-bug vs impl-bug, attributed to specs).
   - `FINISHED` → proceed to FINAL VERIFY (step 7).
   - `ISSUES` → FIX-LOOP (step 6b).
6b. **FIX-LOOP** (if tester returned ISSUES): read DESIGN + specs + classified findings. Write a fix-plan INLINE in the implementer prompt (no FIX-PLAN.md file). Spawn `yasdd-implementer` subagent(s) for the affected spec(s), in `STATE.md` order, passing: the fix-plan (inline text) + affected spec paths + prompt-injected "Run ALL checks: typecheck, compile, smoke test, e2e, unit tests. Fix until green. Prefer commands from `.yasdd/config.yml` gate.*Cmd; fall back to detection only if empty." (this instruction is NOT in the implementer skill — it's injected by the orchestrator). Route `impl-bug`s to the implementer for the attributed spec; `test-bug`s to the implementer too (it can fix both code + tests during fix-loops). If a bug spans multiple specs, route to all affected specs in order. On `FINISHED` → re-run the TESTER → loop until `NO_FINDINGS` (cap **3 rounds for the whole feature**).
   - After 3 rounds with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `SUMMARY.md` (feature blocked after 3 test rounds), mark still-failing specs `- [~]` in `STATE.md`, proceed to WRAP UP.
7. **FINAL VERIFY** (only if ≥1 spec was implemented; runs ONCE for the whole feature): launch ONE `yasdd-verifier` subagent with the feature slug + the list of just-implemented spec paths + config values. It runs the tests-green gate ONCE (unconditional rerun) across all changed files (code + tests) and reviews the whole feature diff for conformance against all implemented specs + full multi-track code review (including the tests written by the tester). It returns high-confidence findings (each attributed to a spec, or `feature-wide`) or `NO_FINDINGS`.
   - `NO_FINDINGS` → proceed to WRAP UP (step 8).
   - Findings → group by the attributed spec(s); ignore specs already blocked. Re-launch `yasdd-implementer` **once per affected spec, in `STATE.md` order**, passing that spec's path + the findings routed to it + prompt-injected "Run ALL checks. Prefer commands from `.yasdd/config.yml` gate.*Cmd; fall back to detection only if empty." (as in step 6b). Then re-run FINAL VERIFY over the whole feature. Loop until `NO_FINDINGS` (cap **3 rounds for the whole feature**).
      - After 3 rounds with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `SUMMARY.md` (feature blocked after 3 verify rounds), mark still-failing specs `- [~]` in `STATE.md`, proceed to WRAP UP.
8. **WRAP UP**: read the final `STATE.md`. If there are checked specs:
   - Update `PROJECT-STATE.md` status (e.g., `done`) and add a SUMMARY link: `— SUMMARY: .yasdd/features/<slug>/SUMMARY.md`.

## Rules
- Handoffs are file references (pass slug/paths, not big text). Stay terse.
- For commands/skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
- Disable watchers/git hooks during parallel implementation (disjoint file sets prevent write races, but watchers may contend).

## Arguments

$ARGUMENTS
