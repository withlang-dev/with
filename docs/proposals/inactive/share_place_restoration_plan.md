# Share-Place Restoration — Historical Plan (Superseded)

> **SUPERSEDED (2026-07-23). Do not execute this plan.** Specification §3.8
> states the current rule: `&T` borrows and plain `T` consumes. The historical
> implementation details below are retained only to explain existing code and
> commits; they are not a backlog. Every “canonical,” “directive,” phase, and
> imperative below is void. For D22, `docs/d22-Eric-Ruling.md` is canonical and
> every conflict here is false.

The historical target was to restore `docs/completed/mutability.md`, which was
then treated as canonical under D5. The plan regarded effect summaries as
complete and move+callee-drop as drift. Its 2026-07-05 removal directive is
recorded here only as superseded provenance and must not be executed.

## Historical target semantics — superseded

- Non-`Copy` `f(x)` default = **ephemeral shared-place alias**: callee gets a
  pointer to the caller's place, mutations are caller-visible, caller keeps
  ownership, destructor runs in the caller's scope. Callee does NOT drop it.
- `move x` = ownership transfer (callee owns + drops; caller binding invalid).
- `copy x` = independent owned value (Copy bitwise / Clone user clone).
- Call-site rule keyed on the callee's inferred effect on that param:
  - `read`/`write` → default share-place OK (read→shared borrow, write→exclusive).
  - `consume`/`escape_value` → require `move`/`copy` (plain `f(x)` is an error).
  - `escape_view` → view-origin tracking (already implemented).
- `Copy` types pass by value (unchanged). Receiver modes already aligned (Cycle 1).

## The exact sites (from the recon map)

Effect infra (Sema.w:296 constants, `sig_param_effects`, `note_*` inference,
`@[effect]` pins, view-origin) — **complete, no change.** `is_copy` (Sema.w:5207,
aggregate-Copy opt-in) — **no change.** `&T` niche — **no change.**

CHANGE (coordinated — Sema+MIR+codegen must flip together or it miscompiles):

1. **Callee drop (the pivot).** MirLower.w:11961 (`lower_fn_with_sig`) and the
   identical clause path 12068: REPLACE the unconditional non-Copy `DK_VALUE`
   drop with: drop only when `sig_param_effect(sig, pi) & (EFF_CONSUME |
   EFF_ESCAPE_VALUE)` — i.e. owned params only. Generalize the existing
   `borrowed_receiver` carve-out to "any share-place param."
2. **Call-site consume (Sema).** SemaCheck.w:12465-12483: REMOVE the
   unconditional `arg_consumed_by_value` for non-Copy and its "a plain T
   parameter consumes" comment. Invalidate the caller binding only when
   `param_eff & (EFF_CONSUME | EFF_ESCAPE_VALUE)` or the arg is
   `NK_MOVE_ARG`/`NK_COPY_ARG`. For plain non-Copy to a consume/escape_value
   param → error "requires `move`/`copy`".
3. **Call-site passing mode (MIR).** `lower_var` MirLower.w:2973 and
   `lower_call_arg` 7824: a default non-Copy value arg → share-place alias
   (address of caller's place), SKIP `consume_moved_operand`. Keep `OK_MOVE` for
   `move x`, clone for `copy x`. Plain `x` and `move x` now diverge (were both
   `OK_MOVE`).
4. **Codegen ABI.** Generalize the value-ref pointer ABI
   (`sig_value_ref_abi_params` / `fn_param_uses_value_ref_abi`, SemaDecl.w:1081)
   from "owner-type method params only" to "any non-Copy value param passed
   share-place," so the callee receives a pointer to the caller's place. Template:
   the receiver plumbing (Codegen.w:3849, 4094 `record_ref_param`). Verify the
   generic monomorphization ABI (CodegenDispatch.w:12882, 16225).
5. **Effect-driven borrow at call sites.** SemaCheck.w:~12459 arg loop: take a
   borrow keyed on `param_eff` (read→SHARED, write→EXCLUSIVE +
   `check_mutation_against_views`), mirroring `note_auto_ref_call_arg`.
6. **REMOVE the inverted vestige lints.** `should_warn_by_value_read_only_param`
   and `emit_by_value_param_returned_view_error` (SemaCheck.w:1076-1139) — their
   text ("by-value here, so the callee owns it"; "consider `&T` so callers keep
   their binding") is the precise inversion of the doc. Delete them; under
   share-place, a by-value read-only param is the correct default, not a lint.

## CRITICAL FINDING — effect inference must be a pre-pass (fixpoint), or share-place double-frees

The call site decides share-place-vs-move from the **callee's inferred effect**,
read from the persistent sig via `sig_param_effect(sig_idx, pi)` (SemaCheck.w
~12459, `propagate_*_param_effect` 7998/8007). But `sig_param_effects` is
populated *per function body* as it is checked (flush at SemaCheck.w:1461), with
**no pre-pass and no callee-first ordering**. Bodies are checked roughly in decl
order.

Under the current MOVE model this is harmless: the call site moves every non-Copy
arg **unconditionally** (SemaCheck.w:12470-12476), independent of the callee's
effect. The effect is only consumed for `escape_view` + transitive propagation.

Under SHARE-PLACE it is a **correctness landmine**. If caller A is checked before
callee B (forward reference, mutual recursion, or just decl order), B's
`sig_param_effect` is still 0 when A's call is checked → A treats B's owning
(`consume`/`escape_value`) param as share-place → A keeps ownership AND B drops
→ **double-free**. This would corrupt the self-host chain silently.

**Therefore the restoration MUST add a whole-program effect-inference pre-pass
that completes before any call-site share-place/borrow decision** — infer every
function's `sig_param_effects` first (a fixpoint over the call graph, because a
param's effect can depend transitively on callees' effects, and mutual recursion
needs iteration to converge; seed unknowns as the weakest effect and iterate to a
greatest fixpoint / until stable). Only then check call sites and lowering, which
now read stable, complete effect summaries. The value_ref_abi flag (below) is
also derived from the final effect, so it too must be set post-fixpoint.

This is foundational and must land **before** the coordinated flip (P1). It is
the reason the effort is release-sized rather than a few edits: the effect *brain*
exists, but it is currently a single-pass side effect of checking, not a
committed pre-pass the convention can depend on.

## Phases / sequencing

- **P0 — effect-inference pre-pass (the foundation; see CRITICAL FINDING).**
  Make every function's `sig_param_effects` complete and stable *before* any
  call-site share-place/borrow/ABI decision. Two candidate implementations:
  (a) run the existing body-check effect-inference over all fns to a fixpoint
  with call-site *decisions* suppressed, then a final decision pass; (b) a
  dedicated lightweight effect-only walk iterated to a fixpoint. Land P0 while
  the convention is still move (P0 changes nothing observable — it only makes
  effects reliably available), gate + fixpoint, so P1 builds on stable ground.
  Derive `value_ref_abi` from the final effect here too.
- **P1** — sites 1-4 + 6 coordinated (the core + vestige removal). Build stage1
  with the old (move) seed → stage1 is share-place. Verify the doc's `append_byte`
  / `store` / `rename` examples on a scratch program.
- **P2 — self-host migration.** Run `stage1 check src/main.w`: share-place stage1
  flags every compiler-source site that relied on implicit consume/escape as
  "requires move/copy." Add explicit `move`/`copy` (compatible with BOTH the old
  seed and share-place — only NAMED non-Copy bindings passed to consume/
  escape_value params; rvalue/temp args need nothing). Iterate until clean.
- **P3** — site 5 (effect-driven borrow) + retire/rewrite drift comments.
- **P4** — `with build` → `:fixpoint` (stage2==stage3 under share-place) →
  `:test` → author doc-example fixtures (share-place write, escape needs move,
  read keeps binding, borrow conflict) → full gate → bootstrap seed.

## P1 codegen findings (traced; ready to execute)

The callee side is a one-flag change; the caller side is the real work.

- **Callee (easy).** `value_ref_abi` on a param makes `declare_function_from_sig`
  emit a plain `ptr` (NOT byval) + `record_ref_param` (Codegen.w:4094-4098), so
  the callee body operates on the *pointed-to caller place* = share-place. A
  non-value_ref_abi non-Copy struct instead goes byval-indirect
  (`internal_abi_needs_indirect_param`, Codegen.w:4115) = callee gets a COPY.
  So: **setting value_ref_abi for a share-place param flips the callee to
  share-place.** Drive it from the final effect, in a pass right after
  `fixpoint_effect_flow`: for each sig param that is non-Copy, by-value (not
  ref/ptr/slice), and whose effect excludes CONSUME|ESCAPE_VALUE, call
  `set_sig_param_value_ref_abi(sig, pi, 1)`.
- **Callee drop.** MirLower.w:11961 + clause path 12068: generalize the
  `borrowed_receiver` exemption — skip `schedule_drop(DK_VALUE)` for any param
  whose effect is share-place (equivalently, whose value_ref_abi is set). Only
  CONSUME|ESCAPE_VALUE params (and move/copy args) are owned + dropped.
- **Caller (the work).** The caller passes an address for a ref param via
  `is_ref_param(fn_sym, pi)` + `mir_try_place_ptr_for_ref` /
  `get_mutable_receiver_ptr`, but this is done **per-call-path for the receiver
  (param 0)** — e.g. CodegenDispatch.w:5887 (multi-index), 12797/12899 (generic),
  13392 — NOT in one general marshalling loop. To generalize: every call path
  that pushes arguments must, for each arg `pi`, check `is_ref_param(fn_sym, pi)`
  and push `mir_operand_place_addr`/`mir_try_place_ptr_for_ref` (address of the
  caller's place) instead of the value. For an rvalue/temp argument to a
  share-place param, materialize a temp, pass its address, and drop the temp in
  the caller scope after the call. Enumerate the call-lowering paths first
  (`build_call_fn_value` and every builder of `call_args`) — this is the bulk of
  P1 and the highest miscompile risk; verify byval and sret interactions.
- **Call-site consume (Sema).** SemaCheck.w:12470-12483: stop the unconditional
  `arg_consumed_by_value` for non-Copy; mark-moved only for explicit
  NK_MOVE_ARG/NK_COPY_ARG. Add a POST-fixpoint validation pass over recorded call
  sites emitting "requires move/copy" for a plain non-Copy binding passed to a
  CONSUME|ESCAPE_VALUE param (needs call sites recorded like the effect edges).
- **Vestige lints.** Remove `emit_by_value_param_returned_view_error` (1459-1460)
  and `should_warn_by_value_read_only_param` (1469-1471) as part of the flip.
- **Generic mono.** CodegenDispatch.w:12882, 16225 recompute value_ref_abi
  structurally (`fn_param_uses_value_ref_abi`) — make them honor the effect-driven
  flag too (read the sig flag, or extend the structural check to share-place).

Estimated: P1 is the large unit; P2 (self-host migration) blast radius is unknown
until share-place stage1 runs `check src/main.w`. Both need fresh context; the P0
foundation they build on is committed and green.

## THE CATHEDRAL — centralize argument marshalling before the flip (Eric's directive)

Recon of all 30 `build_call_fn_value` callers + the bypass path confirms the
bazaar is really **three separate arg-building loops sharing one predicate
family** (`is_ref_param`/`value_ref_abi` + the address helpers), plus 18
runtime/intrinsic value-only sites that have no MIR operand and stay out of
scope. Build the cathedral as a **behavior-neutral** refactor first; then the
share-place flip is a one-line `value_ref_abi` extension in one place.

### The seam: one per-arg helper `push_call_arg`

`Codegen.build_call_fn_value` (Codegen.w:1759) is the common tail and already
owns sret prepend, byval indirection (via `coerce_call_args_for_fn_value`
1715-1757), dyn-trait wrapping, coercion, ABI attrs. Callers own exactly one
thing: **value-vs-address per parameter.** Centralize THAT:

`push_call_arg(args, callee_fn_sym, callee_sig, param_index, body, operand, node)`
— keyed on `is_ref_param(callee, param_index)` for **every** index (matching the
concrete path R7, the most complete existing logic), it must reproduce:
- **ref-param → address:** transparent box/rc/arc (`mir_sema_type_is_box` /
  `mir_sema_type_refcount_kind`) → `mir_operand_place_addr` (T**); else if the
  operand value is **already a pointer**, pass as-is (the #568 short-circuit — a
  `&T` value is already `T*`; taking its place-addr would hand `T**`); else
  `mir_try_place_ptr_for_ref`; else `get_mutable_receiver_ptr` / alloca+store
  (rvalue-temp materialization).
- **value param → value:** `mir_eval_operand`, or `mir_eval_call_operand_info`
  when a cstr/rvalue-temp + `cleanup_ptr` is needed (thread `cleanup_ptr` back).
- Feeds the tail with a VALUE for byval params (the tail does byval indirection);
  pushes the pointer for ref/value_ref_abi params (tail leaves ptr direct).

### The three loops to route through it (behavior-neutral)

1. **Group B receiver blocks** (6): CodegenDispatch.w 5904, 13399, 13435, 13607;
   Codegen.w 5147, 5374 (5147/5374 use a precomputed `obj_ptr` → a value-level
   variant). Today these special-case index 0 only and push args 1..n as values;
   routing every index through `push_call_arg` matches R7 and is neutral because
   `is_ref_param` at index>0 is true only for `&T`/same-owner params whose value
   is already a pointer (the short-circuit yields the same value push).
2. **Concrete/direct path** (CodegenDispatch.w 13913-14245, bypasses the tail):
   the 14101-14131 per-param `needs_ref` sub-block maps 1:1 to `push_call_arg`.
   Leave its byval (14062-14076), direct-aggregate (14080), dyn-trait
   (14132-14152), ctx_ptr (14042), sret (14046) branches in place.
3. **Generic-call eval loop** (CodegenDispatch.w 12884-12909): the receiver
   value-vs-address decision one level above `monomorphize_generic_call_core`
   (which just forwards pre-built `arg_vals`). Route through `push_call_arg`.

### Migration subtleties (found while routing Group B — de-risk before swapping)

Brick 1 (extract `mir_ref_arg_ptr` + concrete path) landed neutral. The remaining
loops are NOT mechanical swaps; each hazard below breaks fixpoint or miscompiles
if ignored:

- **Double-evaluation.** Group B sites (multi-index 5904, direct 13449, 13399)
  pre-compute `recv_val = mir_eval_operand(recv_op)` for the non-ref branch, then
  branch. `mir_ref_arg_ptr(body, operand)` evaluates the operand AGAIN internally
  → a redundant load (fixpoint break) or a double side effect (miscompile). Fix:
  add a value-taking variant `mir_ref_arg_ptr_val(body, operand, val, val_ty)`
  that skips the internal eval, and have pre-computing sites call that; the
  concrete path (no pre-eval) keeps calling `mir_ref_arg_ptr`.
- **Fallback helper.** Group B's rvalue fallback is `get_mutable_receiver_ptr`
  (node, val, ty); the helper's is `alloca+store`. Equivalent ONLY for the
  rvalue case the fallback reaches (a place → `mir_try_place_ptr_for_ref` != 0 →
  fallback not reached; `get_mutable_receiver_ptr`'s NK_IDENT branch is a place
  and never reached here). Verify by gate per site; if a divergence appears,
  route the fallback through `get_mutable_receiver_ptr` in the value-variant.
- **Transparent single-pointer receivers (Box/Rc/Arc).** The generic path (R4,
  12797/12899) uses `mir_operand_place_addr` (T**) for transparent receivers; the
  concrete path / `mir_ref_arg_ptr` treats the box value as already-a-pointer →
  T*. These differ. Determine per site whether transparent receivers actually
  reach it (Box methods likely route through the generic path, not Group B direct
  sites) before unifying; do NOT add transparent handling to `mir_ref_arg_ptr`
  blindly — it would change the concrete path (which works today without it).
  - **FOUND (investigated):** transparent handling lives ONLY in the generic path
    (12819-12925: `T**` via `mir_operand_place_addr`); the concrete path
    (13913-14160) has NO transparent guard and treats a transparent box value as
    already-a-pointer → `T*` via the short-circuit. BOTH currently work + fixpoint.
    So generic and concrete use different, each-correct address forms for a
    transparent receiver — they CANNOT share one `mir_ref_arg_ptr` for that case
    until we resolve WHY the callee ABI differs (does generic-mono vs concrete-mono
    disagree on the transparent receiver's ptr ABI, or do the two paths handle
    disjoint receiver shapes?). The cathedral unifies cleanly for non-transparent
    (struct) receivers — the bulk; the transparent case needs its own resolution
    and must NOT be forced through the shared helper until then. Concrete unblock
    step: determine whether a transparent-receiver method call ever reaches the
    concrete needs_ref block at all (if generic-mono always claims it, the concrete
    short-circuit is dead and the paths are disjoint → safe to unify the rest).

Net: migrate one site → gate (build+fixpoint+suite) → commit, never batch, so a
fixpoint break isolates to one swap.

### Out of scope (leave alone)
- Group A (18 runtime/intrinsic sites, Codegen.w 1989-3214 area): no MIR operand;
  LLVM constants. Not addressable by an operand-keyed helper.
- Structural injections: ctx_ptr (closure env), sret buffer, fmt-spec constants,
  multi-index specs-ref/count, str_concat parts/count — pushed directly, never
  through `push_call_arg`.

### Order of work (each step gated behavior-neutral)
P0.5a define `push_call_arg` (operand-level) + a value-level variant → P0.5b
migrate one Group B site + gate (proof) → P0.5c migrate remaining Group B → P0.5d
concrete-path sub-block → P0.5e generic loop → gate + fixpoint after each. Then
P1's flip = derive `value_ref_abi` from effect post-fixpoint (one place) + callee
no-drop + call-site no-consume + delete residue — and the cathedral marshals the
addresses automatically.

## THE FLIP — requires a two-pass call-site decision (the architectural crux)

The cathedral is done (both sides read `arg_pass_mode`/`marshal_ref_addr`; the
transparent divergence is retired). The flip itself is 4 coordinated parts:

1. Post-P0-fixpoint, set `value_ref_abi` (IndirectPlace) for a param that is
   non-Copy, by-value, and whose complete effect excludes CONSUME|ESCAPE_VALUE
   (read/write/escape_view → share-place). `declare_function` (via
   `arg_pass_mode`) then makes it a `ptr` and `record_ref_param` marks it, so the
   cathedral marshals its address automatically. Note: generic mono recomputes
   ABI structurally, so this naturally lands on CONCRETE functions first;
   generics stay move until the mono ABI reads the flag (follow-on).
2. Callee no-drop for IndirectPlace params (MirLower.w:11961/12068): schedule the
   `DK_VALUE` drop only when the param is OWNED (not `value_ref_abi`). MIR runs
   post-fixpoint, so it reads the final flag — correct.
3. Call-site: a non-Copy value arg to a share-place param must NOT be marked
   consumed (the caller keeps ownership and drops it); a non-Copy arg to an
   OWNED (consume/escape_value) param is consumed as today (later: require
   explicit `move`/`copy`). Delete the `arg_consumed_by_value`-for-all-non-Copy.
4. Delete the inverted lints (SemaCheck.w:1459-60/1469-71).

**The crux (verified):** part 3 runs DURING `check_bodies` (per call, inline with
use-after-move tracking), but the share-place-vs-owned determination needs the
callee's COMPLETE effect, which only finalizes in `fixpoint_effect_flow` AFTER
`check_bodies`. Reading the in-check (single-pass) effect is WRONG for forward
references / mutual recursion:
- callee's effect not yet inferred → reads 0 → "share-place" → caller keeps it,
  but the flag later resolves to OWNED (callee drops) → **double-free**.
And it cannot be deferred to MIR because the use-after decision (`buf.use()` after
`append_byte(buf)` — the definition of share-place) is also in-check.

**Therefore the flip requires a TWO-PASS body check:** pass 1 infers effects
(no consume/use-after decision), fixpoint completes them + sets `value_ref_abi`,
pass 2 makes the call-site consume/use-after decisions with complete flags. This
is a real re-architecture of the move/borrow pass (or a dedicated post-fixpoint
"finalize call-site ownership" pass that records call sites + use positions in
pass 1 and resolves them in pass 2). It is the deepest and last piece; it must be
built carefully and gated hard (a wrong forward-ref decision = a silent
double-free in the seed). Do NOT ship parts 1-2 without 3, and do NOT do 3 off
single-pass effects.

## Self-host note

The seed is move-semantics. `move x` compiles under BOTH move and share-place, so
the P2 migration is monotone-safe: add `move`/`copy`, sources stay buildable by
the old seed, stage1(share-place)→stage2 converges, then `:update-seed`. Do NOT
write share-place-dependent compiler code (use-after-default-pass) until after the
seed is updated.
