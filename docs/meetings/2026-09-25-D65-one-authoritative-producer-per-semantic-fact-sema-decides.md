# D65 — One authoritative producer per semantic fact: Sema decides what, MIR decides where and when, codegen decides how; no stage re-derives another's answer

**Date:** 2026-09-25. **Status:** architecture decision (Eric, endorsing the
boundary proposal with the amendments below; "adopt it"). Executable half:
`with analyze audit:resolution` (#1647). Rule text also in CLAUDE.md /
AGENTS.md ("One owner per fact").

**Decision.** Every semantic fact has exactly one authoritative producer:

- **Sema:** resolved declaration, resolved type, place/value/view category,
  view origin, operation effect (read / borrow / mutate / consume / escape /
  invalidate / preserve), closure capture semantics (mode, access,
  environment storage, call kind), call target and specialization, and
  whether the source program is accepted.
- **MIR:** the CFG, local storage and temporaries, path-sensitive
  initialization and move state, the exact drop points and cleanup edges.
- **ABI / codegen:** physical layout, direct/indirect passing (`PassMode`,
  D6), calling convention, the concrete LLVM representation.

Downstream stages may *propagate, materialize and verify* a fact; they may
not *reconstruct or override* it from syntax or representation. Forbidden
upward inferences, by name: LLVM type → semantic category or passing mode;
MIR local-table lookup → the meaning of a name; AST spelling → resolved
callee after Sema. **Authority vs verification:** MIR may find that Sema's
constraints cannot be realized consistently across the CFG (a consume on a
path where the place may already be moved); it reports the contradiction —
a program Sema wrongly accepted, or a lowering inconsistency — and never
invents a different semantic answer. After Sema succeeds, invalid MIR is a
compiler bug by default, and the validators are assertions between stages.

**Why.** Two weeks of Sema-vs-MIR-vs-codegen friction were the same
defect in different clothes: two layers independently deciding one fact.
#1635: Sema had resolved `let r = c.run` as a view binding; MirLower's
ident-callee dispatch asked its own `lookup_local`, got -1, and inferred a
function *named* `r` — a `GENERIC_CALL` with the argument dropped, which
killed the native build runner; three fixes in the wrong place changed
nothing because the re-derivation lived elsewhere. The `&fn` marshalling
crash: codegen decided "the value is already a pointer" from the LLVM type
and passed a bare function's code pointer where the callee expected the
address of a pair — the FnAbi rule (D6) already forbids per-path ABI
derivation; this generalizes it to every semantic question. D62/D63's
closure semantics were implemented as special cases in `lower_callable_expr`
and codegen's `spawn_os` path instead of one Sema-emitted
`{environment: Owned|Borrowed, call_kind}` record, which is where #1605 and
#1635 came from. Two validators stayed silent over exactly these MIRs
(#1639, the `audit:contract` `ok` over a refused program) because nobody had
said invalid post-Sema MIR is the compiler's fault.

**Amendments over the proposal.** (1) Ownership is path-sensitive, so Sema
legitimately reasons about control flow (let-else moves, loop-carried
captures); the rule is not "Sema never sees the CFG" but "Sema states
constraints per operation, MIR propagates state, and neither re-derives the
other's answer." (2) No new IR: the semantic tables already exist
(`typed_expr_types`, `resolved_call_sigs`, `expr_view_param_origins`, effect
summaries, `binding_closure_nodes`, the facade contract tables); the gap is
MirLower's ~150 AST-first / own-scope-first lookups, so this is a discipline
campaign plus an audit, not a representation change. (3) Enforce
mechanically now, not "socially first": `audit:resolution` joins Sema and
MIR/codegen facts per node the way `audit:calls`/`audit:mir` do, red on a
callee, place, effect or passing mode that disagrees with its producer.

**Smell test for reviewers.** If deleting or changing a downstream
heuristic could change the meaning of an already-successful Sema result,
the boundary is wrong. Changing MIR's drop-state representation or the
closure environment's physical shape must never change which programs are
accepted.

**Sequencing.** Decision now; every new change obeys it; every bug fixed
from now on moves its answer to the owner rather than adding a second
derivation; `audit:resolution` lands incrementally (callees, then codegen
mode provenance, then places, then effects); the wide MirLower cleanup is
deferred until after STC (`docs/stdlib_sourcing_plan.md` phase 3) —
architecture work must not displace what users feel first.

---
