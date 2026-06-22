---
name: yasdd-specs
description: Decomposes a DESIGN.md into 1 to maxSpecs (default 5) lean specs (numbered, slugged), initializes the feature STATE.md, and registers the feature in PROJECT-STATE.md. Runs in the MAIN session reusing DESIGN context.
---
# yasdd-specs

Runs in the MAIN session. Reuse the DESIGN context already loaded in this session; targeted reads of files referenced in DESIGN.md only — for accuracy, not re-exploration. Read `.yasdd/features/<slug>/DESIGN.md`.

1. Decide spec count (1 to `maxSpecs`, default 5) by cohesive concern; if tiny, 1 spec. Number in dependency/implementation order. Use the `maxSpecs` value from `.yasdd/config.yml`; if `< 1` or missing, use `5`. The spec count must be within `1..maxSpecs`. Honor the module-disjoint partitioning from DESIGN's `Components` (no two parallel-batch specs edit the same source file).
2. Write each spec to `.yasdd/features/<slug>/specs/NN-<spec-slug>.md` using the LEAN SPEC FORMAT. Keep the spec a flat, dense page; add stable anchor IDs inline for cheap downstream referencing:
   ```md
   # [S1] Spec: <title>
   [S2] Refs: <file paths + symbols reused/changed — MUST declare the spec's module/file scope (files it creates/modifies) to enable the orchestrator's parallel batch computation>
   [S3] Goal: <1-2 sentences: what & why>
   [S4] I/O: <inputs/outputs as references + deltas>
   [S5] Data: <new/changed shapes (field-level: entity/field/type); deltas only; reference existing types>
   [S6] Interfaces: <function signatures / endpoints — full signatures (name/params/return), deltas only>
   [S7] Rules: <invariants that must always hold>
   - [R1] user id must be unique
   - [R2] token expiry > issue time
   [S8] Scenarios: <edge + error cases only>
   - [C1] when user id missing -> return 400
   - [C2] when token expired -> return 401
   [S9] Acceptance: <Given/When/Then, one per key case: the spec's happy path + one per Scenario>
   - [A1] Given valid user When POST /users Then 201
   - [A2] Given missing id When POST /users Then 400
   [S10] Out of scope: <non-goals for THIS spec>
   ```
   **Anchor rules:** IDs are stable — if a line is reworded, keep its existing `[S#]` / `[R#]` / `[C#]` / `[A#]`. Never renumber. Sections are `[S1]` through `[S10]`; each Rule/Scenario/Acceptance item gets a unique `[R#]`, `[C#]`, or `[A#]` within that spec.
3. Create `.yasdd/features/<slug>/MANIFEST.md` as a lightweight parallel-batch index:
   ```md
   # Manifest: <slug>

   | Spec | File | Dependencies | Status |
   |------|------|--------------|--------|
   | 01-<slug> | path/to/a.ts, path/to/b.ts | - | pending |
   | 02-<slug> | path/to/c.ts | 01-<slug> | pending |
   ```
   - `Spec`: the spec filename stem (no `.md`).
   - `File`: comma-separated files the spec creates/modifies (from its `Refs`).
   - `Dependencies`: other spec stems whose outputs this spec depends on, or `-` if none.
   - `Status`: `pending` / `done` / `blocked`.
   Orchestrators can compute batches by reading this one file instead of re-parsing every spec.
4. Create `.yasdd/features/<slug>/STATE.md` (see STATE formats below).
5. Update `.yasdd/PROJECT-STATE.md` (add/refresh the feature row).

## STATE formats

### `.yasdd/features/<slug>/STATE.md`
```md
# Feature: <slug>

## Specs
- [ ] 01-<spec-slug> — specs/01-<spec-slug>.md
- [ ] 02-<spec-slug> — specs/02-<spec-slug>.md

## Status
- authoring: done
- implementation: 0/2
- last updated: <date>
```

### `.yasdd/PROJECT-STATE.md`
Initial feature row:
```md
# Project State

## Features
- <slug> — .yasdd/features/<slug>/STATE.md — 0/2 specs implemented — in-progress
```
When the feature is done, the orchestrator appends a SUMMARY link to the row:
```md
- <slug> — .yasdd/features/<slug>/STATE.md — 2/2 specs implemented — done — SUMMARY: .yasdd/features/<slug>/SUMMARY.md
```

## Rules
- Each spec independently implementable (clear I/O + Data + Interfaces + Rules + Scenarios). The spec is **self-sufficient**: the implementer must not need DESIGN.md or DISCUSS.md to implement it.
- **File-scope Refs**: each spec's `Refs` must declare its module/file scope (files it creates/modifies) so the orchestrator can compute parallel batches with disjoint file sets. Specs whose `Refs` list another spec's outputs wait for that spec's batch (sequential dependency).
- **Functioning spec (parallel mode split):** spec-conformance is structural — the implementer self-verifies its work against the spec's Rules/Scenarios/Acceptance without building (checked per spec). Functioning (compile + acceptance happy path) is deferred to the TEST phase: the app is not buildable mid-parallel-flight while sibling specs may be half-written. The spec's Acceptance cases are still checkable by a test — just written + run at the TEST phase, not per spec.
- **No overlap**: each Rule/Scenario/Interface/Data delta belongs to exactly ONE spec. Cross-spec dependencies are expressed as `Refs` to prior specs' outputs, never duplicated rules. If two specs need the same concern, assign it to one and reference it from the other.
- Scenarios = edge + error cases only (no happy-path padding). Acceptance = the happy path + each Scenario as Given/When/Then, all checkable by a test. This makes the "functioning spec" rule verifiable, not self-reported.
- Carry DESIGN Non-functional items into the owning spec's Rules (assign to exactly one spec; reference from others). Never drop NFRs.
- Reference existing code; declare only NEW/CHANGED data shapes and interface signatures inline (carried from DESIGN). Never re-declare unchanged existing types.
- Keep each spec small; split if one tries to cover too much.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the spec.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
