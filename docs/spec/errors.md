# 10. Error Handling

### 10.1 Result and Option

```
enum Result[T, E] { Ok(T) | Err(E) }
enum Option[T] { None | Some(T) }
```

No exceptions. Errors are values.

Discarding a `Result` or `Option` has no side effect. The compiler
does not require ceremony such as `let _ = expr` merely to acknowledge
that discard. Propagate, match, or bind the value when handling it
matters; otherwise an expression statement is already an explicit
choice to ignore the value:

```
// OK: the result is intentionally ignored
db.execute("DROP TABLE users")

// Also OK: handle or propagate when the error matters
db.execute("DROP TABLE users")?                    // propagate
db.execute("DROP TABLE users").unwrap_or(())       // handle
```

This keeps discard semantics honest: `Result` and `Option` do not
start background work or acquire resources merely by existing. Use
`let _ = expr` when that local style is useful, but it is not required.

### 10.2 The `?` Operator

`?` on `Result` propagates `Err` by early return. On `Option`,
propagates `None`.

```
fn load_config(path: &str) -> Result[Config, AppError]:
    let text = read_file(path)?           // propagates IoError
    let config = parse_toml(text)?        // propagates ParseError
    Ok(config)
```

The `?` operator is controlled by the `Try` syntax trait (§11.7).
`Result` and `Option` implement `Try` in the standard library. User
types can also implement `Try` to participate in `?` propagation —
for example, parser result types or validation types. `Try.branch`
decides whether evaluation continues, and `Try.from_break` rebuilds
the enclosing return carrier for the early-return path.

### 10.3 Optional Chaining (`?.`)

The `?.` operator accesses a field or method on an `Option` or
`Result`, returning `None`/`Err` if the value is absent:

```
// Without optional chaining
let city = user.address.and_then(a => a.city)

// With optional chaining
let city = user.address?.city

// Chains naturally
let zip = user.address?.city?.zip_code
```

**Desugaring:** The desugaring is **type-aware** to avoid producing
`Option[Option[T]]`:

- If `field` has type `U` (non-Optional): `expr?.field` → `expr.map(v => v.field)` — result is `Option[U]`.
- If `field` has type `Option[U]`: `expr?.field` → `expr.and_then(v => v.field)` — result is `Option[U]` (flattened).
- `expr?.method(args)` → `expr.and_then(v => v.method(args))` when the method returns `Option`/`Result`.

The desugar describes the result's shape, not a move of the base. A chain
on a named place reads the place, as any place read does (§3.8, D22): the
result of `expr?.field` is `Option[&U]`, a view into the base, so the base
stays intact and usable; an owned demand on that view (`let city:
Option[str] = profile.address?.city`) copies a `Copy` payload and, for a
non-`Copy` payload, is refused with the clone fix-it. A chain on a
temporary (`f()?.field`) yields the owned `Option[U]` (D74; D73 is the same
rule for assignment).

```
type Address { city: Option[str], zip: str }
type Profile { address: Option[Address] }

let zip = profile.address?.zip     // map: Option[str]
let city = profile.address?.city   // and_then: Option[str] (not Option[Option[str]])
let len = profile.address?.city?.len()  // chains correctly
```

Optional chaining works on both `Option[T]` and `Result[T, E]`:

```
// On Option
let name: Option[str] = user?.name

// On Result — preserves the error type
let body: Result[str, ApiError] = response?.body
```

### 10.4 Default Operator (`??`)

The `??` operator provides a default value when an `Option` is
`None`:

```
let port = config.get("port") ?? 8080
let name = user.display_name ?? user.username ?? "anonymous"
```

`expr ?? default` evaluates `expr` once and is semantically equivalent to:

```
match expr:
    Some(value) => value
    None => default
```

The right-hand side is lazily evaluated. The result type is the §3.8 join of
the payload expression and the default expression. Consequently:

- `Option[&T] ?? &T` remains `&T` and unions the possible view origins.
- `Option[&T] ?? T` produces `T` when `T: Copy`, because the owned default
  establishes an owned join.
- `Option[&T] ?? T` is a type error for non-`Copy` `T` unless an explicit
  owning conversion is supplied.

**Early exit form:** `??` can be followed by `return`, `break`, or
`continue` for early exit on `None`. The `break` and `continue`
forms may include labels (§13.5a):

```
let user = find_user(id) ?? return Err(.NotFound)
let item = stack.pop() ?? break
let next = iter.next() ?? continue
let token = lexer.peek() ?? break 'scan
```

This replaces the need for `if let` / `let-else` in the most common
cases. The desugaring is:

```
// user = find_user(id) ?? return Err(.NotFound)
// desugars to:
let user = match find_user(id):
    Some(v) => v
    None => return Err(.NotFound)
```

Early-exit forms use the same successful-payload rule; a diverging fallback
contributes no result type.

### 10.5 Option Combinators (Standard Library Requirement)

The standard library must provide these methods on `Option[T]`:

| Method | Signature | Description |
|--------|-----------|-------------|
| `map` | `(fn(T) -> U) -> Option[U]` | Transform the inner value |
| `and_then` | `(fn(T) -> Option[U]) -> Option[U]` | Chain fallible operations |
| `or_else` | `(fn() -> Option[T]) -> Option[T]` | Fallback provider |
| `unwrap_or[U]` | `(U) -> Join[T, U]` | Lazy branch selection; result uses §3.8 join |
| `unwrap_or_else[U]` | `(fn() -> U) -> Join[T, U]` | Lazy fallback; result uses §3.8 join |
| `unwrap` | `() -> T` | Extract value; **panics** if `None` |
| `expect` | `(msg: &str) -> T` | Extract value; **panics** with message if `None` |
| `filter` | `(fn(&T) -> bool) -> Option[T]` | Keep if predicate holds |
| `is_some` | `() -> bool` | Check presence |
| `is_none` | `() -> bool` | Check absence |
| `zip` | `(Option[U]) -> Option[(T, U)]` | Combine two options |
| `unzip` | `() -> (Option[A], Option[B])` | Split paired option |
| `flatten` | `() -> Option[T]` where Self = `Option[Option[T]]` | Remove nesting |
| `copied` | `() -> Option[T]` where Self = `Option[&T]`, T: Copy | Copy a borrowed payload into an independent value |
| `cloned` | `() -> Option[T]` where Self = `Option[&T]`, T: Clone | Clone a borrowed payload into an independent value |
| `inspect` | `(fn(&T)) -> Option[T]` | Side effect without consuming |
| `transpose` | `() -> Result[Option[T], E]` where Self = `Option[Result[T, E]]` | Swap Option/Result nesting |

`Join[T, U]` is specification metavocabulary, not user-facing type syntax. It
means the contextual join defined by §3.8. `unwrap`, `expect`, `?`,
`Some(value)` patterns, and `Ok(value)` patterns preserve the exact payload
type. In particular, eliminating `Option[&T]` without an independently
established owned demand produces `&T`, never conditionally `T`.

`copied` and `cloned` are ownership boundaries. Their successful results
carry no view origin from the source reference. D22 standardizes these
`Option` forms; corresponding iterator and `Result` conveniences remain
separate standard-library requirements.

**Examples:**
```
// Without combinators:
let name = match find_user(id):
    Some(user) => match user.display_name:
        Some(n) => n
        None    => user.username
    None => "anonymous"

// With combinators:
let name = find_user(id)
    .and_then(u => u.display_name.or_else(() => Some(u.username)))
    .unwrap_or("anonymous")
```

### 10.6 Result Combinators (Standard Library Requirement)

| Method | Signature | Description |
|--------|-----------|-------------|
| `map` | `(fn(T) -> U) -> Result[U, E]` | Transform Ok value |
| `map_err` | `(fn(E) -> F) -> Result[T, F]` | Transform Err value |
| `and_then` | `(fn(T) -> Result[U, E]) -> Result[U, E]` | Chain operations |
| `or_else` | `(fn(E) -> Result[T, F]) -> Result[T, F]` | Recover from error |
| `unwrap_or[U]` | `(U) -> Join[T, U]` | Lazy branch selection; result uses §3.8 join |
| `unwrap_or_else[U]` | `(fn(E) -> U) -> Join[T, U]` | Lazy fallback; result uses §3.8 join |
| `unwrap` | `() -> T` | Extract value; **panics** if `Err` |
| `expect` | `(msg: &str) -> T` | Extract value; **panics** with message if `Err` |
| `is_ok` | `() -> bool` | Check success |
| `is_err` | `() -> bool` | Check failure |
| `ok` | `() -> Option[T]` | Convert to Option |
| `err` | `() -> Option[E]` | Extract error |
| `inspect` | `(fn(&T)) -> Result[T, E]` | Side effect on Ok |
| `inspect_err` | `(fn(&E)) -> Result[T, E]` | Side effect on Err |
| `transpose` | `() -> Option[Result[T, E]]` where Self = `Result[Option[T], E]` | Swap Result/Option nesting |
| `context` | `(msg: &str) -> Result[T, ContextError[E]]` | Wrap error with message |
| `with_context` | `(fn() -> str) -> Result[T, ContextError[E]]` | Wrap error lazily |

**`.unwrap()` and `.expect()`:**

Both `Option` and `Result` provide `.unwrap()` and `.expect()` for
extracting the inner value with a panic on failure:

```
// .unwrap() — panics with a generic message
let user = find_user(id).unwrap()
let data = fetch(url).await.unwrap()

// .expect() — panics with a custom message
let user = find_user(id).expect("user must exist in test setup")
let config = load_config().expect("config file is required")
```

`.unwrap()` panics with a message that includes the source location
and the `Debug` representation of the `None`/`Err` value. `.expect()`
panics with the provided message plus the same debug info.

These are intended for tests, prototyping, and cases where failure
is a genuine bug (not a recoverable error). Production code should
prefer `?`, `match`, `unwrap_or`, or `??`.

**Error context:**

`.context()` wraps an error with a human-readable message,
producing a `ContextError[E]` that preserves the original error as
a `source` field. This chains naturally with `?`:

```
fn load_config(path: &str) -> Result[Config, AppError]:
    let text = fs.read_to_string(path)
        .context("failed to read config file")?
    let config = toml.parse(text)
        .context("failed to parse config")?
    Ok(config)

// Error output:
//   failed to read config file
//   caused by: IoError: No such file or directory (os error 2)
```

`.with_context()` evaluates the message lazily (only on error),
useful when building the message is expensive:

```
let user = db.find_user(id)
    .with_context(() => "failed to find user {id}")?
```

`ContextError[E]` implements `Error` when `E: Error`, and the
error chain is traversable via the `source` field:

```
type ContextError[E] {
    message: str,
    source: E,
}

impl Error for ContextError[E] where E: Error:
    fn display(self: &Self) -> str: self.message
    fn source(self: &Self) -> Option[&dyn Error]: Some(&self.source)
```

**Examples:**
```
let config = read_file(path)
    .map_err(e => AppError.Io(e))
    .and_then(text => parse_config(text))
    .unwrap_or_else(_ => Config.default())
```

### 10.7 Collection Combinators: `sequence` and `traverse`

These bridge collections and Option/Result. They are among the most
frequently used combinators in functional programming and are required
in the standard library.

**`sequence`** converts a collection of wrappers into a wrapper of
a collection. If any element is `None` or `Err`, the whole result is:

```
// List[Option[T]] → Option[List[T]]
let inputs: List[Option[i32]] = [Some(1), Some(2), Some(3)]
let result = inputs.sequence()       // Some([1, 2, 3])

let bad: List[Option[i32]] = [Some(1), None, Some(3)]
let result = bad.sequence()          // None

// List[Result[T, E]] → Result[List[T], E]
let results: List[Result[i32, str]] = [Ok(1), Ok(2), Ok(3)]
let all = results.sequence()         // Ok([1, 2, 3])

let mixed: List[Result[i32, str]] = [Ok(1), Err("bad"), Ok(3)]
let all = mixed.sequence()           // Err("bad")
```

**`traverse`** maps a function over a collection, then sequences.
It is `map` + `sequence` fused into one pass:

```
// Apply a fallible function to each element, collect successes
// or fail on first error
let names = ["1", "2", "three"]
let parsed = names.traverse(s => s.parse_int())
// Err(ParseError) — "three" fails

let names = ["1", "2", "3"]
let parsed = names.traverse(s => s.parse_int())
// Ok([1, 2, 3])
```

`traverse` is the workhorse of "apply a fallible operation to every
element and bail on first failure" — extremely common in validation,
parsing, and batch processing.

### 10.8 Error Declarations

```
error ParseError =
    UnexpectedChar(pos: usize, got: u8)
    UnexpectedEof
    InvalidNumber(pos: usize)
```

Automatically implements `Error`, `Debug`, `Display`.

### 10.9 Error Conversion with `from`

```
error AppError from IoError, ParseError, DbError
```

Generates wrapper variants (`AppError.Io(IoError)`, etc.) and `From`
implementations. `?` uses `From` for automatic conversion. Chained
conversion works via transitivity.

An `error` declaration may list both: `error E from A, B =` followed by
variants. A written variant whose name equals a generated wrapper's name
is a compile-time error.

---
