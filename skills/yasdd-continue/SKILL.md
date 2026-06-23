---
name: yasdd-continue
description: "Resume every in-progress feature from the exact step where it stopped (elicitation, architecture, gate, implement, test, fix-loop, verify, or wrap up). Detects the stopped step from PROJECT-STATE.md + feature artifacts."
disable-model-invocation: true
---
# yasdd-continue

Read `.yasdd/config.yml` once for `autoMode` and `maxParallelism`; if missing, use defaults `autoMode: false`, `maxParallelism: 3` (read-only — do NOT create it; only `yasdd-orchestrator`/`yasdd-init`/`yasdd-status`/`yasdd-quick-win` create it).

Always start from `.yasdd/PROJECT-STATE.md`. If it is missing, tell the user yasdd is not initialized and suggest `yasdd-init`, then stop. Otherwise, for each feature row, determine the **stopped step** by inspecting the feature's artifacts in pipeline order (below), then resume from that step using the `yasdd-orchestrator` playbook for that step onward.

## Step detection (per feature, in pipeline order)
Inspect `.yasdd/features/<slug>/`:

1. **ELICITATION.md missing** → stopped at **ELICITATION (step 1)**. Load `yasdd-elicitation` and run it from the start.
2. **ELICITATION.md exists but `## Open questions` is non-empty** → stopped mid-**ELICITATION**. Load `yasdd-elicitation` and continue the elicitation loop (do not re-ask resolved questions; close the remaining open gaps).
3. **ELICITATION.md done (no open questions) but `ARCHITECTURE.md` missing, OR `ARCHITECTURE.md` exists but `STATE.md` missing** → stopped at **ARCHITECTURE (step 2)**. Load `yasdd-architect` and run it.
4. **`ARCHITECTURE.md` + `STATE.md` exist and every component is `impl: pending`** → stopped at the **GATE (step 3)**.
   - `autoMode: true` → proceed straight to IMPLEMENT (step 4).
   - `autoMode: false` → ask the user: "Architecture ready. Can I proceed to implementation?" Proceed (step 4) on confirmation, otherwise wait.
5. **`STATE.md` has ≥1 component with `impl: pending`** → stopped at **IMPLEMENT LOOP (step 4)**. Resume it.
6. **All `impl: done`, but `test: pending` (tester hasn't run yet)** → stopped at **TEST (step 5)**. Run the tester.
7. **`test: ISSUES` (tester returned issues, fix-loop unresolved)** → stopped at **FIX-LOOP (step 5b)**. Route findings and loop.
8. **All `test: done`, but `verify: pending`** → stopped at **FINAL VERIFY (step 6)**. Run the verifier.
9. **`verify: ISSUES`** → stopped at the **FINAL VERIFY fix loop (step 6)**. Route findings and loop.
10. **All components `impl + test + verify: done`** → stopped at **WRAP UP (step 7)**. Run wrap up (update the PROJECT-STATE.md row status + add the SUMMARY link).

If the feature row in PROJECT-STATE.md is already `done` AND every component is fully done, skip it (nothing to continue). Do NOT skip features that are still in ELICITATION or ARCHITECTURE — resume them.

## Selection
- None in-progress → tell the user "nothing to continue" and stop.
- `autoMode: false` → list each in-progress feature with its detected stopped step + pending components; ask the user (question tool) which to continue now (recommend: all, in order).
- `autoMode: true` → continue ALL in-progress features, in PROJECT-STATE order.

## Resuming
For each chosen feature, run the `yasdd-orchestrator` playbook **from the detected step onward**: ELICITATION and ARCHITECTURE run in the MAIN session via their skills; IMPLEMENT (step 4), TEST (step 5), FIX-LOOP (step 5b), and FINAL VERIFY (step 6) launch subagents; WRAP UP (step 7) runs inline. Pass the ARCHITECTURE.md path + component ID `[M#]` + config values (`autoMode`, `maxParallelism`) to each implementer/tester/verifier subagent and tell them to use those values instead of re-reading `config.yml`. The tester runs ONCE for the whole feature after all chosen components are implemented (step 5); the verifier runs ONCE for the whole feature after the tester (step 6). Report each feature's outcome after it finishes. Honor the implementer FINISHED/ISSUES and tester FINISHED/ISSUES return protocols.

## Rules
- Always start from PROJECT-STATE.md; never guess a feature's state.
- When ELICITATION.md has open questions, continue ELICITATION — do not skip ahead to architecture.
- Handoffs are file references (pass slug/paths/component IDs, not big text). Stay terse.
- For skills discovery: if the skill tool does not find a yasdd skill, fall back to reading `~/.agents/skills/<name>/SKILL.md` directly.
