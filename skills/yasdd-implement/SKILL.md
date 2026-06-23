---
name: yasdd-implement
description: "Resume implementation of a feature's components from its STATE.md."
disable-model-invocation: true
---
# yasdd-implement

`$1` = feature slug (`autoMode: false`: optional, list features from `.yasdd/PROJECT-STATE.md` and ask if omitted; `autoMode: true`: use `$1` or the first feature with unimplemented components).

Read `.yasdd/config.yml` once (`autoMode`, `maxParallelism`; defaults: `autoMode = false`, `maxParallelism = 3`). Then:
- `autoMode: false` -> list unimplemented components (those with `impl: pending` in `STATE.md`), ask the user how many/which to implement now (question tool).
- `autoMode: true` -> implement ALL pending components.

Then run the **IMPLEMENT LOOP (step 4)** + **TEST (step 5)** + **FIX-LOOP (step 5b)** + **FINAL VERIFY (step 6)** + **WRAP UP (step 7)** from the `/yasdd` playbook with the `autoMode` rules. Components are identified by `[M#]` from `ARCHITECTURE.md`; parallel batches are read from ARCHITECTURE's `Parallel batches` section (only pending components in each batch). When launching the implementer/tester/verifier subagents, pass the ARCHITECTURE.md path + component ID `[M#]` + config values (`autoMode`, `maxParallelism`) and tell them to use those values instead of re-reading `config.yml`. The tester runs ONCE for the whole feature after all chosen components are implemented (step 5); the verifier runs ONCE for the whole feature after the tester (step 6).
