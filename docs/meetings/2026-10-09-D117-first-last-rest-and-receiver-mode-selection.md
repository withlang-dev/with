# D117 — `first()`, `last()`, `rest()`; one method name may have an observing and an owned form, selected by the receiver's syntax

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **The compiler and
stdlib are NON-COMPLIANT** until implemented.

**Context.** Eric proposed expression forms of `[first, ..rest]` (D115) for
taking one piece inline (`args.rest()` passed to a function,
`lines.first() ?? ""`). The brief raised two corrections: an `Option` from a
positional collection reads as a D71 violation unless the spec says why, and
the first draft made `tail()`'s result type depend on whether a later line
used the receiver, which D5 and D110 rule out.

References (verified in `.reference/`): Rust `first(&self) -> Option<&T>`,
`split_first() -> Option<(&T, &[T])>` (`slice/mod.rs`); Swift
`var first: Element?` and `dropFirst()` returning an O(1) `SubSequence`
(`Collection.swift`); Scala's `head` throws (hence `headOption`); Haskell's
`head` is partial. The Swift-migrator spec already maps `arr.first` to
`arr.first()` and `arr.last` to `arr.last()`, returning `Option`.

**Ruling (Eric, verbatim).**

"Both corrections are right, and the second one is a real catch: I made a
result type depend on whether a later line uses xs, which is exactly what D5
and D110 rule out."

"1. Add the sentence. Something like: first() returns an Option because "is
there a first element?" has a normal answer of no; indexing panics because
an out-of-range index is a bug. That's the distinction D71 is drawing, and
it's why Rust keeps first() beside [0]. Without it, the next agent to read
traits.md will flag first() as a D71 violation."

"2. Receiver-mode selection, keyed on syntax. Agreed, for the reason the
brief gives, and a stronger one: it isn't a one-off mechanism. It's the same
rule the [first, ..rest] pattern uses (a temporary or an explicit move is
owned, anything else is a place), applied to method calls. And it has a
second customer already waiting. #724 left for x in move xs: deferred as
possible sugar over into_iter(). Receiver-mode selection is the general form
of that: (move xs).iter() could mean consuming iteration under the same
name. I wouldn't fold that into this ruling, but it's evidence the mechanism
will pay for itself more than once."

"One rule to state with it: the owned and observing forms of one name must
be the same operation, differing only in ownership of the result. Nothing
can check that mechanically, so it belongs in the spec and in review. Two
methods sharing a name with different meanings is precisely the ambiguity
the mechanism must not enable."

"Names: first(), last() and rest(). first/last already exist in the
Swift-migrator spec, match Rust and Swift, and avoid a rename there. For the
tail, I'd name it rest() rather than tail(), so the methods mirror the
pattern exactly: xs.first() and xs.rest() are the expression forms of
[first, ..rest]. Someone who knows one knows the other, and Clojure users
will recognize the pair. head/tail would be a third vocabulary beside the
pattern's and the migrator's."

Earlier in the same exchange (verbatim): "head() returns an Option. … tail()
never fails. The tail of an empty list is an empty list. It's O(1) the same
way the pattern's rest is … Same modes as the pattern. head() on a place
observes. On an owned value it gives you the element. One rule, no new
ownership story."

**Spec projection (drafted from the agreed design).** §9.5 states
receiver-mode selection and the same-operation rule; `traits.md` §D27/D71
gains the `first()` sentence; §13.3 lists `first()`, `last()`, `rest()` with
their place and owned results.

**Derived, not ruled.**
- Selection applies only where both forms are declared; a name declared
  once is called as declared (today's behavior).
- `rest()` of an owned fixed array is `[T; N-1]`, as the pattern's is.
- `for x in move xs` (#724) is not part of this ruling.

**What would reopen it.** A pair of forms that cannot be the same operation
but wants one name.
