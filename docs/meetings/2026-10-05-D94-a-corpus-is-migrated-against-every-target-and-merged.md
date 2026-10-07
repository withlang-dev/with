# D94 — A corpus is migrated against every target's C, and the results are merged per declaration

**Laws:** 8 (docs/mission.md).

**Date:** 2026-10-05. **Status:** BDFL ruling (Eric: "Rule A", with the six
points below, which are his). Issues #2060, #2070, #2176. Amends D90 (the
one-C-model choice of #2064, and point 4's note on `long`).
**The migrator and the corpora are NON-COMPLIANT**: every corpus is migrated
against one C model, macOS on arm64 (`build/corpus.w`), and `c_import`
emits macOS's C type aliases on every target (#2176).

**The question.** A corpus (zlib, pcre2, tommyds, c-algorithms) is migrated
once and checked in for every target. Against which platform's C does the
migration parse? Today, macOS arm64 for all of them.

**What that model did (measured 2026-10-05).** zlib migrated on macOS and on
Linux differs in 9 of 19 modules (151 lines): `errno` 35 vs 11, `off_t`
spelled `c_longlong` vs `c_long`, `OS_CODE` 19 vs 3, unzip's default case
rule 2 vs 1, a different `zmemzero` branch. `std.zlib` writes OS byte 19
(macOS) into every gzip header on macOS, Linux and Windows. On Windows zlib
does not migrate at all (`gzlib.c`'s `_WIN32` path: `_lseeki64`, and a
construct the migrator cannot translate); the macOS model hid that. zlib
(`ULONG_MAX`, `_WIN64`) and pcre2 (`PCRE2_SIZE_MAX`) choose types in
preprocessor conditionals on the data model, which no single parse serves
for every target. c_import lays out C's `long` as 64 bits on Windows (#2176).

**Decision: A.** Each corpus is migrated against every target's headers;
where the targets' outputs agree, one declaration; where they differ, the
target conditional (D91). Every target gets what a C compiler on that
target builds from the source.

**Why A, beyond the measurements.** The corpora are the migrator's test
suite. `with migrate` is a user tool: someone on Windows migrates their own
C, and it takes its `_WIN32` branches. If the corpora never exercise those
branches, the migrator's Windows gaps stay hidden until a user finds them,
as the macOS model hid zlib's `_lseeki64`. Under A the four corpora test
every platform path the migrator must handle.

"With is the platform" (B) is right for `std.libc`: what `O_EXCL` means is
With's call (D90 point 1). It does not hold for these differences. The gzip
OS byte and unzip's case rule are not libc facts; they are the library's
own platform choices, written in its `#ifdef`s. B would override them; A
keeps them.

1. **Merge at top-level declarations.** Diffing inside function bodies is
   fragile. If any target's version of a declaration differs, emit
   `comptime match` with one whole declaration per arm.
2. **Group identical arms.** Arms whose declarations are the same are one
   arm (`.Linux | .Wasi =>`), and a declaration all targets agree on is one
   plain declaration. Otherwise each arm differs from its neighbor in one
   place, which is noise for a reviewer.
3. **Check every target.** An untaken arm is not type-checked (D91), so the
   corpus gate checks the corpus with `check --target` for each target; a
   broken Windows arm must not pass on a Mac. This is the per-target check
   lane D91 called for.
4. **Header provenance is the prerequisite, settled before the
   implementation.** A needs every target's headers wherever a migration
   runs. The redistributable sources are mingw-w64 for Windows, glibc and
   musl for Linux, wasi-libc, and the Darwin headers (Zig ships them all).
   MSVC and UCRT headers cannot be redistributed.
5. **The ABI dimension.** TargetSpec knows both windows-gnu and
   windows-msvc. If their parses differ, that is where `Target.abi` is
   added, as an exhaustive enum, never a string check.
6. **Cache on inputs.** Each arm's migration is keyed on the migrator, the
   sources and the headers, so the cost of migrating once per target is
   paid only when one of those changes.

**D90 point 4, amended in its premise.** Corpora no longer export to C
(`--c-export` is off by default), so `long`'s width inside a corpus is not
an ABI question any more, only a behavior one. Per-target widths are still
right: they are what a C compiler on that target builds, so the migrated
code means the same thing there.

**Alternatives.** B, With as the platform: one parse against a header set
generated from `std.libc`, no OS macro, one data model; rejected above. One
checked-in corpus per target (Go's `zerrors_<os>_<arch>.go`): rejected in
D90, and with constants named the per-target differences are small, so the
merge gives the same result without N copies. Keeping macOS: the prejudice
this ruling removes.

**Reopen if** a target's redistributable headers disagree with the C
compiler that target's users run (MSVC's UCRT against mingw-w64's), in a
way a corpus observes.
