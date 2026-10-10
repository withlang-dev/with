# D126 — A slice demand supplies the element type to a literal in argument position; the narrow reopen of untyped locals is its own decision, after D114

**Date:** 2026-10-09. **Status:** ruled (Eric Hartford). **Amends** §4.3c
(D113's slice sentence). **The compiler is NON-COMPLIANT** until
implemented.

**Context.** Under D114, `examples/c-interop` stopped compiling in two
places. `let readings = [4, -2, 7, 1]` passed to `range_of(values: []i32)`
was a `List[isize]`: §4.3c said the element type comes "from the elements,
or from the demand: a parameter…" and also that "a slice demand views the
literal… and demands nothing" (D113), which agreed only while literals
defaulted to `i32`. And `var sum = 0` accumulating `Value.int()` (C's `int`)
was `isize` at `ctx.result_int(sum + …)`, by the D114 follow-up ruling that
locals are not typed by their uses. A review noted that the two are one
question (`readings` is a local, so typing it from `range_of` is use-typing),
and proposed a narrow reopen in the spirit of D124.

**Ruling (Eric, verbatim, as pasted).**

"1. Bless the §4.3c wording as written. It holds whichever way you rule 2.

2. Reopen, narrowly, but not inside D114. Your reason for rejecting the
prototype was that the compiler's i32 targets should each be judged by hand,
not hidden by inference. That was about the migration, and the migration's
audit is now done. What's left is a language question for users, and on
that your usual test applies: two annotations in a showcase program, for
types the code already states at the use, is ceremony.

Two changes to the drafted wording:

Drop "first use." The rule already makes conflicting demands an error. So
the local's type is the one all its demanding uses agree on, and textual
order matters only for where the error points. Without "first," nobody has
to define what "first" means in a loop body or across branches.
Add a guarantee: the rule never changes the type of a local in a program
that compiles today, it only accepts programs that are refused today. I
believe that's true. A program that compiles today has only uses that accept
isize, so the agreed type is isize. This is cheap to verify: rebuild the
compiler and std with the rule on and diff every local's type. Any change is
a bug in the implementation.

Cost. The prototype's 82 s to 168 s came from D93's whole-module recheck.
This rule's locals are function-local, so resolving them should only need
the function body, which supports the agent's guess that the per-function
machinery suffices. Make the measurement a gate. If Sema time moves by more
than a few percent, I'd want to see why before landing.

Sequencing. Land D114 now with the two annotations in the example, as the
examples rule requires. Then rule the locals change as its own decision,
with the type-diff test and the timing. When it lands, it removes the
annotations it made necessary. D114 is already 14+ commits with real bug
fixes in it, and stacking an inference change on top would hold all of that
hostage to a perf measurement."

**Blessed words (§4.3c).** "A slice demand supplies the element type to a
literal in argument position and views it; it demands no collection."

**What follows.** D114 lands with `var sum: i32 = 0` and
`let readings: List[i32] = [4, -2, 7, 1]` in `examples/c-interop`, a
spec-change update made under the examples rule (2026-09-22) and said so in
its PR. The untyped-locals rule is drafted with the two changes above,
implemented on its own branch with two gates — the type of every local in
the compiler and std unchanged (diffed), Sema time within a few percent —
and ruled as its own decision; it removes the two annotations.

**What would reopen it.** The type-diff or timing gate failing in a way the
rule, not the implementation, causes.
