# D98 — Delegated decisions: an agent implements its prediction and Eric vetoes afterwards

**Date:** 2026-10-05. **Status:** ruled (Eric).

**Ruling.** A design question goes ahead without waiting for Eric when it is
all three of:
1. not about C interop, ownership or safety;
2. easy to reverse later; and
3. one where the agent's committed prediction of Eric's ruling is 75% or
   higher.

The agent implements its prediction, spec words included, and records the
decision in this log with the full brief: references, spec text, mission
fit, the prediction and its confidence. The entry is marked **delegated**.
Eric vetoes afterwards if he disagrees; a veto is a revert and a new entry.

**Still Eric's, briefed and waited on:** C interop, ownership, safety,
anything hard to reverse, and any change to a UAT fixture, an example or a
published program.

**Why.** Eric was the bottleneck on rulings that did not shape With: D97's
`TotalF64` semantics and `None`-first order would both have gone through,
while its facade error type (C interop) was the one that needed him. His
time goes to the questions that shape the language.
