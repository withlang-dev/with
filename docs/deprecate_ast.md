# Remove AST Codegen: MIR-Only Pipeline

## Goal

Delete the AST codegen path from `src/Codegen.w`. The compiler
goes through MIR for all functions, no exceptions, no fallback.

```
Source → Lex → Parse → Resolve → Sema → MIR → LLVM IR → Binary
```

---

## Current State (March 2026)

MIR does NOT handle everything. Discovery:

- **1,217 functions** have `lowering_failed` set in MirLower.
- Only functions passing `mir_function_is_supported` go through MIR.
- The rest silently fall back to AST codegen.
- Fixpoint holds because the SAME subset goes through MIR in
  both stage2 and stage3. AST handles the rest consistently.
- 225/225 tests pass, but most test functions compile through
  AST, not MIR.

**The blocker is MirLower, not MIR codegen.** The codegen is
correct for what it receives. MirLower can't convert most
functions from AST to MIR.

---

## Revised Plan

### Phase 0: Audit MirLower Gaps (do first)

Categorize the 1,217 failing functions by pattern.

Add instrumentation to `src/MirLower.w` that logs the AST node
kind that caused `lowering_failed` to be set. The failures will
cluster into a few categories. Expected top categories:

1. **Complex match expressions** — nested patterns, guards,
   destructuring in match arms
2. **Closures** — capture lowering, closure body as expression
3. **String interpolation** — desugaring to concat chains
4. **Iterator sugar** — for-in with method iterators
5. **Pipeline operator** — `|>` desugaring
6. **Optional chaining** — `?.` desugaring
7. **Async constructs** — spawn, await, async scope
8. **Method calls with complex receivers** — chained access
9. **Operator overloading** — trait method dispatch
10. **Let-else** — `let x = expr else: fallback`

Track progress with a counter:

```bash
make build 2>&1 | grep "FATAL" | wc -l
# Before: 1,217. Target: 0.
```

### Phase 1: Fix MirLower One Category at a Time

For each category, in order of frequency:

1. Pick the most common failure pattern.
2. Add the lowering code in `src/MirLower.w`.
3. `make build` — confirm fewer failures.
4. `make fixpoint` — confirm no regressions.
5. `./scripts/run_tests.sh` — confirm all pass.
6. Repeat until category is empty.

Do not batch. One pattern at a time. The compiler is
self-hosting — every change compiles through itself.

### Phase 2: Remove `mir_function_is_supported`

Once Phase 1 reaches 0 failures:

1. Remove the `mir_function_is_supported` check.
2. Route all functions unconditionally through MIR.
3. `make build` — no errors.
4. `make fixpoint`.
5. `./scripts/run_tests.sh` — all pass.

### Phase 3: Add Fatal Assertion

Replace AST fallback with a hard error:

```
fn gen_function_dispatch(self: Codegen, fn_node: i32):
    let fn_sym = self.pool.get_data0(fn_node)
    let body_idx = self.mir_input.find_body(fn_sym)
    assert(body_idx >= 0, "no MIR body for: " ++ self.intern.resolve(fn_sym))
    let body = self.mir_input.bodies.get(body_idx as i64)
    self.gen_function_mir(fn_node, body)
```

Build. Fixpoint. Full test suite. If anything panics, it's a
MirLower gap that Phase 1 missed. Fix it before proceeding.

### Phase 4: Delete AST Codegen

Only after Phase 3 proves zero AST usage.

```bash
git tag pre-ast-removal
```

Delete in order, building after each step:

1. `gen_function` — the AST entry point
2. AST expression emitters (`gen_expr`, `gen_bin_op`, `gen_call`,
   `gen_method_call`, `gen_field_access`, `gen_index`, `gen_cast`,
   `gen_closure`, `gen_string_interp`, `gen_pipeline`, `gen_range`,
   `gen_array_lit`, `gen_struct_lit`, `gen_tuple`, `gen_grouped`)
3. AST statement emitters (`gen_let_binding`, `gen_assign`,
   `gen_return`, `gen_defer`, `emit_defers`, `gen_block`,
   `gen_block_discard`)
4. AST control flow (`gen_if_expr`, `gen_while`, `gen_loop`,
   `gen_for`, `gen_for_range`, `gen_for_iter`, `gen_for_vec`,
   `gen_match`, `gen_break`, `gen_continue`)
5. AST sugar (`gen_with_expr`, `gen_record_update`,
   `gen_optional_chain`, `gen_let_else`, `gen_variant_shorthand`,
   `gen_await`, `gen_async_block`, `gen_spawn`, `gen_async_scope`,
   `gen_select_await`, `gen_comptime`, `gen_array_comprehension`)
6. AST support (`gen_builtin_call`, `gen_builtin_static_call`,
   `try_op_overload`, `collect_captures`, `static_receiver_type`,
   `infer_type`, `inferExprType`)
7. Codegen struct fields only used by AST (`expected_type`,
   `defer_stack`, `loop_stack`, `break_stack`)
8. `mir_function_is_supported` and all gating infrastructure

Follow compile errors — they tell you what else to delete. If a
function is called from both AST and MIR paths, keep it.

### Phase 5: Final Validation

```bash
make build
make fixpoint
./scripts/run_tests.sh      # all pass
wc -l src/Codegen.w         # expect 3,000-5,000 lines removed
```

Update seed:

```bash
cp out/bin/with-stage2 src/main
cp out/bin/with-stage2 ~/.local/bin/with
```

---

## What NOT To Do

- **Don't remove AST codegen before MirLower is complete.**
  The agent tried this. 1,217 functions broke.

- **Don't bypass `mir_function_is_supported` as a shortcut.**
  The check protects against real MirLower gaps. Remove it
  only after the gaps are fixed.

- **Don't batch MirLower fixes.** One pattern at a time. Build
  and fixpoint after each.

- **Don't fix MIR codegen for patterns MirLower can't produce.**
  The codegen is fine. The lowering is the problem.

---

## Progress Tracking

```
Phase 0: Audit
  [ ] Add lowering failure instrumentation to MirLower
  [ ] Categorize 1,217 failures by AST node kind
  [ ] Rank categories by frequency
  [ ] Document top 10 categories with counts

Phase 1: Fix MirLower (target: 0 failures)
  Current failure count: 1,217
  [ ] Category 1: _____ (count: _____)
  [ ] Category 2: _____ (count: _____)
  [ ] Category 3: _____ (count: _____)
  [ ] Category 4: _____ (count: _____)
  [ ] Category 5: _____ (count: _____)
  [ ] ...remaining categories...

Phase 2: Remove support check
  [ ] Remove mir_function_is_supported
  [ ] Build succeeds with no fallbacks
  [ ] Fixpoint holds

Phase 3: Assert no AST usage
  [ ] Replace fallback with assertion
  [ ] Build succeeds
  [ ] Fixpoint holds
  [ ] Full test suite passes

Phase 4: Delete AST codegen
  [ ] Tag: pre-ast-removal
  [ ] Delete gen_function
  [ ] Delete expression emitters
  [ ] Delete statement emitters
  [ ] Delete control flow emitters
  [ ] Delete sugar emitters
  [ ] Delete support functions
  [ ] Clean up Codegen struct
  [ ] Delete gating infrastructure

Phase 5: Validate
  [ ] make build
  [ ] make fixpoint
  [ ] ./scripts/run_tests.sh — all pass
  [ ] Update seed
  [ ] Update CONTRIBUTING.md
  [ ] Codegen.w line count: _____
```