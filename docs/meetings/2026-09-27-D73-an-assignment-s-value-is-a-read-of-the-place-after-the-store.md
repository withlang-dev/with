# D73 — An assignment's value is a read of the place after the store (C's rule under With's view semantics)

**Laws:** 5 (docs/mission.md).

**Date:** 2026-09-27. **Status:** BDFL ruling (Eric: "yeah I can see that.
Make it so. problem 2, C's rule under With's view semantics").

#1479: `a = b = e` and `let t = (s = e)` duplicated the stored value (a
double free; `a` left empty). §9.1 said an assignment is "an expression
whose type is the type of `place`" and defined its value only in statement
and tail position (D60). Go, Swift and Zig make assignment a statement; C
keeps it an expression whose value is "the value of the left operand after
the assignment" (C11 §6.5.16p3). Statement-form was weighed and would have
cost the C idioms (`while ((c = f()) != EOF)`) and a regeneration of the
migrated corpora, whose 16,000+ parenthesized assignment statements would
become parse errors. Ruled: C's rule, read through D22/D27 — a read of a
place yields a view, so an assignment expression yields a view of `place`
after the store; a `Copy` demand copies, an owned demand on a non-`Copy`
view is refused with the clone/move fix-it. Nothing is duplicated, so the
double free is impossible rather than defined away. D60's tail rule is this
rule at the tail and stands unchanged. "The value just stored" (a hidden
duplication) stays rejected.

---
