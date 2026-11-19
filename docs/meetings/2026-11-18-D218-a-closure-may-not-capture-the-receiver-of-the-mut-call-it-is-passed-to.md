# D218 — A closure may not capture the receiver of the `mut` call it is passed to

**Laws:** safety (a `mut` receiver is exclusive for the call, D172), 4 (the
explicit form says what happens).

**Date:** 2026-11-18. **Status:** ruled by Eric. Refused immediately: this
is the written rule, so it gets no warning period.

**Context.** #615: §3.2 says a `mut` receiver is exclusive for the duration
of the call and that no other argument may retain access to its place. The
compiler accepted a closure argument that captures and mutates that same
place (`x.scope(() => { x.n += 10; x.n })`), and the writes interleaved.
The risk is a view held across the callback: the callee holds a view into
`self.items`, the closure pushes to `x.items`, and the view dangles. View
liveness is checked inside one body; the closure's body is checked apart.

**Ruling.** The capture is refused. A bracket passes the receiver to its
body: `x.scope((s) => { s.n += 10; s.n })`.

- The failing program (callee holds a view into `self.items`, closure pushes
  to `x.items`) is built anyway and becomes the regression test.
- The fix-it's form needs a closure type whose parameter is `mut`. If
  `fn(mut T) -> R` cannot be written yet, it lands in the same change:
  a fix-it never suggests code that does not compile.

**Alternatives.** Blessing a non-escaping capture: needs "cannot escape"
for closure parameters and a callee-side rule that no view of the receiver
is live across a call of the closure, to keep one spelling. A dedicated
bracket construct: not needed once the receiver is passed.

**Reopen if** the explicit form proves too heavy for the scope-bracket
idiom the language is named for.
