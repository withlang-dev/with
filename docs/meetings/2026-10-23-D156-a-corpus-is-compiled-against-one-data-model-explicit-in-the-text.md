# D156 — A corpus is compiled against one data model, and that model is explicit in the text: widths are fixed integers, only `c_char` stays symbolic (amends D155)

**Laws:** 6 (docs/mission.md); tested against 7 and 10.

**Date:** 2026-10-23. **Status:** ruled by Eric, amended by Eric the same
day. **Issues:** #2585, #2582, #2592. **Amends:** D155 (its "then `c_long`
falls out" clause).

**Decision (Eric, 2026-10-23).** Option 1 of the follow-up brief:

> The brief's evidence corrects my note: I said `c_long` would "fall out" of
> the alias mechanism, and the crc32 tables show it can't. The preprocessor
> already chose the LP64 branch; the alias line was only naming the choice.
> So the honest shape is: **a corpus is compiled against one data model,
> and that model is explicit in the text.** Widths are spelled as fixed
> integers; only `c_char` remains symbolic, because its sign is a
> representation that portable C tolerates rather than a branch the
> preprocessor took.

> The letter of the earlier ruling survives (no `c_*` integer alias in a
> corpus), the width is explicit, and the migrator no longer launders a
> preprocessor choice behind a portable-looking name.

Four things pinned with it, the second and third as amended:

1. **The `c_char` carve-out holds at the ABI boundary, not everywhere.**
   Inside a corpus, `char` as a byte of text (strlen, memcpy, buffers) is
   the target's `c_char`. A corpus can also branch on `char` as arithmetic
   (`if (c < 0)`), a different path on AArch64 than on macOS, exactly like
   `W == 8`. Where the migrator can see the sign mattered (comparison or
   arithmetic on a `char` value that is not masked), it emits the model's
   fixed `i8` for that use and leaves `c_char` for the pointer surface.
   Until it does, the rule is "C's `char` migrates as `c_char`", and a
   sign-dependent branch is a known migration hazard the corpus's aarch64
   tests must catch; nobody mistakes the carve-out for a proof.
2. **The model is recorded, not enforced.** Eric's first wording asked for a
   comptime assertion (`sizeof[c_long]() == 8`) at the top of the corpus;
   his correction withdrew it:

   > "Refuse loudly on hosts the model's widths don't fit" is only correct
   > where the width *reached a branch* or a seam. zlib on wasm32 with LP64
   > tables passes its tests because, once the widths are spelled `u64`,
   > the code is just u64 arithmetic that happens to be slower than the
   > W==4 branch would have been; nothing is wrong, and refusing it would
   > make D156 a regression on two hosts that just went green.

   So the corpus's header carries one line, `// data model: LP64
   (arm64-apple-macosx11.0)`, and a constant, `pub let C_DATA_MODEL`, that
   the seam diagnostic prints, with no size assertion.
3. **A seam is checked, never assumed.** Spelling the widths makes a corpus
   internally consistent and makes the seam the only place the model meets
   the host, where §16.3c belongs. A corpus value spelled `u64` passed to a
   host C parameter that is 32 bits on this host is a narrowing the seam
   has to spell, and the seam diagnostic names the model ("this corpus was
   migrated LP64; `strtoul` is 32-bit here"). The wasm32 and Windows
   failures are not fixed by this, they are named by it: a corpus whose
   correctness depends on the model (zlib's `W` choice) runs on every host
   its widths compile on, and is wrong only at a seam, which is the one
   line that is refused. That is the D112 scaling line, drawn honestly:
   one corpus per *model*, not per host, and a model is added only by
   ruling.
4. **`c_long`-returning APIs in std.libc follow the seam rule.** `strtoul`
   as `u64` everywhere is correct on LP64 hosts and a lie on Windows, where
   the C function writes 32 bits; #2594 is the fix for the seam the corpora
   use, documented as the LP64 seam, with the note that Windows std.libc
   needs its own view before D112 can claim that host for these corpora.

**Against the laws (Eric).** Law 1: the programmer states nothing; the only
spelled thing is `p as *const c_char` where two pointee types genuinely
differ. Law 3 was the defect: `c_char`'s sign had three owners (c_import,
the corpus's `defs.w`, 43 bare `*const i8` sites in std.libc) and the lexer
as a fourth; the ICE was MIR refusing what Sema accepted. Law 6 is what
D156 is an instance of: a corpus's width is a fact about what the
preprocessor compiled, part of the corpus's interface, in the text and not
reconstructed from a target at import time. Law 7: the withdrawn assertion
would have made green hosts red for no wrong result ("redefining the
success condition, pessimistically"); the narrowed version refuses at the
one line that can be wrong and nowhere else. Law 8: D112 held; no per-host
corpora. Law 10: D156 lands with its adversarial program, a corpus value
at a seam whose host width differs, failing with the model named.

**Context.** D155's re-promotion (no `type c_*` lines, the builtin
target-resolved aliases in their place) broke every corpus's wasm32 bundle:
zlib's `crc_big_table: List[c_ulong]` holds 64-bit literals because upstream
selects `W == 8` under the LP64 model, and `c_ulong` is u32 on wasm32 (1164
errors in zlib, 97 in stc, mlib's facade returning `c_ulong` from a `u64`
`strlen`). Every corpus is migrated with `--c-target arm64-apple-macosx11.0`:
its integer widths were the named model's all along, not the host's; what
the Windows leg had wrong was std.libc's 32-bit seam (#2594).

**Alternatives.** (2) A corpus declares its model's integer aliases
(`pub type c_long = i64` from `--c-target`), never `c_char`: readable names,
but a `type c_*` line in every corpus, which D155 removed. (3) Per-data-model
corpora (LP64, LLP64, ILP32 checked in): what D112's scaling rule forbids
without a ruling that adds a model.

**Reopens if** a second model is ruled in (an LLP64 or ILP32 migration of a
corpus): then "one corpus per model" has two, and the host selects.
