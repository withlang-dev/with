# DWARF Debug Info Implementation Plan

This document defines the standalone task for emitting source-level DWARF
debug info from the LLVM backend.

The immediate release goal is simple:

- LLDB must show With source lines instead of disassembly.
- `b main`, `run`, `source list`, and step commands must work on user code.
- The change must preserve `make build`, `make fixpoint`, and
  `./out/bin/with-stage2 check src/main.w`.

This is not part of the general quality pass. It is a discrete backend task.

---

## Current State

Today the compiler emits symbols, but not usable source-level debug info.

- `runtime/llvm_bridge.c` does not include `llvm-c/DebugInfo.h` and exports
  no DIBuilder helpers.
- `src/Codegen.w` has no debug metadata declarations or debug-location calls.
- `src/Codegen.w` currently routes user functions through the AST codegen path:
  `Codegen.gen_function_dispatch()` unconditionally calls `self.gen_function()`.
- MIR already carries statement spans (`MirBody.stmt_spans`), but MIR
  terminators do not carry spans yet.

Important consequence:

- Instrumenting MIR only will not fix shipped binaries today.
- The AST codegen path must be instrumented first.

---

## Release Scope

Phase 1 is the release gate.

Phase 1 must provide:

- `DICompileUnit`
- `DIFile`
- `DISubprogram`
- per-instruction source locations via `LLVMSetCurrentDebugLocation2`
- enough metadata for LLDB to resolve file/line for user functions

Phase 1 does not need:

- local variable inspection
- parameter inspection
- global variable debug info
- complete struct/enum DI type graphs
- dSYM packaging automation

Phase 2 can add variable/type richness after source stepping works.

---

## Acceptance Criteria

The task is complete only when all of the following are true:

- `./out/bin/with-stage2 build examples/hello.w` succeeds.
- `lldb -b -o 'breakpoint set --name main' -o 'process launch' -o 'source list' -- ./examples/hello`
  shows With source instead of `No source available`.
- Stepping inside the function shows source lines rather than disassembly.
- LLVM IR for a small program contains `!llvm.dbg.cu`, `!DICompileUnit`,
  `!DISubprogram`, and instruction `!dbg` attachments.
- `make build` passes.
- `make fixpoint` passes.
- `./out/bin/with-stage2 check src/main.w` passes.
- Compile-time overhead is acceptable; no O(n^2) line lookup in hot codegen.

Darwin note:

- On macOS, `dwarfdump <binary>` may still be sparse even when LLDB can
  resolve source via the debug map. LLDB behavior is the real acceptance gate.

---

## Design Decisions

### 1. AST Path First

The current active path for user functions is AST codegen, not MIR codegen.
The implementation must therefore attach debug locations in `gen_function()`
and the AST expression emitters first.

MIR debug plumbing should still be added in the same task where practical, but
it is not sufficient by itself.

### 2. Always-On for Phase 1

Do not block the feature on new CLI flags.

For Phase 1:

- emit full DWARF metadata by default for the LLVM backend
- defer `-g0` / `-gline-tables-only` / `-gfull` policy to a later follow-up

### 3. Reproducibility Over Canonicalization

Do not canonicalize source paths to absolute host-specific paths.

Use the source path string already carried by the compiler, split into
directory + filename for `DIFile`.

Reason:

- self-host fixpoint runs from a stable repo-relative path
- absolute-path canonicalization would bake machine-specific paths into
  compiler binaries and hurt reproducibility across worktrees and machines

### 4. Use Existing Source Infrastructure

Do not reuse the current `span_to_line()` hot-path scan for debug emission.
That would create avoidable compile-time overhead.

Instead:

- reuse `compiler.foundation.Source`
- build line offsets once from `source_text`
- translate byte offsets to `(line, col)` with binary search

### 5. Split Source Stepping from Variable Debug Info

LLVM 22's C API exposes the new debug record APIs for locals/parameters.
That is more invasive than line info alone.

Therefore:

- Phase 1: source stepping only
- Phase 2: variables and richer type metadata

This keeps the release-critical path small and lowers risk.

---

## File-Level Plan

### `runtime/llvm_bridge.c`

Add the LLVM-C debug bridge.

Required includes:

- `llvm-c/DebugInfo.h`

Required handle macros:

- `MD(i)` for `LLVMMetadataRef`
- `DIB(i)` for `LLVMDIBuilderRef`

Required Phase 1 wrappers:

- `LLVMCreateDIBuilder`
- `LLVMDisposeDIBuilder`
- `LLVMDIBuilderFinalize`
- `LLVMDebugMetadataVersion`
- `LLVMAddModuleFlag`
- `LLVMDIBuilderCreateFile`
- `LLVMDIBuilderCreateCompileUnit`
- `LLVMDIBuilderCreateSubroutineType`
- `LLVMDIBuilderCreateFunction`
- `LLVMSetSubprogram`
- `LLVMDIBuilderCreateDebugLocation`
- `LLVMSetCurrentDebugLocation2`

Recommended Phase 1 helpers:

- `wl_di_flag_zero()`
- `wl_dwarf_lang_c()` or `wl_dwarf_lang_c11()`
- `wl_dwarf_emission_full()`
- `wl_module_flag_warning()`

Optional Phase 2 wrappers:

- `LLVMDIBuilderCreateBasicType`
- `LLVMDIBuilderCreatePointerType`
- `LLVMDIBuilderCreateUnspecifiedType`
- `LLVMDIBuilderCreateStructType`
- `LLVMDIBuilderCreateMemberType`
- `LLVMDIBuilderCreateExpression`
- `LLVMDIBuilderCreateAutoVariable`
- `LLVMDIBuilderCreateParameterVariable`
- `LLVMIsNewDbgInfoFormat`
- `LLVMSetIsNewDbgInfoFormat`
- `LLVMDIBuilderInsertDeclareRecordBefore`
- `LLVMDIBuilderInsertDeclareRecordAtEnd`

Notes:

- All debug handles can use the existing `i64` opaque-handle pattern.
- No extra LLVM library discovery work is expected; `scripts/ensure_runtime.sh`
  already links the debug-related static libraries from the LLVM install.

### `src/Codegen.w`

This is the main implementation site.

Add Phase 1 state:

- `debug_enabled: bool` or `i32`
- `debug_finalized: i32`
- `di_builder: i64`
- `di_compile_unit: i64`
- `di_file: i64`
- `di_current_scope: i64`
- `di_current_subprogram: i64`
- `di_fn_subprograms: HashMap[i32, i64]`
- a `Source` value or equivalent cached line-offset structure

Add Phase 1 helpers:

- `debug_init_module()`
- `debug_finalize_module()`
- `debug_split_path(path: str) -> (dir, file)`
- `debug_location_for_offset(offset: i32, scope: i64) -> i64`
- `debug_set_location_from_node(node: i32)`
- `debug_set_location_from_offset(offset: i32)`
- `debug_clear_location()`
- `debug_enter_function(fn_node: i32, function: i64, fn_type: i64)`
- `debug_leave_function()`
- `debug_subroutine_type_for_fn(fn_node: i32) -> i64`

Phase 1 type policy for subprogram signatures:

- precise basic types for `bool`, integer widths, `f32`, `f64`
- pointers/references as pointer-to-unspecified or pointer-to-basic where easy
- named structs/enums/generics may use `CreateUnspecifiedType` in Phase 1
- do not block source stepping on full composite DI type graphs

This is sufficient because line stepping does not depend on rich local type
inspection.

### `src/compiler/Backend.w`

No major structural change is required. It already sets:

- `cg.source_file`
- `cg.source_text`

The new debug init should consume those values inside `Codegen`.

### `src/Mir.w` and `src/MirLower.w`

Phase 1 can succeed without MIR terminator spans because AST codegen is active.
But the same task should prepare MIR for re-enable.

Required MIR follow-up inside this task:

- add terminator span storage parallel to basic-block terminator data
- thread spans through `MirBody.set_terminator`
- thread spans through `MirBuilder.terminate`
- populate them from the relevant AST node spans

Reason:

- `stmt_spans` covers statements only
- branch, return, switch, and call terminators need source locations too
- otherwise MIR stepping will be imprecise the moment MIR codegen is re-enabled

### `src/compiler/Compilation.w`

No Phase 1 change is strictly required for source stepping.

Potential Darwin follow-up:

- if release packaging needs standalone `.dSYM` bundles, run `dsymutil`
  before the object cleanup path or preserve the object until debug artifacts
  are generated

Do not block core DIBuilder work on this.

---

## Detailed Implementation

## 1. Bridge the LLVM Debug APIs

Start by extending the bridge, not `Codegen`.

The goal of this step is to prove:

- `runtime/llvm_bridge.c` can compile with `llvm-c/DebugInfo.h`
- the self-hosted code can hold `LLVMMetadataRef` and `LLVMDIBuilderRef`
- a module can create and finalize a compile unit without crashing verification

Implementation notes:

- add small wrappers, not generic varargs-style glue
- keep naming aligned with the existing `wl_*` bridge convention
- return metadata handles as `i64`
- keep string handling identical to existing bridge wrappers

Before wiring the entire backend, verify a minimal path:

- create builder
- create file
- create compile unit
- finalize builder
- emit object

If this minimal bridge step fails, stop there and fix it before touching the
rest of codegen.

## 2. Add Module-Level Debug State in `Codegen`

Debug info should be initialized once per module, not per function.

`debug_init_module()` should:

- build a `Source` from `source_file` and `source_text`
- split `source_file` into filename + directory without host canonicalization
- create `DIBuilder`
- create `DIFile`
- add module flags:
  - `"Debug Info Version"` = `LLVMDebugMetadataVersion()`
  - `"Dwarf Version"` = 5
- create a single `DICompileUnit`
- store the resulting handles in `Codegen`

Suggested compile-unit parameters:

- language: temporary fallback `DW_LANG_C`
- producer: stable string such as `with self-hosted compiler`
- isOptimized: `opt_level > 0`
- flags: empty string for Phase 1
- split name: empty string
- emission kind: `Full`
- sysroot/sdk: empty strings for Phase 1 unless a real stable source is added

Why explicit module flags:

- clang-generated IR includes `"Debug Info Version"` and `"Dwarf Version"`
- adding them explicitly avoids relying on undocumented side effects

`debug_finalize_module()` should:

- finalize once
- set `debug_finalized`
- be called before verification/emission/IR printing consumes the module

The safest place is:

- at the end of `gen_module()`, immediately before `self.verify()`

Also guard `emit_object_file()` and `print_ir()` so late callers cannot skip
finalization accidentally.

## 3. Use Fast Offset-to-Location Mapping

Do not call the current `span_to_line()` logic per instruction.

That implementation scans from the start of the source text every time.
Instruction-level debug locations would magnify that cost across self-hosting
builds.

Instead:

- reuse `compiler.foundation.Source`
- store `Source.from_string(source_file, source_text, ...)` once
- convert byte offsets via `offset_to_location()`

Location conversion rules:

- LLVM line numbers are 1-based
- LLVM columns are 1-based
- `SourceLocation` values are 0-based
- so emit `line + 1`, `col + 1`

Invalid offsets:

- for synthetic code with no real source, clear the current debug location
- do not invent fake line numbers for compiler-generated instructions

## 4. Create `DISubprogram` for User Functions

Each user `NK_FN_DECL` needs a `DISubprogram`.

Create the subprogram from source declaration data:

- display name: user-visible function name
- linkage name: actual emitted LLVM symbol name
- file: module `DIFile`
- line: function start line
- scope line: same line for Phase 1
- type: result of `debug_subroutine_type_for_fn()`
- local-to-unit: false
- definition: true
- optimized: `opt_level > 0`

Then attach it with:

- `LLVMSetSubprogram(function, subprogram)`

The builder's current scope for the function body should start as that
subprogram.

Special cases:

- for entry functions renamed to `main`, use the real linkage name `main`
  but preserve the source-visible name when reasonable
- for compiler-generated helper functions, do not emit normal user subprograms
  in Phase 1

Examples of compiler-generated helpers to keep out of the first pass:

- wrapper `main` helpers
- closure thunks
- async trampolines
- synthetic dispatch helpers

If they get debug info later, mark them artificial in a follow-up.

## 5. Instrument the AST Codegen Path

This is the release-critical part.

Because `gen_function_dispatch()` currently routes to `gen_function()`,
Phase 1 must attach locations inside AST emission.

Implementation approach:

- At function entry:
  - create/attach the `DISubprogram`
  - set current debug location to the function declaration line for prologue
    allocas and param stores
- In `gen_expr()`:
  - before dispatching on a real AST node kind, call
    `debug_set_location_from_node(node)`
- In statement-like emitters:
  - set location again before synthetic control-flow instructions that should
    map to the controlling source construct

Functions that explicitly need location handling review:

- `gen_return`
- `gen_if_expr`
- `gen_while`
- `gen_loop`
- `gen_for`
- `gen_match`
- `gen_break`
- `gen_continue`
- `gen_assign`
- `gen_call`
- `gen_block` / `gen_block_discard`

Rules:

- user-triggered instructions should inherit the user node location
- wholly synthetic instructions should clear location
- implicit returns/unreachables should use the source construct that caused
  them only if that construct is user-written; otherwise leave them artificial

This step should be validated before touching variable info.

## 6. Instrument the MIR Codegen Path

Even though MIR is not the active path today, add the matching hooks now.

In `gen_function_mir()`:

- set function-entry location for prologue allocas and param stores
- before each `mir_emit_stmt(body, stmt_id)`, set location from
  `body.stmt_spans[stmt_id]`
- before each terminator emission, set location from the terminator span

This requires MIR terminator spans to exist first.

Without terminator spans:

- `return`
- conditional branches
- `switch`
- call terminators

would all lose their own locations.

MIR must not regress into "source lines work in AST mode only."

## 7. Phase 2: Local and Parameter Variables

Do not make this a prerequisite for shipping source stepping.

Phase 2 is the right place for:

- `frame variable`
- parameter names/types in debugger views
- local variable locations

LLVM 22 note:

- the C API exposes the new debug record insertion functions
- variable work therefore needs explicit handling of the new debug format

Phase 2 implementation sketch:

- expose:
  - `LLVMDIBuilderCreateExpression`
  - `LLVMDIBuilderCreateParameterVariable`
  - `LLVMDIBuilderCreateAutoVariable`
  - `LLVMIsNewDbgInfoFormat`
  - `LLVMSetIsNewDbgInfoFormat`
  - `LLVMDIBuilderInsertDeclareRecordBefore/AtEnd`
- enable the new debug format for the module if required
- emit parameter declarations after entry-block allocas/stores
- emit local variable declarations when allocas are created
- keep O0 simple: alloca-backed `declare` records are enough initially
- defer `dbg.value` sophistication until after basic variable visibility works

## 8. Phase 2: Richer DI Types

Phase 1 can use a minimal type strategy for subprogram signatures.

Phase 2 should build real DI types for:

- named structs
- enums
- Option / Result wrappers
- pointers/references with correct pointee types
- generic instantiations with stable names

Existing codegen data can drive this:

- `abi_size_of`
- `abi_align_of`
- `struct_field_*` arrays
- enum variant tables
- stable mangled names already used for monomorphized types

Determinism rule:

- never build DI composite members by iterating hash maps
- use source/declaration order from the existing vectors only

---

## Debug Metadata Strategy

## Phase 1 Type Mapping

Use the smallest type model that still makes `DISubprogram` valid.

Recommended Phase 1 mapping:

- `void` return: verify whether null return-type entry is acceptable; if not,
  use `CreateUnspecifiedType("Void")`
- `bool`: basic type, size 1, boolean encoding
- signed integers: basic type with real bit width
- `f32` / `f64`: basic type with float encoding
- pointers / refs: pointer type to unspecified pointee for now
- user-defined structs/enums/generics: unspecified type with stable name

Reason:

- line tables and subprogram metadata are the release requirement
- full composite type reconstruction is higher risk and not needed to get LLDB
  out of disassembly mode

## Scope Handling

Phase 1 can use the function `DISubprogram` as the scope for all instruction
locations.

Lexical blocks are optional for Phase 1.

If stepping quality is poor in nested blocks, add Phase 1.5:

- `DILexicalBlock` per `NK_BLOCK`, branch arm, loop body, and match arm

But do not block the first usable release on lexical-scope perfection.

---

## Verification Plan

## Manual Smoke Checks

Primary check:

```sh
./out/bin/with-stage2 build examples/hello.w
lldb -b \
  -o 'breakpoint set --name main' \
  -o 'process launch' \
  -o 'source list' \
  -o 'thread step-over' \
  -o 'source list' \
  -o quit \
  -- ./examples/hello
```

This must not print `No source available`.

Secondary checks:

```sh
./out/bin/with-stage2 ir examples/hello.w | rg '!dbg|!DICompileUnit|!DISubprogram'
```

If the `ir` command is still unstable at the time of implementation, verify
the module by printing IR directly from a temporary backend harness instead of
blocking the debug-info task.

Optional object-level inspection:

```sh
llvm-dwarfdump --debug-line <object-or-dsym>
```

On macOS, treat LLDB behavior as authoritative.

## Self-Host Regression Checks

Every implementation slice must run:

```sh
make build
./out/bin/with-stage2 check src/main.w
make fixpoint
```

If fixpoint fails, stop and debug determinism before adding more debug features.

---

## Risks and How to Avoid Them

### Performance Risk: Per-Instruction Rescanning

Do not use `span_to_line()` in the debug hot path.

Mitigation:

- use `Source.offset_to_location()`

### Determinism Risk: Unstable Metadata Construction

Do not:

- iterate unordered maps to emit type/member metadata
- include timestamps
- include machine-specific canonicalized paths

Mitigation:

- stable producer string
- source-order traversal only
- path strings exactly as already provided by the compiler input

### Coverage Risk: MIR-Only Work

Do not assume MIR is the active backend path.

Mitigation:

- instrument AST first
- add MIR hooks in the same task as future-proofing

### Scope Creep Risk: Variable Info Before Line Info

Do not start with local-variable records.

Mitigation:

- ship Phase 1 line stepping first
- add variables only after LLDB source listing works

---

## Checklist

## Phase 1: Required for Release

- [ ] Add `llvm-c/DebugInfo.h` to `runtime/llvm_bridge.c`
- [ ] Add `LLVMMetadataRef` / `LLVMDIBuilderRef` handle wrappers to the bridge
- [ ] Export Phase 1 DIBuilder bridge functions from `runtime/llvm_bridge.c`
- [ ] Declare the new bridge functions in `src/Codegen.w`
- [ ] Add debug state fields to `Codegen`
- [ ] Reuse `compiler.foundation.Source` for cached offset-to-location lookup
- [ ] Add `debug_init_module()` to create `DIBuilder`, `DIFile`, and `DICompileUnit`
- [ ] Add explicit module flags for `"Debug Info Version"` and `"Dwarf Version"`
- [ ] Add `debug_finalize_module()` and ensure it runs before verify/emission
- [ ] Add `DISubprogram` creation for user `NK_FN_DECL` functions
- [ ] Attach subprograms with `LLVMSetSubprogram`
- [ ] Add fast helpers to set/clear current debug locations
- [ ] Instrument `gen_function()` prologue with function-entry locations
- [ ] Instrument `gen_expr()` so real AST nodes set the current location
- [ ] Review control-flow emitters and set locations for user-visible branches/returns
- [ ] Keep compiler-generated helper functions out of normal user debug scopes
- [ ] Add MIR stmt-location hooks in `gen_function_mir()`
- [ ] Add MIR terminator spans to `MirBody`
- [ ] Thread MIR terminator spans through `MirBody.set_terminator`
- [ ] Thread MIR terminator spans through `MirBuilder.terminate`
- [ ] Verify `examples/hello.w` shows source lines in LLDB
- [ ] Verify a loop/match/control-flow example steps through source lines
- [ ] Run `make build`
- [ ] Run `./out/bin/with-stage2 check src/main.w`
- [ ] Run `make fixpoint`

## Phase 2: Variables and Richer Types

- [ ] Export Phase 2 variable-debug bridge functions
- [ ] Decide and wire LLVM new debug format handling
- [ ] Add `DIExpression` helpers
- [ ] Add parameter variable metadata emission
- [ ] Add local auto-variable metadata emission
- [ ] Emit `declare` records for entry-block allocas
- [ ] Verify `frame variable` works for simple locals and parameters
- [ ] Replace placeholder DI types with real basic/pointer/composite DI types
- [ ] Add deterministic DI type caches for structs/enums/generics
- [ ] Verify methods, generics, and user-defined types appear sensibly in LLDB

## Optional Darwin Packaging Follow-Up

- [ ] Decide whether the compiler should generate `.dSYM` bundles automatically
- [ ] If yes, run `dsymutil` before object cleanup or preserve the object long enough
- [ ] Verify shipped binaries remain debuggable after moving them out of the build tree

---

## Recommended Execution Order

Implement in this order:

1. Bridge only
2. Module init/finalize only
3. Function subprograms only
4. AST instruction locations
5. LLDB hello-world validation
6. MIR stmt locations
7. MIR terminator spans
8. Self-host/fixpoint validation
9. Variable info follow-up

Do not batch all of this into one change. The compiler is self-hosting.
Make one logical change, rebuild immediately, and stop to debug as soon as
the stage chain or LLDB behavior disagrees with the plan.
