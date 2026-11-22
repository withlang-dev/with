# Drop Elaboration Soundness: the reassign-after-move double-drop (#614)

Deep-dive root-cause analysis and recommendation for #614, the reassignment-after-move
double-drop. Written 2026-06-27.

## TL;DR

A `Drop` value that is **moved out** and then **reassigned** (or whose scope ends) is
**dropped a second time** by codegen. The move/ownership dataflow is *correct* and
already proves the drop should be skipped — but that analysis is **diagnostic-only**.
The actual code generator (`CodegenDispatch.with`) emits every `StmtKind.Drop`
unconditionally, never consulting the dataflow. With built the **Conditional** arm of
drop elaboration (runtime drop-flags for *maybe*-moved values) but never the **Dead**
arm (static skip for *definitely*-moved values). The fix is to make the existing,
correct dataflow authoritative for codegen — a real elaboration step, not an
observability tool — exactly as `rustc`'s `elaborate_drops` pass does.

This is a **codegen soundness bug**: the compiler *emits* a double-free. It is not a
user error. It violates `requirements.md` 1.1.1.14 ("double-free … caught at compile
time. Always") and the mission's "exactly as safe as Rust".

## 1. The bug

```with
type R { id: i32, slot: *mut i32 }
impl Drop for R:
    fn drop(move self: Self):
        unsafe: *self.slot = *self.slot + 1
fn take(r: R): ()
fn make(slot: *mut i32) -> R: R { id: 1, slot }

fn main:
    var drops = 0
    var r = make(&raw mut drops)
    take(r)                       // moves r1 into take; take drops r1   (drops=1)
    r = make(&raw mut drops)      // BUG: the OLD r1 is dropped AGAIN     (drops=2)
    take(r)                       // moves r2 into take; take drops r2   (drops=3)
    print_i32(drops)             // prints 3; correct is 2
```

Observed: **3 drops, correct is 2**. The reassignment `r = make()` drops the
already-moved `r1`. The same defect makes the §2.4 reinit-in-loop pattern
(`while …: take(r); r = make()`) over-count by one per iteration (it surfaced there
first, in #613's loop work; it is independent of loops). It is also reproducible as a
plain scope-exit double-drop when the final value is moved.

## 2. Root cause — at the instruction level

`main`'s MIR (`_2` = `r`, ty106 = `R`), from `with check --dump-mir`:

```
bb1:  _2 = move _6;                      // r = make()  (r1)
      call sym12(move _2) → take(r)      // _2 MOVED into take
bb3:  drop(_2) @ drop#10 scope-exit _2;  // ← drops the MOVED _2  → double-free
      _2 = move _11;                     // r = make()  (r2)
      call sym12(move _2) → take(r)
bb5:  StorageDead(_2); return;
```

The `drop(_2)` in `bb3` is the **drop-before-overwrite** that lowering emits for the
reassignment `r = make()` — drop the old value before storing the new one. That is
correct *only if the old value is still owned*. Here it was moved in `bb1`.

The ownership dataflow **knows this** (`with check --trace-ownership main:_2`):

```
bb1.term   event=move  before=_2=Init  after=_2=Moved   call sym12(move _2)
bb3.stmt10 event=drop  before=_2=Moved after=_2=Uninit  drop(_2) @ drop#10 ...
```

`_2` is **`Moved`** before the drop. And the drop *plan* — the elaboration the
diagnostic computes — already says **skip** (`with check --dump-drop-plan`):

```
bb3.stmt10 place=_2 ty=ty106 state_before=Moved action=skip  drop(_2) @ drop#10 ...
```

`action=skip`. The analysis is **completely correct**. Yet the value is dropped at
runtime, and `--validate-ownership` reports `ok`.

**The disconnect is codegen.** `Codegen.mir_emit_stmt` (`CodegenDispatch.with:4634`):

```
if sk == StmtKind.Drop:
    ...
    let ok = self.mir_emit_drop_place_current_origin(body, d0)   // emits unconditionally
    return ok
```

`mir_emit_drop_place_current_origin` (`CodegenDispatch.with`) emits the drop (box/refcount
special-cases, then `mir_emit_drop_ptr`) with **no consultation of the drop-state and
no drop-flag check**. Every `StmtKind.Drop` becomes a drop call.

The `Moved → skip` verdict lives **only** in the diagnostic path: `mir_drop_state_*`
(`Mir.with`) and `mir_drop_plan_action` (`Mir.with:1848`) are reached **exclusively** from
`--dump-drop-state` / `--dump-drop-plan` in `main.with`. **Codegen never computes or
queries the drop-state.** There is no `elaborate_drops` pass.

### How the *conditional* case still works (and why the static case doesn't)

The M7 conditional-move feature (if/match/loops) makes *maybe*-moved drops sound via
runtime **drop flags**: `MirLower` allocates a flag (`ensure_maybe_moved_flag_for_local`),
sets it `0` on the moving path, and structures the drop as flag-gated MIR. So the
*Conditional* (`Maybe`) arm is realized by **MIR structure emitted at lowering time**,
not by consulting the dataflow.

A **definite** move has **no flag** (static analysis already knows it is moved). So its
`StmtKind.Drop` is a plain, unguarded statement, and codegen emits it. The static
**Dead** arm — "this drop provably never runs, delete it" — was never built.

**The exact deepest cause:** there is no step that consumes `mir_drop_state` to prune
`StmtKind.Drop` statements whose place is statically `Moved`. The dataflow at
`Mir.with:1673` (`mir_drop_state_get_place`) is authoritative and correct but unused by
`CodegenDispatch.with:4634`.

## 3. Five Whys

1. **Why does the program double-drop?** `main` emits `drop(_2)` (drop-before-overwrite
   for `r = make()`) on `_2`, which was already moved into `take()`.
2. **Why is that drop emitted when `_2` is moved?** Codegen's `StmtKind.Drop` handler
   (`CodegenDispatch.with:4634` → `mir_emit_drop_place_current_origin`) emits every drop
   unconditionally; it does not consult the drop-state.
3. **Why doesn't codegen consult the drop-state?** The drop-state dataflow
   (`mir_drop_state`, `Mir.with`) is computed only for the `--dump-drop-state` /
   `--dump-drop-plan` diagnostics. No elaboration pass applies it to the MIR that
   codegen consumes.
4. **Why is the dataflow diagnostic-only?** The conditional-move feature (M7)
   implemented drop elaboration **only for the maybe-moved case**, via runtime drop
   flags and branch structure emitted by `MirLower`. The definitely-moved case
   (static skip — Rust's `DropStyle::Dead`) was never wired; the dataflow was added as
   observability for that work.
5. **Why was static skip never wired?** With lowers drops **structurally** at
   `MirLower` time (scope-exit drops + drop-before-overwrite at reassignment), *before*
   move information is available, and the move-aware elaboration step that prunes /
   keeps / flag-gates those drops — the analogue of `rustc`'s `elaborate_drops` — was
   only half-built: the `Conditional` arm exists, the `Dead` and `Static` arms do not.

**Root cause:** a missing drop-elaboration step. The correct analysis exists and is
unused; codegen treats structurally-emitted drops as final.

## 4. How Go, Rust, and Zig handle this

**Rust** (`.reference/rust`) — the model With chose — solves it with exactly the step
With is missing:

- Lowering inserts a `Drop` terminator before an overwriting assignment (the historical
  `DropAndReplace`; the `replace` flag on today's `Drop` terminator is *diagnostic only*
  per `rustc_middle/src/mir/syntax.rs` — it has "no operational meaning").
- The **`elaborate_drops`** MIR pass
  (`rustc_mir_transform/src/elaborate_drops.rs`) runs two dataflow analyses —
  **`MaybeInitializedPlaces`** and **`MaybeUninitializedPlaces`**
  (`rustc_mir_dataflow/src/impls/initialized.rs`). A move marks a place uninit
  (`drop_flag_effects.rs`); an assignment marks it init.
- For each `Drop`, `drop_style` picks (`elaborate_drops.rs:170`):
  `(maybe_init=false) → Dead` (delete the drop — **no code, no flag**),
  `(true, maybe_uninit=false) → Static` (unconditional drop),
  `(true, true) → Conditional` (runtime drop-flag).
- A drop flag is created **only** when `maybe_init ∧ maybe_uninit`
  (`collect_drop_flags`). The reassign-after-move case is `(init=true, uninit=false)`
  at the *new* value's later drop and `Dead` at the *old* value's pre-assignment drop —
  **statically elaborated, zero runtime cost, no double-drop.**

With already has the dataflow (init/uninit/moved) and the `Conditional` flag arm. It is
missing the `Dead`/`Static` static elaboration that `elaborate_drops` performs.

**Go** (`.reference/go`) — **no bug class.** Garbage-collected; no value destructors,
no move semantics, no compiler-inserted cleanup on reassignment. `defer` is
*function*-scoped (LIFO, captured at defer-time), never tied to a variable's value, so
reassignment cannot double-run anything. Cleanup of resources is manual and unrelated to
variable lifetime.

**Zig** (`.reference/zig`) — **no bug class.** No automatic destructors at all; cleanup
is manual `defer`/`errdefer`. If you `defer x.deinit()` and then reassign `x` without
deinit, the compiler neither inserts cleanup nor warns — it is a programmer error, not a
compiler-emitted double-free. Zig avoids the problem by not having compiler-managed value
lifetimes.

**Takeaway:** Go and Zig dodge the problem by *not having the feature*. With (like Rust)
*chose* automatic, deterministic `Drop`, so it must — like Rust — pair drop insertion
with **drop elaboration over an init/move dataflow.** It built the insertion and the
conditional arm; it owes the static-skip arm.

## 5. Recommendation (aligned with `docs/mission.md`)

**Make the existing drop-state dataflow authoritative for codegen by adding the missing
static-elaboration step — With's `elaborate_drops`.** Reuse the machinery already
present; add no user-facing ceremony.

Why this is the mission-aligned fix:
- **"Exactly as safe as Rust."** It is a direct port of `DropStyle::Dead`/`Static`: prune
  provably-dead drops, keep provably-live ones, leave maybe-moved ones to the existing
  flags. Closes a compiler-emitted double-free.
- **Root cause, not symptom.** It fixes the missing pass, not the one call site. The same
  defect causes scope-exit double-drops and the loop reinit over-count (#613); one
  elaboration step fixes all of them.
- **"Don't make the user write what the compiler already knows."** Entirely
  compiler-internal — no `let _ =`, no manual `mem::forget`, no reordering. The compiler
  already *computes* the right answer; this just uses it.
- **Reuses existing, verified code.** The dataflow (`mir_drop_state`, `Mir.with`) is the
  same one the diagnostic prints and that `--validate-ownership` rides on. No new
  analysis, minimal new surface.

### Implementation sketch

Add a per-body elaboration that runs after `MirLower` builds the body and before/within
codegen — mirroring `dump_drop_plan_body`'s existing per-statement walk:

1. Run the forward drop-state dataflow over the body (already implemented for the
   diagnostic).
2. For each `StmtKind.Drop` at a statement, query `mir_drop_state_get_place`:
   - **`Moved`** → **rewrite the statement to `StmtKind.Nop`** (Dead). Codegen already
     treats `Nop` as a no-op (`CodegenDispatch.with:4643`), so this needs *no codegen
     change* — the cleanest possible landing.
   - **`Init`** → leave as-is (Static; emitted unconditionally — already correct).
   - **`Maybe`** → leave as-is (Conditional; the existing drop-flag / branch structure
     already gates it). Do **not** Nop these.
3. (Same for `Drop` terminators if any carry drop semantics.)

This is the smallest sound change: it touches one new pass and zero codegen call sites,
because `Nop` is already a no-op. Place the pass so it sees the same MIR codegen does
(after conditional-move flag insertion, so `Maybe` drops are already structured).

### Verification plan

- The native debug allocator is the oracle. Add `test/debug_alloc/da_reassign_after_move.with`
  (heap-allocating `Drop`): the moved-then-reassigned value must show **no DOUBLE FREE**
  and `leak count=0`.
- Behavior: the #614 repro above must print **2**; tighten `behav_while_reinit_move.with`
  and `behav_for_reinit_move.with` to assert exact drop counts (they are currently relaxed
  *because* of this bug).
- Regression: `da_manual_double_free` must still report `DOUBLE FREE`; `da_pod_vec` must
  stay `leak count=1`; full `:debug-alloc-tests` + fresh `:test` + `:fixpoint`.
- Targeted: `--dump-drop-plan` already shows the intended verdicts; after the fix,
  `--dump-mir` should show the `bb3` drop rewritten to `Nop` for the repro, and the
  allocator should confirm the runtime matches the plan.

### Scope / risk notes

- **Don't Nop `Maybe` drops.** Those are sound only via the runtime flag; converting them
  to `Nop` would leak. The pass must skip *only* statically-`Moved` drops.
- **Partial/field moves.** A struct with some fields moved drops the live fields
  (`emit_drop_place_respecting_moved_fields`, `MirLower.with:582`). The dataflow tracks
  place granularity; the pass must use the same place-keyed state, not whole-local, so a
  partially-moved aggregate still drops its live fields. Verify with a field-move
  `da_*` fixture.
- **Fixpoint determinism.** The pass must iterate in deterministic (bb, stmt) order — no
  unordered maps — to preserve `stage2 == stage3`.
- This is the same architectural shape as the #612 branch-merge fix: a sound dataflow
  join that was computed but not *applied*. There, the use-checker ignored the join;
  here, codegen ignores the elaboration. Both are "the analysis was right, the consumer
  didn't listen."
