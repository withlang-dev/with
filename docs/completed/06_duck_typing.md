# Spec Addition: Duck-Typed Generics

## Summary

Generic type parameters have no required trait bounds. The
compiler monomorphizes each instantiation and type-checks the
concrete result. If the concrete type doesn't support an
operation used in the body, the compiler emits an error pointing
at both the usage site and the instantiation site.

```
fn triple[T](x: T): x * 3

triple(5)       // ok: i32 supports *
triple(3.14)    // ok: f64 supports *
triple("hi")    // error: str does not support *
```

No `Mul` trait. No bounds syntax. No `where` clauses required.
Just write the function and let the compiler check each
instantiation.

---

## §7.X Generic Type Parameters

### Spec Language

A generic function or type declares type parameters in square
brackets after the name:

```
fn triple[T](x: T): x * 3
fn pair[A, B](a: A, b: B): (a, b)
type Stack[T] = { items: Vec[T], size: i32 }
```

Type parameters are placeholders. They are replaced with concrete
types at each call site or construction site. The compiler
generates a specialized version of the function or type for each
unique set of type arguments.

### No Required Bounds

Type parameters do NOT require trait bounds:

```
fn triple[T](x: T): x * 3       // no bounds needed
```

The compiler does not check the function body against abstract
constraints. Instead, it checks each concrete instantiation. When
`triple(5)` is compiled, the compiler substitutes `T = i32`,
verifies that `i32` supports `*` with an `i32` right-hand side,
and generates the specialized code.

### Optional Bounds

Trait bounds are allowed but never required:

```
fn triple[T](x: T): x * 3             // no bounds: ok
fn triple[T: Mul](x: T): x * 3        // with bounds: also ok
```

When bounds are present, the compiler checks them at the call
site before monomorphization. This produces better error messages
for the caller:

```
// Without bounds:
error: type `str` does not support operator `*`
  --> src/lib.w:1:28
   |
1  | fn triple[T](x: T): x * 3
   |                        ^ used here
   |
   = note: in instantiation of triple[str]
   = note: called from src/main.w:4:5

// With bounds:
error: type `str` does not satisfy bound `Mul`
  --> src/main.w:4:5
   |
4  | triple("hi")
   | ^^^^^^^^^^^^ `str` does not implement `Mul`
```

Bounds are documentation and better errors. They are not
required for correctness. The function works identically with
or without them.

### When to Write Bounds

Style guidance:

- **Public API functions:** write bounds. Callers deserve clear
  error messages at the call site, not inside your library.
- **Internal functions:** omit bounds. The compiler catches
  errors either way.
- **Simple one-liners:** omit bounds. `fn triple[T](x: T): x * 3`
  is clear enough.
- **Complex functions:** consider bounds. If the function uses
  five different operations on `T`, stating the bounds in the
  signature saves the reader from tracing the body.

`with fmt` does not enforce this. It's a judgment call.

---

## §7.X.1 Monomorphization

### Spec Language

Each unique instantiation of a generic function produces a
separate compiled function. `triple[i32]` and `triple[f64]`
are two different functions in the binary.

```
fn double[T](x: T): x + x

double(5)       // generates double_i32: i32 + i32
double(3.14)    // generates double_f64: f64 + f64
double(true)    // error: bool does not support +
```

The compiler performs monomorphization after sema, during or
before MIR lowering. Each instantiation is type-checked
independently. An error in one instantiation does not affect
others:

```
double(5)       // compiles fine
double(true)    // error, but double(5) still works
```

### Instantiation Sites

Monomorphization is triggered by:

- Direct call: `triple(5)` → `triple[i32]`
- Explicit type arguments: `triple[f64](5)` → `triple[f64]`
- Struct construction: `Stack[i32] { items: v, size: 0 }`
- Type annotations: `let s: Stack[str] = Stack.new()`

Type arguments are inferred from value arguments when possible:

```
triple(5)               // T inferred as i32
pair("hi", 42)          // A inferred as str, B as i32
```

Explicit type arguments are required only when inference is
ambiguous:

```
let v = Vec[i32].new()  // can't infer T from no arguments
```

---

## §7.X.2 Error Messages

### Spec Language

When a concrete type does not support an operation used in a
generic function body, the error message must include:

1. **The operation that failed** — which operator or method.
2. **The usage site** — the line in the generic function body.
3. **The instantiation site** — the call that triggered it.
4. **The concrete type** — what `T` was substituted with.

```
error: type `str` does not support operator `*`
  --> src/lib.w:1:28
   |
1  | fn triple[T](x: T): x * 3
   |                        ^ `*` used on type parameter `T`
   |
   = note: in instantiation triple[str]
   = note: instantiated at src/main.w:4:5
   |
4  | triple("hi")
   | ^^^^^^^^^^^^
```

For method calls:

```
error: type `i32` has no method `len`
  --> src/lib.w:2:12
   |
2  |     x.len()
   |       ^^^ method not found on `i32`
   |
   = note: in instantiation describe[i32]
   = note: instantiated at src/main.w:8:5
```

For multiple errors in one instantiation, report all of them,
not just the first.

---

## §7.X.3 Interaction With `it`

`it` in closures works with generic functions:

```
fn apply_twice[T](x: T, f: fn(T) -> T): f(f(x))

items |> map(x => apply_twice(x, it * 2))
```

`it` is not valid in generic function bodies. `it` requires a
call-site context for type inference. Generic function bodies
are checked per-instantiation, not per-call-site:

```
fn triple[T](x: T): it * 3    // ERROR: `it` not valid here
```

---

## §7.X.4 Interaction With Operators

Operators desugar to method calls:

| Operator | Method |
|---|---|
| `+` | `add` |
| `-` | `sub` |
| `*` | `mul` |
| `/` | `div` |
| `%` | `rem` |
| `==` | `eq` |
| `!=` | `ne` |
| `<` | `lt` |
| `<=` | `le` |
| `>` | `gt` |
| `>=` | `ge` |
| `<<` | `shl` |
| `>>` | `shr` |
| `&` | `bit_and` |
| `\|` | `bit_or` |
| `^` | `bit_xor` |
| unary `-` | `neg` |
| unary `!` | `not` |

Built-in types (`i32`, `f64`, `bool`, etc.) have these methods
provided by the compiler. User types implement them via `extend`:

```
type Vec2 = { x: f64, y: f64 }

extend Vec2:
    fn add(self: &Vec2, other: Vec2) -> Vec2:
        Vec2 { x: self.x + other.x, y: self.y + other.y }
    fn mul(self: &Vec2, scalar: f64) -> Vec2:
        Vec2 { x: self.x * scalar, y: self.y * scalar }
```

When a generic function uses `*` on type `T`, the compiler
checks that the concrete type has a `mul` method with a
compatible signature. No `Mul` trait is needed.

---

## §7.X.5 Operator Traits (Optional)

Operator traits exist in the standard library as documentation
and for explicit bounds. They are never required:

```
// In prelude — defined but never required
trait Add =
    fn add(self: &Self, rhs: Self) -> Self

trait Mul =
    fn mul(self: &Self, rhs: Self) -> Self

// etc.
```

These traits serve three purposes:

1. Explicit bounds when desired: `fn sum[T: Add](items: &[T])`
2. Documentation: "what methods does + need?"
3. Generic default implementations that need a bound

They are NOT checked by the compiler unless explicitly written
in a bound. Duck typing is the default.

---

## Implementation Note: Monomorphization Pipeline

### Note

Monomorphization happens in sema or between sema and MIR
lowering.

**When a generic function is called:**

1. Sema resolves the concrete type arguments (inferred or
   explicit).
2. Sema checks if this instantiation already exists. If so,
   reuse it.
3. If new: substitute type parameters with concrete types
   throughout the function body's AST.
4. Type-check the substituted body. If any operation fails on
   the concrete type, emit an error with both sites.
5. Store the instantiated AST for MIR lowering.
6. MIR lowering and codegen proceed as normal — the instantiated
   function is just a regular function with concrete types.

**Instantiation cache:**

Key: `(generic_fn_sym, type_arg_0, type_arg_1, ...)`
Value: instantiated function node

This prevents duplicate monomorphization. `triple[i32]` called
from three different sites generates one function, not three.

### Note: Lazy Instantiation

Generic functions are only instantiated when called. A generic
function that is never called produces no code and no errors:

```
fn broken[T](x: T): x.nonexistent_method()

// No call to broken[T] → no error, no code generated
```

This matches the lazy type resolution spec (§4.X). Don't analyze
what isn't used.

---

## Implementation Note: Error Recovery

### Note

When an instantiation fails type-checking, the compiler should:

1. Emit all errors for that instantiation.
2. Skip MIR lowering for that instantiation.
3. Continue compiling other functions and instantiations.
4. Report all errors at the end.

A single bad instantiation should not prevent the rest of the
program from being checked. This allows the developer to see
all errors at once, not one at a time.

---

## Implementation Note: Codegen

### Note

By the time codegen sees an instantiated function, it is a
normal function with concrete types. No generic handling is
needed in codegen. The monomorphization happened upstream.

MIR lowering receives the instantiated AST. MIR codegen receives
the lowered MIR. Neither knows or cares that the function was
originally generic.

This means: zero changes to MIR codegen for duck-typed generics.
All the work is in sema and MIR lowering.

---

## Implementation Note: Interaction With `--emit-c`

### Note

Each monomorphized function becomes a separate C function:

```c
// triple[i32]
int32_t triple_i32(int32_t x) { return x * 3; }

// triple[f64]
double triple_f64(double x) { return x * 3.0; }
```

Name mangling: `fn_name` + `_` + type names joined by `_`.
Keep mangled names deterministic and human-readable.

---

## Examples

```
// Simple arithmetic generics
fn double[T](x: T): x + x
fn square[T](x: T): x * x
fn clamp[T](x: T, lo: T, hi: T):
    if x < lo: lo
    else if x > hi: hi
    else: x

// Container generics
fn first[T](items: &[T]): items.get(0)
fn contains[T](items: &[T], target: T):
    for item in items:
        if item == target: return true
    false

// No bounds needed — compiler checks at instantiation
double(5)           // ok
double(3.14)        // ok
square("hi")        // error: str has no mul method

clamp(5, 0, 10)     // ok
clamp("b", "a", "z") // ok if str supports < and >

// Explicit bounds for public APIs
fn sum[T: Add](items: &[T], zero: T):
    var total = zero
    for item in items:
        total = total + item
    total

// Works without bounds too — just worse error messages
fn sum2[T](items: &[T], zero: T):
    var total = zero
    for item in items:
        total = total + item
    total
```