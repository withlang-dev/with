# D116 — `++` concatenates sequences and observes its operands; `++=` extends in place; `+` stays off `Vec`

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **Supersedes** the
§15.4.9 rule that `++` is `str`-only. **The compiler is NON-COMPLIANT** until
implemented.

**Context.** Eric asked whether `Vec` should have `+` for push and `++` for
concatenation. The brief recommended `++` for concatenation, no `+` for
push, and consuming operands (`a ++ b` moves `a`, reusing its buffer). The
ownership half was wrong: it contradicted D110 (a parameter's mode is what
the callee does with it) and treated a representation choice as a meaning.

References (verified in `.reference/`): Mojo's `List + List` concatenates
and `+=` extends, copying `self` under a `Copyable` bound (`list.mojo`);
Swift's `+` concatenates and `+=` appends, both with a sequence on the right
(`RangeReplaceableCollection.swift`); Zig's `++` concatenates arrays at
comptime (`array_cat`); Rust has no operator on `Vec`; Go has `append`. No
reference makes `+` push one element.

**Ruling (Eric, verbatim).**

"Agree on both calls: ++ for concatenation, and not + for push. The agent's
reasons for rejecting + are right, and there's one more worth adding:
keeping + free on Vec reserves it for element-wise math, which Crux will
want on numeric vectors and tensors."

"But the ownership half of the brief is wrong, and it's the same
wrongthinking as this morning. "Plain operands consume, so a ++ b moves a"
means: `let all = defaults ++ extras` / `print(defaults) // error: use of
moved value`. No one coming from Python, Swift or Haskell expects
concatenation to destroy its inputs, and the fix the brief offers,
a.clone() ++ b, is exactly the ceremony you just ruled out for strings."

"Apply rule 1: what does ++ do with its operands? It reads them to build a
new sequence. It doesn't keep either one, so both are observed. The result
is a new value, and building it is O(n) because that's what concatenation
is, not a hidden copy. Python's a + b is O(n), and nobody calls that hidden.
Then the D111 pattern does the rest: at a's last use the compiler reuses its
buffer and appends b in place, so the common case xs = xs ++ more costs only
the append. Semantics observe, implementation moves when it can."

"a ++ b: concatenates any two sequences (str, Vec, slices, literals) into a
new value. Both operands are untouched. At an operand's last use the
compiler reuses its buffer. a ++= b: extends a in place. This is the
mutation form, and it subsumes push as an expression: v ++= [x]. Under D113
the one-element literal needn't touch the heap. push stays as the plain
method, for the obvious single-element case. The strings.md clause ("++ is
str-only") is replaced by "++ concatenates sequences," with str as one of
them."

**Blessed words (§15.4.9).** Eric blessed the projection below, which adds
the result types and the non-`Copy` element rule the ruling left open:

"`a ++ b` concatenates two sequences into a new value: two `str` give a
`str`; any two of a `Vec`, a slice, a fixed array or a list literal, with
the same element type, give a `Vec[T]` (a `[T; N+M]` where one is demanded).
Both operands are observed and left untouched; at an operand's last use the
compiler reuses its buffer, so `xs = xs ++ more` costs only the append.
Elements that are not `Copy` are moved, so such an operand must be at its
last use or spelled `move`; otherwise write `.clone()`.

`a ++= b` extends `a` in place, and `v ++= [x]` appends one element. `push`
remains the method for a single element."

**Why the non-`Copy` clause.** §2.3: the compiler never produces a second
live value from one unless the type is `Copy`, and clones only where the
program asks. An observed operand of `File`s cannot be left untouched while
its elements also land in the result, so for non-`Copy` elements last-use
reuse is what makes the program legal, not only an optimization. The
alternative, an implicit element clone under `T: Clone`, is the clone §2.3
forbids.

**Consequences (derived, not ruled).**
- `str` with a byte sequence is an error: a `str` is text, not `[]u8`.
- `+` on `Vec` stays unassigned, reserved for element-wise math.

**What would reopen it.** A common program where the non-`Copy` rule forces
`.clone()` that the user would not otherwise write.
