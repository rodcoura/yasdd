---
name: yasdd-goback
description: Update an implemented feature. Loads the feature SUMMARY, asks all change-related questions in batches (DISCUSS-style, codebase-first) about the desired change, writes ONE new spec (NN+1), and updates STATE.md + PROJECT-STATE.md so it acts like a spec still to implement.
---
# yasdd-goback

Input: feature slug (`$1`). Run in the MAIN session with the user.

## Process
1. Read `.yasdd/features/<slug>/SUMMARY.md` (and `STATE.md`) into context. If missing, STOP and tell the user. Read `.yasdd/config.yml` for `maxParallelism` (default 3).
2. GRILL the user about the desired change using the updated DISCUSS batched style: ask ALL initial questions about the desired change in ONE batch (each with a RECOMMENDED answer), then continue in BATCHED rounds (single `question` call per round) until the change is fully resolved — gaps, inferences, misunderstandings closed. Explore the codebase instead of asking when the code can answer. Launch up to `maxParallelism` `yasdd-spy` subagents in PARALLEL (Task tool, `subagent_type: yasdd-spy`; fallback `general`) with focused questions. Never exceed `maxParallelism` parallel subagent calls. Cover: what to update/change, why, affected I/O, edge cases, non-goals. Do NOT re-design the whole feature.
3. When the change is concrete, write ONE new spec to `.yasdd/features/<slug>/specs/NN-<change-slug>.md` (NN = next number after the last spec) using the LEAN SPEC FORMAT with stable anchor IDs (`[S#]`/`[R#]`/`[C#]`/`[A#]`) — see `yasdd-specs` for the format. Include Refs/Goal/I/O/Data/Interfaces/Rules/Scenarios/Acceptance/Out of scope.
4. Update `.yasdd/features/<slug>/STATE.md`: append `- [ ] NN-<change-slug> — specs/NN-<change-slug>.md`; bump `implementation` denominator (e.g., 2/2 -> 2/3); set status `in-progress`; update `last updated`.
5. Update `.yasdd/features/<slug>/MANIFEST.md`: append a row for the new spec (`NN-<change-slug>` | its Refs files | dependencies or `-` | `pending`).
6. Update `.yasdd/PROJECT-STATE.md`: refresh the feature row (count + status `in-progress`).
7. Tell the user to run `/yasdd-implement <slug>` to implement the new spec.

## Rules
- One new spec only; do not decompose further.
- Reuse the existing lean spec format; reference existing code by path.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the spec.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
