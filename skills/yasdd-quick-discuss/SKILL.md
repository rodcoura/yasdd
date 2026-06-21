---
name: yasdd-quick-discuss
description: Pragmatic batched elicitation for a quick win. Runs in the MAIN session, creates only .yasdd/quick-wins/<slug>/DISCUSS.md, no STATE.md or PROJECT-STATE.md updates.
---
# yasdd-quick-discuss

You run in the MAIN session with the user. Turn a vague quick-win request into a gap-free understanding before a single fused spec is written.

## Process
1. Confirm the kebab-case slug for the quick win. Create `.yasdd/` (if missing), `.yasdd/quick-wins/<slug>/`, and `DISCUSS.md` if missing. Read `.yasdd/config.yml` for `maxParallelism`; if missing, create it with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5`.
2. **Initial investigation:** use `codebase_search` + launch up to `maxParallelism` `explore` subagents in parallel (fallback `general`). Goal: identify the FULL initial question set covering every aspect/branch needed to implement the quick win.
3. **Ask ALL initial questions at once (ONE batch):** present the complete list in a single `question` tool call (array of question objects), each with a clearly-marked RECOMMENDED answer so the user can accept/reject/refine. Explicitly NOT one-at-a-time. Wait for all answers.
4. Record dense structured notes to `.yasdd/quick-wins/<slug>/DISCUSS.md` under headings: Goal & why, Data shapes, Interface contracts, Happy-path flow, Constraints, Edge & error cases, Dependencies on existing code, Non-goals, Unknowns (bullets, not prose). Keep an explicit `## Open questions` list; close resolved items. The three new headings must be concrete enough to quote into the spec:
   - **Data shapes**: entities/fields/types — NEW and CHANGED (reference existing types; deltas only).
   - **Interface contracts**: function signatures / endpoints — full signatures, not vague references.
   - **Happy-path flow**: the normal path, step by step (terse numbered), so the spec doesn't have to infer it.
5. **Continue the DISCUSS loop in BATCHED rounds:** re-analyze for remaining gaps, inferences, misunderstandings, and unconnected information. For each round, collect ALL newly-discovered questions into ONE batch and ask them together via a single `question` call (never one-at-a-time), each with a recommended answer. If a question can be answered by exploring the codebase, EXPLORE instead of asking. Append notes; close/open Open-question items; add newly discovered ones. Ground the discussion in explorer findings.
6. **Stop when ALL hold:** Open questions empty AND every category has concrete (non-vague) content AND no inferences remain AND no misunderstandings AND all information is connected.
7. **Final add-anything check:** ask the user (question tool): "Is there anything else you want to add to the discussion that should go into the spec?" If yes, capture it and loop back to step 5 for those items. If no, proceed.
8. Write a final `## Summary` (handoff to spec) and tell the user you're ready to write the quick-win spec.

## Output location
- `.yasdd/quick-wins/<slug>/DISCUSS.md`

## What NOT to create or update
- Do NOT create `.yasdd/features/<slug>/`.
- Do NOT create `STATE.md`.
- Do NOT create or update `PROJECT-STATE.md`.
- Do NOT create `specs/`.

## Rules
- Ask questions in BATCHES (all current open questions per round in one `question` call); never one-at-a-time.
- Dense + structured; never prose essays. Reference existing code by path.
- Never invent answers; record unknowns as open questions.
- Don't over-elicit; be pragmatic — but don't stop until gaps, inferences, misunderstandings, and unconnected information are resolved.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
