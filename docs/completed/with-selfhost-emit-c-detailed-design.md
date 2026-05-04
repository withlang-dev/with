# With Self-Host `--emit-c` Detailed Design

## Status and Intent

This document refines [docs/with-selfhost-emit-c.md](/Users/eric/with/docs/with-selfhost-emit-c.md) into an implementation-grade design, using proven patterns from Zig's self-hosted C backend:

- [`.reference/zig/src/codegen/c.zig`](/Users/eric/with/.reference/zig/src/codegen/c.zig)
- [`.reference/zig/src/link/C.zig`](/Users/eric/with/.reference/zig/src/link/C.zig)
- [`.reference/zig/src/codegen/c/Type.zig`](/Users/eric/with/.reference/zig/src/codegen/c/Type.zig)

Goal: deliver a deterministic, interruptible, portable C11 backend for distribution and cross-compilation, while keeping LLVM as default.

---

## 1. Design Goals

1. `with build --emit-c src/main.w -o out.c` emits valid C11.
2. Emitted C compiles with `zig cc -target ...` + runtime sources.
3. Backend is deterministic and interruptible.
4. Backend does not rely on heuristic type guessing inside emission.
5. Self-host compiler can emit C for itself and cross-compile to target triples in `docs/with-selfhost-emit-c.md`.

---

## 2. Key Lessons from Zig C Backend

Zig's implementation provides architectural patterns we should copy directly.

### 2.1 Separate per-function generation from global flush

In Zig, function/decl codegen populates fragments (`fwd_decl`, `code_header`, `code`) and metadata (`ctype_pool`, lazy function set), and `link/C.zig` performs a global flush/merge pass. This cleanly separates local lowering from whole-module ordering.

Adoption in With:

- `CCodegen` emits per-body fragments + per-body type usage.
- A module assembly pass merges fragments, deduplicates types/helpers, and emits final file in deterministic order.

### 2.2 Central type canonicalization (`CType` pool)

Zig avoids ad hoc textual type printing by interning canonical C type structures, then mapping declaration-local pools into a global pool during flush.

Adoption in With:

- Introduce `CTypeKey` interner for canonical C types and names.
- Emit types from canonical pool, not from repeated string concatenation.
- Deduplicate forward declarations and helper signatures by key.

### 2.3 Strict lowering contracts over heuristic inference

Zig assumes codegen input has enough information and fails on unsupported patterns (`AnalysisFail`) rather than silently guessing.

Adoption in With:

- Add a pre-emit verifier + normalization pass for C backend invariants.
- Codegen fails fast on unresolved types/callees instead of fallback heuristics that produce invalid C.

### 2.4 Deterministic emission ordering

Zig flushes in stable order with explicit handling of exports, externs, lazy declarations, and type ordering.

Adoption in With:

- Stable sort by symbol/type IDs.
- Stable section layout with no hash iteration order leaks.
- Stable naming scheme for all generated helpers.

### 2.5 Performance and memory discipline

Zig reuses buffers, uses writer abstractions, and avoids quadratic string building.

Adoption in With:

- Replace repeated `out = out ++ ...` hotspots with buffered writer abstractions.
- Keep passes linear in MIR/module size; avoid recursive global inference loops.

---

## 3. High-Level Architecture

```
Parse -> Resolve -> Typed -> MIR Lower (existing)
                              |
                              v
                    C Backend Prep (new verifier/normalizer)
                              |
                              v
                      C Body Emitter (per MIR body)
                              |
                              v
                     C Module Assembler (global flush)
                              |
                              v
                            .c file
```

This keeps the existing frontend/MIR pipeline unchanged and only adds a strict C-backend preparation boundary.

---

## 4. C Backend Contract (Must Hold Before Emission)

`verify_c_emit_contract(mir_mod, sema)` enforces:

1. Every local used as value has concrete non-error type (`!= TY_ERR`, `!= unresolved`).
2. Every `TK_CALL` has one of:
   - direct callee symbol with resolved signature
   - typed function-pointer callee with resolved function type
   - explicit builtin-op marker lowered to runtime helper.
3. Every field projection used in MIR has resolved owner type and field type.
4. No "placeholder call forms" remain (for example unresolved `new`/ambiguous method calls).
5. No emission-critical type remains implicit through alias cycles.

If any invariant fails: emit structured compiler error and stop C emission.

This is the core fix for current instability: move uncertain inference out of emission and into a checked normalization stage.

---

## 5. C Backend Prep Pass (New)

`prepare_mir_for_c_emit` runs after MIR lowering and before C emission.

Responsibilities:

1. Canonicalize callees.
   - Resolve every call target to explicit symbol or explicit function-pointer expression with concrete function type.
   - Lower generic container methods (`Vec/HashMap/Option`) to explicit runtime helpers.

2. Materialize local and field types.
   - Fill missing local/field types via single-pass dataflow over MIR (monotonic, worklist-based, bounded).
   - Persist results into MIR metadata or side-table consumed by codegen.

3. Canonicalize unresolved builtins.
   - Example: convert implicit `new` patterns to typed helper calls (`with_vec_new_*`, `with_hashmap_new_*`, etc.) or typed runtime constructors.

4. Reject ambiguity.
   - If multiple candidate callees remain, report compile error with span/symbol context.

Algorithmic constraints:

- Monotonic worklist.
- No recursive `infer -> resolve -> infer` cycles.
- Fixed max iterations (`<= num_locals + num_calls + num_fields`), then hard fail.

---

## 6. Type System to C Mapping

The mapping in `docs/with-selfhost-emit-c.md` remains authoritative. This section specifies implementation shape.

### 6.1 `CTypeKey`

Use a canonical key model:

- Primitive (`bool`, `i32`, `u64`, `f64`, `void`)
- Pointer/ref (`ptr(mutability, pointee_key)`)
- Struct (`struct(name_sym)`)
- Enum tagged union (`enum(name_sym)`)
- Function pointer (`fn_ptr(param_keys[], ret_key)`)
- Runtime container concrete instantiations (`vec(elem_key)`, `option(inner_key)`, `result(ok_key, err_key)`)

All emission uses `CTypeKey -> CTypeName` mapping from one interner.

### 6.2 Naming

Deterministic generated names:

- Functions: sanitized symbol + stable numeric suffix.
- Specialized helpers: `with_vec_<elem_mangle>`, `with_option_<inner_mangle>`, etc.
- Struct fields: stable `f<field_sym>` as currently used.

### 6.3 Type emission order

1. Collect used type graph from signatures, locals, and struct fields.
2. Emit forward typedefs for all named structs/unions.
3. Emit full definitions in dependency order; break cycles via pointers/forwards.
4. Emit container/sum-type specializations after primitives but before function bodies.

---

## 7. Per-Function Emission Design

### 7.1 Inputs

- `MirBody`
- Resolved signature metadata
- Prepared side tables from C backend prep pass

### 7.2 Locals

- Emit local declarations from concrete local types only.
- No heuristic local retyping in emitter.
- For `_0` return slot: `void` returns use `return;`, others use typed `_0`.

### 7.3 Basic blocks

- One label per block: `bbN:`.
- Preserve MIR control flow with `goto`.
- Deterministic statement and terminator order.

### 7.4 Calls

Call emission follows this strict order:

1. Builtin-lowered helper call (already normalized) -> emit direct helper call.
2. Direct symbol callee -> emit `fn(args)`.
3. Function pointer callee with concrete fn type -> emit `callee(args)`.
4. Otherwise -> hard error (`unresolved callee after prepare`).

No name-based fuzzy matching during codegen.

### 7.5 Drops

`SK_DROP`/`TK_DROP_AND_GOTO` map to generated drop helper calls when type requires drop; otherwise no-op comment.
This requires a `needs_drop(type)` query and drop helper naming contract.

### 7.6 Rvalues and places

`emit_rvalue` and `emit_place` remain mostly mechanical; unsupported forms are explicit compile errors.

---

## 8. Runtime and Helper Boundary

### 8.1 Runtime API surface

`runtime/with_runtime.h` is the ABI contract for emitted C.

Required stable functions:

- `with_runtime_init/shutdown`
- `with_str_*`
- `with_vec_*` generic primitives (or concrete instantiations emitted in C)
- panic/assert/print helpers
- fiber/task symbols

### 8.2 Builtin lowering table

Define one source of truth:

- language builtin/method name
- receiver kind
- argument shape
- lowered C symbol
- return type rule

This table lives in backend prep; emitter just prints already-lowered call symbols.

---

## 9. Global Module Assembly ("Flush")

Inspired by Zig `link/C.zig`, final output assembly is section-based:

1. Preamble (`#include`, ABI defines, runtime include)
2. Type forward declarations
3. Type definitions
4. Runtime/helper forward declarations
5. Function forward declarations
6. Function definitions
7. Generated lazy helpers (if any)
8. `main` wrapper

Assembly rules:

- Deduplicate declarations and helper bodies by key.
- Preserve deterministic ordering by stable IDs.
- Keep non-function declarations before function bodies.

---

## 10. Interruptibility and Hang Prevention

All long loops in prep/codegen/assembly check `with_interrupt_requested()`:

- per body
- per basic block
- per statement chunk
- per type graph node
- per helper generation unit

On interrupt:

- stop promptly,
- return `"interrupted by signal"` error,
- avoid partially writing output file (write temp then atomic rename on success).

Hang prevention policies:

1. No recursive unbounded inference.
2. Bounded worklists with progress tracking.
3. Cache keys include context; cache misses cannot recursively call same query without guard.
4. Debug counters/timers for passes with optional diagnostics under a debug flag.

---

## 11. Error Handling Strategy

Categories:

1. `E_C_EMIT_CONTRACT` (prep contract violation)
2. `E_C_EMIT_UNSUPPORTED` (MIR feature not yet supported)
3. `E_C_EMIT_INTERNAL` (backend bug)
4. `E_C_EMIT_INTERRUPTED` (signal)

Each error includes:

- function symbol
- MIR block/statement index if applicable
- type/callee details
- actionable hint (which normalization/lowering path failed)

No silent substitution to zero values for unresolved semantics.

---

## 12. Implementation Plan (Mapped to Checklist)

### Phase A: Foundation

1. Add `verify_c_emit_contract`.
2. Add `prepare_mir_for_c_emit`.
3. Add canonical type interner (`CTypeKey`).

### Phase B: Emitter hardening

1. Remove heuristic local/field/callee inference from `CCodegen`.
2. Consume prepared metadata only.
3. Complete missing mappings:
   - drop emission
   - drop-and-goto
   - aggregate/discriminant/len
   - option/result/vector concrete layouts.

### Phase C: Global assembler

1. Refactor emission into fragments + assembler flush.
2. Add declaration/type/helper dedup.
3. Add deterministic ordering and section writer.

### Phase D: Validation

1. Self-host emit-C for compiler.
2. Cross-compile 4 targets with `zig cc -target`.
3. Round-trip program equivalence tests (LLVM vs emit-C paths).
4. `-Wall -Werror` clean builds under Zig CC/Clang/GCC.

### Phase E: Operational quality

1. Interrupt checks in all heavy loops.
2. Pass timing stats (debug mode).
3. Regression tests for previously failing functions:
   - `dump_async_mir_artifact`
   - `Lexer.lex_number`
   - `AstPool.add_string`
   - `render_*`
   - `resolve_from_root_pool`
   - `ResolveState.build_module_table`.

---

## 13. Testing Matrix

### 13.1 Unit tests

- `CTypeKey` canonicalization and naming
- builtin lowering table coverage
- call contract verification
- field/local type materialization

### 13.2 Golden tests

- small MIR snippets -> exact C output sections
- stable output ordering across runs

### 13.3 Integration

- hello world `--emit-c` -> `zig cc` -> run
- language feature corpus through C backend
- compiler self-host emit and compile

### 13.4 Cross-target

- `aarch64-macos`
- `x86_64-macos`
- `x86_64-linux-gnu`
- `aarch64-linux-gnu`

### 13.5 Performance and interrupt

- large source throughput benchmark
- forced interrupt tests during prep and assembly
- ensure process exits quickly and cleanly on signal

---

## 14. Concrete Design Decisions (To Prevent Rework)

1. **No fuzzy call-name matching in emitter.** All call resolution must be complete before emission.
2. **No recursive field/local inference inside emitter.** Emitter is a printer over prepared MIR+metadata.
3. **All unresolved or ambiguous semantics are compile errors.** Do not emit placeholder code.
4. **One canonical type system for C emission.** No ad hoc type strings.
5. **Deterministic assembly order is required.** No unordered map iteration in output ordering.
6. **Interruptibility is part of correctness.** Long-running passes must poll and abort safely.
7. **Performance objective is linear-ish scaling.** Reject algorithms with repeated whole-module rescans in hot paths.

---

## 15. Relationship to Existing `docs/with-selfhost-emit-c.md`

This document does not change goals/non-goals. It defines how to implement them reliably:

- keeps `--emit-c` as optional backend,
- keeps LLVM default path untouched,
- preserves runtime-based cross-compilation model (`zig cc -target ...`),
- adds strict prep contracts and Zig-inspired assembly architecture to avoid current blocker classes.

