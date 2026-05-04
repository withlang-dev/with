# Plan: Eliminate All C Source Code

## Context

The With compiler originally had 4 C source files totaling 3,548 lines. The goal is to reduce this to zero — the compiler and runtime should be 100% With + assembly. External libraries (LLVM, libclang) are called through `extern fn` declarations, not C wrapper code.

On macOS, libSystem.B.dylib is the stable kernel interface (not "libc" — it's the OS). Linking it is required and correct. On Linux, raw syscalls via inline assembly replace all library dependencies.

`runtime/with_runtime.h` survives as the one C artifact — it's not source code, it's interface documentation for C consumers of `--emit-c` output. Long-term it should be generated from `@[c_export]` annotations rather than maintained by hand.

## Current C inventory

| File | Lines | Status |
|---|---|---|
| ~~`runtime/helpers.c`~~ | ~~80~~ | **Deleted** — replaced by `rt/cimport_stubs.w` |
| ~~`runtime/with_runtime.c`~~ | ~~84~~ | **Deleted** — already in `rt/fiber_stubs.w` + `rt/panic_runtime.w` |
| ~~`runtime/llvm_bridge.c`~~ | ~~930~~ | **Deleted** — replaced by `rt/llvm_bridge.w` |
| `runtime/clang_bridge.c` | 2454 | Phase 5 (planned) |

`src/main.c` (233K lines) is a build artifact (`--emit-c` output), not source.

## Execution order

`Phase 1 → 2 → 3 → 4 → 5 → 6` (easiest/most impactful first, highest risk last)

---

## Phase 1: Remove c_import from darwin_aarch64.w ✅

**Status: DONE** (commit `ec76973`)

- [x] Write `open()` ABI test — confirmed variadic `open` breaks on aarch64 Darwin, `__open` works
- [x] Remove all 4 `use c_import(...)` lines from `rt/darwin_aarch64.w`
- [x] Add explicit `extern fn` declarations for every imported function
- [x] Replace `open` with `__open` (non-variadic libSystem internal symbol)
- [x] Replace `c_void` with `u8` in pointer types
- [x] Fixpoint verified

**Finding:** The variadic `open()` wrapper on Darwin aarch64 DOES corrupt the mode argument. The fix is to call `__open` directly, which is the non-variadic internal symbol. This is the correct approach — all non-variadic libSystem functions work fine through `extern fn`.

---

## Prerequisite: @[weak] attribute ✅

**Status: DONE** (commit `54f6eb2`)

Added `@[weak]` attribute support to the With language:
- [x] Parser: `pending_weak` flag, recognized in attribute parsing
- [x] AST: `fn_weak_flags` HashMap on AstPool
- [x] Codegen: sets `LLVMWeakAnyLinkage = 5` when `@[weak]` + `@[c_export]`
- [x] Verified: `nm` shows `weak external` for `@[weak]` functions, `external` for normal
- [x] Fixpoint verified

---

## Phase 2: Eliminate helpers.c and with_runtime.c ✅

**Status: DONE** (commit `5f4649e`)

- [x] Created `rt/cimport_stubs.w` with 53 `@[weak] @[c_export]` stubs
- [x] Deleted `runtime/helpers.c` (80 lines C)
- [x] Deleted `runtime/with_runtime.c` (84 lines C)
- [x] Updated Makefile: `HELPERS_OBJ` → `CIMPORT_STUBS_OBJ`
- [x] Updated `src/compiler/Link.w`: `helpers.o` → `cimport_stubs.o`
- [x] Updated `scripts/embed_runtime_objects.sh`: `helpers_o` → `cimport_stubs_o`
- [x] C allowlist reduced from 4 files to 2
- [x] Fixpoint verified, all tests pass

---

## Phase 3: Remove libc from compat_runtime.w and fiber_core_darwin.w

**Status: TODO**. **Effort:** 1 day. **Risk:** Low. Already mostly done.

Both files already use `extern fn` for everything. The only real libc dependency is `malloc/free` calls.

**compat_runtime.w changes:**
- [ ] `malloc/free` → `with_alloc/with_free` (from rt_core). Used in `str_to_c_buf` for temporary C strings passed to `fork`/`execv`/`setenv` — these functions expect null-terminated C strings. The replacement is `with_alloc` + `with_memcpy` + explicit null terminator, same logic as today with a different allocator. **Do not remove the null termination** — the slab allocator does not zero memory.
- [ ] `memcpy/memset` → `with_memcpy/with_memset` (from rt_core)
- [ ] `strlen` → inline `c_strlen` helper (5-line loop)
- [ ] `fork/execv/waitpid/sigaction/etc.` → already `extern fn` from libSystem, keep as-is

**fiber_core_darwin.w changes:**
- [ ] `malloc/free` → `with_alloc/with_free`
- [ ] `memcpy/memset` → `with_memcpy/with_memset`
- [ ] `sysconf(_SC_PAGESIZE)` → hardcoded `16384` (aarch64 macOS always uses 16K pages) or `extern fn vm_page_size` from Mach
- [ ] `mmap/mprotect/munmap/sigaction/sigaltstack/raise/write/_exit/abort` → keep as libSystem `extern fn`

**Files:** `rt/compat_runtime.w`, `rt/fiber_core_darwin.w`

**Verify:** `make build && make fixpoint && make test`

---

## Phase 4: Rewrite llvm_bridge.c in With ✅

**Status: DONE**

- [x] Created `rt/llvm_bridge.w` (1271 lines) with all `extern fn LLVM*` declarations (~200)
- [x] Added ~60 LLVM enum constants (extracted from LLVM 22 headers)
- [x] Implemented `to_cstr` rotating buffer, `c_strlen`, `empty_cstr` helpers in With
- [x] Translated all 197 `wl_*` wrappers with `@[c_export]`
- [x] Updated Makefile: compile `rt/llvm_bridge.w` with seed compiler instead of C compilation
- [x] Removed `runtime/llvm_bridge.c` from C allowlist
- [x] Deleted `runtime/llvm_bridge.c` (930 lines C)
- [x] Fixpoint verified, all tests pass (same pre-existing failures)

**Key findings:**
- `LLVMInitializeNativeTarget/AsmPrinter/AsmParser` are C macros, not real symbols. Replaced with direct calls to `LLVMInitializeAArch64*` functions.
- `module` is a reserved keyword in With — parameter names changed to `mod_ref`.
- Void function calls in if/else expression context need `let _ = ` prefix to avoid MIR type inference error.

---

## Phase 5: Rewrite clang_bridge.c in With

**Status: TODO**. **Effort:** 5-8 days. **Risk:** High (struct-by-value ABI, function pointer callbacks).

The clang bridge is the hardest phase. libclang passes structs by value:
- `CXCursor` (32 bytes): `{ kind: i32, xdata: i32, data: [3]i64 }`
- `CXType` (24 bytes): `{ kind: i32, pad: i32, data: [2]i64 }`
- `CXString` (16 bytes): `{ data: i64, flags: u32, pad: u32 }`

These layouts are ABI-stable within a libclang major version. With handles struct-by-value through its codegen (follows platform ABI: AAPCS64 on aarch64, SysV on x86_64).

**BLOCKING: struct-by-value callback ABI test.** `clang_visitChildren(CXCursor, visitor_fn_ptr, client_data)` takes a function pointer that receives `CXCursor` (32 bytes) by value. This is a hard gate — if the test fails, Phase 5 stops until the With codegen handles struct-by-value callbacks correctly. Do NOT translate 2000 lines before confirming this works.

The ABI test:
```with
extern fn clang_createIndex(exclude: i32, display: i32) -> *mut u8
extern fn clang_getTranslationUnitCursor(tu: *mut u8) -> CXCursor
extern fn clang_visitChildren(parent: CXCursor, visitor: *const u8, data: *mut u8) -> u32

fn test_visitor(cursor: CXCursor, parent: CXCursor, data: *mut u8) -> i32:
    // If we get here with valid cursor.kind, the ABI works
    0  // CXChildVisit_Continue

fn main:
    let idx = clang_createIndex(0, 0)
    // ... parse a TU, get root cursor, call visitChildren with test_visitor ...
```

If the test fails, the fallback is a small assembly thunk that adapts the calling convention. But this should not be needed.

**libc deps to replace:**
- [ ] `malloc/free/realloc` → `with_alloc/with_free` or keep as libSystem `extern fn`
- [ ] `strdup/strlen/strstr/memmove` → implement in With (trivial)
- [ ] `snprintf` → use With's `fmt_*` functions
- [ ] `popen/pclose` → use `with_system` + temp file for SDK path detection

**Steps:**
1. [ ] Declare CXCursor/CXType/CXString/CXSourceLocation/CXSourceRange struct layouts
2. [ ] **Write and run ABI verification test** — hard gate, stop if it fails
3. [ ] Declare all `extern fn clang_*` functions
4. [ ] Implement CImportSession state management in With
5. [ ] Translate declaration collection (clang_visitChildren + callback)
6. [ ] Translate type translation (recursive type resolver, ~250 lines)
7. [ ] Translate query functions (50+ simple wrappers)
8. [ ] Translate macro extraction (preprocessor invocation)
9. [ ] Update Makefile, delete `runtime/clang_bridge.c`

**Files:** `rt/clang_bridge.w` (new), `runtime/clang_bridge.c` (delete), `Makefile`

**Verify:** `make build && make fixpoint && c_import("stdio.h") test passes && make test`

---

## Phase 6: Linux raw syscalls (future)

**Status: NOT IN SCOPE.** When Linux is targeted:
- [ ] Create `rt/linux_aarch64.w` using inline assembly (`asm("svc #0" ...)`)
- [ ] Create `rt/linux_x86_64.w` using inline assembly (`asm("syscall" ...)`)
- [ ] Zero library dependencies — pure kernel interface

---

## End state

```
runtime/
  with_runtime.h          ← C header for --emit-c consumers (interface, not source)
  fiber_asm_aarch64.s     ← context switch assembly
  fiber_asm_x86_64.s      ← context switch assembly
  clang_bridge.c          ← Phase 5 (pending rewrite to With)

rt/
  rt_core.w               ← core runtime (allocator, strings, vec, hashmap, fmt)
  darwin_aarch64.w         ← macOS syscall wrappers (extern fn to libSystem, no c_import) ✅
  llvm_bridge.w            ← LLVM-C API bridge (1271 lines With, replaces 930 lines C) ✅
  clang_bridge.w           ← libclang bridge (Phase 5, planned)
  compat_runtime.w         ← compiler-only: fork/exec/signals (extern fn to libSystem)
  panic_runtime.w          ← panic handler
  fiber_stubs.w            ← non-async stubs
  fiber_core_darwin.w      ← fiber scheduler
  fiber_runtime.w          ← fiber lifecycle
  channel_runtime.w        ← channel implementation
  cimport_stubs.w          ← c_import fallback stubs (@[weak] @[c_export]) ✅
```

**Current: 1 C source file remaining (2,454 lines).** Down from 4 files (3,548 lines).

**Compiler links:** libSystem.B.dylib (Darwin kernel interface), libLLVM (static), libclang (dynamic), libz, libxml2, libc++ (LLVM deps).

## Blocking tests

1. ~~**Phase 1: `open()` variadic ABI**~~ ✅ Confirmed: variadic `open` breaks, `__open` works
2. ~~**Phase 2: Weak symbol support**~~ ✅ Implemented `@[weak]` attribute (commit `54f6eb2`)
3. **Phase 5: CXCursor struct-by-value callback** — receive 32-byte struct by value in a function pointer callback across FFI boundary (TODO)

## Verification

After all phases:
```bash
# Zero C source files
find . -name '*.c' -not -path './out/*' -not -path './.reference/*' \
  -not -path './tests/*' -not -path './src/main.c' | wc -l

# Full build chain
make build && make fixpoint && make test

# emit-c still works
make emit-c-test

# c_import still works
./out/bin/with run test/behavior/c_import_basic.w

# Cross-compile still works
make cross CROSS_TARGET=aarch64-linux
```
