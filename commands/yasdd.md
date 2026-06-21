---
description: Start a lean SDD feature: discuss -> design -> specs -> state, then offer to implement.
---
# /yasdd

Load the skill `yasdd-discuss` (skill tool) and run the Discuss phase for a new feature.

You are the orchestrator. Read `.yasdd/config.yml` once at the start (create it with `autoMode: false`, `maxParallelism: 3`, and `maxSpecs: 5` if missing). `autoMode` drives steps 4-6; `maxParallelism` caps parallel subagent calls per step; `maxSpecs` caps specs generated in step 3.

For each subagent role, launch the harness's existing subagent (Task tool, `subagent_type: general`) with a prompt: "Load the skill `yasdd-<role>` (skill tool; if unavailable, read `~/.agents/skills/yasdd-<role>/SKILL.md`) and follow it. Inputs: <slug + paths>. Config values from `.yasdd/config.yml`: `autoMode=<value>`, `maxParallelism=<value>`, `maxSpecs=<value>`. Use these values; do not re-read `config.yml`." After each subagent, briefly report its outcome to the user.

## Pipeline
0. Read `.yasdd/config.yml` (create with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5` if missing) and keep its values in context.
1. **DISCUSS** (main session, skill `yasdd-discuss`): run the grilling elicitation until gaps closed. The skill may launch up to `maxParallelism` `explore` subagents in parallel for codebase-first investigation. Writes `DISCUSS.md`. Create `.yasdd/`, `config.yml`, and `PROJECT-STATE.md` (with `# Project State` heading and empty `## Features`) if missing.
2. **DESIGN** (subagent, skill `yasdd-designer`): pass slug + config values; reads `DISCUSS.md`, writes `DESIGN.md`.
3. **SPECS** (subagent, skill `yasdd-specs`): pass slug + config values; reads `DESIGN.md`, writes 1 to `maxSpecs` specs + `STATE.md` + updates `PROJECT-STATE.md`.
4. **PLAN IMPLEMENTATION**:
   - `autoMode: false`: read `STATE.md`, list unimplemented specs, ask the user (question tool) how many/which to implement now; chosen set = selection.
   - `autoMode: true`: implement ALL specs (no question); chosen set = every spec in `STATE.md`, in order.
5. **IMPLEMENT LOOP** (per chosen spec, in `STATE.md` order, SEQUENTIAL, never parallel):
   a. `todowrite`: one todo per chosen spec.
   b. Implementer subagent (skill `yasdd-implementer`) for spec N. It returns `FINISHED` + one-line summary + conformance table, or `ISSUES` + brief issues. The implementer already increments `SUMMARY.md` on either outcome.
      - `FINISHED` → mark spec N `[x]` in `STATE.md`, bump count, update `PROJECT-STATE.md`, proceed to next spec (no per-spec verify).
      - `ISSUES` → `autoMode: false`: surface the issues to the user and pause for direction. `autoMode: true`: mark spec N as blocked in `STATE.md` (use `- [~]`), bump count, proceed to next spec.
   c. Next spec. (Verification is deferred to step 6 — ONE feature-level pass.)
6. **FINAL VERIFY** (only if ≥1 spec was implemented; runs ONCE for the whole feature): launch ONE `yasdd-verifier` subagent with the feature slug + the list of just-implemented spec paths + config values. It runs the tests-green gate ONCE across all changed files and reviews the whole feature diff for conformance against all implemented specs + full multi-track code review. It returns high-confidence findings (each attributed to a spec, or `feature-wide`) or `NO_FINDINGS`.
   - `NO_FINDINGS` → proceed to WRAP UP (step 7).
   - Findings → group by the attributed spec(s); ignore specs already blocked. Re-launch `yasdd-implementer` **once per affected spec, in `STATE.md` order**, passing that spec's path + the findings routed to it. Then re-run FINAL VERIFY over the whole feature. Loop until `NO_FINDINGS` (cap **3 rounds for the whole feature**).
     - After 3 rounds with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `SUMMARY.md` (feature blocked after 3 verify rounds), mark still-failing specs `- [~]` in `STATE.md`, proceed to WRAP UP.
7. **WRAP UP**: read the final `STATE.md`. If there are checked specs:
   - Update `PROJECT-STATE.md` status (e.g., `done`) and add a SUMMARY link: `— SUMMARY: .yasdd/features/<slug>/SUMMARY.md`.

## Rules
- Handoffs are file references (pass slug/paths, not big text). Stay terse.
- For commands/skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.

## Arguments

$ARGUMENTS