---
name: yasdd-plan
description: "Tiered grilling + codebase exploration → single PLAN.md. One question at a time with recommended answer, challenge vague terms, cross-check claims vs code. Detects impacted existing tests. Runs in the MAIN session with the user."
disable-model-invocation: true
---
# yasdd-plan

Runs in the MAIN session with the user. Turn a vague request into a PRAGMATIC gap-free PLAN.md before implementation.

## Process

1. **Confirm slug.** Create `.yasdd/`, `.yasdd/features/<slug>/` if missing. Read `.yasdd/config.yml` for `autoMode`, `maxParallelism`, and `explorerAgentName`; if missing, use defaults `autoMode: false`, `maxParallelism: 3`, `explorerAgentName: ""` (do NOT create config.yml — only `yasdd-feature` creates it). Capture the verbatim user request at the top of PLAN.md under `## Request constraints`.

2. **EXPLORE:** codebase investigation via the `yasdd-spy` skill. How it runs depends on `explorerAgentName`:
   - **If `explorerAgentName` is set:** launch that named subagent (up to `maxParallelism` in parallel when scope is uncertain; 1 default), passing the main feature request + instruction to load the `yasdd-spy` skill (skill tool; if unavailable, read `~/.agents/skills/yasdd-spy/SKILL.md`). Assign each a DISTINCT concern area (see below).
   - **If `explorerAgentName` is empty:** load the `yasdd-spy` skill directly in this MAIN session (skill tool; if unavailable, read `~/.agents/skills/yasdd-spy/SKILL.md`) and perform the exploration inline. Run the concern areas sequentially (no parallelism in-session).

   **Concern areas** (assign per spy or explore each in turn):
   - **Area 1 — Data shapes & entities:** existing types, schemas, models, migrations, storage shapes touched by the feature.
   - **Area 2 — Interfaces & happy-path flows:** existing endpoints, handlers, call chains, user-facing flows the feature extends or parallels.
   - **Area 3 — Patterns, conventions & dependencies:** reusable functions/types, analogous features as implementation templates, cross-cutting concerns.
   If `maxParallelism < 3`, collapse lower-priority areas into the available spies (keep Area 1 + Area 2 first). Goal: ground every subsequent question in what the code actually does today.
   - **Greenfield detection:** if the exploration (subagent or in-session) returns "greenfield — no existing source files found", treat as greenfield. Inject a "Technical environment decision" sub-step into the question batch: decide language, framework, test runner, lint tool, directory structure. If `.yasdd/CONVENTIONS.md` already exists, inherit it. If not, these decisions will seed CONVENTIONS.md (step 5).
   - **Test impact detection:** for each source file the feature will touch, check whether a corresponding test file exists by the project's convention (read CONVENTIONS.md's `Test location` glob; e.g. colocated `foo.ts` → `foo.test.ts`, or separate `foo.ts` → `tests/test_foo.py`). Record existing test files → they go into PLAN.md's `Test impact: IMPACTED` section.

3. **GRILL:** ask one question at a time via the `question` tool, each with your recommended answer. Inspect the codebase and available local context before asking questions that can be answered without the user. Walk down each branch of the design tree, resolving dependencies between decisions one by one. Each question MUST:
   - **Carry rich codebase CONTEXT** — what the code currently does (file:line), what the exploration found, the existing pattern/type at play — so the developer understands it without needing code awareness.
   - **Be open-ended + genuinely curious.** Frame questions to invite explanation, not yes/no.
   - **Offer a recommended answer** — grounded in code evidence — but invite correction.
   - **Challenge vague terms** such as "user", "account", "tenant", "job", "workflow", "session", or "state" until their meaning is precise in this codebase.
   - **Cross-check user claims against the actual code.** If they conflict, call out the contradiction directly.
   Wait for the answer before forming the next question. If a question can be answered by exploring the codebase, EXPLORE instead of asking.

4. **WRITE PLAN.md:** single artifact at `.yasdd/features/<slug>/PLAN.md` using this dense structure (no prose padding):

   ```md
   # Plan: <feature>

   ## Goal & success measures
   <testable success criteria>

   ## Request constraints
   - <each explicit constraint/requirement from the verbatim request, one item>

   ## Approach
   <2-4 sentences: how it works, key decisions>

   ## Steps
   1. [M1] <component> — files: file1.ts, file2.ts — deps: none — *parallel with step 3*
   2. [M2] <component> — files: file3.ts — deps: M1 — *depends on step 1*
   3. [M3] <component> — files: file4.ts — deps: none — *parallel with step 1*
   (Inline markers: *parallel with N* = can run alongside step N; *depends on N* = must run after step N.)

   ## Data
   <new/changed shapes, field-level, deltas only>

   ## Interfaces
   <full signatures (name/params/return), deltas only>

   ## Rules
   - [R1] <rule text>
   - [R2] <rule text>

   ## Cases
   - [C1] when X -> Y
   - [C2] when Z -> W

   ## Acceptance
   - [A1] Given X When Y Then Z
   - [A2] Given A When B Then C

   ## Test impact
   ### NEW (tests to write — owned by tester)
   - [A1] <test file>: "<case description>"
   - [C1] <test file>: "<case description>"
   ### IMPACTED (existing tests — must stay green, owned by tester to confirm)
   - <source file> → <test file> (<functions/cases covered>)
   (If no existing test files are touched, write "IMPACTED: none".)

   ## Critical files
   - path/to/file1.ts
   - path/to/file2.ts
   - path/to/file3.ts

   ## Verification
   1. <specific verification steps — run commands, test cases, etc.>

   ## Out of scope
   <non-goals>
   ```

   **Self-sufficiency contract:** `Data` and `Interfaces` MUST be concrete enough to quote verbatim into implementation — field-level shapes (entity/field/type, NEW and CHANGED) and full signatures (name/params/return), not vague references. The implementer must not need any file other than PLAN.md to resolve a type or signature.

   **Anchor rules:** IDs are stable — if a line is reworded, keep its existing `[M#]` / `[R#]` / `[C#]` / `[A#]`. Never renumber. Each Rule/Case/Acceptance item gets a unique anchor.

5. **VALIDATE:** read PLAN.md against the user request.
   - **Traceability:** every `## Request constraints` item is addressed by at least one `[R#]` / `[C#]` / `[A#]` / `[M#]`. None silently dropped or reframed.
   - **Intent coverage:** the plan concretely solves the stated problem (Goal & success measures), not just structurally valid.
   - **Gap check:** no ambiguity that would force the implementer to guess intent. No open questions leaked into the plan.
   - **Test impact complete:** every changed source file with an existing test file is listed under `Test impact: IMPACTED`.
   - **Self-sufficiency:** Data is field-level; Interfaces have name/params/return; component deps reference other `[M#]`'s data/interfaces by anchor.
   Read the critical files to confirm the plan is grounded. If gaps: ask one clarifying question at a time (with recommended answer), inline-patch PLAN.md, re-validate. Keep planning until the important design decisions are resolved or explicitly marked out of scope.

6. **SEED CONVENTIONS.md (greenfield only):** if greenfield was detected AND `.yasdd/CONVENTIONS.md` does not exist, write it from the technical-environment decisions made in step 2:
   ```md
   # Project Conventions

   ## Tech stack
   Language: <e.g., TypeScript 5.4>
   Framework: <e.g., Express 4, Next.js 14, FastAPI 0.110>
   Runtime: <e.g., Node 20, Python 3.12>

   ## Test
   Framework: <e.g., Vitest 1.6, pytest 8.2>
   Runner cmd: <e.g., npm test, pytest>
   Test location: <e.g., src/**/*.test.ts, tests/**/test_*.py>

   ## Quality gates
   Lint cmd: <e.g., npm run lint, ruff check>
   Typecheck cmd: <e.g., npm run typecheck, tsc --noEmit, mypy>

   ## Directory structure
   Source: <e.g., src/>
   Tests: <e.g., src/ (colocated), tests/ (separate)>
   Config: <e.g., .env, config/>
   ```
   If brownfield (source files exist) AND CONVENTIONS.md is absent → detect from `package.json`/`Makefile`/`AGENTS.md` + existing test files AND write `.yasdd/CONVENTIONS.md` so subsequent features inherit it.

7. **GATE:** present PLAN.md to the user. Ask: "Plan ready. Finalize and proceed to implementation, or continue refining?" On changes → apply, re-validate, re-present. Loop until the user accepts. Then return to the feature orchestrator (`yasdd-feature`), which proceeds to IMPLEMENT.

## Rules
- Ask one question at a time with a recommended answer. Inspect the codebase first.
- Challenge vague terms until precise in this codebase.
- Cross-check user claims against the actual code — surface contradictions directly.
- Dense + structured notes; never prose essays. Reference existing code by path.
- Never invent answers; record unknowns as open questions to resolve with the user.
- No inferring; if something is undecided, ask or flag it — don't assume.
- The ARCHITECTURE is self-sufficient: the implementer must not need any file other than PLAN.md.
- Check commands (Framework/Runner/Lint/Typecheck) live ONLY in CONVENTIONS.md — never echo them into PLAN.md.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- Ensure every decision makes sense in context before writing it down.
