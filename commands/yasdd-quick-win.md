---
description: Start a single-shot quick win: elicitation -> one fused architecture -> implementation -> test -> light review.
---
# /yasdd-quick-win

Start a lightweight, single-shot SDD flow for a small, self-contained change. Results live in `.yasdd/quick-wins/<slug>/` with only `ELICITATION.md`, `ARCHITECTURE.md`, and `SUMMARY.md`.

You are the orchestrator. Read `.yasdd/config.yml` once at the start (create it with `autoMode: false`, `maxParallelism: 3` if missing). `autoMode` drives the gate at step 3; `maxParallelism` caps parallel subagent calls in elicitation and the verifier track.

Subagents are launched ONLY for the IMPLEMENT (step 4), TEST (step 5), and VERIFY (step 6) phases. ARCHITECTURE (step 2) runs in the MAIN session, reusing the codebase context loaded during elicitation — zero re-exploration.

## Pipeline
0. Read `.yasdd/config.yml` (create with `autoMode: false`, `maxParallelism: 3` if missing) and keep its values in context.
1. **ELICITATION** (main session, skill `yasdd-quick-elicitation`): run core-only batched elicitation (8 sections, no extended) until gaps closed. The skill may launch up to `maxParallelism` `yasdd-spy` subagents in parallel for codebase-first investigation. Greenfield detection if quick-win on empty repo; seeds `CONVENTIONS.md` if greenfield. Writes `.yasdd/quick-wins/<slug>/ELICITATION.md`.
2. **ARCHITECTURE** (main session, skill `yasdd-quick-architect`): reuse elicitation context; load skill `yasdd-quick-architect`, read `.yasdd/quick-wins/<slug>/ELICITATION.md` (already in context), do targeted reads only. Writes `.yasdd/quick-wins/<slug>/ARCHITECTURE.md` using the simplified format (no Components/batches/[M#]). Testing section inherits from CONVENTIONS.md if present; if absent, detects + writes CONVENTIONS.md. Briefly report the outcome to the user.
3. **GATE**:
   - `autoMode: false`: ask the user (question tool) whether to proceed with implementing the quick win now; wait for confirmation.
   - `autoMode: true`: auto-proceed; no question.
4. **IMPLEMENTATION** (subagent, skill `yasdd-implementer`, quick-win override, code-only):
   - Launch ONE `general` subagent and pass slug + config values with this override:
     ```
     This is a QUICK WIN. Read the architecture at .yasdd/quick-wins/<slug>/ARCHITECTURE.md
     (NOT .yasdd/features/<slug>/ARCHITECTURE.md, and there is no [M#] component —
     implement the whole thing as one unit). Write SUMMARY.md to .yasdd/quick-wins/<slug>/SUMMARY.md
     (NOT .yasdd/features/<slug>/SUMMARY.md). Do NOT read or write STATE.md
     or PROJECT-STATE.md — they do not exist for quick wins.
     ```
   - The implementer is code-only (no tests, no checks). It returns `FINISHED` + one-line summary + conformance table (functioning DEFERRED) + changed-files manifest, or `ISSUES` + brief issues.
     - `FINISHED` → collect manifest + conformance table for the tester; proceed to TEST (step 5).
     - `ISSUES` → `autoMode: false`: surface the issues to the user and pause for direction. `autoMode: true`: append a one-line blocked note under `## Business` in `.yasdd/quick-wins/<slug>/SUMMARY.md`, report the blocker, and stop.
5. **TEST** (subagent, skill `yasdd-tester`, quick-win override):
   - Launch ONE `general` subagent with slug + config values + the implementer's conformance table + changed-files manifest + this override:
      ```
      This is a QUICK WIN. No STATE.md or component [M#] exists. Read the architecture at
      .yasdd/quick-wins/<slug>/ARCHITECTURE.md (Testing section + Acceptance [A#] anchors).
      Derive test architecture from ARCHITECTURE's Testing section (inherited from CONVENTIONS.md),
      or detect from package.json/Makefile/AGENTS.md if fields are empty. Write tests to
      .yasdd/quick-wins/<slug>/ or the project's standard test location. Run checks
      (lint/typecheck/tests) once. Return FINISHED + test manifest, or ISSUES with
      classified findings (test-bug vs impl-bug). Attribute findings to "quick-win" (no [M#]).
      ```
   - `FINISHED` → proceed to VERIFY (step 6).
   - `ISSUES` → FIX-LOOP: write a fix-plan inline, re-launch the implementer with the fix-plan + "Run ALL checks. Prefer check commands from ARCHITECTURE's Testing section; fall back to detection." prompt-injected, then re-run the tester. Loop until the tester returns `FINISHED` or 3 rounds. After 3 rounds: `autoMode: false` → surface to user and pause; `autoMode: true` → append blocked note, report, and stop.
6. **CODE REVIEW** (subagent, skill `yasdd-verifier`, lighter quick-win override):
   - Launch ONE `general` subagent with slug + config values + this override:
      ```
      This is a QUICK WIN. Run checks once (lint/typecheck/tests): use commands from
      .yasdd/quick-wins/<slug>/ARCHITECTURE.md's Testing section (inherited from CONVENTIONS.md),
      or detect from package.json/Makefile/AGENTS.md if fields are empty.

      Then run ONLY the business-logic track + architecture conformance against
      .yasdd/quick-wins/<slug>/ARCHITECTURE.md (use the [R#]/[C#]/[A#] anchors
      for precise references — there are no [M#] components for quick wins).
      Review code + tests (tests now exist from the TEST phase). Spawn at most ONE
      yasdd-spy subagent for the business-logic track. Skip security, performance,
      deploy-safety, duplication, and dead-code tracks. Attribute findings to
      "quick-win" (no [M#]). Report findings or NO_FINDINGS using the standard output format.
      ```
   - If the verifier returns `NO_FINDINGS`, the quick win is done.
   - If the verifier returns findings, re-launch the implementer for the SAME quick win with the findings + "Run ALL checks. Prefer check commands from ARCHITECTURE's Testing section; fall back to detection." prompt-injected, then re-verify. Loop until `NO_FINDINGS` or until 3 review attempts have been made.
      - After 3 attempts with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `.yasdd/quick-wins/<slug>/SUMMARY.md`, report the blocker, and stop.
7. **WRAP UP**: report the outcome to the user and point to `.yasdd/quick-wins/<slug>/SUMMARY.md`.

## Rules
- All artifacts live under `.yasdd/quick-wins/<slug>/`. Never write to `.yasdd/features/<slug>/`, `STATE.md`, or `PROJECT-STATE.md`.
- Handoffs are file references (pass slug/paths, not big text). Stay terse.
- For commands/skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
- The implementer/tester/verifier are reused with quick-win overrides so they do not fall back to full-SDD paths or multi-track behavior.
