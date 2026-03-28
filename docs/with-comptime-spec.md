# `comptime` — Compile-Time Execution

*Specification & Implementation Notes*

---

## 1. Overview

With does not have macros. It has `comptime` — compile-time execution of
regular With code with access to type information. This replaces derive
macros, reflection-based codegen, and most uses of procedural macros from
other languages. The key property: generated code is regular With code
that goes through the full type checker and borrow checker. Nothing is
hidden from the safety machinery.

---

## 2. Entry Points

There are six ways to enter comptime context:

| Entry point | Scope | Use case |
|-------------|-------|----------|
| `comptime fn` | Single function | Reusable compile-time logic |
| `comptime:` block | Group of declarations | Libraries of comptime functions |
| `comptime for` | Loop body | Compile-time unrolling |
| `comptime if` | Branch selection | Conditional compilation |
| `const X = comptime expr` | Single expression | Embed a computed constant |
| `@[derive(Trait)]` | Type annotation | Sugar for comptime codegen |

### 2.1 The Cascade Rule

Inside any comptime context, **everything is comptime**. No inner prefixes
needed. `comptime` is only required at the entry point — the outermost
`comptime fn`, `comptime:` block, `comptime for`, or `comptime if`.

```
comptime fn generate_storage[T: type]:
    // All of this is comptime — no prefixes:
    for field in T.fields():
        if field.type_name.starts_with("Vec["):
            emit_vec_storage(field)
        else:
            emit_scalar_storage(field)
```

The cascade is lexical: everything textually inside the comptime entry
point is compile-time. There is no "escaping" back to runtime within a
comptime scope.

---

## 3. `comptime fn`

A function whose body executes at compile time.

```
comptime fn build_table(keys: [str]) -> HashMap[str, usize]:
    var table = HashMap.new()
    var i = 0
    for key in keys:
        table.insert(key, i)
        i += 1
    table

const ROUTES = comptime build_table(["/", "/health", "/users"])
```

**Restrictions:**

- Can only call other `comptime` functions (or functions in a `comptime:` block)
- Cannot perform I/O (no file reads, no network, no printing)
- Cannot allocate heap memory that persists to runtime
- Cannot call FFI / extern functions
- Cannot access mutable global state
- The return value must be a type that can be embedded in the binary
  as a constant (scalars, strings, fixed-size arrays, structs of embeddable types)

**Dual use:** A `comptime fn` can also be called at runtime with runtime
arguments. In that case it behaves as a normal inlined function — the
`comptime` annotation just means it's *eligible* for compile-time evaluation,
not that it *must* be. The `const X = comptime expr` form forces evaluation.

```
comptime fn div_floor(a: i32, b: i32) -> i32:
    let q = a / b
    let r = a % b
    if r != 0 and (r ^ b) < 0: q - 1 else: q

// Compile-time: result embedded as constant -4
const Q = comptime div_floor(-7, 2)

// Runtime: normal function call, inlined
let q = div_floor(x, bucket_size)
```

---

## 4. `comptime:` Block

Marks a group of declarations as comptime. Every `fn`, `type`, `const`,
and nested declaration within the block is compile-time.

```
comptime:
    fn div_floor(a: i32, b: i32) -> i32:
        let q = a / b
        let r = a % b
        if r != 0 and (r ^ b) < 0: q - 1 else: q

    fn mod_floor(a: i32, b: i32) -> i32:
        let r = a % b
        if r != 0 and (r ^ b) < 0: r + b else: r

    fn div_eucl(a: i32, b: i32) -> i32:
        let q = a / b
        let r = a % b
        if r < 0:
            if b > 0: q - 1 else: q + 1
        else:
            q

    fn mod_eucl(a: i32, b: i32) -> i32:
        let r = a % b
        if r < 0:
            if b > 0: r + b else: r - b
        else:
            r
```

This is equivalent to writing `comptime fn` on each function individually.
The block form exists to avoid repetition in files where every function
is comptime — math libraries, lookup table builders, codecs, hash functions.

**Scoping:** The `comptime:` block uses With's standard indentation scoping.
Everything indented under `comptime:` is in scope. Declarations after the
block (at the original indentation level) are normal runtime declarations.

```
comptime:
    fn hash(s: str) -> u64:
        ...

    fn build_table(keys: [str]) -> HashMap[str, u64]:
        ...

// This is a normal runtime function — not comptime
fn lookup(key: str) -> u64:
    TABLE.get(key).unwrap_or(0)
```

**Nesting:** A `comptime:` block inside a `comptime:` block is redundant
but legal (the inner block is already comptime by cascade).

---

## 5. `comptime for`

Unrolls a loop at compile time. The loop body is stamped out once per
iteration with compile-time constants substituted.

```
comptime fn register_components[Ts: [type]]():
    for T in Ts:                       // cascade: already comptime
        world.register_storage[T](
            T.name(),
            T.size(),
        )

// At the call site, this unrolls to:
//   world.register_storage[Position]("Position", 12)
//   world.register_storage[Velocity]("Velocity", 12)
//   world.register_storage[Health]("Health", 4)
register_components[Position, Velocity, Health]()
```

When used outside a comptime function, `comptime for` is the entry point:

```
fn init_systems():
    comptime for T in [Position, Velocity, Health, Transform]:
        world.register[T]()
```

The loop variable is a compile-time constant in each unrolled copy.
The loop body can contain runtime code — only the loop iteration is
compile-time.

---

## 6. `comptime if`

Selects code paths at compile time. Dead branches are not compiled —
they are discarded entirely, not just unreachable.

```
fn serialize_value[T](val: &T, out: &mut Writer):
    comptime if T.is_copy():
        // Fast path for small Copy types
        out.write_bytes(val as *const u8, T.size())
    else if T.implements(Serialize):         // cascade: already comptime
        val.serialize(out)
    else:
        comptime_error(f"Type {T.name()} is not serializable")
```

**Dead branch elimination:** The discarded branches are not type-checked.
This is intentional — it allows code that would be ill-typed for certain
type parameters to coexist with code that handles those parameters:

```
fn process[T](val: T):
    comptime if T.implements(Display):
        print(f"{val}")         // only valid if T: Display
    else:
        print("<opaque>")       // fallback — no Display needed
```

Without `comptime if`, the `f"{val}"` branch would fail type-checking
when `T` doesn't implement `Display`, even though it's unreachable.

---

## 7. `comptime_error`

Produces a compile error with a custom message. Fires only when the
containing code is actually compiled (instantiated for specific type
arguments, or called).

```
comptime_error(msg: str) -> Never
```

**Semantics:** `comptime_error` is an expression of type `Never`. A
function whose body is only `comptime_error(...)` is legal to declare
and reference — the error fires on call, not on declaration.

```
fn legacy_api():
    comptime_error("legacy_api removed; use new_api instead")

// No error — the function exists, never called.
// Calling legacy_api() anywhere → compile error with the message.
```

**Use cases:**

Deprecation:
```
fn old_name():
    comptime_error("old_name renamed to new_name in v2.0")
```

Concept checking (constraints beyond trait bounds):
```
fn only_small_types[T](val: T):
    comptime if T.size() > 64:
        comptime_error(f"{T.name()} is too large ({T.size()} bytes)")
```

Untranslatable C constructs from `c_import`:
```
fn __builtin_complex():
    comptime_error("c_import: __builtin_complex not translatable")
```

---

## 8. Type Introspection

Inside comptime context, type parameters are objects with methods.

### 8.1 Type Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `T.fields()` | `[FieldInfo]` | Struct fields: name, type, offset, size |
| `T.variants()` | `[VariantInfo]` | Enum variants: name, payload type |
| `T.size()` | `usize` | Size in bytes |
| `T.align()` | `usize` | Alignment in bytes |
| `T.name()` | `str` | Type name as string |
| `T.implements(Trait)` | `bool` | Whether T implements Trait |
| `T.is_copy()` | `bool` | Whether T is Copy |

### 8.2 FieldInfo

```
type FieldInfo {
    name: str,
    type_name: str,
    offset: usize,
    size: usize,
    is_ephemeral: bool,
}
```

### 8.3 VariantInfo

```
type VariantInfo {
    name: str,
    discriminant: i64,
    has_payload: bool,
    payload_type_name: str,
}
```

### 8.4 Field Access by Name

Inside comptime context, struct fields can be accessed by a compile-time
string via `self.{field_name}`:

```
comptime fn derive_debug[T: type] -> impl Debug for T:
    impl Debug for T:
        fn debug(&self, out: &mut Formatter):
            out.write(T.name())
            out.write(" { ")
            for field in T.fields():
                out.write(f"{field.name}: ")
                self.{field.name}.debug(out)    // dynamic field access
                out.write(", ")
            out.write("}")
```

`self.{field.name}` resolves to the actual field access at compile time.
Each iteration of the comptime for loop produces a different field access
in the unrolled output. This is type-safe — the compiler checks that the
field exists and that the operation on it (`.debug(out)`) is valid.

### 8.5 TypeInfo Module

For non-generic contexts where `T` is not a type parameter:

```
let size = TypeInfo.size[MyStruct]()
let fields = TypeInfo.fields[MyStruct]()
```

Inside comptime generic functions, `T.fields()` is preferred — it reads
like natural reflection.

---

## 9. `@[derive(Trait)]`

Sugar for invoking a comptime function that generates a trait implementation.

```
@[derive(Serialize, Debug)]
type User { name: str, age: i32, email: str }
```

This calls `derive_serialize[User]()` and `derive_debug[User]()` at
compile time. The convention: `@[derive(X)]` looks for a comptime function
named `derive_x` (lowercase, `derive_` prefix) that takes a type parameter
and returns an `impl` block.

```
comptime fn derive_serialize[T: type] -> impl Serialize for T:
    let fields = T.fields()
    impl Serialize for T:
        fn serialize(self: &T, out: &mut JsonWriter):
            out.begin_object()
            for field in fields:
                out.key(field.name)
                self.{field.name}.serialize(out)
            out.end_object()
```

The generated code is regular With code. It goes through type checking
and borrow checking. If `self.{field.name}.serialize(out)` fails because
a field type doesn't implement `Serialize`, the error points at the
user's type definition with a clear message, not at generated code.

---

## 10. Magic Constants

Two built-in constants evaluated at the point of use:

| Constant | Type | Value |
|----------|------|-------|
| `__FILE__` | `str` | Source file path |
| `__LINE__` | `u32` | Line number |

Useful as default parameters for logging and assertions:

```
fn log(msg: str, file: str = __FILE__, line: u32 = __LINE__):
    print(f"[{file}:{line}] {msg}")
```

---

## 11. Compiler Intrinsics

### 11.1 `src()`

Returns the call site's source location as `"file:line:col"`:

```
fn log(msg: str):
    print(src() ++ ": " ++ msg)

log("hello")    // src/main.w:4:5: hello
```

### 11.2 `embed_file(path)`

Reads a file at compile time and embeds its contents as a string constant:

```
const HELP_TEXT: str = embed_file("help.txt")
const SHADER: str = embed_file("shaders/basic.glsl")
```

The path is relative to the source file. The file is read once during
compilation and its contents are baked into the binary.

---

## 12. Restrictions

Comptime code is a strict subset of With. The following are forbidden
inside any comptime context:

| Forbidden | Reason |
|-----------|--------|
| `extern fn` calls | FFI is a runtime concept |
| File/network I/O | Side effects are not reproducible |
| Heap allocation that escapes | The result must be embeddable |
| Mutable global access | Non-deterministic across compilations |
| Raw pointer arithmetic | Cannot be verified at compile time |
| `unsafe` blocks | Comptime is safe by definition |
| `async` / `.await` | No runtime to schedule on |

**What IS allowed:**

- All pure arithmetic (integer, float, bitwise)
- String operations (concatenation, slicing, formatting)
- Control flow (if, for, while, match, recursion)
- Struct/enum construction and field access
- HashMap and Vec operations (internally, the comptime evaluator
  manages its own heap that is discarded after evaluation)
- Calling other comptime functions
- Type introspection methods
- `comptime_error`

---

## 13. Examples

### 13.1 Compile-Time Lookup Table

```
comptime:
    fn build_crc32_table() -> [u32; 256]:
        var table: [u32; 256] = [0u32; 256]
        for i in 0..256:
            var crc = i as u32
            for _ in 0..8:
                if crc & 1 != 0:
                    crc = (crc >> 1) ^ 0xEDB88320
                else:
                    crc = crc >> 1
            table[i] = crc
        table

const CRC32_TABLE = comptime build_crc32_table()
```

### 13.2 Compile-Time String Hashing

```
comptime fn hash_str(s: str) -> u64:
    var h: u64 = 5381
    for c in s.bytes():
        h = h * 33 + c as u64
    h

const SHADER_PARAM_ID = comptime hash_str("world_matrix")
```

### 13.3 ECS Component Registration

```
comptime fn register_components[Ts: [type]]():
    for T in Ts:
        world.register_storage[T](T.name(), T.size())

register_components[Position, Velocity, Health, Transform]()
```

### 13.4 Struct-of-Arrays Transform

```
comptime fn make_soa[T: type](capacity: usize) -> SoaStorage[T]:
    let fields = T.fields()
    // Generates a struct with one Vec per field:
    // { positions: Vec[Vec3], rotations: Vec[Quat], scales: Vec[f32] }
    // Plus accessors that reconstruct T from the parallel arrays
```

### 13.5 Platform-Specific Code Selection

```
fn allocate_page() -> *mut u8:
    comptime if TARGET_OS == "linux":
        mmap(...)
    else if TARGET_OS == "macos":
        vm_allocate(...)
    else if TARGET_OS == "windows":
        VirtualAlloc(...)
    else:
        comptime_error(f"unsupported OS: {TARGET_OS}")
```

### 13.6 A Comptime Math Library

```
// std/math/divide.w — Three signed integer division modes.
// All functions are comptime — evaluated at compile time with
// constant arguments, inlined at runtime otherwise.

comptime:
    fn div_floor(a: i32, b: i32) -> i32:
        let q = a / b
        let r = a % b
        if r != 0 and (r ^ b) < 0: q - 1 else: q

    fn mod_floor(a: i32, b: i32) -> i32:
        let r = a % b
        if r != 0 and (r ^ b) < 0: r + b else: r

    fn div_eucl(a: i32, b: i32) -> i32:
        let q = a / b
        let r = a % b
        if r < 0:
            if b > 0: q - 1 else: q + 1
        else:
            q

    fn mod_eucl(a: i32, b: i32) -> i32:
        let r = a % b
        if r < 0:
            if b > 0: r + b else: r - b
        else:
            r

// Usage:
const BUCKET_Q = comptime div_floor(-7, 2)   // -4 at compile time
let runtime_q = div_floor(x, bucket_size)     // inlined at runtime
```

---

## 14. Implementation Notes

### 14.1 Architecture

Comptime evaluation requires an interpreter that runs With code during
compilation. The interpreter operates on the AST or MIR after type
checking, executing the comptime-marked functions and replacing `const`
declarations with the computed values.

```
Source → Lexer → Parser → Sema → Comptime Evaluator → MIR → Codegen
                                       ↑
                              Runs comptime functions,
                              produces constant values,
                              unrolls comptime for,
                              eliminates comptime if branches
```

### 14.2 Evaluator Design

The comptime evaluator is a tree-walking interpreter over typed AST
nodes (post-sema). It maintains its own:

- **Value stack:** Local variables, function arguments
- **Heap:** Temporary allocations for HashMap, Vec, strings during
  evaluation. Discarded after the comptime function returns.
- **Type environment:** Access to sema's type tables for introspection

**Key operations:**

| AST node | Evaluator action |
|----------|-----------------|
| Integer literal | Push constant value |
| Binary op | Pop two values, compute, push result |
| `let` binding | Store value in local slot |
| `var` binding | Store mutable value in local slot |
| `if` / `match` | Evaluate condition, take branch |
| `for` loop | Iterate, evaluate body per iteration |
| Function call | Push frame, evaluate body, pop frame |
| `T.fields()` | Query sema type tables, return FieldInfo array |
| `T.size()` | Query sema type tables, return constant |
| `self.{name}` | Resolve to concrete field access in unrolled output |
| `comptime_error(msg)` | Emit compile error with message, halt |

### 14.3 Value Representation

Comptime values need a uniform representation that can hold any With
type:

```
enum ComptimeValue:
    Int(i64)
    Float(f64)
    Bool(bool)
    Str(str)
    Array(Vec[ComptimeValue])
    Struct(HashMap[str, ComptimeValue])
    Enum(str, Option[ComptimeValue])     // variant name + optional payload
    Void
```

This is a boxed tagged-union representation. Performance doesn't matter —
comptime evaluation runs once during compilation, not at runtime.

### 14.4 Embedding Results

After a comptime function returns a `ComptimeValue`, the compiler must
embed it in the binary as a constant. The embedding depends on the type:

| Type | Embedding |
|------|-----------|
| `i32`, `i64`, etc. | Literal constant in LLVM IR |
| `f32`, `f64` | Float constant in LLVM IR |
| `bool` | `i1` constant |
| `str` | String constant in `.rodata` section |
| `[T; N]` | Array constant in `.rodata` |
| Struct | Aggregate constant in LLVM IR |
| `HashMap`, `Vec` | Serialized to a fixed-size representation (frozen) |

**HashMap/Vec embedding:** These are heap-allocated at runtime, so the
comptime evaluator must "freeze" them into a format that can be
reconstructed at program startup. Options:

1. **Static initialization:** Emit a `fn __init_ROUTES()` that builds
   the HashMap at program startup from a constant array of key-value pairs.
   Simple, correct, small cost at startup.

2. **Frozen representation:** Emit the HashMap's internal storage as a
   constant byte array with pre-computed hashes. Zero startup cost but
   requires the runtime HashMap layout to be stable. Fragile.

Option 1 is recommended for v1. The startup cost of rebuilding a small
HashMap from constant data is negligible.

### 14.5 `comptime:` Block Parsing

The parser handles `comptime:` as a block-level modifier. When it sees
`comptime` followed by `:` and a newline, it enters a comptime block
scope. Every declaration parsed at the block's indentation level gets
the comptime flag set.

```
// Parser pseudocode:
if peek() == TK_KW_COMPTIME and peek_ahead(1) == TK_COLON:
    advance()  // consume 'comptime'
    advance()  // consume ':'
    let block_indent = current_indent()
    while current_indent() > block_indent:
        let decl = parse_declaration()
        decl.set_comptime(true)
        declarations.push(decl)
```

This reuses the existing indentation-scoping machinery. No new AST
node needed — each declaration inside the block is individually marked
as comptime, identical to writing `comptime fn` on each one.

### 14.6 `comptime for` Unrolling

`comptime for` is handled during the comptime evaluation phase, after
sema but before MIR lowering:

1. Evaluate the iterable (must be a compile-time constant list)
2. For each element, substitute the loop variable with the constant
3. Emit one copy of the loop body per iteration
4. Each copy goes through sema independently (for type-specialized code)

For `comptime for T in [Position, Velocity, Health]`:
- Iteration 1: T = Position → emit body with T = Position
- Iteration 2: T = Velocity → emit body with T = Velocity
- Iteration 3: T = Health → emit body with T = Health

The result is three copies of the body in the AST, each type-checked
with different type parameters. This is monomorphization at the AST level.

### 14.7 `comptime if` Elimination

`comptime if` is evaluated during the comptime phase:

1. Evaluate the condition (must produce a compile-time bool)
2. Keep only the taken branch in the AST
3. Discard all other branches entirely — they are not type-checked

This is critical for correctness: discarded branches may contain code
that would be ill-typed for the current type parameters. For example,
`f"{val}"` in a branch guarded by `comptime if T.implements(Display)`
must not be type-checked when `T` doesn't implement `Display`.

### 14.8 `@[derive]` Resolution

When the parser encounters `@[derive(TraitName)]` on a type declaration:

1. Convert `TraitName` to `derive_trait_name` (lowercase, add prefix)
2. Look up the comptime function with that name
3. Invoke it with the annotated type as the type parameter
4. The function returns an `impl` block, which is added to the AST

This is syntactic sugar — `@[derive(Serialize)]` on `type User` is
exactly `comptime derive_serialize[User]()`.

### 14.9 Error Reporting

Comptime errors should point at the user's code, not the comptime
function's internals:

```
@[derive(Serialize)]
type Config { callback: fn(i32) -> i32 }
                       ^^^^^^^^^^^^^^^^^
error: field 'callback' of type 'fn(i32) -> i32' does not implement Serialize
  = note: required by @[derive(Serialize)] on Config
  = note: in comptime function derive_serialize[Config]
```

The primary error span is the field declaration. The notes provide the
chain back to the comptime function. Users should never need to read
the comptime function source to understand why their type failed to derive.

### 14.10 Implementation Phases

| Phase | What | Depends on |
|-------|------|-----------|
| 1 | `comptime fn` with scalar returns | Sema (type info) |
| 2 | `const X = comptime expr` embedding | Phase 1 |
| 3 | `comptime if` / `comptime for` | Phase 1 |
| 4 | `comptime:` block syntax | Parser change only |
| 5 | Type introspection (`T.fields()`, etc.) | Phase 1 + sema type tables |
| 6 | `@[derive]` sugar | Phase 5 |
| 7 | `embed_file` / `src()` intrinsics | Independent |
| 8 | HashMap/Vec in comptime results | Phase 1 + embedding strategy |

**Phase 1 is the foundation.** A tree-walking interpreter that handles
arithmetic, control flow, function calls, and returns scalar constants.
Everything else builds on top.

**Estimated scope:**

| Component | Lines (est.) |
|-----------|-------------|
| Comptime evaluator (tree walker) | ~800 |
| Value representation | ~150 |
| Constant embedding (scalars) | ~100 |
| Constant embedding (aggregates) | ~200 |
| `comptime:` block parser change | ~20 |
| `comptime for` unrolling | ~150 |
| `comptime if` elimination | ~80 |
| Type introspection methods | ~300 |
| `@[derive]` resolution | ~100 |
| `embed_file` / `src()` | ~50 |
| **Total** | **~1,950** |

---

*Comptime specification — v1.0*