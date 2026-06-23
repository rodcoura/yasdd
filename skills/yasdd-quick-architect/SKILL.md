---
name: yasdd-quick-architect
description: Fuses design + one lean architecture for a quick win. Writes only .yasdd/quick-wins/<slug>/ARCHITECTURE.md using simplified format (no Components/batches/[M#]); Testing section inherits CONVENTIONS.md. No STATE.md or PROJECT-STATE.md. Runs in the MAIN session reusing elicitation context.
---
# yasdd-quick-architect

Runs in the MAIN session. Reuse the elicitation context already loaded in this session; no subagent spawning. Read `.yasdd/quick-wins/<slug>/ELICITATION.md`. Read only the files referenced in the discussion for accuracy — do NOT scan the whole repo.

## CONVENTIONS.md inheritance

- If `.yasdd/CONVENTIONS.md` exists → inherit `Framework`, `Runner cmd`, `Lint cmd`, `Typecheck cmd` into the Testing section.
- If absent (brownfield) → detect from `package.json`/`Makefile`/`AGENTS.md` + existing test files AND write `.yasdd/CONVENTIONS.md` so subsequent features/quick-wins inherit.
- If greenfield → CONVENTIONS.md was already seeded by elicitation; inherit it.

1. Read `.yasdd/quick-wins/<slug>/ELICITATION.md` (context already loaded).
2. Write `.yasdd/quick-wins/<slug>/ARCHITECTURE.md` using the **simplified format** (no `Components` with `[M#]`, no `Parallel batches`, no `Non-functional` NFRs, no `Risks & mitigations` — quick wins are small enough that these add overhead without value):
   ```md
   # Quick Win: <title>
   Refs: <existing file paths + symbols reused/changed>
   Approach: <2-4 sentences: how it works, key decisions>
   Data: <deltas only, field-level>
   Interfaces: <endpoints/functions/signatures, deltas only>
   Goal: <1-2 sentences: what & why>
   Rules:
     - [R1] <rule text>
   Cases:
     - [C1] when X -> Y
   Acceptance:
     - [A1] Given X When Y Then Z
   Testing:
     Framework: <inherit from CONVENTIONS.md, or detect at runtime>
     Runner cmd: <inherit or detect>
     Lint cmd: <inherit or detect>
     Typecheck cmd: <inherit or detect>
   Out of scope: <non-goals for this quick win>
   ```
   **Anchor rules:** IDs are stable — if a line is reworded, keep its existing `[R#]` / `[C#]` / `[A#]`. Never renumber.

3. Reference existing code; never re-declare existing types.
4. Carry material non-functional requirements into the `Rules` section.

## Output location
- `.yasdd/quick-wins/<slug>/ARCHITECTURE.md`

## What NOT to create or update
- Do NOT create `.yasdd/features/<slug>/`.
- Do NOT create `STATE.md`.
- Do NOT create or update `PROJECT-STATE.md`.
- Do NOT create `CHANGES/`.

## Rules
- The architecture must be independently implementable (clear Data + Interfaces + Rules + Cases).
- **Functioning architecture**: after implementing this single architecture, the system works and the quick win's goal is met. No deferred work required.
- Cases = edge + error cases only. Acceptance = the happy path + each Case, all checkable by a test.
- Reference existing code; never re-declare existing types.
- Testing fields (Framework/Runner/Lint/Typecheck) are inherited from CONVENTIONS.md — never re-decide what's already there.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
