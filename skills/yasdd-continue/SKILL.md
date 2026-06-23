---
name: yasdd-continue
description: "Resume implementation of every in-progress feature from where it stopped (pending components)."
disable-model-invocation: true
---
# yasdd-continue

Read `.yasdd/config.yml` once (create with `autoMode: false`, `maxParallelism: 3` if missing). Read `.yasdd/PROJECT-STATE.md` and, for each feature row, read its `STATE.md`. Collect features that have ≥1 unimplemented component (`impl: pending`), in PROJECT-STATE order. Ignore features with no architecture authored yet (report them and suggest `/yasdd` to finish authoring).

- None pending → tell the user "nothing to continue" and stop.
- `autoMode: false` → list each pending feature with its pending components; ask the user (question tool) which features/components to continue now (recommend: all pending, in order).
- `autoMode: true` → continue ALL pending features, in order.

For each chosen feature, run the **IMPLEMENT LOOP (step 4)** + **TEST (step 5)** + **FIX-LOOP (step 5b)** + **FINAL VERIFY (step 6)** + **WRAP UP (step 7)** from the `/yasdd` playbook with the `autoMode` rules, in `STATE.md` component order. Pass the ARCHITECTURE.md path + component ID `[M#]` + config values (`autoMode`, `maxParallelism`) to each implementer/tester/verifier subagent and tell them to use those values instead of re-reading `config.yml`. The tester runs ONCE for the whole feature after all chosen components are implemented (step 5); the verifier runs ONCE for the whole feature after the tester (step 6). Report each feature's outcome after it finishes. Honor the implementer FINISHED/ISSUES and tester FINISHED/ISSUES return protocols.
