---
name: yasdd-status
description: "Show project + feature component status."
disable-model-invocation: true
---
# yasdd-status

Read `.yasdd/config.yml` and print `autoMode` and `maxParallelism`; if missing, create it with `autoMode: false`, `maxParallelism: 3` (you are one of the few skills allowed to create it) and print the values. Read and print `.yasdd/PROJECT-STATE.md` (if missing, note that yasdd is not initialized and suggest loading the `yasdd-init` skill).

If `$1` (feature slug) is given, also print that feature's `STATE.md` (component impl/test/verify status).
