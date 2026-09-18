# Call/Return Correctness and `FnAbi` Authority Audit

**Audit target:** overview targets 2 and 3  
**Pinned source:** `31f77937abad3bc6573df3b71a0c99b605d6ea8e`  
**Status:** candidate evidence assembled; target/module completion is intentionally not claimed  
**Module-completion claim:** none

## Verdict

The compiler does not implement the `FnAbi` architecture required by D6. There is no `FnAbi`, `ArgAbi`, `compute_fn_abi`, or `push_call_arg` in production source. Instead, ABI decisions are reconstructed in declarations, generic specialization, extern declarations, closure and dynamic-trait helpers, ordinary and indirect call emission, and the C backend. The three integer `PM_*` constants and `arg_pass_mode` helper in [`Codegen.w`](../../../src/Codegen.w#L4662) are only a partial parameter classifier. They are not a cached function descriptor, do not classify returns, omit `Fat` and `Ignore`, and are not consumed by every caller or callee.

The call/return path also contains one confirmed critical defect: an awaited child cancellation takes an ordinary `TK_RETURN` without assigning return local 0. LLVM codegen has already allocated that slot without initialization and therefore loads an indeterminate value. The ordinary caller has only a normal successor and unconditionally consumes the call destination. On the existing `Task[Box[i32]]` fixture this is the exact source chain behind the invalid free already tracked as #916. A dedicated completion probe now also proves that direct, Unit, aggregate, generic, method, closure, raw-function, and dynamic-dispatch callers all continue after cancellation even when no allocator failure occurs. Every advertised analysis audit plus `--validate-all` accepts both the focused probe and the #916 fixture.

The expanded emit-C matrix found two additional confirmed candidates. Raw function pointers are converted to the fat `{fn_ptr,ctx}` representation and produce invalid C for both scalar and aggregate signatures. Canonical generic inherent methods name a concrete generic struct in emitted C without emitting that struct's definition. Both programs succeed natively; `--emit-c` reports success; the downstream C compiler rejects the artifact. Full commands and raw outcomes are preserved in [`evidence.md`](evidence.md).

## Contract and source authorities

The normative architecture is unambiguous:

- D6 in [`docs/decisions.md`](../../../docs/decisions.md#L1611) requires one cached `FnAbi { args, ret, sret }`, per-argument `PassMode`, one computation from the finalized signature, and consumption by both the callee prologue and every call site.
- [`docs/fn_abi_descriptor_design.md`](../../../docs/fn_abi_descriptor_design.md) explicitly describes the current side tables and re-derived decisions as predecessors to remove.
- Repository `AGENTS.md` repeats that `FnAbi` is the single ABI source of truth and forbids per-path ABI derivation.

The focused executable evidence uses a current-source-bound stage1. As established by [`009-build-platform-harness-spec/audit.md`](../009-build-platform-harness-spec/audit.md), the current cache ledger and hashed `seed-input.json` bind the selected seed, current compiler source/runtime/stdlib input fingerprints, produced stage1 fingerprint, and exact process effect; `build --explain stage1 :stage1` reported the artifact fresh against this HEAD. Its placeholder version stamp is intentional for stage binaries, not an ancestor attribution. This is strong repository-internal provenance, but an independent rebuild and current fixpoint would be stronger evidence; neither was run for this audit.

## Complete call-path inventory

### MIR producers

There are 78 raw `TK_CALL` construction sites in 53 `MirLower` functions, plus seven `TK_CALL` readers in seven later analysis/optimization helpers. The With-only inventory helper prints every exact `path:line/function` row and reproduces `producer_sites=78 producer_functions=53 reader_sites=7 reader_functions=7`; see [`source_call_inventory.w`](probes/source_call_inventory.w) and [`evidence.md`](evidence.md). The producers fall into these exhaustively inventoried families:

| Family | Principal producers | Contract/result behavior |
|---|---|---|
| General direct and callable calls | `lower_call`, `lower_call_redirected`, `lower_call_with_arg_nodes_recv`, `lower_call_with_operand_args`, `lower_resolved_call_with_operand_args_contract`, `lower_call_with_receiver_operand` | Records a Sema signature/mono symbol when known, creates a destination and exactly one continuation, then immediately exposes the destination as copy/move. See [`MirLower.w`](../../../src/MirLower.w#L8797). |
| Methods and generic methods | `lower_method_call` and the resolved operand helpers | Receiver ownership is handled while building operands; generic calls are tagged `GENERIC_CALL`. Physical ABI is not stored on the call. |
| Closures and raw function values | ordinary callable helpers plus closure construction/invocation branches | Callable type may substitute for a missing signature. Environment placement and physical parameters are reconstructed later. |
| Dynamic trait calls | method lowering with `DYN_CALL` | Bypasses the ordinary emitter and delegates to the dynamic dispatch path. |
| Built-ins and intrinsics | Vec/HashMap/Option/string/regex/format/index/iteration/comprehension/await/task/drop helpers | Tagged intrinsic calls bypass ordinary codegen audit coverage. Several lower into bespoke call emitters rather than a common ABI consumer. |
| Synthesized functions | cleanup/drop/task helpers, clause dispatcher, generator constructor/next | Build `TK_CALL` directly; their contracts are synthesized rather than uniformly attached from a finalized signature descriptor. |

Every general helper examined has the same value-only shape: `TK_CALL(callee,args,dest,next)`, switch to `next`, register the temporary, then copy or move it. There is no alternate cancellation/unwind successor and no “destination not initialized” completion state. Representative source is [`lower_call`](../../../src/MirLower.w#L8797), [`lower_call_redirected`](../../../src/MirLower.w#L8866), and [`lower_call_with_arg_nodes_recv`](../../../src/MirLower.w#L8906).

`mir_drop_state_transfer_term` then marks every call destination initialized without consulting completion mode, intrinsic, or effect at [`Mir.w`](../../../src/Mir.w#L1815). This makes the invalid return state look initialized to later ownership analysis.

### LLVM consumers and re-derived ABI authorities

The single downstream entry is the 2,700-line `mir_emit_call_term` dispatcher beginning at [`CodegenDispatch.w`](../../../src/CodegenDispatch.w#L13728), but its branches do not share one ABI descriptor. The following are independent physical-contract producers or consumers:

1. The ordinary AST declaration path in [`Codegen.w`](../../../src/Codegen.w#L4316) separately handles value-reference parameters, method-owner pointers, function fat values, extern function pointers, dynamic fat values, references, C aggregates, internal sret, and internal indirect parameters.
2. `declare_function_from_sig` in [`Codegen.w`](../../../src/Codegen.w#L4704) uses `arg_pass_mode` for only part of parameter lowering, then separately recomputes sret and populates byval side tables.
3. `internal_abi_needs_sret` and `internal_abi_needs_indirect_param` in [`Codegen.w`](../../../src/Codegen.w#L4975) are target classifiers, currently meaningful for Windows x86_64 aggregates larger than eight bytes. They are repeatedly called at consumers rather than once from a descriptor constructor.
4. `closure_abi_param_ty` and `closure_abi_arg` in [`Codegen.w`](../../../src/Codegen.w#L5001) form a closure-only authority.
5. Extern declaration construction in [`Codegen.w`](../../../src/Codegen.w#L5256) separately classifies C/internal sret, byval, and direct aggregates and writes parallel maps.
6. `ensure_concrete_mir_function` in [`Codegen.w`](../../../src/Codegen.w#L5864) reconstructs the physical signature for generic specializations.
7. `coerce_call_args_for_fn_value` and `build_call_fn_value` in [`Codegen.w`](../../../src/Codegen.w#L2166) consume symbol-keyed side maps rather than a function ABI object.
8. Dynamic trait function types in [`CodegenTraits.w`](../../../src/CodegenTraits.w#L247) independently rebuild parameters, result, sret, and indirect aggregate handling. Dynamic wrappers infer sret structurally from `void` plus an extra pointer parameter in [`CodegenTraits.w`](../../../src/CodegenTraits.w#L378).
9. Closure and raw-function type builders in [`CodegenDispatch.w`](../../../src/CodegenDispatch.w#L411) separately choose environment, indirect aggregate, and sret layouts. Closure definitions repeat the reconstruction in the same file near line 17159.
10. The ordinary call branch reads six parallel symbol maps for sret/byval/direct transformations at [`CodegenDispatch.w`](../../../src/CodegenDispatch.w#L15098). When no sret entry is found, it re-infers sret from the destination type, parameter count, environment-slot count, LLVM return type, and first parameter shape at lines 15132-15150. Argument emission then independently branches for byval, direct C aggregates, internal indirect aggregates, share/reference parameters, and dynamic fat arguments.
11. Intrinsic, generic, dynamic, closure, and method branches before the ordinary branch perform their own call construction and result finishing.
12. The C backend is an entirely separate authority. `call_args_text` in [`CCodegen.w`](../../../src/CCodegen.w#L5793) infers signature and argument representation through per-operand/per-parameter heuristics; `emit_term` separately resolves the callee and return type at [`CCodegen.w`](../../../src/CCodegen.w#L8192); `emit_fn_decl` separately derives declarations at [`CCodegen.w`](../../../src/CCodegen.w#L8916).

The source comment at `CodegenDispatch.w:15225-15236` correctly states that caller and callee must share one decision, but the following code still re-derives that decision from `expected_ty`, a Sema parameter type, or, for an unsignatured indirect closure call, the argument type. A comment expressing the invariant is not the invariant.

Mechanical searches close the principal side-table inventory. `internal_abi_needs_sret` is consumed by the AST declaration, signature declaration, extern declaration, generic specialization, and dynamic-trait declaration paths. `internal_abi_needs_indirect_param` is additionally consumed by `arg_pass_mode` and closure-only helpers. `record_c_abi_transform` is written independently by the AST, signature, extern, and generic-specialization paths. `extern_fn_has_sret`, byval masks/types, direct masks/types, and `fn_ref_param` are read by direct-call coercion and ordinary call emission. No production definition of `FnAbi`, `ArgAbi`, `compute_fn_abi`, `push_call_arg`, `PM_FAT`, or `PM_IGNORE` exists; the only `FnAbi` search hit is prose in `CiMigrate.w`.

Target projections do not reduce this duplication. Internal aggregate sret/indirect classification is Windows-x86_64-only at `Codegen.w:4969-4993`; foreign C classification separately handles Windows direct aggregates, Darwin arm64 HFA/direct aggregates, and the greater-than-16-byte fallback at `Codegen.w:5017-5143`. Cross-target IR confirms current caller/callee shape agreement for the focused matrix on Windows x86_64 and Darwin arm64, but that agreement is produced by repeated decisions, not shared descriptor identity.

### Return-slot paths

The return local is allocated at function entry without a store in both ordinary and monomorphized emission paths: [`CodegenDispatch.w`](../../../src/CodegenDispatch.w#L15718) and [`CodegenDispatch.w`](../../../src/CodegenDispatch.w#L16183).

The normal explicit-return, `?`, and user-try paths assign local 0 before cleanup and `TK_RETURN`. The await cancellation path is the exception:

1. `lower_single_await` branches child/self cancellation to `unwind_bb`.
2. The unwind block sets the runtime cancelled-return flag, flushes resets, emits defers and drops, then emits `TK_RETURN` at [`MirLower.w`](../../../src/MirLower.w#L7932).
3. It never assigns local 0.
4. LLVM `TK_RETURN` emission obtains that alloca and loads it at [`CodegenDispatch.w`](../../../src/CodegenDispatch.w#L15447). Direct returns load at line 15515; sret returns load at line 15491 and overwrite the initially constructed default.
5. The caller's normal successor treats the destination as a produced value, and drop-state marks it initialized.

The C backend expresses the same semantic mistake as `return _0;` for every non-void `TK_RETURN` at [`CCodegen.w`](../../../src/CCodegen.w#L8200); it has no cancellation-aware return form.

There are also two default-return fallbacks at `CodegenDispatch.w:15500-15514` for a missing or typeless return pointer. They appear unreachable in normal emission because both entry paths always insert local 0. They are therefore classified as a latent prohibited fallback, not as a demonstrated runtime defect: malformed MIR/codegen state should fail loudly rather than synthesize a successful default return.

## Findings

### ABI-001 — Required `FnAbi` source of truth is absent

**Severity:** Critical  
**Confidence:** Confirmed from exhaustive source search and path inventory  
**Blast radius:** every call and function definition; especially Windows x86_64 aggregates, closures/raw function values, dynamic dispatch, generics, extern C, the emit-C backend, and any future parameter or return mode

The three current `PM_*` constants cover only `Direct`, `Indirect`, and `IndirectPlace`. `arg_pass_mode(sig, param)` is not cached, has no result/sret classification, and is not used by all producers and consumers. `Fat` and `Ignore` from D6 do not exist. Symbol-keyed maps such as `extern_fn_has_sret`, byval masks/types, direct masks/types, and reference-parameter tables are independent authorities whose completeness depends on which declaration path ran first and whether the call can recover a symbol.

This is not merely a refactoring preference. The ordinary caller contains explicit heuristics to distinguish an environment pointer from sret and to recover aggregate ABI from either a callee signature or the argument. Those are exactly the caller/callee/path divergences D6 was adopted to make unrepresentable.

Executable IR confirms that current Unit handling is also a physical convention outside the promised descriptor: LLVM emits `unit_value() -> i32` and `accepts_unit(i32)`, while emit-C emits `unit_value() -> void`, retains `accepts_unit(int32_t)`, and supplies a zero-initialized MIR temporary. Both positive controls run, but D6's `Ignore` projection is absent and the backends do not project Unit identically.

**Issue relationships:** D6 already records the transparent `T*`/`T**` class. Local issue triage associates Windows codegen failures with #806. #761 is adjacent internal-runtime ABI/ownership corruption, and #785/#783 are historical receiver/emit-C contract divergence locators. These relationships do not prove that every issue has the same root; they identify the paths that a repair must retest.

### ABI-002 — emit-C converts raw function pointers into fat With function values

**Severity:** High  
**Confidence:** Confirmed by scalar and aggregate minimal repros, emitted C, and exact source branches  
**Blast radius:** every emit-C program that materializes or calls `*const fn(...) -> ...` / raw With function pointers

Both [`emit_c_raw_fn_scalar_expected_fail.w`](probes/emit_c_raw_fn_scalar_expected_fail.w) and [`emit_c_raw_fn_expected_fail.w`](probes/emit_c_raw_fn_expected_fail.w) execute natively. `--emit-c` exits zero, but `cc` rejects the artifacts. The scalar form assigns `int32_t (*)(int32_t)` into a generated `with_fn_*` struct and then dereferences that struct; the aggregate form does the same with `Big (*)(Big)`.

The first exact wrong branch is `CCodegen.c_type` at [`CCodegen.w`](../../../src/CCodegen.w#L1897): when a raw pointer/reference points at `TY_FN`, lines 1906-1907 return the inner `with_fn_<tid>` fat-struct name instead of a thin C function-pointer declarator. The generic cast renderer at lines 3361-3373 then produces an invalid cast. Call resolution compounds the mistake: `callee_fn_type_from_operand` strips pointer/reference layers through `Sema.callable_any_fn_type` and `fn_tid_is_fat` then classifies the inner `TY_FN` as fat at `CCodegen.w:5453-5457` and `5723-5729`. The repair boundary must preserve callable signature lookup separately from callable storage/pass mode; stripping to a signature cannot erase thin-vs-fat representation.

**Issue relationships:** this is a concrete realization of [`007-names-closures-interop/audit.md`](../007-names-closures-interop/audit.md) A7-05's closure/dynamic ABI authority split and ABI-001's missing `Fat` mode, but it is not presently recorded there as a raw-function emit-C failure. Treat it as a candidate issue, not a duplicate filed issue.

### ABI-003 — emit-C names ordinary generic instances without defining them

**Severity:** High  
**Confidence:** Confirmed by a canonical generic inherent-method repro, generated C, and exact collection branch  
**Blast radius:** emit-C programs using user-defined generic structs, including generic inherent methods and any calls whose declaration/locals expose the instantiated receiver type

[`emit_c_generic_method_expected_fail.w`](probes/emit_c_generic_method_expected_fail.w) executes natively. `--emit-c` exits zero, but `cc` reports `unknown type name 'GBox_i32_'`: the emitted method prototype, locals, and method definition all name `GBox_i32_`, yet no definition is emitted.

The exact source mismatch is internal to C type collection. `c_type` names every non-special generic instance at `CCodegen.w:1934-1937`, but `generic_inst_needs_struct_def` at [`CCodegen.w`](../../../src/CCodegen.w#L2072) is a hard-coded whitelist of seven library types. `collect_struct_types_from_tid` registers generic instances only when that whitelist returns true at `CCodegen.w:8301-8313`; `GBox[i32]` therefore falls through without entering the definition set. A proper repair must derive fields for ordinary generic instances from Sema's finalized instantiated type, recursively collect their field types, and make emitted declarations depend on the same type record. Adding `GBox` or another name to the whitelist would be a symptom patch.

**Issue relationships:** this blocks generic-method emit-C parity and is adjacent to [`008-mir-codegen-optimization/audit.md`](../008-mir-codegen-optimization/audit.md)'s backend-completeness findings, but MCO-001 is the separate LLVM high-arity bridge defect. This candidate was not found in audits 007 or 008.

### RET-001 — Cancellation returns an uninitialized value and the caller consumes it

**Severity:** Critical  
**Confidence:** Confirmed source chain plus executable allocator failure in #916/audit 001  
**Blast radius:** every value-returning function that awaits a cancellable task, regardless of whether the call is direct, method, generic, closure, or indirect; droppable results can corrupt ownership, while scalar/Copy results can silently alter control flow

The exact wrong operation is the load at `CodegenDispatch.w:15515` (or line 15491 for sret), enabled by the `TK_RETURN` at `MirLower.w:7948` that has no dominating assignment to local 0. The next defect in the chain is representational: `TK_CALL` has only a value-producing successor, and `Mir.w:1825` marks its destination initialized unconditionally.

The observed `Task[Box[i32]]` invalid free is one manifestation, not the boundary of the defect. [`cancellation_completion_matrix.w`](probes/cancellation_completion_matrix.w) deterministically prints `continued-*` after cancellation for direct scalar, Unit, trivial aggregate, generic, method, capturing closure, raw function pointer, and dynamic-trait call paths. Its debug-allocator run is clean, proving that incorrect continuation is independently observable without relying on a droppable garbage value. Ignored results still continue; Unit avoids the garbage load but loses cancellation propagation; Copy/scalar results may consume an arbitrary value. These are consequences of #916 / [`003-suspension-cancellation/audit.md`](../003-suspension-cancellation/audit.md) SUSP-001's root, not separate issue recommendations.

### GUARD-001 — Current return/call/codegen audits cannot prove these contracts

**Severity:** High  
**Confidence:** Confirmed by source and focused execution  
**Blast radius:** CI and audit claims for all call paths

`analysis_audit_return_consistency` only checks Unit-signature calls with typed destinations and switches on Unit at [`Analysis.w`](../../../src/Analysis.w#L1137). It does not prove that every normal `TK_RETURN` has a definitely initialized local 0. Codegen coverage skips all intrinsic-tagged calls and only demands one marshalling fact per ordinary argument at [`Codegen.w`](../../../src/Codegen.w#L719). Its verdicts are limited to share-place/reference-table disagreements; it never compares complete caller and callee physical function types, parameter modes, sret/result mode, or attributes.

On both the focused completion probe and `test/spec/spec_ss14_11_await_combinator_cancel_joins.w`, every advertised audit mode plus `--validate-all` exited zero. Representative focused-probe outputs are:

| Command | Result |
|---|---|
| `analyze ... audit:calls` | `violations=0`, `ok` |
| `analyze ... audit:effects` | `violations=0`, `ok` |
| `analyze ... audit:storage` | `violations=0`, `ok` |
| `analyze ... audit:pool` | `violations=0`, `ok` |
| `analyze ... audit:methods` | `violations=0`, `ok` |
| `analyze ... audit:phase` | `violations=0`, `ok` |
| `analyze ... audit:mir` | `violations=0`, `ok` |
| `analyze ... audit:returns` | `violations=0`, `ok` |
| `analyze ... audit:receivers` | `violations=0`, `ok` |
| `analyze ... audit:receiver-surface` | `violations=0`, `ok` |
| `analyze ... audit:codegen` | `violations=0`, `ok` |
| `analyze ... audit:trait-tables` | `violations=0`, `ok` |
| `analyze ... audit:all` | `violations=0`, `ok` |

The #916 fixture produces the debug-allocator invalid-free verdict documented by [`001-validator-trustworthiness/audit.md`](../001-validator-trustworthiness/audit.md), while the focused probe produces all eight invalid continuation messages. Thus the successful audit outputs are confirmed false negatives for the call/return chain, not merely missing coverage for one allocator-specific symptom.

## Executable matrix

The retained probes are the executable audit record; exact commands and raw outputs are in [`evidence.md`](evidence.md).

| Boundary | Native LLVM | Cross-target IR | emit-C/cc/run | Result |
|---|---|---|---|---|
| Direct scalar/small/large, ignored scalar/large, Unit result/parameter | pass, allocator clean | Win64 and Darwin arm64 inspected | pass | Positive caller/callee controls; Unit physical projection differs by backend |
| Read/mut/move receivers | pass | Win64/Darwin declarations inspected | pass | Canonical receiver modes agree in tested cases |
| Generic free function, large result | pass | Win64 specialization is sret/indirect | pass | Positive generic-free control |
| Generic inherent method | pass | Win64 receiver is pointer | `--emit-c` 0, `cc` 1 | ABI-003: missing `GBox[i32]` definition |
| Named fat fn and capturing closure | pass | Win64 fat callable becomes pointer | named fat fn passes; closure fails loudly | emit-C `CK_CLOSURE` unsupported |
| Raw function pointer, scalar and large result | pass | Win64 thin callable plus sret inspected | `--emit-c` 0, `cc` 1 | ABI-002: thin raw pointer converted to fat struct |
| Dynamic trait aggregate call | pass | Win64 sret/indirect inspected | dynamic fixture fails loudly | emit-C dynamic downcast unsupported |
| Extern C scalar | pass | declaration inspected | pass | `abs(i32)->i32` positive control |
| `@[c_export]` 32-byte aggregate return | pass, allocator clean | host/Win64/Darwin all sret | pass | Real foreign-sret positive control |
| Explicit early/default/Never branch | pass | compiled in target IR | pass | Value/default/divergence controls |
| 127/128/129 parameters | 127/128 pass; 129 panics | source root inspected | all three pass | Cross-link audit 008 MCO-001 |
| Cancellation/non-value completion across 8 callable forms | all eight continue incorrectly | source control-flow root inspected | fails loudly before C emission | RET-001 / audit 003 SUSP-001 |
| Known Drop-bearing emit-C return | native pass | n/a | emitted binary assertion fails | Cross-link [`004-move-drop-cleanup`](../004-move-drop-cleanup/audit.md) / [`008-mir-codegen-optimization`](../008-mir-codegen-optimization/audit.md); no duplicate finding |

Cross-target IR is a stronger check than source reading alone: Windows x86_64 shows `Big` results as hidden sret plus indirect aggregate parameters for direct, generic, closure, raw, and dynamic paths, while Darwin arm64 keeps the internal `Big` direct. Corresponding call instructions visibly match those declarations in the focused module. It still cannot prove target runtime behavior. There is no Windows or Darwin execution environment/runtime in this checkout, so cross-target execution is the concrete remaining platform blocker.

The matrix deliberately separates loud unsupported emit-C surfaces from emit-C defects. Closure constants, dynamic downcasts, and the cancellation matrix exit non-zero during emission. Raw pointers and generic methods instead make `--emit-c` report success and leave invalid C for `cc`; those are confirmed artifact-correctness failures.

## Proper repair boundary

A correct repair cannot patch the await fixture or individual call branches:

1. Define the complete `FnAbi`/`ArgAbi`/result descriptor required by D6, including `Direct`, `Indirect`, `IndirectPlace`, `Fat`, and `Ignore`.
2. Compute and cache it exactly once after a signature and target ABI are final. Give indirect callable types an ABI descriptor too; absence of a named callee cannot authorize inference from the argument value.
3. Attach descriptor identity to every MIR call contract. Compiler intrinsics need explicit fixed descriptors rather than an audit exemption.
4. Make one LLVM declaration/prologue builder and one caller marshaller consume the descriptor. Dynamic wrappers, closures, generic specializations, externs, and raw function calls must be projections of that same data.
5. Make the C backend consume the same semantic/physical contract through a backend projection. It must preserve thin raw pointers separately from fat With function values, and must not independently infer receiver, argument, or result modes.
6. Retire the sret/byval/direct/ref side maps as authorities. If implementation staging temporarily retains them, generate them only as projections from `FnAbi` and assert equivalence at every consumer.
7. Derive emit-C generic instance definitions from finalized Sema type data, not a base-name whitelist; recursively collect ordinary instantiated fields before any declaration can name the type.
8. Model cancellation/non-value completion as a distinct control-flow edge or terminator effect. A normal call destination becomes initialized only on the value-producing edge. A cancellation return is not an ordinary value return.
9. Add a definite-initialization proof for local 0 on every normal `TK_RETURN`, and fail codegen loudly on a missing/typeless return slot instead of returning a default.

## Required regression matrix

The repair is not evidence-grade until the following Cartesian boundaries are represented, with pairwise reduction allowed only after each ABI mode appears on each applicable target:

- **Callee kinds:** direct free function; `fn`/`mut fn`/`move fn` receiver; generic free and generic inherent method; captureless and capturing closure; raw function pointer; dynamic trait method; extern C; compiler-internal runtime; intrinsic.
- **Arguments:** scalar; explicit `&T`; in-place receiver; consuming aggregate; Windows aggregate greater than eight bytes; dynamic fat value; function fat value; zero-sized/Unit/ignored parameter.
- **Results:** Unit; scalar; droppable aggregate; Windows sret aggregate; dynamic/fat result if supported; Never/diverge; inferred/default return.
- **Completion:** normal; explicit early return; `?` error; panic/unreachable; self cancellation; child cancellation; nested suspension; ignored result.
- **Targets/backends:** Linux x86_64, Darwin arm64 and x86_64, Windows x86_64; LLVM and emit-C wherever the latter claims support.
- **Arity:** 0/1, representative ordinary arity, 127, 128, 129, and a post-repair bound derived from dynamic storage rather than a fixed bridge buffer.
- **Proofs per case:** identical descriptor identity at declaration and call; exact LLVM function/call type and attributes; MIR destination initialized only on a value edge; every C type named by declarations/locals has one definition; emitted C compiles before emission is reported successful; expected output; debug allocator clean for owned results; malformed or mismatched contracts rejected non-zero.

The present host positive controls should remain, and the #916 fixture must invert from “all audits say ok while allocator fails” to both static rejection of malformed MIR and correct cancellation behavior at runtime.

## Adjacent hypotheses, kept separate from confirmed defects

- `PM_IGNORE` absence is no longer only inferred: LLVM carries Unit result/parameter as i32 while emit-C returns void and supplies a zero-initialized Unit argument temporary. No wrong user-visible result was demonstrated, so this remains part of ABI-001 rather than a separate severity claim.
- `PM_FAT` absence leaves dynamic and function-fat values to bespoke branches. ABI-002 proves a thin/fat emit-C failure; named fat functions and current host dynamic calls still pass, so no broader present miscompile is claimed beyond the reproduced surfaces.
- Structural sret detection in dynamic wrappers is especially fragile when a closure environment is also the first pointer parameter. Existing comments show prior failures, but the current host matrix passed; Windows execution is required before claiming a present concrete miscompile.
- The default-return branches are prohibited silent fallbacks, but appear unreachable under normal current function setup. A negative MIR-injection test is required to classify reachability.

## Module-completion impact

No checklist module can be marked complete from this audit. This report is candidate evidence for parent inspection, not an acceptance verdict. The required repair crosses at least `MirLower.w`, `Mir.w`, `Codegen.w`, `CodegenDispatch.w`, `CodegenTraits.w`, `CCodegen.w`, `Analysis.w`, Sema signature/type finalization, compilation validation, and the test harness. It also overlaps audit 003 for suspension/cancellation, audit 004 for Drop, audit 007 for closures/interop, and audit 008 for MIR/codegen/high arity. Those reports are cross-linked rather than duplicated, and none should infer that target 2 or 3 is closed.

## Audit limits

- No production source or issue tracker state was changed.
- No full build was run; it was unnecessary to answer the source-authority question, and the focused stage1 executions answered the runtime questions available on this host.
- The source-call inventory is deterministic and retained. It covers all 78 `TK_CALL` construction occurrences and seven readers in `MirLower.w`; the downstream inventory covers declaration, specialization, closure, dynamic, extern, ordinary-call, and C-backend authorities. It does not claim semantic correctness for each intrinsic implementation. Intrinsic behavior belongs to the relevant module audits; their exemption from the common contract remains in scope and is recorded here.
- Cross-target IR projections were run, but Windows/Darwin runtime execution was impossible because this Linux checkout has no matching execution environment/runtime. Host emit-C compilation/execution was run for supported cases and retained negative controls.
- Direct malformed-MIR ABI injection remains unavailable through the compiler CLI. Exercising the two latent default-return branches would require a production/test harness mutation outside this report-only ownership boundary. Their reachability therefore remains explicitly unclassified.
- Confirmed defects themselves are concrete blockers: no `FnAbi` descriptor exists to compare for identity, cancellation has no non-value completion representation, raw function pointers emit invalid C, user-defined generic instances emit without definitions, and the 129-parameter LLVM path panics. Candidate evidence cannot turn those red facts into completion.
