# D227 — A compile-time call across a package boundary reaches only a `comptime fn`

**Laws:** D172 (declare the guarantees that must remain stable; infer what
can safely improve the programmer's experience), D104 (a compile-time call
that reaches a forbidden operation reports the chain), D39 (an importer
reads the interface).

**Date:** 2026-11-21. **Status:** ruled by Eric; the words are blessed and in
spec v7.78.

**Context.** A plain function called at compile time is broken by any edit
that adds I/O to a body it reaches. Inside one package that is the author's
own edit. Across packages it is someone else's: an importer's build breaks
from inside a dependency. A bundle also has to know which bodies to carry
for an importer's evaluator. A count over the standard library, the
corpora, the examples, the UAT fixtures and a published program found that
the only compile-time calls across a package there are the two target
queries; the cost of a rule is confined to the tests.

**Ruling.**

- **The rule.** A compile-time call that crosses a package boundary reaches
  only a `comptime fn`, transitively. Within a package no marker is needed.
  The marker is a promise to importers; adding one later is compatible,
  removing one is a breaking change. A function whose body is likely to
  gain a side effect is not marked.
- **The target queries.** The runtime's target queries are `comptime fn`s
  whose compile-time answer the compiler supplies. The compiler keeps one
  list of such functions; the declaration states `comptime fn`.
- **Reflection** on a type is outside the rule: the compiler answers it, and
  no function of a package is called.
- **The build and compiler APIs** need no marker: they run under
  driver-minted capabilities (§17.1b) and the capability registry states
  them. Marking them would make the marker mean two things.
- **Bundles (D39 amended).** A `comptime fn` crosses a bundle boundary with
  its body and the body of every function of its package it reaches. One
  whose answer the compiler supplies crosses as a declaration without a
  body.
- **To be written before standard-library bundling:** how the bodies of the
  registry's functions reach the evaluator then. The bundle design
  (package-bundles.md) proposes that they cross with their bodies.

**Marked when this landed.** The runtime's two target queries;
`std.string`: `str.as_bytes`, `str.find`, `str.trim`, `str.bytes`,
`ByteIter.next`, `string_to_int`, `parse`; `std.numeric`: its 32 limit
functions; `std.sysinfo`: `os`, `arch`.

**What would reopen it.** A real program, outside the tests, that needs a
compile-time call into a library function its author cannot mark.
