# D60 — A tail assignment under a declared non-`Unit` return yields a read of its place; the implicit default applies only to a `Unit` tail

**Laws:** 5 (docs/mission.md).

**Date:** 2026-09-23. **Status:** BDFL ruling (Eric: option (a), with the
§4.10 narrowing and a wording change to §9.1; "blessed"). §9.1 and §4.10
carry the blessed text.

**Decision.** In `fn inc -> i32: g += 1`, the body yields a read of `g`
after the store, under the ordinary copy and move rules. §4.10's implicit
`T.default()` applies only when the tail's own type is `Unit`; a tail of any
other type must match the declared return type or is a type error.

**These are a pair.** Option (a) alone is the "returns 6" convenience
without the guard. The narrowing is what turns the next regression of this
shape into an error instead of a silent zero: #1319 (merged 2026-09-22
without a ruling) made a body-tail assignment discarded, and §4.10 then
substituted `T.default()`, so `inc()` returned 0 instead of 6 and `set()`
0 instead of 9 with no diagnostic. That change was a defect.

**Why "a read of `place`", not "the value just stored".** The latter
implies a second copy exists after the store: free for `i32`, a hidden
clone or an unstated move for `str`. The existing move rules already decide
it: `fn inc -> i32: g += 1` returns 6 because `i32` is `Copy`;
`fn f -> str: g += 1` is a type error; `fn f -> str: name = compute()`
with a global `name` is a move-out-of-global error, not a silent clone.

**What the others do.** Rust (`check_expr_assign` returns `()`), Swift
(assignment is `()`) and Zig (assignment is a statement) reject the
function; Go has no assignment expressions. With's assignment already has
the type of its place (§9.1), so their answer does not transfer.

**Reopens if** a tail read of a place proves to surprise more than it
helps.

---
