# D231 — `reads` on a buffer field: C only reads through the pointer, and the claim takes effect only where it was checked

**Laws:** D51 (a safety fact is stated or proven, never drawn from a name
or an absence), D198 (a proof about C is enumerable).

**Date:** 2026-11-22. **Status:** ruled by Eric; implemented; the words are
in v7.85 (§16.2b.8, §31).

**Context.** #3173. zlib declares `z_const Bytef *next_in`, and `z_const`
is `const` only when the program defines `ZLIB_CONST`. §16.2b.8 gave a
pairing `[]u8` only where the field points at const bytes, so `inflate`
asked for a writable slice for its input: a program holding compressed
bytes it cannot write had to copy them.

**Ruling.** `buffer field P remaining field N reads` states that C only
reads through `P`; the slice is then `[]u8`.

- **It takes effect only where the check ran and passed.** A false `reads`
  lets C write into immutable data, so an unchecked one does not stand.
- **The check follows the pointer**: through a copy to a local, a cast,
  pointer arithmetic, and into every function of the package it is passed
  to. A callee inside the package is judged by its body; a declared const
  proves nothing in C.
- **A store through it in any unit contradicts the claim.**
- **Outside the package**, a function of the C standard library that takes
  it as a pointer to const does not write through it (zlib copies from
  `next_in` with `memcpy`). Any other outside callee leaves the claim
  undecided.
- **Undecided is not applied.** The pairing stands without `reads`, the
  slice is writable (which only asks more of the caller), and both the
  contract and the `with get` report name the use that stopped the check.
- **`reads` on a pointer the header already declares const is an error.**

**Alternative rejected.** Defining `ZLIB_CONST` when the header is imported,
so the header itself says const: a preprocessor setting would carry a
safety fact. Building the library with it is still worth doing, as a check
the C compiler runs on every build; that needs a build setting the facts
file can state, which is its own decision.

**A contract written by hand** states `reads` as it states `lend` or
`drop`: the programmer's claim, applied as written.

**Known beside it.** zlib's facts state `reads` on `next_in`, and it is not
applied yet, for two reasons the report names. `with get` links zlib as a
prebuilt binary, so its source is not the build linked. And read against
its pinned source, the check stops in the gz layer: `gz_comp` passes the
pointer to POSIX `write`, which takes a pointer to const and is not a
function of the C standard library. Whether POSIX's readers are trusted as
the C standard library's are is a question for Eric.
