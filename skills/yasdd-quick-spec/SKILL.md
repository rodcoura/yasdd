---
name: yasdd-quick-spec
description: Fuses design + one lean spec for a quick win. Writes only .yasdd/quick-wins/<slug>/SPEC.md; no STATE.md, PROJECT-STATE.md, or specs/. Runs in the MAIN session reusing DISCUSS context.
---
# yasdd-quick-spec

Runs in the MAIN session. Reuse the DISCUSS context already loaded in this session; no subagent spawning. Read `.yasdd/quick-wins/<slug>/DISCUSS.md`. Read only the files referenced in the discussion for accuracy — do NOT scan the whole repo.
1. Read `.yasdd/quick-wins/<slug>/DISCUSS.md` (context already loaded).
2. Write `.yasdd/quick-wins/<slug>/SPEC.md` using this fused format. Add stable anchor IDs inline for cheap downstream referencing (same scheme as full-feature specs):

   ```md
   # [S1] Quick Win: <title>

   [S2] Refs: <existing file paths + symbols reused/changed>
   [S3] Approach: <2-4 sentences: how it works, key decisions>
   [S4] Components: <new/changed modules, one line each>
   [S5] Data: <deltas only>
   [S6] Interfaces: <endpoints/functions/signatures, deltas only>
   [S7] Goal: <1-2 sentences: what & why>
   [S8] I/O: <inputs/outputs as references + deltas>
   [S9] Rules: <invariants that must always hold>
   - [R1] <rule text>
   - [R2] <rule text>
   [S10] Scenarios: <edge + error cases only>
   - [C1] when X -> Y
   - [C2] when Z -> W
   [S11] Acceptance: <Given/When/Then, happy path + one per Scenario; each checkable by a test>
   - [A1] Given X When Y Then Z
   - [A2] Given A When B Then C
   [S12] Out of scope: <non-goals for this quick win>
   ```
   **Anchor rules:** IDs are stable — if a line is reworded, keep its existing `[S#]` / `[R#]` / `[C#]` / `[A#]`. Never renumber.

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
