# Resume Later

## Session state 2026-07-02 (post-A-tail campaign; resume here)

Approved plan: `/Users/eric/.claude/plans/anything-windows-specific-waits-until-fancy-scott.md`
(tracks, ordering, designs). Progress:

- **Track 1 DONE + bootstrapped.** `[]mut T` stage 1 (`4188d5e7`): first
  collection→slice call-site coercion (imm + mut), call-local §21.1 exclusivity
  (`check_mut_slice_call_exclusivity`), `in_param_type_position` choke point,
  MIR borrow-not-materialize lowering; 13 fixtures. buf_out (`8274956e`):
  memset/explicit_bzero as `[]mut u8`; #379 commented. Callee-side slice
  writes (`buf[i] = x`) already worked.
- **Track 2 DONE + bootstrapped + #607 CLOSED.** Rejections removed
  (`5f697306`) — the niche machinery already delivered all five shapes
  (verified by probe before editing; no lowering changes). A5's
  `behav_mut_self_vec_owner_receiver` restored and green. NOTE: a 4th stale
  rejection fixture (`err_destructure_vec_drop_field`) was missed on the first
  gate run → flipped to `behav_destructure_vec_drop_field`. Process lesson
  saved to memory: confirm "GATES EXIT: 0" as its own step BEFORE commit/close.
- **Track 3a UPDATE (later 2026-07-02): increment 4 ALSO DONE (`f2b13386`).**
  `owns:`/`borrows:` c_import annotation keys (parser → appended counted
  record → Frontend readers → ci_set_owned_annotations bracket around
  translation → consulted ahead of curated tables → in the cache key).
  Increment 3 (refcount families) DEFERRED with design sketch posted to #357:
  blocked on framework linking (verified CF doesn't link); the `owns:` surface
  already covers +1 constructors; the open design is retain-over-type-family
  (shared `CRef_<family>` wrapper). 3a is otherwise complete; #357 stays open
  for refcounts + framework-linking prerequisite. NEXT: Track 3b (#348).
  Bootstrap chain for `4a77a123` + `f2b13386` still pending.
- **Track 3a increments 1+2 DONE (committed `4a77a123`, NOT yet bootstrapped).**
  Schema decision: kept the codebase's accessor-fn pattern (parallel curated
  tables) instead of the planned record schema — `ci_owned_borrow_param_ctor`
  joins `ci_owned_return_destructor`. Borrow-params shipped: readdir/rewinddir
  take `&COwned_opendir`, forward `.handle()`; safe-wrapper convention =
  holding/returning a raw pointer is safe, deref unsafe. REMAINING 3a:
  increment 3 refcount modeling — needs FAMILY-typed handles (CFRetain takes
  any CFTypeRef; per-ctor tables don't fit; consider a curated type-family
  table CFTypeRef→CFRelease with retain fns returning a second owned ref);
  increment 4 `@[owned]`/`consumes` annotation evidence surface (greenfield).
- **Track 3b DONE — #348 CLOSED (`53f48264`).** Pure-With expander
  (`ci_expand_macros_in_text`) replaced the cc -E dump; every consumer already
  held its raw text. Exec machinery deleted (with_cimport_preprocess_text,
  capture_command_stdout, append_cc_common_args, line-marker parsers, weak
  stub). Goldens byte-identical pre/post (test/migrate/issue348_*.c). No
  shell-out remains in c_import/migrate. Bootstrap pending for this commit.
  (Superseded route note below:)
- **(superseded) Track 3b ROUTE RULED (#348).** Plan's premise
  was WRONG: clang_bridge.o is compiled from ClangBridge.with — the bridge is
  pure With over libclang's C API; no C++ shim exists, and clang's
  Preprocessor/-E is C++-only (not in the C API). Ruled route (c') on the
  issue: a narrow With-side expander over the already-de-shelled
  DetailedPreprocessingRecord covering the ACTUAL consumer inventory
  (string-literal macro sequences + initializer text; consumers are
  MIGRATE-ONLY — g_migrate_preprocessed_source set in ci_migrate_file);
  function-like/## shapes fail loudly as untranslatable. Golden shapes
  verified working today via `with migrate` (BANNER "== " NAME " ==" →
  merged literal; k_tag initializer recovery). Order: golden .c fixtures in
  test/migrate → expander → delete capture_command_stdout + cc -E, no
  fallback. Note: test/migrate has no in-repo runner — check how goldens
  gate before relying on them.
- Run the bootstrap chain for `4a77a123`+ before or with the next increment.
- Host rule: `WITH_MEMORY_LIMIT_BYTES=0` on every :test/:test-green/:last-green
  step; bootstrap as ONE chain, no commits mid-chain.

---

# (Historical) Drop/Move Ownership — current state under the niche

Resume record for the `docs/completed/drop-move-ownership.md` effort. **Updated
2026-06-30 to the niche design.** The drop/move substrate is no longer built on runtime
drop flags + static drop elaboration; it is built on the **niche** (reset-on-move
+ the guarded drop), which shipped as Stages 1–6 and is now merged to `main` and
installed. This file records what that means for the remaining slices.

## The design now (read these first)

- Canonical: **spec §2.5** (Generational Ownership), **impl-notes §2.6**
  (implementation), and the niche memory `project-generational-ownership-niche`.
- **Owner safety is a runtime fact, not a static proof.** A move blanks its
  source (owning pointer → null, container → empty); a drop checks the reset
  sentinel (`rt_value_is_zero`) and skips a blanked value. Double-free is
  impossible by construction.
- **Sema move-checking is the diagnostic/optimizer layer, not the safety
  mechanism.** The branch-merge union-join (#612), the loop back-edge dataflow
  (#613), and the never-moved guard-elision optimizer (Stage 4,
  `MirBody.ever_moved_locals`) all live here. A bug in any of them can over-reject
  or cost a redundant store — never leak or double-free.
- **The M7 runtime drop-flag scheme and the static dead-drop elaboration are
  RETIRED** (spec §2.5.2 forbids reintroducing them). Conditional moves
  (if/match/loop) route entirely through the niche. Do not rebuild
  `ensure_maybe_moved_flag_for_local`, `--dump-drop-flags`, etc. — they are gone.

## Done (closed)

- **#612 / #579** branch-merge move-state soundness — union-join for `if`/`match`.
  Analysis + fix record: `docs/completed/branch-merge-soundness.md`.
- **#613** loop maybe-init dataflow — sound for `while`/do-while/`loop`/`for`
  (back-edge UAM, continue-carried move, break accumulator).
- **#614** reassign-after-move double-drop — fixed by reset-on-move (the niche),
  not by the static-elaboration pass the old analysis recommended. Record:
  `docs/completed/drop-elaboration-soundness.md`. `da_reassign_after_move` is green
  and the loop reinit fixtures now assert exact drop counts.
- **#609** fiber pool reported as a leak at shutdown — drained before the ledger
  walk.
- **M7 conditional whole-value moves** (if/match/loop) — sound via the niche.
- **Slice E — conditional *field* moves** — closed by the **field-place niche**.
  A Drop-bearing field moved conditionally out of a non-Drop struct is blanked on
  the moving path (`MirLower.consume_moved_operand` records the field place in
  `pending_reset_field_places` when `field_move_in_branch > 0`; flushed scoped per
  branch in `flush_pending_resets_since`), and the owner's existing guarded
  per-field drop (`rt_value_is_zero`) skips the blanked field — with the base local
  marked `ever_moved` so the Stage-4 elision keeps the owner's guard (else the
  blanked field's drop null-derefs). The reset is scoped to CONDITIONAL moves (the
  `field_move_in_branch` counter, inc'd around if/match/while/loop bodies); an
  unconditional field move stays statically moved and the owner's partial drop
  skips it without a reset (preserved drop-plan, no dead store). The
  `SemaCheck.with:18691` rejection is lifted. Fixtures:
  `behav_conditional_field_move_drop` (if + match), `da_conditional_field_move`.
  Field move-OUT of a `Drop` aggregate stays forbidden (§2.4;
  `err_move_out_vec_field_*` + `SemaCheck.with:18685/18688/18741`).
- **Slice F — M8 generator/async-state ownership audit** — done; the async path is
  sound. With's async is fiber-based, so a `Drop` value live across a suspend
  (await) stays on the fiber stack (no copy/zero of "generator state") and the
  niche drops it normally — on normal completion, on move-after-await, and on
  cancellation (the loser of a `select await` unwinds and drops its live locals).
  Verified for a `Drop` struct and a `Vec[Drop]` across a suspend. Fixtures:
  `da_async_drop_across_await`, `behav_async_drop_across_await`,
  `da_async_cancel_drops_live`. (No copy/zero hazard — the `gen_zero_operand` the
  plan worried about is the aggregate-init/reset helper, not used in async lowering.)
- **Field-read drop suppression** — fixed. `cancel_scheduled_value_drop_for_receiver_expr`
  (`MirLower.with`) marked *any* field-access RHS of a `let` moved (the #606 self-aliasing
  case), including a plain **Copy** field read (`let _ = r.ptr`). Marking a Copy field of
  a `Drop` struct moved degraded the owner's whole-value `Drop` into a partial drop that
  emits nothing (its fields are not individually needs-drop) → the user `Drop` was
  bypassed → leak. Fix: skip the mark when the field type is `Copy` (a Copy read carries
  no owned buffer; only the non-Copy aliasing read does). Root-caused at the instruction
  level (`--dump-mir` showed `StorageDead(_2)` with no `drop(_2)` after `_4 = copy _2.f8`).
  Fixtures: `da_field_read_keeps_drop`, `behav_field_read_keeps_drop`; #606 aliasing
  (`behav_mut_self_field_assign_vec_tail`) still passes.

## Genuinely remaining

1. **Deeper partial-move precision (A6/A7/A8 — separate future phases, not the niche
   core).** Nested aggregate-in-struct-field drop (A6), wildcard/discard element drop in
   irrefutable destructure (A7), and precise per-element partial-extraction tracking to
   replace the conservative whole-base consume (A8). See `docs/completed/phase_8_handoff.md` and
   `docs/completed/a5_handoff.md`. (One A5 coverage gap noted while archiving: the
   `behav_mut_self_vec_owner_receiver.with` test from the handoff's restore list was never
   restored; the other two A5 fixtures exist and pass.) The niche plus conditional
   whole-value and field moves (Slices
   A–F) and the field-read drop fix are complete; A6/A7/A8 are precision refinements
   (the current whole-base consume is conservative/safe), not soundness gaps.

## Session state 2026-07-01 evening (A6/A7/A8 probes; resume here)

- **A5 restore-list gap: RESOLVED, no restore.** `behav_mut_self_vec_owner_receiver.with`
  cannot come back as a behavior test — its shape (move-self returning a `Vec[W]`
  field) is deliberately rejected (#607 boundary, `SemaCheck.with` reject sites) and is
  pinned by `err_move_out_vec_field_moveself.with`, which documents it flips back to a
  behavior test (count 1) when #607 lands.
- **A6 VERIFIED + FIXTURES LANDED (uncommitted).** All six shapes re-run heap-backed
  under `--debug-alloc`: exact counts, leak 0. New fixtures for the uncovered shapes:
  `da_drop_struct_tuple_field`, `da_drop_struct_option_field`,
  `da_drop_nested_struct_tuple_field`, `behav_drop_struct_field_aggregates`, plus
  README update. (Array/Vec/nested-Vec shapes were already pinned by existing da_.)
- **A7 IS A REAL LEAK FAMILY — FIX IMPLEMENTED (uncommitted, build verifying).**
  Every pattern-position discard orphans Drop values: `let (a,_)`, nested `_`,
  `let {x, y: _}`, `let {x, ..}` , match arm `(a,_)`, and whole-subject `_` arm
  (leaks the ENTIRE subject: `match make(): _ => ()` → 2 leaks). Root cause: the
  consuming contexts (let-destructure/if-let/match, `MirLower.with` consume sites)
  cancel the subject's drop while `lower_pattern` binds only NAMED elements; the
  match consume comment documented the leak as a known follow-up. `let _ = expr`
  (statement discard) and param patterns (`fn f({x, y: _}: P)`) were already sound.
  FIX in `MirLower.with lower_pattern`: NK_PAT_WILDCARD moves a needs-value-drop
  scrutinee into an anonymous drop-scheduled local (mirrors NK_PAT_IDENT; borrowed
  subjects arrive ref-typed → untouched); NK_PAT_STRUCT `..` rest iterates
  unmentioned fields via type reflection and does the same (by-value subjects only,
  `pattern_subject_ref_mutability(scrutinee) < 0`). New fixtures (uncommitted):
  `da_drop_wildcard_destructure`, `da_drop_match_wildcard_arm`,
  `da_drop_struct_pat_rest`, `behav_drop_pattern_discard`.
- **A-TAIL COMPLETE — ALL COMMITTED.** A6 fixtures `036bb50a`; A7 fix+fixtures
  `0e22d06f`; A8 fix+fixtures `ca713079`. All gates green per cycle (fixpoint,
  debug-alloc lane, 742+ behavior, all targets). Host note: `with build :test`
  needs `WITH_MEMORY_LIMIT_BYTES=0` here — the limit trips AFTER "EMIT-C SMOKE
  OK" in :test's final phase (known; feedback_bootstrap_sequence memory).
  A8 final shape: NK_INDEX extraction materializes into a temp + blanks the
  slot IMMEDIATELY (deferred pending-reset double-freed tail-position
  extraction — consumed after scope drops); array keeps its guarded drop
  (ever_moved). Codegen: zero-const struct store memset extended to PROJECTED
  destinations (aggregate zeroinitializer left PADDING bytes unwritten →
  rt_value_is_zero saw nonzero → drop on blanked value → null deref; lldb
  verified 0xff padding). ALL FOLLOW-UPS CLOSED 2026-07-02: (a) enum-payload
  discard probe found `.A(a, ..)` payload-rest LEAKED (NK_PAT_REST bare
  `continue` in the variant binding path) — fixed + pinned in `60cc437f`
  (`da_drop_enum_payload_discard`: `.A(a, _)`, `.A(a, ..)`, whole-`_` arm);
  (b) #605 and #606 CLOSED on GitHub with the full record; (c) bootstrap done —
  seed `src/main` + `~/.local/bin/with` (2026-07-02 01:04) carry A7/A8,
  installed compiler smoke-tested green on the new fixtures. Host note: the
  memory cap trips in `:test-green`/`:last-green` too — prefix EVERY bootstrap
  step with `WITH_MEMORY_LIMIT_BYTES=0`, one chain, no commits mid-chain.
  Untested edge noted: positional-struct-pattern rest (`P(x, ..)`) shares the
  old NK_PAT_REST skip in its own path — probe when nearby.
- **A8 SPLIT VERDICT.** Tuple partial extraction ALREADY per-element precise
  (`let a = t.0` → t.1 still drops; existing machinery: static field move + partial
  base drop). ARRAY index extraction LEAKS siblings (`let a = arr[0]` → arr[1]
  leaked): root cause is the documented whole-base consume in the NK_INDEX branch
  of `MirLower.with lower_expr` (search "#606: moving a non-Copy element out of an
  ARRAY"), which cancels the array's drop and returns OK_COPY. NEXT CYCLE fix
  (designed, not yet applied): return OK_MOVE, push the index place onto
  `pending_reset_field_places`/`_types` (unconditional slot blank at stmt boundary;
  flush handles arbitrary places), `mark_local_ever_moved(base)` so the array's
  kept drop stays guarded (`mir_emit_drop_array_ptr` → per-element
  `mir_emit_guarded_user_drop` skips blanked slots), and DELETE the
  cancel/mark-moved lines. Note `place_field_projection_count` returns -1 for index
  projections so `consume_moved_operand` won't record bogus static marks. Probe
  tail-position extraction (`return arr[0]`) for reset-before-scope-exit-drop
  ordering. Existing pinned fixtures (extract-both, count 2) must stay green.
- **Verification per cycle:** check src/main.with → build → :fixpoint →
  :debug-alloc-tests → fresh :test → :test-green. Commit A6 fixtures and A7
  fix+fixtures as separate commits after gates; A8 is its own cycle after.
- Probes live in the session scratchpad (a6/, a7/, a8/) — regenerate trivially.

## Session state 2026-07-01 (saved before a host reboot; resume here)

- **#617 — DONE end-to-end.** Three thread races in the comptime `parallel()`
  compile path fixed (`e8a01e48` rt sanity-check-under-lock, `da6176fb` Mir
  cache spinlock + atomic `out/tmp/with_runtime` extraction via temp+rename +
  temp-archive registry lock). Verified 0/45 repro runs (was ~50%), full gates
  green, merged + pushed to `main`, **bootstrap completed**: seed `src/main` and
  `~/.local/bin/with` (both 2026-07-01 ~20:20) carry the fixes; installed
  compiler smoke-tested 3/3 clean on the 8-workspace `parallel()` stress repro.
  #617 stays open only for the never-reproduced `with get` zlib symptom.
  Full record: the 2026-07 comments on GitHub #617.
- **#604 — RULED 2026-07-02: Option A staged** (ruling posted to the issue;
  Eric delegated the call via the spec-as-compass). Implement parameter-position
  `[]mut T` first (coercion from mutable places, `d1=1` slice creation,
  call-local §21.1 exclusivity, unchanged fat-pointer ABI), which unblocks
  #379 `buf_out`; local-binding and return-position follow as separate
  increments. `VecRange` stays internal. Original brief context below:
  Recommendation: **Option A staged** — realize `[]mut T` per spec §4.8,
  parameter-position first (coercion + `d1=1` slice creation from mutable
  places + call-local §21.1 exclusivity; codegen unchanged — same fat-pointer
  ABI). Spec review confirmed: §2.5's Vale-style "validity is a runtime fact"
  covers owners (reset-on-move) and handles (per-slot generation) but
  deliberately NOT borrows — the borrow row is ephemerality + §21.1 Rule 1
  (view-liveness), which is existing, load-bearing machinery this extends.
  `VecRange` was verified to snapshot `(data,offset,len)` — same hazard class
  as a slice, no runtime validation — so blessing it (Option B) buys nothing.
  On ruling: post the brief + ruling to #604, then implement staged.
- **A6 — probe matrix run (2026-07-01): nested aggregate-in-struct-field drop
  ALREADY WORKS.** Six probes (Drop type `W{id,slot}` adding `id` to a counter
  in `fn drop`; struct dropped at scope exit): plain field → 1 ✓, tuple field
  `(W,W)` → 3 ✓, array field `[W;2]` → 3 ✓, `Option[W]` field (Some) → 1 ✓,
  `Vec[W]` field (2 elems) → 3 ✓, two-level `Outer{Inner{(W,W)}}` → 3 ✓.
  Exact counts = no leak AND no double-free. So A6 is **verification + fixtures,
  not implementation**: (a) re-run the matrix heap-backed under `--debug-alloc`
  (leak-count oracle), (b) land the matrix as `behav_`/`da_` fixtures (+ restore
  the missing `behav_mut_self_vec_owner_receiver.with` from the A5 list), (c) probe
  A7 (wildcard/discard destructure) and A8 (partial extraction then drop) the
  same way — the whole A-tail may already be delivered by the niche, reducing
  #605/#606 to fixtures + close/retarget.
- **Campaign status (docs/implementation_plan.md):** Phases 0–7, 10, 11 fully
  closed. Remaining: Phase 8 = #348 (partial), #357 (partial), #604 (ruling),
  #605/#606 (the A-tail above); Phase 9 = #369 (Windows); Phase 13 = 56
  coverage-sweep test issues; ~44 open issues sit outside the plan → Phase 12
  triage. Agreed order: A6→A7→A8, then #357/#348, then triage + sweep.

## Verification protocol (every change)

`./out/release/bin/with check src/main.with` → `with build` → `with build :fixpoint`
→ `with build :debug-alloc-tests` (the soundness oracle) →
`rm -rf out/test-graph && with build :test` (fresh) → `with build :test-green`.
For conditional moves the `da_*conditional_move*` fixtures must show `leak count=0`
and never `DOUBLE FREE`.

## Key files (current)

- `src/Sema.with` / `src/SemaCheck.with` — move-checking diagnostic: `check_if_expr`,
  `check_match_expr`, the loop dataflow (`finalize_loop_move_state`,
  `check_loop_continue_carried_move`, `capture_loop_break_move_state`), the
  field-move rejections (`:18685`–`:18741`).
- `src/MirLower.with` — the niche: reset-on-move recorded at the single
  `pending_reset_locals.push` site (also marks `ever_moved_locals` for the Stage-4
  elision); the guarded drop in `emit_drop_entry`.
- `src/Mir.with` — `MirBody.ever_moved_locals` (the elision set).
- `rt/rt_core.with` — `rt_value_is_zero` (the reset-sentinel check); per-slot
  `with_slotmap_*` generation for §6 handles.
- Tests: `test/behavior/behav_{conditional,match_conditional}_move_drop_value.with`,
  `test/debug_alloc/da_{drop,match}_conditional_move_value.with`,
  `test/compile_errors/err_loop_conditional_move_drop_value.with`,
  `test/compile_errors/err_move_out_vec_field_*.with`.

## Open issues

- #617 — the parallel-workspace corruption is root-caused and fixed (three
  thread races in the comptime `parallel()` compile path; commits `e8a01e48` +
  `da6176fb`). The issue stays open only for the original, never-reproduced
  `with get` zlib symptom.
- #607/#605/#606 — the transitive-Drop move/drop substrate this effort continued;
  Vec drop and aggregate content drop now ride the niche.
