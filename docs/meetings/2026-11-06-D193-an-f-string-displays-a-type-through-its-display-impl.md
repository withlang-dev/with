# D193 — `{x}` in an f-string displays a type through its `impl Display`

**Laws:** 1, 3 (docs/mission.md).

**Date:** 2026-11-06. **Status:** delegated (D98, 90%) on #3005, under the
#1 goal (bridge-the-impl-gap.md).

**Ruling.** In an f-string, `{x}` over a struct, enum or generic instance
with an `impl Display` formats `x` by that impl's `to_str`, called with a
borrow of the value: `f"p = {p}"` prints what `print(p)` prints. A width
or alignment pads that text (`{p:>8}`); `:?` stays the Debug form (D61).
A type with neither has no default display and `{x}` is refused, with the
help naming both remedies (§15.4.8). Numbers, bool and str keep the
built-in formatters: an `impl Display` for them is not consulted.

**Why.** §15.4 said "no trait dispatch", so `print(p)` (which is
`print[T: Display]`) and `f"{p}"` disagreed on the same value: the one
spelling every user writes first for a library type (`f"loss = {loss}"`
over a decimal, a date, a matrix) was an error whose fix was `{p.to_str()}`
or `{p:?}` — the compiler knew the impl and made the programmer spell it.
`:?` already dispatches to a user `Debug` impl through the same mechanism
(Sema binds the method; MIR calls it with a borrow), so `{}` dispatching to
`Display` adds no second machinery.

**What the others do.** Rust: `{}` is `Display`, `{:?}` is `Debug`, both
trait dispatch. Swift: string interpolation calls `description`
(`CustomStringConvertible`). Go: `%v` consults `String()` (`Stringer`).
Zig: `{}` calls a type's `format`. With had been the odd one out.

**Reopens it.** A `Display` impl on a primitive (today ignored); a
precision spec on a displayed type (`{p:.2}`, today float-only).
