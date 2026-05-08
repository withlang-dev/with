## Critical (Weld cannot function without these)
*These form the core memory and data models. Cannot start Crux/Weld without these.*

### C1. `@[drop]` — Automatic resource cleanup (RAII)
**First needed:** Session 14 (Tensor, Storage)
**Difficulty:** 3-4 sessions (major, but well-scoped)

Tensor implements Drop to decrement Storage refcount. Without this, every intermediate tensor leaks on error paths. This is the single highest-priority language feature for Weld.

**Spec:**
```with
@[drop]
type Tensor = {
    storage: *mut Storage,
    view: View,
    grad_meta: *mut GradMeta,
}

impl Drop for Tensor:
    fn drop(self: &mut Self):
        if self.storage != null:
            storage_release(self.storage)
        if self.grad_meta != null:
            grad_meta_release(self.grad_meta)
```

**Semantics:**
- `Drop` is a built-in trait: `fn drop(self: &mut Self)`
- Compiler inserts drop calls at scope exit on ALL paths: normal return, early return, `?` propagation, break, continue.
- Drop order is reverse declaration order (LIFO).
- A moved value is NOT dropped (new owner is responsible).
- A returned value is NOT dropped (caller owns it).
- `Copy` and `Drop` are mutually exclusive.

**Drop on reassignment:** When a `var` binding of a droppable type is reassigned, the old value is dropped before the new value is stored. This is critical for Weld's transformer loop:
```with
var h = embedding(ctx, self.embed.weight, tokens)
for i in 0..self.blocks.len():
    h = self.blocks[i].forward(ctx, h)
    // old h dropped here — Storage refcount decremented
```

**Drop on expression temporaries:** Temporaries created within an expression are dropped at the end of the statement. This frees intermediate tensors:
```with
let c = relu(ctx, add(ctx, a, b))
// add's result is a temporary — dropped after relu reads it
// only c's Storage survives
```

**Implementation (MirLower):**
- Track which locals have droppable types.
- At every scope exit point, insert drop calls for live locals in reverse declaration order.
- On `var` reassignment, insert drop of old value before store.
- Mark locals as "moved" when assigned to another binding or returned. Moved locals are not dropped.
- Expression temporaries: allocate unnamed locals, drop at statement end.

### C2. Auto-referencing at function call sites
**First needed:** Session 14 (Invisible borrow-based API)
**Difficulty:** Already partially implemented (Section 3.8). Needs verification.

When a function expects `&T` and the caller passes `T`, the compiler automatically takes a reference. This is what makes the borrow-based API invisible to users:

```with
// User writes:
let c = add(ctx, a, b)

// Compiler sees:
let c = add(&ctx, &a, &b)
```

**What needs verification:**
- Works for all argument positions, not just the first.
- Works for method calls on `&self`.
- Works for nested calls: `add(ctx, a, relu(ctx, b))` — the temporary from `relu` must be auto-ref'd into `add`.
- Works when the argument is already a reference (no double-ref).
- Works for operator overloading: `a + b` desugars to `Add.add(&a, &b)` when the trait method takes `&Self`.
- Works for field access: `self.weight` through `&self` is `&Tensor`, passed to a function expecting `&Tensor` — no extra ref.

**Critical interaction with Drop:** Auto-referencing means the original value stays alive (it's borrowed, not moved). The compiler must ensure the borrow is valid for the duration of the function call, and the original is dropped at its natural scope exit — not at the call site.

### C3. Move semantics for Drop types
**First needed:** Session 14
**Difficulty:** 1-2 sessions (piggybacks on Drop implementation)

Assignment of a Drop type moves ownership. The source binding becomes invalid. Using it after the move is a compile error.

```with
let a = zeros(shape2(3, 4), Float32, device)
let b = a          // MOVE — a is now invalid
// let c = add(ctx, a, b)  // COMPILE ERROR: use of moved value 'a'
```

**What Weld needs:**
- Function return is a move (caller owns the result).
- Passing an owned value to a function that takes `T` (not `&T`) is a move. (Weld avoids this for Tensor, but it applies to other types.)
- `var` reassignment: the new value moves in, the old is dropped.

**Implementation Simplified for v1:** A boolean "consumed" flag per binding in Sema. No full borrow checker. No lifetime annotations. Just: "has this binding been moved? If yes, error on use."

### C4. Fixed-size arrays `[T; N]`
**First needed:** Session 1 (Shape, Strides)
**Difficulty:** 2-3 sessions

Crux's Shape and Strides need `[usize; 8]` and `[isize; 8]`. The struct-with-8-fields workaround is ugly, error-prone, and prevents loop-based access. This is the #1 missing structure feature.

**Spec:**
```with
fixed_array_type = "[" type ";" int_expr "]"
```
A fixed-size array is a value type with compile-time-known length. Stack-allocated. Copyable. Indexable.

```with
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
- **Lexer/Parser:**
  - Parse `[T; N]` in type position as `NK_ARRAY_TYPE` with data0=element_type_node, data1=size_expr_node.
  - Parse `[v0, v1, ...]` as `NK_ARRAY_LIT` (already exists for dynamic arrays — extend or add `NK_FIXED_ARRAY_LIT`).
  - Parse `[value; N]` as `NK_ARRAY_REPEAT` (new node kind).
  - Parse `arr[i]` reuses existing `NK_INDEX` (already works).
- **Sema:**
  - Add `TY_FIXED_ARRAY` type kind with d0=element_type_id, d1=length (i32).
  - Type checking: index expression must be integer. Array length must be compile-time evaluable.
  - `[T; N]` in struct fields: layout is inline (no pointer indirection), size = N * elem_size.
- **Codegen:**
  - Map `[T; N]` to `LLVMArrayType(elem_type, N)`.
  - Array literal: `LLVMConstArray` for constants, sequential `LLVMBuildInsertValue` for runtime values.
  - Index: `LLVMBuildExtractValue` for constant index, GEP + load for runtime index.
  - Pass by value: LLVM handles small arrays in registers, large arrays via stack copy (sret).
- **MirLower:**
  - `NK_FIXED_ARRAY_LIT` → `RK_AGGREGATE` with element operands.
  - `NK_ARRAY_REPEAT` → loop of `SK_ASSIGN` to each index.
  - Index on fixed array → `PK_INDEX` projection (reuse existing).

---

## High Priority (needed for early sessions)
*Core substrate implementation depends on these.*

### H1. `defer` — verified on all exit paths
**First needed:** Session 14 (restore_grad pattern)
**Difficulty:** 1 session (verification + fixes)

Crux allocates GPU memory, command buffers, and pipelines that must be freed on all exit paths.

**Spec:**
```with
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

**Implementation Status:** Already partially implemented in MIR. Verify it works correctly for all exit paths (normal return, early return, `?` propagation). Add test cases.

### H2. `?` operator — Result/Option propagation
**First needed:** Session 2
**Difficulty:** 1 session

Every Crux API call returns `Result`. Without `?`, error handling is verbose match/if chains.

**Spec:**
```with
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

**Implementation (MirLower):** Desugar `expr?` to:
```with
match expr:
    Ok(v) -> v
    Err(e) -> return Err(e)
```
This is a `TK_SWITCH_INT` on the discriminant + `PK_DOWNCAST` for the payload + `TK_RETURN` for the error path. Interacts with `defer` (defer fires before `?` propagates) and `Drop` (locals are dropped before `?` returns).

### H3. `for` loop with `usize` ranges
**First needed:** Session 1 (iteration over shapes, params)
**Difficulty:** 1 session

Current `for` works with `i32` ranges. Extend to support `usize` and `i64` ranges without explicit casting.

**Spec:**
```with
let n: usize = shape.elem_count()
for i in 0..n:                          // i is usize
    process(i)
```

**Implementation:** In MirLower, when lowering `NK_FOR`, check the type of the range endpoints. If they're `usize` or `i64`, the loop variable and comparison should use the matching type, not always `i32`.

### H4. Bitwise operators on all integer types
**First needed:** Session 3 (IR ops, hashing for program keys)
**Difficulty:** 1 session (mostly debugging existing codegen)

Crux's IR uses bitwise ops (and, or, xor, shift) extensively. The c_import expression evaluator had to implement shifts via multiplication loops because `<<` and `>>` on i64 broke the seed compiler. These must work natively.

**Spec:**
```with
a & b       // bitwise AND
a | b       // bitwise OR
a ^ b       // bitwise XOR
~a          // bitwise NOT
a << n      // left shift
a >> n      // right shift (arithmetic for signed, logical for unsigned)
```
All operators work on i8-i128, u8-u128. Mixed-width operands are promoted to the wider type.

**Implementation:** These operators already parse and work for i32. The issue is that codegen emits incorrect LLVM IR for 64-bit and 128-bit operands. Debug: Find where `OP_BIT_AND`, `OP_BIT_OR`, `OP_BIT_XOR`, `OP_SHL`, `OP_SHR` are lowered in Codegen.w. Verify that the LLVM instruction uses the correct integer width (not always i32). Fix: In `mir_emit_binop` (or equivalent), ensure the operands are widened/narrowed to match before emitting `LLVMBuildAnd`, `LLVMBuildOr`, `LLVMBuildXor`, `LLVMBuildShl`, `LLVMBuildAShr` (signed) / `LLVMBuildLShr` (unsigned).

### H5. String interpolation
**First needed:** Session 6 (MSL source generation)
**Difficulty:** 1-2 sessions

Crux generates MSL source code via string concatenation. Without interpolation, every kernel emitter is a wall of `++` operators.

**Spec:**
```with
let name = "world"
let s = "hello {name}"           // "hello world"
let n = 42
let s3 = "sum = {a + b}"        // "sum = 7"
```

**Semantics:**
- `{expr}` inside a string is evaluated and converted to str.
- `{{` produces literal `{`, `}}` produces literal `}`.
- Interpolated strings produce owned `str`.

**Implementation:**
- **Parser:** When scanning a string literal and encountering `{`:
  1. Split the string into segments.
  2. Desugar to concatenation: `"hello " ++ to_string(name)`
  3. Each `{expr}` becomes `++ to_string(expr) ++`
- No lexer changes needed — handle entirely in the parser by post-processing string literal tokens.
- **Built-in to_string:** Add `to_string` as a built-in for primitive types (i32, i64, f32, f64, bool, str).

---

## Medium Priority (needed for sessions 14-25)
*Core programs and tensor library.*

### M1. Operator overloading
**First needed:** Session 14 (Tensor ops, scalar arithmetic)
**Difficulty:** 2-3 sessions

Crux's Scalar, Shape, and View types, and Weld's Tensors need arithmetic operators.

**Spec:**
```with
trait Add[Rhs = Self]:
    fn add(self: &Self, rhs: &Rhs) -> Self

impl Add for Tensor:
    fn add(self: &Self, rhs: &Self) -> Self:
        weld.add(get_default_context(), self, rhs)
```
**Critical Interaction:** Operator traits MUST take `&Self`, not `Self`. Otherwise `a + b` moves both operands and `a + b + c` fails. With's auto-referencing makes `a + b` desugar to `Add.add(&a, &b)`.

**Implementation:** In Sema's `check_binary_op`, when operands are struct types, look up the corresponding trait impl (Add, Sub, Mul, Div, Neg, Eq, etc.) and desugar `a + b` to `Add.add(a, b)`.

### M2. Closures / function values
**First needed:** Session 14 (make_saved callbacks in elementwise helper)
**Difficulty:** 1-2 sessions (verification — NK_CLOSURE may exist)

```with
fn binary_elementwise(ctx: &Context, a: &Tensor, b: &Tensor,
                       op: i32, backward_id: i32,
                       make_saved: fn(&Tensor, &Tensor) -> SavedState) -> Tensor
```
Crux's thread pool needs function values for work dispatch. Also useful for reduction combiners and kernel generators. Verify they work for the patterns Crux needs: capture by value, no recursive closures, function pointers for non-capturing closures.

### M3. Trait dynamic dispatch (`dyn Trait`)
**First needed:** Session 14 (Backend trait), Session 19 (Module / Optimizer traits)
**Difficulty:** 3-5 sessions (major feature)

Crux's Backend trait requires dynamic dispatch — the same code dispatches to Metal, CPU, or CUDA at runtime.

**Spec:**
```with
trait Backend =
    fn alloc(self: &Self, size: usize) -> Result[i64, SubstrateError]
    fn compile(self: &Self, source: ProgramSource) -> Result[i64, SubstrateError]
    fn dispatch(self: &Self, stream: i64, prog: i64, bindings: Bindings) -> Result[i64, SubstrateError]

// Dynamic dispatch:
fn run_on(backend: &dyn Backend):
    let mem = backend.alloc(1024)?
```

**Semantics:**
- `&dyn Trait` is a fat pointer: `(data_ptr, vtable_ptr)`.
- vtable contains function pointers for each trait method.
- Method calls through `&dyn Trait` go through vtable indirection.

**Workaround (if not ready):** Manual vtable struct (`BackendVtable { alloc_fn: i64, ... }`).

### M4. `@[derive(Clone, Debug, Eq, Hash)]` for structs
**First needed:** Session 14 (Model cloning for DP, Debugging, Shape comparison)
**Difficulty:** 2-3 sessions

Crux has dozens of struct types that need debug printing and comparison.

**Spec:**
```with
@[derive(Debug, Clone, Eq)]
type Shape = { d0: usize, d1: usize, rank: i32 }

let s = shape2(3, 4)
print(debug(s))        // "Shape { d0: 3, d1: 4, rank: 2 }"
let s2 = s.clone()
assert s == s2
```

**Implementation:**
Implement as compiler built-ins (not user-extensible comptime for v1). Each derive handler:
1. Gets field list from sema
2. Generates AST nodes for the impl
3. Injects before type checking

*Note:* `derive(Clone)` for `Tensor` must call `clone()` (deep copy allocating new `Storage`), not just bit-copy the struct fields (which would cause use-after-free).

### M5. Slice types `[]T` and `[]mut T`
**First needed:** Session 19 (passing variable-length tensor lists)
**Difficulty:** 2-3 sessions

Crux frequently passes variable-length sequences (parameter lists, binding arrays, IR instruction sequences).

**Spec:**
```with
fn sum(data: []f32) -> f32:
    var total: f32 = 0.0
    for i in 0..data.len():
        total = total + data[i]
    total

let arr: [f32; 4] = [1.0, 2.0, 3.0, 4.0]
let s = sum(arr[..])      // slice of entire array
```

**Semantics:**
- `[]T` is a fat pointer: `(ptr: *const T, len: usize)`.
- Created by slicing an array or Vec.
- Read-only by default. `[]mut T` for mutable slices.
- No ownership — borrows the underlying storage.
- Bounds-checked in debug mode.

**Implementation:**
- **Sema:** Add `TY_SLICE` type kind with d0=element_type_id.
- **Codegen:** Represent as `{ ptr, len }` struct in LLVM.
- **MirLower:** Slice indexing via GEP on the pointer.

### M6. Numeric cast audit (`as` casts)
**First needed:** Session 14 (usize ↔ i32 ↔ i64 ↔ f64)
**Difficulty:** 1 session

```with
let x: i32 = 42
let y: i64 = x as i64        // widening (always safe)
let z: f32 = x as f32        // int to float
let n: usize = x as usize    // signed to unsigned
```
**Status:** `as` casts exist for some type pairs. Verify all numeric type pairs work: i8↔i16↔i32↔i64↔i128, u8↔u16↔u32↔u64↔u128, f32↔f64, int↔float, signed↔unsigned, pointer↔integer. Weld constantly casts between these for indexing and handles.

### M7. `comptime if` — conditional compilation
**First needed:** Session 5 (Platform-specific backends)
**Difficulty:** 2-3 sessions

Crux needs platform-specific code paths (Metal vs CUDA vs CPU) without runtime overhead.

**Spec:**
```with
comptime if cfg.target_os == "darwin":
    use c_import("Metal/Metal.h", framework: "Metal")
    fn create_metal_device() -> i64:
        crux_metal_create_device()
comptime else:
    fn create_metal_device() -> i64:
        0  // not available
```

**Semantics & Implementation:**
- Condition must be compile-time evaluable.
- **Sema (early pass):** Before type checking, evaluate comptime if conditions. Replace the comptime if node with the taken branch's contents. Delete eliminated branches from the AST.
- This runs after name resolution but before type checking — so eliminated branches with undefined types don't cause errors.
- **cfg values:** Populated from the target triple and build configuration (`cfg.target_os`, `cfg.has_metal`, `cfg.has_cuda`). Stored in `Sema.cfg_values: HashMap[str, str]`.

---

## Lower Priority (sessions 19-32 and polish)
*Not blocking but make Crux code significantly better.*

### L1. `@[test]` attribute and built-in test runner
**First needed:** Session 14
**Difficulty:** 2 sessions

Crux needs hundreds of correctness tests.
```with
@[test]
fn test_shape_elem_count():
    assert shape2(3, 4).elem_count() == 12
```
**Implementation:**
- **Parser:** `@[test]` attribute on functions → `FN_FLAG_TEST`.
- **Compiler:** When building in test mode, collect all test functions, generate a main that calls each and reports results. Run via `with test <path>`.

### L2. Tuple types
**First needed:** Session 19 (named_parameters returns `Vec[(str, *mut Tensor)]`)
**Difficulty:** 2 sessions

```with
fn min_max(data: []f32) -> (f32, f32): ...
let (lo, hi) = min_max(data)
```
**Implementation:** Tuples are anonymous structs: `(T1, T2, ...)` is sugar for `{ _0: T1, _1: T2, ... }`. Destructuring assignment unpacks them.

### L3. `comptime for` over type fields
**First needed:** Session 26+ (dtype-generic dispatch)
**Difficulty:** 2-3 sessions

Crux's IR interpreter needs dtype-generic dispatch.
```with
comptime for dtype in [Int8, Int16, Int32, Int64, Float32, Float64]:
    fn scalar_add_{dtype}(a: u64, b: u64) -> u64: ...
```
**Implementation:** The comptime evaluator unrolls the loop at compile time, substituting the iteration variable. Each copy is independently type-checked.

### L4. Named/labeled break and continue
**First needed:** Session 19 (nested loops in transformer code)
**Difficulty:** 1 session

```with
for outer i in 0..M:
    for j in 0..N:
        if condition: break outer
```

### L5. `assert` with message
**First needed:** Session 14 (shape validation)
**Difficulty:** 1 session

```with
assert view.shape.rank > 0, "view must have at least one dimension"
```
**Implementation:** `assert` already exists. Add optional second argument (message string). If the assertion fails, print the message before aborting.

### L6. Type aliases
**First needed:** Session 14 (Code clarity)
**Difficulty:** -1 sessions (may already work)

```with
type Handle = i64
type ByteOffset = usize
```
Verify `type Name = other_type` works for primitive types.

### L7. `enum` methods and match improvements
**First needed:** Session 13 (WeldError)
**Difficulty:** 1-2 sessions

```with
impl SubstrateError:
    fn message(self: &Self) -> str:
        match self:
            OutOfMemory -> "out of memory"
            CompileError(msg) -> "compile error: " ++ msg
```

### L8. `pub` visibility modifier
**First needed:** Release prep
**Difficulty:** 1-2 sessions

Crux is a library. It needs to control which symbols are public API vs internal implementation. `pub fn alloc(...)` vs `fn internal_helper()`.

### L9. Module system / namespaces
**First needed:** Release prep
**Difficulty:** 3-5 sessions (significant feature)

```with
use crux.core
use weld.nn

let device = crux.metal.create_device()
```
Crux has ~20 source files. Without namespaces, every function and type is in the global scope. Collisions are inevitable.

### L10. Const generics
**First needed:** Not required, nice-to-have
**Difficulty:** 2-3 sessions

```with
fn dot_product[N: usize](a: [f32; N], b: [f32; N]) -> f32: ...
```
**Implementation:** In the generic instantiation path, allow integer values as generic parameters. The monomorphizer stamps out a concrete function for each unique value.

---

## Nice-to-Have (quality of life)

### N1. Thread pool / parallel_for
**First needed:** Session 19 (CPU backend)
**Difficulty:** 2-3 sessions

Crux's CPU backend needs parallel execution for `parallel[grid]` dispatch.
**Implementation:** Use pthreads via c_import (`use c_import("pthread.h")`). Create a global thread pool at substrate init. Queue work items. Each `parallel[grid]` iteration becomes a work item.

### N2. SIMD intrinsics (or auto-vectorization control)
**First needed:** Session 19 (CPU backend)
**Difficulty:** 1-3 sessions

Start with LLVM auto-vectorization (emitting loops with `@[vectorize]` hints or compiling with `-march=native -mattr=+neon`). If needed later, explicit `simd.load_f32x4(ptr)` built-ins.

### N3. HashMap performance
**First needed:** When profiling shows it's a bottleneck
**Difficulty:** 1 session

Crux's compilation cache and binding lookup need fast hash maps. Profile performance. If too slow, optimize the hash function or switch to Robin Hood / Swiss Table.

---

## Tier 5: Future (after Crux v1)
*Not needed for initial Crux/Weld but important for the ecosystem.*

*   **Borrow checker:** Resource safety for Memory handles, preventing use-after-free at compile time.
*   **Async/await with fiber runtime:** For async GPU dispatch patterns — submit work, do CPU work, await completion.
*   **Generators / iterators:** For streaming data processing, lazy evaluation of IR.
*   **Package manager:** For distributing Crux/Weld as a library that other projects depend on.
*   **Documentation comments:** `///` doc comments that generate HTML documentation.
*   **Compile-time string processing:** For IR text format parsing at compile time.

---

## Feature Interaction Map (Crucial for Weld)

These features must be tested together, as their intersection forms the bedrock of the ML stack:

### 1. The Triad: Drop + Auto-ref + Move
These three features together enable Weld's zero-cost ownership model. They MUST be tested as a unit:
```with
fn example(ctx: &Context):
    let a = zeros(shape2(3, 4), Float32, device)
    let b = ones(shape2(3, 4), Float32, device)
    let c = add(ctx, a, b)     // a, b auto-ref'd, not moved
    let d = add(ctx, a, c)     // a reused — still valid
    let e = relu(ctx, d)       // d auto-ref'd
    // Scope exit: e, d, c, b, a dropped in LIFO order
    // Each drop decrements Storage refcount.
```

### 2. Drop + `var` reassignment
```with
var h = zeros(...)
h = ones(...)    // Old h MUST be dropped BEFORE new value is stored
```

### 3. Drop + Expression Temporaries
```with
let c = relu(ctx, add(ctx, a, b))
// The temporary from add() MUST be dropped AFTER relu() returns,
// but BEFORE the next statement executes.
```

### 4. Auto-ref + Operator Overloading
```with
let d = a + b + c  // desugars to Add.add(&Add.add(&a, &b), &c)
// The temporary owned Tensor from (a+b) must be auto-ref'd
// into the outer addition, then dropped at the statement's end.
```

### 5. Drop + defer
```with
fn inference(ctx: &mut Context):
    no_grad(ctx)
    defer: restore_grad(ctx)
    let t = zeros(...)
    // on exit: t is dropped FIRST, then defer runs restore_grad
    // defer runs AFTER local drops (Rust model), assuming locals are freed.
```

---

## Implementation Priority Order

```text
Sprint  Feature             Difficulty  Unblocks
──────  ──────────────────  ──────────  ────────────────────────────
  1     C4. Fixed arrays    2-3 sess    Shape, Strides everywhere
  2     H4. Bitwise ops     1 sess      Program key hashing
        H3. for + usize     1 sess      All loops

  3     C1. @[drop] pt 1    2 sess      Tensor ownership model
        — scope tracking, drop on normal exit, LIFO order

  4     C1. @[drop] pt 2    2 sess      Full ownership model
        — drop on reassignment, drop on error paths
        — expression temporary drop
        C3. Move semantics   (included)
        C2. Auto-ref verify  1 sess     Call site ergonomics

  5     H1. defer verify    1 sess      restore_grad pattern
        H2. ? operator      1 sess      Error handling
        M6. Numeric casts   1 sess      usize/i32/i64 conversions

  6     H5. String interp   1-2 sess    Error messages, debug

  === Crux Sessions 1-8 can proceed ===
  === Weld Sessions 14-18 can start ===

  7     M1. Op overloading  2-3 sess    a + b syntax
  8     M2. Closures        1-2 sess    make_saved callbacks
  9     M4. @[derive(...)]  2-3 sess    Model cloning, debugging
 10     L2. Tuple types     2 sess      named_parameters

  === Weld Sessions 19-25 can start ===

 11     M3. dyn Trait        3-5 sess   Module polymorphism
 12     M5. Slice types      2-3 sess   &[Tensor] params
 13     L1. @[test]          2 sess     Test runner
 14     M7. comptime if      2-3 sess   Platform backends

  === Weld Sessions 28-32 can start ===

 15     L5. assert + message 1 sess     Better errors
 16     L6. Type aliases     -1 sess   Code clarity
 17     L7. Enum methods     1-2 sess   WeldError
 18     L8. pub visibility   1-2 sess   API surface
 19     L9. Module system    3-5 sess   use weld.nn
 20     L3. comptime for     2-3 sess   Dtype dispatch
 21     N1. Thread pool      2-3 sess   CPU backend
 22     N2. SIMD             1-3 sess   CPU backend
```
