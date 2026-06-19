---
name: yasdd-specs
description: Decomposes a DESIGN.md into 1 to maxSpecs (default 5) lean specs (numbered, slugged), initializes the feature STATE.md, and registers the feature in PROJECT-STATE.md.
---
# yasdd-specs

Input: feature slug. Read `.yasdd/features/<slug>/DESIGN.md`.

1. Decide spec count (1 to `maxSpecs`, default 5) by cohesive concern; if tiny, 1 spec. Number in dependency/implementation order. Use the `maxSpecs` value provided in the subagent prompt; if `< 1` or missing, use `5`. The spec count must be within `1..maxSpecs`.
2. Write each spec to `.yasdd/features/<slug>/specs/NN-<spec-slug>.md` using the LEAN SPEC FORMAT:
   ```md
   # Spec: <title>
   Refs: <file paths + symbols reused/changed>
   Goal: <1-2 sentences: what & why>
   I/O: <inputs/outputs as references + deltas>
   Rules: <invariants that must always hold>
   Scenarios: <edge + error cases only: "when X -> Y">
   Acceptance: <Given/When/Then, one per key case: the spec's happy path (proves the system works standalone per the functioning-spec rule) + one per Scenario; each must be checkable by a test>
   Out of scope: <non-goals for THIS spec>
   ```
3. Create `.yasdd/features/<slug>/STATE.md` (see STATE formats below).
4. Update `.yasdd/PROJECT-STATE.md` (add/refresh the feature row).

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
- Each spec independently implementable (clear I/O + Rules + Scenarios).
- **Functioning spec**: after implementing a spec (given prior specs), the system works and that spec's goal is met on its own. No spec leaves the system half-built expecting a later spec to make it usable.
- **No overlap**: each Rule/Scenario/Interface delta belongs to exactly ONE spec. Cross-spec dependencies are expressed as `Refs` to prior specs' outputs, never duplicated rules. If two specs need the same concern, assign it to one and reference it from the other.
- Scenarios = edge + error cases only (no happy-path padding). Acceptance = the happy path + each Scenario as Given/When/Then, all checkable by a test. This makes the "functioning spec" rule verifiable, not self-reported.
- Carry DESIGN Non-functional items into the owning spec's Rules (assign to exactly one spec; reference from others). Never drop NFRs.
- Reference existing code; never re-declare existing types.
- Keep each spec small; split if one tries to cover too much.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the spec.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
