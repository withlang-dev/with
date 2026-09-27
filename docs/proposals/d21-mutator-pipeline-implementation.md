# D21 Mutator Pipeline Implementation Plan

**Status:** Planned, not implemented. Specification §9.5/§9.6 and decision D21
lead; the compiler, runtime-facing intrinsics, stdlib, and tests are currently
non-compliant.

**Authority:** `docs/with-specification.md` §9.5 and §9.6,
`docs/decisions.md` D21, and requirements `9.5.1.16`–`9.5.1.17` plus
`9.6.1.12`–`9.6.1.19`.

**Sequencing constraint:** This work follows the active #691/D18 ownership
batch. It must not be mixed into that dirty batch. Finish #691, obtain its full
green evidence, reseed, and start D21 from that known-good compiler.

## Outcome

After this plan lands:

- `Vec.push`, `Vec.clear`, and `Vec.set_i32` are ordinary Unit-returning
  `mut fn` operations everywhere.
- A pipeline stage whose resolved callee is a `mut fn` and whose resolved
  concrete return type is Unit performs the ordinary call and carries the same
  receiver place into the next stage.
- Any other stage carries its actual result. A `Never` stage diverges normally.
- Named places stay live after in-place mutation. Rvalue roots use the existing
  statement-temporary and assignment-move rules; there is no pipeline-specific
  drop cancellation.
- A `mut fn` cannot return the non-Copy receiver as a second owner. Copy
  results, views, fresh owned results, and D17 moved/reset projections remain
  legal.
- Direct calls and pipelines have identical argument evaluation, aliasing,
  receiver access, ABI, and mutation rules.
- LLVM, C emission, and comptime evaluation agree on the same semantics.

This is not a Vale-style `mut`/`move` overload project. No consuming `Vec.push`
overload is added. Receiver-returning value builders remain `move fn`; in-place
mutators get fluency from D21's place-threading rule.

## Scope boundaries

In scope:

- resolved pipeline-stage metadata in Sema;
- pipeline expression typing after inference and generic substitution;
- place-preserving MIR lowering for Unit `mut fn` stages;
- deletion of the historical receiver-returning `Vec.push` machinery;
- LLVM, C, and comptime parity;
- enforcement and regression coverage for receiver-owned returns;
- migration of source and tests that depended on `push` returning a Vec;
- a semantic audit of builder APIs exposed by the ownership flip.

Out of scope:

- changing the general free-function pipeline rewrite;
- threading a receiver after non-Unit mutators;
- adding must-use behavior for `Option` or `Result`;
- restoring receiver-returning `push` to solve type-context propagation;
- reworking `FnAbi` or introducing a pipeline-specific calling convention;
- general improvements to collection inference beyond the D21 surface. This
  plan still must support the specified `Vec.new() |> push(1)` forms by using
  ordinary outer expected types and stage-argument constraints; it may not use
  a receiver-returning `push` as an inference crutch.

## Prerequisite discrepancy: `Vec.pop`

D21's blessed normative examples and requirement `9.6.1.19` use
`Vec.pop() -> Option[T]`. The implementation currently has a different API:
Sema types `pop` as `T`, LLVM and C return the element directly, comptime
evaluation diagnoses an empty Vec, and existing tests assert the raw-element
contract. At planning time, `.pop(` occurs in 35 With source files, including
15 behavior/compile-error/debug-allocator test sites.

This must not be hidden inside pipeline lowering. Under the current spec, the
compliant sequence is:

1. Land an isolated `Vec.pop() -> Option[T]` compliance batch first.
2. Migrate raw-element call sites explicitly (`pop().unwrap()` only where the
   non-empty invariant is real; pattern/optional handling elsewhere).
3. Make empty pop return `None` in runtime and comptime execution.
4. Preserve ownership when returning `Some(element)`: the element moves out,
   the Vec length shrinks, the old slot is no longer live, and dropping the
   Option or its payload drops the element exactly once.
5. Cover both LLVM and C emission and run the move/drop audits for that batch.

If `Vec.pop` is intended to remain trapping and return raw `T`, that conflicts
with the already-blessed §9.6 words and requires a new exact spec ruling before
implementation. The D21 batch may use a small user-defined non-Unit mutator to
develop the value-switching mechanism, but D21 is not complete until the exact
`push |> pop |> unwrap` pins required by the spec pass.

## Current implementation facts

| Layer | Current fact | D21 consequence |
|---|---|---|
| Sema pipeline typing | `SemaCheck.check_pipeline` records only the method name and types the pipeline as the method return. | Sema must separately record the call result and the value/place carried by the pipeline. |
| Builtin signatures | `builtin_intrinsic_method_return_type` says `push` is Unit, while the generic builtin path says it returns the receiver type. | Consolidate the Sema builtin contract; no path may re-derive a receiver result for `push`. |
| MIR lowering | `MirLower.lower_pipeline` delegates directly to `lower_method_call`, so the method result is always the pipeline result. | Add a resolved place-threading path without reevaluating the receiver. |
| Drop scheduling | `lower_intrinsic_call` cancels a `push` receiver temporary's drop, and `cancel_scheduled_value_drop_for_receiver_expr` recursively cancels the receiver for an escaping self-aliasing push. | Delete only the push/self-alias branches; retain the general helper for real moves such as await and field extraction. |
| LLVM backend | `CodegenDispatch` calls `with_vec_push`, then loads the receiver into a non-Unit destination to fabricate a Vec result. | `VEC_PUSH` has a Unit destination and never loads/copies the receiver. |
| C backend | `CCodegen` mirrors the fake receiver materialization. | Remove it and preserve backend parity. |
| Comptime | Pipeline evaluation returns the method result; collection rebinding understands named/field receivers but not a nested pipeline or rvalue carrier. | Carry evaluator place identity across Unit mutator stages and switch to the result at a non-Unit stage. |
| Receiver checker | Tail and explicit returns already feed `EFF_ESCAPE_VALUE` through `note_returned_place_effect`; D17 weakens non-Copy projections to WRITE, and `enforce_receiver_modes` requires `move fn` for a root escape. | Prove and reuse this machinery before adding a new analysis. Harden only uncovered return shapes or diagnostics. |
| Stdlib builders | `ProcessEnv.set` and six `ProcessSpec` methods borrow `&Self` while rebuilding values from owned Vec-bearing fields. | Audit their actual effects; consuming value builders should become `move fn`, unless they perform a real independent clone. |

## Root-cause chain

1. The crash is a double free because a live receiver place and a returned Vec
   header both claim the same allocation.
2. Two owners exist because `push` mutates through `mut self` and also pretends
   to return the receiver as an owned value.
3. The compiler permits that contradiction because builtin Sema paths disagree
   about `push`'s return, and builtin lowering bypasses the ordinary receiver
   effect contract.
4. MIR and both code generators compensate by cancelling drops and copying the
   receiver header, so ownership depends on expression shape and expected type.
5. The deepest design error is conflating a method's call result with a
   pipeline's next carrier. D21 separates them: the call still returns Unit,
   while the pipeline statically carries the receiver place only because Unit
   contains no information.

The implementation must remove that conflation at Sema's resolved-call
boundary. Fixing only the double-free site or only changing the advertised
`push` type would leave the contradictory lowering machinery alive.

## Semantic invariants for the implementation

1. **Resolve once in Sema.** Receiver mode, concrete call result, and pipeline
   carrier kind are decided after overload selection, inference, and generic
   substitution. MIR and backends consume that decision; they do not infer it
   again from method names or destination types.
2. **Keep two types.** A place-threading stage has an actual call result of Unit
   and a pipeline expression type equal to the receiver place's type. These
   facts must not share one field.
3. **Preserve place identity.** The receiver expression is evaluated once. A
   named root remains that place; an rvalue is materialized once as an ordinary
   statement temporary.
4. **Use ordinary calls.** Argument order, receiver exclusivity, borrow checks,
   `FnAbi`, and callee dispatch are the same as `receiver.method(args)`.
5. **Use ordinary move/drop law.** A final receiver carrier can be moved by its
   enclosing value context. If a non-Unit result replaces it, a hidden receiver
   temporary remains scheduled for its ordinary statement-end drop.
6. **No implicit discard of information.** Only resolved Unit enables
   place-threading. `bool`, `Option[T]`, generic `R = bool`, and every other
   non-Unit type carry the result.
7. **No backend ownership invention.** Backends emit the call described by MIR.
   They never load a receiver to manufacture an intrinsic return.
8. **No name-based semantic exception.** `push` is the flagship pin, not the
   definition of the rule. User methods, extensions, and generic methods use
   the same resolved predicate.

## Phase 1 — Characterize and centralize the Sema contract

Before edits, spell and check a small matrix against the #691-green compiler:

- direct named and rvalue `Vec.push`;
- named and rvalue pipeline chains;
- a user `mut fn` with inferred Unit;
- a user `mut fn` returning `bool`;
- a generic mutator instantiated once as Unit and once as `bool`;
- a `mut fn` returning `self`;
- positive receiver-return controls: Copy, view, fresh owned value, and a
  non-Copy projection moved out under D17 reset-on-move.

Use `analyze explain:effect`/the receiver effect audit to establish which cases
already become READ, WRITE, ESCAPE_VALUE, or CONSUME. This decides whether D21
needs a checker fix or only a diagnostic/test pin. Do not add a parallel origin
graph if `note_returned_place_effect`, `weaken_projection_owning_effects`, and
the effect fixed point already prove the rule.

Then add one Sema-owned pipeline-stage decision keyed by the `NK_PIPELINE`
node. The representation may follow the existing sidecar-map style, but it must
encode at least:

- actual resolved call return type;
- carrier kind (`ReturnValue` or `ReceiverPlace`).

The existing `pipeline_method_calls` and `resolved_call_sigs` continue to name
the chosen callee/signature. For a method stage:

1. Resolve and check the ordinary method call.
2. Read the concrete receiver mode from the resolved signature, or from the
   single Sema builtin method descriptor.
3. After substitution/inference, choose `ReceiverPlace` only for
   `ReceiverMode.Mut` plus concrete Unit.
4. Store the actual call return independently.
5. Type the pipeline expression as the receiver type for `ReceiverPlace`, or
   as the call return for `ReturnValue`.

Free-function stages remain ordinary return-value pipelines, including a free
function returning Unit. `Never` remains `ReturnValue`/diverging and gets no
continuation special case.

The return used for this decision must be final. If a forward, generic, or
inferred method return is not resolved yet, drive the existing declaration/
specialization dependency to completion or diagnose an inference cycle; never
classify an unresolved placeholder as Unit. The chosen carrier must be stable
before the outer pipeline stage is checked.

Preserve ordinary bidirectional inference across the pipeline. In particular,
cover all three rvalue constructor shapes:

- `Vec[i32].new() |> push(1)` (explicit receiver type);
- `let v: Vec[i32] = Vec.new() |> push(1)` (outer expected type);
- `Vec.new() |> push(1)` (element type constrained by the mutator argument).

If the last shape exposes a missing constraint edge, add that edge between the
selected method's concrete receiver and arguments. Do not change `push`'s Unit
call result or invent a default element type.

Within Sema, replace the conflicting Vec builtin return tables and mutability
allowlists with one authoritative builtin-method contract (existence, receiver
mode, parameters, return construction). At minimum all consumers must delegate
to one helper. `push`, `clear`, and `set_i32` resolve to Unit on direct calls,
pipeline calls, optional chains, generic instances, and frozen queries.

### Phase 1 gates

- Type dumps show direct `push` is Unit but a Unit-mut pipeline expression has
  the receiver type.
- The generic matrix chooses the carrier from the substituted result, with no
  explicit return annotation required.
- A same-named free function is still used only when no method applies.
- `analyze audit:all` reports no new phase drift or duplicate contract source.

## Phase 2 — Lower a place carrier in MIR

Refactor `MirLower.lower_pipeline` so it consumes Sema's stage decision rather
than using `expr_type(node)` as both call result and pipeline result.

For `ReceiverPlace`:

1. Lower the left side once to an addressable receiver place. A nested
   place-threading stage must return the same place identity; an rvalue uses the
   existing statement-temp materialization path.
2. Lower the ordinary method/intrinsic call against that place, using the
   resolved call signature, existing receiver auto-deref, existing argument
   checking/lowering, and the actual Unit call destination.
3. After the call, expose the same receiver place as the pipeline carrier
   without copying, moving, or creating a second owned local.
4. Let the outer stage or surrounding expression decide whether the carrier is
   borrowed again, observed, discarded, or finally moved.

For `ReturnValue`, retain the ordinary method-result path. A named receiver is
still mutated by the call but is no longer the pipeline carrier. For an rvalue
receiver, its statement temporary stays live until the ordinary statement-end
flush even when the returned value is captured.

The lowering API should make it impossible to evaluate the left expression a
second time. If the existing operand-only interface cannot express a live
non-Copy place without looking like a move/copy, introduce an internal
place-carrier result or a `lower_method_call_with_receiver_place` helper. Do not
encode the distinction as a fake `OK_COPY` of a non-Copy value.

Add validation used by `--validate-all`:

- a place-threading stage's call destination has the actual Unit type;
- its carrier refers to the original/materialized receiver place;
- no new Vec-typed result local is created for `VEC_PUSH`;
- a mixed rvalue chain retains exactly one scheduled receiver-temp drop after
  the stage switches to a non-Unit result.

### Remove the historical push escape machinery

Once the new lowering is active and pinned, delete the push-specific parts of:

- the `VEC_PUSH` statement-temp cancellation in `lower_intrinsic_call`;
- the recursive self-aliasing-push branch in
  `cancel_scheduled_value_drop_for_receiver_expr`;
- expected-Unit rewriting of a `push` return;
- comments and tests that describe a copied receiver as an owner transfer.

Do not delete the general cancellation helper: await, actual local moves, and
D17 field extraction still use it.

### Phase 2 gates

For named, field, and rvalue roots, inspect `--trace-place`,
`--explain-mir-origin`, `--trace-ownership`, `--dump-place-map`, and
`--dump-drop-plan` before a rebuild. The expected proof is one receiver place,
Unit call destinations for Unit stages, no alias owner, and exactly the
ordinary final move or statement-end drop.

## Phase 3 — Make code generation boring

LLVM `VEC_PUSH` continues to call `with_vec_push` but never loads the receiver
into a destination. Delete the `push_dest_sema`/receiver-load branch in
`CodegenDispatch`.

C `VEC_PUSH` does the same. Delete the Vec-typed destination materialization in
`CCodegen`.

Both backends should receive a Unit destination from MIR. A non-Unit
destination for `VEC_PUSH` becomes a validator/compiler-phase error, not a
fallback that fabricates a value. No runtime ABI change is needed for push:
`with_vec_push` already returns void.

User methods continue through the existing resolved signature and `FnAbi`.
D21 adds no per-path ABI rule and must not bypass `compute_fn_abi` or
`push_call_arg`.

### Phase 3 gates

- LLVM and emitted C run the same named/rvalue/mixed fixtures.
- MIR for `push` has a Unit destination in both paths.
- Source search finds no live backend code that loads a `push` receiver as a
  result.

## Phase 4 — Comptime parity

Comptime evaluation needs the same two-part result as runtime lowering: the
ordinary method result and, while applicable, the receiver place/value being
carried. Extend the evaluator with an internal pipeline carrier that preserves
both the current value and enough lvalue identity to rebind a named/field root
across nested Unit stages. Rvalue roots use an evaluator-owned hidden slot for
the duration of the pipeline evaluation.

For each method stage:

1. Execute the ordinary method evaluator and update the receiver exactly as a
   direct call would.
2. Consult the resolved D21 carrier kind.
3. Return the updated receiver carrier for Unit `mut fn`, or discard the
   carrier and return the actual non-Unit result.

Top-level comptime transforms currently run before normal Sema has populated
`pipeline_method_calls`. Their fallback must use the same Sema method-contract
helpers and resolved return substitution rather than a second name-based D21
table. If a user/generic stage cannot be resolved soundly at that phase, fail
loudly or defer it to the typed evaluator; never guess Unit from a method name.

Direct `v.push(x)` remains Unit in comptime. Only a pipeline expression carries
the updated Vec. Empty `pop` behavior follows the separate Option prerequisite.

### Phase 4 gates

- Named and rvalue Unit-mutator chains work in comptime.
- A generic Unit/non-Unit pair switches carriers per concrete instantiation.
- Direct `push` is still Unit.
- Runtime and comptime produce the same mixed-chain value and post-mutation Vec.

## Phase 5 — Enforce the receiver ownership rule

Use the characterization matrix to finish the general rule at the existing
effect-summary choke point:

- returning a non-Copy root `self` from `mut fn` records ESCAPE_VALUE and
  requires `move fn`;
- returning a Copy value does not force ownership escape;
- returning a reference records ESCAPE_VIEW and uses ordinary origin tracking;
- returning a fresh owned value has no receiver origin;
- returning a non-Copy projection is WRITE on the receiver root only when D17
  actually moves and resets that projection.

Exercise implicit tails, explicit `return`, branches, matches, generic
specializations, and transitive helper returns. If an uncovered wrapper loses
the root, extend `note_returned_place_effect`/the existing effect edges. If the
effects are already correct, add a D21-specific diagnostic at
`enforce_receiver_modes` that explains that receiver-returning fluency requires
`move fn`; do not add a redundant ownership analysis.

Builtin APIs do not get an exemption. Their contracts must be representable by
the same rule; making `push` Unit removes the invalid builtin contract.

### Phase 5 gates

- The negative receiver-return fixture fails at the method declaration with a
  `move fn` remedy.
- Copy, view, fresh-owned, and moved/reset projection controls compile and run.
- `analyze <file> audit:receivers` plus
  `'explain:effect:Type.method:self'` shows the exact root or projection path
  that justified each result.

## Phase 6 — Source and test migration

### Stdlib/source audit

Run a semantic receiver/effect audit over stdlib, build code, compiler code,
examples, and tests. Text search is only the candidate list; the decision is
based on resolved effects and ownership origins.

Known candidates:

- `ProcessEnv.set`;
- `ProcessSpec.arg`, `working_dir`, `timeout`, `stdin`, `env_var`, and
  `capture`.

These currently rebuild owned values from `&Self` fields. Convert genuine
value builders to `move fn` and move owned fields into the replacement value.
Use a read receiver only if the implementation performs a real independent
clone. Spell and run the named-place, reassignment, and temporary-chain call
matrix before mechanically migrating callers; do not infer move-receiver call
ceremony from Rust.

The generated SoA `push` in `ComptimeTransform` already uses `move self` and
returns Self. Keep it as the positive consuming-builder model.

### Existing tests to migrate, not delete

- `behav_pipeline_vec_push_chain.w`: retain the rvalue chain and add one
  expression chaining over a named Vec that remains live afterward.
- `behav_drop_vec_pipeline_elements.w`: rewrite the ownership explanation from
  self-aliasing result temps to one hidden place; retain exact element drops.
- `da_vecdrop_field_push_chain_tail.w`: replace obsolete dot chaining
  `h.items.push(...).push(...)` with a D21 pipeline over the field place.
- `behav_drop_vec_push_value_tail.w`: stop returning `push`; perform the Unit
  call and return the Vec explicitly so the test pins a real move.
- `behav_drop_vec_push_stmt_reuse.w` and
  `behav_drop_vec_push_void_tail.w`: keep behavior, replace receiver-returning
  comments with the Unit contract.
- `behav_mut_self_vec_return.w`: retain as the consuming `move fn` builder
  control.
- `behav_pipeline_methods.w`: retain method-over-free resolution coverage.
- `behav_comptime_pipeline_intrinsic.w`: extend or add a sibling for mutator
  pipeline parity.
- `behav_process_env_builder.w` and build ProcessSpec fixtures: retain fluent
  value-builder behavior under consuming receiver contracts.

Search all source and non-superseded docs for bound, returned, dotted, or piped
`push` results. Every hit must be classified as one of: D21 pipeline, explicit
statement plus real move, consuming builder, or stale historical text. Do not
perform a blind textual rewrite of self-hosting code; if a migration tool is
needed, write it in With and use the parser/token model.

### Required new pins

| Pin | Required observation |
|---|---|
| Named Unit chain | `v |> push(1) |> clear() |> push(3)` mutates one place and `v` remains live. |
| Rvalue Unit chain, bare statement | One hidden Vec is created and dropped once at statement end. |
| Rvalue Unit chain, captured | The final hidden Vec moves into the binding and is dropped once by that binding. |
| Inferred Unit user mutator | No explicit `-> Unit` annotation is needed for place-threading. |
| Generic Unit/non-Unit pair | The substituted concrete return controls the carrier independently per instantiation. |
| Named mixed chain | `push |> pop |> unwrap` returns the element and leaves the named Vec alive and empty. |
| Rvalue mixed chain | The Option arrives; the now-empty hidden Vec drops exactly once at statement end under `--debug-alloc`. |
| Non-Unit status mutator | `try_push -> bool` carries the bool rather than silently carrying/moving the Vec. |
| Never | A `-> Never` mutator has no continuation; later stages are unreachable under ordinary rules. |
| Aliasing parity | `v |> push(f(v))` and `v.push(f(v))` receive the same accept/reject result and diagnostic. |
| Receiver escape error | A `mut fn` returning non-Copy `self` is rejected with `move fn` guidance. |
| Return controls | Copy, view, fresh owned, and D17 moved/reset projection returns remain accepted. |
| Direct-call control | `v.push(x)` has Unit type outside a pipeline. |
| Free-function control | A Unit-returning free pipeline stage carries Unit, not its first argument. |
| Backend/comptime parity | The semantic matrix agrees under LLVM, emitted C, and comptime evaluation. |

Use Drop-bearing elements and the debug allocator where ownership is material;
POD-only tests cannot detect copied Vec headers.

## Execution order and batch discipline

### Gate 0 — Finish the active ownership batch

Do not touch implementation files for D21 until #691/D18 is green, committed,
and reseeded. Record its exact commit as the D21 baseline. This prevents a D21
drop failure from being confused with the current `restore_moved_field_lengths`
stage-layout failure.

### Batch A — `Vec.pop() -> Option[T]`

This is an isolated API/codegen/ownership batch because it changes returned
ownership and both backends. Add the empty/non-empty/drop pins, update Sema,
MIR/backend/comptime handling, migrate all callers, then run the full
move/drop-aware battery. Do not mix D21 place-threading into it.

### Batch B — D21

Keep D21 alone in its batch. Suggested commit order within the batch:

1. Add the semantic matrix and expected-failure pins.
2. Centralize builtin method contracts and record resolved pipeline carriers.
3. Implement place-preserving MIR lowering and validation.
4. Remove LLVM/C fake `push` returns.
5. Implement comptime carriers.
6. Harden the receiver-return check only where the matrix proves a gap.
7. Migrate directly affected stdlib/source/tests and delete obsolete
   self-alias workarounds.
8. Mark requirements `9.5.1.16`–`9.5.1.17` and
   `9.6.1.12`–`9.6.1.19` complete only after every required pin is green.

Use iterate-tier evidence per commit. Run one full battery for the completed
isolated batch, as required by D19.

## Verification strategy

Every build must answer a stated question. Use source inspection, analysis, MIR
dumps, and the debugger first.

### Iterate tier

1. `with check src/main.w`
   - Question: is the edited compiler source accepted by the current blessed
     seed?
2. Targeted `with check`/run of the semantic matrix
   - Question: does Sema choose the expected call-result/carrier pair and do the
     focused runtime assertions hold?
3. `with check <repro> --trace-place ... --explain-mir-origin ...`
   - Question: is every Unit stage rooted in the same place without a second
     owner?
4. `--trace-ownership`, `--dump-place-map`, `--dump-drop-plan`, and
   `--trace-cleanup-edge`
   - Question: is the final receiver moved or dropped exactly where ordinary
     rules require?
5. `--validate-all`
   - Question: are Sema's actual call result, pipeline carrier, MIR destination,
     and scheduled drops internally consistent?
6. `WITH_DEBUG_ALLOC=1`/`--debug-alloc` on the rvalue, mixed, and Drop-element
   pins
   - Question: is there exactly one Vec allocation owner and one corresponding
     free, with each live element dropped once?
7. Targeted emitted-C compilation/run
   - Question: does the C backend match LLVM without receiver materialization?
8. `with build :dev`
   - Question: can the seed produce one self-hosted stage containing D21?

For a memory verdict, start with the native debug allocator, then use
`tools/debug_drop.w`/LLDB plus the ownership and drop-plan dumps to reach the
exact lowering/codegen branch. For a large failure, minimize with `with reduce`.
Do not enter an edit/build/trace loop. For a fixpoint failure, run
`with build :fixpoint-diff` before inspecting generated objects.

### Full isolated-batch battery

After targeted evidence is green:

1. `with build`
2. `with build :fixpoint`
3. `./out/stage/bin/with-stage2 analyze src/main.w audit:all`
4. `with build :move-audit`
5. `with build :drop-audit`
6. `with build :emit-c-test`
7. `with build :emit-c-fixpoint`
8. `with build :test`
9. `with build :test-green`
10. `with build :last-green`
11. `with build :update-seed`
12. `with build :install-user`

Run independent audit/test targets concurrently only where the build graph says
their outputs do not overlap. Never change optimization from `-O1`.

## Completion criteria

D21 is complete only when all of the following are true:

- every D21 requirement is backed by a passing behavior, compile-error, or
  debug-allocator pin;
- `Vec.push`, `clear`, and `set_i32` are Unit in every Sema/query path;
- the method call result and pipeline carrier are distinct, resolved Sema facts;
- generic instantiations choose place/result carriers from the concrete return;
- MIR evaluates each receiver once and uses ordinary place/temp/drop law;
- no live push-specific drop cancellation or backend receiver-return branch
  remains;
- user-defined methods, builtins, extensions, LLVM, C, and comptime agree;
- the receiver-return negative and all four positive controls pass;
- exact named and rvalue `push |> pop` pins pass with `Option` and exact drops;
- stdlib/source receiver-owned builder candidates have been semantically audited
  and migrated or proven independently owned;
- no non-superseded document or test still describes `mut self` push as
  returning an owned Vec;
- the isolated full battery, fixpoint, audits, tests, evidence recording,
  reseed, and user install all pass.
