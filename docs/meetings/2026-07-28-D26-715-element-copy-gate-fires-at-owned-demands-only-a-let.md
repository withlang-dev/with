# D26 — #715 element-copy gate fires at owned demands only; a let binding is not an owned demand

**Date:** 2026-07-28
**Status:** Done as an interim projection, then superseded in implementation by
D27's uniform element-view campaign (#740).

**Decision.** Sema rejects a non-Copy, Drop-bearing element reached via
`vec.get(i)` / `vec[i]` when it must satisfy an owned demand: a by-value call
argument, an assignment into an owned place, or a struct-literal field. A plain
`let` binding of such an expression is NOT gated.

**Why let is excluded.** Two proofs, one from the ruling and one from shipped
behavior. The D22 ruling: a view "materializes an independent `T` only when an
owned-value demand has already been established" — binding does not establish
one. And the issue-64 behavior pins (`issue64_receiver_shape_matrix` et al.)
assert `let item = inners.get(0); item.tags.push(99)` mutates the vec's element
in place — the binding is a place-chain alias today, and gating it would outlaw
a shipped, pinned surface. The first gate draft treated let as an owned demand
and broke exactly those pins; the narrowing is conformance, not retreat.

**Known residuals, on purpose.**
- A let-bound element that is *later* consumed escapes the gate (the gate keys
  on the get/index expression, not on bindings). The cure is D22's uniform
  view semantics for element access (plan line 334), under which the binding
  IS a `&T` and any later owned demand is checked structurally. Do not try to
  patch this by data-flow-tracking bindings in the interim gate.
- Whether a let binding is an owned demand for *field* projections through an
  explicit borrow (#730's gate currently says yes at let sites) is the same
  question and should get one uniform answer when Vec-element view semantics
  land. Surfaced to Eric with the #715 close-out.
- `Vec[i32][1, 2]` spells a collection literal (type-level index base); the
  gate must consult `index_expr_is_type_level`, as `check_index` does, or it
  misreads the literal as an element read.

**Reopen if:** Eric rules that binding a view to a name is itself an owned
demand, or D22's element-access-as-view implementation lands (which subsumes
this gate and should replace it).

---
