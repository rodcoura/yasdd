---
description: Resume implementation of a feature's specs from its STATE.md.
---
# /yasdd-implement

`$1` = feature slug (`autoMode: false`: optional, list features from `.yasdd/PROJECT-STATE.md` and ask if omitted; `autoMode: true`: use `$1` or the first feature with unimplemented specs).

Read `.yasdd/config.yml` once (`autoMode`, `maxParallelism`, and `maxSpecs`; all have defaults: `autoMode = false`, `maxParallelism = 3`, `maxSpecs = 5`). Then:
- `autoMode: false` -> list unimplemented specs, ask the user how many/which to implement now (question tool).
- `autoMode: true` -> implement ALL specs.

Then run the **IMPLEMENT LOOP (step 5)** + **TEST (step 6)** + **FIX-LOOP (step 6b)** + **FINAL VERIFY (step 7)** + **WRAP UP (step 8)** from the `/yasdd` playbook with the `autoMode` rules from step 5. When launching the implementer/tester/verifier subagents, pass the spec path(s) + config values (`autoMode`, `maxParallelism`, `maxSpecs`, plus `gate.testCmd`, `gate.lintCmd`, `gate.typecheckCmd`) and tell them to use those values instead of re-reading `config.yml`. The tester runs ONCE for the whole feature after all chosen specs are implemented (step 6); the verifier runs ONCE for the whole feature after the tester (step 7).
