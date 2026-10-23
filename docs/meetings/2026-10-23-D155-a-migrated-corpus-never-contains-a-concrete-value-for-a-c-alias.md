# D155 — A migrated corpus never contains a concrete value for a `c_*` alias; `c_char` is the target's everywhere, `c"…"` is `*const c_char`, and a pointer to one integer type is not a pointer to another

**Laws:** 1, 2, 5 (docs/mission.md).

**Date:** 2026-10-23. **Status:** ruled by Eric. **Issues:** #2585, #2582
(the linux-aarch64 seed), #2176 (the aliases are the target's), #2592.

**Decision (Eric, 2026-10-23).** Option 1 of the brief
(`~/.local/with-staging/notes/brief-2585-c-char.md`), written about the
mechanism, not about `c_char`:

> The deeper problem is that the corpora bake a target at all, and
> `c_char` is only the first alias that bit. `c_long` is in the same
> `defs.w` and differs on Windows (32-bit), which D112's "one corpus serves
> every host" already depends on nobody noticing. Option 1 fixes the
> mechanism (corpora import std's target-resolved aliases instead of
> baking them), so write the ruling about the mechanism, not about
> `c_char`: a migrated corpus never contains a concrete value for a `c_*`
> alias. Then `c_long` falls out and the Windows leg stops being luck.

> `c"…"` should be `*const c_char`, period. Otherwise the literal is wrong
> on exactly the hosts the ruling is trying to fix.

> "Pointers to differing integer types are not compatible" is sharper than
> the brief claims. `*const u8` from a byte buffer passed to a `*const
> c_char` parameter on a signed-char target is a real and common shape, and
> under the one-line fix it becomes an error. That's correct for the
> mission (two meanings; spell it), but it needs an obvious spelling, `p as
> *const c_char`, and the error has to suggest it.

> Against option 2 [a fixed `c_char = i8`]: With promises C-level reach,
> and a `char` that's unsigned to C and signed to With breaks every API
> where the value matters (`isalpha` tables, UTF-8 bytes above 0x7f).
> Swift could afford fixing CChar because Swift strings never cross as
> `char *`; With's whole FFI story does.

Two things the ruling settles besides: a facade written against `c_char`
is portable without edits (it must be, or facades become per-target), and
the Sema fix gets a fixture pinned to each of the three targets so the
next alias to drift is caught by CI, not a seed leg.

**Order of work (the brief's, confirmed).** The Sema fix is the last step:
landing it first turns a latent disagreement into a red battery with
nothing to fix it against.

1. std.libc declares the target's `c_*` aliases (`c_char` by Target: u8 on
   AArch64 Linux and wasm, i8 elsewhere; `c_long` 32 bits on Windows and
   wasm32) and spells its C strings `*const c_char` / `*mut c_char`;
   std.string, std.zip, std.collections and the build layer follow.
2. `c"…"` is `*const c_char`; the runtime's C-string parameters meet it.
3. The migrator emits no `type c_*` into a corpus; a corpus's `defs.w`
   imports std.libc's. Every corpus is re-promoted under `ruling:D155`
   (D112), and each corpus's tests run on AArch64 Linux and Windows.
4. Sema: a pointer to one integer type is not a pointer to another, with
   the fix-it `p as *const c_char`; one fixture per target (darwin,
   linux-x86_64, linux-aarch64 at least) pins the alias widths.
5. The linux-aarch64 seed leg.

**Context.** On AArch64 Linux three parts of With disagreed about `char`:
c_import and a fresh migration say `c_char = u8` (#2176); the promoted
corpora bake `c_char = i8`, `c_long = i64` from the one C model they are
migrated against (arm64 macOS); std.libc spells C strings `*const i8` with
no alias. The aarch64 seed leg's posix_path_calls bound std.libc's `realpath
-> *mut i8` to a `*mut c_char` (u8) and MIR refused it as an ICE after Sema
let it through.

**What the others do.** Rust, Zig and Go make `c_char` the target's (u8 on
aarch64-linux); Swift fixes `CChar = Int8` everywhere.

**Alternatives.** (2) a fixed `c_char = i8`: reverses #2176 to match an
implementation, and breaks every API where the value matters. (3) both
worlds with Sema tolerating equal-width pointees at the C boundary: a second
owner of the pointee type to avoid a decision (D65).

**Reopens if** a target appears whose C `long` or `char` the comptime
`Target` cannot name; the alias then needs a new arm, not a baked value.
