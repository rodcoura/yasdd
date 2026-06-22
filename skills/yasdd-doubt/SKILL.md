---
name: yasdd-doubt
description: Explains an implemented feature concisely: what it does, key entry points (file:line), how it works, known gaps. Read-only; does not edit.
---
# yasdd-doubt

Input: feature slug (`$1`). Run in the MAIN session.

## Process
1. Read `.yasdd/features/<slug>/SUMMARY.md` and `STATE.md`. Read `.yasdd/config.yml` for `maxParallelism` (default 3).
2. Optionally launch up to ONE `yasdd-spy` subagent (fallback `general`; within `maxParallelism`) to inspect the current implementation and confirm entry points (file:line).
3. Output a concise explanation:
   - What the feature does (2-3 sentences).
   - Key entry points: `file:line — what`.
   - How it works (terse flow).
   - Known gaps/deviations (from `STATE.md` `- [~]` blocked specs and reading the code).

## Rules
- Read-only; do not edit code or specs.
- If the feature isn't implemented, say so.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the spec.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
