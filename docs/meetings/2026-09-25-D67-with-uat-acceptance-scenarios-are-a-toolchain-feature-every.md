# D67 — `with uat`: acceptance scenarios are a toolchain feature every project has; `with init` scaffolds one

**Laws:** 10, 8 (docs/mission.md).

**Date:** 2026-09-25. **Status:** BDFL ruling (Eric: "blessed" on the §18.5
line, the §18.8 `with init` row and §18.5d, after "make sure it's written
in a way that users can use too … `with init` should set up their project
with an example UAT"). Plan: `docs/uat-plan.md`.

**Decision.** Acceptance scenarios are plain-text files a person writes
with a fixed set of verbs (`new directory`, `run:`, `write … from …`,
`stdin:`, `env`, `expect …`), one per scenario under `uat/`, run by
`with uat` with three verdicts — pass, skip with the reason (`requires:`
unmet), fail — and `expect (human):` lines that are recorded and reported,
never executed. Programs a scenario writes into the project are ordinary
source files under `uat/fixtures/`. `with init` writes `uat/hello.uat` and
`uat/README.md`. The compiler's own release UATs (`build/release_uat.w`,
nine hand-coded actions) migrate onto it and the build layer keeps no
scenario logic.

**Why.** A UAT is a promise a person can read — what a user does and sees
— and the existing harness had only the mechanism: scenarios existed as
call sequences inside the build system, coverage was not enumerable,
preconditions (no OpenGL on the macOS runner, #1375) read as failures, and
the human expectation ("colored balls moving on a field of black") had no
home. Eric's own phrasing of a hand-written UAT is a list of verbs and
nouns; that list is the notation. Gherkin's Given/When/Then is ceremony the
mission dislikes; a step-definition API is deferred (the verbs are the
runner's, like `with test`'s). Making it a toolchain feature rather than a
repo harness is the same call as `with test`: the language ships the way
its programs are checked.

---
