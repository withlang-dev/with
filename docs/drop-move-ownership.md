# Plan: Correct Complete Drop/Move Ownership Solution

## Purpose

This document defines the implementation plan for completing With’s drop/move substrate correctly, without accidentally changing language semantics or hiding unresolved allocator evidence.

The core problem is not “drop `Vec` fields” in isolation. The core problem is that the compiler needs a real ownership state machine for MIR places:

> For every non-Copy value, at every program point, exactly one place owns the drop obligation, unless the value is intentionally uninitialized, moved, or conditionally initialized behind a runtime drop flag.

The complete solution is:

```text
canonical MIR places
+ per-place drop obligations
+ partial aggregate drop emission
+ sema-typed drop glue
+ path-sensitive cleanup
+ runtime drop flags for conditional ownership
+ generated async/generator state modeled as ordinary owned places
+ explicit language decision on user-visible field move-out
```

This plan deliberately separates:

1. **The substrate**: what the compiler must know to avoid leaks and double frees.
2. **The language rule**: whether users are allowed to move a drop-needing field out of an aggregate.
3. **Cascade discoveries**: tuple projection normalization, cleanup path sensitivity, generated async/generator state, and allocator leaks.

The substrate can make some programs mechanically safe, but that does not automatically mean the language should permit them.

---

## Current Decision Boundary

### Existing language policy remains in force unless explicitly changed

The existing `err_move_out_vec_field_*` compile-error fixtures represent a deliberate semantics guard:

```text
Moving a drop-needing field out of an aggregate is rejected.
```

Do not convert these tests into behavior tests unless the BDFL explicitly chooses that language semantics.

Until then:

```text
User-visible move-out of drop-needing aggregate fields: rejected.
Internal compiler-owned field transfers: allowed only through the MIR ownership substrate.
```

### Required cleanup before continuing

Before implementation resumes, restore the tree to a policy-clean state:

```text
restore test/compile_errors/err_move_out_vec_field_let.w
restore test/compile_errors/err_move_out_vec_field_return.w
restore test/compile_errors/err_move_out_vec_field_moveself.w

delete or shelve:
  test/behavior/behav_move_out_vec_field_let.w
  test/behavior/behav_move_out_vec_field_return.w
  test/behavior/behav_move_out_vec_field_moveself.w
  test/debug_alloc/da_vecdrop_moveout_let.w
  test/debug_alloc/da_vecdrop_moveout_return.w
  test/debug_alloc/da_vecdrop_moveout_moveself.w
```

Also revert or isolate the generator-state clear edit unless it is separately proven. The previous evidence showed it did **not** fix the channel double-free; the path-sensitivity fix did.

### Diagnostic tools to use before substrate edits

Before changing MIR ownership lowering, cleanup emission, or drop glue, capture
the current facts with the diagnostic-only `with check` tools:

```text
--dump-place-map
--trace-ownership <fn:place>
--dump-drop-state
--dump-drop-plan
--trace-cleanup-edge '<fn:bbA->bbB>'
--dump-drop-flags
--validate-ownership
--validate-all
```

These reports show what MIR currently believes about places, moves, cleanup
edges, and planned drops. They do not prove the root cause by themselves; use
them to choose the exact lowering or codegen branch to inspect in `lldb`.

---

## Non-Goals

This substrate session must not silently absorb unrelated Phase 8 work.

Out of scope unless separately commissioned:

```text
#348 c_import shell-out removal
#357 proven C ownership wrappers
#604 []mut T coercion
#608 POD Vec buffer freeing
language decision to allow user-visible move-out of Drop fields
```

Also out of scope:

```text
changing tests to match accidental semantics
declaring debug-alloc leaks “expected noise” without provenance
zeroing generator fields as a cleanup substitute
type-global “consumed field” state
```

---

## Core Concepts

### Place

A `Place` is the unit of ownership.

A place is:

```text
base local + canonical projection path
```

Examples:

```text
h
h.items
h.pair.0
state.rx
state.payload.inner.values
```

### Projection

Projection representation must be canonical. Do not represent tuple fields sometimes as raw integer `0` and sometimes as interned symbol `"0"`.

Recommended MIR-level representation:

```text
enum ProjectionKind:
    Field(symbol)
    TupleIndex(i32)
    ArrayIndex(...)
    Deref
```

If the AST represents `pair.0` as a field symbol `"0"`, normalize it when constructing MIR places. Codegen should not be responsible for recovering from inconsistent projection encodings.

### Drop obligation

A drop obligation records that a place currently owns initialized cleanup.

Conceptual model:

```text
DropObligation {
    place: PlaceId,
    ty: TypeId,
    state: DropState,
}
```

### DropState

```text
Init        // place currently owns an initialized value
Moved       // value was moved out; do not drop
Uninit      // no initialized value lives here
Maybe(flag) // value may be initialized at runtime; consult drop flag
```

`Maybe(flag)` is needed for path-sensitive and conditional moves.

### Aggregate splitting

A whole aggregate can be split into field obligations lazily.

Before:

```text
h = Init
```

After moving `h.a`:

```text
h.a = Moved
h.b = Init
```

Cleanup for `h` now means:

```text
drop h.b
skip h.a
StorageDead h
```

not:

```text
drop h
```

and not:

```text
StorageDead h only
```

---

## Compiler Responsibility Split

### Sema

Sema decides legality.

Sema should:

```text
classify move/copy/borrow expressions
enforce language policy
reject use-after-move
reject forbidden user-visible move-out of Drop fields
preserve existing diagnostics unless policy changes
```

Sema should not own the runtime drop model.

Sema may maintain a diagnostic-only field-move model, but the authoritative drop ownership state belongs in MIR.

### MIR Lowering

MIR lowering owns the drop obligation model.

MIR should:

```text
canonicalize places
update ownership state on move/copy/assignment/borrow/drop
split aggregate obligations when needed
emit drops only for still-owned initialized places
insert runtime drop flags when static ownership is path-dependent
model generated async/generator state as ordinary owned places
```

### Codegen

Codegen emits drop glue, not ownership policy.

Codegen should:

```text
consume MIR Drop(place, sema_type)
use sema-typed drop dispatch for aggregate fields
emit Vec/array/tuple/enum/struct drop glue correctly
not infer ownership from type alone
not skip fields based on type-global consumed state
```

The guiding rule:

```text
MIR decides whether to drop.
Codegen decides how to drop.
```

---

## Ownership Transfer Rules

### Copy

For Copy types:

```text
copy src -> dest
```

State effect:

```text
src remains Init
dest becomes Init
```

For non-Copy types, copy by value is illegal unless it is an internal representation copy paired with ownership state transfer.

### Move

For non-Copy / drop-needing values:

```text
move src -> dest
```

State effect:

```text
require src is initialized
dest becomes Init
src becomes Moved or Uninit
descendant obligations under dest are reset to reflect the new value
ancestors of src become partially initialized if src is a field path
```

Example:

```with
let h = H { a: make(), b: make() }
let moved = h.a
```

Conceptual state:

```text
before:
  h.a = Init
  h.b = Init

after:
  moved = Init
  h.a = Moved
  h.b = Init
```

If language policy rejects this user-visible move, Sema rejects it before MIR. But MIR must still support equivalent internal ownership transfers.

### Assignment / Reinitialization

For:

```with
h.a = new_value
```

MIR must:

```text
if h.a is initialized:
    drop h.a using sema-typed drop glue
assign new_value into h.a
mark h.a = Init
clear moved/uninit descendants of h.a
```

If `h.a` was `Moved` or `Uninit`, do not drop old storage before assignment.

### Drop

For:

```text
drop place
```

MIR must emit drops for exactly the initialized obligations under `place`.

Cases:

```text
whole place Init:
    Drop(place, sema_ty)

partially moved aggregate:
    Drop(initialized fields only)
    skip moved fields

Maybe(flag):
    if flag:
        Drop(place, sema_ty)
```

### StorageDead

`StorageDead(local)` is not a drop.

Before `StorageDead(local)`, MIR must already have discharged all initialized drop obligations beneath that local.

### Borrow

Borrow does not transfer ownership.

Borrowing a moved/uninit place is illegal.

Mutable borrow may restrict later assignment/move by existing borrow rules, but it should not alter drop state by itself.

---

## Branches and Runtime Drop Flags

### Why static field ledgers are insufficient

This case cannot be solved by a straight-line table alone:

```with
if cond:
    let x = h.a

// cleanup for h
```

At cleanup:

```text
h.a moved if cond == true
h.a still initialized if cond == false
```

A complete solution must either reject this or generate a runtime drop flag.

### Initial policy option

The project may initially reject conditional partial moves:

```text
conditional move of drop-needing field requires drop-state tracking
```

This is acceptable only as an explicit staged limitation.

### Complete policy

The complete fix requires runtime drop flags:

```text
drop_h_a = true

if cond:
    x = move h.a
    drop_h_a = false

if drop_h_a:
    drop h.a
drop h.b
StorageDead h
```

MIR representation:

```text
DropState::Maybe(flag_local)
```

Merge rule at control-flow join:

```text
Init + Init       -> Init
Moved + Moved     -> Moved
Init + Moved      -> Maybe(flag)
Moved + Init      -> Maybe(flag)
Uninit + Init     -> Maybe(flag)
Uninit + Moved    -> Uninit/Moved depending on path legality
```

The exact join lattice should be documented and unit-tested.

---

## Generated Async / Generator State

Generated state must use the same ownership model as user locals.

Do not special-case by zeroing fields at completion.

### Correct model

When resuming:

```text
local_x = move state.x
state.x = Moved
```

When suspending:

```text
state.x = move local_x
local_x = Moved
```

When completing:

```text
drop initialized locals
drop initialized state fields
skip moved state fields
StorageDead state
```

If a state field is initialized only on some paths, it needs a runtime drop flag.

### Avoid

Do not use this as the primary fix:

```text
on generator return:
    zero all drop fields in state
```

That is not ownership modeling. It can mask double frees, create leaks, or corrupt values. It is only valid if proven as an implementation of a precise ownership transition, and the previous evidence did not prove it.

### Channel-specific caution

The channel bounded case previously produced:

```text
ok
debug-alloc: LEAK ... size=512
debug-alloc: LEAK ... size=512
debug-alloc: leak count=2
```

That must remain open until root-caused.

Acceptable resolutions:

```text
1. free the leaked allocations;
2. prove they are intentional process-lifetime roots and teach debug-alloc to classify them as roots;
3. create a smaller channel debug-alloc fixture with deterministic ownership and document why the behavior test is not a debug-alloc oracle.
```

Unacceptable resolution:

```text
call it expected noise without allocation provenance
```

---

## Field Receiver Chains

The chain:

```with
h.items.push(a).push(b)
```

must be assigned explicit semantics.

There are two possible models.

### Model A: field is consumed and not reinitialized

Lowering resembles:

```text
tmp0 = move h.items
tmp1 = Vec.push(tmp0, a)
tmp2 = Vec.push(tmp1, b)
drop tmp2
h.items = Moved
drop h.other
StorageDead h
```

This preserves chaining but means `h.items` is moved afterward.

### Model B: field is reinitialized after chain

Lowering resembles:

```text
tmp0 = move h.items
tmp1 = Vec.push(tmp0, a)
tmp2 = Vec.push(tmp1, b)
h.items = move tmp2
h.items = Init
```

This preserves chaining and keeps `h.items` usable afterward.

Decision: use Model B. Field receiver chains reinitialize the field after the
chain, so `h.items` remains usable afterward. Do not rely on accidental
tail-expression behavior.

The substrate should support both; language lowering should choose one deliberately.

---

## Sema Policy: Move-Out of Drop Fields

This is a language fork.

### Option 1: keep rejection

Current policy:

```text
moving a drop-needing field out of an aggregate is rejected
```

Then these should remain compile-error tests:

```text
test/compile_errors/err_move_out_vec_field_let.w
test/compile_errors/err_move_out_vec_field_return.w
test/compile_errors/err_move_out_vec_field_moveself.w
```

Sema must reject user-visible expressions like:

```with
let moved = h.a
return h.a
fn Holder.into_values(move self) -> Vec[W]: self.values
```

even though MIR can model them.

Internal generated MIR may still use field-level ownership transfers.

### Option 2: allow partial moves

If the BDFL chooses to allow this:

```text
moving a drop-needing field out of a non-Drop aggregate is allowed
```

then add behavior and debug-alloc tests, and define restrictions:

```text
Is it allowed if the owner type implements Drop?
Is whole-owner use rejected after partial move?
Can fields be reinitialized?
Are conditional partial moves allowed or rejected until drop flags?
Are tuple/array/enum payload partial moves allowed?
```

This should be a separate explicit language change, not a side effect of the substrate.

---

## Implementation Milestones

### Milestone 0: Restore policy-clean baseline

Actions:

```text
stop any running build/test processes
restore deleted compile-error tests
remove untracked behavior/debug tests that encode the unapproved allow policy
revert or shelve generator-state clear
verify git diff contains only intended substrate files
```

Gates:

```text
with check src/main.w
known baseline tests, or document current reds exactly
```

Output:

```text
short state note: clean policy boundary restored
```

### Milestone 1: Add debug-alloc provenance

Before more soundness work, make allocator evidence actionable.

Add one of:

```text
allocation site tags
allocation callsite backtraces
runtime category tags
```

Minimum useful output:

```text
debug-alloc: LEAK addr=... size=512 tag=fiber_stack allocated_at=...
debug-alloc: DOUBLE FREE addr=... size=64 tag=channel_receiver first_freed_at=... second_freed_at=...
```

This is especially important for channel/task/generator cases.

Gates:

```text
da_manual_double_free still reports DOUBLE FREE
known da_vecdrop fixtures still report their current expected counts
channel bounded leak can be attributed to an allocation category
```

Do not proceed to claim soundness with unexplained leaks.

### Milestone 2: Canonical MIR places

Implement canonical projection representation.

Tasks:

```text
define ProjectionKind if not already present
normalize tuple fields to TupleIndex(i32)
normalize struct fields to Field(symbol)
ensure nested field paths round-trip through MIR dump
ensure Codegen consumes canonical projections
remove duplicate tuple-token recovery paths where possible
```

Tests:

```text
MIR dump for pair.0 uses TupleIndex(0)-equivalent representation consistently
field paths for h.inner.items are stable
no raw "0" vs 0 mismatch in partial-drop synthesized places
```

Gate:

```text
with check src/main.w
with build
```

Status: implemented. MIR now has `ProjKind.PK_TUPLE_INDEX`; source tuple field
access, tuple destructuring, tuple patterns, tuple `with` bindings, and
partial-drop synthesized tuple fields construct canonical tuple-index
projections. Flow-fact tables compare projection kind and projection payload, so
`Field(0)` and `TupleIndex(0)` cannot alias.

### Milestone 3: Sema-typed drop glue

Implement or retain sema-typed drop dispatch.

Tasks:

```text
Drop(place, sema_ty) carries or recovers sema type reliably
struct field drops project sema field type
tuple drops project tuple element type
array drops project element type
enum payload drops project active payload type
Vec[T] drops elements if T needs drop, and releases buffer according to current Vec policy
```

Key invariant:

```text
type_needs_drop tells whether drop glue exists.
ownership state tells whether to invoke it.
```

Tests:

```text
Vec[Drop] field inside struct drops elements
tuple field containing Vec[Drop] drops elements
array field containing Drop drops elements
nested struct field containing Vec[Drop] drops elements
```

Gate:

```text
with build :debug-alloc-tests
```

### Milestone 4: MIR drop obligation ledger, straight-line only

Implement per-place ownership state for straight-line code first.

Tasks:

```text
record local initialization
record field move
record field reinitialization
record assignment drop-before-overwrite
split aggregate obligations lazily
emit partial drops at scope cleanup
```

Explicitly reject or conservatively diagnose conditional partial moves until Milestone 7.

Core transfer functions:

```text
on_move(src, dest)
on_copy(src, dest)
on_assign(dest, rhs)
on_drop(place)
on_storage_dead(local)
on_reinit(place)
```

Tests:

```text
A6: struct field reassignment drops old + new contents exactly once
B: self.values = mk() does not leak old Vec
field receiver push tail does not double-free
sibling field still drops after one field is consumed
field receiver chain remains valid under chosen semantics
```

Gates:

```text
with check src/main.w
with build
focused debug-alloc fixtures
```

### Milestone 5: Path-sensitive cleanup correctness

The previous session exposed this failure:

```text
cleanup path A emitted partial cleanup and cleared moved-field state
cleanup path B later forgot the field move and emitted whole drop
```

Fix this architecturally.

Tasks:

```text
associate ownership state with MIR control-flow state, not one global mutable table
do not clear ownership facts merely because one cleanup path was emitted
at each cleanup emission point, consult the ownership state for that control-flow path
```

Possible implementation strategies:

#### Strategy A: explicit state snapshots per basic block

```text
block_entry_state[bb]
block_exit_state[bb]
merge states at joins
emit cleanup from the state associated with that edge
```

#### Strategy B: cleanup scopes carry drop obligations

```text
drop tree is attached to cleanup scope
move/reinit updates the scope obligation
each cleanup edge emits from the current obligation snapshot
```

Avoid:

```text
global moved_field list cleared after first cleanup emission
```

Tests:

```text
normal return + alternate cleanup branch for partially moved tuple
early return after field move
panic/defer cleanup after field move if supported
channel tuple pair.0/pair.1 move does not double-free
```

Gates:

```text
focused channel behavior tests
debug-alloc channel fixture if deterministic
with build :test behavior-tests
```

### Milestone 6: Preserve language rejection for user-visible field moves

If current policy remains rejection, restore and strengthen Sema guards.

Tasks:

```text
detect user-visible move from drop-needing aggregate field
reject let-binding form
reject return-tail form
reject explicit return form
reject move-self method return form
allow internal compiler-generated field transfers only through marked lowering paths
```

Important distinction:

```text
h.items.push(...) may be an approved field receiver lowering.
let moved = h.items is a user-visible field move.
```

Tests:

```text
err_move_out_vec_field_let.w
err_move_out_vec_field_return.w
err_move_out_vec_field_moveself.w
err_use_after_move_struct_field.w
err_use_after_move_vec_into_struct_field.w
```

Gate:

```text
with build :test native-compile-error-tests
```

If the policy changes to allow partial moves, this milestone becomes a language-change milestone instead, with an explicit spec update.

### Milestone 7: Runtime drop flags for conditional ownership

Implement the complete dynamic solution.

Tasks:

```text
introduce drop flag locals
set flag true when place initialized
set flag false when place moved/uninitialized
merge Init/Moved control-flow states into Maybe(flag)
emit conditional drops
clear flags on StorageDead
```

Cases:

```text
conditional field move
conditional reinitialization
early return after partial move
loop-carried maybe-init state
generator suspend/resume maybe-init state
```

Initial implementation may reject loops with changing partial ownership if full dataflow is too large, but that limitation must be explicit.

Tests:

```text
if cond moves h.a; h.b always drops; h.a drops only when not moved
if cond reinitializes h.a; exactly one old/new value drops
early return after partial move does not double-free
```

Gates:

```text
with build
with build :debug-alloc-tests
focused conditional debug-alloc fixtures
```

### Milestone 8: Generated async/generator state ownership

Replace special cleanup with ordinary ownership transfers.

Tasks:

```text
model generator/task state fields as MIR places
on resume: move state.field -> local; mark state.field moved
on suspend: move local -> state.field; mark local moved
on completion: drop initialized locals/state fields using normal obligations
remove speculative zero/clear hacks
```

Debug focus:

```text
channel sender/receiver captured into async task
completed task cleanup
awaited task cleanup
cancelled/dropped task cleanup
generator suspend with owned Vec[Drop]
generator completion with moved state fields
```

Required allocator evidence:

```text
no DOUBLE FREE
no unexplained LEAK
if runtime-root allocation remains, it is tagged and documented
```

Gates:

```text
behav_channel_bounded.w
behav_channel_close.w
new focused debug-alloc channel/task fixture
with build :debug-alloc-tests
```

### Milestone 9: Full regression matrix

Add or update fixtures covering:

#### Shapes

```text
Vec[Drop]
array of Drop
tuple containing Drop
struct containing Vec[Drop]
nested struct containing Vec[Drop]
enum/Option payload containing Drop
channel endpoint in tuple
generated state field containing channel endpoint
```

#### Operations

```text
construction in-place
construction via named local move-in
rvalue move-in
drop at trailing statement
drop as tail expression
field reassignment
field receiver push tail
field receiver chained push
sibling field preservation
discard/wildcard aggregate field
partial move use-after-move
conditional partial move / drop flag
async/generator resume/suspend/complete
```

#### Expected results

For sound debug-alloc fixtures:

```text
leak count=0
no DOUBLE FREE
```

For sentinel fixtures:

```text
da_manual_double_free -> DOUBLE FREE
da_pod_vec -> leak count=1 only if #608 remains out of scope
```

For policy fixtures:

```text
move-out-of-Drop-field compile-error tests remain errors unless policy changes
```

---

## Required Gates Before Commit

Minimum gates:

```text
with check src/main.w
with build
with build :fixpoint
with build :debug-alloc-tests
with build :test
```

If the repo has `:test-green`, run it too:

```text
with build :test-green
```

The debug-alloc gate is not optional. The normal floor cannot see many ownership bugs.

---

## Commit Discipline

Use small commits, each with a clear invariant.

Recommended commit sequence:

```text
1. Restore policy-clean baseline / remove bad test conversions
2. Debug-alloc provenance tags
3. Canonical MIR place/projection representation
4. Sema-typed drop glue for aggregate fields
5. Straight-line MIR drop-obligation ledger
6. Path-sensitive cleanup fix
7. Preserve Sema language rejection for user-visible field moves
8. Runtime drop flags
9. Generated async/generator state ownership transfers
10. Final debug-alloc matrix/docs
```

Do not commit:

```text
generator-state zero/clear hacks without proof
test conversions that encode unapproved semantics
unexplained debug-alloc leaks
dead helpers from rejected approaches
```

---

## Review Checklist

Before final merge, answer these explicitly:

### Ownership invariant

```text
For every drop-needing value, which place owns it after each move?
```

### Drop emission

```text
Can every emitted Drop(place) be traced to an initialized obligation?
Can every skipped field be traced to a move/uninit/Maybe(false)?
```

### Double-free audit

```text
Can any two places own the same Vec buffer/channel endpoint/task resource at the same time?
```

### Leak audit

```text
Can every resource allocation be matched to a drop/free or documented root?
```

### Language policy

```text
Are user-visible move-out-of-Drop-field tests still aligned with the chosen policy?
```

### Generated state

```text
Are generator/task state fields moved in/out through the same ownership model as locals?
```

### Conditional paths

```text
Are conditional moves either rejected or protected by runtime drop flags?
```

---

## Final Acceptance Criteria

The complete solution is done only when all of the following are true:

```text
1. User-visible move-out-of-Drop-field semantics are explicitly decided and tests match that decision.
2. MIR has canonical place ownership state, not type-global consumed-field state.
3. Drop emission drops exactly initialized owned places and skips moved/uninit places.
4. Sema-typed drop glue handles struct/tuple/array/enum/Vec nested cases.
5. Cleanup paths are path-sensitive and do not forget partial moves.
6. Conditional ownership is either rejected clearly or implemented with runtime drop flags.
7. Async/generator state uses ordinary ownership transfers, not cleanup hacks.
8. Debug allocator reports leak count=0 for all sound ownership fixtures.
9. Manual double-free still reports DOUBLE FREE.
10. Any remaining leak is either fixed, tagged as an intentional root, or tracked as a separate issue with a deterministic fixture.
11. Full build, fixpoint, debug-alloc, and test gates pass.
```

---

## One-Sentence Implementation Rule

Do not ask, “Does this type need drop?”

Ask:

```text
Which exact place owns the initialized value right now, and what drop obligation remains for it on every path?
```

Once the compiler can answer that question, the leaks, double-frees, field reassignment bugs, tuple/channel cleanup bugs, and generated-state ownership bugs become one coherent problem instead of a pile of patches.


# Appendix:  debug-allocator harness
## What it is
A native, zero-C memory-error instrument built into With's own runtime. It watches the runtime's custom slab allocator and reports double-frees, use-after-frees, and leaks at the level of individual block addresses — turning "is this a leak or a double-free, and on what buffer?" from a multi-pass guessing game into a single deterministic readout.
## Why it exists
The whole #606/#607 effort kept thrashing because drop bugs were being diagnosed by characterizing from black-box run-counts — run a repro, read an exit count, infer the mechanism, get it wrong, repeat. One leak got four contradictory characterizations before the truth settled. The harness exists to end that loop: every verdict is an address from a ledger, not an inference.
The obvious tool — AddressSanitizer — doesn't work here, and proving that was the first finding. With's runtime is a custom mmap-backed slab allocator (rt_alloc/free_small_block), not libc malloc/free. ASan interposes malloc/free and treats an anonymous mmap region as one opaque blob, so it's structurally blind to sub-block double-frees. And the hard constraint — With is 100% self-hosted, zero C in the compiler — rules out ASan annotation (its poison calls are C-runtime calls) and Valgrind (external, dead on ARM64 anyway). The only option constitutive of the no-C goal was to build the instrument natively, the way Zig's DebugAllocator does it.
## How it works
The core is a ledger — a side table backed by direct rt_mmap (so it never recurses through the allocator it's watching), keyed by payload address, recording {addr, size, freed_flag}. The allocator's rt_alloc/rt_free are hooked: alloc records an entry, free looks it up before the existing ownership check. Freeing an already-freed block → double-free abort reporting the address and size. At program exit (via with_runtime_shutdown), it walks the ledger and prints every still-live entry as a leak with its address and size, then a leak count.
## A few design decisions that came out of running it rather than reasoning:

In-process backtraces don't work — the brief assumed a frame-pointer walker (read x29, follow the chain), but running refuted it: With's codegen doesn't maintain a walkable aarch64 frame chain ([fp]/[fp+8] read 0 even in a framed function). So it pivoted: the ledger does detection in-process (which block, what verdict); lldb resolves source sites out-of-process, conditioned on the address the ledger reports. Cleaner separation, still zero-C.
Scribble-on-free is opt-in (WITH_DEBUG_ALLOC_SCRIBBLE), default off — because poisoning a freed Vec[Drop] buffer turns a subsequent double-drop's element read into a use-after-free crash before the ledger can report the double-free, masking the clean verdict. That interaction was found by running the acceptance test.

## How you turn it on
Runtime-gated by a single cached bool, with two discoverable front doors: a --debug-alloc CLI flag (shows in --help; sets WITH_DEBUG_ALLOC for the child process before exec) and the WITH_DEBUG_ALLOC env var directly (for toggling an already-built binary). Read once and cached at init — never per-allocation, which would be a hot-path regression. No compiler/comptime/build-graph plumbing, so it's fixpoint-safe; the gating code compiles in but stays dormant.
## What surrounds the core

- A .w harness driver (tools/debug_drop.w) — runs a repro or a corpus under the allocator, parses the ledger output into a verdict, drives lldb (plain command files, since lldb on the box has no Python).
- lldb command files (tools/debug_drop_sites.lldb, debug_drop_fields.lldb) — resolve alloc/free sites for a flagged address, and surface the codegen branch behind a field-drop bug.
- A commit-gate lane (:debug-alloc-tests) running a fixture corpus (test/debug_alloc/*.w) — the Vec[Drop]/array/tuple × construction/escape matrix. This is the structural fix for the deepest recurring problem: the normal test floor has zero Vec[Drop] and is blind to over/under-drop in both directions. The lane gives the corpus eyes for exactly that blind spot.
- A committed design note (docs/debug-allocator.md) recording the zero-C principle, why ASan is out, and that future sanitizer-ecosystem compatibility is permitted only by no-C means (emitting ASan's shadow-memory format via inline asm, never linking ASan's C runtime).
- AGENTS.md rules making it the default: a root cause isn't established until you can name the exact branch observed in the debugger or the debug allocator (not inferred from run-counts); the workflow default for any drop/lifetime/double-free/leak bug is --debug-alloc first, then lldb.
