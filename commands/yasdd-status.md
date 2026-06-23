---
description: Show project + feature component status.
---
# /yasdd-status

Read `.yasdd/config.yml` if it exists; print `autoMode` and `maxParallelism` (if missing, note that yasdd is not initialized and suggest `/yasdd-init`). Read and print `.yasdd/PROJECT-STATE.md`.

If `$1` (feature slug) is given, also print that feature's `STATE.md` (component impl/test/verify status).
