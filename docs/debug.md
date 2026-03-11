# DWARF Debug Info Implementation Plan

## Goal

Emit source-level DWARF debug info from the LLVM backend so that
LLDB shows With source lines instead of disassembly. Breakpoints,
stepping, and source listing must work on user code.

This is a discrete backend task, not part of the general quality pass.

---

## Current State

- MIR codegen is the active path. All tests pass. Fixpoint holds.
- MIR carries statement spans (`MirBody.stmt_spans`).
- MIR terminators do NOT carry spans yet — this must be added.
- `runtime/llvm_bridge.c` does not include `llvm-c/DebugInfo.h`
  and exports no DIBuilder helpers.
- `src/Codegen.w` has no debug metadata.

---

## Scope

### Phase 1 (release gate)

- `DICompileUnit`, `DIFile`, `DISubprogram`
- Per-instruction source locations via `LLVMSetCurrentDebugLocation2`
- Enough metadata for LLDB to resolve file/line for user functions
- MIR statement locations (spans already exist)
- MIR terminator locations (spans must be added)

### Phase 1 does NOT include

- Local variable inspection (`frame variable`)
- Parameter inspection
- Global variable debug info
- Full struct/enum DI type graphs
- dSYM packaging automation
- `-g0` / `-gline-tables-only` flags (always-on for Phase 1)

### Phase 2 (post-release)

- Variable and parameter debug records
- Richer DI types for structs, enums, generics
- Lexical block scopes for better stepping in nested blocks
- `--release` flag strips debug info
- `DW_LANG` registration for With
- `#line` directives in `--emit-c` output

---

## Acceptance Criteria

All of the following must be true:

- `./out/bin/with-stage2 build examples/hello.w` succeeds.
- LLDB shows With source, not disassembly:
  ```
  lldb -b \
    -o 'breakpoint set --name main' \
    -o 'process launch' \
    -o 'source list' \
    -o 'thread step-over' \
    -o 'source list' \
    -o quit \
    -- ./examples/hello
  ```
- LLVM IR contains `!llvm.dbg.cu`, `!DICompileUnit`,
  `!DISubprogram`, and `!dbg` instruction attachments.
- `make build` passes.
- `make fixpoint` passes.
- `./out/bin/with-stage2 check src/main.w` passes.
- No O(n²) line lookup in hot codegen paths.

---

## Design Decisions

### 1. MIR Only

MIR is the active codegen path. All debug instrumentation goes
through MIR. No AST codegen is instrumented. If AST codegen is
deleted later, no debug work is lost.

This matches Zig (debug info from AIR) and Rust (debug info
from MIR).

### 2. Always-On for Phase 1

Emit full DWARF metadata by default. No `-g` flags yet.
`--release` stripping is Phase 2.

### 3. Reproducible Paths

Use source paths as-is from the compiler input. Do not
canonicalize to absolute host-specific paths. Fixpoint depends
on deterministic output — machine-specific paths would break it.

### 4. Fast Offset-to-Location

Do not reuse the current `span_to_line()` which scans from the
start of source text every time. Instead:

- Use `compiler.foundation.Source`
- Build line offsets once from `source_text`
- Binary search for `(line, col)` from byte offset
- O(log n) per lookup, not O(n)

### 5. Phase 1 Type Strategy

Use the smallest type model that makes `DISubprogram` valid:

| With type | DI type |
|---|---|
| `void` / `Unit` return | `CreateUnspecifiedType("Unit")` |
| `bool` | Basic type, 1 bit, boolean encoding |
| `i8`..`i64` | Basic type, real bit width, signed |
| `u8`..`u64` | Basic type, real bit width, unsigned |
| `f32`, `f64` | Basic type, float encoding |
| Pointers / refs | Pointer to unspecified |
| Structs / enums | `CreateUnspecifiedType` with stable name |

Full composite DI types are Phase 2. Line stepping does not
require rich type metadata.

---

## File Changes

### `runtime/llvm_bridge.c`

Add LLVM-C debug bridge wrappers.

Include:
- `llvm-c/DebugInfo.h`

Required wrappers:

```c
// Builder lifecycle
i64 wl_di_create_builder(i64 module)
void wl_di_dispose_builder(i64 builder)
void wl_di_finalize(i64 builder)

// Module metadata
i32 wl_debug_metadata_version()
void wl_add_module_flag_int(i64 module, const char* key, i32 val)

// File and compile unit
i64 wl_di_create_file(i64 builder, const char* filename, const char* directory)
i64 wl_di_create_compile_unit(i64 builder, i64 file, const char* producer,
    i32 is_optimized, i32 dwarf_version)

// Subprogram
i64 wl_di_create_subroutine_type(i64 builder, i64 file, i64* param_types, i32 count)
i64 wl_di_create_function(i64 builder, i64 scope, const char* name,
    const char* linkage_name, i64 file, i32 line, i64 type,
    i32 is_definition, i32 scope_line, i32 is_optimized)
void wl_di_set_subprogram(i64 function, i64 subprogram)

// Locations
i64 wl_di_create_debug_location(i64 context, i32 line, i32 col, i64 scope)
void wl_di_set_current_location(i64 builder, i64 location)
void wl_di_clear_current_location(i64 builder)

// Phase 1 helpers
i32 wl_di_flag_zero()
i32 wl_dwarf_lang_c()
```

All handles use the existing `i64` opaque pattern. No new
handle types needed.

### `src/Codegen.w`

Main implementation site.

**New state fields:**

```
di_builder: i64
di_compile_unit: i64
di_file: i64
di_source: Source                    // cached line offsets
di_fn_subprograms: HashMap[i32, i64] // fn_sym -> subprogram
```

**New helpers:**

```
fn debug_init_module(self: Codegen)
fn debug_finalize_module(self: Codegen)
fn debug_enter_function(self: Codegen, fn_sym: i32, function: i64)
fn debug_set_location(self: Codegen, byte_offset: i32)
fn debug_clear_location(self: Codegen)
```

**Integration in `gen_function_mir`:**

```
fn gen_function_mir(self: Codegen, fn_node: i32, body: MirBody):
    let fn_sym = self.pool.get_data0(fn_node)
    let function = self.fn_values.get(fn_sym).unwrap()

    // Create DISubprogram and set as current scope
    self.debug_enter_function(fn_sym, function as i64)

    // Set location for prologue (param stores, entry allocas)
    let fn_span = self.pool.get_span_start(fn_node)
    self.debug_set_location(fn_span)

    // ... existing param setup ...

    for bb in 0..body.bb_count():
        // ... existing block setup ...

        for stmt in bb_stmts:
            // Set location from MIR statement span
            let span = body.stmt_spans.get(stmt as i64)
            if span > 0:
                self.debug_set_location(span)
            self.mir_emit_stmt(body, stmt)

        // Set location from MIR terminator span
        let term_span = body.term_spans.get(bb as i64)
        if term_span > 0:
            self.debug_set_location(term_span)
        self.mir_emit_terminator(body, bb)
```

**Module lifecycle:**

```
fn gen_module(self: Codegen):
    self.debug_init_module()
    // ... existing function generation ...
    self.debug_finalize_module()
    self.verify()
```

### `src/Mir.w`

Add terminator span storage.

```
// Add parallel to existing terminator arrays
bb_term_spans: Vec[i32]    // source byte offset per BB terminator
```

### `src/MirLower.w`

Thread spans through terminator creation.

```
// Update set_terminator to accept span
fn set_terminator(self: MirBody, bb: i32, kind: i32,
    d0: i32, d1: i32, d2: i32, d3: i32, span: i32)

// Update MirBuilder.terminate to pass span
fn terminate(self: MirBuilder, kind: i32,
    d0: i32, d1: i32, d2: i32, d3: i32, span: i32)
```

Populate spans from the AST node that caused the terminator:
- `return` → span of the return expression
- `break` / `continue` → span of the break/continue keyword
- `if` branch → span of the condition
- `match` switch → span of the scrutinee
- Call → span of the call expression
- `goto` (implicit fall-through) → span of the enclosing block

---

## `debug_init_module` Detail

```
fn debug_init_module(self: Codegen):
    // Build Source for fast offset-to-location lookup
    self.di_source = Source.from_string(
        self.source_file, self.source_text)

    // Split source path: "src/main.w" -> ("src", "main.w")
    let (dir, file) = split_path(self.source_file)

    // Create DIBuilder
    self.di_builder = wl_di_create_builder(self.llmod)

    // Create DIFile
    self.di_file = wl_di_create_file(self.di_builder, file, dir)

    // Module flags
    wl_add_module_flag_int(self.llmod, "Debug Info Version",
        wl_debug_metadata_version())
    wl_add_module_flag_int(self.llmod, "Dwarf Version", 5)

    // Create compile unit
    self.di_compile_unit = wl_di_create_compile_unit(
        self.di_builder,
        self.di_file,
        "with self-hosted compiler",
        self.opt_level > 0,
        5)  // DWARF version
```

## `debug_enter_function` Detail

```
fn debug_enter_function(self: Codegen, fn_sym: i32, function: i64):
    let fn_name = self.intern.resolve(fn_sym)
    let fn_node = // look up from fn_sym
    let fn_span = self.pool.get_span_start(fn_node)
    let loc = self.di_source.offset_to_location(fn_span)
    let line = loc.line + 1   // LLVM is 1-based

    // Create subroutine type (minimal for Phase 1)
    let sub_type = wl_di_create_subroutine_type(
        self.di_builder, self.di_file, null, 0)

    // Create subprogram
    let subprogram = wl_di_create_function(
        self.di_builder,
        self.di_file,          // scope = file
        fn_name,               // display name
        fn_name,               // linkage name
        self.di_file,          // file
        line,                  // line number
        sub_type,              // type
        1,                     // is_definition
        line,                  // scope_line
        self.opt_level > 0)    // is_optimized

    wl_di_set_subprogram(function, subprogram)
    self.di_fn_subprograms.insert(fn_sym, subprogram)
```

## `debug_set_location` Detail

```
fn debug_set_location(self: Codegen, byte_offset: i32):
    if byte_offset <= 0:
        wl_di_clear_current_location(self.builder)
        return
    let loc = self.di_source.offset_to_location(byte_offset)
    let line = loc.line + 1    // 1-based
    let col = loc.col + 1      // 1-based
    let scope = self.di_fn_subprograms.get(
        self.current_function_name_sym).unwrap() as i64
    let di_loc = wl_di_create_debug_location(
        self.context, line, col, scope)
    wl_di_set_current_location(self.builder, di_loc)
```

---

## Execution Order

Each step is independently testable. Rebuild and verify fixpoint
after each step. Do not batch.

1. **Bridge only.** Add wrappers to `llvm_bridge.c`. Verify it
   compiles. No codegen changes yet.

2. **Module init/finalize.** Create DIBuilder, DIFile,
   DICompileUnit. Finalize before verify. Confirm IR contains
   `!llvm.dbg.cu`. Verify fixpoint.

3. **MIR terminator spans.** Add `bb_term_spans` to MirBody.
   Thread spans through `set_terminator` and `terminate`.
   Populate from AST node spans. Verify fixpoint.

4. **Function subprograms.** Create DISubprogram per user
   function. Attach with `wl_di_set_subprogram`. Confirm IR
   contains `!DISubprogram`. Verify fixpoint.

5. **MIR statement locations.** In `gen_function_mir`, set
   debug location from `stmt_spans` before each statement.
   Confirm IR instructions have `!dbg` attachments.
   Verify fixpoint.

6. **MIR terminator locations.** Set debug location from
   `term_spans` before each terminator. Verify fixpoint.

7. **LLDB validation.** Build hello world. Run in LLDB.
   Confirm source lines appear. Confirm stepping works.
   Test with a loop/match example.

8. **Self-host validation.** `make build`, `make fixpoint`,
   `./out/bin/with-stage2 check src/main.w`. All pass.

---

## Risks and Mitigations

### Performance: per-instruction location lookup

Use `Source.offset_to_location()` with precomputed line
offsets and binary search. O(log n) per lookup. Do not
use the existing `span_to_line()` linear scan.

### Determinism: metadata construction

Do not iterate unordered maps. Do not include timestamps
or machine-specific paths. Use source-order traversal and
the path strings already provided by compiler input.

### Binary size: always-on debug info

Phase 1 emits full DWARF always. This increases binary size.
Phase 2 adds `--release` to strip debug info. The 33K hello
world will grow — accept this for Phase 1 and fix in Phase 2.

### MIR terminator spans: missing data

Statement spans exist. Terminator spans do not. Step 3 adds
them. Without terminator spans, returns, branches, and calls
have no source location — stepping through control flow would
show disassembly. This is why step 3 must come before step 5.

---

## Checklist

### Phase 1

- [x] Add `llvm-c/DebugInfo.h` to `runtime/llvm_bridge.c`
- [x] Add `wl_di_*` wrapper functions to bridge
- [x] Declare bridge functions in `src/Codegen.w`
- [x] Add debug state fields to `Codegen`
- [x] Add `Source` for cached offset-to-location lookup
- [x] Implement `debug_init_module`
- [x] Add module flags for debug version and DWARF version
- [x] Implement `debug_finalize_module`, call before verify
- [x] Add `bb_term_spans` to `MirBody`
- [x] Thread spans through `MirBody.set_terminator`
- [x] Thread spans through `MirBuilder.terminate`
- [x] Populate terminator spans from AST node spans
- [x] Implement `debug_enter_function`
- [x] Create `DISubprogram` per user function
- [x] Attach subprograms with `wl_di_set_subprogram`
- [x] Implement `debug_set_location` and `debug_clear_location`
- [x] Set location from `stmt_spans` before each MIR statement
- [x] Set location from `term_spans` before each MIR terminator
- [x] Set location for function prologue (param stores, allocas)
- [x] Clear location for synthetic instructions
- [x] Verify `examples/hello.w` shows source in LLDB
- [x] Verify loop/match example steps through source
- [x] `make build` passes
- [x] `make fixpoint` passes
- [x] `./out/bin/with-stage2 check src/main.w` passes

### Phase 2

- [ ] Add `-g0` / `--release` to strip debug info
- [ ] Add `#line` directives to `--emit-c` output
- [ ] Variable and parameter debug records
- [ ] Rich DI types for structs, enums, generics
- [ ] Lexical block scopes
- [ ] Register `DW_LANG` for With
- [x] dSYM packaging on macOS