# MIR → C Backend Implementation Plan

## Goal

Add `--emit-c` flag to the With compiler. When passed, the compiler
runs the normal pipeline through MIR, then emits portable C instead
of going through LLVM. The output is a `.c` file (plus runtime files)
that can be compiled to a native binary by any C compiler on any
supported platform.

```
with build --emit-c src/main.w -o main.c
zig cc -target x86_64-linux-gnu main.c runtime/fiber.c runtime/fiber_asm_x86_64.s -o with-linux-x86
```

The LLVM backend remains the default. `--emit-c` is a distribution
and cross-compilation tool.

---

## Non-Goals

- Replacing the LLVM backend.
- Optimizing the emitted C (that's the C compiler's job).
- Supporting every C compiler quirk (target GCC/Clang/Zig CC, C11).
- Changing anything before the MIR stage.

---

## Architecture

```
MIR (existing) → CCodegen.w (new) → .c file
                                   + runtime/ (existing, ships alongside)
                                   + fiber_asm_<arch>.s (existing, ships alongside)
```

One new file: `src/CCodegen.w`. It walks a `MirModule` and writes C.
Nothing else in the compiler changes.

---

## MIR → C Mapping

The MIR is already shaped like C. The translation is mechanical.

### Basic Blocks → Labels + Gotos

```
// MIR                          // C
bb0:                            bb0: {
    _3 = const 42i32;               _3 = 42;
    goto -> bb1;                     goto bb1;
                                }
bb1:                            bb1: {
    _0 = move _3;                   _0 = _3;
    return;                          return _0;
                                }
```

### Locals → C Local Variables

```
// MIR                          // C
let _0: i32;                    int32_t _0;
let _1: str;                    with_str _1;
let _2: bool;                   bool _2;
let _3: User;                   User _3;
```

### Statements

| MIR Statement | C Output |
|---|---|
| `_3 = rvalue` (SK_ASSIGN) | `_3 = <rvalue>;` |
| `StorageLive(_3)` (SK_STORAGE_LIVE) | `/* StorageLive _3 */` (no-op in C, local scope handles it) |
| `StorageDead(_3)` (SK_STORAGE_DEAD) | `/* StorageDead _3 */` (no-op unless drop needed) |
| `Drop(_3)` (SK_DROP) | `with_drop_TypeName(&_3);` |
| `Nop` (SK_NOP) | (omit) |

### Terminators

| MIR Terminator | C Output |
|---|---|
| `goto -> bb1` (TK_GOTO) | `goto bb1;` |
| `return` (TK_RETURN) | `return _0;` |
| `unreachable` (TK_UNREACHABLE) | `__builtin_unreachable();` or `abort();` |
| `switchInt(_2) -> [0: bb1, otherwise: bb2]` (TK_SWITCH_INT) | `if (_2) { goto bb2; } else { goto bb1; }` |
| `switchInt(_5) -> [0: bb1, 1: bb2, 2: bb3, otherwise: bb4]` (TK_SWITCH_INT) | `switch (_5) { case 0: goto bb1; case 1: goto bb2; ... default: goto bb4; }` |
| `call fn(args) -> [return: _3, next: bb2]` (TK_CALL) | `_3 = fn(args); goto bb2;` |
| `drop_and_goto(_3) -> bb1` (TK_DROP_AND_GOTO) | `with_drop_TypeName(&_3); goto bb1;` |

### Rvalues

| MIR Rvalue | C Output |
|---|---|
| `Use(copy _3)` (RK_USE + OK_COPY) | `_3` |
| `Use(move _3)` (RK_USE + OK_MOVE) | `_3` (C doesn't distinguish, drops handle ownership) |
| `Use(const 42i32)` (RK_USE + OK_CONSTANT) | `42` |
| `BinOp(Add, _1, _2)` (RK_BIN_OP) | `(_1 + _2)` |
| `UnOp(Neg, _1)` (RK_UN_OP) | `(-_1)` |
| `Ref(Shared, _3)` (RK_REF) | `(&_3)` |
| `AddrOf(_3)` (RK_ADDR_OF) | `(&_3)` |
| `Ref(Mutable, _3)` (RK_REF) | `(&_3)` |
| `Aggregate(StructName, fields)` (RK_AGGREGATE) | `(StructName){ .f0 = _1, .f1 = _2 }` (C99 compound literal) |
| `Discriminant(_3)` (RK_DISCRIMINANT) | `(_3).tag` |
| `Cast(_3, target_type)` (RK_CAST) | `((target_type)_3)` |
| `Len(_3)` (RK_LEN) | `(_3).len` |

### Places (Projections)

| MIR Place | C Output |
|---|---|
| `_3` | `_3` |
| `_3.field[2]` (PK_FIELD) | `_3.field2` |
| `_3[_4]` (PK_INDEX) | `_3.data[_4]` |
| `*_3` (PK_DEREF) | `(*_3)` |
| `_3 downcast Variant(1)` (PK_DOWNCAST) | `_3.variants.Variant1` |

### Constants

| MIR Constant | C Output |
|---|---|
| `CK_INT` | Integer literal |
| `CK_BOOL` | `true` / `false` |
| `CK_STR` | `with_str_lit("escaped string")` |
| `CK_UNIT` | `(with_unit){}` or omit |
| `CK_FLOAT` | Float literal with suffix |
| `CK_ZERO_SIZED` | `(TypeName){}` (empty struct literal) |

---

## Type Mapping

| With Type | C Type |
|---|---|
| `i8` / `i16` / `i32` / `i64` | `int8_t` / `int16_t` / `int32_t` / `int64_t` |
| `u8` / `u16` / `u32` / `u64` | `uint8_t` / `uint16_t` / `uint32_t` / `uint64_t` |
| `f32` / `f64` | `float` / `double` |
| `bool` | `bool` |
| `Unit` | `void` (return type) or empty struct (value) |
| `str` | `with_str` (runtime struct: `{ char* data; size_t len; size_t cap; }`) |
| `&T` | `const T*` |
| `&mut T` | `T*` |
| `Vec[T]` | `with_vec_T` (generated per instantiation) |
| `Option[T]` | `with_option_T` (tagged union per instantiation) |
| `Result[T, E]` | `with_result_T_E` (tagged union per instantiation) |
| User struct | C struct with same fields |
| Enum (algebraic) | Tagged union: `struct { int32_t tag; union { ... } variants; }` |
| `fn(A, B) -> C` | `C (*)(A, B)` (function pointer) |
| Closure | Struct with captures + function pointer |
| `Task[T]` | `with_task` (opaque handle to fiber runtime) |

---

## Emitted File Structure

`--emit-c` produces a single `.c` file with:

```c
// ---- with_output.c ----

// 1. Preamble
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include "with_runtime.h"

// 2. Forward declarations of all types
typedef struct User User;
typedef struct with_vec_i32 with_vec_i32;

// 3. Type definitions (structs, tagged unions)
struct User {
    with_str name;
    int32_t age;
};

struct with_vec_i32 {
    int32_t* data;
    size_t len;
    size_t cap;
};

// 4. Forward declarations of all functions
int32_t main_fn(void);
User create_user(with_str name, int32_t age);

// 5. Function bodies
int32_t main_fn(void) {
    int32_t _0;
    with_str _1;
    User _2;

    bb0: {
        _1 = with_str_lit("Alice");
        _2 = create_user(_1, 30);
        with_println_user(&_2);
        _0 = 0;
        goto bb1;
    }
    bb1: {
        with_drop_User(&_2);
        with_drop_str(&_1);
        return _0;
    }
}

// 6. Entry point
int main(int argc, char** argv) {
    with_runtime_init();
    int32_t result = main_fn();
    with_runtime_shutdown();
    return result;
}
```

---

## Runtime Files (already exist, ship alongside)

The user compiles the output with:

```bash
zig cc -target <triple> \
    with_output.c \
    runtime/with_runtime.c \
    runtime/fiber.c \
    runtime/fiber_asm_<arch>.s \
    -o output_binary
```

### `with_runtime.h` — shared header

- `with_str` type and string operations
- `with_vec_*` macros or inline helpers
- `with_option_*` / `with_result_*` tag union helpers
- Drop function signatures
- Fiber/task API declarations
- `with_runtime_init()` / `with_runtime_shutdown()`
- `with_println`, `with_assert`, `with_panic`

### `with_runtime.c` — portable C runtime

- String allocator, `with_str_lit`, `with_str_concat`, etc.
- Vec grow/push/pop
- Print formatting
- Panic handler
- Allocator (arena or malloc-based)

### `fiber.c` + `fiber_asm_<arch>.s` — fiber runtime (existing)

- Already written in C and platform assembly
- `fiber_asm_aarch64.s` exists
- `fiber_asm_x86_64.s` needs writing (one-time, ~30 lines)

---

## Implementation Checklist

### 0. Prerequisites

- [x] Write `fiber_asm_x86_64.s` — x86_64 stack-switching trampoline.
      Port from minicoro or libco. ~30 lines. Test on Linux x86_64.

### 1. `with_runtime.h` — C runtime header

- [x] Define `with_str` struct and string operation signatures.
- [x] Define `with_runtime_init` / `with_runtime_shutdown` signatures.
- [x] Define `with_panic`, `with_assert` signatures.
- [x] Define fiber/task API signatures (`with_fiber_create`, `with_fiber_switch`, etc.).
- [x] Define macros or templates for generic containers (`with_vec`, `with_option`, `with_result`).
      These may be emitted inline by CCodegen for each concrete instantiation instead.

### 2. `with_runtime.c` — C runtime implementation

- [x] Implement string operations (create, concat, slice, drop, print).
- [x] Implement panic handler (print message + file:line, abort).
- [x] Implement `with_runtime_init` (fiber scheduler startup) and `with_runtime_shutdown`.
- [x] Verify existing `fiber.c` works standalone when compiled with `zig cc`.

### 3. `src/CCodegen.w` — MIR → C emitter

This is the core deliverable. It walks `MirModule` and writes a `.c` file.

#### 3a. Type emission

- [ ] `emit_type_forward_decls(mir_module)` — emit `typedef struct X X;` for all user types.
- [ ] `emit_type_defs(mir_module)` — emit full struct definitions.
- [ ] `emit_enum_as_tagged_union(enum_type)` — `struct { int32_t tag; union { ... } variants; }`.
- [ ] `emit_vec_instantiation(elem_type)` — `struct with_vec_T { T* data; size_t len; size_t cap; };`.
- [ ] `emit_option_instantiation(inner_type)` — tagged union with `None`/`Some`.
- [ ] `emit_result_instantiation(ok_type, err_type)` — tagged union with `Ok`/`Err`.
- [ ] `emit_closure_struct(closure_id, capture_types)` — struct for captured variables.

#### 3b. Function emission

- [x] `emit_fn_forward_decl(fn_body)` — `return_type fn_name(params);`
- [x] `emit_fn_body(fn_body)` — full function with locals, basic blocks, terminators.
- [x] `emit_locals(fn_body)` — local variable declarations at function top.
- [x] `emit_basic_block(bb)` — label, statements, terminator.

#### 3c. Statement emission

- [x] `emit_assign(place, rvalue)` — `place = rvalue;`
- [ ] `emit_drop(place, type)` — `with_drop_TypeName(&place);`
- [x] `emit_storage_live(local)` — comment or no-op.
- [x] `emit_storage_dead(local)` — comment or no-op.

#### 3d. Terminator emission

- [x] `emit_goto(target_bb)` — `goto bbN;`
- [x] `emit_return()` — `return _0;`
- [x] `emit_unreachable()` — `abort();` or `__builtin_unreachable();`
- [x] `emit_switch_int(discriminant, targets)` — `switch` or `if` chain.
- [x] `emit_call(fn, args, dest, next_bb)` — `dest = fn(args); goto next_bb;`
- [ ] `emit_drop_and_goto(place, target_bb)` — drop then goto.

#### 3e. Rvalue emission

- [x] `emit_use(operand)` — copy or move (same in C).
- [x] `emit_bin_op(op, lhs, rhs)` — `(lhs op rhs)`.
- [x] `emit_un_op(op, operand)` — `(op operand)`.
- [x] `emit_ref(borrow_kind, place)` — `(&place)`.
- [x] `emit_addr_of(place)` — `(&place)`.
- [ ] `emit_aggregate(type, fields)` — C99 compound literal.
- [ ] `emit_discriminant(place)` — `(place).tag`.
- [x] `emit_cast(operand, target_type)` — `((target_type)operand)`.
- [ ] `emit_len(place)` — `(place).len`.

#### 3f. Place emission

- [x] `emit_place(place)` — walk projection chain: field, index, deref, downcast.

#### 3g. Constant emission

- [x] `emit_const_int(value)` — integer literal.
- [x] `emit_const_bool(value)` — `true` / `false`.
- [x] `emit_const_str(symbol)` — `with_str_lit("escaped string")`.
- [x] `emit_const_float(value)` — float literal with suffix.
- [x] `emit_const_unit()` — `(with_unit){}` or omit.
- [x] `emit_const_zero_sized(type)` — `(TypeName){}` (empty struct literal).

#### 3h. Entry point

- [x] `emit_main_wrapper()` — `int main(int argc, char** argv) { ... }`.
      Calls `with_runtime_init()`, calls the With `main` function,
      calls `with_runtime_shutdown()`, returns exit code.

### 4. Driver integration

- [x] Add `--emit-c` flag to CLI parser in `src/main.w`.
- [x] Thread flag through `Driver.w`.
- [x] When `--emit-c` is set, after MIR pass, call `CCodegen.emit_module(mir_module)` instead of
      `Codegen.emit_module(mir_module)`.
- [x] Write output to file specified by `-o` (default: input name with `.c` extension).
- [x] Print instructions for compiling: the `zig cc` invocation with runtime files.

### 5. Testing

- [x] Round-trip test: compile hello world to C, compile C with `zig cc`, run, verify output.
- [ ] Round-trip test: compile the test suite to C, compile with `zig cc`, run all tests.
- [x] Cross-compilation test: emit C on macOS, compile with `zig cc -target x86_64-linux-gnu`,
      run in Docker container, verify output.
- [ ] Compare: `with build program.w && ./program` vs
      `with build --emit-c program.w -o program.c && zig cc program.c runtime/*.c -o program && ./program`.
      Output must be identical.
- [ ] Verify emitted C compiles cleanly with `-Wall -Werror` under GCC, Clang, and `zig cc`.

### 6. Cross-compilation convenience script

- [x] `scripts/cross-build.sh <target-triple> <source.w>`:
  - Runs `with build --emit-c` on source.
  - Selects correct `fiber_asm_<arch>.s` based on target.
  - Invokes `zig cc -target <triple>` with all runtime files.
  - Outputs binary.

### 7. Self-hosting cross-compilation test

- [ ] Compile the With compiler itself to C: `with build --emit-c src/main.w -o with_compiler.c`
- [ ] Cross-compile for all four targets:
  ```
  zig cc -target aarch64-macos    with_compiler.c runtime/*.c runtime/fiber_asm_aarch64.s -o with-aarch64-macos
  zig cc -target x86_64-macos     with_compiler.c runtime/*.c runtime/fiber_asm_x86_64.s  -o with-x86_64-macos
  zig cc -target x86_64-linux-gnu with_compiler.c runtime/*.c runtime/fiber_asm_x86_64.s  -o with-x86_64-linux
  zig cc -target aarch64-linux-gnu with_compiler.c runtime/*.c runtime/fiber_asm_aarch64.s -o with-aarch64-linux
  ```
- [ ] Verify each binary runs and can compile hello world on its target platform.

---

## Acceptance Criteria

1. `with build --emit-c hello.w -o hello.c` produces valid C11.
2. `zig cc hello.c runtime/with_runtime.c runtime/fiber.c runtime/fiber_asm_x86_64.s -o hello`
   produces a working binary.
3. All existing tests pass when run through the C backend path.
4. The With compiler itself can be compiled to C and cross-compiled for
   all four targets from a single Mac.
5. Emitted C compiles without warnings under `-Wall -Werror` on GCC and Clang.

---

## What This Unlocks

- **Cross-compilation from one machine.** Four targets, your Mac, five minutes.
- **Universal bootstrap.** Anyone with a C compiler can build the With compiler.
  No Zig, no LLVM, no special dependencies.
- **Debugging.** Step through generated C in any debugger. Run through ASan/MSan/valgrind.
- **LLVM becomes optional.** Users who want optimized builds install LLVM.
  Everyone else uses the C backend. The compiler works either way.
