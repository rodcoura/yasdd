---
name: yasdd-test-design
description: Writes TESTING.md (test-architecture handoff) for a feature right after DESIGN. Runs in the MAIN session reusing DESIGN context. Prose-only I/O.
---
# yasdd-test-design

Runs in the MAIN session. Reuse the DESIGN context already loaded in this session; do NOT re-launch yasdd-spy subagents. Targeted reads of test files referenced in DESIGN.md only — for accuracy, not re-exploration. Read `.yasdd/features/<slug>/DESIGN.md`.

`TESTING.md` is the **test-architecture handoff** — same role DESIGN.md plays for implementation: prevents the tester from re-exploring to find test framework, file locations, fixtures, e2e strategy.

Write `.yasdd/features/<slug>/TESTING.md` using this dense structure (no prose padding):

```md
# Testing: <feature>
Framework: <test runner + version>
Runner cmd: <e.g., npm test, pytest, go test — NOTE: if .yasdd/config.yml has a non-empty gate.testCmd, the tester uses that instead>
Unit test location: <convention per module>
Fixture strategy: <shared fixtures, factories, mocks>
E2E scope: <entry points + scenarios covered>
Acceptance mapping: <how each spec's Given/When/Then maps to a test file/case>
```

## Rules
- Reference the project's actual test framework + conventions (read package.json/Makefile/AGENTS.md and existing test files for accuracy).
- Map every spec's Acceptance case (Given/When/Then) to a concrete test file/case location so the tester writes tests without exploring the codebase.
- Keep it dense and structural; the tester needs framework + locations + fixture strategy + acceptance mapping, not implementation detail.
- Do NOT write tests here — this is architecture handoff only. The tester (`yasdd-tester`) writes the actual tests after all specs land.

## Pragmatic principles
- No overthinking; do the simplest thing that satisfies the need.
- No inferring; if something is undecided, ask or flag it — don't assume.
- Ensure every decision makes sense in context before writing it down.
