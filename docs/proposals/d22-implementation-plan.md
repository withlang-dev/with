# D22 Implementation Plan — Uniform Keyed Lookup, Contextual Copy, and View Origins

**Status (2026-07-23): Implementation in progress.**

## Authority and scope

[`docs/d22-Eric-Ruling.md`](d22-Eric-Ruling.md) is the canonical and complete
D22 ruling. Specification v7.2 must conform to it. This plan is only an ordered
implementation checklist: it must not narrow, reinterpret, or add semantics to
the ruling. If this plan conflicts with the ruling, the ruling wins and this
plan must be corrected before implementation continues.

D22 applies to every owning keyed map. The currently named implementations are
`HashMap[K, V]` and `BTreeMap[K, V]`; it also confirms the existing
`SlotMap[T]` lookup/removal contract. D22 does not restandardize the signatures
of Vec, fixed-array, slice, string, iterator, or arbitrary user-defined lookup
APIs. Those APIs participate in D22's general expression and origin rules
according to their existing signatures. Changing those signatures is a
separate D23 candidate.

D22 does not change a map's key-parameter mode. It also does not authorize an
unrelated source-signature, bootstrap, string-runtime, or general parameter-ABI
migration. Keep such work in a separate plan and batch.

## Non-negotiable semantic core

- Every owning keyed-map lookup observes map-owned storage:
  `get(...) -> Option[&V]` for every `V`.
- Removal transfers ownership: `remove(...) -> Option[V]`.
- A map lookup view originates only in the receiver, never in the transient
  key.
- A shared `&T` remains `&T` through inference, forwarding, structural
  projection, capture, and exact-payload elimination, including when `T: Copy`.
- An independently established owned-value demand may materialize `&T` only
  when `T: Copy`: copy the pointee first, then apply ordinary value coercions.
- Contextual Copy never clones, allocates, transfers ownership, duplicates a
  `Drop` value, selects an overload or method, changes dispatch, or changes ABI.
- Patterns are structural projections, not owned-demand positions. Nested
  projection through `&T` produces shared subviews and preserves reference
  layers exactly.
- Multi-expression joins use one arm-order-independent algorithm. Exact-equal
  arms preserve their type; non-reference expressions or an enclosing expected
  type may establish an owned result; compatible `&Copy` arms then materialize.
  A reference-only join preserves references and unions origins. Owned
  temporaries are never implicitly borrowed to force a reference result.
- Diverging `return`, `break`, and `continue` fallbacks contribute no result
  type. Removing the last owned anchor may change an inferred join back to a
  reference; an explicit expected type pins the intended result.
- Origins follow semantic values through transparent carriers and every
  semantic engine. Wrapper spelling, compiler temporaries, IR, inlining, and
  backend representation never launder a view.
- Only a real ownership boundary ends an origin for the independent result:
  contextual Copy, `copied`, `clone`, `cloned`, construction of an independent
  owned value, `remove`, or another explicitly consuming ownership transfer.
- `Option[&T].copied() -> Option[T]` requires `T: Copy`.
- `Option[&T].cloned() -> Option[T]` requires `T: Clone`.
- Raw pointers never participate in contextual Copy.

## Staged execution plan

These stages are the commit and verification boundaries for implementing the
semantic work packages below. A later stage may use facts produced by an
earlier stage; it must not re-derive or reinterpret them. Each stage is kept
reviewable on its own, and no stage is promoted while its gate is red.

The current worktree contains D22 work mixed with an unrelated string,
parameter-mode, bootstrap, runtime-ABI migration, and a suspect `Vec.clone`
rewrite. That mixed tree is evidence and salvage material, not an
implementation baseline. D22 must be reconstructed from reviewed hunks on top
of the committed doctrine. A broad checkout or reset would destroy useful work;
carrying the mixed tree forward would make ownership failures impossible to
attribute.

### Stage 0 — Preserve the mixed worktree and establish a D22-only baseline

Before changing compiler behavior:

1. Preserve every current tracked and untracked change in a recoverable local
   rescue commit/branch. Do not push it as D22 and do not discard it.
2. Start the D22 implementation from the committed doctrine baseline.
3. Create a hunk-level salvage manifest. Classify every mixed hunk as:
   - D22 candidate;
   - unrelated migration work to quarantine;
   - suspect work requiring a fresh proof;
   - test/diagnostic evidence only.
4. Reapply only reviewed D22 hunks. File proximity is not evidence: mixed files
   such as `Sema.w`, `SemaCheck.w`, `MirLower.w`, `CodegenDispatch.w`,
   `rt_core.w`, and `collections.w` must be split by function and purpose.
5. Quarantine all broad `str`/parameter/bootstrap ABI edits and the
   `Vec[T: Clone].clone` rewrite. D22 does not authorize them.

The initial D22 candidate set is limited to:

- Sema exact-type, contextual-adjustment, join, and origin facts;
- MIR consumers of those facts;
- keyed-map declarations, lookup/removal representation, and exact drop glue;
- comptime and C-backend parity for those same facts;
- D22 diagnostics, fixtures, and the semantic migration tool.

**Gate:** the ruling and active doctrine are clean; the rescue state is
recoverable; the implementation diff contains no unrelated source-signature,
string-runtime, bootstrap, general parameter-ABI, or public `Vec.get` change.
No build is needed to answer this source-control question.

### Stage 1 — Version the acceptance matrix without changing behavior

Move the complete D22 matrix into an explicit NON-COMPLIANT lane that is
versioned but excluded from the ordinary green runner. Record the required
verdict, exact type, expected diagnostic, origin set, and drop behavior in each
fixture. Include HashMap, BTreeMap, and the already-uniform SlotMap control;
explicit `Option[&T]`/`Result[&T, E]` programs provide producer-independent
tests for the general rules.

Promote a fixture to the active lane only in the stage that implements its
requirement. A fixture must never be weakened to make a stage green.

**Gate:** every case required by D22 Section 14 has a named fixture and an
owner stage; the existing active test lanes are unchanged and green. This
stage asks only whether the acceptance contract is complete and correctly
quarantined.

### Stage 2 — Establish exact Sema types and one contextual-Copy adjustment

Implement the exact-type half of D22 before generating a pointee copy:

- inference, generic forwarding, patterns, inferred returns, captures,
  `unwrap`, `expect`, and `?` preserve exact reference types;
- demand detection happens only after method, overload, trait, dispatch, and
  ABI selection;
- one Sema-owned adjustment records source expression, exact `&T` source type,
  owned target type, and any ordinary post-copy value coercion;
- raw pointers and non-Copy pointees never receive this adjustment.

Use explicit carriers and SlotMap to prove the mechanism before changing
HashMap or BTreeMap lookup representation. Do not add backend-local Copy
inference.

**Gate:** check-only fixtures prove exact inferred types and every single-value
owned-demand position. `with check src/main.w` answers whether the compiler
sources remain type-correct. Targeted semantic checks answer whether Sema
records one adjustment without changing resolution or ABI. No runtime build is
earned yet.

### Stage 3 — Centralize joins and defaulting eliminators

Add the one order-independent contextual join resolver required by D22. Route
`if`, `match`, sequence/collection literals, `??`, `unwrap_or`, and
`unwrap_or_else` through it. Record owned anchors, materialized reference arms,
view-producing arms, the final type, and the unioned origin set.

This stage includes diverging-arm handling, explicit expected-type
stabilization, reordered and five-arm matches, borrowed defaults, owned Copy
defaults, and non-Copy mismatch classification. It must not yet invent map- or
backend-specific lowering.

**Gate:** semantic fixtures prove arm-order independence and identical results
for every covered join spelling. A source edit that removes the final owned
anchor changes an inferred join to a reference exactly as the ruling states;
an expected type pins it. Diagnostics may still be provisional, but failures
must already be classified by the shared resolver rather than by generic
unification.

### Stage 4 — Propagate transparent-carrier origins as a general Sema fact

Implement one origin-transfer mechanism for Option, Result, tuples, ephemeral
structs/enums, patterns, control flow, optional chaining, built-in and
user-defined `Try`, function effects, generic forwarding, and closure capture.
Construction records carried origins; projection and exact-payload elimination
transfer them; joins union them. Contextual Copy and explicit ownership
boundaries clear the origin only on the independent result.

Integrate these facts with NLL. A mutation is rejected while a possibly
affected view remains live and accepted after its final use. The map lookup key
must never become a view origin.

No `HashMap.get().unwrap()` special case is allowed. Existing uniform producers
and explicit carriers must prove the mechanism first.

**Gate:** the negative origin matrix rejects `unwrap`, `expect`, `?`, user
`Try`, nested patterns, joins, tuple/Result forwarding, and closure escape at
the original storage owner. Positive controls prove contextual copies, clones,
removes, and mutation after final use are independent or dead as appropriate.
Use `--explain-mir-origin`, `--trace-place`, and `--validate-all` to confirm the
semantic facts before touching runtime representation.

### Stage 5 — Lower Sema decisions into ownership-correct MIR

MIR consumes the exact Sema adjustment and join/origin records:

- contextual Copy loads through the shared reference exactly once;
- exact-payload eliminators preserve `&T` when no owned demand exists;
- `copied` and `cloned` create owned results with their required bounds;
- consuming Option/Result eliminators move non-Copy payloads and reset their
  source wrapper instead of duplicating ownership;
- compiler-generated temporaries preserve the Sema origin and place facts.

This stage must not repeat Copy-ness, join selection, or origin inference in
MIR. Fixing an unwrap double-free by dropping both owners, skipping a drop, or
special-casing a map producer is forbidden.

**Gate:** all promoted carrier/contextual-Copy fixtures pass MIR validation.
`--trace-ownership`, `--dump-place-map`, and `--dump-drop-plan` show one owner
after owned extraction and a live view after borrowed extraction. Focused
Option/Result debug-allocator controls report zero invalid frees, double frees,
and leaks. If not, use the debugger to name the exact lowering branch before
another edit.

### Stage 6 — Implement owning keyed-map contracts and exact native drops

In one isolated ownership/ABI batch, align the native implementation of
HashMap, BTreeMap, and SlotMap with the already-proven semantics:

- `get` produces a view into receiver-owned storage for Copy and non-Copy V;
- only the receiver seeds the view origin;
- `remove` transfers one owned payload out;
- replacement, clear, and destruction drop every still-owned key/value exactly
  once;
- removed values remain valid after mutation or collection destruction.

For HashMap, a nullable pointer may represent `Option[&V]`, but caller and
callee must share one internal ABI contract. For BTreeMap, form a checked
reborrow of internal storage without changing the public signature of
`Vec.get`; direct raw reborrow is library-maintainer machinery, not a D23
ruling. Audit SlotMap rather than assuming that its existing source signature
implies correct storage destruction.

**Gate:** run the native debug allocator on Copy and nested non-Copy values for
get, replace, remove, clear, and scope destruction. Use the D22 allocation/drop
fixtures, `tools/debug_drop.w`, drop plans, and LLDB on the exact glue-emission
branch. The gate is zero leaks and exactly one drop per owner—not merely the
absence of the original double free. Because this stage touches ownership,
drop scheduling, and an internal ABI, it remains alone in its batch and earns
`:move-audit` and `:drop-audit`.

### Stage 7 — Make comptime and C emission consume the same semantics

Bring the remaining semantic engines into parity without re-deriving D22:

- comptime evaluation consumes exact types, contextual adjustments, shared
  joins, transparent origins, and uniform map contracts;
- C emission consumes MIR/Sema decisions and uses the same lookup/removal and
  Option representation contracts as native code;
- no backend repairs a wrong source type or synthesizes an owned map lookup.

**Gate:** paired native, comptime, and C-emitted fixtures produce the same
types, diagnostics, values, origins, and drop behavior. Generated C compiles
and runs under the applicable allocator checks. A backend-only pass does not
promote the stage.

### Stage 8 — Finish the D22 diagnostic contract

Use the source facts recorded by Stages 2–4 to produce the normative
diagnostics and machine-applicable remedies. The diagnostic must point through
transparent carriers to the collection and view binding, identify the
invalidating mutation and later use, identify mixed-join anchors and
materialized arms, and distinguish a Copy annotation remedy from explicit
`cloned()` or a lifetime-correct borrowed fallback.

**Gate:** exact diagnostic fixtures pass. Every suggested rewrite is compiled
as a positive companion fixture. Successful programs emit no materialization
notes, and no non-Copy error suggests that an annotation can manufacture
ownership.

### Stage 9 — Migrate active source and retire obsolete pins

Only after the semantics and diagnostics are stable, run the D22 migration over
the compiler and standard-library source. The migration tool may apply only
compiler-proven, unambiguous fix-its; it must never infer intent from `.get()`
spelling or text shape. Ambiguous lifetime/ownership choices remain loud human
decisions.

Convert superseded call-site-only rejection pins into positive tests and
promote the remaining NON-COMPLIANT fixtures. Re-audit active comments and
doctrine against the ruling. Do not combine the postponed string/parameter ABI
migration with this source migration.

**Gate:** the candidate compiler checks the migrated source; the migration is
idempotent; no D22 NON-COMPLIANT fixture remains; and a repository search finds
no active doctrine or code comment that conflicts with the ruling.

### Stage 10 — Bless the isolated D22 batch

Run verification in increasing cost order:

1. focused Sema/type/diagnostic fixtures;
2. MIR validators and origin/ownership/drop traces;
3. comptime/native/C parity fixtures;
4. native debug allocator and move/drop audits;
5. `with check src/main.w` and the targeted D22 suite;
6. `with build` and `with build :fixpoint`;
7. `audit:all` and `with build :test`;
8. `with build :test-green`, `with build :last-green`, reseed, and install only
   after the completed battery supplies the required evidence.

Before each build, state the exact unanswered question and what a pass or fail
would mean. If a failure is in ownership, MIR, codegen, or fixpoint behavior,
use the deep-debugging workflow and locate the exact function, branch,
condition, and emitted instruction before changing code.

**Gate:** every completion criterion below is satisfied across every semantic
engine and backend, and stage2 equals stage3. Only this stage permits calling
D22 implemented.

## Detailed semantic work packages

### 1. Version the complete conformance matrix

Keep failing D22 fixtures explicitly marked NON-COMPLIANT until their required
verdict is implemented. Do not weaken a fixture to match current behavior.
Before moving any fixture into an active lane, verify its exact type, origin,
ownership, diagnostic, and runtime/drop behavior as applicable.

The matrix must cover all of the following.

#### Uniform producer and eliminator types

- `HashMap.get` and `BTreeMap.get` produce `Option[&V]` for Copy and non-Copy
  values.
- `SlotMap.get` remains `Option[&T]`.
- `remove` produces owned `Option[V]`/`Option[T]`.
- Unannotated `get(...).unwrap()` and `expect(...)` infer `&V`.
- Built-in `?` and user-defined `Try` preserve the exact success payload.
- `Some(value)` and `Ok(value)` patterns bind the exact payload type.
- `if let`, `let ... else`, refutable `for`, tuple patterns, nested patterns,
  field projection, and additional reference layers preserve exact types.
- Inferred function returns and closure captures preserve the reference.
- Generic forwarding remains `Option[&V]` for every instantiation.

#### Contextual Copy positions

- Typed bindings and assignments.
- Cast targets.
- Declared function returns.
- Known struct fields, tuple components, and array/collection elements.
- Resolved by-value function parameters and constructor components.
- Already-selected by-value method receivers, without changing dispatch.
- Resolved arithmetic, comparison, and other operator positions.
- Copy first, then ordinary widening or other legal value coercion.
- The source reference remains usable after producing an independent Copy.
- Raw pointers do not materialize.
- Non-Copy pointees fail without invoking `Clone` or another hidden operation.

#### Join behavior

- Same-type reference arms preserve the reference and union origins.
- Owned defaults anchor `??`, `unwrap_or`, and `unwrap_or_else` for Copy
  pointees.
- Borrowed defaults keep an all-reference result.
- `if`, `match`, array literals, collection literals, `??`, `unwrap_or`, and
  `unwrap_or_else` use the same rule.
- Mixed five-arm and reordered-arm cases select the same result type.
- An explicit expected type stabilizes the result.
- Removing the final owned anchor changes an inferred result to a reference.
- Owned temporaries are not implicitly borrowed to force a reference join.
- Non-Copy borrowed-success/owned-default joins fail with the D22 diagnostic.
- `?? return`, `?? break`, and `?? continue` preserve the successful payload's
  exact type because the fallback diverges.

#### Transparent origins

- `Option`, `Result`, tuples, and ephemeral structs/enums.
- `Some`/`Ok` construction and equivalent carrier construction.
- `unwrap`, `expect`, built-in `?`, user-defined `Try`, and optional chaining.
- Patterns, `match`, `if let`, `let ... else`, and refutable `for`.
- `??`, `unwrap_or`, and `unwrap_or_else`.
- Branch and multi-source origin unions.
- Non-owning combinators that forward or derive a view.
- Closure capture, compiler-generated temporaries, inlining, MIR, comptime,
  native codegen, C emission, and runtime representations.
- A contextual Copy, explicit clone, or successful remove ends the source
  origin only for the independent owned result.
- Mutation after a view's final use remains accepted as the NLL precision
  control.

#### Generic ownership contracts

- Uniform borrowed forwarding for unbounded `V`.
- Pattern bindings remain `&V` for every instantiation.
- An owned generic result requires `V: Copy`, `V: Clone` plus explicit cloning,
  or a borrowed default/result contract as specified by the ruling.

#### Diagnostics

- Mutation while a view is live names the original collection, the view
  binding, the invalidating mutation, and the later use.
- A Copy pointee offers a machine-applicable owned-type annotation only when
  its type is known and the rewrite is unambiguous.
- A non-Copy owned join explains the borrowed-success/owned-default split and
  never implies that an annotation can copy a non-Copy value.
- `.cloned()` is suggested only when the required Clone operation exists.
- A borrowed fallback is suggested only when it is lifetime-correct.
- A mixed-join diagnostic identifies the owned anchor and the relevant
  materialized reference arms.
- Carrier diagnostics identify the original storage owner rather than an
  `Option`, temporary, or eliminator.
- Clean builds emit no contextual-materialization notes.

### 2. Establish exact types before contextual adjustment

Keep expression inference, pattern projection, inferred returns, and capture
on exact types. `unwrap`, `expect`, `?`, and structural patterns must expose the
carrier's exact payload type without consulting Copy-ness.

Method lookup, overload resolution, trait selection, dynamic dispatch, and ABI
selection occur on that exact type with ordinary auto-dereferencing. Record a
contextual Copy adjustment only after a resolved context independently demands
an owned target.

Use one Sema-owned adjustment record containing at least the source expression,
exact source type, owned target type, and ordinary value coercion required after
the pointee copy. MIR and every backend consume that decision; they must not
repeat Copy-ness or demand inference.

### 3. Centralize the contextual join algorithm

Implement one Sema join resolver for every covered multi-expression form:

1. Ignore non-reaching/diverging expressions for result-type selection.
2. Preserve an exact type when all reaching expressions have that type.
3. Otherwise determine an owned candidate from an enclosing expected type or
   compatible non-reference reaching expressions, independently of arm order.
4. Materialize only compatible `&T` arms where `T: Copy` and owned `T` can
   ordinarily coerce to the candidate.
5. If no owned candidate exists, preserve compatible shared references and
   union every reaching origin.
6. Reject non-Copy ownership mismatches and attempts to borrow owned temporaries
   into a reference result.

Record the owned anchor, each materialized arm, each view-producing arm, and
the final origin union for diagnostics and MIR lowering. `??`, `unwrap_or`, and
`unwrap_or_else` use this resolver rather than private approximations.

### 4. Implement transparent-carrier origins once

Use one Sema-owned semantic origin-transfer mechanism:

- producers seed origins;
- construction records the origins of carried ephemeral values;
- projection and exact-payload elimination transfer them;
- joins union every reaching origin;
- functions and non-owning combinators propagate origins through inferred or
  declared view effects;
- contextual Copy and explicit ownership-producing operations create an
  independent result with no source-view origin.

The mechanism must cover Option, Result, tuples, ephemeral structs/enums,
patterns, control flow, optional chaining, compiler-generated temporaries,
inlining, built-in and user-defined `Try`, MIR, comptime, and both backends.
No `HashMap.get().unwrap()`-specific escape hatch is permitted. MIR consumes
Sema's resolved facts instead of creating a second origin regime.

Integrate origin invalidation with NLL so mutation is rejected only while a
possibly affected view remains live. Preserve unioned origins across branches
and accept mutation after the final use.

### 5. Converge owning-map lookup and removal across every engine

Align standard-library declarations, Sema, MIR, comptime evaluation, native
codegen, C emission, and runtime behavior:

- every owning keyed `get` returns a view into map-owned storage;
- the view's only producer origin is the receiver;
- Copy-ness never changes the producer signature or representation contract;
- `remove` transfers the payload out and removes it from map ownership;
- map destruction drops values still owned by the map exactly once;
- a removed value remains valid after map mutation/destruction;
- no semantic engine or backend synthesizes owned `Option[V]` for `get`.

A nullable-pointer representation is an implementation choice for
`Option[&V]`, not a separate source-level rule. Internal runtime ABI changes
needed to represent the uniform view must remain consistent across callers and
callees. Contextual Copy itself never changes callable ABI.

### 6. Complete general Option and Result behavior

Keep `unwrap`, `expect`, patterns, and `?` exact-payload operations. Implement
`??`, `unwrap_or`, and `unwrap_or_else` through the shared join resolver for
both Option and Result.

Implement `Option[&T].copied()` and `Option[&T].cloned()` with their exact D22
bounds and results. Their successful results are independent owned values.
Do not make these methods conditional-return operations and do not special-case
them based on a HashMap producer.

### 7. Implement the full diagnostic contract

Use the source facts recorded by contextual adjustment, join resolution, and
origin tracking to produce the diagnostics required by Sections 8.5 and 11 of
the ruling. Diagnostics must explain ownership in the user's terms, point back
through transparent carriers to the true storage owner, and offer only
applicable, lifetime-correct remedies.

Do not substitute generic type-unification failures for D22 ownership
diagnostics. Do not emit informational coercion notes on successful programs.

### 8. Retire superseded doctrine and pins

Inventory documentation, requirements, examples, tests, comments, and
migration tools for the non-conforming interpretations listed in Section 13 of
the ruling. Mark historical material conspicuously superseded or remove active
claims that conflict with D22.

Convert the former call-site-only Copy restriction fixtures into must-compile
tests for every newly authorized owned-demand position. Replace every active
claim that keyed-map `get` returns owned or conditionally-owned values.

All active doctrine must point to `docs/d22-Eric-Ruling.md`. No implementation
comment, handoff, test, or migration tool may narrow or reinterpret it.

### 9. Verify conformance in an isolated ownership/ABI batch

Run the cheapest semantic checks first, then verify every affected engine:

1. exact-type and diagnostic checks in Sema;
2. MIR validation, place/origin traces, and ownership/drop plans;
3. comptime equivalents;
4. native execution under the debug allocator;
5. C emission, compilation, and execution equivalents;
6. generic and NLL precision controls;
7. move/drop audits;
8. compiler self-check and the targeted D22 suite;
9. full build, fixpoint, audit, and test gates for the isolated batch.

Any internal lookup ABI change is part of this isolated batch. Contextual Copy
must remain an expression adjustment and must not alter dispatch or callable
ABI.

## Completion criteria

D22 is implemented only when:

- every required case in Section 14 of the ruling is active and has its stated
  verdict;
- every affected semantic engine and backend agrees on exact types, ownership,
  origins, and runtime behavior;
- map lookup never creates a second owner;
- map removal and destruction drop each owned value exactly once;
- origin tracking rejects every live-view invalidation and accepts the NLL
  controls;
- diagnostics satisfy the ruling rather than merely rejecting the program;
- all active doctrine and migration tools conform to the canonical ruling;
- the isolated build, fixpoint, audit, and test gates pass.

Passing only the current compiler tests, only one backend, or only the pleasant
Copy cases is not D22 conformance.
