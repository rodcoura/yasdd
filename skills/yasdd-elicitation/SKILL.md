---
name: yasdd-elicitation
description: "Tiered elicitation for a new feature. Runs in the MAIN session with the user. Asks all open questions in batches (with recommended answers, codebase-first) until gap-free understanding, then persists to .yasdd/features/<slug>/ELICITATION.md. Core 8 sections always; extended 10 if complex/greenfield."
disable-model-invocation: true
---
# yasdd-elicitation

You run in the MAIN session with the user. Turn a vague request into a gap-free understanding before architecture.

## Process
1. Confirm kebab-case slug. Create `.yasdd/`, `.yasdd/features/<slug>/`, and `ELICITATION.md` if missing. Create `.yasdd/PROJECT-STATE.md` (`# Project State` + empty `## Features`) if missing. Read `.yasdd/config.yml` for `maxParallelism`; if missing, create it with `autoMode: false`, `maxParallelism: 3`.
2. **Initial investigation:** launch up to `maxParallelism` `yasdd-spy` subagents in parallel. Goal: identify the FULL initial question set covering every aspect/branch of the design tree.
   - **Greenfield detection:** if yasdd-spy returns "greenfield — no existing source files found" (no source files in repo OR repo empty), treat as greenfield. Inject a "Technical environment decision" sub-step into the initial batch: decide language, framework, test runner, lint tool, directory structure. If `.yasdd/CONVENTIONS.md` already exists, inherit it instead of re-deciding. If not, these decisions will seed `CONVENTIONS.md` (see step 6).
3. **Ask ALL initial questions at once (ONE batch):** present the complete list in a single `question` tool call (array of question objects), each question with a clearly-marked RECOMMENDED answer so the user can accept/reject/refine. Explicitly NOT one-at-a-time. Initial batch includes new question types grounded in research:
   - "What problem does this solve and how is it measured today?" (Goldsmith: current measures)
   - "What are the technical/domain constraints?" (Sommerville)
   - "What assumptions are we making?" (Alexander)
   - "What's must-have vs nice-to-have?" (Alexander: priorities)
   Wait for all answers.
4. **Decide tier:** after the initial investigation round, decide whether to include the 10 extended sections. Triggers (ANY): greenfield detected, feature touches >3 modules, user explicitly flags complexity, or any core section reveals cross-cutting concerns. Quick wins always use core-only (handled by `yasdd-quick-elicitation`).
5. Record dense structured notes to `ELICITATION.md` under the tiered headings below. Keep an explicit `## Open questions` list; close resolved items. Core headings must be concrete enough to quote into ARCHITECTURE.md:
   - **Data shapes**: entities/fields/types — NEW and CHANGED (reference existing types; deltas only).
   - **Interface contracts**: function signatures / endpoints — full signatures, not vague references.
   - **Happy-path flow**: the normal path, step by step (terse numbered), so ARCHITECTURE doesn't have to infer it.
   - **Problem & motivation**: current measures showing the problem is real (Goldsmith).
   - **Goal & success measures**: testable success criteria (Goldsmith: goal measures).
6. **Continue the elicitation loop in BATCHED rounds:** re-analyze for remaining gaps, inferences (things assumed but unconfirmed), misunderstandings, and orphaned details (facts not tied to a decision or component). **Each round explicitly checks for the 3 Christel & Kang problems:** scope creep (system boundary ill-defined, unnecessary technical details), misunderstanding (users unsure, omitted "obvious" info, ambiguous/untestable requirements), volatility (requirements likely to change). For each round, collect ALL newly-discovered questions into ONE batch and ask them together via a single `question` call (never one-at-a-time), each with a recommended answer. If a question can be answered by exploring the codebase, EXPLORE instead of asking. Append notes; close/open Open-question items; add newly discovered ones. Ground the discussion in yasdd-spy findings. Do NOT read other features' ELICITATION/ARCHITECTURE/SUMMARY for project state.
7. **Stop when ALL hold:** Open questions empty AND every category has concrete (non-vague) content AND no inferences remain AND no misunderstandings AND no orphaned details remain AND the 3 Christel & Kang problems show no indicators.
8. **Final add-anything check:** ask the user (question tool): "Is there anything else you want to add to the discussion that should go into the architecture?" If yes, capture it and loop back to step 5 for those items. If no, proceed.
9. **Seed CONVENTIONS.md (greenfield only):** if greenfield was detected AND `.yasdd/CONVENTIONS.md` does not exist, write it from the technical-environment decisions made in step 2/3:
   ```md
   # Project Conventions

   ## Tech stack
   Language: <e.g., TypeScript 5.4>
   Framework: <e.g., Express 4, Next.js 14, FastAPI 0.110>
   Runtime: <e.g., Node 20, Python 3.12>

   ## Test
   Framework: <e.g., Vitest 1.6, pytest 8.2>
   Runner cmd: <e.g., npm test, pytest>
   Test location: <e.g., src/**/*.test.ts, tests/**/test_*.py>

   ## Quality gates
   Lint cmd: <e.g., npm run lint, ruff check>
   Typecheck cmd: <e.g., npm run typecheck, tsc --noEmit, mypy>

   ## Directory structure
   Source: <e.g., src/>
   Tests: <e.g., src/ (colocated), tests/ (separate)>
   Config: <e.g., .env, config/>
   ```
   If brownfield (source files exist) → do NOT seed CONVENTIONS.md here; the architect will detect + write it on first feature.
10. Write a final `## Summary` (handoff to architecture) and proceed to architecture (skill `yasdd-architect`).

## ELICITATION.md format (tiered)

```md
# Elicitation: <feature>

## ── CORE (always present, 8 sections) ──
## Problem & motivation       (Goldsmith: real problem, why it matters, current measures)
## Goal & success measures     (Goldsmith: goal measures — testable success criteria)
## Data shapes                 (field-level, deltas only)
## Interface contracts         (full signatures)
## Happy-path flow             (terse numbered — use cases/scenarios)
## Invariants                  (what must always hold)
## Acceptance criteria         (how you know it's done — testable)
## Non-goals                   (scope boundary — Christel & Kang: scope problem)

## ── EXTENDED (complex or greenfield, 10 sections) ──
## Stakeholders & perspectives (who cares, their bias/concerns)
## Technical environment       (Sommerville: architecture, OS, infra constraints)
## Domain constraints          (Sommerville: business/domain limits on functionality/perf)
## Edge & error cases
## Component boundaries        (natural module/file splits for parallelism)
## Dependencies on existing code
## Assumptions & rationale     (Alexander: why each requirement, what's assumed)
## Glossary                    (Alexander: shared terminology — only non-obvious terms)
## Priorities                  (Alexander: must-have vs nice-to-have)
## Risks                       (volatility awareness — Christel & Kang)

## Open questions
## Summary
```

Omit the extended section header + its subsections if the tier decision (step 4) was core-only.

## Rules
- Ask questions in BATCHES (all current open questions per round in one `question` call); never one-at-a-time.
- Dense + structured; never prose essays. Reference existing code by path.
- Never invent answers; record unknowns as open questions.
- Don't over-elicit; be pragmatic — but don't stop until gaps, inferences, misunderstandings, and orphaned details (facts not tied to a decision or component) are resolved.
- Check for the 3 Christel & Kang problems (scope, understanding, volatility) every round.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
