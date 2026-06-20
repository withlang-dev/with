# A5 Vec Drop Handoff

This is the transition document for the next agent taking over A5. Every claim
below is tagged as `[verified-by-test]`, `[inferred]`, `[open]`, or
`[maintainer's-call]`.

## Status

- A5 is **not done**. `[verified-by-test]`
- The preserved wide-audit branch is `wip-a5-wide-audit` at commit `b6f05eabdd47a99d350ecc24ae7c6d2571a1ca36`. `[verified-by-test]`
- The A5 behavior tests still crash under the wide-audit attempt. `[verified-by-test]`
- The wide-audit approach below was abandoned and must not be resumed as the implementation base. `[maintainer's-call]`
- `main` is the clean reset point; recover individual snippets from `wip-a5-wide-audit` only after reading this document. `[verified-by-test]`

## Do Not Resume The Wide Path

- Do not make every `Vec[T]` needs-drop. `[maintainer's-call]`
- Do not keep adding `memcpy`/`memset` take-store-replace helpers to preserve POD `Vec` headers across local scopes. `[maintainer's-call]`
- Do not keep converting POD state holders such as `MirBlockStack` and `MirValueScan` into raw-pointer handle wrappers to dodge copied `Vec[i32]` cleanup. `[maintainer's-call]`
- Do not keep converting by-value `Vec[i64]` call-argument plumbing into borrowed `&Vec[i64]` parameters to chase crashes. `[maintainer's-call]`
- The reason is that the wide flip retroactively made POD compiler bookkeeping vectors owning values, which breaks the compiler's existing "Vec is a cheap copyable handle" assumption in many unrelated backend and frontend paths. `[verified-by-test]`
- Chasing those POD crashes is not A5; A5 is element drop for `Vec` whose element type itself needs drop. `[maintainer's-call]`

## Root Cause / Negative Knowledge

- The wide attempt changed `Sema.type_needs_drop` so any std `Vec` became a transitive Drop type. `[verified-by-test]`
- With that gate, POD compiler vectors such as `Vec[i32]` and `Vec[i64]` started being dropped as owning containers. `[verified-by-test]`
- The compiler pervasively copies those POD `Vec` headers as cheap handles, so adding universal `Vec` ownership turns those copies into double-free and invalid-free hazards. `[verified-by-test]`
- The failures surfaced in sequence across unrelated state because the shared root was the universal POD `Vec` ownership flip, not independent bugs at each site. `[inferred]`
- Concrete crash/fix sites chased in the WIP diff were:
  - Codegen type bindings: `Codegen.type_binding_syms: Vec[i32]` and `Codegen.type_binding_types: Vec[i64]`, patched by `CodegenTypeBindingState` and take/restore helpers in `src/Codegen.w`. `[verified-by-test]`
  - Loop, scope, defer, errdefer, tailrec, and MIR basic-block state in `src/CodegenTraits.w` and `src/CodegenDispatch.w`, mostly `Vec[i32]`/`Vec[i64]`, patched by take/replace helpers. `[verified-by-test]`
  - `MirBlockStack` and `MirValueScan` in `src/CodegenDispatch.w`, both POD `Vec[i32]` backed, patched into raw-pointer handle wrappers plus `@[link_name]` runtime calls. `[verified-by-test]`
  - `Codegen.build_call_fn_value` argument vectors, POD `Vec[i64]`, patched from by-value to `&Vec[i64]` across many call sites. `[verified-by-test]`
  - `AstPoolState.kinds` and neighboring parser pool vectors, including POD `Vec[i32]`, where a copied aggregate temp caused an invalid free once Vec drop was enabled. `[verified-by-test]`
  - Frontend/ZCU import cleanup reached `with_vec_free` while running an A5 behavior test under stage2; the exact vector header at that final stop was not identified before debugging was halted. `[open]`
- The load-bearing fact for the concrete identified failures is that the vectors were POD vectors (`Vec[i32]` or `Vec[i64]`), not `Vec[str]` or `Vec[Drop]`. `[verified-by-test]`
- The final frontend/ZCU crash is expected to be another POD-vector ownership consequence, but that exact header was not proven before the stop. `[inferred]`
- Do not restart the one-probe-per-rebuild loop; if the narrow gate still crashes, instrument the whole ownership/pool picture in one run and then use `lldb`. `[maintainer's-call]`

### Repro Commands

- Reproduce the wide branch stage2 used for the crash work:

```sh
git switch wip-a5-wide-audit
with build :clang-bridge-object
```

`with build :clang-bridge-object` reached stage2 successfully on the WIP after the aggregate-temp move fix. `[verified-by-test]`

- Reproduce the A5 behavior crash under that stage2:

```sh
./out/stage/bin/with-stage2 run test/behavior/behav_drop_vec_elements.w
./out/stage/bin/with-stage2 run test/behavior/behav_mut_self_field_assign_vec_tail.w
./out/stage/bin/with-stage2 run test/behavior/behav_mut_self_vec_owner_receiver.w
```

Those tests hit `panic: invalid free: pointer is not an allocated payload start` under the wide branch stage2. `[verified-by-test]`

- LLDB command used for the final frontend/ZCU crash:

```sh
lldb --batch \
  -o "target create ./out/stage/bin/with-stage2" \
  -o "breakpoint set --name with_panic_core" \
  -o "process launch -- run test/behavior/behav_drop_vec_elements.w" \
  -o "bt all" \
  -o "register read x0 x1 x2 x3 x19 x20 x21 x22 x23 x24 x25 x26"
```

The stack stopped at `with_panic_core`, through `with_vec_free` in
`rt/rt_core.w`, then `Zcu.parse_imported_file_frontend` and
`Zcu.process_imports_frontend`. `[verified-by-test]`

## Chosen Approach

- The next attempt is maintainer-directed: narrow the drop gate from "is std Vec" to "is std Vec and the element type needs drop". `[maintainer's-call]`
- In `Sema.type_needs_drop`, `Vec[i32]`, `Vec[i64]`, and other POD-element Vecs must remain non-drop. `[maintainer's-call]`
- `Vec[str]`, `Vec[DropType]`, and `Vec` whose element recursively needs drop are the real A5 surface. `[maintainer's-call]`
- Rationale: every concrete crash chased above came from POD `Vec` state; narrowing makes those vectors non-drop and removes the need for the wide audit sprawl. `[inferred]`
- After narrowing, reset to clean `main` and re-apply only the keepers below from `wip-a5-wide-audit`; do not continue the WIP branch itself. `[maintainer's-call]`
- After re-applying the narrow keepers, rebuild and rerun the A5 subset before touching A6/A8. `[maintainer's-call]`

## Keep Vs Discard

### Keep

- `src/MirLower.w`, `MirBuilder.consume_moved_operand`: type-aware consumption of `OK_COPY` or `OK_MOVE` operands when the source type needs value drop. `[verified-by-test]`
- `src/MirLower.w`, aggregate literal lowering: struct, tuple, and array literals returning `OK_MOVE` when the aggregate type needs drop. `[verified-by-test]`
- The aggregate-temp move fix above cleared the `AstPoolState.kinds` invalid-free enough for `with build :clang-bridge-object` to pass stage2 on the WIP. `[verified-by-test]`
- `src/MirLower.w` and `src/SemaCheck.w`: `Vec.push`, `Vec.clear`, and `Vec.set_i32` should be treated as `Unit`-returning mutators. `[inferred]`
- `src/MirLower.w` and `src/SemaCheck.w`: `Vec.remove` should return the removed element type `T`, and `Vec.pop`/`remove` must materialize returned elements so moved values can drop later exactly once. `[inferred]`
- `src/Codegen.w`, `Codegen.sema_symbol_text`: removal of the stale `sema_symbol_texts` cache path should be kept; one coherent Sema/pool should be used instead of cached symbol text snapshots. `[inferred]`
- `rt/rt_core.w`, `with_vec_free`: the runtime helper that frees a Vec buffer is a keeper for Drop-element Vecs. `[inferred]`
- `src/CodegenDispatch.w`, `mir_emit_vec_element_drops_ptr`, `mir_emit_vec_free_ptr`, and `mir_emit_drop_vec_ptr`: the LLVM backend element-drop loop and buffer free are keepers once the gate is narrowed. `[inferred]`
- `src/CodegenDispatch.w`, `mir_emit_vec_remove_value` plus `VEC_REMOVE` and `VEC_POP` materialization: keep the shape that moves the removed/popped element into the result before compacting the vector. `[inferred]`
- `src/CodegenDispatch.w`, `VEC_CLEAR`: keep the shape that drops live elements before clearing when the element type needs drop. `[inferred]`
- `src/CCodegen.w`: C backend parity for `Vec.remove`/`clear`/`pop` exists partially in the WIP, but it was not proven by the stopped run. `[open]`
- The six rewritten tests in the WIP branch should be restored first, before implementation, and kept phase-tagged. `[maintainer's-call]`

### Discard

- `src/Sema.w`, `prepare_backend_codegen_copy_owned` and `prepare_backend_codegen_copy`: discard the broad backend Sema cloning and POD-table cloning path. `[maintainer's-call]`
- `src/Sema.w`, the `with_memcpy`/`with_memset` overwrite helpers for many Sema `Vec` fields: discard under the narrow Vec gate. `[maintainer's-call]`
- `src/Codegen.w`, `CodegenTypeBindingState`, `codegen_take_i32_vec`, `codegen_take_i64_vec`, `codegen_store_*`, and `codegen_replace_*`: discard the take/store/replace discipline for POD type-binding vectors. `[maintainer's-call]`
- `src/CodegenTraits.w` and `src/CodegenDispatch.w`, loop/scope/defer/errdefer/tailrec/MIR-BB take/replace snapshots: discard unless the narrowed gate independently proves a Drop-element Vec at that exact site. `[maintainer's-call]`
- `src/CodegenDispatch.w`, `MirBlockStack` and `MirValueScan` raw-pointer state rewrites plus `@[link_name]` externs: discard under the narrow gate. `[maintainer's-call]`
- `src/Codegen.w` and `src/CodegenDispatch.w`, `build_call_fn_value(... args: &Vec[i64] ...)` and related monomorphize by-value-to-borrow conversions: discard under the narrow gate. `[maintainer's-call]`
- `src/Mir.w`, broad MIR module/body cloning for backend ownership: discard unless a narrowed Drop-element path proves it is still needed. `[maintainer's-call]`
- `src/compiler/Backend.w`, debug pool-flow prints and snapshot scaffolding: discard. `[maintainer's-call]`
- `src/compiler/Compilation.w` and `src/CCodegen.w`, wide borrow/snapshot rewrites: discard unless the narrowed C backend path proves a specific need. `[maintainer's-call]`

All discarded code is recoverable from `wip-a5-wide-audit` at
`b6f05eabdd47a99d350ecc24ae7c6d2571a1ca36`. `[verified-by-test]`

## Open Questions

- Does narrowing the Vec drop gate fully clear the frontend/ZCU invalid-free, or are there copy-shared `Vec[str]` or `Vec[Drop]` sites still needing a real move fix or scoped snapshot? `[open]`
- Can the backend snapshot shrink to only fields whose element type needs drop, or can it be removed entirely once POD Vecs stop dropping? `[open]`
- Does the C backend need the same Vec element-drop/remove/pop work immediately for fixpoint, or can LLVM backend correctness land first with a loud C backend gap? `[open]`
- Does `behav_drop_vec_elements.w` still expose a distinct `clear`/`remove`/`pop` semantic issue after the gate is narrowed? `[open]`

## Maintainer's Calls

- The wide flip where every `Vec` frees its buffer is a separate deliberate project, not part of A5. `[maintainer's-call]`
- A5 is limited to Vecs whose elements need drop. `[maintainer's-call]`
- A6 nested aggregate-in-struct-field drop propagation remains its own phase. `[maintainer's-call]`
- A7 wildcard/discard aggregate element drop remains its own phase. `[maintainer's-call]`
- A8 precise partial-move tracking remains its own phase. `[maintainer's-call]`
- #604 remains Eric's language-design call for `[]mut T` versus `VecRange`. `[maintainer's-call]`

## Durable Pointers And Spec

- WIP salvage branch: `wip-a5-wide-audit`. `[verified-by-test]`
- WIP salvage commit: `b6f05eabdd47a99d350ecc24ae7c6d2571a1ca36`. `[verified-by-test]`
- `out/project-state.md` is stale local scratch and still describes "reset then reimplement"; do not treat it as current truth. `[verified-by-test]`
- Broader durable phase state is in `docs/phase_8_handoff.md`. `[verified-by-test]`
- A5 test files to restore from the WIP:
  - `test/behavior/behav_drop_vec_elements.w`: expected count `8`. `[verified-by-test]`
  - `test/behavior/behav_mut_self_field_assign_vec_tail.w`: expected count `2`. `[verified-by-test]`
  - `test/behavior/behav_mut_self_vec_owner_receiver.w`: expected count `1`. `[verified-by-test]`
- A6/A8 tests to restore but not gate A5 on:
  - `test/behavior/behav_drop_struct_field_move_reinit.w`: expected count `4`. `[verified-by-test]`
  - `test/compile_errors/err_use_after_move_struct_field.w`: expected diagnostic contains `use of moved value`. `[verified-by-test]`
  - `test/compile_errors/err_use_after_move_vec_into_struct_field.w`: expected diagnostic contains `use of moved value`. `[verified-by-test]`
- Only the A5 subset should go green from the A5 fix; do not scope A5 outward to chase the A6/A8 reds. `[maintainer's-call]`
- Before any stage build, source-check the likely outcome with greps, MIR dumps, or single-file `check` runs. `[maintainer's-call]`
- If a build is needed, state the question and what each possible outcome means before running it. `[maintainer's-call]`
- Never destroy dirty WIP without a recoverable branch first. `[maintainer's-call]`
- Do not use `git stash`. `[maintainer's-call]`
