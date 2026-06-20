---
name: yasdd-quick-spec
description: Fuses design + one lean spec for a quick win. Writes only .yasdd/quick-wins/<slug>/SPEC.md; no STATE.md, PROJECT-STATE.md, or specs/.
---
# yasdd-quick-spec

Input: quick-win slug + config values (`autoMode`, `maxParallelism`, `maxSpecs`) passed in the subagent prompt. The spec at `.yasdd/quick-wins/<slug>/SPEC.md` will be used directly by the implementer.

1. Read `.yasdd/quick-wins/<slug>/DISCUSS.md`. Read only the files referenced in the discussion for accuracy — do NOT scan the whole repo.
2. Write `.yasdd/quick-wins/<slug>/SPEC.md` using this fused format:

   ```md
   # Quick Win: <title>

   Refs: <existing file paths + symbols reused/changed>
   Approach: <2-4 sentences: how it works, key decisions>
   Components: <new/changed modules, one line each>
   Data: <deltas only>
   Interfaces: <endpoints/functions/signatures, deltas only>
   Goal: <1-2 sentences: what & why>
   I/O: <inputs/outputs as references + deltas>
   Rules: <invariants that must always hold>
   Scenarios: <edge + error cases only: "when X -> Y">
   Acceptance: <Given/When/Then, happy path + one per Scenario; each checkable by a test>
   Out of scope: <non-goals for this quick win>
   ```

3. Reference existing code; never re-declare existing types.
4. Carry material non-functional requirements into the `Rules` section.

## Output location
- `.yasdd/quick-wins/<slug>/SPEC.md`

## What NOT to create or update
- Do NOT create `.yasdd/features/<slug>/`.
- Do NOT create `STATE.md`.
- Do NOT create or update `PROJECT-STATE.md`.
- Do NOT create `specs/NN-*.md`.

## Rules
- The spec must independently implementable (clear I/O + Rules + Scenarios).
- **Functioning spec**: after implementing this single spec, the system works and the quick win's goal is met. No deferred work required.
- Scenarios = edge + error cases only. Acceptance = the happy path + each Scenario, all checkable by a test.
- Reference existing code; never re-declare existing types.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the spec.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
