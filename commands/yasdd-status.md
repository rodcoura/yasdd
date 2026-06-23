---
description: Show project + feature component status.
---
# /yasdd-status

Read `.yasdd/config.yml` (create it with `autoMode: false`, `maxParallelism: 3` if missing). Print `autoMode` and `maxParallelism`. Read and print `.yasdd/PROJECT-STATE.md`.

If `$1` (feature slug) is given, also print that feature's `STATE.md` (component impl/test/verify status).
