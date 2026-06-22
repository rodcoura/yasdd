---
description: Start a single-shot quick win: discuss -> one fused spec -> implementation -> test -> light review.
---
# /yasdd-quick-win

Start a lightweight, single-shot SDD flow for a small, self-contained change. Results live in `.yasdd/quick-wins/<slug>/` with only `DISCUSS.md`, `SPEC.md`, and `SUMMARY.md`.

You are the orchestrator. Read `.yasdd/config.yml` once at the start (create it with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5`, and an empty `gate: { testCmd: "", lintCmd: "", typecheckCmd: "" }` block if missing). `autoMode` drives step 3; `maxParallelism` caps parallel subagent calls in DISCUSS and the verifier track. `maxSpecs` is ignored for quick wins (always exactly one `SPEC.md`).

Subagents are launched ONLY for the IMPLEMENT (step 4), TEST (step 5), and VERIFY (step 6) phases. SPEC (step 2) runs in the MAIN session, reusing the codebase context loaded during DISCUSS — zero re-exploration.

## Pipeline
0. Read `.yasdd/config.yml` (create with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5`, and an empty `gate: { testCmd: "", lintCmd: "", typecheckCmd: "" }` block if missing) and keep its values in context.
1. **DISCUSS** (main session, skill `yasdd-quick-discuss`): run batched elicitation until gaps closed. The skill may launch up to `maxParallelism` `yasdd-spy` subagents in parallel for codebase-first investigation. Writes `.yasdd/quick-wins/<slug>/DISCUSS.md`.
2. **SPEC** (main session, skill `yasdd-quick-spec`): reuse DISCUSS context; load skill `yasdd-quick-spec`, read `.yasdd/quick-wins/<slug>/DISCUSS.md` (already in context), do targeted reads only. Writes `.yasdd/quick-wins/<slug>/SPEC.md` using the fused format. No TESTING.md (single spec). Briefly report the outcome to the user.
3. **PLAN IMPLEMENTATION**:
   - `autoMode: false`: ask the user (question tool) whether to proceed with implementing the quick win now; wait for confirmation.
   - `autoMode: true`: auto-proceed; no question.
4. **IMPLEMENTATION** (subagent, skill `yasdd-implementer`, quick-win override, code-only):
   - Launch ONE `general` subagent and pass slug + config values with this override:
     ```
     This is a QUICK WIN. Read the spec at .yasdd/quick-wins/<slug>/SPEC.md
     (NOT specs/NN-*.md). Write SUMMARY.md to .yasdd/quick-wins/<slug>/SUMMARY.md
     (NOT .yasdd/features/<slug>/SUMMARY.md). Do NOT read or write STATE.md
     or PROJECT-STATE.md — they do not exist for quick wins.
     ```
   - The implementer is code-only (no tests, no gate). It returns `FINISHED` + one-line summary + spec-conformance table (functioning DEFERRED) + changed-files manifest, or `ISSUES` + brief issues.
     - `FINISHED` → collect manifest + conformance table for the tester; proceed to TEST (step 5).
     - `ISSUES` → `autoMode: false`: surface the issues to the user and pause for direction. `autoMode: true`: append a one-line blocked note under `## Business` in `.yasdd/quick-wins/<slug>/SUMMARY.md`, report the blocker, and stop.
5. **TEST** (subagent, skill `yasdd-tester`, quick-win override):
   - Launch ONE `general` subagent with slug + config values + the implementer's conformance table + changed-files manifest + this override:
     ```
     This is a QUICK WIN. No TESTING.md exists. Derive test architecture from
     the project's existing test framework (package.json/Makefile/AGENTS.md
     + existing test files). Read the spec at .yasdd/quick-wins/<slug>/SPEC.md
     for Acceptance cases ([A#] anchors). Write tests to .yasdd/quick-wins/<slug>/
     or the project's standard test location. Run the gate (lint/typecheck/tests)
     once: prefer gate.*Cmd from .yasdd/config.yml if non-empty, falling back to
     package.json/Makefile/AGENTS.md detection if a slot is empty. Return
     FINISHED + test manifest, or ISSUES with classified findings
     (test-bug vs impl-bug).
     ```
   - `FINISHED` → proceed to VERIFY (step 6).
   - `ISSUES` → FIX-LOOP: write a fix-plan inline, re-launch the implementer with the fix-plan + "Run ALL checks. Prefer commands from `.yasdd/config.yml` gate.*Cmd; fall back to detection only if empty." prompt-injected, then re-run the tester. Loop until `NO_FINDINGS` or 3 rounds. After 3 rounds: `autoMode: false` → surface to user and pause; `autoMode: true` → append blocked note, report, and stop.
6. **CODE REVIEW** (subagent, skill `yasdd-verifier`, lighter quick-win override):
   - Determine gate behavior before launching: if the fix-loop (step 5) ran and changed files after the tester's gate, pass `RUN_GATE` to the verifier; otherwise (tester returned `FINISHED` on the first pass, no subsequent edits) pass `SKIP_GATE`.
   - Launch ONE `general` subagent with slug + config values + the gate directive + this override:
      ```
      This is a QUICK WIN. Gate directive: <RUN_GATE|SKIP_GATE>.
      - IF SKIP_GATE: skip the tests-green gate rerun; trust the tester's reported exit codes.
      - IF RUN_GATE: run the tests-green gate once (unconditional rerun) using the
        gate.*Cmd values from .yasdd/config.yml if non-empty, falling back to
        package.json/Makefile/AGENTS.md detection if a slot is empty.

       Then run ONLY the business-logic track + spec conformance against
       .yasdd/quick-wins/<slug>/SPEC.md (use the spec's [S#]/[R#]/[C#]/[A#] anchors
       for precise references). Review code + tests (tests now exist from
       the TEST phase). Spawn at most ONE yasdd-spy subagent for the business-logic
       track. Skip security, performance, deploy-safety, duplication, and dead-code
       tracks. Report findings or NO_FINDINGS using the standard output format.
      ```
   - If the verifier returns `NO_FINDINGS`, the quick win is done.
   - If the verifier returns findings, re-launch the implementer for the SAME quick win with the findings + "Run ALL checks. Prefer commands from `.yasdd/config.yml` gate.*Cmd; fall back to detection only if empty." prompt-injected, then re-verify. Loop until `NO_FINDINGS` or until 3 review attempts have been made.
      - After 3 attempts with remaining findings: `autoMode: false` → surface findings to the user and pause. `autoMode: true` → append a one-line blocked note under `## Business` in `.yasdd/quick-wins/<slug>/SUMMARY.md`, report the blocker, and stop.
7. **WRAP UP**: report the outcome to the user and point to `.yasdd/quick-wins/<slug>/SUMMARY.md`.

## Rules
- All artifacts live under `.yasdd/quick-wins/<slug>/`. Never write to `.yasdd/features/<slug>/`, `STATE.md`, or `PROJECT-STATE.md`.
- Handoffs are file references (pass slug/paths, not big text). Stay terse.
- For commands/skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
- The implementer/tester/verifier are reused with quick-win overrides so they do not fall back to full-SDD paths or multi-track behavior.
