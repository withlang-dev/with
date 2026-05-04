# Zig Features That With Doesn't Have

A comprehensive catalog of Zig language features tested in `.reference/zig/test/behavior/*.zig` that have no equivalent in With. Organized by category. Each entry names the feature, explains what it does, and references the Zig test file(s) that exercise it.

Total Zig behavior tests: **2,043** across 116 files.
Of those, roughly **1,200+** tests cover features With doesn't have.

---

## 1. SIMD / Vector Operations

### 1a. Fixed-Width Vectors (`@Vector`)
**File:** `vector.zig` (56 tests)

Zig has a first-class SIMD vector type `@Vector(N, T)` where `N` is a compile-time lane count and `T` is a scalar element type. Arithmetic operators (`+`, `-`, `*`, `/`), comparisons, and bitwise operations all work element-wise across the entire vector. The compiler maps these directly to hardware SIMD instructions (SSE, AVX, NEON) where available, falling back to scalar loops otherwise. Tests cover vector arithmetic, reduction (`@reduce`), splat (`@splat`), and coercion between vectors and arrays.

### 1b. Vector Shuffle (`@shuffle`)
**File:** `shuffle.zig` (4 tests)

`@shuffle` reorders or selects lanes from one or two vectors using a compile-time index mask, analogous to x86 `_mm_shuffle_ps` or ARM `vtbl`. Each element of the result is drawn from either the first or second source vector based on the mask index. Negative indices select from the second vector. This is essential for efficient SIMD permutations like transpose, interleave, and broadcast.

### 1c. Vector Select (`@select`)
**File:** `select.zig` (3 tests)

`@select` performs a lane-wise conditional: given a boolean vector predicate and two value vectors, it picks elements from the first vector where the predicate is true, and from the second where false. This maps to hardware blend instructions (`vblendvps`, `vbsl`). It is the SIMD equivalent of a ternary operator.

### 1d. String Literal to Vector (`@as(@Vector, "str".*`)
**File:** `lower_strlit_to_vector.zig` (1 test)

Zig can convert a string literal (which is a `[N]u8` array) into a `@Vector(N, u8)` for SIMD processing. This enables applying vector operations to string data — useful for SIMD-accelerated parsing, searching, and transformation.

---

## 2. Atomics and Threading

### 2a. Atomic Operations (`@atomicLoad`, `@atomicStore`, `@atomicRmw`, `@cmpxchg`)
**File:** `atomics.zig` (13 tests)

Zig provides built-in functions for lock-free atomic operations with explicit memory ordering (`.monotonic`, `.acquire`, `.release`, `.seq_cst`, `.acq_rel`). `@atomicRmw` supports operations like `.Add`, `.Sub`, `.Xchg`, `.And`, `.Or`, `.Nand`, `.Min`, `.Max`. `@cmpxchgWeak` and `@cmpxchgStrong` implement compare-and-swap. These compile directly to hardware atomic instructions and are the building blocks for lock-free data structures.

### 2b. Thread-Local Storage (`threadlocal`)
**File:** `threadlocal.zig` (3 tests)

The `threadlocal` keyword declares variables that have a separate instance per OS thread. Each thread sees its own copy; modifications in one thread are invisible to others. The compiler uses the platform's TLS mechanism (e.g., `__thread` on ELF, `__declspec(thread)` on Windows). Tests verify that spawned threads get independent copies of threadlocal variables.

---

## 3. Inline Assembly

### 3a. `asm` Expression
**File:** `asm.zig` (7 tests)

Zig's `asm` expression embeds target-specific assembly instructions directly into the program. It supports input/output constraints (similar to GCC extended asm), clobber lists, and can be marked `volatile` to prevent the optimizer from reordering or eliminating it. Tests cover reading special registers (e.g., stack pointer), performing arithmetic in assembly, and using memory constraints.

### 3b. x86_64-Specific Tests
**File:** `x86_64.zig` (0 tests in main file; uses sub-files)

Architecture-specific behavior tests for x86_64 features like specific register usage, calling conventions, and instruction encoding edge cases.

---

## 4. Packed Structs and Unions

### 4a. Packed Structs
**File:** `packed-struct.zig` (40 tests)

A `packed struct` lays out fields with exact bit-level precision — no padding, no alignment gaps. Fields can be non-byte-sized integers (e.g., `u3`, `u12`). A packed struct with fields totaling 32 bits occupies exactly 4 bytes. You can take pointers to individual bit-fields (which become special proxy pointers), cast the entire struct to its backing integer type, and use it for memory-mapped I/O registers, network protocol headers, or file format parsing. Tests cover bit-field access, pointer-to-field, nested packed structs, and endianness.

### 4b. Packed Struct with Explicit Backing Integer
**File:** `packed_struct_explicit_backing_int.zig` (1 test)

Packed structs can specify an explicit backing integer type (e.g., `packed struct(u32) { ... }`), ensuring the struct's in-memory representation is exactly that integer type. This guarantees ABI compatibility with C bitfields and enables direct `@bitCast` between the struct and integer.

### 4c. Packed Unions
**File:** `packed-union.zig` (6 tests)

Like packed structs, but for tagged unions. A `packed union` overlaps all variants in the same bit-space without alignment padding. The tag field can be a specific-width enum. This is used for compact discriminated unions in protocols and file formats where every bit matters.

### 4d. Empty Unions
**File:** `empty_union.zig` (8 tests)

Zig allows unions with zero-size types (like `void`) as fields. An empty union or a union where all fields are zero-sized still functions correctly for dispatch. Tests verify that switching on such unions works and that they have the expected size of zero.

---

## 5. Non-Byte-Sized Integers

### 5a. Arbitrary-Width Integers (`u3`, `i7`, `u21`, `i128`, etc.)
**Files:** `int128.zig` (5 tests), `cast_int.zig` (6 tests), `truncate.zig` (10 tests), `int_comparison_elision.zig` (2 tests)

Zig supports integer types of any bit width from `u0`/`i0` to `u65535`/`i65535`. Non-standard widths like `u3` (0–7), `u21` (for Unicode codepoints), or `i7` are first-class types with full arithmetic, comparison, and casting support. The compiler handles the masking and sign-extension automatically. 128-bit integers (`u128`, `i128`) get special codegen for targets without native 128-bit support (using pairs of 64-bit registers). Tests in `cast_int.zig` exercise coercing non-byte-sized integers across the 32-bit boundary. Tests in `truncate.zig` cover `@truncate` on `u0`, `i0`, and non-power-of-two widths.

---

## 6. Compile-Time Execution (`comptime`)

### 6a. Compile-Time Evaluation
**File:** `eval.zig` (109 tests)

Zig's `comptime` keyword forces an expression, block, or function to execute at compile time. This goes far beyond simple constant folding — any Zig code can run at comptime, including loops, function calls, memory allocation (into comptime-only allocator), and type construction. Tests cover compile-time arithmetic, compile-time struct/array manipulation, compile-time function evaluation, labeled break from comptime blocks, and interaction between runtime and comptime values.

### 6b. Comptime Memory
**File:** `comptime_memory.zig` (32 tests)

Tests specifically for compile-time memory semantics: creating arrays, slices, and structs at compile time, modifying them, and ensuring the results are correctly materialized into the runtime binary. Covers `@ptrCast` at comptime, comptime slice operations, and the rules for what memory operations are legal during compilation.

### 6c. Functions in Structs at Comptime
**File:** `fn_in_struct_in_comptime.zig` (1 test)

Tests the edge case of defining a struct type inside a comptime block, where the struct contains methods. Verifies that the methods are correctly accessible and callable.

---

## 7. Type Introspection and Reflection

### 7a. `@typeInfo`
**File:** `type_info.zig` (34 tests)

`@typeInfo` returns a compile-time struct describing any type's structure: for a struct, it lists all fields (name, type, default value, alignment); for an enum, all variants and their integer values; for a function, parameter types and return type; etc. This enables generic code that inspects and adapts to arbitrary types. Tests cover introspection of structs, enums, unions, arrays, pointers, optionals, error unions, and functions.

### 7b. `@typeName`
**File:** `typename.zig` (8 tests)

`@typeName` returns the fully-qualified name of any type as a compile-time string slice. For example, `@typeName(u32)` returns `"u32"`, and `@typeName(MyStruct)` returns something like `"behavior.typename.MyStruct"`. Useful for debug output, serialization, and generic error messages.

### 7c. `@sizeOf` and `@typeOf`
**File:** `sizeof_and_typeof.zig` (26 tests)

`@sizeOf` returns the byte size of a type (accounting for alignment and padding). `@TypeOf` returns the compile-time type of an expression. Tests verify correct sizes for various types (including packed structs, arrays, optionals, and zero-sized types) and that `@TypeOf` correctly infers types from expressions.

### 7d. `@hasDecl` and `@hasField`
**Files:** `hasdecl.zig` (2 tests), `hasfield.zig` (1 test)

`@hasDecl(T, "name")` checks at compile time whether type `T` has a declaration (function, const, or var) named "name". `@hasField(T, "name")` checks whether a struct/union type has a field with that name. These enable conditional compilation in generic code: "if this type has a `.format` method, call it; otherwise fall back."

### 7e. `@fieldParentPtr`
**File:** `field_parent_ptr.zig` (16 tests)

Given a pointer to a struct field, `@fieldParentPtr` recovers the pointer to the containing struct. This is the Zig equivalent of Linux's `container_of` macro. It enables intrusive data structures (intrusive linked lists, trees) where a node is embedded inside a larger struct and you need to navigate from the node back to the container.

### 7f. Reflection (`@field`)
**File:** `reflection.zig` (2 tests)

`@field(obj, "name")` accesses a struct/union field by compile-time string name. Combined with `@typeInfo`, this enables fully generic serialization/deserialization: iterate over all fields of any struct, read/write each by name, without knowing the concrete type. Tests verify runtime field access via compile-time-known names.

### 7g. `@src` (Source Location)
**File:** `src.zig` (3 tests)

`@src()` returns a `std.builtin.SourceLocation` struct containing the file name, function name, line number, and column of the call site. Useful for logging, assertion messages, and debug tooling. The equivalent in C would be `__FILE__`, `__LINE__`, `__func__` combined into a single expression.

### 7h. `@returnAddress`
**File:** `return_address.zig` (1 test)

`@returnAddress()` returns the return address of the current function — the address the CPU will jump to when the function returns. This is used for stack unwinding, profiling, and implementing custom panic handlers. Equivalent to GCC's `__builtin_return_address(0)`.

---

## 8. Pointer and Memory Builtins

### 8a. `@ptrCast`
**File:** `ptrcast.zig` (29 tests)

`@ptrCast` converts between pointer types with different element types or constness. Unlike C casts, it preserves alignment information and the compiler can still reason about the result. Tests cover casting between `*T` and `*U`, `[*]T` and `*[N]T`, const/volatile conversions, and interactions with alignment.

### 8b. `@ptrFromInt` and `@intFromPtr`
**File:** `ptrfromint.zig` (4 tests)

`@ptrFromInt` creates a pointer from a raw integer address. `@intFromPtr` extracts the integer address from a pointer. These are essential for memory-mapped I/O, custom allocators, and interfacing with hardware. Tests verify round-trip correctness and interactions with alignment.

### 8c. `@bitCast`
**File:** `bitcast.zig` (24 tests)

`@bitCast` reinterprets the bits of a value as a different type without any conversion — the bit pattern is preserved exactly. For example, `@bitCast(f32, @as(u32, 0x3f800000))` gives `1.0f32`. This is the Zig equivalent of C's `memcpy`-based type punning (or C++20's `std.bit_cast`). Tests cover integer↔float, struct↔integer, array↔integer, and enum↔integer bitcasts.

### 8d. `@memcpy`
**File:** `memcpy.zig` (9 tests)

Built-in for copying memory between non-overlapping regions. Unlike C's `memcpy`, Zig's version works on slices and arrays with type safety. The compiler can optimize it to use SIMD instructions. Tests verify correctness for various types, sizes, and alignment combinations.

### 8e. `@memmove`
**File:** `memmove.zig` (4 tests)

Like `@memcpy` but handles overlapping source and destination regions correctly. The compiler picks the optimal direction (forward or backward copy) based on the overlap pattern. Tests verify correctness when source and destination overlap.

### 8f. `@memset`
**File:** `memset.zig` (11 tests)

Built-in for filling a memory region with a specified byte value. Works on slices with type safety. Tests cover filling with zero, filling with patterns, and interactions with alignment.

---

## 9. Bit Manipulation Builtins

### 9a. `@popCount`
**File:** `popcount.zig` (3 tests)

`@popCount` counts the number of set (1) bits in an integer. Maps to hardware `POPCNT` instruction on x86. Works on any integer width. Used in bitmap operations, Hamming distance calculations, and combinatorics. Tests cover various integer widths and edge cases.

### 9b. `@bitReverse`
**File:** `bitreverse.zig` (6 tests)

`@bitReverse` reverses the order of all bits in an integer. Bit 0 becomes the MSB, bit 1 becomes MSB-1, etc. Used in FFT algorithms, CRC calculations, and certain serialization protocols. Tests verify correct reversal for various integer widths (u8 through u128).

### 9c. `@byteSwap`
**File:** `byteswap.zig` (6 tests)

`@byteSwap` reverses the byte order of a multi-byte integer — converting between big-endian and little-endian representations. Maps to hardware `BSWAP` instruction on x86. Tests cover u16, u32, u64, and u128 swaps with various values.

### 9d. `@prefetch`
**File:** `prefetch.zig` (1 test)

`@prefetch` issues a CPU cache prefetch hint for a memory address, telling the processor to start loading data into cache before it's needed. Takes parameters for locality level (0–3) and read/write intent. Used in performance-critical loops that traverse large data structures. Maps to `_mm_prefetch` / `__builtin_prefetch`.

---

## 10. Arithmetic Builtins

### 10a. Saturating Arithmetic (`+|`, `-|`, `*|`)
**File:** `saturating_arithmetic.zig` (10 tests)

Saturating operators clamp the result to the type's min/max instead of wrapping or trapping on overflow. `127 +| 1` for `i8` gives `127`, not `-128` (wrapping) or a panic (checked). Essential for DSP, audio processing, and image manipulation where clamping is the desired behavior. Tests cover all combinations of signed/unsigned types and edge values.

### 10b. Wrapping Arithmetic (`+%`, `-%`, `*%`)
**File:** `wrapping_arithmetic.zig` (3 tests)

Wrapping operators perform two's complement wrapping without triggering overflow checks. `127 +% 1` for `i8` gives `-128`. This is the explicit way to opt into C-style overflow behavior when you intentionally want wrapping (e.g., hash functions, cryptographic operations). Tests verify correct wrapping for various types.

### 10c. `@mulAdd` (Fused Multiply-Add)
**File:** `muladd.zig` (9 tests)

`@mulAdd(T, a, b, c)` computes `a * b + c` in a single operation with only one rounding step, giving more precise results than separate multiply and add. Maps to hardware FMA instructions (e.g., `vfmadd`). Critical for numerical computation where accumulated rounding error matters. Tests cover f16, f32, f64, and f128 types.

### 10d. `@max` / `@min`
**File:** `maximum_minimum.zig` (19 tests)

Built-in functions that return the maximum or minimum of their arguments. Unlike a user-defined `max`, these handle special cases like NaN (following IEEE 754 semantics), work with comptime values, and can operate on vectors for SIMD min/max. Tests cover integer, float, comptime, optional, and vector operands.

### 10e. `@abs`
**File:** `abs.zig` (9 tests)

Built-in for computing the absolute value of integers and floats. For integers, the result type is the corresponding unsigned type (e.g., `@abs(i32)` returns `u32`). This avoids the classic C bug where `abs(INT_MIN)` is undefined behavior — Zig's version returns `@as(u32, 2147483648)`. Tests cover signed integers of various widths and floats.

---

## 11. Memory Layout and Alignment

### 11a. Alignment (`align`)
**File:** `align.zig` (30 tests)

Zig allows specifying custom alignment on variables, struct fields, function parameters, and pointer types (e.g., `var x: u32 align(16) = 0`). The type system tracks alignment through pointer types (`*align(16) u32` is different from `*u32`), enabling the compiler to verify alignment requirements at compile time. Tests cover over-aligned allocations, alignment of struct fields, casting between different alignments, and interaction with slices.

### 11b. `@alignOf`
**File:** `alignof.zig` (3 tests)

`@alignOf(T)` returns the natural alignment of type `T` in bytes. For primitive types this matches the size; for structs it's the maximum alignment of any field; for arrays it's the element alignment. Tests verify alignment values for primitive types, structs, and arrays.

### 11c. Address Spaces and Link Sections
**File:** `addrspace_and_linksection.zig` (9 tests)

Variables and functions can be placed in specific address spaces (for GPU/embedded targets where memory is segmented) or specific linker sections (e.g., `.rodata`, `.bss`, custom sections). Address spaces model hardware like GPU global/shared/local memory. Link sections control where symbols appear in the final binary, which matters for bootloaders, firmware, and custom linker scripts.

---

## 12. Extern / FFI Features

### 12a. Extern Structs
**File:** `extern.zig` (5 tests), `extern_struct_zero_size_fields.zig` (0 tests)

`extern struct` guarantees C-compatible memory layout: fields are laid out in declaration order with C's alignment and padding rules. This is different from Zig's default struct layout (which the compiler may reorder for efficiency). Essential for FFI with C libraries, system calls, and binary protocol parsing. Tests verify size and layout match C expectations.

### 12b. `@export` and Export Keywords
**Files:** `export_builtin.zig` (4 tests), `export_keyword.zig` (2 tests), `export_c_keywords.zig` (0 tests), `export_self_referential_type_info.zig` (0 tests)

`@export` makes a Zig symbol visible in the compiled object file under a specified name, enabling C code to call Zig functions. The `export` keyword on functions is syntactic sugar for the same. Tests verify that exported functions are callable, that C keyword names can be used as export names, and that self-referential type info can be exported.

### 12c. `@import` Mechanics
**Files:** `import.zig` (3 tests), `import_c_keywords.zig` (1 test)

Tests specific edge cases of Zig's `@import` system: importing files that use C keywords as identifiers, importing files that themselves import other files, and verifying that imported declarations are correctly scoped. Not about basic module imports (which With has), but about Zig-specific import semantics.

### 12d. Multiple Externs with Conflicting Types
**File:** `multiple_externs_with_conflicting_types.zig` (1 test)

Tests Zig's handling of the case where the same `extern` symbol is declared with different types in different compilation units — a common scenario when interfacing with C libraries that use opaque types.

---

## 13. Error Set Features

### 13a. Error Set Merging
**File:** `merge_error_sets.zig` (1 test)

Zig's error sets can be merged with `||` to create a union error set. If function A returns `error{Foo, Bar}` and function B returns `error{Bar, Baz}`, the merged set is `error{Foo, Bar, Baz}`. This enables composing error types from multiple subsystems without a centralized error enum. Tests verify that merged sets contain all variants and that matching works correctly.

### 13b. `@intFromError` / `@errorFromInt`
**File:** (tested within `error.zig`, 64 tests)

Zig errors are internally represented as integers. `@intFromError` extracts the integer value; `@errorFromInt` converts back. This enables serializing errors across FFI boundaries or into compact binary formats. With uses `Result[T, E]` with explicit error types instead of Zig's built-in error set mechanism.

---

## 14. Comptime Type Construction

### 14a. `@This()` (Self-Referential Types)
**File:** `this.zig` (4 tests)

`@This()` returns the type of the innermost struct/union/enum being defined. This enables self-referential types: a struct can have a field whose type is a pointer to itself, or methods that return `@This()`. Without this, recursive data structures (linked lists, trees) would require forward declarations. Tests verify `@This()` works in struct methods, nested types, and comptime contexts.

### 14b. Type Manipulation (`type` as First-Class Value)
**File:** `type.zig` (23 tests)

In Zig, `type` is a first-class comptime value. Functions can accept `type` as a parameter and return `type`. This enables generic programming: `fn ArrayList(comptime T: type) type` returns a new struct type specialized for `T`. Tests cover passing types as function arguments, storing types in comptime variables, comparing types for equality, and constructing complex generic types.

### 14c. Declaration Literals
**File:** `decl_literals.zig` (7 tests)

Declaration literals allow referring to a type's declarations (methods, constants) using a shorthand `.name` syntax when the type can be inferred. For example, if a function parameter is `enum { a, b }`, you can pass `.a` instead of `MyEnum.a`. Tests verify this works for enums, structs with declarations, and nested types.

---

## 15. NaN and Special Float Values

### 15a. NaN Handling
**File:** `nan.zig` (1 test)

Tests for IEEE 754 Not-a-Number semantics: signaling NaN vs. quiet NaN, NaN memory representation across float types (f16, f32, f64, f128), and NaN propagation through arithmetic. Verifies that NaN bit patterns are preserved through memory operations and that the `math.isNan` function correctly identifies both sNaN and qNaN.

---

## 16. Variadic Functions

### 16a. Var Args (`anytype`, `...`)
**File:** `var_args.zig` (11 tests)

Zig supports C-style variadic functions (for `extern "C"` interop) and also its own `anytype` parameter mechanism for compile-time duck typing. An `anytype` parameter accepts any type and the function body is monomorphized at each call site. Tests cover passing different types to the same `anytype` parameter, extracting variadic arguments, and mixing fixed and variadic parameters.

---

## 17. Miscellaneous Zig-Specific Features

### 17a. `undefined` (Uninitialized Memory)
**File:** `undefined.zig` (6 tests)

Zig's `undefined` value explicitly marks memory as uninitialized. In debug mode, it fills memory with `0xAA` bytes to help catch use-before-init bugs. In release mode, it's a no-op (no initialization cost). Any type can be `undefined`. Tests verify the debug-mode pattern fill and that `undefined` is a valid initializer for arrays, structs, and optionals.

### 17b. `_` (Discard) Semantics
**File:** `underscore.zig` (2 tests)

The `_` identifier discards a value, but Zig makes this observable: assigning to `_` still evaluates the expression (including side effects). Tests verify that discarding a function return value still calls the function and that `_` works in destructuring assignments.

### 17c. Function Delegation
**File:** `fn_delegation.zig` (1 test)

A function can delegate to another function, forwarding all its arguments. This is used for wrapper functions and trait implementations where one function simply calls through to another with no transformation.

### 17d. Incomplete Struct Parameters
**File:** `incomplete_struct_param_tld.zig` (1 test)

Tests the edge case where a function takes a parameter whose type is a struct that hasn't been fully defined yet (forward reference). Zig allows this because struct sizes are resolved lazily.

### 17e. By-Value Argument Variables
**File:** `byval_arg_var.zig` (1 test)

Tests that function arguments passed by value can be used as local variables — you can take their address and modify them without affecting the caller.

### 17f. Const Slice Child Type
**File:** `const_slice_child.zig` (1 test)

Tests that a `[]const T` slice correctly propagates the `const` to the child type when accessed via pointer operations.

### 17g. Inline Switch
**File:** `inline_switch.zig` (10 tests)

`inline` switch generates a separate code path for each prong at compile time, avoiding the runtime dispatch. This is Zig's alternative to template specialization — the compiler generates optimal code for each case. Tests verify that inline switch correctly unrolls and that each prong can use the matched value as a comptime-known constant.

### 17h. Switch Loop (Switch in a Loop)
**File:** `switch_loop.zig` (15 tests)

Tests the pattern of using a switch inside a loop where each iteration dispatches to a different handler. This is common in state machines and interpreters. Tests verify that labeled continue/break interact correctly with switch prongs inside loops.

### 17i. IR Block Dependencies
**File:** `ir_block_deps.zig` (1 test)

Tests an internal compiler edge case where IR basic blocks have specific dependency ordering requirements. Ensures the compiler's IR generation handles block ordering correctly in complex control flow.

### 17j. Namespace Depends on Compile Var
**File:** `namespace_depends_on_compile_var.zig` (1 test)

Tests that a namespace's contents can depend on a compile-time variable (e.g., conditionally including declarations based on the target platform).

### 17k. Various Switch Edge Cases
**Files:** `switch_on_captured_error.zig` (2 tests), `switch_prong_err_enum.zig` (1 test), `switch_prong_implicit_cast.zig` (1 test), `ref_var_in_if_after_if_2nd_switch_prong.zig` (1 test)

Edge cases in switch/if interaction: switching on a captured error value, implicit type coercion in switch prongs, and variable references across nested if/switch structures. These test compiler correctness in complex control flow lowering.

### 17l. Self-Referential Structs
**Files:** `struct_contains_null_ptr_itself.zig` (1 test), `struct_contains_slice_of_itself.zig` (2 tests)

Tests that structs can contain pointers or slices to their own type — the fundamental requirement for linked lists, trees, and other recursive data structures. Verifies that the compiler correctly handles the forward reference in the type definition.

### 17m. Pub Enum (Visibility)
**File:** `pub_enum.zig` (2 tests)

Tests that `pub` visibility on enum declarations works correctly across file boundaries — a `pub const` enum defined in one file is accessible from another via `@import`.

### 17n. Decltest
**File:** `decltest.zig` (0 tests by count; uses special `decltest` syntax)

Zig's `decltest` is a test block that references a specific declaration, creating a documentation-test link. If the declaration is removed, the test fails to compile. This ensures documentation examples stay in sync with the API.

### 17o. Duplicated Test Names
**File:** `duplicated_test_names.zig` (1 test)

Tests that Zig correctly handles the case where two test blocks have the same name — they should both run without conflict.

### 17p. Sentinel-Terminated Slices at Comptime
**File:** `slice_sentinel_comptime.zig` (4 tests)

Zig slices can have a sentinel terminator value (like C's null-terminated strings, but generalized to any value and type). `[:0]u8` is a null-terminated byte slice. Tests verify that sentinel slices work correctly in comptime evaluation.

### 17q. Tuple Declarations
**File:** `tuple_declarations.zig` (2 tests)

Tuples in Zig are anonymous structs with numeric field names (`.@"0"`, `.@"1"`). This file tests edge cases in tuple type declarations, including nested tuples and tuples with mixed types.

### 17r. ZON (Zig Object Notation)
**File:** `zon.zig` (21 tests)

ZON is Zig's data serialization format (analogous to JSON but using Zig syntax). It supports all Zig literal types: integers, floats, booleans, strings, arrays, structs, enums, optionals, and null. Tests cover parsing and materializing various ZON values at compile time and runtime.

### 17s. Builtin Functions Returning Void or Noreturn
**File:** `builtin_functions_returning_void_or_noreturn.zig` (0 tests)

Tests that builtin functions with return type `void` or `noreturn` can be used in expression position correctly (e.g., assigned to a void variable or used in unreachable code paths).

### 17t. Integer Comparison Elision
**File:** `int_comparison_elision.zig` (2 tests)

The compiler can elide comparisons when the result is statically known — for example, `x < 256` when `x` is `u8` is always true. Tests verify the compiler correctly identifies and optimizes these tautological or contradictory comparisons without changing observable behavior.

### 17u. WASM-Specific Behavior
**File:** `wasm.zig` (1 test)

Target-specific tests for WebAssembly, covering WASM-specific memory model behavior, import/export mechanics, and instruction semantics that differ from native targets.

---

## Summary Table

| Category | Zig Files | Total Tests | Key Feature |
|----------|-----------|-------------|-------------|
| SIMD/Vectors | 4 | 64 | `@Vector`, `@shuffle`, `@select` |
| Atomics/Threading | 2 | 16 | `@atomicRmw`, `threadlocal` |
| Inline Assembly | 2 | 7 | `asm` expression |
| Packed Structs/Unions | 4 | 55 | Bit-level layout, non-byte fields |
| Non-Byte-Sized Integers | 4 | 23 | `u3`, `i7`, `u128`, etc. |
| Comptime Execution | 3 | 142 | Full compile-time evaluation |
| Type Introspection | 8 | 93 | `@typeInfo`, `@typeName`, `@field` |
| Pointer/Memory Builtins | 6 | 81 | `@ptrCast`, `@bitCast`, `@memcpy` |
| Bit Manipulation | 4 | 16 | `@popCount`, `@bitReverse`, `@byteSwap` |
| Arithmetic Builtins | 5 | 50 | Saturating/wrapping ops, `@mulAdd` |
| Alignment | 3 | 42 | `align`, `@alignOf`, address spaces |
| Extern/FFI | 6 | 11 | `extern struct`, `@export`, `@import` edge cases |
| Error Sets | 1 | 1 | Error set merging (`\|\|`) |
| Comptime Types | 3 | 34 | `@This()`, `type` as value |
| NaN/Special Floats | 1 | 1 | IEEE 754 NaN handling |
| Variadic Functions | 1 | 11 | `anytype`, C varargs |
| Misc Edge Cases | 19 | ~70 | Various compiler edge cases |
| **Total** | **~76** | **~1,216** | |

The remaining ~40 Zig files (827 tests) test features that With *does* have equivalents for: basic types, control flow, structs, enums, arrays, slices, optionals, functions, generics, error handling, pointers, and math operations.
