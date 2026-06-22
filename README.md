# yasdd

> Yet Another Spec-Driven Development framework — a pragmatic, markdown-only SDD pipeline for AI coding agents.

**Languages:** [English](README.md) · [Português (Brasil)](README.pt-br.md) · [中文](README.cn.md)

---

## Installation

yasdd is pure markdown — no build step, no dependencies. Place `skills/` and `commands/` where your agent harness reads them. Pick one location:

- **Global (all projects):** `~/.agents/` — gives you `~/.agents/skills/yasdd-*/SKILL.md` and `~/.agents/commands/yasdd*.md`.
- **Project-local (one repo):** `.agents/` in the project root — `.agents/skills/...` and `.agents/commands/...`.
- **Custom:** any folder your agent harness loads skills/commands from.

Symlink each skill + command (safe if the folder already holds other skills):

```bash
# clone
git clone https://github.com/rodcoura/yasdd ~/projects/yasdd

# global install
mkdir -p ~/.agents/skills ~/.agents/commands ~/.agents/prompts
for s in ~/projects/yasdd/skills/*; do ln -sf "$s" ~/.agents/skills/; done
for c in ~/projects/yasdd/commands/*.md; do ln -sf "$c" ~/.agents/commands/; done
for p in ~/projects/yasdd/prompts/*.md; do ln -sf "$p" ~/.agents/prompts/; done
```

For a project-local install, repeat the loops with `.agents/` instead of `~/.agents/`. Then run `/yasdd-init` in your project to scaffold `.yasdd/` and update `AGENTS.md`.

---

## What is yasdd?

yasdd is a **spec-driven development framework** made entirely of markdown skills and commands. It gives an AI coding agent a repeatable pipeline to take a vague feature request and turn it into a fully implemented, reviewed feature — without overthinking and without skipping the hard questions.

It is not source code. There is no build system. Everything lives in `commands/` (the user-facing playbook commands) and `skills/` (the subagent instructions).

## How it works

Every feature flows through an 8-step pipeline:

```
0. config          read .yasdd/config.yml
1. DISCUSS         grill the user until the feature is gap-free  (main session)  → DISCUSS.md
2. DESIGN          pragmatic design from the discussion          (main session)  → DESIGN.md
2b. TESTING        test-architecture handoff                    (main session)  → TESTING.md
3. SPECS           decompose the design into 1..maxSpecs specs    (main session)  → specs/*.md + STATE.md
4. PLAN            pick which specs to implement now + compute parallel batches from Refs
5. IMPLEMENT LOOP  per batch, parallel (up to maxParallelism): code-only implementers → mark done (no gate)
6. TEST            ONE tester writes unit + e2e tests + runs the gate once over the whole feature
6b. FIX-LOOP       if bugs: orchestrator writes fix-plan inline → implementer with "run all checks" → re-test (cap 3 rounds)
7. FINAL VERIFY    ONE feature-level review + tests-green gate (unconditional rerun) over code + tests (cap 3 rounds)
8. WRAP UP         update project state
```

DISCUSS/DESIGN/TESTING/SPECS run in the main session reusing loaded codebase context (zero re-exploration); IMPLEMENT/TEST/VERIFY run as isolated subagents with clean contexts.

Five core ideas make yasdd work:

- **Lean, self-sufficient specs**: each spec is a single page (Refs / Goal / I/O / Data / Interfaces / Rules / Scenarios / **Acceptance** / Out of scope) — it carries the concrete data shapes and interface signatures needed to implement it, so the implementer never needs DESIGN.md. No prose padding.
- **Acceptance = Given/When/Then**: the happy path + each Scenario, each checkable by a test. This makes the "functioning spec" rule verifiable instead of self-reported.
- **Main-session context reuse**: DESIGN, TESTING, and SPECS run inline in the main session, reusing the codebase context loaded during DISCUSS — no re-exploration subagents, lower token usage.
- **Parallel implementation via deferred testing**: the implementer is code-only (no tests, no gate) so specs with disjoint file sets can run in parallel batches. The tester writes all tests + runs the gate once after all specs land. The orchestrator computes parallel batches from spec `Refs` + DESIGN's `Components` (AI judgment, inline — no script).
- **One feature-level verify**: instead of a verifier per spec, a single verifier runs after the TEST phase — it runs the tests-green gate once (unconditional rerun) across all changed files (code + tests) and reviews the whole feature diff for conformance + code review, then attributes findings to specs for routing. Lower token usage, shared context.
- **FINISHED/ISSUES protocol**: the implementer (and tester) end their output with a status token. The orchestrator parses it: `FINISHED` → mark done; `ISSUES` → surface to the user (or, in autoMode, mark the spec blocked with `- [~]` and continue).

## Commands

| Command | What it does |
| --- | --- |
| `/yasdd` | Start a new feature: discuss → design → specs → state, then offer to implement. |
| `/yasdd-quick-win` | Start a single-shot quick win: discuss → one fused spec → implementation → light review. |
| `/yasdd-implement <slug>` | Resume implementing a single feature's specs from its STATE.md. |
| `/yasdd-continue` | Resume **every** in-progress feature that still has pending specs. |
| `/yasdd-status [slug]` | Print project + feature spec status. |
| `/yasdd-goback <slug>` | Update an already-implemented feature by writing ONE new spec. |
| `/yasdd-doubt <slug>` | Explain an implemented feature concisely (read-only). |
| `/yasdd-init` | Initialize yasdd for a project (scaffolding + AGENTS.md). |
| `/yasdd-clear` | Remove all features and reset PROJECT-STATE.md (destructive). |

## Skills (phases & subagents)

| Skill | Role |
| --- | --- |
| `yasdd-discuss` | Batched elicitation; writes DISCUSS.md. (main session) |
| `yasdd-quick-discuss` | Quick-win batched elicitation; writes `.yasdd/quick-wins/<slug>/DISCUSS.md`. (main session) |
| `yasdd-designer` | Writes DESIGN.md; defines components, data, interfaces, risks, **Non-functional** NFRs; partitions specs by module/file boundaries. (main session) |
| `yasdd-test-design` | Writes TESTING.md (test-architecture handoff) right after DESIGN. (main session) |
| `yasdd-specs` | Decomposes DESIGN into specs; carries NFRs into spec Rules; each spec's `Refs` declares file scope for parallel batch computation. (main session) |
| `yasdd-quick-spec` | Fuses design + one lean spec for a quick win; writes `.yasdd/quick-wins/<slug>/SPEC.md`. (main session) |
| `yasdd-implementer` | Implements ONE spec: scoped reads, **code-only** (no tests, no gate), split conformance table (spec-conformance self-verified; functioning DEFERRED) + changed-files manifest, increments SUMMARY.md, returns FINISHED/ISSUES. (subagent) |
| `yasdd-tester` | Writes unit + e2e tests after all specs land; reads TESTING.md + conformance tables + manifest; runs the gate once; returns FINISHED + test manifest, or ISSUES with classified findings (test-bug vs impl-bug). (subagent) |
| `yasdd-verifier` | ONE feature-level research-only review of code **+ tests** + a **tests-green gate** (unconditional rerun; runs lint/typecheck/tests once per feature, across all changed files). (subagent) |
| `yasdd-goback` | Updates an implemented feature with one new spec. (main session) |
| `yasdd-doubt` | Explains a feature (read-only). (main session) |
| `yasdd-init` | Scaffolds `.yasdd/` and config. (main session) |
| `yasdd-clear` | Wipes features (keeps config). (main session) |

### yasdd-spy (codebase exploration agent)

yasdd ships a dedicated **lightweight** subagent, `yasdd-spy`, for all codebase exploration and feature-tracing tasks. It is configured with a fast, inexpensive model (e.g. `anthropic/claude-haiku-4-5`) so that DISCUSS, GOBACK, and VERIFY phases can launch multiple parallel spies without significant token cost.

**Developers should use `yasdd-spy`** (not the harness's generic `explore` agent) whenever a skill or command calls for codebase investigation. The spy traces feature implementations from entry points to data storage, returning `file:line` references and essential-files lists.

To use a different lightweight model, edit `agents/yasdd-spy.md` and change the `model:` frontmatter field.

## Quick start

1. Run `/yasdd-init` once in your project (creates `.yasdd/`, `config.yml`, `PROJECT-STATE.md`, and updates `AGENTS.md`).
2. Run `/yasdd` and answer the batched questions about your feature.
3. The pipeline authors `DISCUSS.md → DESIGN.md → TESTING.md → specs/ → STATE.md` (all in the main session), then offers to implement.
4. The orchestrator computes parallel batches from spec `Refs` + DESIGN's `Components`; implementers run code-only in parallel per batch (up to `maxParallelism`). Then ONE tester writes all tests + runs the gate once. Then ONE feature-level verify runs over code + tests (fix → re-test/re-verify, up to 3× each).
5. Done? `SUMMARY.md` has grown with one bullet per implementation across `## Business` (PM language), `## Implemented` (architecture), and `## Files` (changed files); `PROJECT-STATE.md` is updated.

## Configuration

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = implement all specs without asking
maxParallelism: 3    # cap on parallel subagent calls per step
maxSpecs: 5          # cap on specs generated from one DESIGN
gate:                # detected once at init; reused by tester/verifier/fix-loop
  testCmd: ""        # e.g. "npm test"; empty = detect at runtime
  lintCmd: ""        # e.g. "npm run lint"; empty = detect at runtime
  typecheckCmd: ""   # e.g. "npm run typecheck"; empty = detect at runtime
```

## What lives where

```
.yasdd/
  config.yml
  PROJECT-STATE.md                 # all features at a glance
  features/<slug>/
    DISCUSS.md
    DESIGN.md
    TESTING.md                     # test-architecture handoff (framework, locations, fixtures, acceptance mapping)
    MANIFEST.md                    # lightweight spec/file/dependency index for parallel batch computation
    STATE.md                        # spec checklist: [ ] [x] [~]
    SUMMARY.md                      # Business / Implemented / Files (appended per implementation)
    specs/NN-<spec-slug>.md
  quick-wins/<slug>/
    DISCUSS.md
    SPEC.md                         # fused design + one lean spec
    SUMMARY.md                      # Business / Implemented / Files
```

Spec status markers: `- [ ]` unimplemented · `- [x]` done · `- [~]` blocked.

### Quick wins

`/yasdd-quick-win` collapses the full SDD pipeline into a single-shot, stateless flow:

```
DISCUSS → SPEC (fused design + spec, main session) → IMPLEMENTATION (code-only) → TEST → LIGHT CODE REVIEW
```

- One `SPEC.md` per quick win — no `specs/` directory.
- No `TESTING.md` (single spec — the tester derives test architecture from the project's existing framework).
- No `STATE.md`; inspect the folder directly.
- No `PROJECT-STATE.md` updates.
