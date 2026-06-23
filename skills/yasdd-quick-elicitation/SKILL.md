---
name: yasdd-quick-elicitation
description: Core-only batched elicitation for a quick win. Runs in the MAIN session, creates only .yasdd/quick-wins/<slug>/ELICITATION.md (8 core sections, no extended), no STATE.md or PROJECT-STATE.md updates.
---
# yasdd-quick-elicitation

You run in the MAIN session with the user. Turn a vague quick-win request into a gap-free understanding before a single fused architecture is written.

## Process
1. Confirm the kebab-case slug for the quick win. Create `.yasdd/` (if missing), `.yasdd/quick-wins/<slug>/`, and `ELICITATION.md` if missing. Read `.yasdd/config.yml` for `maxParallelism`; if missing, create it with `autoMode: false`, `maxParallelism: 3` (no `maxSpecs`).
2. **Initial investigation:** use `codebase_search` + launch up to `maxParallelism` `yasdd-spy` subagents in parallel (fallback `general`). Goal: identify the FULL initial question set covering every aspect/branch needed to implement the quick win.
   - **Greenfield detection:** if yasdd-spy returns "greenfield — no existing source files found", inject a "Technical environment decision" sub-step (language, framework, test runner, lint, directory structure). If `.yasdd/CONVENTIONS.md` already exists, inherit it. If not, seed it from these decisions (see step 7).
3. **Ask ALL initial questions at once (ONE batch):** present the complete list in a single `question` tool call (array of question objects), each with a clearly-marked RECOMMENDED answer so the user can accept/reject/refine. Explicitly NOT one-at-a-time. Wait for all answers.
4. Record dense structured notes to `.yasdd/quick-wins/<slug>/ELICITATION.md` under the **core-only** headings (8 sections, no extended): Problem & motivation, Goal & success measures, Data shapes, Interface contracts, Happy-path flow, Invariants, Acceptance criteria, Non-goals. Keep an explicit `## Open questions` list; close resolved items. The three headings must be concrete enough to quote into the architecture:
   - **Data shapes**: entities/fields/types — NEW and CHANGED (reference existing types; deltas only).
   - **Interface contracts**: function signatures / endpoints — full signatures, not vague references.
   - **Happy-path flow**: the normal path, step by step (terse numbered), so the architecture doesn't have to infer it.
5. **Continue the elicitation loop in BATCHED rounds:** re-analyze for remaining gaps, inferences, misunderstandings, and unconnected information. Each round checks for the 3 Christel & Kang problems (scope, understanding, volatility). For each round, collect ALL newly-discovered questions into ONE batch and ask them together via a single `question` call (never one-at-a-time), each with a recommended answer. If a question can be answered by exploring the codebase, EXPLORE instead of asking. Append notes; close/open Open-question items; add newly discovered ones. Ground the discussion in yasdd-spy findings.
6. **Stop when ALL hold:** Open questions empty AND every category has concrete (non-vague) content AND no inferences remain AND no misunderstandings AND all information is connected.
7. **Final add-anything check:** ask the user (question tool): "Is there anything else you want to add to the discussion that should go into the architecture?" If yes, capture it and loop back to step 5 for those items. If no, proceed.
8. **Seed CONVENTIONS.md (greenfield only):** if greenfield was detected AND `.yasdd/CONVENTIONS.md` does not exist, write it from the technical-environment decisions (same format as `yasdd-elicitation`).
9. Write a final `## Summary` (handoff to architecture) and proceed to write the quick-win architecture (skill `yasdd-quick-architect`).

## ELICITATION.md format (core-only)

```md
# Elicitation: <quick-win>
## Problem & motivation
## Goal & success measures
## Data shapes
## Interface contracts
## Happy-path flow
## Invariants
## Acceptance criteria
## Non-goals
## Open questions
## Summary
```

## Output location
- `.yasdd/quick-wins/<slug>/ELICITATION.md`

## What NOT to create or update
- Do NOT create `.yasdd/features/<slug>/`.
- Do NOT create `STATE.md`.
- Do NOT create or update `PROJECT-STATE.md`.
- Do NOT create `specs/` or `ARCHITECTURE.md` (the quick-architect writes the simplified ARCHITECTURE.md).

## Rules
- Ask questions in BATCHES (all current open questions per round in one `question` call); never one-at-a-time.
- Dense + structured; never prose essays. Reference existing code by path.
- Never invent answers; record unknowns as open questions.
- Don't over-elicit; be pragmatic — but don't stop until gaps, inferences, misunderstandings, and unconnected information are resolved.
- Core-only (8 sections, no extended) — quick wins are always core-only.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
