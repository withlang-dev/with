# Idiomatic With

The principle: **if the compiler already knows it, don't type it.**

Every rule in this guide follows from that. With is designed so
that the shortest, cleanest version of the code is also the
correct version.

---

## Functions

**Drop the parens.** If a function takes no arguments, don't
write empty parentheses.

```
// ✗ verbose
fn greet():
    println("hello")

// ✓ idiomatic
fn greet:
    println("hello")
```

**Drop the return type when it's Unit.** If a function doesn't
return anything, don't annotate it.

```
// ✗ verbose
fn greet() -> Unit:
    println("hello")

// ✓ idiomatic
fn greet:
    println("hello")
```

**`fn main:` not `fn main -> i32:`.** A program that succeeds
shouldn't need to say so.

```
// ✗ C-brain
fn main -> i32:
    println("Hello, World!")
    0

// ✓ idiomatic
fn main:
    println("Hello, World!")
```

---

## Let the Compiler Infer Types

**Don't annotate what's obvious.** The compiler has
bidirectional type inference. Use it.

```
// ✗ over-annotated
let x: i32 = 42
let name: str = "Alice"
let items: Vec[i32] = Vec.new()
let found: bool = list.contains(x)

// ✓ idiomatic
let x = 42
let name = "Alice"
let items = Vec.new[i32]()
let found = list.contains(x)
```

**Do annotate when it helps the reader.** If the type isn't
obvious from the right-hand side, annotate it.

```
// ✓ annotation helps here — what does parse return?
let config: ServerConfig = parse(args)
```

---

## Don't Return What's Implied

**Don't write trailing `0`.** If a function returns a type
that implements `Default` and the last expression is a
statement, the compiler returns `T.default()`.

```
// ✗ boilerplate
fn setup_logging -> i32:
    init_logger()
    set_level("debug")
    0

// ✓ idiomatic — i32.default() is 0
fn setup_logging -> i32:
    init_logger()
    set_level("debug")
```

**Don't write `Ok(())`.** If a function returns `Result[Unit, E]`
and the body ends with a statement, the compiler wraps it.

```
// ✗ ceremony
fn save_all(items: &Vec[Item]) -> Result[Unit, DbError]:
    for item in items:
        db.insert(item)?
    Ok(())

// ✓ idiomatic — implicit Ok(())
fn save_all(items: &Vec[Item]) -> Result[Unit, DbError]:
    for item in items:
        db.insert(item)?
```

**Don't write `Ok(value)`.** The happy path just returns the
value. The compiler wraps it.

```
// ✗ wrapping manually
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    Ok(User.from_row(row))

// ✓ idiomatic — auto-wrapped in Ok
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    User.from_row(row)
```

**The rule:** `?` handles the sad path. The happy path just
returns the value.

---

## Use Enum Variant Shorthand

When the type is known from context, use `.Variant` instead
of the full `TypeName.Variant`.

```
// ✗ verbose
fn color_name(c: Color) -> str:
    match c
        Color.Red   -> "red"
        Color.Green -> "green"
        Color.Blue  -> "blue"

// ✓ idiomatic
fn color_name(c: Color) -> str:
    match c
        .Red   -> "red"
        .Green -> "green"
        .Blue  -> "blue"
```

Works everywhere the compiler can infer the enum type: match
arms, return positions, function arguments, let bindings with
type annotations.

```
// ✓ in return position
fn default_dir -> Direction: .North

// ✓ in function arguments
move_player(.North, 10.0)

// ✓ in error returns
if age < 0 then return Err(.InvalidAge)
```

---

## Use Field Shorthand

When variable names match field names, don't repeat yourself.

```
// ✗ repetitive
let user = User { name: name, email: email, active: active }

// ✓ idiomatic
let user = User { name, email, active }
```

Works in struct literals, patterns, and destructuring.

---

## Use Default Fields

Struct fields with defaults can be omitted at construction.

```
type ServerConfig = {
    host: str = "localhost",
    port: i32 = 8080,
    max_connections: i32 = 100,
}

// ✗ specifying defaults
let config = ServerConfig {
    host: "localhost",
    port: 8080,
    max_connections: 200,
}

// ✓ idiomatic — only specify what differs
let config = ServerConfig { max_connections: 200 }
```

---

## Use `then` for Guards

Single-expression conditionals use `then` for inline guards.
Don't inflate them into blocks.

```
// ✗ heavy
if not valid:
    return Err(.Invalid)

// ✓ idiomatic
if not valid then return Err(.Invalid)
```

This reads like English: "if not valid, then return error."

---

## Use `?` and `??`, Not Manual Matching

**`?` for propagation.** Don't manually match on Option/Result
when you just want to propagate the error.

```
// ✗ manual propagation
let user = match db.find_user(id)
    Ok(u)  -> u
    Err(e) -> return Err(e)

// ✓ idiomatic
let user = db.find_user(id)?
```

**`??` for defaults.** Don't match when you just want a
fallback.

```
// ✗ manual default
let name = match user.nickname
    Some(n) -> n
    None    -> "anonymous"

// ✓ idiomatic
let name = user.nickname ?? "anonymous"
```

**`?.` for optional chaining.** Navigate nested Options
without unwrapping each layer.

```
// ✗ nested matching
let city = match user.address
    Some(addr) -> match addr.city
        Some(c) -> Some(c)
        None    -> None
    None -> None

// ✓ idiomatic
let city = user.address?.city
```

---

## Use `let ... else` for Early Exit

When you need to unwrap or bail, `let ... else` reads cleanly.

```
// ✗ nested
match parse_config(path)
    Ok(config) ->
        // rest of function indented
    Err(e) ->
        return Err(e)

// ✓ idiomatic — flat
let config = parse_config(path) else |e|:
    return Err(e)
// rest of function at top level
```

Works with enum patterns:

```
let .Connected(socket) = state else:
    return Err(.NotConnected)
```

---

## Use Pipelines for Data Transformation

When data flows through a sequence of steps, use `|>` instead
of nested calls.

```
// ✗ nested — read inside-out
let result = summarize(transform(validate(parse(data))))

// ✓ idiomatic — read left-to-right
let result = data |> parse |> validate |> transform |> summarize
```

Pipelines compose with `?`:

```
let result = data
    |> parse?
    |> validate?
    |> transform
    |> summarize
```

**Use method chains for objects, pipelines for free functions.**

```
// ✓ methods — the value is the subject
let names = users.iter()
    .filter(|u| u.active)
    .map(|u| u.name)
    .collect[Vec]()

// ✓ pipeline — data flows through transformations
let report = raw_data
    |> parse_csv
    |> normalize
    |> aggregate_by_month
    |> render_chart
```

---

## Use `with` for Scoped Operations

### Builders

Don't write mutable-then-freeze manually. Use `with ... as mut`.

```
// ✗ manual builder pattern
var config = Config.default()
config.timeout = 30
config.retries = 3
config.verbose = true
let config = config   // freeze

// ✓ idiomatic — mutation is scoped
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3
    c.verbose = true
```

### Guarded access

Don't manually lock and unlock. `with` scopes it.

```
// ✗ manual lock management
let guard = lock.read()
let count = guard.data.len()
drop(guard)

// ✓ idiomatic — the type tells the compiler it's a guard
with lock.read() as data:
    data.len()
```

### Record update

Don't clone and mutate. Use `{ expr with field: val }`.

```
// ✗ clone and mutate
var new_config = config.clone()
new_config.timeout = 60

// ✓ idiomatic — functional update
let new_config = { config with timeout: 60 }
```

---

## Use `defer` for Cleanup

Don't write cleanup at every exit point. `defer` runs at scope
exit regardless of how you leave.

```
// ✗ fragile — cleanup at every return
fn process(path: str) -> Result[Unit, IoError]:
    let f = File.open(path)?
    if not f.is_valid():
        f.close()
        return Err(.Invalid)
    let data = f.read_all()?
    f.close()

// ✓ idiomatic — one defer, always runs
fn process(path: str) -> Result[Unit, IoError]:
    let f = File.open(path)?
    defer f.close()
    if not f.is_valid() then return Err(.Invalid)
    let data = f.read_all()?
```

---

## Pattern Matching

**Use `match`, not chains of `if/else if`.** When you're
dispatching on variants, `match` is exhaustive and the
compiler checks you covered everything.

```
// ✗ if-chains on enums
if status == .Ok:
    handle_success()
else if status == .NotFound:
    handle_404()
else if status == .ServerError:
    handle_500()

// ✓ idiomatic — compiler ensures exhaustiveness
match status
    .Ok          -> handle_success()
    .NotFound    -> handle_404()
    .ServerError -> handle_500()
```

**Destructure in the pattern.** Don't match then access.

```
// ✗ match then access
match result
    Ok(val) -> println("{val.name}: {val.score}")
    Err(e)  -> println("error: {e}")

// ✓ idiomatic — destructure deeper if it helps
match result
    Ok({ name, score }) -> println("{name}: {score}")
    Err(e)              -> println("error: {e}")
```

---

## String Interpolation

Don't concatenate. Interpolate.

```
// ✗ concatenation
let msg = "Hello, " ++ name ++ "! You have " ++ count.to_str() ++ " items."

// ✓ idiomatic
let msg = "Hello, {name}! You have {count} items."
```

---

## Ranges and Loops

**Use ranges.** Don't write C-style index manipulation.

```
// ✗ C-style
var i = 0
while i < 10:
    process(i)
    i += 1

// ✓ idiomatic
for i in 0..10:
    process(i)
```

**Use iterators.** Don't index when you can iterate.

```
// ✗ indexing
for i in 0..items.len():
    process(items[i])

// ✓ idiomatic
for item in items:
    process(item)
```

**Use comprehensions for transforms.**

```
// ✗ manual accumulation
var result = Vec.new[i32]()
for x in 0..10:
    result.push(x * x)

// ✓ idiomatic
let result = [x * x for x in 0..10]
```

---

## Closures

**Minimize syntax.** Closures are already short. Keep them that
way.

```
// ✗ over-specified
items.filter(|item: &Item| -> bool { item.active == true })

// ✓ idiomatic — types inferred, expression body
items.filter(|item| item.active)
```

---

## Single-Expression Functions

If a function body is one expression, it's one line.

```
// ✗ verbose
fn double(x: i32) -> i32:
    x * 2

// ✓ idiomatic — both are fine, but the short form is preferred
fn double(x: i32) -> i32: x * 2
```

Same for match arms, if/else, closures — if it fits on one
line, keep it on one line.

---

## Naming

With follows Rust's naming conventions:

| Kind | Convention | Example |
|------|-----------|---------|
| Functions, methods, variables | `snake_case` | `get_user`, `is_valid` |
| Types, traits, enums | `PascalCase` | `ServerConfig`, `Display` |
| Enum variants | `PascalCase` | `Option.Some`, `Color.Red` |
| Constants | `SCREAMING_SNAKE` | `MAX_RETRIES` |
| Modules, files | `snake_case` | `string_map.w` |

`with fmt` enforces these.

---

## Summary: The Idiomatic Checklist

Before submitting code, check:

1. **No unnecessary parens** — `fn greet:` not `fn greet():`
2. **No unnecessary return types** — `fn main:` not `fn main -> i32:`
3. **No unnecessary type annotations** — `let x = 42` not `let x: i32 = 42`
4. **No `Ok(value)`** — just return the value
5. **No `Ok(())`** — just end the function
6. **No trailing `0`** — implicit default return handles it
7. **No manual unwrap chains** — use `?`, `??`, `?.`
8. **No verbose enum paths** — `.Variant` not `Type.Variant` when inferrable
9. **No field repetition** — `User { name, email }` not `User { name: name, email: email }`
10. **No mutable-then-freeze** — use `with ... as mut`
11. **No nested function calls** — use `|>` for pipelines
12. **No manual lock/guard management** — use `with`
13. **No string concatenation** — use interpolation `"hello {name}"`
14. **No C-style loops** — use ranges and iterators
15. **No `if/else if` chains on enums** — use `match`
16. **No manual cleanup at every exit** — use `defer`
17. **No `== true` or `== false`** — just `if active` or `if not active`