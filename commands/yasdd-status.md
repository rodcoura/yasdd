---
description: Show project + feature spec status.
---
# /yasdd-status

Read `.yasdd/config.yml` (create it with `autoMode: false`, `maxParallelism: 3`, and `maxSpecs: 5` if missing). Print `autoMode`, `maxParallelism`, and `maxSpecs`. Read and print `.yasdd/PROJECT-STATE.md`.

If `$1` (feature slug) is given, also print that feature's `STATE.md`.
