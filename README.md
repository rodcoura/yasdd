# yasdd

> Yell At Specs, Design Directly — a pragmatic, markdown-only pipeline for AI coding agents.

**Languages:** [English](README.md) · [Português (Brasil)](README.pt-br.md) · [中文](README.cn.md)

---

## Installation

yasdd is pure markdown — no build step, no dependencies. Place `skills/`, `commands/`, and `agents/` where your agent harness reads them.

### Recommended: installer script

The `install-to-agents.sh` script copies skills, agents, commands, and prompts to the locations each tool actually scans:

```bash
# from a repo checkout
./install-to-agents.sh

# or one-liner (downloads + installs)
curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash

# pin a specific version
YASDD_REF=<tag> curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash
```

Targets:

| Directory | Contents |
| --- | --- |
| `~/.agents/` | skills, agents, commands, prompts (cross-tool mirror) |
| `~/.config/opencode/` | agents, commands (opencode native) |
| `~/.claude/` | agents, commands, skills (Claude Code native) |

### Manual: symlinks

Pick one location:

- **Global (all projects):** `~/.agents/` — gives you `~/.agents/skills/yasdd-*/SKILL.md`, `~/.agents/commands/yasdd*.md`, and `~/.agents/agents/yasdd-spy.md`.
- **Project-local (one repo):** `.agents/` in the project root — `.agents/skills/...`, `.agents/commands/...`, `.agents/agents/...`.
- **Custom:** any folder your agent harness loads skills/commands from.

Symlink each directory (safe if the folder already holds other skills):

```bash
# clone
git clone https://github.com/rodcoura/yasdd ~/projects/yasdd

# global install
mkdir -p ~/.agents/skills ~/.agents/commands ~/.agents/agents ~/.agents/prompts
for s in ~/projects/yasdd/skills/*; do ln -sf "$s" ~/.agents/skills/; done
for c in ~/projects/yasdd/commands/*.md; do ln -sf "$c" ~/.agents/commands/; done
for a in ~/projects/yasdd/agents/*.md; do ln -sf "$a" ~/.agents/agents/; done
for p in ~/projects/yasdd/prompts/*.md; do ln -sf "$p" ~/.agents/prompts/; done
```

For a project-local install, repeat the loops with `.agents/` instead of `~/.agents/`. Then run `/yasdd-init` in your project to scaffold `.yasdd/` and update `AGENTS.md`.

---

## What is yasdd?

yasdd is a **specless design and delivery framework** made entirely of markdown skills and commands. It gives an AI coding agent a repeatable pipeline to take a vague feature request and turn it into a fully implemented, reviewed feature — without overthinking and without skipping the hard questions.

It is not source code. There is no build system. Everything lives in four directories:

- `commands/` — user-facing slash commands (the orchestrator playbooks).
- `skills/` — subagent instructions, one folder per skill (`<skill>/SKILL.md`).
- `agents/` — subagent definitions (currently `yasdd-spy.md`, the lightweight codebase explorer).
- `prompts/` — symlinks mirroring `commands/` for tools that read from a `prompts/` directory instead of `commands/`.

## How it works

Every feature flows through a lean pipeline:

```
0. config              read .yasdd/config.yml
0b. CONVENTIONS check  if .yasdd/CONVENTIONS.md absent → architect will seed it
1. ELICITATION         tiered grilling (core 8 + extended 10 if complex/greenfield)  (main session)  → ELICITATION.md
2. ARCHITECTURE        components [M#] + parallel batches + testing + rules/cases/acceptance + 10-point self-check  (main session)  → ARCHITECTURE.md + STATE.md
3. GATE                autoMode? true → proceed; false → ask user
4. IMPLEMENT LOOP      per batch, parallel (up to maxParallelism): code-only implementers per component [M#] → mark done (no checks)
5. TEST                ONE tester writes unit + e2e tests + runs checks once (from ARCHITECTURE, inherited from CONVENTIONS.md) over the whole feature
5b. FIX-LOOP           if bugs: orchestrator writes fix-plan inline → implementer with "run all checks" → re-test (cap 3 rounds)
6. FINAL VERIFY        ONE feature-level review + checks rerun (unconditional) over code + tests (cap 3 rounds)
7. WRAP UP             update project state
```

ELICITATION and ARCHITECTURE run in the main session reusing loaded codebase context (zero re-exploration); IMPLEMENT/TEST/VERIFY run as isolated subagents with clean contexts.

Five core ideas make yasdd work:

- **Architecture-level, component-partitioned implementation**: ARCHITECTURE.md contains the spec content (Rules/Cases/Acceptance with anchors) + testing architecture + parallel batch plan. Implementation is driven by `Components [M#]` — the LLM's natural todo-list building becomes the plan. No specs decomposition step.
- **Acceptance = Given/When/Then**: the happy path + each Case, each checkable by a test. This makes the "functioning architecture" rule verifiable instead of self-reported.
- **Main-session context reuse**: ELICITATION and ARCHITECTURE run inline in the main session, reusing the codebase context loaded during elicitation — no re-exploration subagents, lower token usage.
- **Parallel implementation via deferred testing**: the implementer is code-only (no tests, no checks) so components with disjoint file sets can run in parallel batches (pre-computed in ARCHITECTURE's `Parallel batches` section). The tester writes all tests + runs checks once after all components land. Mid-flight batch update (in-memory) handles unforeseen file conflicts.
- **One feature-level verify**: instead of a verifier per spec, a single verifier runs after the TEST phase — it runs checks once (unconditional rerun; commands inherited from CONVENTIONS.md via ARCHITECTURE) across all changed files (code + tests) and reviews the whole feature diff for conformance + code review, then attributes findings to components `[M#]` for routing. Lower token usage, shared context.
- **FINISHED/ISSUES protocol**: the implementer (and tester) end their output with a status token. The orchestrator parses it: `FINISHED` → mark done; `ISSUES` → surface to the user (or, in autoMode, mark the component blocked and continue).

## Commands

| Command | What it does |
| --- | --- |
| `/yasdd` | Start a new feature: elicitation → architecture (with self-check + batches + testing) → gate → implement by component → test → verify. |
| `/yasdd-quick-win` | Start a single-shot quick win: elicitation → one fused architecture → implementation → light review. |
| `/yasdd-implement <slug>` | Resume implementing a single feature's components from its STATE.md. |
| `/yasdd-continue` | Resume **every** in-progress feature that still has pending components. |
| `/yasdd-status [slug]` | Print project + feature component status. |
| `/yasdd-goback <slug>` † | Update an already-implemented feature by writing ONE new CHANGES/NN delta. |
| `/yasdd-doubt <slug>` † | Explain an implemented feature concisely (read-only). |
| `/yasdd-init` † | Initialize yasdd for a project (scaffolding + AGENTS.md). |
| `/yasdd-clear` † | Remove all features, quick-wins, CHANGES, and CONVENTIONS.md; reset PROJECT-STATE.md (destructive). |

> † These four have no command wrapper file in `commands/` — they are invoked by loading their skill directly (e.g. via the skill tool, or `Load the skill yasdd-init`). The five commands above them are thin wrappers: each loads its same-named skill (e.g. `/yasdd` loads the `yasdd` skill), which contains the full orchestrator playbook. All skills live in `skills/`.

## Skills (phases & subagents)

| Skill | Role |
| --- | --- |
| `yasdd-elicitation` | Tiered batched elicitation (core 8 + extended 10 if complex/greenfield); greenfield detection → seeds CONVENTIONS.md; Christel & Kang watchlist per round; writes ELICITATION.md. (main session) |
| `yasdd-quick-elicitation` | Quick-win core-only elicitation (8 sections, no extended); greenfield detection; writes `.yasdd/quick-wins/<slug>/ELICITATION.md`. (main session) |
| `yasdd-architect` | Writes ARCHITECTURE.md; absorbs Rules/Cases/Acceptance + Testing + Parallel batches; 10-point self-check (cap 3 iterations); token-cost awareness; CONVENTIONS.md inheritance. (main session) |
| `yasdd-quick-architect` | Fuses design + one lean architecture for a quick win; simplified format (no Components/batches/[M#]); Testing inherits CONVENTIONS.md; writes `.yasdd/quick-wins/<slug>/ARCHITECTURE.md`. (main session) |
| `yasdd-implementer` | Implements ONE component `[M#]`: scoped reads, **code-only** (no tests, no checks), split conformance table (architecture-conformance self-verified; functioning DEFERRED) + changed-files manifest, increments SUMMARY.md, returns FINISHED/ISSUES. (subagent) |
| `yasdd-tester` | Writes unit + e2e tests after all components land; reads ARCHITECTURE.md (Testing + Acceptance `[A#]`); runs checks once (commands inherited from CONVENTIONS.md via ARCHITECTURE); returns FINISHED + test manifest, or ISSUES with classified findings (test-bug vs impl-bug, attributed to components `[M#]`). (subagent) |
| `yasdd-verifier` | ONE feature-level research-only review of code **+ tests** + a **checks rerun** (unconditional; runs lint/typecheck/tests once per feature, across all changed files; commands inherited from CONVENTIONS.md via ARCHITECTURE). Attributes findings to components `[M#]`. (subagent) |
| `yasdd-goback` | Updates an implemented feature with one CHANGES/NN delta in ARCHITECTURE format. (main session) |
| `yasdd-doubt` | Explains a feature (read-only). (main session) |
| `yasdd-init` | Scaffolds `.yasdd/` and config; does NOT create CONVENTIONS.md. (main session) |
| `yasdd-clear` | Wipes features, quick-wins, CHANGES, and CONVENTIONS.md (keeps config). (main session) |

### yasdd-spy (codebase exploration agent)

yasdd ships a dedicated **lightweight** subagent, `yasdd-spy`, for all codebase exploration and feature-tracing tasks. It is defined in `agents/yasdd-spy.md` (frontmatter: `name`, `description`, `mode: subagent`) and intended to run on a fast, inexpensive model (e.g. `anthropic/claude-haiku-4-5`) so that ELICITATION, GOBACK, and VERIFY phases can launch multiple parallel spies without significant token cost.

**Developers should use `yasdd-spy`** (not the harness's generic `explore` agent) whenever a skill or command calls for codebase investigation. The spy traces feature implementations from entry points to data storage, returning `file:line` references and essential-files lists. It also detects **greenfield** repos (no source files) and returns a greenfield signal so the elicitation skill can seed `CONVENTIONS.md`.

To configure a specific model, edit `agents/yasdd-spy.md` and add or change a `model:` frontmatter field (support depends on your agent harness).

## Quick start

1. Run `/yasdd-init` once in your project (creates `.yasdd/`, `config.yml`, `PROJECT-STATE.md`, and updates `AGENTS.md`).
2. Run `/yasdd` and answer the batched questions about your feature.
3. The pipeline authors `ELICITATION.md → ARCHITECTURE.md → STATE.md` (all in the main session), then asks to proceed (unless `autoMode: true`).
4. The orchestrator reads ARCHITECTURE's `Parallel batches`; implementers run code-only in parallel per batch (up to `maxParallelism`), one per component `[M#]`. Then ONE tester writes all tests + runs checks once (commands inherited from CONVENTIONS.md via ARCHITECTURE). Then ONE feature-level verify runs over code + tests (fix → re-test/re-verify, up to 3× each).
5. Done? `SUMMARY.md` has grown with one bullet per implementation across `## Business` (PM language), `## Implemented` (architecture), and `## Files` (changed files); `PROJECT-STATE.md` is updated.

## Configuration

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = architecture → straight to implementation (no gate pause)
maxParallelism: 3    # cap on parallel subagent calls per step + batch size
```

Check commands (lint, typecheck, test) are **project-wide**, captured once in `.yasdd/CONVENTIONS.md` (seeded by elicitation on greenfield, or by the architect on brownfield first feature). Every feature's ARCHITECTURE.md inherits them. This eliminates per-feature test-framework rediscovery.

## CONVENTIONS.md

A project-wide file at `.yasdd/CONVENTIONS.md` captures the project's technical conventions **once** so every feature's ARCHITECTURE.md inherits them instead of re-discovering:

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

| Scenario | When CONVENTIONS.md is created |
|----------|--------------------------------|
| **Greenfield (first feature)** | Elicitation's "Technical environment decision" sub-step seeds it before architecture runs |
| **Brownfield (no CONVENTIONS.md yet)** | Architect detects from `package.json`/`Makefile`/`AGENTS.md` on first feature, writes it so subsequent features inherit |
| **Already exists** | Architect inherits (never re-decides); elicitation skips technical-environment sub-step |

`/yasdd-init` does NOT create CONVENTIONS.md — it's seeded by elicitation/architect on first feature, not at init time (init doesn't know the tech stack yet).

## What lives where

```
.yasdd/
  config.yml
  CONVENTIONS.md                     # project-wide tech conventions (seeded once, inherited by all features)
  PROJECT-STATE.md                   # all features at a glance
  features/<slug>/
    ELICITATION.md                   # tiered: core 8 + extended 10 (if complex/greenfield)
    ARCHITECTURE.md                  # components [M#] + batches + testing + rules/cases/acceptance
    STATE.md                         # per-component impl/test/verify status
    SUMMARY.md                       # Business / Implemented / Files (appended per implementation)
    CHANGES/NN-<change-slug>.md      # goback deltas in ARCHITECTURE format
  quick-wins/<slug>/
    ELICITATION.md                   # core-only (8 sections)
    ARCHITECTURE.md                  # simplified format (no Components/batches/[M#])
    SUMMARY.md                       # Business / Implemented / Files
```

Component status markers in STATE.md: `- [ ]` not started · `- [~]` blocked (failed test or verify) · `- [x]` fully done (impl + test + verify). During implementation the top-level marker stays `[ ]`; it only flips to `[x]` once all three sub-markers are done. Each component has `impl`/`test`/`verify` sub-markers for precise fix-loop routing.

### Quick wins

`/yasdd-quick-win` collapses the full SDD pipeline into a single-shot, stateless flow:

```
ELICITATION (core-only) → ARCHITECTURE (simplified, main session) → IMPLEMENTATION (code-only) → TEST → LIGHT CODE REVIEW
```

- One `ARCHITECTURE.md` per quick win — no `specs/` directory, no `Components` with `[M#]`, no `Parallel batches`.
- No `STATE.md`; inspect the folder directly.
- No `PROJECT-STATE.md` updates.
- Testing section inherits from CONVENTIONS.md (or detects at runtime if absent).

## Greenfield support

yasdd detects greenfield repos (no source files) via `yasdd-spy` and handles them gracefully:

- `yasdd-spy` returns "greenfield — no existing source files found" instead of failing.
- The elicitation skill injects a "Technical environment decision" sub-step (language, framework, test runner, lint, directory structure).
- These decisions seed `CONVENTIONS.md` before architecture runs.
- The first feature is treated as **architecture-defining** — the architect writes the foundational structure (directory layout, shared utilities, base configuration).
- Subsequent features inherit `CONVENTIONS.md` — no re-deciding.

This does NOT add a separate scaffolding step — it folds naturally into the existing elicitation → architecture flow.
