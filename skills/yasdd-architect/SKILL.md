---
name: yasdd-architect
description: Produces a pragmatic ARCHITECTURE.md from a feature's ELICITATION.md. Absorbs spec content (Rules/Cases/Acceptance with anchors) + testing architecture + parallel batch plan. 10-point self-check (cap 3 iterations). CONVENTIONS.md inheritance. Runs in the MAIN session reusing elicitation context.
disable-model-invocation: true
---
# yasdd-architect

Runs in the MAIN session. Reuse the codebase context loaded during elicitation; do NOT re-launch yasdd-spy subagents. Targeted reads of files referenced in ELICITATION.md only — for accuracy, not re-exploration. Read `.yasdd/features/<slug>/ELICITATION.md`.

## CONVENTIONS.md inheritance

Before writing ARCHITECTURE.md:
- If `.yasdd/CONVENTIONS.md` exists → **inherit** `Framework`, `Runner cmd`, `Lint cmd`, `Typecheck cmd` from it. Do NOT re-decide these values. Only write feature-specific fields (`Unit test location`, `Fixture strategy`, `E2E scope`, `Acceptance mapping`) in ARCHITECTURE's Testing section.
- If `.yasdd/CONVENTIONS.md` is absent (brownfield without init) → detect from `package.json`/`Makefile`/`AGENTS.md` + existing test files AND write `.yasdd/CONVENTIONS.md` with the detected values so subsequent features inherit. Then inherit into ARCHITECTURE.
- If greenfield (no source) → CONVENTIONS.md was already seeded by elicitation's technical-environment decision; inherit it.

## Write ARCHITECTURE.md

Write `.yasdd/features/<slug>/ARCHITECTURE.md` using this dense structure (no prose padding):

```md
# Architecture: <feature>
Refs: <existing file paths + symbols changed/extended>
Approach: <2-4 sentences: how it works, key decisions>
Components:
  - [M1] <component> — files: file1.ts, file2.ts — deps: none
  - [M2] <component> — files: file3.ts — deps: M1
  - [M3] <component> — files: file4.ts — deps: none
Parallel batches (maxParallelism=<N>):
  - Batch 1: [M1], [M3]  (disjoint files, no deps)
  - Batch 2: [M2]        (deps: M1)
Data: <new/changed shapes, field-level, deltas only>
Interfaces: <full signatures (name/params/return), deltas only>
Flow: <numbered happy path, terse>
Rules:
  - [R1] <rule text>
  - [R2] <rule text>
Cases:
  - [C1] when X -> Y
  - [C2] when Z -> W
Acceptance:
  - [A1] Given X When Y Then Z
  - [A2] Given A When B Then C
Testing:
  Framework: <test runner + version>            ← inherit from CONVENTIONS.md if present
  Runner cmd: <e.g., npm test, pytest, go test> ← inherit from CONVENTIONS.md if present
  Lint cmd: <e.g., npm run lint, ruff check>     ← inherit from CONVENTIONS.md if present
  Typecheck cmd: <e.g., npm run typecheck, tsc --noEmit, mypy> ← inherit from CONVENTIONS.md if present
  Unit test location: <convention per module>
  Fixture strategy: <shared fixtures, factories, mocks>
  E2E scope: <entry points + scenarios covered>
  Acceptance mapping: <how each [A#] maps to a test file/case>
Out of scope: <non-goals>
Risks & mitigations: <list>
Non-functional: <1-2 NFRs; note which component [M#] owns each>
```

### Token-cost awareness (no hard cap)

There is no hard cap on component count — it is decided naturally. However, include this awareness in your reasoning:

> **Component count awareness:** each `[M#]` component triggers one implementer invocation (~4,000–5,000 tokens each). If the component count exceeds 6, re-evaluate whether some components can merge (e.g., two tightly-coupled modules editing the same file set → one component). This is advisory, not a hard cap — complex features may legitimately need 8+ components.

### Anchor rules

IDs are stable — if a line is reworded, keep its existing `[M#]` / `[R#]` / `[C#]` / `[A#]`. Never renumber. Each Rule/Case/Acceptance item gets a unique `[R#]`, `[C#]`, or `[A#]`.

## 10-point self-check (cap 3 iterations)

After writing ARCHITECTURE.md, validate ALL 10 points:

1. **Disjointness**: all `[M#]` components have disjoint file sets (or explicit `deps:` making them sequential).
2. **Parallel batches valid**: every `[M#]` appears in exactly one batch; batches respect `maxParallelism`; deps satisfied by earlier batches; same-batch components have disjoint files.
3. **Rules concrete**: every `[R#]` is a testable invariant, not vague.
4. **Cases concrete**: every `[C#]` is a specific edge/error, not a category.
5. **Acceptance testable**: every `[A#]` is Given/When/Then, checkable by a test.
6. **Data field-level**: every shape has entity/field/type.
7. **Interfaces complete**: every signature has name/params/return.
8. **Flow complete**: happy path covers all components.
9. **Testing complete**: framework + commands specified (or inherited from CONVENTIONS.md); every `[A#]` maps to a test location.
10. **Component self-sufficiency**: every `[M#]` with `deps:` references another `[M#]`'s data/interfaces by anchor (e.g., `deps: M1 (Data: [M1] Account shape, Interfaces: [M1] AccountRepo)`), not vaguely — so the implementer doesn't need to guess dependency shapes.

If any fails → iterate ARCHITECTURE.md (don't emit, don't launch a reviewer). Loop until all 10 pass. **Iteration cap: 3.** If still failing after 3 iterations, emit ARCHITECTURE.md with a flagged `## Self-check warnings` section listing the failed points and proceed.

## Initialize STATE.md + PROJECT-STATE.md

After ARCHITECTURE.md is written (clean or with warnings):

Create `.yasdd/features/<slug>/STATE.md`:
```md
# Feature: <slug>

## Components
- [ ] [M1] <component> — files: file1.ts, file2.ts
  - impl: pending
  - test: pending
  - verify: pending
- [ ] [M2] <component> — files: file3.ts
  - impl: pending
  - test: pending
  - verify: pending

## Status
- architecture: done
- implementation: 0/N components
- testing: pending
- verification: pending
- last updated: <date>
```

Update `.yasdd/PROJECT-STATE.md` (add/refresh the feature row):
```md
- <slug> — .yasdd/features/<slug>/STATE.md — 0/N components — in-progress
```

## Rules
- Reference existing code; never re-describe it. Specify WHAT + constraints, not implementation minutiae.
- **Concrete Data + Interfaces (self-sufficiency contract):** `Data` and `Interfaces` MUST be concrete enough to quote verbatim into implementation — field-level shapes (entity/field/type, NEW and CHANGED) and full signatures (name/params/return), not vague references. The implementer must not need ELICITATION.md to resolve a type or signature.
- **Module-disjoint partitioning:** partition components by file/module boundaries. No two parallel-batch components edit the same source file. Components that must share a file become sequential dependencies (one writer at a time, across batches). Minimize cross-component file sharing by design.
- Pick the simplest approach that meets the elicitation; flag trade-offs only if material.
- Read only files referenced or needed for accuracy.
- Material Non-functional items must be carried into the owning component's Rules.
- Testing fields (Framework/Runner/Lint/Typecheck) are inherited from CONVENTIONS.md — never re-decide what's already there.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
