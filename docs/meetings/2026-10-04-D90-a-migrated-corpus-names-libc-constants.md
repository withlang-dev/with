# D90 — A migrated corpus names its libc constants; a constant and the function that consumes it come from one table

**Laws:** 3, 8 (docs/mission.md).

**Date:** 2026-10-04. **Status:** BDFL ruling (Eric: "Rule A", with the
five points below, which are his). Issues #2060, #2070, #2071; PR #2064.
**Amended by [D94](2026-10-05-D94-a-corpus-is-migrated-against-every-target-and-merged.md)**:
a corpus is migrated against every target's headers and merged, not
against one fixed header set (point 5's input); point 4's handling of
platform conditionals and type sizes is how D94 merges.
**The migrator and `std.libc` are NON-COMPLIANT**: the bundled corpora
(zlib, pcre2, tommyds, c-algorithms) carry Darwin's macro values as integer
literals, so `gz_open` passes Darwin's `O_EXCL` to a seam that reads it as
the runtime's `O_APPEND`, on every target.

**The question.** A migrated corpus bakes in whatever the C headers said
when it was migrated. Either the migrator emits a name where C used a libc
macro (A), or each corpus is migrated and checked in once per target (B).

**Decision: A.** B does not fix the bug: the runtime's `open` uses its own
flag numbering, so even a Linux-migrated copy carrying glibc's `O_EXCL`
would be wrong. The constant must mean whatever the seam it is passed to
accepts. Only a name can say that; a number is always some header's
opinion. A also matches what `c_import` does with live headers, and B
triples every re-migration for nothing.

1. **What a `std.libc` constant's value is.** The value the With seam
   accepts, not the host OS value. For `open` flags that is the runtime's
   own numbering, which the per-target backend translates; for `errno`,
   whatever `std.libc`'s errno returns. The table may therefore be portable
   for flags and per-target only where a value passes straight through to
   the OS. One rule: **a constant and the function that consumes it come
   from the same table.** That makes #2070's mistranslated append
   impossible, not merely fixed.
2. **What counts as a libc macro.** Decided by where the macro is defined,
   not by a name list: any object-like macro whose definition comes from a
   system header in the fixed set is emitted as a `std.libc` name. If
   `std.libc` has no entry for it, migration fails and names the macro (no
   silent fallback: otherwise the next unknown constant quietly reverts to
   a Darwin number).
3. **Constant-expression positions.** `std.libc.O_EXCL` works anywhere C
   used the macro: `switch` arms, array sizes, bit-ors into other
   constants, static initializers. These are compile-time constants.
4. **Names do not fix layout or conditionals,** and migrating against one
   header set freezes both: Darwin's `#ifdef` branches (zlib's `gzguts.h`
   has Windows paths), Darwin's struct layouts (`struct stat`), Darwin's
   type sizes (`unsigned long` is 64 bits on macOS and 32 on Windows, and
   zlib uses it in its public API). The handling: target types are emitted
   as such (`c_ulong`, never `u64`); an `#ifdef` on a platform macro stays
   a conditional on the target (`comptime if target…`); a libc struct is a
   `std.libc` type. What is not yet handled this way is filed as a known
   gap **with a Windows test that catches it**; the `long` case is the
   sharpest, and silent on Windows today.
5. **Drift check.** Under A the migrated output is the same on every host
   (apart from point 4), so the gate keeps one fixed header set as its
   input (#2064), and asserts that the output holds no integer literal
   equal to a system-header macro's value at the site the macro was used:
   a cheap check that the migrator did not expand what it should have
   named.

**Alternatives.** B (a corpus per target): rejected above. Fixing the
values in place (a Darwin-to-runtime translation inside `std.libc.open`):
rejected — it keeps a number's meaning dependent on which headers the
corpus happened to see.

**Reopen if** a libc constant has no value the seam can define on some
target (the name then has no meaning there; that is a facade question,
not a numbering one).
