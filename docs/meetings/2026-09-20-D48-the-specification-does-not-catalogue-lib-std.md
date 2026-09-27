# D48 — The specification does not catalogue `lib/std`

**Date:** 2026-09-20. **Status:** ruled (Eric: "I do not want the language
spec to care what we do in lib/std"). §18.6's Module Map table and the
`std.internal` paragraph removed; the `spec-inventory-check` stdlib arm
retired.

**Context.** Adding `std.zip` failed `spec-inventory-check`, which required
every top-level module under `lib/std` to have a row in the spec's Module Map.
That put Eric's exact-wording sign-off on every library addition.

**What the others do.** Go's spec names two packages, `main` and `unsafe`,
both compiler-known. Zig's langref uses `std` in examples and catalogues
none of it. Swift keeps the standard library in its own documents. Rust's
Reference disclaims the standard library (from memory; its tree is not
checked out in `.reference/`).

**Reasoning.** A specification says what programs mean; a module list says
what ships. The table was a second source of truth, so it drifted and needed
a gate. What stays normative is the library surface the language itself
depends on, each in its own section: the prelude, `Option`/`Result` and
`?`/`??`, the traits behind syntax (`Iter`, `Try`, `Drop`, `IndexGet`,
`IndexPlace`, `Contains`), what literals and comprehensions build, the regex
literal engine, and the collection ownership doctrine (D22, D27, D44). The
test: would a program's meaning change if this changed?

**Reopen if** a library module becomes something syntax depends on; it then
gets its own normative section, not a table row.

---
