# yasdd v2 — Upgrade Plan

> **Fast. Not Much Tokens. High Quality.**

## Core Decision: Drop Specs, Strengthen ARCHITECTURE

The spec layer is eliminated. ARCHITECTURE.md absorbs the spec content (Rules, Cases, Acceptance with anchors) + testing architecture + parallel batch plan. Implementation is **feature-level, component-partitioned** — not spec-level. The LLM's natural todo-list building becomes the implementation plan, driven by ARCHITECTURE's `Components [M#]` section.

## Decisions Locked

| Decision | Choice |
|----------|--------|
| DESIGN self-check | Baked into `yasdd-architect` (iterate until clean, no subagent); **cap at 3 iterations**, then emit + flag to user |
| goback model | Separate `CHANGE.md` file (delta, not appended to ARCHITECTURE) |
| quick-spec rename | Rename to `yasdd-quick-architect` |
| Component anchors | `[M#]` (M for Module, avoids D/Data confusion) |
| Testing | Absorbed into ARCHITECTURE.md; DROP `yasdd-test-design` + `TESTING.md` |
| designer → architect | Rename skill + artifact (`DESIGN.md` → `ARCHITECTURE.md`) |
| discuss → elicitation | Rename skill + artifact (`DISCUSS.md` → `ELICITATION.md`) |
| maxSpecs | Removed from config (no hard cap); architect has **token-cost awareness note** ("if >6 components, consider whether some can merge") |
| autoMode gate | true → architecture + straight to implementation; false → ask to proceed |
| Parallelism | ARCHITECTURE.md explicitly plans parallel batches respecting maxParallelism |
| Quick-win format | Simplified format (no `Parallel batches`, no `Components` with `[M#]`); closer to v1's fused SPEC.md |
| Elicitation sections | Tiered: always-present **core (8 sections)** + **extended (10 sections)** triggered when feature is complex or greenfield |
| Project conventions | New `CONVENTIONS.md` captures project-wide framework/test-runner/lint/typecheck commands once; every ARCHITECTURE inherits; eliminates per-feature TESTING rediscovery (helps brownfield + greenfield) |
| Greenfield support | Medium: yasdd-spy returns "greenfield detected" instead of failing; elicitation handles stack decisions inline; CONVENTIONS.md seeds project-wide conventions; first feature is architecture-defining |
| Self-check point 10 | Every `[M#]` with `deps:` references another `[M#]`'s data/interfaces by anchor, not vaguely (restores v1 self-sufficiency contract) |
| STATE.md granularity | Per-component status with `impl`/`test`/`verify` markers (not just implemented `[x]`/`[ ]`) |
| Mid-flight batch update | Orchestrator can demote overlapping components to sequential without re-reading whole ARCHITECTURE (in-memory batch adjustment) |

---

## Elicitation Improvement (grounded in research)

### Frameworks mapped to yasdd-elicitation

#### Christel & Kang problems (1992) — *what to watch for*
1. **Scope** — system boundary ill-defined, unnecessary technical details
2. **Understanding** — users unsure, omit "obvious" info, ambiguous/untestable requirements
3. **Volatility** — requirements change over time

#### Sommerville & Sawyer guidelines (1997) — *what to elicit*
- Assess business + technical feasibility
- Identify stakeholders + organizational bias
- Define technical environment (architecture, OS, constraints)
- Identify domain constraints (business environment limits)
- Solicit from multiple perspectives, identify rationale
- Create usage scenarios/use cases

#### Alexander & Beus-Dukic approaches (2008) — *complementary dimensions*
- Stakeholders, goal modeling, context modeling, scenarios, qualities/constraints (NFRs), rationale/assumptions, definitions of terms, measurements (acceptance criteria), priorities

#### Goldsmith problem pyramid (2004) — *sequencing*
1. Identify real problem/opportunity
2. Current measures showing problem is real
3. Goal measures showing problem addressed
4. As-is causes
5. Business wants
6. Product design

### Current yasdd-discuss gaps vs these frameworks

| Missing dimension | Source |
|---|---|
| Problem context (current measures, as-is causes) | Goldsmith |
| Goal/success measures (testable success criteria) | Goldsmith |
| Technical environment | Sommerville |
| Domain constraints (business limits) | Sommerville |
| Assumptions & rationale | Alexander |
| Glossary (shared terminology) | Alexander |
| Priorities (must-have vs nice-to-have) | Alexander |

### New ELICITATION.md format (tiered: core + extended)

The 18 sections are split into a **core (always present)** and **extended (triggered when the feature is complex or greenfield)**. This keeps small features fast while retaining thoroughness for complex/greenfield work.

**Tier trigger:** the elicitation skill decides after the initial investigation round. Extended set is included when ANY of: greenfield detected (no existing source), feature touches >3 modules, user explicitly flags complexity, or any core section reveals cross-cutting concerns. Quick wins always use core-only.

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
```

### Process improvements in the skill

- Initial batch includes new question types: "What problem does this solve and how is it measured today?", "What are the technical/domain constraints?", "What assumptions are we making?", "What's must-have vs nice-to-have?"
- Each batched round explicitly checks for the 3 Christel & Kang problems: scope creep, misunderstanding, volatility indicators
- Codebase-first (yasdd-spy) already addresses the understanding problem — keep and emphasize
- **Greenfield detection:** if yasdd-spy returns "greenfield — no existing source files found" (no source files in repo OR repo empty), the elicitation injects a "Technical environment decision" sub-step: decide language/framework, test runner, lint tool, directory structure. These decisions seed `CONVENTIONS.md` (see CONVENTIONS.md section) on first feature, and are referenced by ARCHITECTURE's Testing section thereafter. If `CONVENTIONS.md` already exists, inherit it instead of re-deciding.
- **Extended tier trigger:** after the initial investigation round, the skill decides whether to include the 10 extended sections. Triggers: greenfield detected, feature touches >3 modules, user flags complexity, or core sections reveal cross-cutting concerns. Quick wins always use core-only.

---

## Enhanced ARCHITECTURE.md Format

Absorbs: old DESIGN.md + old TESTING.md + parallel batch plan.

```md
# Architecture: <feature>
Refs: <existing file paths + symbols changed/extended>
Approach: <2-4 sentences: how it works, key decisions>
Components:
  - [M1] <component> — files: file1.ts, file2.ts — deps: none
  - [M2] <component> — files: file3.ts — deps: M1
  - [M3] <component> — files: file4.ts — deps: none
Parallel batches (maxParallelism=<N>):
  - Batch 1: [M1], [M3]  (disjoint files, no deps)
  - Batch 2: [M2]        (deps: M1)
Data: <new/changed shapes, field-level, deltas only>
Interfaces: <full signatures (name/params/return), deltas only>
Flow: <numbered happy path, terse>
Rules:
  - [R1] <rule text>
  - [R2] <rule text>
Cases:
  - [C1] when X -> Y
  - [C2] when Z -> W
Acceptance:
  - [A1] Given X When Y Then Z
  - [A2] Given A When B Then C
Testing:
  Framework: <test runner + version>            ← inherit from CONVENTIONS.md if present
  Runner cmd: <e.g., npm test, pytest, go test> ← inherit from CONVENTIONS.md if present
  Lint cmd: <e.g., npm run lint, ruff check>     ← inherit from CONVENTIONS.md if present
  Typecheck cmd: <e.g., npm run typecheck, tsc --noEmit, mypy> ← inherit from CONVENTIONS.md if present
  Unit test location: <convention per module>
  Fixture strategy: <shared fixtures, factories, mocks>
  E2E scope: <entry points + scenarios covered>
  Acceptance mapping: <how each [A#] maps to a test file/case>
Out of scope: <non-goals>
Risks & mitigations: <list>
Non-functional: <1-2 NFRs; note which component [M#] owns each>
```

### CONVENTIONS.md inheritance

If `.yasdd/CONVENTIONS.md` exists, the architect **inherits** (not re-decides) `Framework`, `Runner cmd`, `Lint cmd`, `Typecheck cmd` from it. Only feature-specific fields (`Unit test location`, `Fixture strategy`, `E2E scope`, `Acceptance mapping`) are written per-feature. If `CONVENTIONS.md` is absent (brownfield without init), the architect detects from `package.json`/`Makefile`/`AGENTS.md` as today AND writes `CONVENTIONS.md` with the detected values so subsequent features inherit. If greenfield (no source), the elicitation's technical-environment decisions seed `CONVENTIONS.md` before architecture runs.

### Token-cost awareness (no hard cap)

The architect has no `maxSpecs` cap — component count is decided naturally. However, the architect includes this **token-cost awareness note** in its reasoning:

> **Component count awareness:** each `[M#]` component triggers one implementer invocation (~4,000–5,000 tokens each). If the component count exceeds 6, re-evaluate whether some components can merge (e.g., two tightly-coupled modules editing the same file set → one component). This is advisory, not a hard cap — complex features may legitimately need 8+ components.

### Architect Self-Check (baked into yasdd-architect, 10 points, cap at 3 iterations)

After writing ARCHITECTURE.md, the architect validates:

1. **Disjointness**: all `[M#]` components have disjoint file sets (or explicit `deps:` making them sequential)
2. **Parallel batches valid**: every `[M#]` appears in exactly one batch; batches respect `maxParallelism`; deps satisfied by earlier batches; same-batch components have disjoint files
3. **Rules concrete**: every `[R#]` is a testable invariant, not vague
4. **Cases concrete**: every `[C#]` is a specific edge/error, not a category
5. **Acceptance testable**: every `[A#]` is Given/When/Then, checkable by a test
6. **Data field-level**: every shape has entity/field/type
7. **Interfaces complete**: every signature has name/params/return
8. **Flow complete**: happy path covers all components
9. **Testing complete**: framework + commands specified (or inherited from CONVENTIONS.md); every `[A#]` maps to a test location
10. **Component self-sufficiency**: every `[M#]` with `deps:` references another `[M#]`'s data/interfaces by anchor (e.g., `deps: M1 (Data: [M1] Account shape, Interfaces: [M1] AccountRepo)`), not vaguely — restores v1's self-sufficiency contract so the implementer doesn't need to guess dependency shapes

If any fails → iterate ARCHITECTURE.md (don't emit, don't launch a reviewer). The skill loops until all 10 pass. **Iteration cap: 3.** If still failing after 3 iterations, emit ARCHITECTURE.md with a flagged `## Self-check warnings` section listing the failed points and proceed (the user/gate will see them).

---

## Config (simplified)

```yaml
autoMode: false      # true = architecture → straight to implementation; false = ask to proceed
maxParallelism: 3    # cap on parallel subagent calls + batch size
```

`maxSpecs` removed. The architect decides component count naturally — no artificial cap. Token-cost awareness note in the architect skill advises merging if >6 components, but this is advisory, not enforced.

`CONVENTIONS.md` is NOT in config — it's a project-wide artifact seeded by elicitation (greenfield) or architect (brownfield) on first feature, then inherited. See CONVENTIONS.md section.

---

## autoMode Gate Behavior

| autoMode | After ARCHITECTURE.md + self-check passes |
|----------|-------------------------------------------|
| `true` | Go straight to implementation (no pause) |
| `false` | Ask user: "Architecture ready. Can I proceed to implementation?" |

This replaces the current behavior where autoMode gates step 4 (PLAN IMPLEMENTATION) with spec selection. Now there's nothing to select — the architect already planned the batches.

---

## Pipeline (v2)

```
0. config                          read .yasdd/config.yml (autoMode + maxParallelism)
0b. CONVENTIONS check              if .yasdd/CONVENTIONS.md absent → architect will seed it (greenfield: elicitation decides; brownfield: architect detects from package.json/Makefile/AGENTS.md)
1. ELICITATION (main)              → ELICITATION.md (tiered: core 8 + extended 10 if complex/greenfield); greenfield detection via yasdd-spy; seeds CONVENTIONS.md on first feature
2. ARCHITECTURE (main + self-check) → ARCHITECTURE.md (components + batches + testing + rules/cases/acceptance); inherits Testing fields from CONVENTIONS.md; 10-point self-check (cap 3 iterations)
3. GATE                            autoMode? true → proceed; false → ask user
4. IMPLEMENT LOOP (parallel per batch, code-only; mid-flight batch update if file conflict detected)
5. TEST (feature-level, reads ARCHITECTURE Acceptance + Testing; check commands inherited from CONVENTIONS.md via ARCHITECTURE)
5b. FIX-LOOP (route by files → components [M#]; per-component test status in STATE.md)
6. FINAL VERIFY (feature-level, ARCHITECTURE conformance; per-component verify status in STATE.md)
7. WRAP UP
```

**Eliminated vs v1:** SPECS step, MANIFEST.md, TESTING.md, TESTING step (2b), spec-level STATE tracking, per-feature test-framework rediscovery (CONVENTIONS.md inherits once).

**New vs v1:** CONVENTIONS.md (project-wide, seeded once), greenfield detection (yasdd-spy + elicitation), tiered elicitation (core + extended), mid-flight batch update (in-memory), per-component impl/test/verify status (STATE.md).

---

## Artifacts

| Artifact | v1 | v2 |
|----------|----|----|
| `ELICITATION.md` | `DISCUSS.md` (~150 lines) | ~120-190 lines (tiered: core 8 sections ~120 lines; +extended 10 sections ~190 lines if complex/greenfield) |
| `ARCHITECTURE.md` | `DESIGN.md` (~40 lines) + `TESTING.md` (~15 lines) + 5 specs (~300 lines) + `MANIFEST.md` (~10 lines) | ~100-120 lines (all absorbed) |
| `CONVENTIONS.md` | n/a | ~15-20 lines (project-wide, seeded once on first feature; inherited by all ARCHITECTURE.md) |
| `SUMMARY.md` | unchanged | unchanged |
| `PROJECT-STATE.md` | spec tracking | component tracking |
| `STATE.md` | spec checklist | component checklist with per-component impl/test/verify status |
| `specs/` | 5 files | **DROPPED** |
| `MANIFEST.md` | ~10 lines | **DROPPED** (batches in ARCHITECTURE; mid-flight update in-memory) |
| `TESTING.md` | ~15 lines | **DROPPED** (absorbed into ARCHITECTURE; framework/commands inherited from CONVENTIONS.md) |
| `CHANGES/` | n/a | new (goback deltas in ARCHITECTURE format) |

**Total artifact reduction: ~60%** (from ~530 lines to ~210-230 lines per feature, excluding CONVENTIONS.md which is project-wide) + elimination of specs decomposition + test-design steps + per-feature test-framework rediscovery.

---

## Token Savings Estimate

### Artifact lines (per feature)

| Artifact | Current (5 specs) | New |
|----------|-------------------|-----|
| ELICITATION.md | ~150 lines | ~120 lines (core) or ~190 lines (core+extended) |
| ARCHITECTURE.md | ~40 lines | ~100-120 lines (absorbs spec content + testing + batches) |
| CONVENTIONS.md | n/a | ~15-20 lines (project-wide, written once; not per-feature) |
| TESTING.md | ~15 lines | **0** (dropped; inherited from CONVENTIONS.md via ARCHITECTURE) |
| 5 specs | ~300 lines | **0** (dropped) |
| MANIFEST.md | ~10 lines | **0** (dropped) |
| STATE.md | ~15 lines | ~15 lines (per-component impl/test/verify — slightly richer) |
| **Total per feature** | **~530 lines** | **~235-325 lines** (depending on tier) |
| **SPECS step thinking** | significant (decompose + write) | **0** (eliminated) |
| **TEST-DESIGN step** | significant (write TESTING.md) | **0** (eliminated) |
| **Per-feature test-framework rediscovery** | significant (detect from package.json each time) | **0** (inherited from CONVENTIONS.md) |

**~40-55% artifact token reduction** per feature + elimination of the specs decomposition reasoning step + elimination of the test-design step + elimination of per-feature test-framework rediscovery.

### Total pipeline tokens (including implementation units)

The artifact savings are real, but the **total pipeline cost** depends on the component count. Each `[M#]` component triggers one implementer invocation (~4,000-5,000 tokens each). For features with ≤5 natural components, v2 is cheaper than v1. For features with >5 components (e.g., a full app with 8 components), v2 can cost more because there's no `maxSpecs` cap — the token-cost awareness note in the architect skill mitigates this but doesn't prevent it.

**Budget financial management app example (~8 components):**

| Phase | v2 tokens (8 components) | v1 tokens (5 specs) |
|-------|--------------------------|---------------------|
| Elicitation | ~6,000 (core+extended) | ~5,000 |
| Architecture | ~4,200 (incl. self-check 2 iters) | ~2,000 (DESIGN) + ~300 (TESTING) + ~5,000 (SPECS) = ~7,300 |
| Implementation | ~36,000 (8 × ~4,500) | ~25,000 (5 × ~5,000) |
| Test | ~10,000 | ~10,000 |
| Verify | ~8,000 | ~8,000 |
| Fix loops (1-2 rounds) | ~7,000 | ~7,000 |
| **Total** | **~71,000** | **~62,500** |

**Speed at 30 tokens/sec:**
- v2: ~71,000 / 30 = ~2,370s = **~40 min pure generation** (~60-80 min wall-clock with tool calls)
- v1: ~62,500 / 30 = ~2,083s = **~35 min pure generation** (~50-70 min wall-clock)

**Key insight:** for features with ≤5 components, v2 saves ~15-20% total tokens (fewer implementation units + no specs/test-design reasoning). For features with >5 components, v2 can cost ~10-15% more total tokens — the artifact savings are outweighed by extra implementation units. The token-cost awareness note is the safeguard but not a hard cap.

**Note:** 30 tok/s is conservative. Modern models hit 50-100+ tok/s, where tool-call overhead (file reads, subagent spawning) dominates and the framework difference shrinks.

---

## Parallelism (without MANIFEST) + Mid-flight Batch Update (P6)

Orchestrator reads ARCHITECTURE's `Components` + `Parallel batches` directly:
- `[M1]` with `deps: none` → batch 1
- `[M2]` with `deps: M1` → batch 2 (after M1)
- `[M3]` with `deps: none` → batch 1 (parallel with M1, if file-disjoint)
- File-disjoint check: if two components in the same batch list the same file → sequential
- Batch size capped at `maxParallelism`

The architect pre-computes batches in ARCHITECTURE.md itself. The orchestrator just reads and executes them.

### Mid-flight batch update (in-memory, no file rewrite)

If a file conflict emerges during parallel implementation that the architect didn't foresee (e.g., two components in the same batch both modify a shared utility), the orchestrator handles it **in-memory** without re-reading or rewriting the whole ARCHITECTURE.md:

1. **Detect:** during the aggregate step (after a batch completes), the orchestrator checks for file overlap in the changed-files manifests reported by implementers in the same batch.
2. **Demote:** if overlap is found, the orchestrator marks the overlapping components as **sequentially dependent** (in-memory only): the second component waits for the first to finish before launching. No STATE.md or ARCHITECTURE.md rewrite — the orchestrator just adjusts the next batch's launch order.
3. **Flag:** the orchestrator notes the partition violation in its report to the user ("M2 and M3 both modified `utils/auth.ts` — ran sequentially instead of parallel") so the architect can learn for future features (via goback CHANGES if needed).

This preserves v1's disjointness validation (which used MANIFEST) but operates in-memory — the orchestrator has the batch plan + changed-files manifests already, no separate artifact needed.

---

## Fix Routing (without spec attribution)

1. Verifier cites `file:line` in findings
2. Orchestrator maps files → `[M#]` components (from ARCHITECTURE's Components)
3. Routes fix to the implementer that owns those files

Almost as precise as spec attribution — the only difference is multiple rules/cases/acceptance items may belong to the same component rather than separate specs, but the fix-loop still routes to the right files.

---

## STATE.md (v2) — per-component impl/test/verify status (P4)

```md
# Feature: <slug>

## Components
- [x] [M1] <component> — files: file1.ts, file2.ts
  - impl: done
  - test: done
  - verify: done
- [~] [M2] <component> — files: file3.ts
  - impl: done
  - test: FAIL (2 impl-bugs)
  - verify: pending
- [ ] [M3] <component> — files: file4.ts
  - impl: pending
  - test: pending
  - verify: pending

## Status
- architecture: done
- implementation: 2/3 components
- testing: 1/3 passed
- verification: 1/3 done
- last updated: <date>
```

**Status markers:** `[x]` = fully done (impl + test + verify), `[~]` = blocked (failed test or verify), `[ ]` = not started.

**Per-component granularity** lets the fix-loop after the TEST phase target the right component. If `[M2]` fails testing, the orchestrator knows to re-launch the implementer for `[M2]` only, not the whole feature. The tester's classified findings (impl-bug/test-bug) are attributed to components via the changed-files manifest → `[M#]` mapping, and the component's `test:` field is updated to `FAIL (N impl-bugs)` or `FAIL (N test-bugs)` for routing.

---

## goback (v2)

Writes `.yasdd/features/<slug>/CHANGES/NN-<change-slug>.md` — an ARCHITECTURE-format delta:

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

STATE.md gets `[M3]` appended. Orchestrator implements `[M3]` like any other component.

---

## CONVENTIONS.md (P7–P10: greenfield Medium support)

A new project-wide file at `.yasdd/CONVENTIONS.md` captures the project's technical conventions **once** so every feature's ARCHITECTURE.md inherits them instead of re-discovering.

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

### Lifecycle

| Scenario | When CONVENTIONS.md is created |
|----------|--------------------------------|
| **Greenfield (first feature)** | Elicitation's "Technical environment decision" sub-step seeds it before architecture runs |
| **Brownfield (no CONVENTIONS.md yet)** | Architect detects from `package.json`/`Makefile`/`AGENTS.md` on first feature, writes CONVENTIONS.md so subsequent features inherit |
| **Already exists** | Architect inherits (never re-decides); elicitation skips technical-environment sub-step |

### Who reads it

| Skill | How it uses CONVENTIONS.md |
|-------|---------------------------|
| `yasdd-elicitation` | Checks if it exists; if not + greenfield → runs technical-environment decision sub-step + seeds it; if not + brownfield → flags "will be detected by architect" |
| `yasdd-architect` | Inherits `Framework`/`Runner cmd`/`Lint cmd`/`Typecheck cmd` into ARCHITECTURE's Testing section; if absent, detects + writes CONVENTIONS.md as part of architecture |
| `yasdd-implementer` | No direct read (gets values via ARCHITECTURE.md Testing section) |
| `yasdd-tester` | Reads ARCHITECTURE.md Testing section (which inherited from CONVENTIONS.md); no runtime detection needed |
| `yasdd-verifier` | Same as tester — check commands come from ARCHITECTURE.md (inherited from CONVENTIONS.md) |
| `yasdd-init` | Does NOT create CONVENTIONS.md (it's seeded by elicitation/architect on first feature, not at init time — init doesn't know the tech stack yet) |

### Greenfield detection (P9)

`yasdd-spy` is updated to handle greenfield gracefully:

- If no source files are found in the repo (empty repo, or only `.git/`/`.yasdd/`/`README.md`), yasdd-spy returns: `"greenfield — no existing source files found; technical environment to be decided"` instead of failing or returning empty results.
- This triggers the elicitation's technical-environment decision sub-step (which seeds CONVENTIONS.md).
- If the repo has source files but they're in a different language/framework than the feature targets (polyglot repo), yasdd-spy traces the relevant subset normally.

### First-feature special handling (P10)

If `PROJECT-STATE.md` has no features AND yasdd-spy detects greenfield, the first feature is treated as **architecture-defining**:

1. Elicititation injects the "Technical environment decision" sub-step (language, framework, test runner, lint, directory structure).
2. These decisions seed `CONVENTIONS.md`.
3. The architect inherits CONVENTIONS.md and writes the first ARCHITECTURE.md with the project's foundational structure (directory layout, shared utilities, base configuration).
4. Subsequent features inherit CONVENTIONS.md — no re-deciding.

This does NOT add a separate scaffolding step — it folds naturally into the existing elicitation → architecture flow.

---

## Quick-Win Simplified Format (P5)

Quick wins use a **simplified format** — no `Parallel batches`, no `Components` with `[M#]`, no component partitioning. Quick wins are single-shot, stateless, one implementation unit — parallelism is irrelevant.

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

**What's dropped vs full ARCHITECTURE.md:** `Components` with `[M#]`, `Parallel batches`, `Non-functional` NFRs, `Risks & mitigations`. Quick wins are small enough that these add overhead without value.

**What's kept:** `Rules`/`Cases`/`Acceptance` with stable anchors (`[R#]`/`[C#]`/`[A#]`), `Testing` section (inheriting from CONVENTIONS.md if present). These are the minimum for the tester + verifier to work.

**Format lineage:** this is closer to v1's fused `SPEC.md` (which had `Refs`/`Goal`/`I/O`/`Data`/`Interfaces`/`Rules`/`Scenarios`/`Acceptance`/`Out of scope`) but adds the `Testing` section (inherited from CONVENTIONS.md or detected) and drops `I/O` (redundant with `Data` + `Interfaces`). The `Approach` field replaces v1's `Components` for context.

---

## Skills: Full Change List

| Skill | v1 name | v2 name | Action | Summary |
|-------|---------|---------|--------|---------|
| elicitation | yasdd-discuss | yasdd-elicitation | **Rename + modify** | Tiered ELICITATION.md (core 8 + extended 10); greenfield detection → seeds CONVENTIONS.md; 3 Christel & Kang problems watchlist per round |
| architect | yasdd-designer | yasdd-architect | **Rename + major modify** | Absorb Rules/Cases/Acceptance + Testing + Parallel batches; 10-point self-check (cap 3 iterations); token-cost awareness note; CONVENTIONS.md inheritance |
| test-design | yasdd-test-design | — | **DROP** | Absorbed into architect |
| specs | yasdd-specs | — | **DROP** | Absorbed into architect |
| implementer | yasdd-implementer | yasdd-implementer | **Modify** | Read ARCHITECTURE.md; implement one component `[M#]`; conformance table references ARCHITECTURE anchors |
| tester | yasdd-tester | yasdd-tester | **Modify** | Read ARCHITECTURE.md (Testing section + Acceptance `[A#]`); no TESTING.md; inherit check commands from CONVENTIONS.md via ARCHITECTURE |
| verifier | yasdd-verifier | yasdd-verifier | **Modify** | ARCHITECTURE conformance; attribute findings to components/files via `[M#]`; check commands from CONVENTIONS.md via ARCHITECTURE |
| goback | yasdd-goback | yasdd-goback | **Modify** | Write CHANGES/NN delta in ARCHITECTURE format |
| quick-elicitation | yasdd-quick-discuss | yasdd-quick-elicitation | **Rename + modify** | Core-only elicitation (8 sections, no extended); greenfield detection if quick-win on empty repo |
| quick-architect | yasdd-quick-spec | yasdd-quick-architect | **Rename + modify** | Simplified format (no Components/batches, no [M#]); Testing section inherits CONVENTIONS.md |
| doubt | yasdd-doubt | yasdd-doubt | **Modify** | Read ARCHITECTURE.md |
| init | yasdd-init | yasdd-init | **Modify** | Config without maxSpecs; AGENTS.md updated; does NOT create CONVENTIONS.md (seeded by elicitation/architect on first feature) |
| clear | yasdd-clear | yasdd-clear | **Modify** | Simpler cleanup; also clear CHANGES/ |
| spy | yasdd-spy | yasdd-spy | **Modify** | Greenfield detection: return "greenfield — no existing source files" instead of failing on empty repos |

---

## Commands: Full Change List

| Command | Action | Key changes |
|---------|--------|-------------|
| `/yasdd` | **Modify** | Drop SPECS + TESTING steps; add CONVENTIONS.md check (0b); architect writes ARCHITECTURE.md with batches + testing; autoMode gate after architecture; implement by component; mid-flight batch update on file conflict; per-component STATE.md tracking |
| `/yasdd-implement` | **Modify** | Implement by component `[M#]`; per-component test/verify status updates |
| `/yasdd-continue` | **Modify** | Continue by feature (pending components); respect per-component impl/test/verify status |
| `/yasdd-quick-win` | **Modify** | Use yasdd-quick-elicitation (core-only) + yasdd-quick-architect (simplified format, no Components/batches) |
| `/yasdd-status` | **Modify** | Show component status (impl/test/verify per component) |
| `/yasdd-goback` | **Modify** | CHANGES/NN in ARCHITECTURE format |
| `/yasdd-init` | **Modify** | Config without maxSpecs; does NOT create CONVENTIONS.md |
| `/yasdd-clear` | **Modify** | Also clear CHANGES/ + CONVENTIONS.md |

---

## Other Files

| File | Action |
|------|--------|
| `README.md` | **Modify** — new pipeline, artifacts (incl. CONVENTIONS.md), commands, skills table, config, greenfield support |
| `README.pt-br.md` | **Modify** — same |
| `README.cn.md` | **Modify** — same |
| `agents/yasdd-spy.md` | **Modify** — greenfield detection: return "greenfield — no existing source files" on empty repos instead of failing |
| `prompts/*.md` | **Modify** — mirror commands |

---

## Quality Safeguards

| Risk | Safeguard |
|------|-----------|
| ARCHITECTURE wrong → all components affected | Enhanced elicitation (tiered: core 8 + extended 10 if complex/greenfield; Problem/Goal/TechEnv/DomainConstraints/Assumptions questions) + 10-point ARCHITECTURE self-check (cap 3 iterations) |
| Less precise fix routing (files vs specs) | Orchestrator maps files → `[M#]` components from ARCHITECTURE; per-component impl/test/verify status in STATE.md for precise routing |
| No implicit review from spec decomposition | ARCHITECTURE self-check bakes quality in (10 points); verifier still runs feature-level |
| ARCHITECTURE too large for implementer context | ARCHITECTURE is one lean page (~100-120 lines); implementer focuses on its `[M#]` section; self-sufficiency check (point 10) ensures deps are anchored, not vague |
| Parallelism lost without MANIFEST | ARCHITECTURE's Components + Parallel batches sections provide file ownership + deps + batch plan directly; mid-flight batch update (in-memory) handles unforeseen file conflicts |
| goback loses history | CHANGES/NN files preserve deltas with full ARCHITECTURE-format context |
| Elicitation misses requirements | Christel & Kang watchlist per round + Alexander's 9 complementary approaches + Goldsmith problem pyramid sequencing; tiered sections ensure core is always present, extended for complex/greenfield |
| Self-check loops forever | Iteration cap: 3. If still failing, emit with `## Self-check warnings` and proceed |
| Component count explodes (>6) without maxSpecs | Token-cost awareness note in architect skill advises merging; advisory, not enforced |
| Greenfield: yasdd-spy fails on empty repo | yasdd-spy returns "greenfield detected" instead of failing; elicitation seeds CONVENTIONS.md |
| Per-feature test-framework rediscovery | CONVENTIONS.md captures framework/commands once; ARCHITECTURE inherits; tester/verifier read inherited values |
| Quick wins over-burdened with full ARCHITECTURE format | Simplified format (no Components/batches/[M#]); closer to v1's fused SPEC.md |

---

## Implementation Order

1. **`yasdd-architect`** (major rewrite — the keystone: absorbs specs + testing + batches + 10-point self-check with cap + token-cost awareness + CONVENTIONS.md inheritance)
2. **`yasdd-elicitation`** (rename + tiered elicitation core 8 + extended 10 + greenfield detection + CONVENTIONS.md seeding)
3. **`yasdd-spy`** (modify — greenfield detection: return "greenfield" on empty repos)
4. **`yasdd-implementer`** (ARCHITECTURE-based, component-level; per-component conformance)
5. **`yasdd-tester`** (reads ARCHITECTURE.md Testing + Acceptance; inherits from CONVENTIONS.md)
6. **`yasdd-verifier`** (ARCHITECTURE conformance; per-component verify status; inherits check commands)
7. **`yasdd-goback`** (CHANGES/NN in ARCHITECTURE format)
8. **`yasdd-quick-elicitation`** + **`yasdd-quick-architect`** (rename + enhance; quick-architect uses simplified format)
9. **`yasdd-doubt`** + **`yasdd-clear`** + **`yasdd-init`** (minor updates; init does NOT create CONVENTIONS.md)
10. **Commands** (`/yasdd`, `/yasdd-implement`, `/yasdd-continue`, `/yasdd-quick-win`, `/yasdd-status`)
11. **Delete** `yasdd-specs` + `yasdd-test-design` skills
12. **READMEs** (all three languages — document CONVENTIONS.md, greenfield, tiered elicitation)
13. **Prompts** (mirror commands)
