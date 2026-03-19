# With Language Enhancements for Weld

**Purpose:** Every With language change — required, helpful, or
nice-to-have — that Weld needs. Organized by the Weld session
that first needs it, with implementation difficulty estimates.

**Companion to:** weld-design.md, weld-impl-notes.md

**Context:** Weld's ownership model (Part 1 of the spec) depends
on three language features working correctly together: `@[drop]`,
auto-referencing, and move semantics. These three are the
foundation. Everything else is progressive improvement.

---

## Critical (Weld cannot function without these)

### C1. `@[drop]` — Automatic resource cleanup (RAII)

**First needed:** Session 14 (Tensor, Storage)
**Difficulty:** 3-4 sessions (major, but well-scoped)

Tensor implements Drop to decrement Storage refcount. Without this,
every intermediate tensor leaks on error paths. This is the single
highest-priority language feature for Weld.

**Spec:**

```
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
- Compiler inserts drop calls at scope exit on ALL paths: normal
  return, early return, `?` propagation, break, continue.
- Drop order is reverse declaration order (LIFO).
- A moved value is NOT dropped (new owner is responsible).
- A returned value is NOT dropped (caller owns it).
- `Copy` and `Drop` are mutually exclusive.

**Drop on reassignment:** When a `var` binding of a droppable type
is reassigned, the old value is dropped before the new value is
stored. This is critical for Weld's transformer loop:

```
var h = embedding(ctx, self.embed.weight, tokens)
for i in 0..self.blocks.len():
    h = self.blocks[i].forward(ctx, h)
    // old h dropped here — Storage refcount decremented
```

**Drop on expression temporaries:** Temporaries created within an
expression are dropped at the end of the statement. This frees
intermediate tensors:

```
let c = relu(ctx, add(ctx, a, b))
// add's result is a temporary — dropped after relu reads it
// only c's Storage survives
```

**Implementation (MirLower):**
- Track which locals have droppable types.
- At every scope exit point, insert drop calls for live locals
  in reverse declaration order.
- On `var` reassignment, insert drop of old value before store.
- Mark locals as "moved" when assigned to another binding or
  returned. Moved locals are not dropped.
- Expression temporaries: allocate unnamed locals, drop at
  statement end.

---

### C2. Auto-referencing at function call sites

**First needed:** Session 14
**Difficulty:** Already partially implemented (Section 3.8). Needs verification.

When a function expects `&T` and the caller passes `T`, the
compiler automatically takes a reference. This is what makes
the borrow-based API invisible to users:

```
// User writes:
let c = add(ctx, a, b)

// Compiler sees:
let c = add(&ctx, &a, &b)
```

**What needs verification:**
- Works for all argument positions, not just the first.
- Works for method calls on `&self`.
- Works for nested calls: `add(ctx, a, relu(ctx, b))` — the
  temporary from `relu` must be auto-ref'd into `add`.
- Works when the argument is already a reference (no double-ref).
- Works for operator overloading: `a + b` desugars to
  `Add.add(&a, &b)` when the trait method takes `&Self`.
- Works for field access: `self.weight` through `&self` is
  `&Tensor`, passed to a function expecting `&Tensor` — no extra ref.

**Critical interaction with Drop:** Auto-referencing means the
original value stays alive (it's borrowed, not moved). The
compiler must ensure the borrow is valid for the duration of the
function call, and the original is dropped at its natural scope
exit — not at the call site.

---

### C3. Move semantics for Drop types

**First needed:** Session 14
**Difficulty:** 1-2 sessions (piggybacks on Drop implementation)

Assignment of a Drop type moves ownership. The source binding
becomes invalid. Using it after the move is a compile error.

```
let a = zeros(shape2(3, 4), Float32, device)
let b = a          // MOVE — a is now invalid
// let c = add(ctx, a, b)  // COMPILE ERROR: use of moved value 'a'
```

**What Weld needs:**
- Function return is a move (caller owns the result).
- Passing an owned value to a function that takes `T` (not `&T`)
  is a move. (Weld avoids this for Tensor, but it applies to
  other types.)
- `var` reassignment: the new value moves in, the old is dropped.

**Simplified for v1:** A boolean "consumed" flag per binding in
Sema. No full borrow checker. No lifetime annotations. Just:
"has this binding been moved? If yes, error on use."

---

### C4. Fixed-size arrays `[T; N]`

**First needed:** Session 14 (Shape, Strides = `[usize; 8]`)
**Difficulty:** 2-3 sessions

```
let a: [i32; 4] = [1, 2, 3, 4]
let x = a[2]
var b: [f32; 8] = [0.0; 8]     // fill syntax
b[3] = 3.14
```

Shape and stride types are `[usize; 8]`. Without fixed arrays,
these are structs with 8 named fields — no loop-based access.

---

## High Priority (needed for early sessions)

### H1. `defer` — verified on all exit paths

**First needed:** Session 14 (restore_grad pattern)
**Difficulty:** 1 session (verification + fixes)

```
fn run_inference(ctx: &mut Context):
    no_grad(ctx)
    defer: restore_grad(ctx)
    // ... restore_grad called on normal return, early return, ? propagation
```

Verify defer fires on: normal return, early return, `?`, break,
continue. Fix any gaps.

---

### H2. `?` operator — Result/Option propagation

**First needed:** Session 14 (error handling)
**Difficulty:** 1 session (verification)

```
let prog = registry_get_or_compile(ctx.programs, key)?
```

Verify `?` works with `Result[T, E]` and `Option[T]`. Must
interact correctly with defer (defer fires before `?` propagates)
and with Drop (droppable locals are dropped before `?` returns).

---

### H3. `for` loop with `usize` ranges

**First needed:** Session 14 (iteration over shapes, params)
**Difficulty:** 1 session

```
for i in 0..shape.rank:
    // i should be usize when iterating usize ranges
```

Currently may require `as i32` casts. Should work natively with
`usize` and `i64` ranges.

---

### H4. Bitwise operators on all integer types

**First needed:** Session 15 (hashing for program keys, dtype manipulation)
**Difficulty:** 1 session

`&`, `|`, `^`, `~`, `<<`, `>>` on i8, i16, i32, i64, u8, u16,
u32, u64, usize, isize. `>>` is arithmetic for signed, logical
for unsigned.

---

### H5. String interpolation

**First needed:** Session 15 (error messages, debug output)
**Difficulty:** 1-2 sessions

```
let msg = "shape mismatch: {a.shape} vs {b.shape}"
print("loss: {loss.item()}")
```

Desugars to concatenation + to_string calls in parser.

---

## Medium Priority (needed for sessions 14-25)

### M1. Operator overloading

**First needed:** Session 15 (Tensor + Tensor, scalar arithmetic)
**Difficulty:** 2-3 sessions

```
trait Add[Rhs = Self]:
    fn add(self: &Self, rhs: &Rhs) -> Self

impl Add for Tensor:
    fn add(self: &Self, rhs: &Self) -> Self:
        weld.add(get_default_context(), self, rhs)
```

**Critical:** Operator traits MUST take `&Self`, not `Self`.
Otherwise `a + b` moves both operands and `a + b + c` fails
(a is consumed by the first `+`). With's auto-referencing
makes `a + b` desugar to `Add.add(&a, &b)`.

Operators needed: `+`, `-`, `*`, `/`, `-` (unary neg).
Comparison operators (`==`, `<`, etc.) return bool tensors.

---

### M2. Closures / function values

**First needed:** Session 15 (make_saved callbacks in elementwise helper)
**Difficulty:** 1-2 sessions (verification — NK_CLOSURE may exist)

```
fn binary_elementwise(ctx: &Context, a: &Tensor, b: &Tensor,
                       op: i32, backward_id: i32,
                       make_saved: fn(&Tensor, &Tensor) -> SavedState) -> Tensor

// Called as:
binary_elementwise(ctx, a, b, OP_MUL, BACKWARD_MUL,
    fn(a: &Tensor, b: &Tensor): SavedState {
        tensors: [save_tensor(a), save_tensor(b)], ...
    })
```

At minimum: function pointers that can be passed as arguments.
Full closures (capturing environment) needed later for
distributed hooks.

---

### M3. Trait dynamic dispatch (dyn Trait)

**First needed:** Session 19 (Module trait, Optimizer trait)
**Difficulty:** 3-5 sessions

```
fn train_step(model: &dyn Module, opt: &mut dyn Optimizer, ctx: &Context):
    let logits = model.forward(ctx, input)
    ...
```

Fat pointer: `(data_ptr, vtable_ptr)`. Needed when different
module types are used polymorphically.

**Workaround:** Integer enum + switch (already used for backward_fn
dispatch). Works for backward functions. Less clean for Module/
Optimizer where the set of implementations is open-ended.

---

### M4. `@[derive(Clone)]` for structs

**First needed:** Session 14 (clone models for data parallel)
**Difficulty:** 1-2 sessions

```
@[derive(Clone)]
type ModelConfig = { ... }
```

Auto-generates a `clone` method that clones each field. For types
containing Tensors, clone must allocate new Storage (deep copy).

Note: `derive(Clone)` for Tensor must call `clone()` (which
allocates new Storage), not just copy the struct fields (which
would share Storage without incrementing refcount — use-after-free).

---

### M5. `@[derive(Debug)]` for structs

**First needed:** Session 14 (debugging, error messages)
**Difficulty:** 1-2 sessions

```
@[derive(Debug)]
type Shape = { rank: i32, dims: [usize; 8] }
print("{shape}")  // Shape { rank: 2, dims: [3, 4, ...] }
```

---

### M6. Slice types `[]T` and `[]mut T`

**First needed:** Session 17 (passing variable-length tensor lists)
**Difficulty:** 2-3 sessions

```
fn cat(ctx: &Context, tensors: &[Tensor], dim: i32) -> Tensor
fn encode(tok: &Tokenizer, text: &str) -> Vec[i32]
```

Fat pointer: `(ptr, len)`. `&[T]` is an immutable view into a
contiguous sequence. Used extensively for passing lists of tensors,
token arrays, etc.

---

### M7. Numeric cast audit

**First needed:** Session 14 (usize ↔ i32 ↔ i64 ↔ f64)
**Difficulty:** 1 session

Verify all `as` casts work correctly for all numeric type pairs.
Weld constantly casts between usize (for indexing), i32 (for dims),
i64 (for handles), and f64 (for scalar values).

---

### M8. `comptime if` — conditional compilation

**First needed:** Session 15 (platform-specific backends)
**Difficulty:** 2-3 sessions

```
comptime if cfg.has_metal:
    fn create_metal_device() -> *mut Device: ...
comptime else:
    fn create_metal_device() -> *mut Device: null
```

Needed for multi-backend Crux code that Weld calls into.

---

## Lower Priority (sessions 19-32 and polish)

### L1. `@[test]` attribute and test runner

**First needed:** Session 14 (but can use workaround until then)
**Difficulty:** 2 sessions

```
@[test]
fn test_matmul_grad():
    let ctx = context_default()
    check_grad(ctx, fn(ctx, x): matmul(ctx, x, w), input, 1e-4, 1e-3, 1e-3)
```

Without this, tests are regular functions called from a test main.
Works but verbose.

---

### L2. Tuple types

**First needed:** Session 19 (named_parameters returns `Vec[(str, *mut Tensor)]`)
**Difficulty:** 2 sessions

```
fn named_parameters(self: &Self) -> Vec[(str, *mut Tensor)]

let (name, param) = named_params[i]
```

Destructuring assignment on tuples. Needed for named_parameters
and for iterating over (key, value) pairs.

---

### L3. `comptime for` over type fields

**First needed:** Session 20 (dtype-generic dispatch)
**Difficulty:** 2-3 sessions

```
comptime for dtype in [Float16, Float32, BFloat16]:
    register_program(OP_ADD, dtype, generate_add_ir(dtype))
```

Reduces boilerplate in program registration.

---

### L4. Named break / continue

**First needed:** Session 19 (nested loops in transformer code)
**Difficulty:** 1 session

```
for outer i in 0..num_layers:
    for j in 0..num_params:
        if found: break outer
```

---

### L5. `assert` with message

**First needed:** Session 14 (shape validation)
**Difficulty:** 1 session

```
assert shape_get(a.shape, -1) == shape_get(b.shape, -2),
       "matmul: inner dimensions must match: {K_a} vs {K_b}"
```

---

### L6. Type aliases

**First needed:** Session 14 (Handle = i64, etc.)
**Difficulty:** 0-1 sessions (may already work)

```
type Handle = i64
type DeviceHandle = i64
type StreamHandle = i64
```

---

### L7. Enum methods

**First needed:** Session 13 (WeldError.message())
**Difficulty:** 1-2 sessions

```
impl WeldError:
    fn message(self: &Self) -> str:
        match self:
            ShapeMismatch(s) => s
            DTypeMismatch(s) => s
            ...
```

---

### L8. `pub` visibility

**First needed:** Session 19 (module system — public API vs internals)
**Difficulty:** 1-2 sessions

```
pub fn add(ctx: &Context, a: &Tensor, b: &Tensor) -> Tensor
fn broadcast_shapes_internal(a: Shape, b: Shape) -> Shape  // private
```

---

### L9. Module system / namespaces

**First needed:** Session 19 (use weld.nn, use weld.optim)
**Difficulty:** 3-5 sessions

```
use weld
use weld.nn
use weld.distributed
```

Allows organizing Weld into `weld.nn.Linear`, `weld.optim.Adam`,
etc. Without this, everything is in one flat namespace.

---

### L10. Const generics

**First needed:** Not required, nice-to-have
**Difficulty:** 2-3 sessions

```
fn dot[N: usize](a: &[f32; N], b: &[f32; N]) -> f32
```

Would allow Shape to be generic over rank, but the fixed `[usize; 8]`
approach works fine.

---

## Nice-to-Have (quality of life)

### N1. Thread pool / parallel_for

**First needed:** Session 26 (CPU backend optimization)
**Difficulty:** 2-3 sessions

```
parallel_for(0, num_elements, fn(i: usize):
    output[i] = input[i] * 2.0
)
```

For CPU backend performance. Not needed for GPU backends.

---

### N2. SIMD intrinsics or auto-vectorization

**First needed:** Session 26 (CPU backend optimization)
**Difficulty:** 1-3 sessions

Start with LLVM auto-vectorization via `-march=native`.
Explicit SIMD later if needed.

---

### N3. HashMap performance optimization

**First needed:** When profiling shows it's a bottleneck
**Difficulty:** 1 session

ProgramRegistry and tokenizer vocabulary use HashMap.
Profile and optimize if needed.

---

### N4. `@[derive(Eq)]` for structs

**First needed:** Session 14 (Shape comparison)
**Difficulty:** 1 session (alongside derive(Debug, Clone))

```
@[derive(Eq)]
type Shape = { rank: i32, dims: [usize; 8] }
if a.shape == b.shape: ...
```

---

## Feature Interaction Map

Some features interact with each other. These interactions
must be tested together:

### Drop + Auto-ref + Move (the triad)

These three features together enable Weld's ownership model.
They MUST be tested as a unit:

```
// This must compile and run correctly:
fn example(ctx: &Context):
    let a = zeros(shape2(3, 4), Float32, device)
    let b = ones(shape2(3, 4), Float32, device)
    let c = add(ctx, a, b)     // a, b auto-ref'd, not moved
    let d = add(ctx, a, c)     // a reused — still valid (borrowed)
    let e = relu(ctx, d)       // d auto-ref'd
    // scope exit: e, d, c, b, a dropped in reverse order
    // each drop decrements Storage refcount
    // memory freed when refcount reaches 0
```

### Drop + `var` reassignment

```
var h = zeros(...)
h = ones(...)    // old h must be dropped BEFORE new value stored
```

### Drop + `?` operator

```
fn fallible(ctx: &Context) -> Result[Tensor, WeldError]:
    let a = zeros(...)
    let b = compile_program(ctx)?  // if Err: a must be dropped
    Ok(add(ctx, a, b))
```

### Drop + expression temporaries

```
let c = relu(ctx, add(ctx, a, b))
// The temporary from add must be dropped after relu returns
// BEFORE the next statement executes
```

### Drop + defer

```
fn inference(ctx: &mut Context):
    no_grad(ctx)
    defer: restore_grad(ctx)
    let t = zeros(...)
    // on exit: t is dropped FIRST, then defer runs restore_grad
    // (defer runs after local drops? or before? Must be specified.)
```

**Decision needed:** Does defer run before or after local drops?
Recommendation: defer runs AFTER local drops (Rust model). This
means defer cleanup can assume locals are already freed.

### Auto-ref + operator overloading

```
// trait Add takes &Self:
let c = a + b      // desugars to Add.add(&a, &b)
let d = a + b + c  // desugars to Add.add(&Add.add(&a, &b), &c)
// The temporary from the inner add must be auto-ref'd into the outer add
```

### Closures + borrows

```
fn make_saved(a: &Tensor, b: &Tensor) -> SavedState:
    SavedState { tensors: [save_tensor(a), save_tensor(b)], ... }

binary_elementwise(ctx, a, b, OP_MUL, BACKWARD_MUL, make_saved)
// make_saved receives &Tensor — borrows a and b
```

If closures capture by reference, the captured values must outlive
the closure. For Weld's use (immediate invocation within the same
scope), this is always satisfied.

---

## Implementation Priority Order

```
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
        M7. Numeric casts   1 sess      usize/i32/i64 conversions

  6     H5. String interp   1-2 sess    Error messages, debug

  === Sessions 14-18 can start ===

  7     M1. Op overloading  2-3 sess    a + b syntax
  8     M2. Closures        1-2 sess    make_saved callbacks
  9     M4. derive(Clone)   1-2 sess    Model cloning for DP
        M5. derive(Debug)   (included)
        N4. derive(Eq)      (included)
 10     L2. Tuple types     2 sess      named_parameters

  === Sessions 19-25 can start ===

 11     M3. dyn Trait        3-5 sess   Module polymorphism
 12     M6. Slice types      2-3 sess   &[Tensor] params
 13     L1. @[test]          2 sess     Test runner
 14     M8. comptime if      2-3 sess   Platform backends

  === Sessions 28-32 can start ===

 15     L5. assert + message 1 sess     Better errors
 16     L6. Type aliases     0-1 sess   Code clarity
 17     L7. Enum methods     1-2 sess   WeldError
 18     L8. pub visibility   1-2 sess   API surface
 19     L9. Module system    3-5 sess   use weld.nn
 20     L3. comptime for     2-3 sess   Dtype dispatch
 21     N1. Thread pool      2-3 sess   CPU backend
 22     N2. SIMD             1-3 sess   CPU backend
```

**Critical path:** Sprints 1-4 unblock Weld session 14. Fixed
arrays and `@[drop]` are the two features that most change how
code is written. Sprint 4 is the big one — Drop, move semantics,
and auto-ref verification all land together, and the ownership
model must be tested as a unit before Weld session 14 begins.

---

## What Already Works

These With features are confirmed working and used by Weld:

- Generic functions ✓
- `Vec[T]` and `HashMap[K, V]` ✓
- `Result[T, E]` and `Option[T]` ✓
- Struct types with methods ✓
- Enum types with `match` ✓
- Trait declarations and impls ✓
- `unsafe` blocks ✓
- Raw pointer arithmetic (`*mut T`) ✓
- `null` pointer literal ✓
- `sizeof[T]()` / `alignof[T]()` ✓
- `transmute[T](value)` ✓
- `extern fn` / `extern var` ✓
- `c_import` ✓
- `@[repr(C)]` / `@[packed]` / `@[noalias]` ✓
- `comptime_error("msg")` ✓
- String concatenation (`++`) ✓
- Float types (f32, f64) ✓
- All integer types (i8-i128, u8-u128, usize, isize) ✓
- `@[inline]` ✓
- `usize` / `isize` ✓