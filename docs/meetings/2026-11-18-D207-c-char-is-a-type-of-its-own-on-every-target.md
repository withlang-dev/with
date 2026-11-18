# D207 — `c_char` is a type of its own on every target

**Laws:** 4 (one meaning: a program is accepted or refused the same on every
target), 1 (the compiler knows the target's `char`; the programmer does not
spell it).

**Date:** 2026-11-18 (ruled 2026-11-17, words blessed 2026-11-18). **Status:**
ruled by Eric. Amends D155: only "alias" is withdrawn.

**Context.** D155 made `c_char` "the target's": an alias of `u8` on AArch64
Linux and wasm, of `i8` elsewhere. An alias makes type identity follow the
target. `puts(p)` with `p: *const u8` was an error on darwin and accepted on
linux-aarch64, and a facade resource over `*mut c_char` received every
`unsigned char *` parameter there and none elsewhere (#3375: one facade, an
error on one target and a safe method on the other; the linux-aarch64 nightly
was red on it).

**Ruling.** `c_char` is a builtin integer type distinct from `u8` and `i8`
everywhere: one byte, with the signedness of the target's `char`, never an
alias. Operations among `c_char` values behave as the target's `char`. A
conversion happens without `as` only when it keeps the value on every target:
that is why a `c_char` widens into a wider signed type and not into an
unsigned one, why a value conversion to or from `u8` or `i8` takes `as`, and
why arithmetic, ordering and equality between a `c_char` and a `u8` or an
`i8` are refused. The words are §16.1's.

**Why both cast rules were kept.** Each exists because the same program
behaved differently by target: the implicit conversion to `u8` carried a
range check that panics for a byte above 0x7f on a signed-`char` target and
not on an unsigned one, and a mixed comparison ordered the same two bytes
differently.

**Cost, measured before the words landed** (a scratch build that gave the
type its identity and reported every site the rules refuse, on darwin-aarch64
and linux-aarch64): no site in the compiler, the standard library, the six
promoted corpora or the tests, examples and UAT programs; 44 pointer
conversions in `rt/wasm.w`, the one runtime file only an unsigned-`char`
target compiles. No published program changes by a character. Windows was
measured for the runtime only.

**What stands.** D155's reasons (C's value of a `char`; `c"…".ptr` is
`*const c_char`). D156: the migrator already keeps `char` symbolic, so no
corpus is re-promoted for its text.

**Not decided here.** `long`, `unsigned long` and `wchar_t` have the same
defect (a pointer to one is a pointer to a different fixed-width type by
target), and an enum's underlying type should come from what clang reports
for the target. One brief, after this has landed and its cost is known.

**Reopens if** a target appears whose `char` is not one byte.
