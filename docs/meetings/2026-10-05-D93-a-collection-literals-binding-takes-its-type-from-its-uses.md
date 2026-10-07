# D93 — A collection literal's binding takes its type from its uses

**Laws:** 2 (docs/mission.md).

**Date:** 2026-10-05. **Status:** BDFL ruling; the words are Eric's (his
review of the draft in #2148). Spec v7.23 §4.3c rule 1. **The
implementation is NON-COMPLIANT until it catches up** (#2144; the
annotation half, `let w: Vec = [1, 2, 3]`, is #2146).

**The question.** README's ownership example spelled `let xs: Vec[i32] =
[1, 2, 3]`. Eric: "cannot the T of xs be inferred?" and "even java infers
vector type from the value." §4.3c made a bare `[1, 2, 3]` a fixed array
unless an expected type said otherwise, so the binding needed the whole
annotation: `let xs = [1, 2, 3]` then `total(xs)` was "wrong argument
type", and `let xs: Vec = [1, 2, 3]` was "type mismatch in binding".

**Decision.** Two rules, in Eric's words (§4.3c rule 1):

1. An annotation may name the collection without its arguments, and the
   elements decide them.
2. A binding with no annotation takes its type from its uses, as an
   unsuffixed numeric literal does (§4.2.1, D88/D89). A demand is a
   parameter, an assignment to or from a typed place, a return, or a
   method that exactly one of the candidate collections has (`push`
   demands a `Vec`). The demand settles the element type too (`Vec[i64]`
   gives a `Vec[i64]`). A slice demand is met by the fixed array and
   settles nothing. Two demanded types are an error at the second. With
   no demand, a non-empty literal is a fixed array and an empty literal is
   an error asking for its element type. Demands come from the binding's
   own function only.

**What Eric changed in the draft, and why.** The draft counted only type
demands and left `xs.push(4)` an error on an array. Eric reversed that:
methods count. It is the Python-programmer test (`var xs = []`, then
`xs.push(1)`), and the closed candidate list keeps it safe, since a method
settles the kind only when exactly one candidate has it; stating less now
would mean reversing a ruling later instead of implementing a planned
phase. He also removed the slice from the collections a literal builds ("a
slice of *what* storage?"), made the element type part of the demand,
gave the empty literal its own sentence, added assignment *into* the
binding as a demand, and made the conflict "two different types" so
`Vec[i32]` against `Vec[i64]` is covered.

**Others.** Java `var xs = List.of(1, 2, 3)`; Rust `vec![1, 2, 3]` with
`Vec<_>`; Swift `[1, 2, 3]` is `[Int]`. None lets later uses choose
between an array and a growable vector; With has both under one literal,
and the uses already decide which is meant.

**Implementation order.** Method demands may land as a second step after
type demands; the text states the whole rule.

**Reopen if** a demand from outside the binding's function is wanted (a
returned literal's caller), or a second collection gains `push`.
