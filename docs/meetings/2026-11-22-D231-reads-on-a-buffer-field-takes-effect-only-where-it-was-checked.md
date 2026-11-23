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

**Amended 2026-11-23 (Eric): the platform C library's facts file.** The
trusted functions are not a list in the compiler. One facts file for the
platform C library (`registry/c/libc/facts.with`) states `reads param N`
for the functions ISO C, POSIX and the Windows C runtime specify as reading
through a pointer, each line cited to its standard, and is pinned like any
other. Every C build links that library, so its facts are always consulted
for a callee outside the package. Four rules:

- The facts apply only when a system header declares the callee and the
  package defines no function of that name; a library with its own `write`
  is judged by that body.
- If the facts say `reads param 1` and the header in use does not declare
  that parameter a pointer to const, that is an error in the facts file,
  not a pass.
- A function that returns a pointer into what it was given (`memchr`,
  `strchr`, `strstr`, `bsearch`) or stores one through an out-parameter
  (`strtol`) is not listed: the caller may write through what comes back.
  The compiler's first list had trusted several of these.
- The check reports every use that stops it, not the first.

With it, zlib's `gz_comp` passing the pointer to POSIX `write` no longer
stops the check.

**A contract written by hand** states `reads` as it states `lend` or
`drop`: the programmer's claim, applied as written.

**Known beside it.** zlib's facts state `reads` on `next_in`, and it is not
applied until two things land, both ruled: `with get` building from source
by default (D212), since a prebuilt binary's source is not the build
linked; and the platform C library's facts (the amendment above), since
the gz layer's `gz_comp` passes the pointer to POSIX `write`.
