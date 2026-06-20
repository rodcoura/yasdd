---
description: Start a single-shot quick win: discuss -> one fused spec -> implementation -> light review.
---
# /yasdd-quick-win

Start a lightweight, single-shot SDD flow for a small, self-contained change. Results live in `.yasdd/quick-wins/<slug>/` with only `DISCUSS.md`, `SPEC.md`, and `SUMMARY.md`.

You are the orchestrator. Read `.yasdd/config.yml` once at the start (create it with `autoMode: false`, `maxParallelism: 3`, and `maxSpecs: 5` if missing). `autoMode` drives step 3; `maxParallelism` caps parallel subagent calls in DISCUSS and the verifier track. `maxSpecs` is ignored for quick wins (always exactly one `SPEC.md`).

## Pipeline
0. Read `.yasdd/config.yml` (create with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5` if missing) and keep its values in context.
1. **DISCUSS** (main session, skill `yasdd-quick-discuss`): run batched elicitation until gaps closed. The skill may launch up to `maxParallelism` `explore` subagents in parallel for codebase-first investigation. Writes `.yasdd/quick-wins/<slug>/DISCUSS.md`.
2. **SPEC** (subagent, skill `yasdd-quick-spec`): launch a `general` subagent with slug + config values; tell it to read `.yasdd/quick-wins/<slug>/DISCUSS.md` and write `.yasdd/quick-wins/<slug>/SPEC.md` using the fused format. Briefly report its outcome to the user.
3. **PLAN IMPLEMENTATION**:
   - `autoMode: false`: ask the user (question tool) whether to proceed with implementing the quick win now; wait for confirmation.
   - `autoMode: true`: auto-proceed; no question.
4. **IMPLEMENTATION** (subagent, skill `yasdd-implementer`, quick-win override):
   - Launch ONE `general` subagent and pass slug + config values with this override:
     ```
     This is a QUICK WIN. Read the spec at .yasdd/quick-wins/<slug>/SPEC.md
     (NOT specs/NN-*.md). Write SUMMARY.md to .yasdd/quick-wins/<slug>/SUMMARY.md
     (NOT .yasdd/features/<slug>/SUMMARY.md). Do NOT read or write STATE.md
     or PROJECT-STATE.md — they do not exist for quick wins.
     ```
   - The implementer returns `FINISHED` + one-line summary + conformance table, or `ISSUES` + brief issues.
     - `FINISHED` → proceed to review (step 5).
     - `ISSUES` → `autoMode: false`: surface the issues to the user and pause for direction. `autoMode: true`: append a one-line blocked note under `## Business` in `.yasdd/quick-wins/<slug>/SUMMARY.md`, report the blocker, and stop.
5. **CODE REVIEW** (subagent, skill `yasdd-verifier`, lighter quick-win override):
   - Launch ONE `general` subagent with slug + config values + this override:
     ```
     This is a QUICK WIN. Run ONLY: (1) the tests-green gate (step 0), and
     (2) the business-logic track + spec conformance against
     .yasdd/quick-wins/<slug>/SPEC.md. Spawn at most ONE explore subagent for
     the business-logic track. Skip security, performance, deploy-safety,
     duplication, and dead-code tracks. Report findings or NO_FINDINGS using
     the standard output format.
     ```
   - If the verifier returns `NO_FINDINGS`, the quick win is done.
   - If the verifier returns findings, re-launch the implementer for the SAME quick win with the findings, then re-verify. Loop until `NO_FINDINGS` or until 3 review attempts have been made.
     - After 3 attempts with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `.yasdd/quick-wins/<slug>/SUMMARY.md`, report the blocker, and stop.
6. **WRAP UP**: report the outcome to the user and point to `.yasdd/quick-wins/<slug>/SUMMARY.md`.

## Rules
- All artifacts live under `.yasdd/quick-wins/<slug>/`. Never write to `.yasdd/features/<slug>/`, `STATE.md`, or `PROJECT-STATE.md`.
- Handoffs are file references (pass slug/paths, not big text). Stay terse.
- For commands/skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
- The implementer/verifier are reused with quick-win overrides so they do not fall back to full-SDD paths or multi-track behavior.
