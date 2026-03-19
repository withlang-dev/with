# With Language Features for Crux & Weld

**Purpose:** Every language feature that Crux needs, wants, or would
benefit from. Organized by priority. Each feature has spec language
and implementation notes. This is the complete punch list.

**Principle:** Crux and Weld are With's flagships. If Crux/Weld needs it, With gets it.

---

## Tier 0: Blocking Crux session 1
*Cannot start Crux without these.*

### 0a. Fixed-size arrays `[T; N]`

Crux's Shape and Strides need `[usize; 8]` and `[isize; 8]`.
The struct-with-8-fields workaround is ugly, error-prone, and
prevents loop-based access. This is the #1 missing feature.

**Spec:**

```
fixed_array_type = "[" type ";" int_expr "]"
```

A fixed-size array is a value type with compile-time-known length.
Stack-allocated. Copyable. Indexable.

```
let a: [i32; 4] = [1, 2, 3, 4]
let x = a[0]                    // 1
let y = a[3]                    // 4

var b: [f32; 8] = [0.0; 8]     // fill with 0.0
b[2] = 3.14

fn sum(arr: [i32; 4]) -> i32:
    var total = 0
    for i in 0..4:
        total = total + arr[i]
    total
```

**Semantics:**
- Length N must be a compile-time constant (integer literal or const).
- `[T; N]` has size `N * sizeof(T)` and alignment `alignof(T)`.
- Passed by value (copied). For large arrays, pass by reference.
- Bounds checking in debug mode, unchecked in release.
- `[value; N]` syntax creates an array filled with `value`.
- `[v0, v1, ..., vN]` syntax creates an array from elements.
- `.len()` returns N as `usize` (compile-time constant).

**Implementation:**

**Lexer/Parser:**
- Parse `[T; N]` in type position as `NK_ARRAY_TYPE` with
  data0=element_type_node, data1=size_expr_node.
- Parse `[v0, v1, ...]` as `NK_ARRAY_LIT` (already exists for
  dynamic arrays — extend or add `NK_FIXED_ARRAY_LIT`).
- Parse `[value; N]` as `NK_ARRAY_REPEAT` (new node kind).
- Parse `arr[i]` reuses existing `NK_INDEX` (already works).

**Sema:**
- Add `TY_FIXED_ARRAY` type kind with d0=element_type_id,
  d1=length (i32).
- Type checking: index expression must be integer.
  Array length must be compile-time evaluable.
- `[T; N]` in struct fields: layout is inline (no pointer
  indirection), size = N * elem_size.

**Codegen:**
- Map `[T; N]` to `LLVMArrayType(elem_type, N)`.
- Array literal: `LLVMConstArray` for constants, sequential
  `LLVMBuildInsertValue` for runtime values.
- Index: `LLVMBuildExtractValue` for constant index,
  GEP + load for runtime index.
- Pass by value: LLVM handles small arrays in registers,
  large arrays via stack copy (sret).

**MirLower:**
- `NK_FIXED_ARRAY_LIT` → `RK_AGGREGATE` with element operands.
- `NK_ARRAY_REPEAT` → loop of `SK_ASSIGN` to each index.
- Index on fixed array → `PK_INDEX` projection (reuse existing).

**Estimated work:** 2-3 sessions.

---

### 0b. Bitwise operators on all integer types

Crux's IR uses bitwise ops (and, or, xor, shift) extensively.
The c_import expression evaluator had to implement shifts via
multiplication loops because `<<` and `>>` on i64 broke the
seed compiler. These must work natively.

**Spec:**

```
a & b       // bitwise AND
a | b       // bitwise OR
a ^ b       // bitwise XOR
~a          // bitwise NOT
a << n      // left shift
a >> n      // right shift (arithmetic for signed, logical for unsigned)
```

All operators work on i8, i16, i32, i64, u8, u16, u32, u64,
i128, u128. Mixed-width operands are promoted to the wider type.

**Implementation:**

These operators already parse and work for i32. The issue is that
codegen emits incorrect LLVM IR for 64-bit and 128-bit operands.

Debug: Find where `OP_BIT_AND`, `OP_BIT_OR`, `OP_BIT_XOR`,
`OP_SHL`, `OP_SHR` are lowered in Codegen.w. Verify that the
LLVM instruction uses the correct integer width (not always i32).

Fix: In `mir_emit_binop` (or equivalent), ensure the operands
are widened/narrowed to match before emitting `LLVMBuildAnd`,
`LLVMBuildOr`, `LLVMBuildXor`, `LLVMBuildShl`, `LLVMBuildAShr`
(signed) / `LLVMBuildLShr` (unsigned).

**Estimated work:** 1 session (mostly debugging existing codegen).

---

## Tier 1: Needed for Crux sessions 1-8
*Core substrate implementation depends on these.*

### 1a. `comptime if` — conditional compilation

Crux needs platform-specific code paths (Metal vs CUDA vs CPU)
without runtime overhead.

**Spec:**

```
comptime_if = "comptime" "if" comptime_expr ":" block
              ("comptime" "else" "if" comptime_expr ":" block)*
              ("comptime" "else" ":" block)?
```

```
comptime if cfg.target_os == "darwin":
    use c_import("Metal/Metal.h", framework: "Metal")
    fn create_metal_device() -> i64:
        crux_metal_create_device()
comptime else:
    fn create_metal_device() -> i64:
        0  // not available
```

**Semantics:**
- Condition must be compile-time evaluable.
- Only the taken branch is type-checked and compiled.
- Eliminated branches are erased — they may contain
  platform-specific types and functions that don't exist
  on the current target.
- Available at module level and inside function bodies.

**Built-in cfg values:**
```
cfg.target_os      // "darwin", "linux", "windows"
cfg.target_arch    // "aarch64", "x86_64"
cfg.is_debug       // true in debug builds
cfg.is_release     // true in release builds
cfg.has_metal      // true if Metal framework available
cfg.has_cuda       // true if CUDA toolkit found
```

**Implementation:**

**Sema (early pass):**
Before type checking, evaluate comptime if conditions. Replace
the comptime if node with the taken branch's contents. Delete
eliminated branches from the AST.

This runs after name resolution but before type checking — so
eliminated branches with undefined types don't cause errors.

**cfg values:** Populated from the target triple and build
configuration in Compilation.w. Stored in
`Sema.cfg_values: HashMap[str, str]`.

**Estimated work:** 2-3 sessions.

### 1b. String interpolation

Crux generates MSL source code via string concatenation. Without
interpolation, every kernel emitter is a wall of `++` operators.

**Spec:**

```
let name = "world"
let s = "hello {name}"           // "hello world"
let n = 42
let s2 = "value = {n}"          // "value = 42"
let s3 = "sum = {a + b}"        // "sum = 7"
let s4 = "literal brace: {{"    // "literal brace: {"
```

**Semantics:**
- `{expr}` inside a string is evaluated and converted to str.
- Conversion uses a `to_string()` method or built-in formatting.
- `{{` produces literal `{`, `}}` produces literal `}`.
- Interpolated strings produce owned `str`.

**Implementation:**

**Parser:** When scanning a string literal and encountering `{`:
1. Split the string into segments.
2. Desugar to concatenation: `"hello " ++ to_string(name)`
3. Each `{expr}` becomes `++ to_string(expr) ++`

No lexer changes needed — handle entirely in the parser by
post-processing string literal tokens.

**Built-in to_string:** Add `to_string` as a built-in for
primitive types (i32, i64, f32, f64, bool, str). For user
types, require a `Display` trait impl (future).

For Crux session 6, string interpolation makes the MSL emitter
go from:

```
msl = msl ++ "device const float* param_" ++ int_to_string(i) ++ " [[buffer(" ++ int_to_string(i) ++ ")]]"
```

to:

```
msl = msl ++ "device const float* param_{i} [[buffer({i})]]"
```

**Estimated work:** 1-2 sessions.

### 1c. `defer` — deterministic resource cleanup

Crux allocates GPU memory, command buffers, and pipelines that
must be freed on all exit paths.

**Spec:**

```
fn process() -> Result[i32, SubstrateError]:
    let mem = alloc(device, 1024)?
    defer: free(mem)                    // runs on function exit
    let prog = compile(device, source)?
    defer: program_destroy(prog)
    dispatch(stream, prog, bindings)?
    Ok(0)
```

**Semantics:**
- `defer` registers a block to execute when the enclosing scope exits.
- Multiple defers execute in LIFO order (reverse of declaration).
- Defers execute on normal return AND error return (via `?`).
- The deferred expression captures variables by reference.

**Status:** Already partially implemented in MIR. Verify it works
correctly for all exit paths (normal return, early return, `?`
propagation). Add test cases.

**Estimated work:** 1 session (verification + test cases).

### 1d. `?` operator — Result/Option propagation

Every Crux API call returns `Result`. Without `?`, error handling
is verbose match/if chains.

**Spec:**

```
fn run() -> Result[i32, SubstrateError]:
    let mem = alloc(device, 1024)?       // returns Err on failure
    let view = view_contiguous(mem, shape, Float32)
    let prog = compile(device, source)?
    dispatch(stream, prog, bindings)?
    Ok(0)
```

**Semantics:**
- `expr?` on `Result[T, E]`: unwrap Ok, propagate Err.
- `expr?` on `Option[T]`: unwrap Some, propagate None.
- Enclosing function must return compatible Result/Option.
- Error type conversion via `From` trait if types differ (future).

**Implementation:**

**MirLower:** Desugar `expr?` to:
```
match expr:
    Ok(v) -> v
    Err(e) -> return Err(e)
```

This is a TK_SWITCH_INT on the discriminant + PK_DOWNCAST for
the payload + TK_RETURN for the error path.

**Status:** Check if already implemented. The spec defines it and
some test infrastructure exists. May need MirLower wiring.

**Estimated work:** 1 session.

### 1e. `for` loop over ranges with `usize`

Crux iterates over shape dimensions, buffer indices, and kernel
parameters using `usize`. The `for i in 0..N` syntax must work
when N is `usize`, not just `i32`.

**Spec:**

Current `for` works with `i32` ranges. Extend to support `usize`
and `i64` ranges without explicit casting.

```
let n: usize = shape.elem_count()
for i in 0..n:                          // i is usize
    process(i)

let m: i64 = 1000000
for j in 0..m:                          // j is i64
    process(j)
```

**Implementation:**

In MirLower, when lowering `NK_FOR`, check the type of the range
endpoints. If they're `usize` or `i64`, the loop variable and
comparison should use the matching type, not always `i32`.

**Estimated work:** 1 session.

---

## Tier 2: Needed for Crux sessions 9-18
*Core programs and tensor library.*

### 2a. Trait dynamic dispatch (vtables)

Crux's Backend trait requires dynamic dispatch — the same code
dispatches to Metal, CPU, or CUDA at runtime.

**Spec:**

```
trait Backend =
    fn alloc(self: &Self, size: usize) -> Result[i64, SubstrateError]
    fn free(self: &Self, handle: i64)
    fn compile(self: &Self, source: ProgramSource) -> Result[i64, SubstrateError]
    fn dispatch(self: &Self, stream: i64, prog: i64, bindings: Bindings) -> Result[i64, SubstrateError]

type MetalBackend = { ctx: i64 }
impl Backend for MetalBackend:
    fn alloc(self: &Self, size: usize) -> Result[i64, SubstrateError]:
        crux_metal_alloc(self.ctx, size)
    // ...

// Dynamic dispatch:
fn run_on(backend: &dyn Backend):
    let mem = backend.alloc(1024)?
```

**Semantics:**
- `&dyn Trait` is a fat pointer: (data_ptr, vtable_ptr).
- vtable contains function pointers for each trait method.
- Method calls through `&dyn Trait` go through vtable indirection.

**Status:** With has partial trait support (sealed traits, trait
bounds on generics). Dynamic dispatch via `&dyn Trait` is not
implemented.

**Workaround (if not ready):** Manual vtable struct:
```
type BackendVtable = {
    alloc_fn: i64,
    free_fn: i64,
    // ...
}
fn backend_alloc(vt: BackendVtable, size: usize) -> Result[i64, SubstrateError]:
    // call vt.alloc_fn as function pointer
```

This works but is ugly. Real `dyn Trait` is better.

**Estimated work:** 3-5 sessions (major feature).

### 2b. Operator overloading

Crux's Scalar, Shape, and View types need arithmetic operators.
Without overloading, every operation is a function call.

**Spec:**

```
impl Add for Shape:
    fn add(self: Shape, other: Shape) -> Shape:
        // element-wise add of dimensions
        ...

let s = shape2(3, 4) + shape2(1, 1)  // shape2(4, 5)
```

**Traits for overloading:**
```
trait Add[Rhs = Self]:
    fn add(self: Self, rhs: Rhs) -> Self

trait Sub[Rhs = Self]:
    fn sub(self: Self, rhs: Rhs) -> Self

trait Mul[Rhs = Self]:
    fn mul(self: Self, rhs: Rhs) -> Self

trait Div[Rhs = Self]:
    fn div(self: Self, rhs: Rhs) -> Self

trait Eq:
    fn eq(self: &Self, other: &Self) -> bool

trait Index[Idx]:
    fn index(self: &Self, idx: Idx) -> &Self::Output
```

**Implementation:**

In Sema's `check_binary_op`, when operands are struct types,
look up the corresponding trait impl (Add, Sub, etc.) and
desugar `a + b` to `Add.add(a, b)`.

**Estimated work:** 2-3 sessions.

### 2c. `@[derive(Debug, Clone, Eq)]`

Crux has dozens of struct types that need debug printing and
comparison.

**Spec:**

```
@[derive(Debug, Clone, Eq)]
type Shape = {
    d0: usize, d1: usize, ...
    rank: i32,
}

let s = shape2(3, 4)
print(debug(s))        // "Shape { d0: 3, d1: 4, ..., rank: 2 }"
let s2 = s.clone()
assert s == s2
```

**Built-in derives:**
- `Debug` → generates `fn debug(self: &Self) -> str`
- `Clone` → generates `fn clone(self: &Self) -> Self`
- `Eq` → generates `fn eq(self: &Self, other: &Self) -> bool`
- `Hash` → generates `fn hash(self: &Self, h: &mut Hasher)`

**Implementation:**

For v1, implement as compiler built-ins (not user-extensible
comptime). Each derive handler:
1. Gets field list from sema
2. Generates AST nodes for the impl
3. Injects before type checking

**Estimated work:** 2-3 sessions.

### 2d. `comptime for` over type fields

Crux's IR interpreter needs dtype-generic dispatch. comptime for
enables writing one function that handles all dtypes:

```
comptime for dtype in [Int8, Int16, Int32, Int64, Float32, Float64]:
    fn scalar_add_{dtype}(a: u64, b: u64) -> u64:
        let va = transmute[dtype](a)
        let vb = transmute[dtype](b)
        transmute[u64](va + vb)
```

**Spec:**

```
comptime_for = "comptime" "for" IDENT "in" comptime_expr ":" block
```

The body is stamped out once per element. Each iteration has the
element available as a comptime constant.

**Implementation:**

The comptime evaluator unrolls the loop at compile time, substituting
the iteration variable. Each copy is independently type-checked.

**Estimated work:** 2-3 sessions.

### 2e. Slice types `[]T`

Crux frequently passes variable-length sequences (parameter lists,
binding arrays, IR instruction sequences).

**Spec:**

```
fn sum(data: []f32) -> f32:
    var total: f32 = 0.0
    for i in 0..data.len():
        total = total + data[i]
    total

let arr: [f32; 4] = [1.0, 2.0, 3.0, 4.0]
let s = sum(arr[..])      // slice of entire array
let s2 = sum(arr[1..3])   // slice of elements 1, 2
```

**Semantics:**
- `[]T` is a fat pointer: `(ptr: *const T, len: usize)`.
- Created by slicing an array or Vec.
- Read-only by default. `[]mut T` for mutable slices.
- No ownership — borrows the underlying storage.
- Bounds-checked in debug mode.

**Implementation:**

**Sema:** Add `TY_SLICE` type kind with d0=element_type_id.
**Codegen:** Represent as `{ ptr, len }` struct in LLVM.
**MirLower:** Slice indexing via GEP on the pointer.

**Estimated work:** 2-3 sessions.

---

## Tier 3: Needed for Crux sessions 19-30
*Transformer inference and multi-backend.*

### 3a. Async functions / thread pool

Crux's CPU backend needs parallel execution for `parallel[grid]`
dispatch. This requires either:
- OS threads + thread pool
- async/await with a runtime

**Spec (minimal, thread pool only):**

```
fn parallel_for(start: usize, end: usize, body: fn(usize)):
    // Dispatches body(i) for i in start..end across thread pool
```

**Implementation:**

Use pthreads via c_import:
```
use c_import("pthread.h", link: "pthread")
```

Create a global thread pool (N = cpu_count) at substrate init.
Queue work items. Each parallel[grid] iteration becomes a work item.

**Workaround if no closures:** Pass a struct with the iteration
range and a function pointer.

**Estimated work:** 2-3 sessions.

### 3b. SIMD intrinsics (or auto-vectorization control)

Crux's CPU backend needs vector operations for elementwise kernels
and reductions.

**Spec:**

Option A (LLVM auto-vectorization):
Emit loops with `@[vectorize]` hint. LLVM's loop vectorizer
handles the rest. This is the minimum viable approach.

Option B (explicit SIMD):
```
use simd

let a = simd.load_f32x4(ptr)
let b = simd.load_f32x4(ptr + 16)
let c = simd.add_f32x4(a, b)
simd.store_f32x4(out_ptr, c)
```

**Recommendation:** Start with auto-vectorization (Option A).
The With compiler already uses LLVM. Adding `-march=native` and
`-mattr=+neon` (or `+avx2`) to the LLVM compilation flags enables
auto-vectorization without language changes.

**Estimated work:** 1 session (compiler flags) to 3 sessions (explicit SIMD).

### 3c. `@[test]` attribute and built-in test runner

Crux needs hundreds of correctness tests.

**Spec:**

```
@[test]
fn test_shape_elem_count():
    assert shape2(3, 4).elem_count() == 12

@[test]
fn test_view_slice():
    let v = view_contiguous(0, shape2(10, 20), DTYPE_FLOAT32)
    let s = view_slice(v, 0, 2, 5)
    assert shape_get(s.shape, 0) == 3
```

```bash
with test lib/crux/test/     # runs all @[test] functions
with test lib/crux/test/test_view.w  # runs tests in one file
```

**Implementation:**

**Parser:** `@[test]` attribute on functions → `FN_FLAG_TEST`.
**Compiler:** When building in test mode, collect all test
functions, generate a main that calls each and reports results.
**CLI:** `with test <path>` command.

**Estimated work:** 2 sessions.

### 3d. `HashMap[K, V]` performance

Crux's compilation cache and binding lookup need fast hash maps.
The current With HashMap works but may be slow for hot-path lookups.

**Status:** HashMap exists and works. Profile performance. If too
slow, optimize the hash function (current: unknown) or switch to
Robin Hood / Swiss Table.

**Estimated work:** 1 session (profiling + potential optimization).

---

## Tier 4: Nice-to-have (improve ergonomics)
*Not blocking but make Crux code significantly better.*

### 4a. Named/labeled break and continue

```
for outer i in 0..M:
    for j in 0..N:
        if condition:
            break outer     // breaks the outer loop
```

Crux's IR interpreter and kernel generators have nested loops
where breaking the outer loop is needed.

**Estimated work:** 1 session.

### 4b. Tuple types

```
fn min_max(data: []f32) -> (f32, f32):
    var lo = data[0]
    var hi = data[0]
    for i in 1..data.len():
        lo = min(lo, data[i])
        hi = max(hi, data[i])
    (lo, hi)

let (lo, hi) = min_max(data)
```

Crux/Weld functions often need to return multiple values. Currently
requires a struct type for each combination.

**Implementation:**

Tuples are anonymous structs: `(T1, T2, ...)` is sugar for
`{ _0: T1, _1: T2, ... }`. Destructuring assignment unpacks them.

**Estimated work:** 2 sessions.

### 4c. Type aliases

```
type Handle = i64
type ByteOffset = usize
type ElemStride = isize
```

Crux uses `i64` for many semantically different things (handles,
offsets, sizes). Type aliases improve readability.

**Status:** `type Name = other_type` already works for struct
aliases. Verify it works for primitive types.

**Estimated work:** 0-1 sessions (may already work).

### 4d. Const generics

```
fn dot_product[N: usize](a: [f32; N], b: [f32; N]) -> f32:
    var sum: f32 = 0.0
    for i in 0..N:
        sum = fma(a[i], b[i], sum)
    sum
```

Crux's tile sizes, ranks, and array dimensions are compile-time
constants that vary per kernel. Const generics enable writing
one function that works for any tile size.

**Implementation:**

In the generic instantiation path, allow integer values (not just
types) as generic parameters. The monomorphizer stamps out a
concrete function for each unique value.

**Estimated work:** 2-3 sessions.

### 4e. Closures / function values

```
fn map(data: []f32, f: fn(f32) -> f32) -> Vec[f32]:
    var out = Vec.new()
    for i in 0..data.len():
        out.push(f(data[i]))
    out

let doubled = map(data, fn(x: f32) -> f32: x * 2.0)
```

Crux's thread pool (Tier 3a) needs function values for work
dispatch. Also useful for: reduction combiners, kernel generators,
test harness callbacks.

**Status:** Closures exist in With (NK_CLOSURE, gen_closure).
Verify they work for the patterns Crux needs: capture by value,
no recursive closures, function pointers for non-capturing closures.

**Estimated work:** 1 session (verification) to 2 sessions (fixes).

### 4f. `enum` methods and match improvements

```
enum SubstrateError =
    | OutOfMemory
    | DeviceLost
    | CompileError(str)
    | ShapeMismatch(str)

impl SubstrateError:
    fn message(self: &Self) -> str:
        match self:
            OutOfMemory -> "out of memory"
            DeviceLost -> "device lost"
            CompileError(msg) -> "compile error: " ++ msg
            ShapeMismatch(msg) -> "shape mismatch: " ++ msg
```

Crux's error types need methods for message extraction and display.

**Estimated work:** 1-2 sessions.

### 4g. `pub` visibility modifier

```
pub type Shape = { ... }
pub fn alloc(device: i64, size: usize) -> Result[i64, SubstrateError]: ...
fn internal_helper() -> i32: ...    // not exported
```

Crux is a library. It needs to control which symbols are public
API vs internal implementation.

**Estimated work:** 1-2 sessions.

### 4h. Module system / namespaces

```
use crux.core
use crux.metal
use crux.ir

let device = crux.metal.create_device()
let mem = crux.core.alloc(device, 1024)
```

Crux has ~20 source files. Without namespaces, every function
and type is in the global scope. Collisions are inevitable.

**Estimated work:** 3-5 sessions (significant feature).

### 4i. `assert` with message

```
assert view.shape.rank > 0, "view must have at least one dimension"
assert i < N, "index {i} out of bounds (N={N})"
```

Crux's validation code needs assertions that produce useful
error messages, not just "assertion failed".

**Implementation:** `assert` already exists. Add optional second
argument (message string). If the assertion fails, print the
message before aborting.

**Estimated work:** 1 session.

### 4j. Numeric type conversions (`as` casts)

```
let x: i32 = 42
let y: i64 = x as i64        // widening (always safe)
let z: f32 = x as f32        // int to float
let w: i32 = 3.14 as i32     // float to int (truncates)
let n: usize = x as usize    // signed to unsigned
```

**Status:** `as` casts exist for some type pairs. Verify all
numeric type pairs work: i8↔i16↔i32↔i64↔i128, u8↔u16↔u32↔u64↔u128,
f32↔f64, int↔float, signed↔unsigned, pointer↔integer.

**Estimated work:** 1 session (audit + fixes).

---

## Tier 5: Future (after Crux v1)
*Not needed for initial Crux/Weld but important for the ecosystem.*

### 5a. Borrow checker

Resource safety for Memory handles, preventing use-after-free
at compile time.

### 5b. Async/await with fiber runtime

For async GPU dispatch patterns — submit work, do CPU work,
await completion.

### 5c. Generators / iterators

For streaming data processing, lazy evaluation of IR.

### 5d. Package manager

For distributing Crux/Weld as a library that other projects depend on.

### 5e. Documentation comments

`///` doc comments that generate HTML documentation.

### 5f. Compile-time string processing

For IR text format parsing at compile time (compile-time regex,
string splitting, etc.).

---

## Implementation Order

This is the recommended order, interleaved with Crux sessions:

```
Sprint  Feature                         Crux unblocks
──────  ──────────────────────────────  ─────────────────
  1     0a. Fixed-size arrays           Session 1 (Shape, Strides)
  2     0b. Bitwise ops on all types    Session 3 (IR ops)
        1e. for loops with usize        Session 1 (iteration)

  3     1d. ? operator verification     Session 2 (error handling)
        1c. defer verification          Session 2 (resource cleanup)
        4j. Numeric cast audit          Session 1 (type conversions)

  4     1b. String interpolation        Session 6 (MSL generation)

  --- Crux sessions 1-4 can proceed ---

  5     1a. comptime if                 Session 5 (Metal conditional)

  --- Crux sessions 5-8 can proceed ---

  6     2c. @[derive(Debug, Eq)]        Session 9+ (debugging)
  7     2b. Operator overloading        Session 14 (Tensor ops)
  8     4b. Tuple types                 Session 14 (multiple returns)

  --- Crux sessions 9-13 can proceed ---

  9     2a. Trait dynamic dispatch      Session 14 (Backend trait)
 10     4e. Closures verification       Session 14 (callbacks)
 11     3c. @[test] attribute           All sessions (testing)

  --- Crux sessions 14-18 can proceed ---

 12     3a. Thread pool / parallel_for  Session 19 (CPU backend)
 13     4a. Named break/continue        Session 19 (nested loops)
 14     2e. Slice types                 Session 19 (buffer passing)

  --- Crux sessions 19-25 can proceed ---

 15     2d. comptime for                Session 26+ (dtype generic)
 16     4d. Const generics              Session 26+ (tile sizes)
 17     4g. pub visibility              Release prep
 18     4h. Module system               Release prep

  --- Crux v1 complete ---
```

**Total: ~30 sprints of language work to fully support Crux.**
The first 4 sprints unblock Crux session 1. By sprint 8, Weld
can build the full tensor library. The rest is progressive
improvement.

---

## What Already Works (no implementation needed)

These With features are already implemented and Crux depends on them:

- `usize` / `isize` types ✓
- `i128` / `u128` types ✓
- Opaque types (`type Device = opaque`) ✓
- Union types (`type Scalar = union { ... }`) ✓
- `unsafe` blocks ✓
- Raw pointer arithmetic (`ptr + n`, `*ptr`) ✓
- `null` literal ✓
- `sizeof[T]()` and `alignof[T]()` ✓
- `transmute[T](value)` ✓
- `extern fn` declarations ✓
- `extern var` / `extern let` ✓
- `c_import` for C headers ✓
- `@[repr(C)]` structs ✓
- `@[packed]` structs ✓
- `comptime_error("msg")` ✓
- `Result[T, E]` and `Option[T]` ✓
- Generic functions ✓
- `Vec[T]` and `HashMap[K, V]` ✓
- `match` on enums ✓
- String concatenation (`++`) ✓
- `let` / `var` bindings ✓
- `if` / `else` / `while` / `for` control flow ✓
- Struct types with methods ✓
- Enum types (regular and discriminant) ✓
- Trait declarations and impls ✓
- Float types (f32, f64) ✓
- Inline `@[inline]` attribute ✓