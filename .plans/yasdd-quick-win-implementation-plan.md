# Plan: yasdd Quick-Win Command

## Goal

Create `/yasdd-quick-win`, a lightweight variant of yasdd that collapses the full SDD pipeline into a single-shot, stateless flow:

```
DISCUSS → SINGLE SPEC (fused design + spec) → IMPLEMENTATION → LIGHT CODE REVIEW
```

Results live in `.yasdd/quick-wins/<slug>/` with only `DISCUSS.md`, `SPEC.md`, and `SUMMARY.md`. No `STATE.md`, no `specs/` directory, and no registration in `PROJECT-STATE.md`.

## Decisions locked

- **Skill strategy:** Option A — create **2 new skills** (`yasdd-quick-discuss`, `yasdd-quick-spec`) and **reuse 2 existing skills** (`yasdd-implementer`, `yasdd-verifier`) with explicit quick-win override prompts.
- **Paths:** every artifact is under `.yasdd/quick-wins/<slug>/`, never `.yasdd/features/<slug>/`.
- **autoMode behavior:** respect `autoMode` from `.yasdd/config.yml`. `autoMode:false` asks before implementing; `autoMode:true` proceeds automatically.
- **Code review depth:** lighter review — run the tests-green gate + the business-logic/spec-conformance track only. Skip security, performance, deploy-safety, duplication, and dead-code tracks.
- **No state management:** no `STATE.md`, no `PROJECT-STATE.md` updates for quick wins.

## Folder layout

```
.yasdd/
  config.yml
  quick-wins/<slug>/
    DISCUSS.md
    SPEC.md
    SUMMARY.md
```

## Pipeline

```
0. config          read .yasdd/config.yml (create with defaults if missing)
1. DISCUSS         main session + explore subagents (≤ maxParallelism) → DISCUSS.md
2. SPEC            ONE general subagent → SPEC.md (fused design + lean spec)
3. PLAN            autoMode:false → ask user before implementing; autoMode:true → auto-proceed
4. IMPLEMENTATION  general subagent (reuse yasdd-implementer, quick-win override)
                   → code + tests + SUMMARY.md
5. CODE REVIEW     general subagent (reuse yasdd-verifier, lighter override)
                   → findings | NO_FINDINGS; re-loop cap 3
```

## Files to create / change

### 1. `skills/yasdd-quick-discuss/SKILL.md` (new)

Trimmed, quick-win version of `yasdd-discuss`.

- Main session, batched elicitation.
- Confirm kebab-case slug. Create `.yasdd/quick-wins/<slug>/` and `DISCUSS.md`.
- Read `.yasdd/config.yml` for `maxParallelism`.
- Launch up to `maxParallelism` `explore` subagents in parallel (fallback `general`) for codebase-first investigation.
- Ask ALL open questions in ONE `question` call per round, each with a clearly marked RECOMMENDED answer. Repeat rounds until gaps/inferences/misunderstandings are closed.
- Dense notes under headings: Goal & why, I/O, Constraints, Edge & error cases, Dependencies on existing code, Non-goals, Unknowns, Open questions.
- Final add-anything check, then `## Summary` for handoff to spec.
- Do NOT create `STATE.md`, `PROJECT-STATE.md`, or `specs/`.

### 2. `skills/yasdd-quick-spec/SKILL.md` (new)

Combines the responsibilities of `yasdd-designer` + `yasdd-specs` into a single spec.

- Runs as a `general` subagent.
- Input: slug + config values from `.yasdd/config.yml`.
- Read `.yasdd/quick-wins/<slug>/DISCUSS.md`.
- Write `.yasdd/quick-wins/<slug>/SPEC.md` with the fused format:

```md
# Quick Win: <title>

Refs: <existing file paths + symbols>
Approach: <2-4 sentences: how it works, key decisions>
Components: <new/changed modules, one line each>
Data: <deltas only>
Interfaces: <signpoints/functions/signatures, deltas only>
Goal: <1-2 sentences: what & why>
I/O: <inputs/outputs>
Rules: <invariants>
Scenarios: <edge + error cases only>
Acceptance: <Given/When/Then: happy path + each Scenario, test-checkable>
Out of scope: <non-goals>
```

- Reference existing code; do not re-declare existing types.
- Carry material non-functional requirements into the `Rules` section.
- Do NOT create `STATE.md`, `specs/`, or update `PROJECT-STATE.md`.

### 3. `commands/yasdd-quick-win.md` (new)

Orchestrator playbook. Mirrors the structure of `commands/yasdd.md` but scoped to quick wins.

- Load `yasdd-quick-discuss` in the main session.
- Launch the `yasdd-quick-spec` subagent (general type).
- Respect `autoMode` for the implementation decision.
- Launch `yasdd-implementer` with this quick-win override:

```
This is a QUICK WIN. Read the spec at .yasdd/quick-wins/<slug>/SPEC.md
(NOT specs/NN-*.md). Write SUMMARY.md to .yasdd/quick-wins/<slug>/SUMMARY.md
(NOT .yasdd/features/<slug>/SUMMARY.md). Do NOT read or write STATE.md
or PROJECT-STATE.md — they do not exist for quick wins.
```

- Parse implementer return status: `FINISHED` → proceed to review; `ISSUES` → surface or append blocker note depending on `autoMode`.
- Launch `yasdd-verifier` with this lighter override:

```
This is a QUICK WIN. Run ONLY: (1) the tests-green gate (step 0), and
(2) the business-logic track + spec conformance against
.yasdd/quick-wins/<slug>/SPEC.md. Spawn at most ONE explore subagent for
the business-logic track. Skip security, performance, deploy-safety,
duplication, and dead-code tracks. Report findings or NO_FINDINGS using
the standard output format.
```

- Re-loop implementer → verifier up to 3 times when findings are returned.
- Wrap up by reporting the outcome and the location of `SUMMARY.md`.

Also create `prompts/yasdd-quick-win.md` as a mirror, matching the existing `commands/` / `prompts/` convention.

### 4. README updates

Update `README.md`, `README.pt-br.md`, `README.cn.md`:

- Add `/yasdd-quick-win` row to the Commands table.
- Add a "Quick wins" subsection under "What lives where" showing `.yasdd/quick-wins/<slug>/` content.
- Add `yasdd-quick-discuss` and `yasdd-quick-spec` rows to the Skills table.
- Note that implementer and verifier are reused with quick-win overrides.

### 5. Global install symlinks (existing convention)

```bash
ln -sf /Users/rodcoura/Projects/yasdd/skills/yasdd-quick-discuss ~/.agents/skills/
ln -sf /Users/rodcoura/Projects/yasdd/skills/yasdd-quick-spec ~/.agents/skills/
ln -sf /Users/rodcoura/Projects/yasdd/commands/yasdd-quick-win.md ~/.agents/commands/
ln -sf /Users/rodcoura/Projects/yasdd/prompts/yasdd-quick-win.md ~/.agents/prompts/
```

## Key quick-win overrides (so reused skills avoid full-SDD mode)

| Existing skill | Hardcoded SDD behavior | Quick-win override |
|---|---|---|
| `yasdd-implementer` step 6 | Reads/writes `.yasdd/features/<slug>/SUMMARY.md` | Redirect to `.yasdd/quick-wins/<slug>/SUMMARY.md`; spec path = `SPEC.md` |
| `yasdd-implementer` | Assumes `STATE.md` / `PROJECT-STATE.md` exist | "Do NOT read/write `STATE.md` or `PROJECT-STATE.md`" |
| `yasdd-verifier` step 2 | Spawns up to 6 parallel tracks | "Run ONLY tests-green gate + business-logic/spec-conformance; spawn ≤1 explore subagent" |
| `yasdd-verifier` step 1 | Grounds review in feature specs | Ground in `.yasdd/quick-wins/<slug>/SPEC.md` |

## Config values from `.yasdd/config.yml`

- `autoMode`: drives whether the pipeline asks before implementing.
- `maxParallelism`: caps parallel explore subagents in DISCUSS and the verifier track.
- `maxSpecs`: ignored for quick wins (always exactly one SPEC.md).

## Out of scope

- No `/yasdd-quick-implement` resume command (quick wins are single-shot).
- No `/yasdd-quick-status` command (no STATE to read; inspect the folder directly).
- No `/yasdd-quick-doubt` command (defer to a later need).
- No dedicated quick-win implementer/verifier skills (reuse with override was chosen).

## Validation

1. Read each new skill and the command end-to-end; confirm all paths use `.yasdd/quick-wins/<slug>/`.
2. Grep new files for `features/` to ensure no leftover full-SDD paths.
3. Confirm override prompts explicitly nullify `STATE.md` / `PROJECT-STATE.md` for the reused implementer/verifier.
4. Dry-run `/yasdd-quick-win` in a scratch project and verify the three artifacts land in the quick-wins folder.
