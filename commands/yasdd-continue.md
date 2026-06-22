---
description: Resume implementation of every in-progress feature from where it stopped (pending specs).
---
# /yasdd-continue

Read `.yasdd/config.yml` once (create with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5` if missing). Read `.yasdd/PROJECT-STATE.md` and, for each feature row, read its `STATE.md`. Collect features that have ≥1 unimplemented spec (`- [ ]`), in PROJECT-STATE order. Ignore features with no specs authored yet (report them and suggest `/yasdd` to finish authoring).

- None pending → tell the user "nothing to continue" and stop.
- `autoMode: false` → list each pending feature with its pending specs; ask the user (question tool) which features/specs to continue now (recommend: all pending, in order).
- `autoMode: true` → continue ALL pending features, in order.

For each chosen feature, run the **IMPLEMENT LOOP (step 5)** + **TEST (step 6)** + **FIX-LOOP (step 6b)** + **FINAL VERIFY (step 7)** + **WRAP UP (step 8)** from the `/yasdd` playbook with the `autoMode` rules, in `STATE.md` spec order. Pass the spec path(s) + config values (`autoMode`, `maxParallelism`, `maxSpecs`, plus `gate.testCmd`, `gate.lintCmd`, `gate.typecheckCmd`) to each implementer/tester/verifier subagent and tell them to use those values instead of re-reading `config.yml`. The tester runs ONCE for the whole feature after all chosen specs are implemented (step 6); the verifier runs ONCE for the whole feature after the tester (step 7). Report each feature's outcome after it finishes. Honor the implementer FINISHED/ISSUES and tester FINISHED/ISSUES return protocols.
