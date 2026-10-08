# D109 — `offsetof[T](field)` is a built-in beside `sizeof`; a migrated `offsetof(T, f)` is spelled, never folded (delegated)

**Laws:** 1, 7 (docs/mission.md).

**Date:** 2026-10-07. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2131.

**Decision.** `offsetof[T](field)` is a built-in generic function with the
shape of `sizeof[T]()`: the type argument is a struct (a generic instance
included), the one argument is the bare name of one of its fields, the
result is the field's byte offset in T's layout for the compilation
target, `i64` like `sizeof`. The field is a name in T's declaration and
never an expression: Sema resolves it to a field index and records it,
MIR lowers no operand for it, codegen reads the layout model. An unknown
field or a non-struct type is a compile error.

The C migrator spells `offsetof(T, f)` and `__builtin_offsetof(T, f)` as
`(offsetof[T](f) as usize)` (C's offsetof is a size_t) and no longer
emits clang's folded value, which is the host's layout, anywhere: not in
a body, an initializer, an object macro's `let`, nor for a use of such a
macro by name. The record is clang's (a typedef or a macro-suffixed name
such as pcre2's `pcre2_match_data` resolves to its declaration); a member
chain `offsetof(T, a.b)` is the sum `offsetof[T](a) + offsetof[A](b)`. An
index component (`offsetof(T, a[2])`) stays untranslated and loud.

**Why.** The migrated pcre2 carried `offsetof(heapframe, ovector)` as the
literal 136 and `offsetof(heapframe, eptr)` as 80, clang's answer on the
64-bit host; on wasm32 pointers are 4 bytes, every frame field was
addressed askew, and every match reported "no match" (#2131 item 4). A
number in the corpus is a fact decided once for one target; the layout is
the compiler's to decide per target (law 7: the compiler already knows
it), so the corpus must name the field and let each target's layout place
it. `sizeof` is already spelled symbolically in the corpora; `offsetof`
was the one layout fact still folded.

**What the others do.** C has `offsetof(type, member)` as a macro over
`__builtin_offsetof`. Zig: `@offsetOf(T, "field")`, the name as a string.
Rust: `core::mem::offset_of!(T, field)`, the bare field name (stable since
1.77); nested paths later. Go has `unsafe.Offsetof(x.f)`, a selector on a
value. The bare name is the spelling the C family and Rust share; a
string would make the compiler parse a literal it has to check anyway
(law 1: no ceremony for what the compiler knows).

**What the spec said.** §16.12 named `sizeof` and `alignof` only; §17.2
lists `T.fields()` with offsets for comptime reflection, which the
evaluator serves, not a runtime expression. No rule covered a runtime
field offset; the migrator's folding was an implementation choice, not a
ruling.

**Mission fit.** Law 7 (the compiler infers what is forced): a layout fact
is forced by the type and the target. Law 1: the programmer writes the
field's name and nothing else.

**Prediction.** 85% that Eric keeps it: it mirrors `sizeof`, it is what C
programmers expect, and it is the smallest change that makes the corpora
target-independent. The alternative is `T.fields()[i].offset` at comptime
only; that would leave the migrator without a runtime spelling for an
expression C evaluates at any site.

**Reopen if** `sizeof` moves to `usize` (D108 makes `isize` the length
width; `sizeof` was not re-ruled) — then `offsetof` moves with it — or if
nested designators are wanted (`offsetof[T](a.b)`), which is a widening,
not a change.
