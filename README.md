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

Every feature flows through a 7-step pipeline:

```
0. config          read .yasdd/config.yml
1. DISCUSS         grill the user until the feature is gap-free  → DISCUSS.md
2. DESIGN          pragmatic design from the discussion          → DESIGN.md
3. SPECS           decompose the design into 1..maxSpecs specs     → specs/*.md + STATE.md
4. PLAN            pick which specs to implement now (or all in autoMode)
5. IMPLEMENT LOOP  per spec, sequential: implementer → mark done (no per-spec verify)
6. FINAL VERIFY    ONE feature-level review + tests-green gate over the whole diff (cap 3 rounds)
7. WRAP UP         update project state
```

Three core ideas make yasdd work:

- **Lean, self-sufficient specs**: each spec is a single page (Refs / Goal / I/O / Data / Interfaces / Rules / Scenarios / **Acceptance** / Out of scope) — it carries the concrete data shapes and interface signatures needed to implement it, so the implementer never needs DESIGN.md. No prose padding.
- **Acceptance = Given/When/Then**: the happy path + each Scenario, each checkable by a test. This makes the "functioning spec" rule verifiable instead of self-reported.
- **One feature-level verify**: instead of a verifier per spec, a single verifier runs after all specs are implemented — it runs the tests-green gate once across all changed files and reviews the whole feature diff for conformance + code review, then attributes findings to specs for routing. Lower token usage, shared context.
- **FINISHED/ISSUES protocol**: the implementer ends its output with a status token. The orchestrator parses it: `FINISHED` → mark done; `ISSUES` → surface to the user (or, in autoMode, mark the spec blocked with `- [~]` and continue).

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

## Skills (subagents)

| Skill | Role |
| --- | --- |
| `yasdd-discuss` | Batched elicitation; writes DISCUSS.md. |
| `yasdd-quick-discuss` | Quick-win batched elicitation; writes `.yasdd/quick-wins/<slug>/DISCUSS.md`. |
| `yasdd-designer` | Writes DESIGN.md; defines components, data, interfaces, risks, **Non-functional** NFRs. |
| `yasdd-specs` | Decomposes DESIGN into specs; carries NFRs into spec Rules. |
| `yasdd-quick-spec` | Fuses design + one lean spec for a quick win; writes `.yasdd/quick-wins/<slug>/SPEC.md`. |
| `yasdd-implementer` | Implements ONE spec: scoped reads, code + minimal tests, conformance table, increments SUMMARY.md (Business/Implemented/Files), returns FINISHED/ISSUES. Reused by quick wins with a path override. |
| `yasdd-verifier` | ONE feature-level research-only review + a **tests-green gate** (runs lint/typecheck/tests once per feature, across all changed files). Reused by quick wins with a lighter, single-track override. |
| `yasdd-goback` | Updates an implemented feature with one new spec. |
| `yasdd-doubt` | Explains a feature (read-only). |
| `yasdd-init` | Scaffolds `.yasdd/` and config. |
| `yasdd-clear` | Wipes features (keeps config). |

## Quick start

1. Run `/yasdd-init` once in your project (creates `.yasdd/`, `config.yml`, `PROJECT-STATE.md`, and updates `AGENTS.md`).
2. Run `/yasdd` and answer the batched questions about your feature.
3. The pipeline authors `DISCUSS.md → DESIGN.md → specs/ → STATE.md`, then offers to implement.
4. Specs are implemented sequentially (implementer per spec), then ONE feature-level verify runs over the whole feature (fix → re-verify, up to 3×).
5. Done? `SUMMARY.md` has grown with one bullet per implementation across `## Business` (PM language), `## Implemented` (architecture), and `## Files` (changed files); `PROJECT-STATE.md` is updated.

## Configuration

`.yasdd/config.yml`:

```yaml
autoMode: false      # true = implement all specs without asking
maxParallelism: 3    # cap on parallel subagent calls per step
maxSpecs: 5          # cap on specs generated from one DESIGN
```

## What lives where

```
.yasdd/
  config.yml
  PROJECT-STATE.md                 # all features at a glance
  features/<slug>/
    DISCUSS.md
    DESIGN.md
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
DISCUSS → SPEC (fused design + spec) → IMPLEMENTATION → LIGHT CODE REVIEW
```

- One `SPEC.md` per quick win — no `specs/` directory.
- No `STATE.md`; inspect the folder directly.
- No `PROJECT-STATE.md` updates.
