# D36 — Build graph producer edges are inferred from consumed outputs, never demanded

**Laws:** 1, 8 (docs/mission.md).

**Date:** 2026-09-01
**Status:** Implemented (29212f97, #700). Agent judgment call under the
no-ceremony rule; reopen only if an inferred edge is ever wrong.

**Decision.** When a build.w target's `entry` or `.input()` names a path
that another target produces (`.output()` or an extra output), the graph
adds the producer edge itself (`build_graph_complete_edges`, once in the
materializer before the graph is emitted). Inferred edges are data edges:
the consumer reads the file, so they feed the `dep_rebuilt` staleness rule
exactly as a written `.dep()` does. Ordering-only edges — where nothing
is consumed — remain the author's to declare, and remain the only kind
that must never feed `dep_rebuilt` (D13).

**Context.** #700 demonstrated the consequence of a missing edge: not a
slow rebuild but a wrong binary — a stage1 assembled from pre-swap and
post-swap objects, differing from any tree that ever existed. The edge
audit already found every such edge and printed a note.

**Alternatives.** (a) Keep the note. (b) Make it a hard error — tried
first in this batch; it failed the selfhost `build-w` fixture on the
first battery, and would fail anyone using `compile_asm_object` or
`compile_c_object` on a generated source, since those helpers cannot
declare deps. (c) Infer. Ninja and Zig's build graph both derive the
edge from the produced path; Go's module graph is implicit.

**Reasoning.** The compiler had computed the producer in order to
complain about it. Demanding that the author repeat a fact the compiler
already holds is the exact ceremony the mission forbids; the fixture
failure made the cost concrete on the first run. Inference also removes
the declaration-order dependence rather than policing it.

---
