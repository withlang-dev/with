# Move/drop correctness and cleanup control-flow audit

## Audit identity

- Audit target: overview targets 5 and 7 — move/drop correctness and cleanup control flow
- Source revision: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`
- Compiler exercised: `out/stage/bin/with-stage2`
- Audit date: 2026-09-01
- Production files changed: none
- Overall status: **incomplete and unsafe to mark audited**

This was a bounded source-first pass. It confirmed two independent correctness
defects, proved two additional structural limitations in source, and identified
cross-target dependencies. No applicable module is marked complete: the full
type/exit/backend matrix has not been executed, and confirmed defects remain.

## Verdict

| ID | Status | Severity | Reach | Confidence | Summary |
|---|---|---:|---|---|---|
| MDC-001 | Confirmed executable defect | High | Any function whose inner lexical scope registers `errdefer` and later exits through an outer `?` | Very high | Normal lexical scope exit leaves the inner `errdefer` registered, so it runs on a later unrelated error return. |
| MDC-002 | Confirmed executable defect | Critical | Every non-`Vec` destructor emitted through the public `--emit-c` backend | Certain | C codegen replaces a real MIR `Drop` with a comment and exits successfully. |
| MDC-003 | Source-proven limitation; runtime consequence not isolated | High | Loop/backedge ownership validation and any future consumer of the drop-state plan | High | Drop-state analysis ignores higher-numbered predecessors/backedges and makes only one linear pass. |
| MDC-004 | Source-proven architecture/verification drift | Medium | MIR drop validation/elaboration and maintainers relying on its comments/dumps | High | The only MIR dead-drop elaborator has no textual caller, while its comments describe a retired M7 runtime flag model. |

Severity reflects semantic/resource-safety impact, not how often a backend or
construct is used. In particular, MDC-002 is Critical because a successful
compiler command silently removes user resource cleanup; its reach is bounded to
`--emit-c`.

## Method and evidence boundaries

The repository knowledge graph was queried first as required, but the indexed
graph returned no usable move/drop/cleanup symbols. Discovery therefore fell
back to `tilth`, exact source sections, and executable probes. Source and emitted
behavior were treated as authoritative. Specification prose was not used to
infer implementation behavior.

Evidence collected:

1. Read the move-state, cleanup-stack, MIR dataflow, validator, LLVM-codegen, and
   C-codegen branches listed below.
2. Inventoried existing move/drop, `defer`/`errdefer`, and debug-allocator tests.
3. Compiled both new repros with `--validate-all`.
4. Ran both new repros and their relevant controls; all runtime probes also used
   the native debug allocator where supported.
5. Emitted, inspected, compiled, and ran the C artifact for MDC-002, then compared
   it to the LLVM-backed execution of the same source.

No compiler build, fixpoint, or full test suite was run: this audit made no
production changes, and the bounded probes answer the claims made here. One
initial generated-C link attempt referenced the stale `out/lib` layout and
failed before linkage; the same generated source was then linked against the
current `out/bootstrap-lib` runtime objects and executed successfully.

## Source authority inventory

### Semantic move authority

- `src/Sema.w:63-66` defines the diagnostic variable states: `LIVE` and
  `MOVED` only.
- `src/Sema.w:4767-4778` owns lexical scope state and clears moved-field facts.
- `src/Sema.w:4909-4936` joins branch state: a local is considered moved if any
  non-diverging branch moves it.
- `src/Sema.w:4938-5070` handles loop-carried move state and break accumulators.
  `is_loop_carried_move` at `4990-4991` deliberately gates the check on
  `needs_drop != 0`; the surrounding source says POD moves are currently
  non-destructive (#607).
- `src/Sema.w:7212-7247` checks movement of projected/consumed fields.

This is a diagnostic state machine. It is separate from MirLower's emission
state and from MIR's validator dataflow, so agreement between all three is not
structurally guaranteed.

### Cleanup registration and ownership-state authority

- `src/MirLower.w:296-303` records five independent scope markers: drops,
  bindings, aliases, defers, and errdefers.
- `src/MirLower.w:332-391` registers and emits `with` guard cleanup.
- `src/MirLower.w:393-457` records whole-local move/drop ownership.
- `src/MirLower.w:475-620` records projected moved-field paths.
- `src/MirLower.w:622-658` decides whether a whole value, its remaining fields,
  or nothing is dropped. A custom `Drop` owner with moved descendants is still
  dropped as a whole; ordinary aggregates recurse in reverse field order.
- `src/MirLower.w:660-707` creates statement-temporary frames.
- `src/MirLower.w:717-766` consumes `move` operands, marks whole or projected
  places moved, cancels statement-temporary drops, and queues reset-on-move.
- `src/MirLower.w:775-786` queues field resets.
- `src/MirLower.w:829-907` flushes statement temporaries and queued resets in
  reverse/drop-safe order.
- `src/MirLower.w:929-1015` emits one scheduled cleanup/drop entry.
- `src/MirLower.w:1017-1082` pops lexical scopes on normal inline and goto paths.
- `src/MirLower.w:1084-1140` emits cleanup for target exits and function return.
- `src/MirLower.w:5909-6027` lowers blocks and registers `defer`/`errdefer`.
- `src/MirLower.w:7757-7840` handles break, continue, goto, and explicit return.
- `src/MirLower.w:10563-10664` handles the failure return of `?`.
- `src/MirLower.w:11861-12015` lowers `with` forms.
- `src/MirLower.w:13758-13920` initializes function-owned parameters and emits
  tail/fallthrough cleanup.

### MIR drop-state and validation authority

- `src/Mir.w:1631-1660` defines the drop-state lattice join.
- `src/Mir.w:1708-1750` marks places and constructs the initial state.
- `src/Mir.w:1752-1827` transfers moves, assignments, calls, and drops.
- `src/Mir.w:1829-1913` finds successors and reconstructs block input state.
- `src/Mir.w:2086-2097` computes block states.
- `src/Mir.w:2146-2187` builds a drop plan.
- `src/Mir.w:2198-2240` defines dead-drop elaboration.
- `src/Mir.w:2379-2415` validates ownership at MIR drop sites.
- `src/Mir.w:2660-2670` defines `validate_all_mir_module` as shape, typed-MIR,
  and ownership checks.

### Codegen consumers

- `src/CodegenDispatch.w:5456-5470` consumes MIR `Drop` in LLVM codegen. It sets
  `current_drop_needs_guard` from the root local's `ever_moved` bit, then invokes
  the LLVM drop-place emitter.
- `src/CodegenDispatch.w:3989-4079` emits unconditional/guarded user `Drop` glue.
- `src/CodegenDispatch.w:4012-4028` implements the byte-zero moved sentinel.
- `src/CodegenDispatch.w:5035-5137` applies null guards to `Rc`, `Arc`, and `Box`
  paths.
- `src/CCodegen.w:8155-8160` consumes statement-form MIR `Drop` in C codegen.
- `src/CCodegen.w:8232-8240` consumes terminator-form `DropAndGoto` in C codegen.
- `src/compiler/DriverOptions.w:424-434` and
  `src/compiler/Compilation.w:1140` establish `--emit-c` as a reachable compiler
  mode, not dead code.

## MDC-001 — inner `errdefer` survives normal lexical scope exit

### Reproduction

```with
use std.builtins.write

enum R { Ok(i32) | Err(str) }

fn fail -> R: .Err("boom")

fn probe -> R:
    if true:
        errdefer: write("I")
    errdefer: write("O")
    let _value = fail()?
    .Ok(0)

fn main:
    let _result = probe()
```

Expected output: `O`. The inner lexical scope completed successfully, so its
failure-only cleanup is no longer eligible when the later outer operation fails.

Observed evidence:

```text
with-stage2 check errdefer_scope_leak.w --validate-all
validate-all: ok

with-stage2 run errdefer_scope_leak.w --debug-alloc
OI
```

A negative control removed only the inner `errdefer` while retaining the same
outer failure path:

```text
with-stage2 check errdefer_scope_control.w --validate-all
validate-all: ok

with-stage2 run errdefer_scope_control.w --debug-alloc
O
```

The defect is therefore tied to lexical registration, not generic `?` order or
the outer `errdefer` implementation.

### Exact failure chain

1. `lower_block_mode` records `errdefer_start` on scope entry
   (`src/MirLower.w:5920-5925`).
2. `NODE_ERRDEFER` appends the expression to the global `errdefer_nodes` vector
   (`src/MirLower.w:5972-5976`).
3. On normal block exit, `lower_block_mode` explicitly emits and removes only
   normal `defer_nodes` (`src/MirLower.w:5996-6006`).
4. It then calls `pop_scope_inline` (`src/MirLower.w:6008`). That function pops
   `errdefer_scope_starts` but never truncates `errdefer_nodes`
   (`src/MirLower.w:1051-1082`). `pop_scope_with_goto` has the same omission at
   `1017-1049`.
5. A later `?` failure calls `emit_errdefers_for_return`
   (`src/MirLower.w:10640`), which walks the still-present global vector. The
   escaped inner cleanup therefore executes after the later outer one, producing
   `OI`.

### Five Whys

1. Why did `I` run? The inner cleanup node remained globally registered.
2. Why did it remain? Normal scope exit never truncated the errdefer vector.
3. Why was truncation missed? A scope stores offsets separately from the node
   vectors, and the generic scope-pop helpers pop markers rather than the owned
   ranges.
4. Why did normal `defer` not fail identically? Block lowering manually emits and
   removes `defer_nodes`, a one-off operation not mirrored for `errdefer`.
5. Why can exit paths diverge? Cleanup semantics are distributed across block
   lowering, two pop helpers, target cleanup, return cleanup, and `?` cleanup
   instead of one cleanup-frame transition.

### Impact and validator gap

The wrong cleanup can release a resource that is no longer live, mutate state,
or mask the original error. Both `--validate-all` runs succeed because MIR
validation checks place/type/ownership shape, not lexical cleanup-stack balance
or cleanup-edge provenance.

### Root repair boundary

Repair the cleanup-stack abstraction, not the `?` branch alone. A lexical cleanup
frame should own the exact drop/defer/errdefer ranges it registered. One canonical
scope-exit operation must:

- execute the cleanup categories appropriate to the exit reason;
- truncate every category to the frame's saved bounds;
- be used by fallthrough, return, `?`, break, continue, goto, and detached
  unreachable lowering; and
- make stale inner nodes structurally unrepresentable after scope exit.

A narrow `errdefer_nodes.truncate(...)` only in `lower_block_mode` would leave the
duplicated exit machinery and is not a complete root repair.

## MDC-002 — `--emit-c` silently removes user destructors

### Reproduction and differential oracle

```with
use std.builtins.print_i32

var DROPS: i32 = 0

type Guard { id: i32 }

impl Drop for Guard:
    fn drop(move self: Self):
        DROPS = DROPS + self.id

fn scoped:
    let guard = Guard { id: 1 }

fn main:
    scoped()
    print_i32(DROPS)
```

Observed LLVM-backed execution:

```text
with-stage2 check emit_c_user_drop.w --validate-all
validate-all: ok

with-stage2 run emit_c_user_drop.w --debug-alloc
1
```

Observed C-backed execution:

```text
with-stage2 build emit_c_user_drop.w --emit-c -O1 -o emit_c_user_drop.c
success

generated C at lines 7753-7765:
    ... initialize Guard ...
    /* drop(_1); */
    return;

cc -O1 ... emit_c_user_drop.c out/bootstrap-lib/{runtime objects} ...
success (warnings only)

./emit_c_user_drop
0

WITH_DEBUG_ALLOC=1 ./emit_c_user_drop
0
```

The same checked MIR program therefore produces a destructor call in the LLVM
backend and no destructor call in the C backend.

### Exact failure chain

1. MirLower correctly schedules and emits a `StmtKind.Drop` for `guard`.
2. LLVM codegen consumes that statement through
   `src/CodegenDispatch.w:5456-5470` and emits user drop glue.
3. C codegen reaches `src/CCodegen.w:8155-8160`. It clears only its pseudo-`Vec`
   representation; every other type is emitted as the literal comment
   `/* drop(place); */`.
4. The compiler returns success and the generated C compiles and runs.
5. `DropAndGoto` repeats the same silent behavior at
   `src/CCodegen.w:8232-8240`.

### Five Whys

1. Why was the destructor absent? C codegen emitted a comment in place of MIR
   cleanup.
2. Why did it do so? Its drop branch implements only pseudo-`Vec` clearing.
3. Why can one backend omit language semantics? MIR does not hand both backends a
   canonical, backend-neutral drop-glue plan; LLVM reconstructs semantic cleanup
   in its own emitter.
4. Why was the omission accepted? The C backend treats unsupported cleanup as a
   successful placeholder instead of a hard diagnostic.
5. Why was it not caught? No user-defined-`Drop` C/LLVM parity fixture was found
   in the test inventory.

### Impact

This violates the repository's no-silent-fallback rule. Any user-defined
destructor, and any non-`Vec` resource whose release relies on MIR `Drop`, loses
observable behavior in generated C. Consequences include leaks, missing unlocks,
missing flush/close operations, and transaction/guard semantics being skipped.

### Root repair boundary

Make destructor selection/traversal/guarding a canonical MIR drop-glue contract
consumed by both code generators. C codegen must implement every supported action
or reject the program with a source-located non-zero diagnostic. It must not
independently approximate type semantics. Until full parity exists, failing
loudly on a non-`Vec` drop is the only acceptable bounded behavior.

The repair must cover both statement `Drop` and terminator `DropAndGoto`, and
must include user `Drop`, aggregate traversal, enum payloads, `Box`/`Rc`/`Arc`,
moved-value guards, and partial moves.

## MDC-003 — MIR drop-state analysis is backedge-blind

This is a source-proven limitation, not a claimed runtime reproducer.

`mir_drop_state_block_input` considers only predecessor block numbers in
`0..bb` (`src/Mir.w:1897-1913`). A predecessor created later than `bb`, including
the conventional loop latch/backedge, cannot contribute. If no earlier
predecessor is seen, the function returns the function-entry state.

`mir_compute_drop_states` then visits blocks exactly once in numeric order
(`src/Mir.w:2086-2097`). It has no worklist and no fixed-point iteration. Thus a
state change on a backedge can never update the loop header or its downstream
drop decisions.

The affected consumers are:

- the ownership validator at `src/Mir.w:2379-2415`; and
- the drop planner/elaborator at `src/Mir.w:2146-2240` if/when elaboration is
  connected.

The current LLVM emitter primarily relies on MirLower's `ever_moved` sentinel
strategy, which limits the evidence for an immediate emitted-code failure. The
validator's assurance is still incomplete for loop-carried move/drop state, and
the planner cannot safely become an optimization authority in its present form.

### Root repair boundary

Use a reachable-block worklist fixed point over the complete predecessor graph,
including backedges. Preserve a distinct unreachable state instead of silently
substituting function-entry state. Run the same lattice authority for planning
and validation, then add hand-authored negative MIR controls that force a moved,
maybe-live, and reinitialized place around a loop backedge.

## MDC-004 — dead-drop elaboration is orphaned and documents a retired model

Exact-text source search found `mir_elaborate_dead_drops` only at its definition
(`src/Mir.w:2198-2240`); no textual caller was found under `src/`. Its comments
say a `MaybeGarbage` place retains “M7 runtime drop-flag/branch structure”
(`2204-2206`), while the active MirLower drop emitter says M7 flags were retired
in favor of reset-on-move sentinels (`src/MirLower.w:929-932`).

This is not enough to claim a current runtime failure: LLVM codegen consumes the
`ever_moved` bit and zero/null sentinels directly. It is enough to prove that the
named MIR elaboration pass is not part of the textual pipeline and that its
documented model disagrees with the active emitter.

### Root repair boundary

Choose and enforce one authority:

- if MIR drop elaboration is required, connect it at a documented phase boundary,
  repair MDC-003 first, and make backends consume its result; or
- if reset-on-move is the sole design, remove the dead elaboration contract and
  make validators/dumps explicitly validate that design.

Do not wire the current elaborator into production before fixing its backedge
analysis.

## Cross-target dependencies, not duplicate findings

- `src/Mir.w:1822-1825` marks every `TK_CALL` destination initialized without a
  success/cancellation distinction. The wider audit has already associated this
  with issue #916 and call-result/cancellation analysis; this report does not
  claim it as a new move/drop issue.
- `validate_all_mir_module` does not include the separate use-after-kill audit.
  The broader audit associates dominance/use-after-kill work with #742. MDC-003
  is adjacent validator infrastructure, but this pass did not prove it is the
  same defect.
- `src/MirLower.w:788-803` explicitly says only same-scope `str` views are
  materialized before consuming their owner; cross-scope consumes and non-`str`
  views retain “robbed view” behavior. That source-admitted residue belongs to
  the dedicated borrow/view audit target and is handed off rather than counted
  twice here.
- Existing source/test comments connect nearby work to #605, #606, #607, #614,
  #697, #719, #729, #771, #777, and #780. Those identifiers establish historical
  adjacency, not current issue status or coverage of MDC-001/MDC-002.

Neither confirmed defect is asserted to be previously unreported. A bounded
search of local `docs/issues` found no matching numeric records, but upstream
issue status was not checked and no issue was filed.

## Existing-test inventory and gaps

The repository contains meaningful tests for:

- basic/LIFO `errdefer`, `?`, success suppression, and the rule that goto/break
  do not themselves execute errdefer;
- conditional whole moves and projected moves;
- reset-on-move for `Vec`, `str`, `Box`, `Rc`, `Arc`, tuples, structs, enums, and
  selected deferred/return paths;
- statement-temporary order and several debug-allocator double-free/leak
  regressions; and
- labeled break/continue cleanup.

The inventory did not find coverage for:

- an `errdefer` registered in a nested scope that completes normally before a
  later outer `?` fails;
- user-defined `Drop` parity between LLVM and `--emit-c`;
- a complete drop matrix over every exit edge and every aggregate projection;
- validator negative controls with ownership changes on loop backedges; or
- cleanup equivalence across fallthrough, explicit return, tail return, `?`,
  break, continue, goto, async cancellation, panic/unwind, and `with` guard exit.

## Required regression matrix

The following is the minimum root-fix matrix. Each row needs both a semantic
oracle (counter/event order) and a debug-allocator oracle where allocation is
involved. Backend-capable rows need LLVM/C parity.

| Dimension | Required cases |
|---|---|
| Whole-place state | live, moved, conditionally moved, moved then reinitialized, moved in loop then used/dropped after loop |
| Projection | first/middle/last field; nested field; tuple; fixed array; enum active payload; multiple fields moved on different branches |
| Drop kind | user `Drop`; structural aggregate; `str`; `Vec`; `Box`; `Rc`; `Arc`; task/future/thread-scope cleanup; `with` guard |
| Origin | owned local; consuming parameter; receiver; statement temporary; call result; pattern binding; `?` payload |
| Normal exit | block fallthrough; tail return; explicit return; nested normal scope followed by outer error |
| Target exit | break; labeled break; continue; labeled continue; goto; nested target crossing multiple scopes |
| Error/abnormal exit | `Result ?`; `Option ?`; nested `errdefer`; mixed defer/errdefer LIFO; panic/unwind if supported; async cancellation |
| Backend | LLVM execution; emitted C execution; generated artifact inspection; loud C failure for any temporarily unsupported action |
| Validator | `--validate-all`; malformed hand-authored MIR negative control; loop/backedge fixed-point case; unreachable-block case |

Ordering assertions must include:

- statement temporaries before reset-on-move;
- reverse lexical drop order;
- reverse `defer` order;
- only currently active lexical `errdefer` nodes on error;
- defers/errdefers before owned-place drops when required by the current lowering
  contract; and
- exactly one cleanup per resource on every reachable exit.

## Explicit limitations

- This is not an exhaustive proof over all move/drop-capable modules or types.
- No module is marked complete while MDC-001 and MDC-002 remain and the matrix
  above is unexecuted.
- No full suite, stage rebuild, fixpoint, sanitizer corpus, reducer pass, or async
  cancellation harness was run.
- The source branches were identified exactly, but no LLDB instruction trace was
  captured. The two confirmed defects instead use deterministic differential
  execution and debug-allocator runs; MDC-003/MDC-004 remain explicitly
  source-proven limitations rather than runtime diagnoses.
- Existing fixtures were inventoried but not all rerun. Passing historical
  fixtures would not cover the two missing cases demonstrated here.
- Upstream issue-reporting status was not established; no issue was created or
  modified.
- The report recommends repair boundaries only. It does not propose normative
  language changes and did not rely on an Observed spec section as contract.
