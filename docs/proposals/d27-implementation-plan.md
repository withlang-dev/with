# D27 Element-View Implementation Plan (#740)

## Authority and scope

This is a derivative execution plan for the D27 ruling recorded in
`docs/decisions.md` and the normative element-access text in the
specification (beside the operator-trait table). It cannot amend either.
Where this plan and the ruling disagree, the ruling wins and this plan is
wrong. The E1–E4 campaign is complete: the acceptance cells live in the active
behavior and compile-error lanes, and CLAUDE.md carries the conforming status.

Target semantics, restated from D27:

- `xs[i]` denotes the element place: reads yield a view (`&T`), writes
  through a mutable base mutate in place via `IndexPlace`, including
  receiver chains `xs[i].tags.push(v)`.
- `xs.get(i)` returns `&T`, read-only, panicking out-of-range. Keyed maps
  keep `Option[&V]` (D22). `remove(i) -> T` transfers.
- Copy elements materialize at owned demands; non-Copy owned demands are
  rejected (D22 §13.6). A binding names what's there; an annotation
  demands what it says — uniform for fields and elements.
- Uniform across `Vec`, fixed arrays, slices, and user
  `IndexGet`/`IndexPlace` implementations.

## Relationship to the D22 plan

D27 rides the D22 machinery; it must not duplicate it. Element access
becomes another **view producer** feeding the same exact-type,
contextual-Copy-adjustment, join, and origin-propagation pipeline the
map campaign establishes (d22-implementation-plan stages 2–5). Any
element-specific special case in a join or eliminator is the D22 §13.7
"container-specific hack" smell and is wrong here too.

Element stages E2+ therefore build on the D22 stages that install the
shared machinery. Do not start E2 while the corresponding D22 machinery
is absent or half-landed — extend it, in the same functions, guarded by
the same acceptance matrix style.

## Staged execution plan

Each stage is one battery-blessed batch. Ownership/MIR stages are ALONE
in their batches with `:move-audit`/`:drop-audit`.

### E0 — Acceptance matrix and baseline (no behavior change)

Author the element conformance matrix as checked-in expected-output
fixtures, versioned like the D22 matrix: every spelling of element
access (index/get; Copy/non-Copy/Drop-bearing element; let/typed-let/
call-arg/assign/struct-field/return/operator demand; receiver chains
read and write; explicit `&xs[i]`; `remove`) × the CURRENT verdict and
the D27 verdict. The matrix names which cells flip per stage. The
interim gates' pins (err_elem_copy_*, err_view_field_steal_*,
issue64_*) are recorded as pre-D27 cells.

### E1 — Exact Sema types for element reads

`check_index` (runtime index on Vec/array/slice/str) and `Vec.get`
produce `&T` as the expression's exact type; the collection-literal
(type-level base) path is untouched. User `IndexGet` impls already
declare their return; the builtin containers align with them.
Contextual-Copy materialization at owned demands (the D22 adjustment
machinery) covers the Copy cells; non-Copy owned demands are rejected by
the EXISTING #715 gate sites until E3 replaces them structurally.
Receiver-chain WRITE positions must keep resolving through `IndexPlace`
place projection, not through the read view — the mutation cells of the
matrix must not regress. Mutation through a `get` chain becomes an
error (read-only view); issue64 get-mutation pins are respelled to the
`[i]` place form in this batch (their aliasing cells are what D27
specifies; only the accessor spelling changes).

Expected fallout: the compiler and stdlib's own `let x = v.get(i)` on
Copy elements start binding `&i32`-style views; operator and call
demands materialize. Sweep with the matrix, not ad hoc: every fallout
site is either a matrix cell working as ruled or a bug in E1.

### E2 — MIR lowering: reads are borrows, demands are copies

**Execution note (learned in E1):** E1 and E2 land in ONE batch. A Sema-only
flip miscompiles — stage1 built from flipped source materializes views the
old MIR still lowers as owned loads (four matrix cells SIGSEGVed) — and
stage2 is compiled BY flipped stage1, so no battery can bless E1 alone.

Element reads lower to element-address borrows; materialization points
(from Sema's adjustment facts) lower to explicit element loads. No
element-copy drops are scheduled for view reads — `--dump-drop-plan`
and the drop audit are the oracle. `remove` keeps its transfer
lowering. ALONE in its batch; `:move-audit`/`:drop-audit` mandatory.

### E3 — Origins through bindings; retire the interim gates

Bindings that hold element views carry view origins (reuse
`bind_is_view_bound` — the §15.17 iterator-view scope machinery — and
the D22 rule-4 origin facts), so a let-bound view consumed later is
caught at the consume site. Then retire, in the same batch:
- the #715 element gate (`reject_owned_demand_from_element_copy`), and
- the #730 unannotated-let field over-breadth (D26/D27 record it as a
  deliberate stand-in for exactly this stage).
The gates' pins convert to structural-error pins (same spellings, now
diagnosed by the general machinery — diagnostics may re-word, cells may
not change verdict).

### E4 — Fixture, docs, and migrator conformance

Full fixture sweep against the matrix; `with migrate` guidance for
`let x = v.get(i)` idioms; docs examples sweep; spec cross-references
verified. Close #740 citing the batch commits; flip the CLAUDE.md D27
status paragraph from NON-COMPLIANT to done (one line, pointing here).

## Escalation

If `[i]` place semantics prove irreconcilable with view-liveness
(§3.2) — e.g. a live element view invalidated by a sibling in-place
mutation the matrix says must stay legal — STOP and surface to Eric
with the failing matrix cells (D27 reopen clause). Do not narrow the
doctrine, weaken the aliasing rule, or special-case a container.

## Completion criteria

- Every matrix cell shows its D27 verdict; no cell is skipped or
  "temporarily" pre-D27.
- The interim gates are gone; no `reject_owned_demand_from_element_copy`
  call sites remain.
- `with build`, `:fixpoint`, `:test`, `:move-audit`, `:drop-audit` green
  in the final isolated batch; reseed performed.
- The debug allocator shows no element double-free or element-view UAF
  on the matrix programs (`--debug-alloc` run of the behavior matrix).
