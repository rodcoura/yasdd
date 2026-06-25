# yasdd

> Yell At Specs, Design Directly — a pragmatic, markdown-only pipeline for AI coding agents.

**Languages:** [English](README.md) · [Português (Brasil)](README.pt-br.md) · [中文](README.cn.md)

---

## Installation

yasdd is pure markdown — no build step, no dependencies. Place `skills/` where your agent harness reads them.

### Recommended: installer script

The `install-to-agents.sh` script copies skills to the locations each tool actually scans:

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
| `~/.agents/` | skills (cross-tool mirror) |
| `~/.claude/` | skills (Claude Code native) |

### Manual: symlinks

Pick one location:

- **Global (all projects):** `~/.agents/` — gives you `~/.agents/skills/yasdd-*/SKILL.md`.
- **Project-local (one repo):** `.agents/` in the project root — `.agents/skills/...`.
- **Custom:** any folder your agent harness loads skills from.

Symlink each directory (safe if the folder already holds other skills):

```bash
# clone
git clone https://github.com/rodcoura/yasdd ~/projects/yasdd

# global install
mkdir -p ~/.agents/skills
for s in ~/projects/yasdd/skills/*; do ln -sf "$s" ~/.agents/skills/; done
```

For a project-local install, repeat the loop with `.agents/` instead of `~/.agents/`.

---

## What is yasdd?

yasdd is a **specless design and delivery framework** made entirely of markdown skills. It gives an AI coding agent a repeatable pipeline to take a vague feature request and turn it into a fully implemented, reviewed feature — without overthinking and without skipping the hard questions. It also has a bug fixing pipeline: investigate root cause → fix → verify.

It is not source code. There is no build system. Everything lives in one directory:

- `skills/` — one folder per skill (`<skill>/SKILL.md`); includes the feature + bug orchestrators, the plan/grill skill, the investigator skill, and subagent instructions.

## How it works

### Feature pipeline

Every feature flows through a lean, user-gated pipeline:

```
0. CONFIG     yasdd-feature reads .yasdd/config.yml (creates with defaults if missing)
1. PLAN        grill + explore → PLAN.md (incl. Test impact, [M#] anchors, inline parallelism)
2. GATE         user reads PLAN.md → accepts OR asks for changes → loop until accepted
3. IMPLEMENT    read PLAN.md → launch implementer subagents per [M#], parallel where possible, sequential on deps
4. GATE         if autoMode:true → skip. If false → user manually tests → vibe-coding fix loop until "no more issues"
5. TEST         ONE tester writes unit tests + confirms impacted tests pass → returns FINISHED/ISSUES
6. VERIFY       ONE verifier runs checks + reviews diff + writes SUMMARY.md (Business/Implemented/Files)
```

PLAN runs in the main session reusing loaded codebase context (zero re-exploration); IMPLEMENT/TEST/VERIFY run as isolated subagents with clean contexts.

### Bug fixing pipeline

Every bug fix flows through a lean, user-gated pipeline:

```
0. CONFIG       yasdd-bug reads .yasdd/config.yml (creates with defaults if missing)
1. INVESTIGATE   trace root cause + git blame + blast radius → FIX.md (incl. fix steps [M#], Test impact)
2. GATE          user reads FIX.md → accepts root cause + fix approach OR asks for changes → loop until accepted
3. FIX           read FIX.md → launch implementer subagents per [M#], code-only, parallel where possible
4. GATE          if autoMode:true → skip. If false → user manually tests → vibe-coding fix loop until "no more issues"
5. TEST          ONE tester writes regression unit tests + confirms impacted tests pass → returns FINISHED/ISSUES
6. VERIFY        ONE verifier runs checks + reviews diff + writes SUMMARY.md (Business/Implemented/Files)
```

INVESTIGATE runs in the main session reusing loaded codebase context; FIX/TEST/VERIFY run as isolated subagents with clean contexts.

Core ideas that make yasdd work:

- **One PLAN.md, no specs decomposition**: the plan skill grills the user (one question at a time with a recommended answer), launches yasdd-spy for codebase investigation, and writes a single PLAN.md carrying components `[M#]` + inline parallelism markers + Rules/Cases/Acceptance with anchors + Test impact. No separate elicitation/architecture artifacts.
- **Inline parallelism markers**: steps carry `*parallel with N*` or `*depends on N*` markers — no separate "Parallel batches" section. The orchestrator (feature or bug) reads the markers to decide what runs in parallel vs sequentially.
- **Acceptance = Given/When/Then**: the happy path + each Case, each checkable by a test. This makes the plan verifiable instead of self-reported.
- **Test impact coverage**: PLAN.md lists NEW tests (for `[A#]`/`[C#]`/`[R#]`) AND IMPACTED existing tests (source file → test file mapping, must stay green). The tester confirms both. This catches breakage of existing tests at TEST phase, not deferred to VERIFY.
- **Manual test gate = vibe-coding loop**: between implementation and unit testing, if `autoMode: false`, the user manually exercises the system and reports issues — the implementer fixes, the user re-tests, loop until "no more issues". No cap. Informal. User drives. Skipped when `autoMode: true`.
- **Code-only implementer + deferred testing**: the implementer is code-only (no tests, no checks) so components with disjoint file sets can run in parallel. The tester writes all unit tests + runs checks once after all components land.
- **One feature-level verify**: a single verifier runs after the TEST phase — it runs checks once (unconditional rerun) across all changed files and reviews the whole feature diff for conformance + code review, then writes SUMMARY.md.
- **FINISHED/ISSUES protocol**: the implementer and tester end their output with a status token. The orchestrator parses it: `FINISHED` → proceed; `ISSUES` → fix-loop or surface to the user.
- **No state tracking**: there is no PROJECT-STATE.md or STATE.md. The orchestrator detects continuation by inspecting artifacts (PLAN.md/FIX.md presence, SUMMARY.md presence, git diff). Two artifacts per feature or bug: PLAN.md/FIX.md + SUMMARY.md.

## Skills

`yasdd-feature` (features) and `yasdd-bug` (bug fixes) are the entry points. The user may also call specific skills manually if they want.

| Skill | Role |
| --- | --- |
| `yasdd-feature` | Feature pipeline entry point. Config bootstrap, continuation detection, pipeline driver: plan → implement → manual test → test → verify. |
| `yasdd-bug` | Bug fixing pipeline entry point. Config bootstrap, continuation detection, pipeline driver: investigate → fix → manual test → test → verify. |
| `yasdd-plan` | Grilling + codebase exploration → single PLAN.md. One question at a time with recommended answer, challenge vague terms, cross-check claims vs code. Detects impacted existing tests. (main session) |
| `yasdd-investigator` | Bug investigation + root cause analysis → single FIX.md. Traces defects backward from symptoms, runs git blame to identify the commits that introduced the bug, assesses blast radius (level 1–5), writes fix steps `[M#]` + Rules/Cases/Acceptance + Test impact. (main session) |
| `yasdd-implementer` | Implements ONE component `[M#]`: scoped reads, **code-only** (no tests, no checks), split conformance table (plan-conformance self-verified; functioning DEFERRED) + changed-files manifest, returns FINISHED/ISSUES. Works with both PLAN.md (features) and FIX.md (bugs). (subagent) |
| `yasdd-tester` | Writes UNIT TESTS ONLY (no e2e/integration; unit tests chain real functions to cover the business flow) after all components land; reads CONVENTIONS.md (commands) + plan artifact (Acceptance `[A#]` + Test impact); confirms impacted tests stay green; runs checks once; returns FINISHED or ISSUES with classified findings (test-bug vs impl-bug vs impl-bug-impacted). (subagent) |
| `yasdd-verifier` | ONE feature/bug-level research-only review of code + unit tests + a checks rerun (unconditional; runs lint/typecheck/tests once per feature/bug, across all changed files; commands from CONVENTIONS.md). Cross-references Test impact. Attributes findings to components `[M#]`. Writes SUMMARY.md. (subagent) |
| `yasdd-spy` | Lightweight code analyst that traces feature implementations from entry points to data storage. Auto-invoked for codebase investigation + greenfield detection. Detects impacted existing tests. (auto-invoked; runs on a fast inexpensive model) |

### yasdd-spy (auto-invoked)

`yasdd-spy` is the only skill with `disable-model-invocation: false` — it is auto-invoked whenever a skill calls for codebase investigation. It is intended to run on a fast, inexpensive model (e.g. `anthropic/claude-haiku-4-5`) so that the PLAN phase can launch multiple parallel spies without significant token cost.

The spy traces feature implementations from entry points to data storage, returning `file:line` references and essential-files lists. It also detects **greenfield** repos (no source files) and returns a greenfield signal so the plan skill can seed `CONVENTIONS.md`. When asked, it maps source files → existing test files for the Test impact section.

To configure a specific model, edit `skills/yasdd-spy/SKILL.md` and add a `model:` frontmatter field (support depends on your agent harness).

## Quick start

### Feature implementation

1. Load the `yasdd-feature` skill with your feature request as arguments.
2. The orchestrator creates `.yasdd/config.yml` (if missing), derives a slug, and loads `yasdd-plan`.
3. The plan skill grills you (one question at a time with recommended answers), launches yasdd-spy subagents for codebase investigation, and writes `PLAN.md`. It validates the plan and presents it to you for acceptance.
4. On accept, the orchestrator reads PLAN.md's steps with `[M#]` anchors + inline parallelism markers. Implementers run code-only in parallel (up to `maxParallelism`), one per component `[M#]`.
5. If `autoMode: false`, you manually test the running system and report issues (vibe-coding fix loop until "no more issues"). Then ONE tester writes unit tests + confirms impacted tests pass + runs checks once. Then ONE feature-level verify runs over code + tests (fix → re-verify, up to 3×) and writes SUMMARY.md.
6. Done? `SUMMARY.md` has `## Business` (PM language), `## Implemented` (architecture), `## Files` (changed files).

### Bug fixing

1. Load the `yasdd-bug` skill with your bug report as arguments.
2. The orchestrator creates `.yasdd/config.yml` (if missing), derives a slug, and loads `yasdd-investigator`.
3. The investigator parses the bug report, traces the data flow backward from the entry point to the root cause, runs `git blame` to identify the commits that introduced the bug (Caused By), assesses the blast radius (level 1–5), and writes `FIX.md` with fix steps `[M#]` + Rules/Cases/Acceptance + Test impact. It presents the investigation to you for acceptance.
4. On accept, the orchestrator reads FIX.md's fix steps with `[M#]` anchors. Implementers run code-only (up to `maxParallelism`), one per component `[M#]`.
5. If `autoMode: false`, you manually test the running system and confirm the bug is fixed (vibe-coding fix loop until "no more issues"). Then ONE tester writes regression unit tests + confirms impacted tests pass + runs checks once. Then ONE bug-level verify runs over code + tests (fix → re-verify, up to 3×) and writes SUMMARY.md.
6. Done? `SUMMARY.md` has `## Business` (PM language), `## Implemented` (architecture), `## Files` (changed files).

## Configuration

`.yasdd/config.yml`:

```yaml
autoMode: false        # true = skip manual test gate, proceed straight to TEST; false = pause for manual testing
maxParallelism: 3      # cap on parallel subagent calls per step + batch size
```

Check commands (lint, typecheck, test) are **project-wide**, captured once in `.yasdd/CONVENTIONS.md` (seeded by the plan skill on the first feature). The tester + verifier read CONVENTIONS.md directly. Bug fixes inherit the same CONVENTIONS.md.

## CONVENTIONS.md

A project-wide file at `.yasdd/CONVENTIONS.md` captures the project's technical conventions **once** so the tester + verifier inherit them directly instead of re-discovering:

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
| **Greenfield (first feature)** | The plan skill's "Technical environment decision" sub-step seeds it before implementation runs |
| **Brownfield (no CONVENTIONS.md yet)** | The plan skill detects from `package.json`/`Makefile`/`AGENTS.md` on first feature, writes it so subsequent features inherit |
| **Already exists** | The plan skill inherits (never re-decides) |

## What lives where

```
.yasdd/
  config.yml                         # autoMode + maxParallelism
  CONVENTIONS.md                     # project-wide tech conventions (seeded once; tester + verifier read directly)
  features/<slug>/
    PLAN.md                          # the single source of truth (goal, steps [M#], data, interfaces, rules, cases, acceptance, test impact, critical files, verification)
    SUMMARY.md                       # Business / Implemented / Files (written by verifier)
  bugs/<bug-slug>/
    FIX.md                           # investigation report + fix plan (root cause, data flow trace, caused by, blast radius, fix steps [M#], rules, cases, acceptance, test impact)
    SUMMARY.md                       # Business / Implemented / Files (written by verifier)
```

Two artifacts per feature: `PLAN.md` (written by the plan skill, accepted by the user) and `SUMMARY.md` (written by the verifier at the end). Two artifacts per bug: `FIX.md` (written by the investigator, accepted by the user) and `SUMMARY.md` (written by the verifier at the end).

## Greenfield support

yasdd detects greenfield repos (no source files) via `yasdd-spy` and handles them gracefully:

- `yasdd-spy` returns "greenfield — no existing source files found" instead of failing.
- The plan skill injects a "Technical environment decision" sub-step (language, framework, test runner, lint, directory structure).
- These decisions seed `CONVENTIONS.md` before implementation runs.
- Subsequent features inherit `CONVENTIONS.md` — no re-deciding.

This does NOT add a separate scaffolding step — it folds naturally into the existing plan flow.
