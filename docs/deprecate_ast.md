# Remove AST Codegen: MIR-Only Pipeline

## Goal

Delete the AST codegen path from `src/Codegen.w`. The compiler
goes through MIR for all functions, no exceptions, no fallback.
The pipeline becomes:

```
Source → Lex → Parse → Resolve → Sema → MIR → LLVM IR → Binary
```

There is no AST → LLVM IR path. MIR is the only input to codegen.

---

## Why Now

- MIR codegen is the active path. All tests pass. Fixpoint holds.
- The AST codegen path is dead code kept as a safety net.
- DWARF debug info is about to be added — instrumenting dead code
  is wasted work.
- Every bug fix and feature addition currently has to consider
  two codegen paths. Removing one halves the maintenance surface.
- The quality pass manifesto says: "one source of truth per fact."
  Two codegen paths is two sources of truth for code generation.

---

## What Gets Deleted

The AST codegen path is everything that walks AST nodes directly
to emit LLVM IR. This includes:

**Top-level dispatch:**
- `gen_function` — the AST function codegen entry point
- `gen_function_dispatch` — the MIR-vs-AST routing logic
  (becomes unconditional MIR dispatch)

**Expression emitters:**
- `gen_expr`
- `gen_bin_op` / `gen_binary`
- `gen_unary`
- `gen_call`
- `gen_method_call`
- `gen_field_access`
- `gen_index`
- `gen_cast`
- `gen_closure` (AST path)
- `gen_string_interp`
- `gen_pipeline`
- `gen_range`
- `gen_array_lit`
- `gen_struct_lit`
- `gen_tuple`
- `gen_grouped`

**Statement emitters:**
- `gen_let_binding` (AST path)
- `gen_assign` (AST path)
- `gen_return` (AST path)
- `gen_defer` / `emit_defers`
- `gen_block` / `gen_block_discard`

**Control flow emitters:**
- `gen_if_expr`
- `gen_while`
- `gen_loop`
- `gen_for` / `gen_for_range` / `gen_for_iter` / `gen_for_vec`
- `gen_match`
- `gen_break`
- `gen_continue`

**Sugar emitters:**
- `gen_with_expr`
- `gen_record_update`
- `gen_optional_chain`
- `gen_let_else`
- `gen_variant_shorthand`
- `gen_await`
- `gen_async_block`
- `gen_spawn`
- `gen_async_scope`
- `gen_select_await`
- `gen_comptime`
- `gen_array_comprehension`

**Support functions that exist only for AST codegen:**
- `gen_builtin_call` / `gen_builtin_static_call`
- `try_op_overload` (AST path — verify MIR has equivalent)
- `collect_captures` (AST path — verify MIR closure lowering)
- `static_receiver_type`
- `infer_type` / `inferExprType` (AST-based type inference)
- Any `expected_type` threading through AST emitters

**What stays:**
- `gen_function_mir` — the MIR codegen entry point
- `mir_emit_stmt` / `mir_emit_terminator`
- `mir_eval_rvalue` / `mir_eval_operand`
- `mir_build_bin_op` / `mir_str_concat`
- `mir_const_value` / `mir_place_ptr`
- All LLVM bridge calls
- `declare_function` — function declaration is shared
- `gen_module` — module-level orchestration (simplified)
- `gen_module_constant` — top-level constants
- `resolve_type` — type resolution is shared
- Type helpers, struct layout, enum layout
- All `wl_*` bridge wrappers

---

## Preconditions

Before deleting anything, verify these are true:

- [ ] All 200+ tests pass with MIR codegen as the only path.
- [ ] `make fixpoint` passes.
- [ ] `gen_function_dispatch` never falls through to `gen_function`
  in practice. Add a counter or log to confirm: zero AST fallbacks
  across the full test suite and self-compilation.
- [ ] No function in `src/*.w` (the compiler's own source) triggers
  AST fallback.

If any function still falls through to AST, that function's MIR
lowering is incomplete. Fix MIR lowering first, don't keep AST
as a crutch.

---

## Execution Order

One step at a time. Build and fixpoint after each step. Do not
batch.

### Step 1: Verify zero AST fallback

Add a hard assertion in `gen_function_dispatch`:

```
fn gen_function_dispatch(self: Codegen, fn_node: i32):
    let fn_sym = self.pool.get_data0(fn_node)
    let body_idx = self.mir_input.find_body(fn_sym)
    if body_idx >= 0:
        let body = self.mir_input.bodies.get(body_idx as i64)
        if self.mir_function_is_supported(body):
            self.gen_function_mir(fn_node, body)
            return
    // If we get here, a function has no MIR or MIR doesn't support it
    let fn_name = self.intern.resolve(fn_sym)
    panic("AST fallback triggered for: {fn_name}")
```

Run `make build` and `make fixpoint`. If the panic fires, fix the
MIR gap before proceeding. If it doesn't fire, every function goes
through MIR and the AST path is confirmed dead.

### Step 2: Remove `mir_function_is_supported`

Once step 1 proves every function goes through MIR, the support
check is unnecessary. All functions are supported. Simplify:

```
fn gen_function_dispatch(self: Codegen, fn_node: i32):
    let fn_sym = self.pool.get_data0(fn_node)
    let body_idx = self.mir_input.find_body(fn_sym)
    assert(body_idx >= 0, "no MIR body for function")
    let body = self.mir_input.bodies.get(body_idx as i64)
    self.gen_function_mir(fn_node, body)
```

Build. Fixpoint.

### Step 3: Delete `gen_function`

Remove the entire AST function codegen entry point. This is the
big function that dispatches to all the expression/statement/
control flow emitters. Removing it will cause compile errors
for every AST emitter it calls — that's expected and desired.

Build will fail. That's fine — proceed to step 4.

### Step 4: Delete AST expression emitters

Delete every `gen_expr`, `gen_bin_op`, `gen_call`, etc. that was
only reachable from `gen_function`. Work through the compile
errors from step 3. Each deleted function may reveal other
functions that were only called from it — delete those too.

Keep a running list of what you delete. If a function is called
from BOTH the AST and MIR paths, don't delete it — it's shared
infrastructure.

### Step 5: Delete AST control flow emitters

Delete `gen_if_expr`, `gen_while`, `gen_for`, `gen_match`,
`gen_loop`, etc. Same process — follow the compile errors.

### Step 6: Delete AST sugar emitters

Delete `gen_with_expr`, `gen_record_update`, `gen_pipeline`,
`gen_optional_chain`, etc. MIR desugars all of these before
codegen sees them.

### Step 7: Delete AST support functions

Delete `gen_builtin_call`, `static_receiver_type`,
`inferExprType`, `collect_captures` (AST path), and any
remaining functions that only existed to support the AST
codegen path.

### Step 8: Clean up Codegen struct

Remove any fields that were only used by the AST path:

- `expected_type` stack/threading
- `defer_stack` (MIR handles drops explicitly)
- `loop_stack` / `break_stack` (MIR has explicit break blocks)
- Any `HashMap` that tracked AST-specific state

### Step 9: Remove `mir_function_is_supported` infrastructure

Delete the operand checking functions, the rvalue checking
functions, and the MIR support classification logic. All of
it was gatekeeping for the AST fallback. With no fallback,
no gatekeeping needed.

### Step 10: Final validation

```bash
make build
make fixpoint
./scripts/run_tests.sh    # all tests pass
wc -l src/Codegen.w       # should be significantly smaller
```

---

## Expected Impact

**Lines removed:** Rough estimate 3,000-5,000 lines from
`Codegen.w`. The AST codegen path is the largest section of
the file. Removing it may cut the file nearly in half.

**Compile speed:** Fewer lines to compile in the compiler's own
source. The self-host chain gets faster.

**Bug surface:** Every codegen bug now has one place to look.
No more "is this the AST path or the MIR path?" debugging.

**Feature velocity:** New features only need MIR lowering +
MIR codegen. No need to implement anything in the AST path.

**DWARF:** Debug info instrumentation (the next task) only needs
to touch the MIR path. No wasted work.

---

## Risk Mitigation

**What if a test fails after deletion?**

The test was relying on AST codegen behavior that differs from
MIR codegen. This is a MIR bug, not a reason to keep AST.
Fix the MIR bug. Step 1 (panic on fallback) should catch these
before deletion begins.

**What if fixpoint breaks after deletion?**

The deletion changed some compile-time behavior (fewer functions
in the binary, different symbol order). Check if the break is
in the hash (benign — the compiler binary changed because code
was removed) or in behavior (real bug). If hash-only, rebuild
the seed. If behavioral, revert the last deletion step and
investigate.

**What if I need AST codegen back?**

You don't. But if you're worried, tag the commit before step 3.
`git tag pre-ast-removal`. You can always check it out. But
you won't need to — the MIR path handles everything. That's
what steps 1 and 2 prove before any deletion begins.

---

## Checklist

- [ ] Step 1: Panic on AST fallback — confirm zero triggers
- [ ] Step 2: Remove `mir_function_is_supported` gating
- [ ] Step 3: Delete `gen_function`
- [ ] Step 4: Delete AST expression emitters
- [ ] Step 5: Delete AST control flow emitters
- [ ] Step 6: Delete AST sugar emitters
- [ ] Step 7: Delete AST support functions
- [ ] Step 8: Clean up Codegen struct fields
- [ ] Step 9: Remove MIR support checking infrastructure
- [ ] Step 10: Final validation — build, fixpoint, all tests pass
- [ ] Update CONTRIBUTING.md: remove references to AST codegen path
- [ ] Update architecture docs: pipeline is MIR-only
- [ ] Celebrate: Codegen.w is half the size it was