# D35 — Compound self-assignment `.=` and inclusive ranges `..=`

**Laws:** 1 (docs/mission.md).

**Date:** 2026-09-02
**Status:** Ruled by Eric in the D34 follow-on conversation. Verbatim:
`.=` — "line = line.replace(...) becomes line.=replace(...)" (wanted);
`..=` — "i want a ..= too. 1..=100 should include 100 where 1..100
should not include 100." Raku precedent for `.=` (the only shipped
implementation); Rust/Swift precedent for inclusive ranges. Design
pins recorded on #924/#923: `.=` is statement-position, receiver
evaluated once, desugars to `x = x.f(args)`; `..=` must NOT lower to
end+1 (type-max overflow — loop form lowers to a <= comparison,
reified ranges carry an inclusive flag). Spec wording pending Eric.
Synergies: `.=` removes a D22 view-liveness contortion class (atomic
self-replacement) and marks D34-C in-place-growth sites statically.

---
