---
description: Resume implementation of a feature's specs from its STATE.md.
---
# /yasdd-implement

`$1` = feature slug (`autoMode: false`: optional, list features from `.yasdd/PROJECT-STATE.md` and ask if omitted; `autoMode: true`: use `$1` or the first feature with unimplemented specs).

Read `.yasdd/config.yml` once (`autoMode`, `maxParallelism`, and `maxSpecs`; all have defaults: `autoMode = false`, `maxParallelism = 3`, `maxSpecs = 5`). Then:
- `autoMode: false` -> list unimplemented specs, ask the user how many/which to implement now (question tool).
- `autoMode: true` -> implement ALL specs.

Then run the **IMPLEMENT LOOP (step 5)** + **FINAL VERIFY (step 6)** + **WRAP UP (step 7)** from the `/yasdd` playbook with the `autoMode` rules from step 5. When launching the implementer and verifier subagents, pass the spec path(s) + config values (`autoMode`, `maxParallelism`, `maxSpecs`) and tell them to use those values instead of re-reading `config.yml`. The verifier runs ONCE for the whole feature after all chosen specs are implemented (step 6), not per spec.
