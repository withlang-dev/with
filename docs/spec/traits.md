# 11. Traits

### 11.1 Definition and Implementation

```
trait Show:
    fn show(self: &Self) -> String

impl Show for Point:
    fn show(self: &Point) -> String: "({self.x}, {self.y})"
```

### 11.2 Generic Bounds

Generic type parameters may omit bounds entirely. Unbounded generics
are checked when they are instantiated with concrete types:

```
fn double[T](x: T): x + x
```

If `double(5)` is instantiated, the compiler checks that `i32`
supports `+`. If `double("hi")` is instantiated and the concrete
type does not support the required operator or method, the compiler
emits an error naming the concrete type, the unsupported operation,
and the instantiation:

```
error: unsupported operator '+' for type 'str' in instantiation of 'double__str'
```

If a generic function is never called, its body is never compiled and
no errors are reported — even if the body contains invalid operations.

Explicit bounds remain available as optional contracts:

```
fn debug[T: Show + Hash](x: &T):
    print(f"{x.show()} (hash: {x.hash()})")
```

Use bounds when they improve the public API contract or produce
clearer caller-facing errors. Omit them when the body already makes
the requirement obvious.

### 11.2a `where` Clauses

Trait bounds may also be specified with `where` clauses, placed after the
function signature, type definition, or impl header:

```
fn display[T](x: T) where T: Printable:
    print(x.to_string())

fn multi[T](x: T) where T: Show, T: Hash:
    print(f"{x.show()} (hash: {x.hash()})")
```

`where` clauses are equivalent to inline bounds (`T: Trait` in the generic
parameter list) when present, but neither form is required. Generic
functions and types may omit both inline bounds and `where` clauses
and rely on instantiation-time checking instead. When bounds are
written, `where` clauses scale better when there are many constraints:

```
fn merge[A, B, C](a: A, b: B) -> C
    where A: Serialize, B: Serialize, C: Deserialize + Default:
    ...
```

`where` clauses may appear on functions, type declarations, and impl blocks:

```
type Wrapper[T] where T: Eq = { inner: T }

impl Showable for Pair where Pair: Describable:
    fn show(self: &Self) -> str: self.describe()
```

The compiler validates that each constraint references a known type parameter
and a known trait. Unknown type parameters or traits produce compile errors.

### 11.3 Static Dispatch by Default

Trait calls are monomorphized. Dynamic dispatch via explicit `dyn Trait`.

**Object safety:** A trait can be used as `dyn Trait` only if all
its methods are **object-safe**. A method is object-safe if:

1. It uses an explicit object-safe receiver mode: `self: &Self` or
   `mut self: Self`, OR
2. It uses `move self: Self` and the trait specifies `Self: Sized` —
   but `dyn Trait` is unsized, so consuming receiver methods are
   excluded from the vtable.

```
trait Drawable:
    fn draw(self: &Self)        // OK: &Self, object-safe
    fn name(self: &Self) -> str // OK: &Self, object-safe

trait Consumable:
    fn consume(move self: Self) // consuming receiver: NOT object-safe

let d: &dyn Drawable = &circle    // OK: all methods are object-safe
let c: &dyn Consumable = &item    // ERROR: consume() takes self by value
```

A parameter cannot take a bare `dyn Trait` by value. Use `&dyn Trait` to
borrow an object or `Box[dyn Trait]` to transfer ownership. Typed downcast
patterns over borrowed trait objects are defined in §9.7.

**Consuming `self` behind `Box`:** To call a consuming method through
a trait object, wrap it in `Box[dyn Trait]`. The compiler generates
a shim that moves the value out of the box (which has a known
pointer size):

```
trait Builder:
    fn build(move self: Self) -> Config // consuming receiver
    fn preview(self: &Self) -> str     // by-reference

// Box[dyn Builder] can call build() via a generated shim:
let b: Box[dyn Builder] = Box.new(MyBuilder { ... })
let cfg = b.build()    // moves value out of box, calls build
```

Traits with generic methods (where the generic is not `Self`) are
not object-safe, because the vtable cannot contain entries for all
possible monomorphizations.

### 11.4 Coherence (Orphan Rules)

A trait implementation is permitted only if the trait or the type is
defined in the current package. This ensures global coherence.

**Extension block coherence:** `extend` blocks (§9.5) follow similar
rules to prevent method conflicts across packages:

- You may `extend` any type with new methods.
- If two packages in scope extend the same type with the same method
  name, calling that method is a **compile error** (ambiguous). The
  caller must disambiguate using the fully-qualified syntax:
  `pkg_a.method_name(value)`.
- Extension methods **never shadow** inherent methods (defined in the
  same module as the type). Inherent methods always win.
- Extension methods are resolved by import: only methods from
  packages in the current `use` scope are candidates.

```
// In package `slug`:
extend String:
    fn to_slug(self: &Self) -> String: ...

// In package `url`:
extend String:
    fn to_slug(self: &Self) -> String: ...

// In user code:
use slug
use url
let s = "hello".to_owned()
s.to_slug()               // ERROR: ambiguous — slug::to_slug or url::to_slug?
slug.to_slug(&s)          // OK: fully qualified
```

### 11.5 Async Methods in Traits

Async methods in traits are permitted and require no special rules.

```
trait DataSource:
    async fn fetch(self: &Self, id: i32) -> Result[Data, Error]
```

Because `async fn fetch(...) -> T` is equivalent to
`fn fetch(...) -> Task[T]`, the trait signature is simply a method
returning `Task[T]`. No boxing, no GATs, no special async trait
machinery.

**Trait objects with async methods:**

```
let svc: &dyn DataSource = &remote_db
let task = svc.fetch(42)     // dynamic dispatch, returns Task[Data]
let data = task.await
```

This works because:

1. `Task[T]` is a concrete, fixed-size type (an opaque handle).
2. The vtable entry for `fetch` returns `Task[T]` like any other
   return value.
3. No boxing of the return value is needed — `Task[T]` is already
   a handle to a heap-allocated fiber.

**Formal rule:** Async methods are methods returning `Task[T]`. No
special trait rules, object safety constraints, or dynamic dispatch
restrictions apply beyond those that apply to any method returning a
concrete type.

### 11.6 Feature Scope (v1.0)

Supported: generic type parameters, optional bounds, multiple bounds,
default methods, async methods in traits, `where` clauses, blanket impls,
associated types (basic), sealed traits.

Not supported in v1.0: `Self` type in associated type references,
associated type bound checking, higher-kinded types, lifetime
parameters on traits.

**Associated types (basic):** Traits can declare associated types and impls
can provide concrete bindings:

```
trait Container:
    type Item

impl Container for IntVec:
    type Item = i32
```

Default associated types are supported (`type Item = i32` in the trait).
Missing required associated types produce a compile error. `Self.Item`
references in type expressions and associated type bound checking
(`type Item: Eq`) are deferred.

**Sealed traits:** The `@[sealed]` attribute restricts a trait so that only
the defining module can implement it:

```
@[sealed]
trait Node:
    fn eval(self: &Self) -> i32

impl Node for Literal: ...    // OK: same module
impl Node for BinOp: ...      // OK: same module
// impl Node for External: ... // ERROR: cannot implement sealed trait
```

Sealed traits guarantee a closed set of implementors, enabling optimizations
and exhaustive reasoning. Implementors outside the defining module produce
a compile error.

**Blanket impls:** A blanket impl provides a trait implementation for all types
satisfying a bound:

```
impl[T: Display] Printable for T:
    fn print(self: &Self): print(self.display())
```

The compiler checks for overlaps between blanket and direct impls to prevent
ambiguity.

### 11.7 Syntax Traits

Certain traits, when implemented, unlock participation in language
syntax. This is a deliberate design pattern: library types opt into
language constructs by implementing a known trait. The set of syntax
traits is **fixed and closed** — users cannot define new syntax hooks.
Arithmetic operators are the main exception: they use fixed method names
on the concrete type (`add`, `sub`, `mul`, `div`, `matmul`, `neg`).
Comparison is one primitive per family: `Eq.eq(self: &Self, other: &Self)
-> bool` backs `==` and `!=`, and `Ord.cmp(self: &Self, other: &Self) ->
i32` backs `<`, `<=`, `>`, and `>=` (negative, zero, or positive as the
receiver orders before, with, or after `other`). A type may additionally
define the fixed-name methods `ne`, `lt`, `le`, `gt`, `ge` as overrides;
when present, the override is selected for its operator. Both operands are
observed, never consumed: `a < b` compares the values `a` and `b` name,
whether they are owned or views, and a view of a type with neither
primitive is a compile error, never an address comparison — only raw
pointers order by address (§16). The prelude traits `Add`, `Sub`, `Mul`,
`Div`, `MatMul`, `Neg`, `Eq`, and `Ord` remain available for explicit
bounds and documentation, but an unbounded generic does not need to name
them.

| Trait | Unlocks | Syntax |
|-------|---------|--------|
| `Iter[T]` | `for` loops | `for x in expr:` |
| `Contains[T]` | Membership test | `x in collection`, `x not in collection` |
| `IndexGet[I, O]` | Subscript read | `expr[index]` |
| `IndexPlace[I, O]` | Subscript read/write (place) | `expr[index] = val` |
| `MultiIndex[O]` | Generalized subscript read | `expr[i, j]`, `expr[1:4, :, ...]` |
| `MultiIndexMut[V]` | Generalized subscript write | `expr[i, j] = val`, `expr[:, 0] = val` |
| `Try[T, E]` | `?` operator | `expr?` |
| `Drop` | Destructor | automatic at scope exit |

**Element access observes; `remove` transfers (D27).** A subscript read
`xs[i]` on a collection denotes the element *place*: reading it yields a
view (`&T`) of collection-owned storage, and writing through it (when the
base place is mutable) mutates the element via `IndexPlace`, including
receiver chains such as `xs[i].tags.push(v)`. A positional collection
has one spelling for element access, `xs[i]`; it has no positional `get`
(D71). Out-of-range positional access panics — for positional access,
absence is a bug, not a value, so no `Option` appears. (Keyed maps differ:
absence is normal there, so `get` returns `Option[&V]` per D22.) The
ownership-transfer operation is `remove(i) -> T`.

An element view follows the contextual rules of §3.8 and D22: when
`T: Copy`, an owned-value demand materializes an independent copy; when
`T` is not `Copy`, an owned demand is rejected (D22 §13.6) — borrow the
element, clone it, or remove it from the collection. These semantics are
uniform across `Vec`, fixed arrays, slices, and user types implementing
`IndexGet`/`IndexPlace`.

**Examples:**

```
// A matrix type that supports m[row, col] syntax
type Matrix { data: Vec[f64], rows: usize, cols: usize }

impl Index[(usize, usize), f64] for Matrix:
    fn index(self: &Self, (r, c): (usize, usize)) -> &f64:
        &self.data[r * self.cols + c]

let m = Matrix.new(3, 3)
let val = m[(1, 2)]    // calls Matrix::index
```

**Generalized indexing:**

The `[]` syntax also supports comma-separated multi-dimensional
indices, slice notation, ellipsis, and `newaxis`:

```
let pixel = image[10, 20, 0]
let rows = image[2:5, :]
let flipped = image[::-1]
let channel0 = image[..., 0]
let batched = image[newaxis, :]
image[2:5, :] = 0.0
```

The compiler evaluates each component left-to-right and lowers the
list into a standard sequence of `IndexSpec` values with four forms:
scalar, slice, ellipsis, and new-axis insertion. `...` may appear at
most once in a single index list. The meaning of those specs is owned
by the receiving type's `MultiIndex` / `MultiIndexMut`
implementation. Standard library tensor and array-view types interpret
negative scalar indices and slice bounds relative to the end of the
indexed dimension.

The standard library exposes `IndexSpec` as the carrier for those
components:

```
IndexSpec.Scalar(expr)
IndexSpec.Slice(start?, stop?, step?)
IndexSpec.Ellipsis
IndexSpec.NewAxis
```

```
// A parser result that supports ? propagation
enum ParseResult[T]:
    ParseOk(T, remaining: str)
    ParseErr(msg: str, pos: usize)

impl Try[T, ParseError] for ParseResult[T]:
    fn branch(move self: Self) -> ControlFlow[ParseError, T]:
        match self:
            ParseOk(v, _) => ControlFlow.Continue(v)
            ParseErr(m, p) => ControlFlow.Break(ParseError { msg: m, pos: p })
    fn from_break(err: ParseError) -> Self:
        ParseErr(err.msg, err.pos)

// Now ? works naturally in parser combinators:
fn parse_pair(input: &str) -> ParseResult[(Expr, Expr)]:
    let left = parse_expr(input)?
    let right = parse_expr(left.remaining)?
    ParseOk((left.value, right.value), right.remaining)
```

**Design constraints:**

1. The set of syntax traits is defined by the language. Users cannot
   add new syntax hooks.
2. Resolution is always static. No implicit conversions, no fallback
   chains, no dynamic dispatch (unless the user explicitly writes
   `dyn Trait`).
3. The compiler knows at compile time exactly which trait
   implementation or concrete method resolution controls each
   syntactic form.
4. Pattern matching extensibility (Scala-style `unapply`) is **not
   included** in v1.0. It introduces hidden runtime behavior into
   match resolution and conflicts with exhaustiveness checking. This
   may be revisited in a future version.

**Arithmetic and comparison operator methods:**

Arithmetic operators use fixed method names on the concrete type:

| Operator | Method |
|----------|--------|
| `+` | `add` |
| `-` | `sub` |
| `*` | `mul` |
| `/` | `div` |
| `@` | `matmul` |
| unary `-` | `neg` |

Comparison operators derive from one primitive per family; a fixed-name
method, when defined, overrides the derivation for its operator:

| Operator | Derived from | Override |
|----------|--------------|----------|
| `==` | `eq(&other)` | — |
| `!=` | `not eq(&other)` | `ne` |
| `<` | `cmp(&other) < 0` | `lt` |
| `<=` | `cmp(&other) <= 0` | `le` |
| `>` | `cmp(&other) > 0` | `gt` |
| `>=` | `cmp(&other) >= 0` | `ge` |

```
trait Eq:
    fn eq(self: &Self, other: &Self) -> bool

trait Ord:
    fn cmp(self: &Self, other: &Self) -> i32
```

The prelude also defines optional traits with matching names and
signatures for the arithmetic operators, for explicit bounds and
documentation:

```
trait Add[Rhs, Output]:
    fn add(self: Self, rhs: Rhs) -> Output

trait Sub[Rhs, Output]:
    fn sub(self: Self, rhs: Rhs) -> Output
trait Mul[Rhs, Output]:
    fn mul(self: Self, rhs: Rhs) -> Output
trait Div[Rhs, Output]:
    fn div(self: Self, rhs: Rhs) -> Output
trait MatMul[Rhs, Output]:
    fn matmul(self: Self, rhs: Rhs) -> Output
trait Neg[Output]:
    fn neg(self: Self) -> Output

enum ControlFlow[B, C]:
    Continue(C)
    Break(B)

trait Try[T, E]:
    fn branch(move self: Self) -> ControlFlow[E, T]
    fn from_break(value: E) -> Self
```

**The `Contains` trait:**

```
trait Contains[T]:
    fn contains(self: &Self, value: &T) -> bool
```

`x in collection` desugars to `collection.contains(&x)`.
`x not in collection` desugars to `not collection.contains(&x)`.

Standard library implementations:

| Type | `Contains[T]` for | Semantics |
|------|-------------------|-----------|
| `[T; N]` (array) | `T` where `T: Eq` | Linear scan |
| `[]T` (slice) | `T` where `T: Eq` | Linear scan |
| `Vec[T]` | `T` where `T: Eq` | Linear scan |
| `HashSet[T]` | `T` where `T: Hash + Eq` | O(1) lookup |
| `HashMap[K, V]` | `K` where `K: Hash + Eq` | Key existence |
| `BTreeSet[T]` | `T` where `T: Ord` | O(log n) lookup |
| `BTreeMap[K, V]` | `K` where `K: Ord` | Key existence |
| `Range[T]` (`a..b`) | `T` where `T: Ord` | `a <= x and x < b` |
| `RangeInclusive[T]` (`a..=b`) | `T` where `T: Ord` | `a <= x and x <= b` |
| `str` | `str` | Substring search |
| `str` | `char` | Character search |
| `String` | `str` | Substring search |
| `String` | `char` | Character search |

Maps test **key** containment, not value. This is consistent with
`for (k, v) in map` iterating keys. To test value containment:
`value in map.values()`.

User types can implement `Contains`:

```
type Whitelist { allowed: HashSet[str] }

impl Contains[str] for Whitelist:
    fn contains(self: &Self, value: &str) -> bool:
        value in self.allowed

if user.name in whitelist:
    grant_access()
```

**Operator desugaring:** For user-defined types, operator resolution
searches the full `(lhs_type, rhs_type)` pair:

1. Try an implementation whose `Self` is the left operand type and
   whose right-hand-side parameter matches the right operand type.
2. If none exists, try an implementation whose `Self` is the right
   operand type and whose right-hand-side parameter matches the left
   operand type.
3. Exactly one implementation must match. If both sides provide
   distinct applicable implementations, the expression is ambiguous
   and rejected.

The selected operation then desugars to a method call with
auto-referencing:

```
a + b      →  Add.add(&a, &b)       // left-side dispatch
1.0 + arr  →  Add.add(&arr, &1.0)   // right-side dispatch
a @ b      →  MatMul.matmul(&a, &b)
-a         →  Neg.neg(&a)
a == b     →  Eq.eq(&a, &b)
```

When right-side dispatch is selected, the implementation still
represents the original source expression order. An implementation of
`Sub[f64, Array] for Array` therefore defines `f64 - Array`, not
`Array - f64`.

**Operator traits should take `&Self`, not `Self`.** If `add` takes
`Self` by value, then `a + b` moves both operands and `a + b + c`
fails because `a` was consumed. With auto-referencing, the pattern
is:

```
impl Add for Vector:
    fn add(self: &Self, rhs: &Self) -> Self:
        Vector { x: self.x + rhs.x, y: self.y + rhs.y }

let d = a + b + c   // works: a, b, c are borrowed, not moved
```

For primitive types (`i32`, `f64`, etc.), operators are built-in
and do not go through trait dispatch.

### 11.8 Derive

`@[derive(...)]` generates trait implementations based on a type's
structure. The following traits may be derived:

| Trait | Condition | Behavior |
|-------|-----------|----------|
| `Copy` | Explicit opt-in only; all fields are `Copy`, no `Drop` | Bitwise copy |
| `Clone` | All fields are `Clone` | Field-by-field clone |
| `Default` | All fields are `Default` | Field-by-field default |
| `Eq` | All fields are `Eq` | Field-by-field equality |
| `Hash` | All fields are `Hash` | Hash all fields in order |
| `Ord` | All fields are `Ord` | Lexicographic comparison |
| `Debug` | Always | "{TypeName} { field: value, ... }" |
| `Display` | Always (enums) | Variant name as string |

```
@[derive(Eq, Hash, Debug, Clone)]
type Point { x: f64, y: f64 }

@[derive(Eq, Debug)]
enum Role { Admin | Member | Guest }
```

**`@[derive(all)]`** derives every eligible trait the type
qualifies for:

```
@[derive(all)]
type Color { r: u8, g: u8, b: u8, a: u8 }
// Derives: Clone, Default, Eq, Hash, Ord, Debug
// (NOT Copy — aggregate types require explicit Copy opt-in)

@[derive(all)]
type User { name: str, email: str, age: i32 }
// Derives: Clone, Default, Eq, Hash, Debug
// (NOT Copy — aggregate types require explicit Copy opt-in)
// (NOT Ord — not all fields implement Ord by default)
```

Aggregate types (`type`, anonymous records, and `enum`) are
**non-`Copy` by default**, even when all fields are `Copy`.
`Copy` is part of the type's API surface and must be opted into
explicitly with `impl Copy for T` or equivalent declaration syntax
such as `type Pair: Copy { ... }`.

`@[derive(all)]` is conservative — it only derives traits where all
fields satisfy the trait's requirements, and it never implicitly opts
an aggregate type into `Copy`. If a field is added that doesn't
implement `Eq`, the type silently loses its derived `Eq`. This is by
design — no compile error, because `@[derive(all)]` means "whatever
you can."

For explicit control, list traits individually. `@[derive(Eq, Hash)]`
will produce a compile error if a field doesn't implement `Eq` or
`Hash`.

`@[derive(...)]` is implemented via comptime (§17.3). User-defined
derive targets (e.g., `@[derive(Serialize)]`) are supported through
comptime functions.

**`@[derive(Builder)]`** generates a builder struct with chaining
methods for every field. This eliminates the most common source of
builder boilerplate:

```
@[derive(Builder)]
type DatabaseConfig {
    host: str,
    port: i32 = 5432,
    max_connections: i32 = 10,
    timeout: Duration = Duration.secs(30),
    ssl: bool = false,
}

// Generates:
// type DatabaseConfigBuilder {
//     host: Option[str], port: Option[i32], ...
// }
// impl DatabaseConfigBuilder:
//     fn host(self: Self, val: str) -> Self: ...
//     fn port(self: Self, val: i32) -> Self: ...
//     fn build(self: Self) -> Result[DatabaseConfig, BuilderError]: ...
// impl DatabaseConfig:
//     fn builder -> DatabaseConfigBuilder: ...

// Usage:
let config = DatabaseConfig.builder()
    .host("localhost")
    .port(5433)
    .ssl(true)
    .build()?
```

Fields with default values are optional in the builder. Fields
without defaults are required — `.build()` returns an error if they
aren't set. This is checked at compile time when all `.field()`
calls are visible.

### 11.9 Debug Formatting (`:?`)

The `:?` format specifier in f-strings produces a programmer-facing
structural representation of a value. See §15.4.7 for full details.

```
type Point { x: i32, y: i32 }

let p = Point { x: 1, y: 2 }
print(f"{p:?}")    // prints "Point { x: 1, y: 2 }"
```

Debug formatting is generated inline by the compiler at compile time,
without runtime reflection. A type with an explicit `impl Debug` is
formatted by its `debug_str`, at top level and nested alike; every other
type uses the generated form (§15.4.7). For primitives, `:?` produces the
same output as default display, except that strings are quoted and
escaped.

---
