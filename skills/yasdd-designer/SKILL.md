---
name: yasdd-designer
description: Produces a pragmatic DESIGN.md from a feature's DISCUSS.md. References existing code, defines components/data/interfaces/risks, anticipates spec decomposition.
---
# yasdd-designer

Input: feature slug (from launch prompt) + config values (`autoMode`, `maxParallelism`, `maxSpecs`) passed in the subagent prompt. Read `.yasdd/features/<slug>/DISCUSS.md`.

Use the provided `maxSpecs` value (default 5) when estimating `Anticipated specs`. Do NOT read the whole repo.

Write `.yasdd/features/<slug>/DESIGN.md` using this dense structure (no prose padding):

```md
# Design: <feature>
Refs: <existing file paths + symbols changed/extended>
Approach: <2-4 sentences: how it works, key decisions>
Components: <new/changed modules, one line each>
Data: <new/changed shapes (reference existing types; deltas only)>
Interfaces: <endpoints/functions/signatures, deltas only>
Flow: <numbered happy path, terse>
Edge & errors: <list>
Risks & mitigations: <list>
Non-functional: <1-2 NFRs that shape the design: perf budget / threat surface / reliability target. "none material" if not applicable. If material, note which anticipated spec owns each.>
Testing: <what to test; key scenarios>
Anticipated specs: <rough count 1 to maxSpecs (default 5) and what each covers> (final count decided by yasdd-specs)
```

## Rules
- Reference existing code; never re-describe it. Specify WHAT + constraints, not implementation minutiae.
- **Concrete Data + Interfaces (self-sufficiency contract):** `Data` and `Interfaces` MUST be concrete enough to quote verbatim into specs — field-level shapes (entity/field/type, NEW and CHANGED) and full signatures (name/params/return), not vague references. Specs carry these forward; the implementer must not need DESIGN.md to resolve a type or signature.
- Pick the simplest approach that meets the discussion; flag trade-offs only if material.
- Read only files referenced or needed for accuracy.
- Material Non-functional items must be carried into the owning spec's Rules (enforced by yasdd-specs).

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the spec.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
