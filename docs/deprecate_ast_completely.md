# MIR CK_FN Call Support: Method Key Bridge + Self-Param Convention

Ship as one atomic commit. Neither half works alone.

## Current State

- 177 MIR-dispatched, 1143 lowering-failed, 258 codegen-unsupported
- CK_FN gate disabled (`return false` in `mir_operand_is_supported`)
- Prerequisites landed, seed updated, fixpoint verified

## The Two Problems

### Problem A: Sym format mismatch

```
MirLower: resolve_method_callee_sym → method_key ($m$<type>|<method>)
         → stored in CK_FN constant

Codegen:  declare_function → fn_values[Type.method] = llvm_fn
          mir_const_value  → fn_values[$m$type|method] → NOT FOUND → undef → crash
```

### Problem B: Self-param calling convention

```
declare_function: fn Vec.push(self: Vec, elem: i32) → LLVM (ptr, i32) → void
MIR codegen:      evaluates receiver → loads Vec struct value
                  callee expects ptr → type mismatch → "wrong argument type"
```

AST codegen handles this via `fn_ref_param_starts` + `get_mutable_receiver_ptr`.
MIR codegen never checks `fn_ref_param_starts`.

---

## Fix A: Method Key Registration

**File: `src/Codegen.w`**

- [x] **A1.** Compute `method_key_sym` early in `declare_function`
- [x] **A2.** Register method_key in `fn_values` / `fn_fn_types`
- [x] **A3.** Register ref_param / dyn_param under method_key
- [ ] **A4.** Re-enable CK_FN gate — all 182 tests pass with `WITH_CK_FN=1`, ready to flip

---

## Fix B: Ref-Param-Aware Call Emission

**File: `src/Codegen.w`**

- [x] **B1.** Add `is_ref_param` helper
- [x] **B2.** Add `mir_try_place_ptr_for_ref` helper
- [x] **B3.** Modify `mir_emit_call_term` arg loop with ref-param handling
- [ ] **B4.** Simplify `mir_eval_call_operand` (remove redundant `is_struct_val` block)

---

## Fix C: MIR Codegen Correctness (landed separately)

- [x] **C1.** Pool ID translation for CK_FN constants (sema pool → codegen pool)
- [x] **C2.** Mixed-width binop: coerce to wider type, never truncate (`mir_build_bin_op`)
- [x] **C3.** Array `.len()` method in AST codegen (`gen_method_call`)
- [x] **C4.** Regular enum variant construction (`gen_field_access` + `gen_method_call`)
- [x] **C5.** Async function default return type: `i32` not `void` (`declare_async_function`)

---

## Remaining: Re-enable CK_FN (A4)

All 182 non-skipped tests pass with `WITH_CK_FN=1` forced on.
The `WITH_CK_FN` env var gate is in `mir_operand_is_supported`.

Next step: flip the gate permanently and fix the self-host chain.

1. Change `mir_operand_is_supported` to `return ck == CK_FN` (remove env var check)
2. Build — self-host chain may expose new MIR codegen bugs in compiler functions
3. Fix any self-host failures
4. Fixpoint + full test suite
5. Update seed

Do NOT binary-search crashes one at a time. Use IR diff for systematic debugging.

---

## Verification

```bash
make build
./out/bin/with-stage2 build src/main.w -o /tmp/with-stage3   # no crash
cp out/bin/with-stage2 src/main && cp out/bin/with-stage2 ~/.local/bin/with
make fixpoint
./scripts/run_tests.sh
```

## Expected Impact

All ~374 MIR-supported functions compile and run correctly, including
method calls with struct receivers. 1143 lowering-failed and 258
codegen-unsupported unchanged (separate problems: expr_type coverage,
NK_RANGE, missing RK_*/TK_*).
