---
name: yasdd-goback
description: "Update an implemented feature. Loads the feature SUMMARY + ARCHITECTURE, asks all change-related questions in batches (elicitation-style, codebase-first) about the desired change, writes ONE new CHANGES/NN delta in ARCHITECTURE format, and updates STATE.md + PROJECT-STATE.md so it acts like a component still to implement."
disable-model-invocation: true
---
# yasdd-goback

Input: feature slug (`$1`). Run in the MAIN session with the user.

## Process
1. Read `.yasdd/features/<slug>/SUMMARY.md`, `ARCHITECTURE.md`, and `STATE.md` into context. If missing, STOP and tell the user. Read `.yasdd/config.yml` for `maxParallelism` (default 3).
2. GRILL the user about the desired change using the elicitation batched style: ask ALL initial questions about the desired change in ONE batch (each with a RECOMMENDED answer), then continue in BATCHED rounds (single `question` call per round) until the change is fully resolved — gaps, inferences, misunderstandings closed. Explore the codebase instead of asking when the code can answer. Launch up to `maxParallelism` `yasdd-spy` subagents in PARALLEL (Task tool, `subagent_type: yasdd-spy`; fallback `general`) with focused questions. Never exceed `maxParallelism` parallel subagent calls. Cover: what to update/change, why, affected I/O, edge cases, non-goals. Do NOT re-design the whole feature.
3. When the change is concrete, write ONE change delta to `.yasdd/features/<slug>/CHANGES/NN-<change-slug>.md` (NN = next number after the last change, or 01 if none) using the ARCHITECTURE-format delta:
   ```md
   # Change NN: <title>
   Base: .yasdd/features/<slug>/ARCHITECTURE.md
   New components:
     - [M3] <component> — files: file4.ts — deps: M1
   New rules:
     - [R3] <rule text>
   New cases:
     - [C3] when X -> Y
   New acceptance:
     - [A3] Given X When Y Then Z
   New testing:
     - [A3] → tests/file4.test.ts
   Modified components:
     - [M1] add file4.ts to scope
   Out of scope: <non-goals for this change>
   ```
   Use the next available `[M#]` number (do NOT reuse existing component numbers — new components get fresh IDs). Reference existing code by path.
4. Update `.yasdd/features/<slug>/STATE.md`: append the new component under `## Components` with `impl`/`test`/`verify: pending`; bump `implementation` denominator; set status `in-progress`; update `last updated`.
5. Update `.yasdd/PROJECT-STATE.md`: refresh the feature row (count + status `in-progress`).
6. Tell the user to run `/yasdd-implement <slug>` to implement the new component.

## Rules
- One new change delta only; do not decompose further.
- Reuse the ARCHITECTURE-format delta; reference existing code by path.
- New components get fresh `[M#]` IDs (never reuse existing ones).

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
