# Pre-Release Spec Additions and Implementation Notes

---

## §11.X Trait Coherence (Orphan Rules)

### Spec Language

A trait implementation is permitted only if at least one of the
following holds:

1. The implementing module defines the trait.
2. The implementing module defines the `Self` type.

This is the **orphan rule**. It prevents two independent modules
from providing conflicting implementations of the same trait for
the same type.

```
// OK: module defines the trait
trait Render:
    fn render(self: &Self) -> str

impl Render for i32:
    fn render(self: &i32) -> str: "{self}"

// OK: module defines the type
type Celsius = distinct f64

impl Display for Celsius:
    fn display(self: &Celsius) -> str: "{self.0}°C"

// ERROR E1101: orphan implementation
// Neither `Display` nor `Vec[i32]` is defined in this module.
impl Display for Vec[i32]:
    fn display(self: &Vec[i32]) -> str: ...
```

**Blanket implementations** are permitted when the implementing
module defines the trait:

```
// OK: this module defines Printable
trait Printable:
    fn to_str(self: &Self) -> str

// Blanket impl: any Display type is Printable
impl[T: Display] Printable for T:
    fn to_str(self: &T) -> str: self.display()
```

**Overlap rule:** Two trait implementations overlap if they could
apply to the same concrete type. Overlapping implementations are
a compile error, regardless of which module defines them.

```
// ERROR E1102: overlapping implementations
impl[T: Debug] Render for T: ...
impl Render for i32: ...
// Both apply to i32
```

**Rationale:** Without the orphan rule, adding a trait implementation
in any library is a potentially breaking change for every downstream
user. The orphan rule ensures that implementations are always
controlled by the author of the trait or the author of the type.

---

## §4.X Variance

### Spec Language

Generic type parameters have a **variance** that determines subtyping
relationships on the constructed type. Variance is inferred
automatically by the compiler from how the type parameter is used in
the type definition. The programmer does not annotate variance.

The three variances are:

| Variance | Rule | When |
|----------|------|------|
| **Covariant** | If `A` is subtype of `B`, then `F[A]` is subtype of `F[B]` | `T` appears only in output positions (return types, immutable fields) |
| **Contravariant** | If `A` is subtype of `B`, then `F[B]` is subtype of `F[A]` | `T` appears only in input positions (function parameter types) |
| **Invariant** | `F[A]` is never a subtype of `F[B]` | `T` appears in both input and output positions, or in a mutable position |

Inference rules:

- `T` in an immutable field (`field: T`): covariant.
- `T` in a mutable field (`field: mut T`): invariant.
- `T` behind a shared reference (`&T`): covariant.
- `T` behind a mutable reference (`&mut T`): invariant.
- `T` as a function parameter: contravariant.
- `T` as a function return type: covariant.
- Combined positions: the more restrictive variance applies.

```
// Covariant: T only in output position
type Producer[T] = { get: fn() -> T }

// Contravariant: T only in input position
type Consumer[T] = { accept: fn(T) -> Unit }

// Invariant: T in both positions (mutable container)
type Cell[T] = { value: mut T }

// Invariant: Vec has push (input) and get (output)
type Vec[T]  // invariant in T
```

The compiler computes variance per type parameter during type
definition analysis. Variance is not part of the surface syntax.
There is no `in` or `out` annotation.

---

## §14.X Send and Sync

### Spec Language

`Send` and `Sync` are **auto-traits**: the compiler automatically
derives them for any type whose contents satisfy the requirements.
The programmer does not write `impl Send for T`.

| Trait | Meaning | Auto-derived when |
|-------|---------|-------------------|
| `Send` | Value can be moved to another fiber/thread | All fields are `Send` |
| `Sync` | Value can be shared by `&T` across fibers/threads | All fields are `Sync` |

Primitive types (`i32`, `f64`, `bool`, `str`) are both `Send` and
`Sync`. Structs and enums are `Send`/`Sync` if all their fields are.

**Types that are NOT `Send`:**

- Any type containing a raw pointer obtained via `unsafe`.
- Any type explicitly marked `@[not_send]`.

**Types that are NOT `Sync`:**

- Any interior-mutable type without synchronization (e.g., `Cell[T]`).
- Any type explicitly marked `@[not_sync]`.

**Enforcement points:**

- `spawn expr`: all values captured by the spawned fiber must be
  `Send`. Compile error otherwise.

  ```
  let data = load()           // data: SomeType
  spawn process(data)         // OK only if SomeType: Send
  ```

- `async scope |s|`: values captured by tracked tasks need only be
  `ScopedSend`, not `Send`. `ScopedSend` permits ephemeral
  references because the scope guarantees task completion before
  the referenced data is dropped. (See §14.9.)

- Shared references (`&T`) across fiber boundaries: `T` must be
  `Sync`.

**Opting out:**

```
@[not_send]
type Handle = { raw: RawPtr }

// Compile error: Handle is not Send
spawn use_handle(handle)
```

**Opting in with `unsafe`:**

```
@[unsafe_send]
type SharedBuffer = { ptr: RawPtr, len: i32 }
// Programmer asserts thread safety manually
```

---

## §6.X Slice Patterns

### Spec Language

Pattern matching supports destructuring of slices and arrays with
the following pattern forms:

```
match items
    [] -> handle_empty()
    [only] -> handle_single(only)
    [first, second] -> handle_pair(first, second)
    [first, ..rest] -> handle_first_and_rest(first, rest)
    [..init, last] -> handle_last(init, last)
    [first, ..middle, last] -> handle_ends(first, middle, last)
    [_, _, third, ..] -> handle_third(third)
```

**Semantics:**

- `[]` matches a slice of length 0.
- `[a, b, c]` matches a slice of exactly length 3 and binds each
  element.
- `[first, ..rest]` matches a slice of length ≥ 1. `first` binds
  the first element. `rest` binds a slice of the remaining elements.
- `[..init, last]` matches a slice of length ≥ 1. `last` binds
  the last element. `init` binds a slice of all preceding elements.
- `[first, ..middle, last]` matches a slice of length ≥ 2. `first`
  and `last` bind the endpoints. `middle` binds the interior slice.
- `..` without a binding name (`[a, ..]`) matches remaining elements
  without binding them.
- `_` in element position matches any single element without binding.

**Nesting:** Slice patterns may appear inside struct, tuple, and
enum patterns and may contain nested patterns:

```
match data
    { users: [first, ..], status: .Active } ->
        greet(first)
    { users: [], .. } ->
        handle_no_users()
```

**Exhaustiveness:** The compiler checks slice pattern exhaustiveness.
A set of slice patterns is exhaustive if every possible length is
covered. `[..] -> ...` or `_ -> ...` covers all remaining lengths.

---

## §11.X Associated Types

### Spec Language

A trait may declare **associated types**: type members that each
implementor must define concretely. Associated types are declared
with `type Name` inside a trait body and referenced as `Self.Name`.

```
trait Iterator:
    type Item
    fn next(self: &mut Self) -> Option[Self.Item]
```

An implementation provides the concrete type:

```
extend Vec[T]:
    impl Iterator:
        type Item = T
        fn next(self: &mut Vec[T]) -> Option[T]: ...
```

**Usage in bounds:**

```
fn sum_all[I: Iterator](iter: &mut I) -> i32
    where I.Item: Add[i32]:
    ...
```

**Difference from generic parameters on traits:**

- `trait Foo[T]` means: a type can implement `Foo` multiple times
  with different `T`. The caller chooses `T`.
- `trait Foo` with `type Output` means: a type implements `Foo`
  exactly once. The implementor chooses `Output`.

```
// Generic param: multiple impls per type
trait From[T]:
    fn from(value: T) -> Self

impl From[i32] for f64: ...
impl From[str] for f64: ...

// Associated type: one impl per type
trait Iterator:
    type Item
    fn next(self: &mut Self) -> Option[Self.Item]

// Vec[i32] has exactly one Item: i32
```

**Associated types with bounds:**

```
trait Collection:
    type Item: Eq
    type Iter: Iterator where Iter.Item = Self.Item
    fn iter(self: &Self) -> Self.Iter
```

**Default associated types:**

```
trait Add:
    type Output = Self       // default: Output is Self
    fn add(self: Self, rhs: Self) -> Self.Output
```

Implementors may override the default or accept it.

---

## §11.X Sealed Traits

### Spec Language

A trait marked `@[sealed]` may only be implemented within the module
that defines it. Implementations in other modules are a compile error.

```
// In module parser/token.w:

@[sealed]
trait Token:
    fn span(self: &Self) -> Span
    fn kind(self: &Self) -> TokenKind

type Ident = { name: str, span: Span }
type Number = { value: f64, span: Span }
type StringLit = { value: str, span: Span }

impl Token for Ident: ...
impl Token for Number: ...
impl Token for StringLit: ...
```

```
// In another module:
use parser.token.Token

impl Token for MyType: ...
// ERROR E1201: `Token` is sealed and cannot be implemented
// outside of module `parser.token`
```

**Exhaustive matching:** Because the compiler knows all implementors
of a sealed trait at compile time, `match` on a sealed trait object
is exhaustive:

```
fn describe(tok: &dyn Token) -> str:
    match tok
        t: &Ident -> "identifier: {t.name}"
        t: &Number -> "number: {t.value}"
        t: &StringLit -> "string: {t.value}"
    // No wildcard needed — compiler knows this is exhaustive
```

Adding a new implementor to the sealed trait's module without
updating all match sites is a compile error.

---

## §6.X `where` Clauses

### Spec Language

`where` is a reserved keyword. Function and type declarations may
use a `where` clause to specify trait bounds separately from the
generic parameter list.

```
fn merge[T, U](a: U, b: U) -> Vec[T]
    where T: Ord + Hash,
          U: IntoIter[T]:
    ...
```

A `where` clause appears after the return type (or after the
parameter list if no return type) and before the `:` that introduces
the body.

**Permitted locations:**

- Function declarations
- Trait declarations
- Trait implementations
- Type declarations

```
type SortedMap[K, V]
    where K: Ord + Hash:
    entries: Vec[(K, V)]

trait Graph[N, E]
    where N: Eq + Hash,
          E: Weighted:
    fn nodes(self: &Self) -> Iter[N]
    fn edge_weight(self: &Self, from: N, to: N) -> Option[E.Weight]

impl[K, V] Display for SortedMap[K, V]
    where K: Display,
          V: Display:
    fn display(self: &SortedMap[K, V]) -> str: ...
```

**Equivalence:** Inline bounds and `where` clauses are equivalent.
`fn foo[T: Ord](x: T)` and `fn foo[T](x: T) where T: Ord` are
the same declaration. `where` is preferred when bounds are complex
or reference associated types.

**Associated type constraints in `where`:**

```
fn process[I](iter: I)
    where I: Iterator,
          I.Item: Display + Eq:
    ...
```

---

## Reserved Syntax: Const Generics

### Spec Language

The following syntax is reserved for future use. The compiler must
reject it with a clear error message indicating the feature is not
yet implemented. No other meaning may be assigned to this syntax.

```
// Reserved: const generic parameters
fn zeros[const N: i32]() -> Array[f32, N]: ...
type Matrix[const ROWS: i32, const COLS: i32] = { ... }

// Reserved: const in where clauses
fn safe_index[T, const N: i32](arr: Array[T, N], idx: i32) -> T
    where N > 0: ...
```

The keyword `const` inside `[...]` generic parameter lists is
reserved. An identifier followed by a type annotation inside generic
parameters, when preceded by `const`, is a const generic parameter.

This reservation enables future compile-time-checked array sizes,
matrix dimensions, and buffer capacities.

---

## Reserved Syntax: `move` Closures

### Spec Language

The following syntax is reserved for future use:

```
// Reserved: move closure
let f = move || process(data)
let f = move |x| x + captured_value
```

`move` before a closure (`||` or `|params|`) forces the closure to
take ownership of all captured variables by moving them into the
closure, regardless of whether the compiler would infer borrowing.

Until this feature is implemented, the compiler infers capture mode
(borrow vs move) from context. `spawn` and detached tasks
implicitly require move semantics. The `move` keyword provides an
explicit override when inference is insufficient.

---

## Implementation Note: Error Return Traces

### Note

In debug builds, the `?` operator should capture source location
(file, line, column) at the point where an error is propagated.
This trace is attached to the error value and can be retrieved for
diagnostic output.

Mechanism:

1. The `Result[T, E]` runtime representation in debug builds carries
   an optional trace buffer (a small Vec of source locations).
2. Each `?` application appends the current `src()` to the trace.
3. In release builds, trace capture is compiled out entirely.
   `Result[T, E]` has no trace field. Zero overhead.
4. `err.trace()` returns the captured propagation path:

   ```
   error: connection refused
     at src/db.w:42        (connect)
     at src/repo.w:18      (find_user)
     at src/handler.w:7    (get_dashboard)
   ```

Implementation priority: after fixpoint. This is a runtime library
and codegen concern, not a spec concern. The spec guarantees only
that `?` propagates errors and that debug/release behavior may
differ in diagnostic richness.

---

## Implementation Note: `embed_file`

### Note

Add a compiler intrinsic `embed_file(path: str) -> [u8]` that
includes the contents of a file as a compile-time constant byte
slice.

```
let schema = comptime embed_file("schema.sql")
let shader = comptime embed_file("shaders/vertex.glsl")
let cert = comptime embed_file("certs/root.pem")
```

Semantics:

- `path` is resolved relative to the source file containing the
  call.
- The file is read at compile time. The bytes are embedded in the
  binary as a static constant.
- The return type is `[u8]` (byte slice).
- File-not-found is a compile error with file and line.
- This is a `comptime`-only intrinsic. Calling it at runtime is
  a compile error.

Implementation: in the LLVM backend, emit the bytes as a global
constant. In the C backend, emit a `static const unsigned char[]`
array. In both cases, the data appears in the binary's read-only
data section.

---

## Implementation Note: `errdefer`

### Note

Add `errdefer` as a counterpart to `defer`. An `errdefer` block
executes only when the enclosing function returns an `Err` value
(or panics). On successful return, the block is skipped.

```
fn open_connection(path: str) -> Result[Connection, DbError]:
    let conn = connect(path)?
    errdefer conn.close()
    conn.execute("PRAGMA journal_mode=WAL")?
    conn.execute("PRAGMA foreign_keys=ON")?
    conn    // success: caller owns conn, errdefer does NOT run
```

Desugaring in MIR:

- `errdefer` is lowered to a drop/cleanup block that is only
  reached via error-return paths, not via normal-return paths.
- The MIR builder tracks `errdefer` entries separately from `defer`
  entries in the scope stack.
- On normal return: only `defer` blocks execute.
- On error return (`?` propagation or explicit `return Err(...)`):
  both `defer` and `errdefer` blocks execute, in LIFO order.
- On panic: both `defer` and `errdefer` execute (same as error).

Interaction with `defer`:

```
fn example() -> Result[Unit, Error]:
    let a = acquire_a()?
    defer release_a(a)           // always runs
    let b = acquire_b()?
    errdefer release_b(b)        // only on error
    let c = acquire_c()?
    errdefer release_c(c)        // only on error

    // Success: release_a runs. release_b and release_c do NOT.
    // Error at acquire_c: release_b, release_a run. (release_c was
    //   not yet registered.)
    // Error at acquire_b: release_a runs. (release_b not yet registered.)
```

This is a parser + MIR lowering change. Reserve the keyword `errdefer`
now. Implementation can follow after fixpoint but the keyword must
be reserved before release.

---

## Implementation Note: `src()` Default Source Location

### Note

Add a compiler intrinsic `src()` that evaluates to the source
location (file, line, column) of the call site. When used as a
default argument value, it captures the *caller's* location:

```
fn require(condition: bool, msg: str, loc: SourceLoc = comptime src()):
    if not condition:
        panic("requirement failed: {msg} at {loc.file}:{loc.line}")

fn check(condition: bool, msg: str, loc: SourceLoc = comptime src()):
    if not condition:
        panic("check failed: {msg} at {loc.file}:{loc.line}")
```

Usage:

```
fn process(count: i32):
    require(count > 0, "count must be positive")
    // If count <= 0, panic message shows THIS line, not
    // the line inside require()
```

`SourceLoc` is a compiler-provided type:

```
type SourceLoc = {
    file: str,
    line: i32,
    column: i32,
}
```

Implementation: `src()` is a comptime intrinsic. When used in a
default argument, the compiler substitutes the caller's source
location at each call site. This is the same mechanism Zig uses
with `@src()` and that C++ uses with `std::source_location::current()`.

Reserve the `src` intrinsic name now. Implementation can follow the
same comptime evaluation path as other intrinsics.

---

## Implementation Note: Closure Capture Inference

### Note

Verify that the compiler's closure capture rules are:

1. **Borrow by default.** If the closure does not outlive the
   captured variable's scope, capture by shared reference.

2. **Mutable borrow when mutated.** If the closure mutates a
   captured variable, capture by mutable reference.

3. **Move when required by lifetime.** If the closure is passed
   to `spawn`, stored in a data structure, or otherwise outlives
   the captured variable's scope, capture by move.

4. **Explicit `move` override.** (Reserved syntax, see above.)
   Forces all captures to move regardless of inference.

The compiler must emit a clear error when:

- A closure captures by borrow but is used in a context requiring
  `Send` (e.g., `spawn`). Error message should suggest `move`.
- A closure captures a non-`Copy`, non-`Send` value and is passed
  to `spawn`. Error should name the offending capture.

These rules should be documented in the spec under §8 (Closures)
and tested with fixtures covering each capture mode.

---

## Summary: Keywords and Syntax to Reserve Before Release

The following must be reserved keywords or syntax forms. They may
not be used as identifiers. The compiler should reject them with
"reserved for future use" if the feature is not yet implemented.

| Keyword/Syntax | Future Use |
|---|---|
| `where` | Complex trait bounds |
| `errdefer` | Error-path-only deferred cleanup |
| `move` (before closures) | Explicit move capture |
| `const` (in generic params) | Const generics |
| `sealed` | Attribute, already available via `@[sealed]` |
| `it` | Implicit closure parameter (already spec'd) |

Verify none of these are currently used as identifiers in
stdlib, tests, or example code.