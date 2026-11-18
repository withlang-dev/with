# D211 — A call through a function-pointer field the package fills

**Laws:** 1 (the library's own source determines the callee), D198 (proofs
about C are enumerable).

**Date:** 2026-11-18. **Status:** ruled by Eric; extends D198's one-writer
proof.

**Context.** #3174, #3206: a call through a field
(`_glfw.platform.setWindowTitle(window, title)`) stopped the retention proof,
the largest raw cluster. D198 already decided a field the package writes in
exactly one place with a named function. Measured over 22 libraries'
source evidence: 1138 functions wait on "the record is passed to a call
through a function pointer", 84 on "written in several places", 371 on a
real outside function.

**Ruling.** Under D198's conditions (every unit read, no cast of the record,
no unmapped initializer, no field address taken, built from the source that
was read):

- **Several writers.** A field written in several places, each with a named
  function of the package, is the join over them: a parameter is retained if
  any retains it; a return is owned only if all return owned.
- **A record passed to a call through such a field** has not left what the
  drafter reads, once that field's callee set is closed and every member is
  read. The verdicts are a fixed point.
- A whole-record assignment or a `memcpy` counts as a write to every
  function-pointer field of the record.
- Proofs are per target: tables such as GLFW's are filled per platform.
- `field F of R holds f, g` states the set where the proof fails: a cited
  claim, shown as `registry:` in the contracts artifact.
- The outside-function cases stay undecided; neither extension sees into
  them.

**Reopen if** a library fills a table from data the units do not show (a
plugin loaded at run time): the proof fails there by its own conditions, and
`holds` would be a false claim.
