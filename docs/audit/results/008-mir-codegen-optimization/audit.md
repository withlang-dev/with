# 008 — MIR/codegen agreement, optimization, and semantic duplication

Status: **In progress — bounded source inventory and high-arity negative control complete; cross-target and malformed-MIR matrices remain**  
Inventory snapshot: `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
Executable evidence artifact: `out/bootstrap/bin/with-stage1`, bound to the current
input tree by the repository's stage1 ledger, seed manifest, process-effect record,
and `fresh` explanation documented in [Audit 009](../009-build-platform-harness-spec/audit.md)  
Audit targets: overview §§13, 14, 23, and 24

## Scope and conclusion

This pass traced the production MIR-to-LLVM and MIR-to-C boundaries, LLVM
verification/optimization/emission ordering, codegen-unit optimization, the most
material compiler/migrator fallback families, and the duplicated authorities for
ABI, completion, Copy/drop, suspension, type identity, layout, reachability, and
ownership.

The strongest new executable finding is a deterministic compiler crash at 129
function parameters. `wl_get_fn_param_type` asks LLVM for an unbounded parameter
array into fixed `[128]i64` storage, then indexes the same array at 128. A
128-parameter control compiles and runs; the 129-parameter program exits 134 with
`panic: index out of bounds`. LLDB stops at the exact bridge helper with parameter
index 128 and a caller in `Codegen.apply_noalias_param_attrs_with_offset`.

The strongest new source-confirmed fail-open path is LLVM optimization itself:
`LLVMRunPasses` errors are consumed and discarded, both backend callers continue
to object emission, and the module is not verified after optimization. A real
pass-manager error was not injected in this bounded pass, so that is not claimed
as a currently manifesting wrong binary.

Three larger correctness failures belong to other audit targets and are
cross-linked rather than double-counted here:

- cancellation returns through MIR without a value while codegen and the caller
  consume one ([003/SUSP-001](../003-suspension-cancellation/audit.md));
- emit-C replaces every non-Vec MIR `Drop` with a comment and returns success
  ([004/MDC-002](../004-move-drop-cleanup/audit.md));
- D6's required `FnAbi` does not exist; caller and callee ABI are independently
  reconstructed along twelve paths
  ([002/ABI-001](../002-call-return-abi/audit.md)).

Together, these are not random leaf bugs. They cluster at missing authoritative
descriptors for function ABI/completion/effects and at backend paths that are
allowed to reinterpret or omit MIR semantics. That supports re-engineering these
semantic seams in place. This bounded target does not establish that the entire
compiler should be replaced.

No production, specification, build, test, issue-tracker, overview, checklist, or
result-index file was changed.

## Source authority inventory

### MIR and backend entry

- [`src/Mir.w`](../../../src/Mir.w) defines the parallel-table MIR, structural,
  typed, ownership, and drop-state validators. Target 001 establishes that these
  checks do not prove all semantics codegen consumes.
- [`src/MirLower.w`](../../../src/MirLower.w) produces places, rvalues, calls,
  drops, cleanup edges, and `TK_RETURN` terminators.
- `Codegen.gen_module_from_mir`,
  [`src/Codegen.w:1268`](../../../src/Codegen.w#L1268), runs structural MIR
  validation and then delegates to `gen_module`.
- `Codegen.gen_module`, [`src/Codegen.w:6210`](../../../src/Codegen.w#L6210),
  declares functions, emits bodies, finalizes debug info, and returns the result
  of LLVM module verification at line 6303.
- `Zcu.compile_to_object_backend`,
  [`src/compiler/Backend.w:14`](../../../src/compiler/Backend.w#L14), checks that
  result, optionally optimizes, then emits the object.
- [`src/CodegenDispatch.w`](../../../src/CodegenDispatch.w) emits MIR statements
  and terminators for LLVM. Its call/return duplication and ordinary-return
  fallbacks are inventoried in target 002.
- [`src/CCodegen.w`](../../../src/CCodegen.w) is a separate MIR consumer. Most
  unsupported constructs call `self.fail`; `c_emit_module` then returns
  `CEmitResult { ok: 0, source: "" }`. Its non-Vec `Drop` branch is the material
  exception proven in target 004.

### Optimization and verification

- `Codegen.optimize`, [`src/Codegen.w:1066`](../../../src/Codegen.w#L1066),
  calls `wl_optimize` and has no result to inspect.
- `wl_optimize`,
  [`src/compiler/LlvmBridge.w:1223`](../../../src/compiler/LlvmBridge.w#L1223),
  selects LLVM's `default<O0/O1/O2/O3>` pipeline and calls `LLVMRunPasses`.
- Single-unit compilation calls it at
  [`src/compiler/Backend.w:82`](../../../src/compiler/Backend.w#L82).
- Generated codegen units call the same helper at
  [`src/compiler/CodegenUnits.w:162`](../../../src/compiler/CodegenUnits.w#L162)
  before object emission.
- The only `wl_verify_module` production consumer is `Codegen.verify`; it runs
  before the backend's optimization call. No post-optimization verification was
  found.
- [`src/MirOpt.w`](../../../src/MirOpt.w) is not the production optimizer. It is
  an unreferenced analysis stub whose four passes count candidates without
  mutating MIR.

### Layout and high-arity parameter queries

- `Sema.type_layout_size_of/align_of` and their frozen caches live in
  [`src/TypeLayout.w`](../../../src/TypeLayout.w). They model language-level
  layout using hard-coded pointer/fat-value sizes and aggregate rules.
- `Codegen.abi_size_of`, [`src/Codegen.w:1254`](../../../src/Codegen.w#L1254),
  asks LLVM's target `DataLayout`; ABI decisions repeatedly consume this result.
- C emission independently projects semantic types to C declarations in
  `CCodegen.c_type` and related aggregate emitters.
- `wl_get_fn_param_type`,
  [`src/compiler/LlvmBridge.w:1174`](../../../src/compiler/LlvmBridge.w#L1174),
  is a fourth physical-query seam. It is used by noalias attribute application,
  named-function-to-fat-function thunks, and main wrapping.

## Finding MCO-001 — 129 parameters overflow the bridge contract and crash the compiler

Verdict: **Confirmed executable defect**  
Severity: **High** — deterministic compiler panic on accepted source; the bridge
also hands LLVM undersized storage before the bounds panic  
Blast radius: **Functions with more than 128 physical parameters**, including
ordinary declarations; the same helper is also used by fat-function thunks  
Confidence: **Very high**  
Issue status: **Candidate unreported**; no matching item exists in the local
82-open-issue snapshot

### Differential negative control

Both programs were passed directly through `with-stage1 -e ... -O1`. The source
generator used the exact parameter sequence `p0: i32` through `p(N-1): i32`, a
body returning `p0`, and `print_i32(0)` as the top-level statement.

| Parameter count | Exit | Output |
|---:|---:|---|
| 128 | 0 | `0` |
| 129 | 134 | `panic: index out of bounds` |

The semantic difference is only the final `p128: i32` parameter. No `-O0` build
or execution was used.

### Exact failure chain

1. `apply_noalias_param_attrs_with_offset`, `Codegen.w:4913-4919`, iterates all
   129 source parameters. At `actual_idx == 128`, its comparison against LLVM's
   parameter count succeeds and it calls `wl_get_fn_param_type(fn_type, 128)`.
2. `wl_get_fn_param_type`, `LlvmBridge.w:1176-1177`, confirms that 128 is below
   LLVM's count of 129.
3. It allocates `params: [128]i64` at line 1178.
4. It computes `actual_count = 128` at line 1179 but never uses it.
5. It passes the 128-entry buffer to `LLVMGetParamTypes` at line 1180. LLVM's API
   writes the full parameter count; the helper provides no capacity argument.
6. It then evaluates `params[128]` at line 1181 and the With bounds trip-wire
   terminates the compiler.

LLDB confirmed the exact instruction path on the failing control:

- breakpoint: `wl_get_fn_param_type` with SysV argument register `$rsi == 128`;
- caller: `Codegen.apply_noalias_param_attrs_with_offset`;
- source chain continues through `declare_function_at_inner`, `gen_module`, and
  `Zcu.compile_to_object_backend`;
- disassembly calls `LLVMGetParamTypes`, then compares the requested index with
  immediate `0x80` and branches to `with_panic_ref`.

The disassembly also confirms that `LLVMGetParamTypes` runs *before* the
128-element bounds check. Thus the loud panic contains the demonstrated 129 case,
but the C API write contract is already memory-unsafe for every count above the
fixed buffer capacity.

### Root cause (5 Whys)

1. Why does accepted source panic the compiler? Codegen queries parameter 128
   through a 128-element array.
2. Why does that query exist? Noalias attributes and function-thunk construction
   rediscover physical parameter types from LLVM after declaration.
3. Why is the query bounded incorrectly? The bridge uses a fixed local array for
   an API whose required capacity is the runtime parameter count.
4. Why does its apparent clamp not help? `actual_count` is dead; LLVM's API has
   no count argument and always writes the full function-type count.
5. Why can this physical contract drift into an unsafe bridge helper? There is no
   complete, cached `FnAbi`/argument descriptor that declaration, attributes,
   thunks, and calls consume together.

The immediate defect is exact at `LlvmBridge.w:1178-1181`. The architectural root
joins D6/ABI-001: repeated introspection substitutes for one bounded descriptor.

### Proper repair boundary and regressions

The bridge must never provide less storage than `LLVMCountParamTypes` requires.
Either allocate an exact-sized buffer or remove bulk C-API introspection from the
single-parameter helper. The larger D6 repair should make attributes and thunk
construction consume the same `FnAbi` used for declaration, with LLVM queries
retained only as assertions.

Regression coverage must include 0, 1, 64, 127, 128, 129, and at least 256
parameters across ordinary declarations, named-function-to-fat-value coercion,
generic specialization, extern declarations, and trait/dynamic wrappers. If the
language adopts a parameter limit, Sema must reject it explicitly before LLVM;
the bridge still must remain memory-safe for malformed internal input.

## Finding MCO-002 — LLVM optimization errors are discarded and emission continues

Verdict: **Confirmed fail-open source branch; pass-manager failure not injected**  
Candidate severity: **High** — a production build may report success after its
requested optimization pipeline failed or partially transformed the module  
Blast radius: **Every optimized single-unit and generated multi-unit build**  
Confidence: **High for control flow, Medium for present manifestation**  
Issue status: **Candidate unreported**

`wl_optimize` receives LLVM's error object at `LlvmBridge.w:1230`. On error it
obtains the message and immediately disposes it without printing it, setting a
compiler error, or returning failure. Its return type is `Unit`.

Both production callers therefore continue:

- `Backend.w:82` calls `cg.optimize(opt_level)` and then emits the object;
- `CodegenUnits.w:163` calls `wl_optimize` and then emits the unit object.

LLVM module verification occurs at the end of `Codegen.gen_module`, before these
calls. There is no verification after the pass pipeline. A pass-manager error can
therefore be invisible, and a post-pass invalid module is left to object emission
to reject incidentally, if it rejects it at all.

Root-cause chain:

1. LLVM can report an optimization error.
2. The bridge converts an error-bearing operation into `Unit`.
3. It discards the only diagnostic text.
4. Backend APIs consequently cannot stop object emission.
5. Optimization is treated as a best-effort side effect even though the build
   contract requires the selected `-O1` pipeline and forbids silent fallback.

Proper repair: return a status, render LLVM's error message, propagate nonzero
through both backend paths, and verify the module after successful optimization.
Add a bridge-level invalid-pipeline negative control plus single-/multi-unit
integration tests proving that an optimizer error creates no successful object.

## Cross-linked MIR/codegen contradictions

These findings are evidence for this target, but their primary reports own the
defect details and severity:

| Contract | Primary evidence | MIR/codegen disagreement |
|---|---|---|
| Normal call completion produces a value | [003/SUSP-001](../003-suspension-cancellation/audit.md) and [002/RET-001](../002-call-return-abi/audit.md) | Cancellation emits ordinary `TK_RETURN` without initializing `_0`; LLVM loads it and the caller consumes the destination. |
| Every MIR `Drop` executes its destructor | [004/MDC-002](../004-move-drop-cleanup/audit.md) | emit-C renders non-Vec `Drop` as `/* drop(...); */`, emits no cleanup, and returns success. |
| Caller and callee share one physical ABI | [002/ABI-001](../002-call-return-abi/audit.md) | Required `FnAbi` is absent; declaration, calls, closures, traits, generics, externs, and C emission re-derive modes. |
| Codegen consumes only validated MIR | [001/VAL-001/003/005](../001-validator-trustworthiness/audit.md) | Production gates structural/typed subsets; return initialization, complete call typing, and several parallel-table contracts are not proved. |
| Typed semantic facts have complete, attributable producers | [006/Finding 1](../006-type-identity-generics/audit.md), narrowed by [009 provenance reconciliation](../009-build-platform-harness-spec/audit.md) | Audit 009 rules out a stale or unattributed stage1 as the supported explanation. The narrower unresolved question is which indirect source path populates the observed typed facts and whether completeness validators prove every required fact exists. |

## Bounded silent-fallback inventory

The inventory deliberately distinguishes placeholder *values used after recording
failure* from branches that let the command succeed:

| Surface | Branch | Classification |
|---|---|---|
| LLVM type lowering | `Codegen.type_fallback` returns `i32` but sets `had_error` | **Fail-closed scaffolding**; backend returns nonzero. |
| emit-C unsupported formatting/operators/callees/statements | helper emits placeholder text after `self.fail` | **Fail-closed scaffolding**; `c_emit_module` discards the generated source and returns `ok=0`. |
| emit-C non-Vec `Drop` | `CCodegen.emit_stmt` emits only a comment | **Confirmed silent semantic omission**; owned by MDC-002. |
| C migrator unsupported function type/body | `ci_migrate_fail_function` / project failure totals | **Fail-closed**; no extern or callable stub is substituted. |
| Rust/Zig/Swift migrator stub | `Migrate.run` prints not implemented and returns 1 | **Loud unsupported command**, not false success. |
| LLVM pass-manager error | `wl_optimize` disposes error and returns Unit | **Confirmed source fail-open**, MCO-002. |
| Named function to fat function | `gen_fn_to_fat_ptr_thunk` directly wraps when `orig_fn_ty == 0` with comment “may mismatch” | **Latent prohibited fallback**; no executable producer was demonstrated. |
| Aggregate comparison type skew | `compare_aggregate_eq` returns `undef i1` for missing/mismatched LLVM types without `had_error` | **Latent malformed-state fallback**; incomplete typed validation makes it relevant, but no user repro was isolated. |
| Missing/typeless LLVM return slot | default return synthesis in `CodegenDispatch` | **Latent prohibited fallback** inventoried in target 002; normal entry currently allocates `_0`. |

This is a bounded high-risk inventory, not an exhaustive proof over every helper
in the compiler's hundreds of thousands of lines. Target 23 must remain in
progress until every failure-producing helper is mechanically joined to its
command result and negative-tested.

## Duplicated semantic-decision map

| Decision | Competing authorities | Current evidence |
|---|---|---|
| Function ABI | Sema signatures; AST declaration lowering; symbol side maps; generic, closure, dynamic, extern, ordinary-call, and C-backend reconstruction | Confirmed architectural noncompliance and concrete corruption history; [002](../002-call-return-abi/audit.md). |
| Call completion/cancellation | Sema call shape, MIR one-successor `TK_CALL`, runtime cancellation flag, LLVM return emission, caller drop-state initialization | Confirmed invalid free and hang family; [003](../003-suspension-cancellation/audit.md). |
| May-suspend effect | Sema AST recursion/allowlist, MIR intrinsic/callee fixed point, runtime wait loops | Confirmed callable and wrapper false negatives; [003/SUSP-004/005](../003-suspension-cancellation/audit.md). |
| Move/drop need | Sema diagnostic state, `is_copy`/`type_needs_drop` caches, MirLower cleanup stack, MIR drop-state validator, LLVM drop emission, C drop emission | Confirmed disagreement and silent C omission; [004](../004-move-drop-cleanup/audit.md), issue #898. |
| View/ownership provenance | Sema origin masks and pattern aggregation, signature ownership modes, MIR operands/places, ABI ref/share side maps | Confirmed projection conflation and 31-bit capacity collapse; [005](../005-borrow-view-provenance/audit.md). |
| Type identity/specialization | flat symbol IDs, typed-expression sidecar, canonical/pretty symbols, generic specialization tables/cache, MIR call contracts | Semantic-producer attribution and completeness remain open; stale/unattributed stage1 provenance is unsupported by [009](../009-build-platform-harness-spec/audit.md). See [006](../006-type-identity-generics/audit.md) and issues #666/#751/#767. |
| Layout | Sema `TypeLayout`, frozen caches, LLVM target `DataLayout`, C declarations, per-path ABI classifiers | Multiple necessary projections exist, but no complete cross-backend equivalence assertion was found; candidate seam, especially on Windows/aggregates. |
| CFG reachability/dataflow | Sema branch/loop walkers, MIR drop-state pass, linear use-after-kill reachability, suspension fixed point, backend control-flow emission | The analyses answer different questions, but incompatible traversal limits already produce validator gaps and ignored backedges; [001](../001-validator-trustworthiness/audit.md) and [004/MDC-003](../004-move-drop-cleanup/audit.md). |

The repair direction is not “deduplicate every helper.” Backend projections are
necessary. The contract is that one semantic descriptor is produced once, every
projection names that descriptor, and validators assert equivalence before a
backend can emit. Today many consumers instead infer a missing fact from local
shape, symbol tables, LLVM types, or conservative defaults.

## Required regression matrix

No repair at these seams is evidence-grade without:

- MIR terminators/statements: assign, drop, call, switch, return, unreachable,
  cleanup, suspension, cancellation, and panic;
- values/places: scalar, reference, fat function, trait object, aggregate,
  partial projection, moved field, zero-sized value, and uninitialized result;
- callees: ordinary, receiver modes, generic, closure, raw function value,
  dynamic trait, extern C, intrinsic, and synthesized cleanup/drop function;
- parameter counts around every representation boundary, including 127/128/129;
- optimization: `-O1` single unit and multiple generated units, pre/post LLVM
  verification, fixpoint, debug allocator, and an injected pass error;
- backends/targets: LLVM and every emit-C surface it claims, Linux x86_64,
  Darwin arm64/x86_64, and Windows x86_64;
- negative controls: malformed MIR type/place/parallel-table/call contracts,
  missing return initialization, omitted drop, incompatible layout, and failed
  optimizer; every case must exit nonzero without emitting a successful object.

## Evidence limits and completion impact

- No full build or test suite ran; no production changes required that cost.
- Audit 009's stage1 ledger, hashed seed manifest, recorded process effect, and
  `build --explain stage1 :stage1` result bind the exercised stage1 to the current
  input tree. The stage placeholder is intentional, not evidence of unknown
  provenance. A clean independent rebuild/fixpoint would be stronger; the only
  Audit 006 observation retained here is the narrower unresolved indirect
  semantic-producer and validator-completeness question.
- Only the host x86_64 LLVM path was executed. Windows, Darwin, emit-C runtime,
  post-optimization fault injection, and high-arity generic/closure/dynamic
  variants remain unexecuted.
- Candidate fallbacks were not promoted to defects without an executable producer
  or a complete source proof of user-visible wrong behavior.
- The report reuses primary findings from targets 001–006 and Audit 009's
  provenance reconciliation rather than assigning new IDs or severities to the
  same defect chain.
- No module can be marked complete. Confirmed defects remain, and the exhaustive
  negative-control/cross-target matrix required by the overview is open.
