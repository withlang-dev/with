# Wave 7 Implementation Plan

## MIR Lowering for Withc2

## Goal

Build a full MIR (Mid-level Intermediate Representation) from the typed IR produced
by Wave 6 semantic analysis. After Wave 7:

- Every function body is a CFG of basic blocks.
- All syntactic sugar is lowered — no sugar exists beyond this point.
- All drops are explicit and placed at the correct scope exit points.
- `--dump-mir` output matches Stage0 behavior on the Wave 7 corpus.

Wave 7 exit gate:

- `--dump-mir` output is identical to Stage0 on the Wave 7 corpus.

---

## Inputs and Constraints

- Canonical wave definitions:
  - `docs/with-selfhost-plan.md` (§2.5 MIR contract, §3 sugar lowering map)
  - `docs/with-selfhost-detailed-plan.md` (§4.4 MIR, §7 Wave plan)
- Stage0 oracle:
  - `bootstrap/src/Codegen.zig` — current lowering reference (AST → LLVM direct)
  - `bootstrap/src/Sema.zig` — typed IR oracle
- Existing self-host files:
  - `src/Mir.w` — minimal scaffold to be replaced
  - `src/BorrowCfg.w` — lightweight CFG (node/edge lists); Wave 7 supersedes it for MIR
  - `src/Sema.w` — typed IR (Wave 6 output, Wave 7 input)
  - `src/Driver.w` — pipeline wiring
- Reference architecture:
  - Zig: `.reference/zig/src/Air.zig` — AIR (Zig's post-Sema IR, analog to MIR)
  - Rust:
    - `.reference/rust/compiler/rustc_mir_build/src/builder/mod.rs`
    - `.reference/rust/compiler/rustc_mir_build/src/builder/cfg.rs`
    - `.reference/rust/compiler/rustc_mir_build/src/builder/scope.rs`
    - `.reference/rust/compiler/rustc_mir_build/src/builder/expr/`
    - `.reference/rust/compiler/rustc_mir_build/src/builder/matches/`

Constraints:

- Stage0 remains semantic oracle throughout Wave 7.
- Self-host source must stay within Stage0-safe subset (no async combinators, no
  generic async task-collection patterns).
- No borrow checking in Wave 7 (Wave 8).
- No async lowering in Wave 7 (Wave 9).
- All state uses stable i32 handles (SoA, no stored references).
- Synchronous, deterministic pass pipeline.

---

## MIR Contract (from `with-selfhost-plan.md` §2.5)

### Input

Typed IR from Wave 6 (`Sema` output):

- All names resolved to DefIds/symbols.
- All expressions have TypeIds.
- All trait obligations resolved.
- Sugar still present (see Sugar Lowering Map).

### Output

Basic blocks where every block contains:

- Zero or more **statements**: `Assign`, `StorageLive`, `StorageDead`, `Drop`, `Nop`
- Exactly one **terminator**: `Goto`, `Return`, `Unreachable`, `SwitchInt`, `Call`

### Invariants

- No syntactic sugar remains.
- Only: assignments, jumps, calls, temporaries, drops, returns, explicit branches.
- Drop insertion complete (all scope exits explicit).
- Control flow is fully explicit.

### Eliminated Sugar (single source of truth from §3)

| Feature                  | Lowering Action                               |
| ------------------------ | --------------------------------------------- |
| `?.`                     | Match on Option/Result → branch               |
| `??`                     | Match on Option → branch with early exit      |
| `with` Form 1            | Guard enter/exit calls + scope                |
| `with` Form 2/3          | Block + temporary binding                     |
| Record update `{ ..base }` | Field copies + struct aggregate             |
| Pattern matching         | Decision tree → `SwitchInt` terminators       |
| Implicit Ok wrapping     | Insert explicit `Ok(expr)` aggregate          |
| Implicit default return  | Insert explicit return of default value       |
| `let...else`             | Match + early return branch                   |
| Chained `if let`         | Nested `SwitchInt` chains                     |
| Pipeline operator `\|>`  | Explicit temporary + call                     |
| Closure sugar            | Closure struct + captured fields              |

---

## Scope

### In scope

- Full MIR data structure replacing the scaffold in `src/Mir.w`.
- MIR builder (`src/MirLower.w`):
  - Basic block creation and management.
  - Statement/terminator construction.
  - Scope stack for drop scheduling.
  - Temporary allocation.
- Lowering of all typed IR constructs to MIR.
- All sugar lowering per the single-source-of-truth table above.
- Explicit drop insertion at scope exits (normal, break, continue, return).
- `--dump-mir` flag wired through `Driver.w` and `main.w`.
- Wave 7 parity harness and unit tests.

### Out of scope

- Borrow/lifetime analysis (Wave 8).
- Async lowering (Wave 9): `async fn`, `.await`, `select`, `spawn`, `gen` remain
  as opaque MIR nodes in Wave 7. They are preserved structurally, not lowered.
- LLVM codegen changes (Wave 10).
- MIR optimizations (`MirOpt.w` is a separate concern).

---

## New File: `src/MirLower.w`

This is the primary deliverable. It contains:

- `MirBody` — the full MIR of one function (SoA, i32 handles).
- `MirBuilder` — builder state for a single function.
- `lower_fn` — entry point: typed IR fn body → MirBody.
- Sugar lowering methods.
- Drop elaboration.

`src/Mir.w` is rewritten to hold the shared MIR data types used by both
`MirLower.w` and downstream passes (BorrowCfg, codegen).

---

## MIR Data Structure Design

All IDs are `i32`. All tables are SoA (parallel Vec arrays). No stored references.

### Basic Blocks

```
// Block IDs are i32 indices.
// BB 0 is always the entry block.

bb_stmt_starts: Vec[i32]     // start index into stmt arrays for this BB
bb_stmt_counts: Vec[i32]     // number of stmts in this BB
bb_term_kinds: Vec[i32]      // terminator kind tag
bb_term_d0..d3: Vec[i32]     // terminator payload fields
bb_is_cleanup: Vec[i32]      // 1 if this is a cleanup/unwind block
```

### Statements

```
// SK_* = statement kind constants

fn SK_ASSIGN      -> i32: 0   // place = rvalue
fn SK_STORAGE_LIVE -> i32: 1  // StorageLive(local)
fn SK_STORAGE_DEAD -> i32: 2  // StorageDead(local)
fn SK_DROP        -> i32: 3   // Drop(place)
fn SK_NOP         -> i32: 4

stmt_kinds:   Vec[i32]
stmt_d0:      Vec[i32]   // primary operand (place/local)
stmt_d1:      Vec[i32]   // secondary operand (rvalue id)
stmt_spans:   Vec[i32]   // source span
```

### Terminators

```
// TK_* = terminator kind constants

fn TK_GOTO        -> i32: 0   // d0 = target BB
fn TK_RETURN      -> i32: 1
fn TK_UNREACHABLE -> i32: 2
fn TK_SWITCH_INT  -> i32: 3   // d0 = discriminant operand, d1 = switch table id
fn TK_CALL        -> i32: 4   // d0 = fn operand, d1 = args start, d2 = args count, d3 = dest BB
fn TK_DROP_AND_GOTO -> i32: 5 // d0 = place to drop, d1 = target BB
```

### Places

```
// A place is a local + zero or more projections.
// place_id → local_id + projection list

place_locals:     Vec[i32]
place_proj_starts: Vec[i32]
place_proj_counts: Vec[i32]

// Projections
// PK_* = projection kind

fn PK_FIELD  -> i32: 0   // d0 = field index
fn PK_INDEX  -> i32: 1   // d0 = index local
fn PK_DEREF  -> i32: 2
fn PK_DOWNCAST -> i32: 3 // d0 = variant index

proj_kinds: Vec[i32]
proj_d0:    Vec[i32]
```

### Rvalues

```
// RK_* = rvalue kind constants

fn RK_USE       -> i32: 0   // operand
fn RK_BIN_OP   -> i32: 1   // d0=op, d1=left operand, d2=right operand
fn RK_UN_OP    -> i32: 2   // d0=op, d1=operand
fn RK_REF      -> i32: 3   // d0=borrow kind, d1=place id
fn RK_ADDR_OF  -> i32: 4   // d0=place id
fn RK_AGGREGATE -> i32: 5  // d0=agg kind, d1=fields start, d2=fields count
fn RK_DISCRIMINANT -> i32: 6 // d0=place id
fn RK_CAST     -> i32: 7   // d0=operand, d1=target type id
fn RK_LEN      -> i32: 8   // d0=place id (slice length)

rval_kinds: Vec[i32]
rval_d0:    Vec[i32]
rval_d1:    Vec[i32]
rval_d2:    Vec[i32]
```

### Operands

```
// OK_* = operand kind constants

fn OK_COPY     -> i32: 0   // d0=place id
fn OK_MOVE     -> i32: 1   // d0=place id
fn OK_CONSTANT -> i32: 2   // d0=const id

operand_kinds: Vec[i32]
operand_d0:    Vec[i32]
```

### Constants

```
// CK_* = constant kind

fn CK_INT  -> i32: 0   // d0=value (small int)
fn CK_BOOL -> i32: 1   // d0=0/1
fn CK_STR  -> i32: 2   // d0=intern pool symbol
fn CK_UNIT -> i32: 3
fn CK_FLOAT -> i32: 4  // d0=interned float id
fn CK_ZERO_SIZED -> i32: 5 // d0=type id

const_kinds:  Vec[i32]
const_d0:     Vec[i32]
const_types:  Vec[i32]   // TypeId for this constant
```

### Locals

```
// Local variables and temporaries for one function body.
// Local 0 is always the return place (_0).
// Parameters follow: locals 1..n_params.
// Temporaries follow.

local_type_ids: Vec[i32]   // TypeId
local_mutables: Vec[i32]   // 1 if mutable
local_names:    Vec[i32]   // intern symbol (0 = anonymous temp)
local_is_user_var: Vec[i32] // 1 if user-declared, 0 if compiler temp
```

### MirBody (per function)

```
type MirBody = {
    fn_sym: i32,       // function symbol

    // Locals (SoA)
    local_type_ids:    Vec[i32],
    local_mutables:    Vec[i32],
    local_names:       Vec[i32],
    local_is_user_var: Vec[i32],
    n_params:          i32,

    // Basic blocks (SoA)
    bb_stmt_starts:  Vec[i32],
    bb_stmt_counts:  Vec[i32],
    bb_term_kinds:   Vec[i32],
    bb_term_d0:      Vec[i32],
    bb_term_d1:      Vec[i32],
    bb_term_d2:      Vec[i32],
    bb_term_d3:      Vec[i32],
    bb_is_cleanup:   Vec[i32],

    // Statements (SoA)
    stmt_kinds:  Vec[i32],
    stmt_d0:     Vec[i32],
    stmt_d1:     Vec[i32],
    stmt_spans:  Vec[i32],

    // Places (SoA)
    place_locals:      Vec[i32],
    place_proj_starts: Vec[i32],
    place_proj_counts: Vec[i32],
    proj_kinds: Vec[i32],
    proj_d0:    Vec[i32],

    // Rvalues (SoA)
    rval_kinds: Vec[i32],
    rval_d0:    Vec[i32],
    rval_d1:    Vec[i32],
    rval_d2:    Vec[i32],

    // Operands (SoA)
    operand_kinds: Vec[i32],
    operand_d0:    Vec[i32],

    // Constants (SoA)
    const_kinds:  Vec[i32],
    const_d0:     Vec[i32],
    const_types:  Vec[i32],

    // Switch tables: switch_table_starts[id], switch_table_counts[id]
    // Each entry is (value: i32, target_bb: i32), packed into switch_table_vals/targets
    switch_table_starts:  Vec[i32],
    switch_table_counts:  Vec[i32],
    switch_table_vals:    Vec[i32],
    switch_table_targets: Vec[i32],

    // Aggregate fields scratch: agg_field_starts[id], counts[id]
    agg_field_starts:  Vec[i32],
    agg_field_counts:  Vec[i32],
    agg_field_operands: Vec[i32],

    // Call argument scratch
    call_arg_starts:  Vec[i32],
    call_arg_counts:  Vec[i32],
    call_arg_operands: Vec[i32],
}
```

### MirModule (per compilation unit)

```
type MirModule = {
    bodies: Vec[MirBody],
    body_fn_syms: Vec[i32],   // for fast lookup by fn_sym
}
```

---

## MIR Builder Design

```
type ScopeEntry = {
    local_id: i32,     // local to drop on scope exit
    drop_kind: i32,    // DK_VALUE or DK_STORAGE
}

type DropScope = {
    drops: Vec[ScopeEntry],
}

type LoopInfo = {
    continue_bb: i32,
    break_bb: i32,
    // drops to run on break (snapshot of scope stack at loop entry)
    break_drop_depth: i32,
}

type MirBuilder = {
    body: MirBody,        // being constructed

    // Current block
    cur_bb: i32,

    // Scope stack for drop scheduling
    scope_stack: Vec[DropScope],

    // Loop stack for break/continue
    loop_stack: Vec[LoopInfo],

    // Next temp counter (for anonymous temporaries)
    next_temp: i32,

    // Reference back to Sema for type lookups
    sema: Sema,
}
```

Key builder operations:

- `new_block() -> i32` — allocate a fresh basic block, return its id
- `push_stmt(kind, d0, d1, span)` — append statement to `cur_bb`
- `terminate(kind, d0, d1, d2, d3)` — set terminator on `cur_bb`, advance `cur_bb`
- `new_temp(type_id) -> i32` — allocate anonymous local, return local id
- `push_scope()` / `pop_scope(exit_bb)` — manage drop scope stack
- `schedule_drop(local_id)` — register drop in current scope
- `emit_drops_to(target_bb)` — emit all pending drops, then goto target
- `new_place(local_id) -> i32` — create place for local
- `new_field_place(base_place, field_idx) -> i32` — place with field projection

---

## Lowering Pass Design (`lower_fn`)

Entry point per function:

```
fn lower_fn(builder: MirBuilder, fn_node: i32) -> MirBody:
    // 1. Allocate return local (_0)
    // 2. Allocate param locals
    // 3. StorageLive for all params
    // 4. Push root scope
    // 5. lower_expr(body_expr) into entry BB
    // 6. Pop root scope (emits drops)
    // 7. Terminate with Return
    // 8. Return completed body
```

---

## Execution Checklist

### 0) Preparation

- [ ] Read and cross-reference:
  - `docs/with-selfhost-plan.md` §2.5 and §3
  - `docs/with-selfhost-detailed-plan.md` §4.4
  - `bootstrap/src/Codegen.zig` (current lowering oracle)
  - `.reference/zig/src/Air.zig` (AIR instruction set)
  - `.reference/rust/compiler/rustc_mir_build/src/builder/cfg.rs`
  - `.reference/rust/compiler/rustc_mir_build/src/builder/scope.rs`
- [ ] Define Wave 7 corpus: a set of `.w` files covering all sugar to be lowered.
- [ ] Add `--dump-mir` to Stage0 (`bootstrap/src/Driver.zig` + `bootstrap/src/main.zig`)
  and capture golden MIR dumps for the corpus.
- [ ] Document the `--dump-mir` text format spec in `docs/wave7-mir-dump-spec.md`.

### 1) Rewrite `src/Mir.w` — Full MIR Data Structures

- [ ] Replace scaffold `MirFunction` / `MirModule` with full MIR types.
- [ ] Define all `SK_*`, `TK_*`, `RK_*`, `OK_*`, `CK_*`, `PK_*` constants.
- [ ] Define `MirBody` (SoA parallel arrays for blocks/stmts/terms/places/rvals/operands/consts).
- [ ] Define `MirModule` (Vec of MirBody + fn_sym lookup).
- [ ] Implement `MirBody.init(fn_sym, sema) -> MirBody`.
- [ ] Implement `MirBody.new_block() -> i32`.
- [ ] Implement `MirBody.push_stmt(bb, kind, d0, d1, span)`.
- [ ] Implement `MirBody.set_terminator(bb, kind, d0, d1, d2, d3)`.
- [ ] Implement `MirBody.new_local(type_id, mutable, name, is_user_var) -> i32`.
- [ ] Implement `MirBody.new_place(local_id) -> i32`.
- [ ] Implement `MirBody.new_field_place(base, field_idx) -> i32`.
- [ ] Implement `MirBody.new_index_place(base, idx_local) -> i32`.
- [ ] Implement `MirBody.new_deref_place(base) -> i32`.
- [ ] Implement `MirBody.new_rvalue(kind, d0, d1, d2) -> i32`.
- [ ] Implement `MirBody.new_operand(kind, d0) -> i32`.
- [ ] Implement `MirBody.new_const(kind, d0, type_id) -> i32`.
- [ ] Implement `MirBody.new_temp(type_id) -> i32` (anonymous local).
- [ ] Implement `MirBody.new_switch_table(vals: &[i32], targets: &[i32]) -> i32`.
- [ ] Implement `MirBody.new_agg_fields(operands: &[i32]) -> i32`.
- [ ] Implement `MirBody.new_call_args(operands: &[i32]) -> i32`.
- [ ] Unit tests for all MirBody builder primitives.

### 2) Create `src/MirLower.w` — Builder and Drop Elaboration

- [ ] Define `ScopeEntry`, `DropScope`, `LoopInfo`, `MirBuilder` types.
- [ ] Implement `MirBuilder.init(sema, fn_sym) -> MirBuilder`.
- [ ] Implement `MirBuilder.push_scope()`.
- [ ] Implement `MirBuilder.schedule_drop(local_id, drop_kind)`.
- [ ] Implement `MirBuilder.pop_scope_with_goto(target_bb)`:
  - Emit a `TK_DROP_AND_GOTO` or explicit `SK_DROP` for each scheduled drop in LIFO order.
  - Chain them as a drop ladder (each drop block goes to next).
  - Final block goes to `target_bb`.
- [ ] Implement `MirBuilder.emit_drops_for_break(loop_info)`:
  - Emit drops down to loop's `break_drop_depth`.
- [ ] Implement `MirBuilder.emit_drops_for_return()`:
  - Emit all drops from all scopes (full stack), chain to return block.
- [ ] Implement `MirBuilder.push_loop(continue_bb, break_bb)`.
- [ ] Implement `MirBuilder.pop_loop()`.
- [ ] Implement `MirBuilder.current_loop() -> LoopInfo`.

### 3) Lowering — Literals and Simple Expressions

- [ ] `lower_int_lit(value, type_id) -> operand_id`
- [ ] `lower_bool_lit(value) -> operand_id`
- [ ] `lower_str_lit(sym) -> operand_id`
- [ ] `lower_float_lit(sym) -> operand_id`
- [ ] `lower_unit() -> operand_id`
- [ ] `lower_var(local_id) -> place_id` (Copy or Move based on type)
- [ ] `lower_bin_op(op, lhs_expr, rhs_expr) -> rvalue_id`
- [ ] `lower_un_op(op, expr) -> rvalue_id`
- [ ] `lower_cast(expr, target_type_id) -> rvalue_id`
- [ ] `lower_field_access(base_expr, field_idx) -> place_id`
- [ ] `lower_index(base_expr, index_expr) -> place_id`
- [ ] `lower_deref(expr) -> place_id`
- [ ] `lower_ref(expr, borrow_kind) -> rvalue_id`
- [ ] `lower_assign(place_expr, rhs_expr)` → `SK_ASSIGN`
- [ ] Unit tests: literals, arithmetic, field access.

### 4) Lowering — Block and Let Bindings

- [ ] `lower_block(stmts, tail_expr) -> operand_id`:
  - Push scope.
  - Lower each statement.
  - Lower tail expression (or unit).
  - Pop scope (emit drops).
- [ ] `lower_let_binding(pat, rhs_expr, mutable)`:
  - Allocate local(s) for binding.
  - Emit `SK_STORAGE_LIVE`.
  - Schedule drop if non-Copy type.
  - Emit assignment.
- [ ] `lower_let_else(pat, rhs_expr, else_block)`:
  - Lower rhs into temp.
  - Emit match decision tree.
  - On match fail → lower else_block (must diverge: return/break/continue).
  - On match success → bind pattern locals.
- [ ] Unit tests: blocks, let, let-else.

### 5) Lowering — Control Flow

- [ ] `lower_if(cond_expr, then_expr, else_expr_opt) -> operand_id`:
  - Lower cond into bool temp.
  - Emit `TK_SWITCH_INT` with then_bb / else_bb.
  - Lower then branch into then_bb.
  - Lower else branch (or unit) into else_bb.
  - Both branches goto join_bb.
  - Result temp assigned in each branch.
- [ ] `lower_if_let(pat, scrutinee_expr, then_expr, else_expr_opt)`:
  - Lower scrutinee into temp.
  - Emit pattern match decision tree.
  - Bind pattern locals in success branch.
  - Fallthrough to else or unit.
- [ ] `lower_loop(body_expr) -> operand_id`:
  - Create loop_header_bb, loop_body_bb, break_bb.
  - Push loop (continue=loop_header_bb, break=break_bb).
  - Lower body in loop_body_bb (back-edge to loop_header_bb).
  - Pop loop.
  - Break result land in break_bb.
- [ ] `lower_while(cond_expr, body_expr)`:
  - Desugar to `loop { if !cond { break } body }`.
  - Use `lower_loop`.
- [ ] `lower_for(pat, iter_expr, body_expr)`:
  - Desugar to `loop` over iterator protocol.
  - Call `iter_expr.next()` → Option; match on Some/None.
  - Bind `pat` locals in Some branch.
  - None branch breaks.
- [ ] `lower_break(value_expr_opt)`:
  - If value: lower into break result place.
  - Emit drops for enclosing scopes up to loop.
  - Goto `break_bb`.
- [ ] `lower_continue()`:
  - Emit drops for enclosing scopes up to loop (but not loop's break drops).
  - Goto `continue_bb`.
- [ ] `lower_return(value_expr_opt)`:
  - Lower value into `_0` (return place).
  - Emit all pending drops (full stack).
  - Emit `TK_RETURN`.
- [ ] `lower_unreachable()`:
  - Emit `TK_UNREACHABLE`.
- [ ] Unit tests: if/else, loop, while, for, break, continue, return.

### 6) Lowering — Pattern Matching and Decision Trees

- [ ] Design decision tree representation:
  - `DecisionNode` with test/match/fail branches.
  - Translate to `TK_SWITCH_INT` terminators.
- [ ] `lower_match(scrutinee_expr, arms) -> operand_id`:
  - Lower scrutinee into temp.
  - Build decision tree from arm patterns.
  - Emit `TK_SWITCH_INT` chains.
  - For each arm: bind locals, lower body, goto join_bb.
- [ ] `lower_pattern(pat, scrutinee_place) -> Vec[(local_id, place_id)]`:
  - Wildcard: no-op.
  - Binding `name`: emit `SK_ASSIGN` place → local.
  - Literal: emit comparison → `TK_SWITCH_INT`.
  - Tuple: recursively match each field.
  - Struct: recursively match named fields.
  - Enum variant: discriminant check + field bindings.
  - Or-pattern `A | B`: try A, on fail try B.
  - Guard: lower guard expr; on fail go to next arm.
- [ ] `lower_enum_discriminant(place) -> operand_id`:
  - Emit `RK_DISCRIMINANT` rvalue.
- [ ] Unit tests: literal match, enum match, struct/tuple destructure, or-patterns, guards.

### 7) Sugar Lowering

- [ ] `lower_question_mark(expr) -> operand_id` — `?.`:
  - Lower inner expr into temp.
  - Emit match: Some(v) → unwrap v; None → return None (or Err propagation).
  - Uses `TK_SWITCH_INT` on discriminant.
- [ ] `lower_double_question(expr, default_expr) -> operand_id` — `??`:
  - Lower inner expr into temp.
  - Emit match: Some(v) → v; None → lower default_expr.
- [ ] `lower_with_form1(guard_expr, body_expr) -> operand_id` — `with guard`:
  - Call guard enter fn.
  - Push scope with guard exit scheduled.
  - Lower body.
  - Pop scope (guard exit emitted as drop).
- [ ] `lower_with_form2_3(pat, rhs_expr, body_expr) -> operand_id` — `with x = expr`:
  - Lower rhs into temp.
  - Bind pat.
  - Lower body.
  - Drop bound local on scope exit.
- [ ] `lower_record_update(base_expr, field_updates) -> operand_id` — `{ ..base }`:
  - Lower base into temp.
  - For each field in struct type:
    - If in `field_updates`: use new value.
    - Else: copy from base temp (field place).
  - Emit `RK_AGGREGATE` with all field operands.
  - Drop base temp if non-Copy.
- [ ] `lower_implicit_ok(expr, ok_type_id) -> operand_id`:
  - Lower inner expr.
  - Emit `RK_AGGREGATE` for `Ok(value)`.
- [ ] `lower_implicit_default_return(type_id) -> operand_id`:
  - Emit unit constant or default aggregate per type.
- [ ] `lower_pipeline(lhs_expr, fn_expr, args) -> operand_id` — `\|>`:
  - Lower lhs into temp.
  - Prepend temp as first argument.
  - Lower as function call.
- [ ] `lower_closure(captured_vars, params, body_expr) -> operand_id`:
  - Allocate closure struct type (captured fields).
  - Emit `RK_AGGREGATE` for closure captures.
  - Register closure body as a synthetic function (to be lowered separately).
- [ ] Unit tests for each sugar form.

### 8) Lowering — Function Calls and Method Dispatch

- [ ] `lower_call(fn_expr, arg_exprs, ret_type_id) -> operand_id`:
  - Lower fn operand (static fn sym or fn pointer).
  - Lower each arg into operand.
  - Allocate result temp.
  - Emit `TK_CALL` terminator.
  - Continue in next_bb.
- [ ] `lower_method_call(self_expr, method_sym, arg_exprs) -> operand_id`:
  - Resolve method to fn sym via Sema.
  - Lower self (pass by value or ref per calling convention).
  - Lower remaining args.
  - Emit `TK_CALL`.
- [ ] `lower_vtable_call(dyn_expr, trait_sym, method_sym, args) -> operand_id`:
  - Extract vtable pointer from fat pointer.
  - Emit indirect `TK_CALL` through vtable slot.
- [ ] Unit tests: direct call, method call, generic monomorphized call.

### 9) Top-Level Lowering and Pipeline Wiring

- [ ] `lower_module(sema, ast_pool) -> MirModule`:
  - For each function declaration in the module (in deterministic order):
    - Call `lower_fn(builder, fn_node)`.
    - Append resulting `MirBody` to `MirModule`.
  - Return completed `MirModule`.
- [ ] Wire `lower_module` into `Driver.w`:
  - After `Sema` pass completes without errors.
  - Store `MirModule` in `Driver` state.
  - Gate `--dump-mir` output on this stage.
- [ ] Update `src/Driver.w`:
  - Add `mir_module: MirModule` field.
  - Add `run_mir_lower()` method.
  - Add `dump_mir()` method (for `--dump-mir` flag).
- [ ] Update `src/main.w`:
  - Add `--dump-mir` flag handling.
  - Pass flag through to Driver.

### 10) MIR Dump Format (`--dump-mir`)

The dump is human-readable text, one function per section.

Format (subject to Stage0 golden comparison):

```
fn function_name(param0: Type0, param1: Type1) -> RetType {
    let _0: RetType;          // return place
    let _1: Type0;            // param 0
    let _2: Type1;            // param 1
    let _3: SomeType;         // user var: name

    bb0: {
        _3 = SomeType { field: const 42i32 };
        goto -> bb1;
    }

    bb1: {
        _0 = move _3;
        return;
    }
}
```

Rules:
- One function per `fn ... { ... }` block.
- Local declarations before basic blocks.
- Anonymous temps named `_N`; user vars show their name in a comment.
- Constants: `const 42i32`, `const true`, `const "hello"`, `const ()`.
- Moves: `move _N`; copies: `copy _N`.
- `StorageLive(_N)` / `StorageDead(_N)` on their own lines.
- `drop(_N)` for explicit drops.
- Terminators: `goto -> bbN`, `return`, `unreachable`,
  `switchInt(operand) -> [val: bbN, ..., otherwise: bbM]`,
  `call fn(args) -> [return: place, next: bbN]`.

- [ ] Implement `dump_mir_body(body, pool) -> str`.
- [ ] Implement `dump_mir_module(module, pool) -> str`.
- [ ] Determinism: functions in symbol-table insertion order; blocks in
  allocation order; locals in allocation order.

### 11) Unit Tests

- [ ] MirBody construction primitives (new_block, push_stmt, set_terminator, etc.).
- [ ] Drop scope: push/pop, schedule, emit.
- [ ] Loop scope: break/continue drop chains.
- [ ] Literal lowering.
- [ ] Arithmetic expression lowering.
- [ ] `if/else` lowering — verify block structure.
- [ ] `loop`/`break`/`continue` lowering — verify back-edge and exit.
- [ ] `match` on enum — verify discriminant + switch table.
- [ ] `match` with guard — verify guard branch.
- [ ] `?.` sugar lowering.
- [ ] `??` sugar lowering.
- [ ] `with` form 1/2/3 lowering.
- [ ] Record update lowering.
- [ ] `let...else` lowering.
- [ ] Function call lowering.
- [ ] Drop insertion on scope exit.
- [ ] Drop insertion on early return.
- [ ] Drop insertion on break.
- [ ] Closure lowering (basic capture).

### 12) Stage0 Parity Harness

- [ ] Add `--dump-mir` to Stage0 bootstrap if not already present.
- [ ] Implement `scripts/run_wave7_mir_parity.sh`:
  - Build Stage0 and self-host.
  - Run `--dump-mir` on Wave 7 corpus with Stage0.
  - Run `--dump-mir` on Wave 7 corpus with self-host.
  - Strict diff both outputs.
  - Re-run self-host to assert determinism.
  - Report PASS / FAIL / KNOWN_DIVERGENCE.
- [ ] Build `test/wave7/mir_corpus.txt` covering:
  - All sugar forms (one test per form).
  - All control flow patterns.
  - All pattern kinds.
  - Functions with drops (non-Copy types).
  - Early return with pending drops.
  - Break/continue with pending drops.
  - Match with or-patterns and guards.
  - Closures with captures.
  - Methods and trait dispatch.
- [ ] Capture Stage0 golden MIR dumps for corpus.

### 13) Documentation and Wave Status

- [ ] Update `docs/with-selfhost-plan.md` Wave 7 status when exit gates pass.
- [ ] Update `docs/with-selfhost-detailed-plan.md` with Wave 7 completion notes.
- [ ] Record any accepted divergences with rationale and test linkage (`KNOWN_DIVERGENCE`).

---

## Key Architectural Decisions

### Why rewrite `src/Mir.w` rather than extend it?

The scaffold only has `MirFunction { name, block_count }` — it has no instructions,
no places, no types. Wave 7 replaces it entirely with the full SoA representation.
`BorrowCfg.w` remains for the lightweight borrow-analysis CFG (Wave 8 will build on it).

### Why separate `MirLower.w` from `Mir.w`?

`Mir.w` is the data model (types, constructors, dump).
`MirLower.w` is the lowering algorithm (builder, sugar expansion, drop elaboration).
This separation keeps the data structure stable while the lowering algorithm evolves.

### Drop Elaboration Strategy

Modeled on Rust `rustc_mir_build/builder/scope.rs` SEME region approach:

- Every lexical scope has a drop list.
- Drops are inserted in LIFO order at scope exit.
- Early exits (break/continue/return) consult the scope stack and emit all
  pending drops before branching.
- For loops, break emits drops down to the loop entry depth.
- For return, all scopes are unwound.

This is simpler than NLL lifetimes — Wave 7 uses lexical scope drops only.
NLL-based drop refinement is Wave 8.

### Pattern Matching Strategy

Decision tree construction:

1. Collect all arms.
2. For each arm, build a chain of tests (discriminant checks, field accesses, comparisons).
3. Tests are emitted as `TK_SWITCH_INT` chains.
4. Or-patterns share a join point.
5. Guards emit the guard expression and branch on the bool result.

This is conservative (may duplicate some tests) but correct and deterministic.
Optimized decision trees are a Wave 10+ concern.

### Closures in Wave 7

Closures are lowered to:
1. A synthetic struct type for captures (emitted to MirModule).
2. A synthetic function taking the closure struct as first arg.
3. An `RK_AGGREGATE` rvalue constructing the closure value.

The closure body is lowered like any other function. No coroutine/generator
state-machine lowering in Wave 7 (Wave 9).

### Stage0 Alignment

Stage0 (`bootstrap/src/Codegen.zig`) does not have an explicit MIR pass — it
lowers AST → LLVM directly. So `--dump-mir` in Stage0 will be added as a new
dump mode that emits the conceptual MIR that Codegen implicitly computes, making
it available for parity validation. The golden MIR dump format is defined by this
Wave 7 plan.

---

## Validation Gates (Wave 7 Exit)

- [ ] All unit tests in `test/wave7/` pass.
- [ ] `scripts/run_wave7_mir_parity.sh` passes with strict diff on Wave 7 corpus.
- [ ] MIR dump determinism check passes on repeated runs.
- [ ] No syntactic sugar appears in any dumped MIR body.
- [ ] All drop insertions are present in MIR (verified by corpus inspection).
- [ ] `--dump-mir` wired into Driver pipeline, gated behind successful Sema pass.
- [ ] No unresolved divergences for Wave 7 scope.
