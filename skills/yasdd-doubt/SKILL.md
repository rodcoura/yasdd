---
name: yasdd-doubt
description: Explains an implemented feature concisely: what it does, key entry points (file:line), how it works, known gaps. Read-only; does not edit.
disable-model-invocation: true
---
# yasdd-doubt

Input: feature slug (`$1`). Run in the MAIN session.

## Process
1. Read `.yasdd/features/<slug>/SUMMARY.md`, `ARCHITECTURE.md`, and `STATE.md`.
2. Optionally launch ONE `yasdd-spy` subagent in parallel to inspect the current implementation and confirm entry points (file:line).
3. Output a concise explanation:
   - What the feature does (2-3 sentences).
   - Key entry points: `file:line — what`.
   - How it works (terse flow, by component `[M#]`).
   - Known gaps/deviations (from `STATE.md` components with `test: FAIL` / `verify: pending` / `[~]` blocked markers and reading the code).

## Rules
- Read-only; do not edit code or architecture.
- If the feature isn't implemented, say so.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
