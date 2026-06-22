---
description: Show project + feature spec status.
---
# /yasdd-status

Read `.yasdd/config.yml` (create it with `autoMode: false`, `maxParallelism: 3`, `maxSpecs: 5`, and an empty `gate: { testCmd: "", lintCmd: "", typecheckCmd: "" }` block if missing). Print `autoMode`, `maxParallelism`, `maxSpecs`, and `gate.*Cmd` values. Read and print `.yasdd/PROJECT-STATE.md`.

If `$1` (feature slug) is given, also print that feature's `STATE.md`.
