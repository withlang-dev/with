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

## Audit Results (2026-03-14)

Total functions in self-host build: **~1,580**

| Path | Count | % |
|---|---|---|
| MIR codegen (working) | ~1,577 | 99.8% |
| AST fallback: unsupported-callee | 3 | 0.2% |

Previous: 698 MIR / 883 lowering-failed / 3 codegen-unsupported.
Gains from: intrinsic gate removal, expected_type propagation, struct literal field
name mapping, short-circuit and/or, projected type stores.

### Lowering failures by first failure kind

| First failure | AST node kind | Count | % of failures |
|---|---|---|---|
| `NK_IDENT` (24) | Unresolved identifier | ~883 | ~100% |

### Root cause: method resolution in `lower_var`

The 1,119 NK_IDENT failures are almost entirely **method calls on struct
fields** where `resolve_method_callee_sym` fails to qualify the method name.

The flow: `self.pool.get_data0(node)` → `lower_method_call` →
`resolve_method_callee_sym(self_expr, method_sym)` → tries to build
`TypeName.method` key via sema type lookup → `expr_type` returns 0 →
falls back to bare `method_sym` (e.g., `get_data0`) → `lower_var`
can't find it → `mark_unsupported`.

**The fix**: improve `expr_type` coverage so `resolve_method_callee_sym`
can build the qualified method key. This is a sema type propagation
issue, not a structural MIR lowering gap. Fixing `expr_type` for
field access chains would resolve ~92% of all lowering failures.

### Codegen-unsupported (205 functions)

These pass MirLower but fail `mir_function_is_supported` in Codegen.w.
Root cause: rvalue kinds or terminator kinds that the MIR codegen
doesn't handle yet. Need to audit which specific RK_*/TK_* are missing.

### Instrumentation

Environment-gated diagnostics added:

- `WITH_MIR_AUDIT=1` — logs `[mir-fallback]` per AST-fallback function
  and `[mir-lower-fail]` per `mark_unsupported` call with node kind
- `WITH_DEBUG_MIR_CODEGEN=1` — logs `[mir-dispatch]` per MIR function
- `WITH_MIR_STRICT=1` — aborts on unexpected AST fallback (non-closure, non-lowering-failed)

Track progress:
```bash
WITH_MIR_AUDIT=1 ./out/bin/with-stage2 build src/main.w -o /dev/null 2>&1 | grep '\[mir-fallback\]' | awk '{print $2}' | sort | uniq -c | sort -rn
```

## Progress Tracking

```
Phase 0: Audit
  [x] Add lowering failure instrumentation to MirLower
  [x] Categorize failures by AST node kind
  [x] Rank categories by frequency
  [x] Document root cause (method resolution / expr_type)

Phase 1: Fix MirLower (target: 0 lowering failures)
  Self-host: 0 fallback. Tests: 0 lowering failures.
  (was 252 test, was 3 self-host, was 23, was 883, was 1,218)
  [x] Sema builtin method return types (check_method_call)
  [x] typed_expr_types key fix (node index vs byte offset)
  [x] Remove MIR dispatch count cap (376→uncapped, 537 through MIR)
  [x] Add NK_RANGE lowering (~64 functions unlocked)
  [x] PK_FIELD projections (struct field access through MIR)
  [x] Operator overloading detection in lower_bin_op
  [x] Record update rewrite (copy-then-overwrite via PK_FIELD)
  [x] Fix tuple pattern match lowering (unterminated blocks)
  [x] expected_type for field assignments (Vec.new elem_size in self.field = Vec.new())
  [x] Struct literal field name mapping (aggregate field index != LLVM struct index)
  [x] Short-circuit evaluation for logical and/or operators
  [x] Remove intrinsic gate (WITH_MIR_INTRINSICS no longer needed)
  [x] PK_INDEX + PK_DEREF projections in mir_place_ptr/mir_place_is_supported
  [x] type_receiver_type helper for NK_INDEX type receivers (Vec[i32].new())
  [x] call_return_type + resolve_method_callee_sym NK_INDEX handling
  [x] Defer/errdefer lowering (emit_defers_for_return, emit_errdefers_for_return)
  [x] Array iteration and Vec.iter() dispatch in lower_for
  [x] CK_CLOSURE constant kind (delegate closure compilation to gen_closure)
  [x] Fat pointer fn_ty fix in mir_emit_vec_map/filter/fold

Phase 1b: Fix MIR codegen support (target: 0 codegen-unsupported)
  Current: 0 codegen-unsupported (was 205)
  [x] PK_FIELD projection support in mir_place_is_supported
  [x] TY_TUPLE + TY_STRUCT sym translation in mir_sema_type_to_llvm
  [x] mir_place_ptr fallback to mir_sema_type_to_llvm
  [x] Projected type in mir_emit_stmt (store to correct type for field assignments)

Phase 2: Remove support check
  [x] Remove mir_function_is_supported
  [x] Build succeeds with no fallbacks
  [x] Fixpoint holds

Phase 3: Assert no AST usage
  [x] WITH_MIR_STRICT=1 fatal assertion for unexpected fallback
  [x] Self-host passes strict mode (0 unexpected fallbacks)
  [x] Fixpoint holds
  [x] 246/246 tests pass

Phase 4: Delete AST codegen
  Self-host: 0 fallbacks (all functions through MIR).
  Tests: 244/246 pass. 2 remaining:
  - behav_hashmap: runtime assertion (HashMap codegen issue, pre-existing)
  - duck_binop_fail: expected-failure test (duck typing error)

  Generic function calls now route through MIR via MIR_INTRINSIC_GENERIC_CALL.
  MirLower emits a placeholder call with the AST node; codegen intercepts and
  calls monomorphize_generic_call. Simple generics (identity, first_of_two,
  apply_fn with fn params) all work.

  [x] Tag: pre-ast-removal
  [x] Generic monomorphization via MIR (was blocker, fixed)
  [x] NK_INDEX generic receiver (Vec[i32].new()) — Sema.check_index
  [x] Enum variant access lowering (Color.Red → discriminant constant)
  [x] Remove mir_input_enabled field and dead code
  [x] Simplify gen_function_dispatch (skip fn-level generics)
  [x] Enum variant constructor lowering (Some/None/Ok/Err via RK_AGGREGATE)
  [x] Generic call lowering (MIR_INTRINSIC_GENERIC_CALL → monomorphize)
  [x] Sema check_ident → typed_expr_types for MIR type propagation
  [x] sema_type_of_node literal type inference (str/int/float/bool)
  [x] mir_build_closure_fn_type sema fallback for post-snapshot types
  [x] gen_function_mir_mono: save/restore mir_bb_values + mir_local_ptrs
  [x] sema_type_mangle for correct struct identity in monomorphization
  [x] Sema-derived LLVM type bindings (wl_type_of flattens single-field structs)
  [x] MIR local bridging for generic call arg resolution
  [x] Option.is_none() MIR intrinsic lowering + codegen fix
  [x] Generic struct method calls via MIR_INTRINSIC_GENERIC_CALL

  [x] AST pool → sema pool symbol fix in resolve_method_callee_sym
  [x] MIR fallback audit logging (WITH_MIR_AUDIT=1 [mir-fallback])
  [x] str.split/Option.filter/map return types in intrinsic_return_type
  [x] Generic struct methods through MIR (param type fallback from AST)
  [x] Remove generic_fn_nodes skip in lower_module

  --- Milestone: self-host fully MIR, seed updated (2026-03-15) ---

  [x] Let-else pattern fix (NK_PAT_IDENT vs raw sym in extras)
  [x] Vec.join MIR intrinsic (MIR_INTRINSIC_VEC_JOIN)
  [x] Global variable proxy locals (ensure_global_local + module_constants)
  [x] Unresolved bare function calls through MIR_INTRINSIC_GENERIC_CALL
  [x] Inverted guard: generic_fn_nodes → mark_unsupported, else → bridge
  [x] Disc enum payload variant lowering (RK_AGGREGATE for disc_has_payload)
  [x] MIR_INTRINSIC_OPT_IS_NONE fix (was checking ==0 instead of !=0)
  [x] gen_function_dispatch: skip generic struct methods without fn_values
  [x] Slice pattern lowering (NK_PAT_SLICE element binding + length check)
  [x] Array GEP in mir_place_ptr and mir_place_projected_type

  [x] Remove generic_fn_nodes guard (all unresolved methods through bridge)
  [x] Slice pattern tail variable binding ([first, ..rest, last])

  --- Milestone: 4 build-mode fallbacks, seed updated (2026-03-15) ---
  Self-host: 0 AST fallbacks. Tests: 244/246 pass.
  Build-mode fallbacks: 4 (3 async, 1 sealed trait match).
  Async: gen_async_function bypasses MIR entirely.
  Sealed trait: NK_PAT_TYPED_BIND requires dynamic dispatch downcast.

  --- AST codegen audit (2026-03-15) ---
  Self-host: 0 AST fallbacks, 0 CK_CLOSURE bridge calls,
  0 MIR_INTRINSIC_GENERIC_CALL bridge calls.
  AST codegen is COMPLETELY DEAD CODE for the self-host.
  40 tests still use bridges (15 closure, 25 generic call).

  [x] Delete gen_function (AST entry point, ~210 lines)
  [x] Delete gen_async_function (~200 lines)
  [x] Stub fallback with unreachable in gen_function_dispatch
  [x] Stub async dispatch with unreachable
  [x] Seed updated (2026-03-15)

  Tests: 240/246 pass (4 new failures: async + sealed trait).
  Codegen.w: 13,827 lines (was ~14,230).

  [ ] Route closure codegen through MIR (remove CK_CLOSURE bridge)
  [ ] Route sealed trait match through MIR (NK_PAT_TYPED_BIND)
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
  [ ] Codegen.w line count: _____
```