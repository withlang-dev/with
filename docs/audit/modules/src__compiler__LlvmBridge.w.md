# Audit: src/compiler/LlvmBridge.w @ 450733e5

Commit: 450733e5 (verified via git rev-parse in workspace /home/shawn/workspace2/with)
Module lines: 1648 (wc -l). Read: lines 1-1648 (FULLY READ this pass).
Mode: READ ONLY for compiler sources. No issues filed.

## Targets traced
- T13 ownership/drop: LLVM handle lifecycle (context/module/builder/target-machine/DIBuilder/buffers/messages), dispose coverage, alloc/free balance on all emission paths.
- T15 migration fidelity: hardcoded LLVM-22 enum constants vs system/bundled headers, struct layouts (WithVec), enum mappings (ordering, RMW op, callconv).
- T22 spec conformance: silent truncations/defaults, platform agreement (native-target init set, triple override), unsupported-path contracts.

## Findings
1. src/compiler/LlvmBridge.w:955 | severity: medium | target: T15 | probe: RAN (header cross-check vs LLVM 22)
   wl_cc_x86_thiscall() returns 33, but LLVM 22 defines X86_ThisCall = 70
   (llvm/IR/CallingConv.h:122; llvm-c/Core.h LLVMX86ThisCallCallConv = 70;
   bundled toolchain is .deps/llvm-22.1.6-linux-x86_64, so the header claim holds
   for the linked LLVM). CONFIRMED wrong constant. Live caller chain in REGEX
   mode: src/Codegen.w:5468 resolve_callconv("thiscall") returns it, and
   src/compiler/ClangBridge.w:1530 maps CXCallingConv_X86ThisCall -> "thiscall",
   so a cimported __thiscall function gets convention 33 (an unrelated slot)
   instead of 70. Blast radius is narrow (thiscall only exists on x86 Windows),
   but the path is reachable, not latent. Refutation attempted: checked whether
   33 could be intentional (legacy LLVM numbering) — LLVM has used 70 for
   ThisCall across versions; 33 is simply wrong. Adjacent (NOT this module):
   Codegen.w:5470 maps "vectorcall" -> wl_cc_x86_fastcall() (65) while
   X86_VectorCall = 80 (CallingConv.h:163); the bridge has no vectorcall
   accessor, so that mapping gap lives in Codegen.w.
2. src/compiler/LlvmBridge.w:1174-1181 | severity: low | target: T13 | probe: RAN (code-path read + caller search)
   wl_get_fn_param_type computes `actual_count` capped at 128 but NEVER USES it:
   LLVMGetParamTypes (count-blind sink, declared :324) is called with the full
   `count` into a 128-slot stack buffer, and `params[index]` is indexed by the
   uncapped index. A function type with >128 params would cause a stack buffer
   OVERWRITE plus an OOB read. CONFIRMED latent defect by reading; unreachable
   in-repo (all callers in Codegen.w:1562,1594,4972,6464-6465 pass indices 0/1/
   small; no >128-param function exists in-repo or in practice). The dead
   `actual_count` binding shows the guard was intended but not wired up.
3. src/compiler/LlvmBridge.w:1321 vs src/Codegen.w:1077-1081,1146-1148 | severity: low | target: T13 | probe: RAN (REGEX caller search)
   wl_di_dispose_builder has ZERO in-repo callers (definition only). Codegen
   creates the DIBuilder (Codegen.w:1121), finalizes it (1148), and deinit
   disposes builder/module/context/target-machine (1078-1081) but never the
   DIBuilder. CONFIRMED one-DIBuilder leak per debug-info compile (process-
   lifetime cost only; CodegenUnits.w uses no DI). Refutation attempted: full
   REGEX search over src/ lib/ tools/ build/ — no caller anywhere.
4. T15 cross-checks that HELD (no defect): atomic ordering constants
   (:74-78: 2,4,5,6,7) match LLVM-C exactly (Acquire=4, skips removed
   Consume=3 — verified in /usr/lib/llvm-22/include/llvm-c/Core.h:335-359);
   RMW ops (79-88, skip Nand=4) match Core.h:362-380, and map_rmw_op (1469-1480)
   correctly bridges Codegen.w AtomicRmwOp 0-9 (verified enum at Codegen.w:43-53)
   to LLVM values; map_ordering (1447-1452) correctly bridges AtomicOrdering
   0-4 (Codegen.w:55-60); Int predicates (39-48: EQ=32..SLE=41), Real predicates
   (49-55), linkage (56-59 + Appending=7 at :961), callconvs C/Fast/Stdcall/
   Fastcall/Win64 (60-64), type kinds (27-34), value kinds (35-38), ObjectFile=1,
   ReturnStatusAction=2/PrintMessage=1, MustTail=2, CodeGenLevel/Reloc/CodeModel,
   DIFlagZero, DWARF C=1/EmissionFull=1, ModuleFlagWarning=1, ATT=0 all match
   headers. AArch64_VectorCall=97 (:957) matches CallingConv.h:221. WithVec
   layout {ptr,len,cap,elem_size} (:1289-1294) matches emitted IR
   `%__with.Vec.i8 = type { ptr, i64, i64, i64 }` (stage1 `ir` probe output).
   wl_vec_data_ptr null-guard (:1297) and guarded value-type queries
   (wl_global_get_value_type :647-654, wl_get_allocated_type :655-660) are sound.
5. T13 paths that HELD (no defect): wl_init_target_machine (:563-591) balances
   layout/default-triple message on all paths and triple aliasing is safe
   (LLVMSetTarget copies before LLVMDisposeMessage); wl_assemble_to_object_for_
   triple (:1528-1571) frees mem_buf/module/ctx/tm/messages on every path;
   CodegenUnits.w:150-173 consumes parse/init/optimize/emit/dispose in balanced
   order with failure-path cleanup; wl_verify_module/wl_optimize/wl_run_*_
   passes/wl_print_ir dispose messages/opts/IR strings; cstr slot ring (:395-449)
   is lock-guarded with abort-on-exhaustion (no silent reuse); wl_build_global_
   string_ptr (:923-938) correctly bypasses the 4096-byte to_cstr truncation for
   string DATA (length-aware global); to_cstr/path truncation (444, 1516, 1211)
   and triple truncation (544-545) affect only names/paths, never string bytes.
6. T22 silent-default inventory — all UNREACHABLE in-repo (info only, no defect):
   codegen_level unknown->Default (:529-533), map_ordering unknown->SeqCst
   (:1452), map_rmw_op unknown->Xchg (:1480), attr silent-skip on unknown names
   (:754,764,771,780,803,810 — callers use only valid "alwaysinline"/"noinline",
   Codegen.w:4667-4669), wl_abi_align_of null->1 (:1154 — caller guards dl,
   Codegen.w:3892). Native-target init covers only AArch64+X86 (:495-527), so a
   --target triple outside those families fails loudly at
   LLVMGetTargetFromTriple (non-silent); no silent mistarget. FCmp surface
   (oeq/one/olt/ogt/ole/oge) covers exactly the six float comparisons the
   language lowers (CodegenDispatch.w:2371-2376, Codegen.w:2523-2524) — no gap.

## Probes run
- P1: git rev-parse in /home/shawn/workspace2/with -> 450733e5 confirmed. PASS.
- P2: wc -l src/compiler/LlvmBridge.w -> 1648. PASS.
- P3: ls out/bootstrap/bin/with-stage1 -> EXISTS (114690576 bytes); --version ->
  `with v0.15.1.7-g450733e58`. PASS.
- P4: `with-stage1 build /tmp/llvm_probe.w -o /tmp/llvm_probe` (trivial main) ->
  rc=0, binary produced and runs rc=0. PASS (exercises context/module/builder/
  target-machine/emit/dispose bridge path end to end).
- P5: `with-stage1 build /tmp/llvm_probe2.w` (print + string const + arithmetic)
  -> rc=0, prints `hello bridge`, exit 0. PASS (exercises
  wl_build_global_string_ptr, const/arith builders, vec-data-ptr call paths).
- P6: `with-stage1 ir /tmp/llvm_probe.w` -> rc=0; Vec layout in IR matches
  WithVec (T15 field evidence). PASS.
- P7: LLVM 22 header cross-check (/usr/lib/llvm-22 + bundled .deps/llvm-
  22.1.6-linux-x86_64): all constants verified; thiscall 33-vs-70 mismatch
  CONFIRMED. PASS (finding F1).
- P8: `-e` one-liner probe -> fails on `println` (undefined variable, needs
  prelude import) — probe-authoring miss, NOT a bridge finding; superseded by
  P4/P5 PASS. Negative control retained as-is.

## Negative controls
- N1: caller searches redone in REGEX mode (mode:"regex"; prior literal-mode
  alternation returned empty and was discarded): wl_di_dispose_builder zero
  callers; AtomicRmwOp/AtomicOrdering enums match bridge maps; thiscall chain
  ClangBridge.w:1530 -> Codegen.w:5468 -> LlvmBridge.w:955 live; wl_add_fn_attr
  callers use valid names only; wl_get_fn_param_type callers use small indices.
  True results, not tool misuse.
- N2: runtime probes -> PASS (P3/P4/P5/P6/P7 green; P8 authoring miss, no
  finding drawn from it).
- N3: full-module read -> MET (1-1648 read this pass in one read).

## Verdict
Verdict: INCOMPLETE — F1 (thiscall=33 vs LLVM22 70, live cimport caller chain) and F2 (128-slot param buffer with unwired cap + OOB index) are confirmed defects needing fixes; F3 (DIBuilder never disposed) is a confirmed low-severity leak. T15 otherwise fully verified against LLVM 22 headers; T13/T22 otherwise held.
