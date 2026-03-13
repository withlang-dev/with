# Migrating to With

A practical phrasebook for systems programmers coming from Rust, Zig,
Go, and Swift. Each section shows the pattern you know, the With
equivalent, and what to watch for.

---

# Table of Contents

1. [From Rust](#from-rust)
2. [From Zig](#from-zig)
3. [From Go](#from-go)
4. [From Swift](#from-swift)
5. [From Kotlin](#from-kotlin)
6. [Universal Patterns](#universal-patterns)

---

# From Rust

If you know Rust, you already understand With. The ownership model,
borrow checker, and trait system are the same. What changes is syntax
and a handful of design decisions that remove Rust's roughest edges.

**The short version:** Strip lifetimes. Replace `{ }` with `:` and
indentation. `impl Type` → `extend Type`. `impl Trait for Type`
stays the same. Postfix `.await`. No `Pin`, `Unpin`, or colored
functions.

## Prelude Names (No Import Needed)

With keeps a practical prelude in scope for every module. You do not
need to import:

- `Vec`, `HashMap`, `HashSet`, `Option`, `Result`, `String`
- `Debug`, `Display`, `Default`, `Iter`, `IntoIter`, `Eq`, `Hash`, `Ord`
- `print`, `println`, `assert` and related assertion/panic helpers

Write these names directly unless you want explicit qualification for
style/readability reasons.

## Types

```rust
// Rust
struct User {
    name: String,
    email: String,
    age: u32,
}

enum Shape {
    Circle(f64),
    Rectangle(f64, f64),
}
```

```with
// With
type User = {
    name: str,
    email: str,
    age: u32,
}

type Shape =
    | Circle(f64)
    | Rectangle(f64, f64)
```

`String` → `str` (both are owned, heap-allocated, UTF-8).
`&str` → `&str` (both are borrowed views). String literals
auto-promote: `let s = "hello"` works without `.to_string()`.

Generics use `[]` not `<>`:

```rust
// Rust
Vec<T>
HashMap<K, V>
Result<T, E>
Option<T>
```

```with
// With
Vec[T]
HashMap[K, V]
Result[T, E]
Option[T]
```

Numeric widening is implicit for lossless cases:

```with
let n8: u8 = 10
let n64: u64 = n8       // OK
let s64: i64 = n8       // OK (unsigned -> wider signed)
let f64v: f64 = 3.0 as f32   // f32 -> f64 is implicit once value is f32
```

Narrowing or sign-risky conversions still require `as`.

**Discriminant enums** (Rust's `#[repr(i32)]` enums) map directly:

```rust
// Rust
#[repr(i32)]
enum Color { Red = 1, Green = 2, Blue = 4 }
```

```with
// With
type Color: i32 = Red = 1 | Green = 2 | Blue = 4
```

Discriminant enums with payloads, `@[flags]` for bitfields, and
`Type.from_int(n)` for safe integer-to-enum conversion are also
supported.

## Variables and Mutability

```rust
// Rust
let x = 5;
let mut y = 10;
y += 1;
```

```with
// With
let x = 5
var y = 10
y += 1
```

No semicolons. `let mut` → `var`.

**`const`:** Rust's `const` maps directly to With's `const`:

```rust
// Rust
const MAX: i32 = 100;
```

```with
// With
const MAX: i32 = 100
```

## Functions

```rust
// Rust
fn add(a: i32, b: i32) -> i32 {
    a + b
}

fn greet(name: &str) {
    println!("Hello, {name}!");
}
```

```with
// With
fn add(a: i32, b: i32) -> i32: a + b

fn greet(name: &str):
    println("Hello, {name}")
```

`: expr` for single-expression bodies. No `!` on `println` — it's a
function, not a macro. String interpolation is built-in: `"{name}"`
calls `Display` on `name`.

## Pattern Matching

```rust
// Rust
match shape {
    Shape::Circle(r) => std::f64::consts::PI * r * r,
    Shape::Rectangle(w, h) => w * h,
}

// With `if let`
if let Some(user) = find_user(id) {
    println!("{}", user.name);
}

// With `let ... else`
let Some(user) = find_user(id) else {
    return Err(NotFound);
};
```

```with
// With
match shape
    .Circle(r) => std.math.PI * r * r
    .Rectangle(w, h) => w * h

// if let
if let Some(user) = find_user(id):
    println("{user.name}")

// chained if let (v6.3)
if let Some(user) = find_user(id), let Some(email) = user.email:
    send_welcome(email)

// let ... else
let Some(user) = find_user(id) else return Err(.NotFound)
```

Variant shorthand: `.Circle` instead of `Shape::Circle` when the
type is known from context. `=>` stays `=>`. Braces become `:` +
indentation.

Enum variants auto-generate accessor methods (§4.4):
`shape.is_circle()` → `bool`, `shape.as_circle()` → `Option[f64]` (moves),
`shape.as_circle_ref()` → `Option[&f64]` (borrowed).
No `matches!()` macro needed.

## Error Handling

```rust
// Rust
fn load(path: &str) -> Result<Config, io::Error> {
    let text = fs::read_to_string(path)?;
    let config = toml::parse(&text)?;
    Ok(config)
}

fn get_name(id: u64) -> Option<String> {
    let user = find_user(id)?;
    Some(user.name)
}
```

```with
// With — implicit Ok wrapping: just return the value
fn load(path: &str) -> Result[Config, IoError]:
    let text = fs.read_to_string(path)?
    let config = toml.parse(&text)?
    config                       // auto-wrapped in Ok(config)

fn get_name(id: u64) -> Option[str]:
    let user = find_user(id)?
    Some(user.name)
```

`?` works identically. The happy path just returns the value —
the compiler wraps it in `Ok(...)` automatically. Additional
ergonomics:

```with
// Optional chaining (no Rust equivalent)
let city = user.address?.city?.name

// Default operator (replaces .unwrap_or())
let name = find_name(id) ?? "anonymous"

// Error context (replaces .map_err() chains)
let text = fs.read_to_string(path)
    .context("failed to read config")?

// Implicit Ok for Unit results — just end the function
fn save(data: &Data) -> Result[Unit, IoError]:
    fs.write_file("out.txt", data.to_bytes())?
    // implicit Ok(()) — no trailing expression needed

// Error composition (replaces thiserror #[from])
error AppError from IoError, DbError =
    Validation(msg: str)
// Generates From impls — ? auto-converts IoError/DbError to AppError
```

In Rust, error composition typically requires `thiserror`:

```rust
// Rust — thiserror
#[derive(thiserror::Error, Debug)]
enum AppError {
    #[error("io error")]
    Io(#[from] std::io::Error),
    #[error("db error")]
    Db(#[from] DbError),
    #[error("validation: {0}")]
    Validation(String),
}
```

In With, `error ... from` generates the wrapper variants and `From`
implementations automatically. `?` uses `From` for conversion, so
errors propagate across subsystem boundaries without boilerplate.

## Structs and Methods

```rust
// Rust
struct Counter {
    count: u32,
}

impl Counter {
    fn new() -> Self {
        Counter { count: 0 }
    }

    fn increment(&mut self) {
        self.count += 1;
    }

    fn value(&self) -> u32 {
        self.count
    }
}
```

```with
// With
type Counter = { count: u32 }

extend Counter
    fn new -> Counter: Counter { count: 0 }
    fn increment(self: &mut Counter): self.count += 1
    fn value(self: &Counter) -> u32: self.count
```

`impl Type` → `extend Type`. `Self` → explicit type name.
`&self` → `self: &Counter`. `&mut self` → `self: &mut Counter`.

By-value `self` enables consuming method chains (builders):

```with
// With — builder pattern with by-value self
extend Builder
    fn host(self: Builder, h: str) -> Builder: { self with host: h }
    fn port(self: Builder, p: u16) -> Builder: { self with port: p }
    fn build(self: Builder) -> Result[Server, ConfigError]: ...

let server = Builder.new()
    .host("localhost")
    .port(8080)
    .build()?
```

v6.3 note: `@[derive(Builder)]` can generate this boilerplate when
you want a standard field-by-field builder.

## Default Values and Construction

```rust
// Rust — requires Default trait impl + struct update syntax
#[derive(Default)]
struct Config {
    timeout: u32,
    retries: u32,
    verbose: bool,
}

impl Default for Config {
    fn default() -> Self {
        Config { timeout: 30, retries: 3, verbose: false }
    }
}

let config = Config::default();
let custom = Config { retries: 5, ..Config::default() };
```

```with
// With — default field values (§4.3): declare defaults inline
type Config = {
    timeout: u32 = 30,
    retries: u32 = 3,
    verbose: bool = false,
}

let config = Config {}               // all defaults
let custom = Config { retries: 5 }   // only override what differs
```

No `impl Default`. No `..Default::default()` spread. Callers just
omit fields that have defaults. Defaults are evaluated at the
construction site (each construction gets fresh values).

## Traits

```rust
// Rust
trait Summary {
    fn summarize(&self) -> String;

    fn preview(&self) -> String {
        format!("{}...", &self.summarize()[..50])
    }
}

impl Summary for Article {
    fn summarize(&self) -> String {
        format!("{}: {}", self.title, self.author)
    }
}
```

```with
// With
trait Summary
    fn summarize(self: &Self) -> str
    fn preview(self: &Self) -> str:
        "{self.summarize().slice(0, 50)}..."

impl Summary for Article {
    fn summarize(self: &Article) -> str:
        "{self.title}: {self.author}"
}
```

`impl` blocks → `extend` for inherent methods. `impl Trait for Type`
stays the same syntax as Rust.

Trait objects: `Box<dyn Trait>` → `Box[dyn Trait]`.
`&dyn Trait` → `&dyn Trait`.

**`where` clauses:** Rust's `where` syntax maps directly. In With,
bounds are optional, so use inline bounds or `where` clauses when you
want the constraint spelled out in the signature:

```rust
// Rust
fn process<T>(x: T) where T: Display + Debug { ... }
```

```with
// With
fn process[T](x: T) where T: Display, T: Debug: ...
```

Unbounded generics are also valid:

```with
fn double[T](x: T): x + x
```

## Lifetimes

**Delete them.** With has no explicit lifetime annotations. The
ephemeral type system handles the same safety guarantees:

```rust
// Rust
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

```with
// With — no lifetime annotations needed
fn longest(x: &str, y: &str) -> &str:
    if x.len() > y.len() then x else y
```

The return type `&str` is ephemeral — the compiler ensures it
doesn't outlive the inputs through the ephemeral value rules (it
can't be stored in a struct, put in a container, or returned from
a function that doesn't propagate ephemerality).

**What to watch for:** Code with multiple lifetime parameters
and complex lifetime relationships may need restructuring. In
most cases, the ephemeral system is sufficient. When it isn't,
the fix is usually to clone or to use owned types.

## Async

```rust
// Rust
async fn fetch(url: &str) -> Result<String, Error> {
    let resp = client.get(url).await?;
    let body = resp.text().await?;
    Ok(body)
}

// Rust — colored functions, Send bounds, Pin...
use futures::join;
let (a, b) = join!(fetch("a"), fetch("b"));
```

```with
// With — no colored functions, no Pin
async fn fetch(url: &str) -> Result[str, Error]:
    let resp = client.get(url).await?
    let body = resp.text().await?
    body                             // implicit Ok wrapping

// Structured concurrency
let (a, b) = async scope s =>
    let ta = s.track(fetch("a"))
    let tb = s.track(fetch("b"))
    (ta.await?, tb.await?)
```

Key differences from Rust async:

| Rust | With |
|------|------|
| Stackless (state machines) | Stackful (fibers) |
| `Pin<&mut Self>` needed | References just work across `.await` |
| `Send` bounds infect everything | Mostly implicit; required only at explicit cross-thread/channel boundaries |
| `async fn` in traits requires workarounds | Just works |
| `.await` inside `map`/`filter` impossible | Works everywhere |
| Multiple runtimes (tokio, async-std) | One blessed runtime |
| `tokio::select!` macro | `select await` language construct |

## Iteration

```rust
// Rust
for item in &collection {
    process(item);
}

for (i, item) in collection.iter().enumerate() {
    println!("{i}: {item}");
}

let squares: Vec<i32> = (0..10).map(|x| x * x).collect();
```

```with
// With
for item in collection:
    process(item)

for (i, item) in collection.enumerate():
    println("{i}: {item}")

let squares = [x * x for x in 0..10]    // comprehension syntax
```

`.iter()` is implicit in `for` loops. Collection comprehensions
replace many `map`/`filter`/`collect` chains.

## Macros

**With has no macros.** Common Rust macros have direct replacements:

| Rust macro | With equivalent |
|------------|----------------|
| `println!("x: {}", val)` | `println("x: {val}")` |
| `format!("{}: {}", a, b)` | `"{a}: {b}"` |
| `vec![1, 2, 3]` | `vec![1, 2, 3]` (built-in syntax) |
| `#[derive(Debug, Clone)]` | `@[derive(Debug, Clone)]` |
| `#[derive(Debug, Clone, PartialEq, Eq, Hash)]` | `@[derive(all)]` |
| `assert!(cond)` | `assert(cond)` |
| `assert!(cond, "msg")` | `assert(cond, "msg")` or `require()`/`check()` for preconditions/invariants |
| `assert_eq!(a, b)` | `assert_eq(a, b)` |
| `todo!()` | `todo()` |
| `unreachable!()` | `unreachable()` |
| `cfg!(target_os = "linux")` | `comptime if cfg.target_os == "linux":` |

Proc macros and `macro_rules!` have no equivalent. If your Rust
code relies heavily on custom macros, you'll need to expand them
before converting, or rewrite using `comptime` (which covers many
of the same use cases).

## Closures

```rust
// Rust
let add = |a, b| a + b;
let double: Vec<i32> = nums.iter().map(|x| x * 2).collect();
let callback = move |x| captured_value + x;
```

```with
// With
let add = (a, b) => a + b
let double = nums |> map(x => x * 2) |> collect[Vec]()
// move closures: With infers capture mode from usage
let callback = x => captured_value + x
```

With infers whether a closure captures by reference or by move
based on how the captured variable is used. Iterator pipelines
accept collections directly.

**Implicit `it`:** For single-parameter closures, use `it` instead
of explicit `param => body` syntax (similar to Kotlin's `it`):

```with
// Rust: nums.iter().filter(|x| *x > 0).map(|x| x * 2)
// With:
nums |> filter(it > 0) |> map(it * 2)
```

## The `with` Block (New)

This has no Rust equivalent. It replaces several patterns:

```with
// Builder pattern (replaces Rust builder + method chaining)
let config = with Config {} as mut c:
    c.timeout = compute_timeout()
    c.retries = if production then 3 else 1

// Scoped resource access (replaces Rust MutexGuard juggling)
with mutex.lock() as data:
    data.process()
// lock released here

// Record update (replaces Rust struct update syntax)
let updated = { user with name: "new_name", active: false }
```

## Quick Reference: Syntax Mapping

| Rust | With |
|------|------|
| `{ }` blocks | `:` + indentation |
| `let mut x` | `var x` |
| `Vec<T>` | `Vec[T]` |
| `impl Foo` | `extend Foo` |
| `impl Trait for Foo` | `impl Trait for Foo` (same) |
| `&self` | `self: &Foo` |
| `match x { A => ..., }` | `match x` ⟨newline⟩ `A => ...` |
| `#[attr]` | `@[attr]` |
| `String::from("x")` / `"x".to_string()` | `"x"` (auto-promoted) |
| `Ok(value)` | `value` (implicit wrapping) or `Ok()` for early returns |
| `println!("{}", x)` | `println("{x}")` |
| `x.await` | `x.await` (same) |
| `async move { }` | `async: expr` (inline block) |
| `;` (semicolons) | (none) |
| `pub(crate)` | `pub` |
| `use crate::module` | `use module` |
| `mod.rs` / `lib.rs` | file = module |
| `Box::new(x)` | `Box.new(x)` |
| `::` (path separator) | `.` |
| `'a` (lifetimes) | (deleted — ephemeral system) |
| `where T: Trait` | `[T: Trait]` in signature or `where T: Trait` |
| `impl Default for Foo` + `..Default::default()` | Default field values: `type Foo = { x: i32 = 0 }`, `Foo {}` |
| `thiserror` `#[from]` | `error AppError from IoError, DbError` |
| `.unwrap_or(())` | `.unwrap_or()` (unit elision) |

---

# From Zig

Zig and With share deep philosophical alignment: no GC, explicit
control, comptime, error-as-values, and `defer`. The transition is
more about syntax than concepts.

**The short version:** Replace `try` with `?`. Replace `orelse` with
`??`. Replace allocator parameters with nothing. Replace `comptime`
duck typing with traits. Gain a borrow checker you never had.

## Types

```zig
// Zig
const User = struct {
    name: []const u8,
    email: []const u8,
    age: u32,
};

const Shape = union(enum) {
    circle: f64,
    rectangle: struct { w: f64, h: f64 },
};
```

```with
// With
type User = {
    name: str,
    email: str,
    age: u32,
}

type Shape =
    | Circle(f64)
    | Rectangle(w: f64, h: f64)
```

`[]const u8` → `&str` (borrowed view) or `str` (owned string).
`union(enum)` → enum with variants.

## Variables

```zig
// Zig
const x: i32 = 5;
var y: i32 = 10;
y += 1;
```

```with
// With
let x: i32 = 5
var y: i32 = 10
y += 1
```

`const` → `let`. `var` → `var`. Type inference works for both:
`let x = 5`.

## Functions

```zig
// Zig
fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub fn greet(name: []const u8) void {
    std.debug.print("Hello, {s}!\n", .{name});
}
```

```with
// With
fn add(a: i32, b: i32) -> i32: a + b

pub fn greet(name: &str):
    println("Hello, {name}")
```

Return type uses `->`. `void` → omit return type (or `-> Unit`).
`pub` works the same.

## Error Handling

```zig
// Zig
fn readFile(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, max_size);
}

fn findUser(id: u64) ?User {
    // ...
}

// orelse
const name = findUser(id) orelse return error.NotFound;

// catch
const data = readFile("config.txt") catch |err| {
    log.err("failed: {}", .{err});
    return err;
};
```

```with
// With
fn read_file(path: &str) -> Result[Vec[u8], IoError]:
    let file = fs.open(path)?
    defer file.close()
    file.read_to_end()

fn find_user(id: u64) -> Option[User]:
    // ...

// ?? (replaces orelse)
let name = find_user(id) ?? return Err(.NotFound)

// Error context (replaces catch-and-rethrow)
let data = read_file("config.txt")
    .context("failed to load config")?
```

`try expr` → `expr?`. `orelse` → `??`. Error sets (`!T`) →
`Result[T, E]` with a specific error type. Optionals (`?T`) →
`Option[T]`.

`errdefer` → use `defer` with a conditional, or restructure with
`?` propagation (which handles cleanup via RAII).

## Allocators

**With has no allocator parameters.** This is the biggest change
from Zig. The default system allocator is used. Custom allocators
are available through `with` blocks:

```zig
// Zig
fn processItems(allocator: std.mem.Allocator, items: []const Item) !void {
    var list = std.ArrayList(Item).init(allocator);
    defer list.deinit();
    for (items) |item| {
        try list.append(item);
    }
}
```

```with
// With — no allocator parameter needed
fn process_items(items: &[Item]) -> Result[Unit, AppError]:
    var list = Vec[Item].new()
    for item in items:
        list.push(item)
    // implicit Ok(())

// For custom allocators, use with blocks:
with Arena.new(1024 * 1024) as arena:
    let data = arena.alloc[MyStruct](count)
    // arena freed at end of block
```

When converting Zig code, strip `allocator` parameters. Replace
`allocator.create(T)` with normal construction. Replace
`allocator.free(x)` with nothing (RAII handles it). Replace
`ArrayList(T).init(allocator)` with `Vec[T].new()`.

## Defer

```zig
// Zig
const file = try std.fs.cwd().openFile(path, .{});
defer file.close();
errdefer std.log.err("failed processing {s}", .{path});
```

```with
// With
let file = fs.open(path)?
defer file.close()
errdefer log.err("failed processing " ++ path)
```

`defer` is identical in both languages. `errdefer` works the same way:
it executes only when the function returns an error (via `?`). On
normal return, `errdefer` blocks are skipped.

## Comptime

```zig
// Zig
fn fibonacci(comptime n: u32) u32 {
    if (n <= 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

const fib_10 = fibonacci(10); // computed at compile time
```

```with
// With
comptime fn fibonacci(n: u32) -> u32:
    if n <= 1 then n
    else fibonacci(n - 1) + fibonacci(n - 2)

comptime let fib_10 = fibonacci(10)
```

Zig's `comptime` blocks → With's `comptime` blocks. The concepts
are nearly identical.

```zig
// Zig — comptime type info
fn dump(comptime T: type, value: T) void {
    const info = @typeInfo(T);
    inline for (info.Struct.fields) |field| {
        std.debug.print("{s}: {}\n", .{field.name, @field(value, field.name)});
    }
}
```

```with
// With — comptime type info
comptime fn dump[T: type](value: &T):
    for field in T.fields():
        println("{field.name}: {value.{field.name}}")
```

`@typeInfo` → `T.fields()` (or `TypeInfo.fields[T]()` in non-generic
contexts). `inline for` → `for` inside `comptime fn` (comptime
cascade).
`@field(value, name)` → `value.{field.name}` (comptime field
access).

## Testing

```zig
// Zig
test "addition" {
    try std.testing.expectEqual(@as(i32, 4), add(2, 2));
}

test "string equality" {
    try std.testing.expectEqualStrings("hello", greeting);
}
```

```with
// With
fn test_addition:
    assert_eq(add(2, 2), 4)

fn test_string_equality:
    assert_eq(greeting, "hello")
```

Zig's `test "name" { }` → `fn test_name:`. Run with
`with test`.

## For Loops and Iteration

```zig
// Zig
for (items) |item| {
    process(item);
}

for (items, 0..) |item, i| {
    std.debug.print("{}: {}\n", .{i, item});
}

var i: u32 = 0;
while (i < 10) : (i += 1) {
    process(i);
}
```

```with
// With
for item in items:
    process(item)

for (i, item) in items.enumerate():
    println("{i}: {item}")

for i in 0..10:
    process(i)
```

Zig's `for (items) |item|` → `for item in items:`.
Zig's `while` loop → `for i in 0..n:` for counted iteration.

## Slices and Arrays

```zig
// Zig
const slice: []const u8 = "hello";
const arr = [_]u8{ 1, 2, 3 };
const sub = slice[1..3];
```

```with
// With
let slice: &[u8] = b"hello"
let arr = [1_u8, 2, 3]
let sub = slice[1..3]
```

`[]const T` → `&[T]`. `[]T` → `&mut [T]`. Owned arrays → `Vec[T]`.

## Ownership (New Concept for Zig Programmers)

Zig trusts the programmer to manage memory manually. With enforces
ownership at compile time. This means:

```with
let a = vec![1, 2, 3]
let b = a              // a is MOVED to b
// a is no longer valid here — compile error to use it

// To keep both, clone explicitly:
let a = vec![1, 2, 3]
let b = a.clone()      // separate copy
// both a and b valid
```

References prevent moves:

```with
fn sum(data: &[i32]) -> i32:   // borrows, doesn't take ownership
    data.iter() |> fold(0, (a, x) => a + x)

let nums = vec![1, 2, 3]
let total = sum(&nums)       // nums still valid
println("{nums}")            // OK
```

**The payoff:** No use-after-free. No double-free. No dangling
pointers. No data races. All checked at compile time with zero
runtime cost.

## Quick Reference: Syntax Mapping

| Zig | With |
|-----|------|
| `const x: T = val` | `let x: T = val` |
| `var x: T = val` | `var x: T = val` |
| `fn foo(x: T) T` | `fn foo(x: T) -> T` |
| `try expr` | `expr?` |
| `orelse` | `??` |
| `catch \|err\|` | `.context("msg")?` or `match` |
| `!T` (error union) | `Result[T, E]` |
| `?T` (optional) | `Option[T]` |
| `[]const u8` | `&str` or `&[u8]` |
| `std.ArrayList(T)` | `Vec[T]` |
| `std.AutoHashMap(K,V)` | `HashMap[K, V]` |
| `@as(T, val)` | `val as T` |
| `@intCast(val)` | `val as T` |
| `defer` | `defer` |
| `errdefer` | `errdefer` (identical) |
| `comptime` | `comptime` |
| `@typeInfo(T)` | `T.fields()` (or `TypeInfo.fields[T]()` in non-generic contexts) |
| `inline for` | `for` inside `comptime fn` (or `comptime for` at top-level) |
| `test "name" { }` | `fn test_name:` |
| `std.debug.print` | `println` |
| `null` | `None` |
| `undefined` | (no equivalent — all values initialized) |
| `allocator` parameter | (removed — automatic) |
| `allocator.free(x)` | (removed — RAII) |

---

# From Go

Go and With share a love of simplicity, fast compilation, and
built-in concurrency. The major shift is from garbage collection
to ownership. This isn't a mechanical translation — it's a
different way of thinking about data. The reward is deterministic
performance with zero GC pauses.

**The short version:** `err != nil` becomes `?`. Goroutines become
`async fn` + `spawn`. Channels stay channels. `context.Context`
disappears entirely. Interfaces become traits. The GC goes away —
you now think about who owns each value.

## Types

```go
// Go
type User struct {
    Name  string
    Email string
    Age   int
}

type Shape interface {
    Area() float64
}
```

```with
// With
type User = {
    name: str,
    email: str,
    age: i32,
}

trait Shape
    fn area(self: &Self) -> f64
```

Go interfaces → With traits. Go structs → With types. Fields are
lowercase in With (no exported/unexported distinction by case —
With uses `pub`).

## Zero Values vs Default Field Values

Go automatically zero-initializes all fields. With requires explicit
initialization — but default field values (§4.3) provide the same
convenience:

```go
// Go — all fields zero-initialized
type Config struct {
    Host    string   // ""
    Port    int      // 0
    Retries int      // 0
    Verbose bool     // false
}
config := Config{Port: 8080}  // other fields are zero
```

```with
// With — default field values declare what "default" means
type Config = {
    host: str = "localhost",
    port: i32 = 8080,
    retries: i32 = 3,
    verbose: bool = false,
}
let config = Config {}                  // all defaults
let custom = Config { port: 9090 }     // override one field
```

Unlike Go's zero values (always the zero of the type), With defaults
can be any expression: `Duration.seconds(30)`, `Vec.new()`, etc.
Fields without defaults must always be provided.

## Variables

```go
// Go
x := 5
var y int = 10
y += 1
const MaxSize = 100
```

```with
// With
let x = 5
var y: i32 = 10
y += 1
let MAX_SIZE = 100    // or: comptime let MAX_SIZE = 100
```

`:=` → `let`. `var` → `var`. Both infer types.

## Functions

```go
// Go
func add(a, b int) int {
    return a + b
}

func divide(a, b float64) (float64, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}
```

```with
// With
fn add(a: i32, b: i32) -> i32: a + b

fn divide(a: f64, b: f64) -> Result[f64, MathError]:
    if b == 0.0 then return Err(.DivisionByZero)
    a / b
```

Go's `(value, error)` return pattern → `Result[T, E]`. Always.
No more `if err != nil`.

## Error Handling

This is the biggest ergonomic improvement over Go.

```go
// Go
func loadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("reading config: %w", err)
    }
    var config Config
    err = json.Unmarshal(data, &config)
    if err != nil {
        return nil, fmt.Errorf("parsing config: %w", err)
    }
    return &config, nil
}
```

```with
// With
fn load_config(path: &str) -> Result[Config, AppError]:
    let data = fs.read_file(path)
        .context("reading config")?
    let config = json.parse[Config](&data)
        .context("parsing config")?
    config                           // implicit Ok wrapping
```

The `?` operator replaces every `if err != nil { return ..., err }`
block. `.context("msg")` replaces `fmt.Errorf("msg: %w", err)`.

More patterns:

```go
// Go
val, ok := myMap[key]
if !ok {
    return defaultValue
}

result, err := doSomething()
if err != nil {
    return err
}
```

```with
// With
let val = my_map.get(key) ?? default_value

let result = do_something()?
```

## Interfaces and Methods

```go
// Go
type Stringer interface {
    String() string
}

type User struct { Name string }

func (u *User) String() string {
    return u.Name
}

func printAnything(s Stringer) {
    fmt.Println(s.String())
}
```

```with
// With
trait Stringer
    fn to_string(self: &Self) -> str

type User = { name: str }

impl Stringer for User {
    fn to_string(self: &User) -> str: self.name
}

fn print_anything(s: &dyn Stringer):
    println(s.to_string())
```

Go interfaces are implicit (structural typing). With traits are
explicit (`impl Trait for Type`). You must declare which traits a
type implements. This catches mistakes at compile time instead
of runtime.

`interface{}` / `any` → generics or `dyn Trait`. There is no
untyped escape hatch in With.

## Goroutines and Concurrency

```go
// Go
go handleRequest(conn)

// With channels
ch := make(chan int, 10)
go func() {
    ch <- 42
}()
val := <-ch

// With select
select {
case msg := <-inbox:
    process(msg)
case <-ctx.Done():
    return ctx.Err()
case <-time.After(5 * time.Second):
    return ErrTimeout
}
```

```with
// With
spawn handle_request(conn)

// With channels
let (tx, rx) = chan[i32](10)
spawn async:
    tx.send(42).await
let val = rx.recv().await

// With select
select await
    msg = inbox.recv() => process(msg)
    _ = cancel.cancelled() => return Err(.Cancelled)
    _ = timeout(5.secs()) => return Err(.Timeout)
```

`go func()` → `spawn async:`. `chan T` → `chan[T]`. `select`
→ `select await`. `ch <- val` → `tx.send(val).await`. `<-ch` →
`rx.recv().await`.

## context.Context — Gone

This is the biggest quality-of-life improvement for Go developers.

```go
// Go — context threaded through everything
func GetUser(ctx context.Context, id int64) (*User, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    row := db.QueryRowContext(ctx, "SELECT ...", id)
    // ...
}
```

```with
// With — structured concurrency handles it all
async fn get_user(id: i64) -> Result[User, DbError]:
    // Cancellation propagates automatically through async scope
    // Timeouts are handled at the caller level
    let row = db.query_one("SELECT ...", &[&id]).await?
    // ...
```

In With, cancellation propagates through the structured concurrency
tree. If a parent scope is cancelled, all child tasks are cancelled
automatically. No `context.Context` parameter on every function. No
`ctx.Done()` checks. No `context.WithTimeout` wrapping.

## For Loops

```go
// Go
for i := 0; i < 10; i++ {
    process(i)
}

for i, item := range items {
    fmt.Printf("%d: %v\n", i, item)
}

for key, val := range myMap {
    fmt.Printf("%s: %v\n", key, val)
}
```

```with
// With
for i in 0..10:
    process(i)

for (i, item) in items.enumerate():
    println("{i}: {item}")

for (key, val) in my_map:
    println("{key}: {val}")
```

## Slices and Maps

```go
// Go
items := []int{1, 2, 3}
items = append(items, 4)
m := map[string]int{"a": 1, "b": 2}
val, ok := m["a"]
delete(m, "b")
```

```with
// With
var items = vec![1, 2, 3]
items.push(4)
var m = HashMap[str, i32].new()
m.insert("a", 1)
m.insert("b", 2)
let val = m.get("a")      // returns Option[&i32]
m.remove("b")
```

Go slices → `Vec[T]`. Go maps → `HashMap[K, V]`. Append →
`.push()`. `delete` → `.remove()`.

v6.3 also adds common map-mutation helpers:
`m.update("a", 0, n => n + 1)` and `m.increment("a")`.

## Defer

```go
// Go
f, err := os.Open(path)
if err != nil {
    return err
}
defer f.Close()
```

```with
// With
let f = fs.open(path)?
defer f.close()
```

Identical concept. Both execute at scope exit in LIFO order.

## Nil

Go uses `nil` for zero values of pointers, slices, maps, channels,
functions, and interfaces. With uses `None` (from `Option[T]`) for
the absence of a value, and has no null pointers:

```go
// Go
func findUser(id int64) *User {
    // returns nil if not found
}
if user := findUser(42); user != nil {
    fmt.Println(user.Name)
}
```

```with
// With
fn find_user(id: i64) -> Option[User]:
    // returns None if not found

if let Some(user) = find_user(42):
    println(user.name)

// Or more concisely:
let name = find_user(42)?.name
```

No null pointer dereferences. Ever. The compiler enforces it.

## Ownership (New Concept for Go Programmers)

This is the fundamental shift. In Go, the garbage collector tracks
every allocation and frees it when nothing references it. In With,
every value has exactly one owner. When the owner goes out of scope,
the value is freed immediately.

```with
// Ownership basics
let a = vec![1, 2, 3]    // a owns the vector
let b = a                 // ownership MOVES to b
// a is invalid here — compile error to use it

// Borrowing: temporary access without ownership transfer
fn print_sum(data: &[i32]):     // borrows immutably
    let sum = data.iter() |> fold(0, (a, x) => a + x)
    println("sum: {sum}")

let nums = vec![1, 2, 3]
print_sum(&nums)           // borrow — nums still valid
println("{nums.len()}")    // OK

// Shared ownership (like Go's implicit sharing, but explicit)
let shared = Arc.new(MyService { ... })
let clone = shared.clone()   // both point to same data
// Last Arc dropped → data freed
```

**Rules of thumb for Go developers:**

- If you'd pass a pointer in Go → pass a reference (`&T`) in With
- If you'd return a new struct → return an owned value
- If you'd share across goroutines → use `Arc[T]`
- If you'd use a mutex → use `with mutex.lock() as data:`
- Stop worrying about when things get freed — it happens at `}`

## Quick Reference: Syntax Mapping

| Go | With |
|----|------|
| `:=` | `let` |
| `var x T` | `var x: T` |
| `func foo(x int) int` | `fn foo(x: i32) -> i32` |
| `err != nil { return err }` | `?` |
| `fmt.Errorf("msg: %w", err)` | `.context("msg")?` |
| `interface { Method() }` | `trait Foo: fn method()` |
| `go func() { }()` | `spawn async: ...` |
| `chan T` | `chan[T]` |
| `select { case ... }` | `select await ... =>` |
| `context.Context` | (deleted — structured concurrency) |
| `defer` | `defer` |
| `nil` | `None` |
| `make([]T, 0)` | `Vec[T].new()` |
| `make(map[K]V)` | `HashMap[K, V].new()` |
| `append(s, x)` | `s.push(x)` |
| `for i, v := range x` | `for (i, v) in x.enumerate():` |
| `fmt.Println(x)` | `println("{x}")` |
| `struct{ }` | `type Foo = { }` |
| `*T` (pointer) | `&T` (reference) or owned `T` |
| `new(T)` | `Box.new(T { ... })` |
| Zero-initialized fields | Default field values: `type Foo = { x: i32 = 0 }` |
| `(value, error)` returns | `Result[T, E]` |
| `errors.New("msg")` | `error AppError from ...` + `?` propagation |

---

# From C and C++

With is a systems language that respects your need for performance and memory layout control, but completely eliminates uninitialized memory, use-after-free bugs, and data races. 

**The short version:** Drop the header files. Drop CMake. Drop `#include` (unless you're using `c_import`). Pointers become safe references (`&T`) that can never be null. `malloc`/`free` and `new`/`delete` are replaced by single-owner values and RAII. Templates are replaced by clean generics. You get to keep the performance, but you lose the Undefined Behavior.

## Pointers, References, and Null

```cpp
// C/C++
void process(User* user) {
    if (user == nullptr) return;
    user->active = true;
}

int val = 5;
int* ptr = &val;
int& ref = val;
```

```with
// With
fn process(user: Option[&mut User]):
    if let Some(u) = user:
        u.active = true

var val = 5
let ptr: &mut i32 = &mut val    // Safe exclusive borrow
```

In C/C++, a pointer can be null, uninitialized, or dangling. In With, a reference (`&T` or `&mut T`) is guaranteed to point to valid memory and **cannot be null**. If a value is optional, use `Option[&T]`. 

Raw pointers (`*mut T`, `*const T`) exist in With, but they are strictly for C-interop and require `unsafe` blocks to dereference.

v6.3 adds null-safe pointer conversion:

```with
let name_ptr: *const c_char = c_get_name(id)
let name = name_ptr.as_option()
    .map(p => CStr.from_ptr(p).to_str())
    .unwrap_or("unknown")
```

`.as_option()` is safe (null check only). Dereferencing still
requires `unsafe`.

## Memory Management

```cpp
// C++
class Buffer {
    uint8_t* data;
public:
    Buffer() { data = new uint8_t[1024]; }
    ~Buffer() { delete[] data; }
};

auto buf = std::make_unique<Buffer>();
```

```with
// With
type Buffer = {
    data: Vec[u8],
}

// No explicit destructor needed; Vec cleans itself up.
let buf = Box.new(Buffer { data: vec![0; 1024] })
```

With uses strict ownership. When a value goes out of scope, it is destroyed. If you need explicit cleanup for custom resources (like closing an OS handle), implement the `Drop` trait. Otherwise, memory management is automatic and deterministic (no GC).

## Headers and Build Systems

```cpp
// C++
#include "math_utils.h"
#include <vector>

// You also need CMakeLists.txt or a Makefile to link this.
```

```with
// With
use std.collections.Vec
use math_utils.clamp

// No build script needed for pure With code. Just `with build`.
```

With has a module system. One file = one module. No header/source split (`.h` / `.cpp`). The compiler figures out dependencies automatically.

## Native C Interop (The Superpower)

If you have existing C code, you don't need to write manual binding files or use external tools. 

```c
// C
#include <sqlite3.h>
sqlite3* db;
sqlite3_open(":memory:", &db);
```

```with
// With
use c_import("sqlite3.h", link: "sqlite3")

var db: *mut sqlite3 = null
sqlite3_open(c":memory:".ptr, &mut db)
```

`c_import` parses C headers at compile time and makes all `struct`s, `enum`s, `#define` macros, and functions instantly available as With symbols. 
Imported C functions are directly callable; `unsafe` is still required for raw pointer dereference and pointer arithmetic.

## Classes and Methods

```cpp
// C++
class Entity {
private:
    int id;
public:
    Entity(int id) : id(id) {}
    int getId() const { return id; }
    void setId(int newId) { id = newId; }
};
```

```with
// With
type Entity = { id: i32 }

extend Entity
    fn new(id: i32) -> Entity: Entity { id }

    // Note the explicit 'self' parameter
    fn get_id(self: &Entity) -> i32: self.id

    fn set_id(self: &mut Entity, new_id: i32):
        self.id = new_id
```

With does not have inheritance (`virtual`, `public/private` base classes). It separates data (`type`) from logic (`extend`). Polymorphism is achieved through `trait`s (similar to pure abstract virtual classes).

## Templates vs Generics

```cpp
// C++
template <typename T>
T max(T a, T b) {
    return (a > b) ? a : b;
}
```

```with
// With
fn max[T](a: T, b: T) -> T:
    if a > b then a else b
```

With generics are also checked at instantiation. The difference is
that With keeps the surface syntax small and still lets you add an
explicit contract when it helps:

```with
fn max[T: Ord](a: T, b: T) -> T:
    if a > b then a else b
```

Write `[T: Ord]` or `where T: Ord` when the bound belongs in the API
contract. Omit it when the body already makes the requirement obvious.

## Constexpr and Macros

```cpp
// C++
#define MAX_PLAYERS 100

constexpr int compute_size(int base) {
    return base * 2;
}
int arr[compute_size(10)];
```

```with
// With
const MAX_PLAYERS: i32 = 100

comptime fn compute_size(base: i32) -> i32:
    base * 2

let arr: [i32; comptime compute_size(10)]
```

With has no token-level macros. Instead, `comptime` allows you to execute normal With code at compile time.

## Quick Reference: Syntax Mapping

| C / C++ | With |
|---------|------|
| `int`, `long long`, `float` | `i32`, `i64`, `f32` |
| `size_t` | `usize` |
| `struct` / `class` | `type` |
| `void foo()` | `fn foo:` (or `fn foo -> Unit:`) |
| `T* ptr` (optional) | `Option[&mut T]` |
| `T& ref` | `&mut T` or `&T` |
| `auto x = 5;` | `let x = 5` |
| `const int x = 5;` | `let x: i32 = 5` (variables are immutable by default) |
| `std::vector<T>` | `Vec[T]` |
| `std::unordered_map<K,V>` | `HashMap[K, V]` |
| `std::unique_ptr<T>` | `Box[T]` |
| `std::shared_ptr<T>` | `Arc[T]` |
| `#include "foo.h"` | `use foo` |
| `namespace ns { }` | `module ns` (at top of file) |
| `nullptr` / `NULL` | `None` (for options) or `null` (for raw FFI pointers) |
| `new T()` | `Box.new(T { ... })` |
| `delete ptr` | (Automatic when owner drops) |
| `std::cout << x << "\n";` | `println("{x}")` |

---

# From Swift

Swift and With are surprisingly close in philosophy: value types,
optionals, protocol-oriented design, structured concurrency, and
explicit error handling. The main difference is that With has no
ARC — ownership is compile-time, not runtime.

**The short version:** `protocol` → `trait`. `extension Foo: Bar` →
`impl Bar for Foo`.
`guard let` → `let ... else`. Optional chaining and `??` work
identically. `class` → owned `type` (or `Arc[T]` for shared state).
Delete `weak`/`unowned`/`strong` — the compiler figures it out.

## Types

```swift
// Swift
struct User {
    let name: String
    var email: String
    var age: Int
}

enum Shape {
    case circle(radius: Double)
    case rectangle(width: Double, height: Double)
}

class ViewModel {
    var items: [Item] = []
}
```

```with
// With
type User = {
    name: str,
    email: str,
    age: i32,
}

type Shape =
    | Circle(radius: f64)
    | Rectangle(width: f64, height: f64)

// class → owned type (no ARC)
// Default field values (§4.3) match Swift's property defaults:
type ViewModel = {
    items: Vec[Item] = Vec.new(),
}
let vm = ViewModel {}    // items defaults to empty Vec
```

Swift `struct` → With `type` (both are value types).
Swift `class` → With `type` (owned, no reference counting).
For shared ownership, use `Arc[T]` explicitly.

Swift `enum` with associated values → With enum variants.

## Variables

```swift
// Swift
let x = 5
var y = 10
y += 1
```

```with
// With
let x = 5
var y = 10
y += 1
```

Identical.

## Functions

```swift
// Swift
func add(_ a: Int, _ b: Int) -> Int {
    return a + b
}

func greet(name: String) {
    print("Hello, \(name)!")
}
```

```with
// With
fn add(a: i32, b: i32) -> i32: a + b

fn greet(name: &str):
    println("Hello, {name}")
```

No argument labels. No `return` needed for expression bodies.
`\(name)` → `{name}`.

## Optionals and Nil

```swift
// Swift
var name: String? = "Alice"
let length = name?.count ?? 0
let upper = name?.uppercased()

if let name = name {
    print(name)
}

guard let user = findUser(id) else {
    return nil
}
```

```with
// With
var name: Option[str] = Some("Alice")
let length = name?.len() ?? 0
let upper = name?.to_upper()

if let Some(name) = name:
    println(name)

let Some(user) = find_user(id) else return None
```

`T?` → `Option[T]`. `nil` → `None`. Optional chaining (`?.`) is
identical. Nil coalescing (`??`) is identical. `guard let ... else`
→ `let ... else`.

## Error Handling

```swift
// Swift
enum AppError: Error {
    case notFound
    case invalidInput(String)
}

func loadConfig(path: String) throws -> Config {
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let config = try JSONDecoder().decode(Config.self, from: data)
    return config
}

do {
    let config = try loadConfig(path: "config.json")
} catch {
    print("Failed: \(error)")
}
```

```with
// With
error AppError = NotFound | InvalidInput(str)

fn load_config(path: &str) -> Result[Config, AppError]:
    let data = fs.read_file(path)
        .context("reading config")?
    let config = json.parse[Config](&data)
        .context("parsing config")?
    config                           // implicit Ok wrapping

match load_config("config.json")
    Ok(config) => use_config(config)
    Err(e) => println("Failed: {e}")
```

`throws` → return `Result[T, E]`. `try expr` → `expr?`.
`do { try ... } catch` → `match` on the Result, or just use `?`
to propagate. Swift error types → With `error` declarations.

## Protocols and Extensions

```swift
// Swift
protocol Drawable {
    func draw(on canvas: Canvas)
    var boundingBox: Rect { get }
}

extension Circle: Drawable {
    func draw(on canvas: Canvas) {
        canvas.drawCircle(center: center, radius: radius)
    }
    var boundingBox: Rect {
        Rect(x: center.x - radius, y: center.y - radius,
             width: radius * 2, height: radius * 2)
    }
}

extension Array where Element: Numeric {
    func sum() -> Element {
        reduce(0, +)
    }
}
```

```with
// With
trait Drawable
    fn draw(self: &Self, canvas: &Canvas)
    fn bounding_box(self: &Self) -> Rect

impl Drawable for Circle {
    fn draw(self: &Circle, canvas: &Canvas):
        canvas.draw_circle(self.center, self.radius)
    fn bounding_box(self: &Circle) -> Rect:
        Rect {
            x: self.center.x - self.radius,
            y: self.center.y - self.radius,
            width: self.radius * 2.0,
            height: self.radius * 2.0,
        }
}

extend Vec[T: Add]
    fn sum(self: &Vec[T]) -> T:
        self.iter() |> fold(T.zero(), (a, x) => a + x)
```

`protocol` → `trait`. `extension Type: Protocol` →
`impl Trait for Type`. Protocol extensions with `where` →
`extend Vec[T: Trait]` (for inherent methods).

Swift's protocol-oriented programming maps directly to With's
trait-oriented design.

## Closures

```swift
// Swift
let double = { (x: Int) -> Int in x * 2 }
let names = users.map { $0.name }
let adults = users.filter { $0.age >= 18 }
let sorted = users.sorted { $0.name < $1.name }

// Trailing closure syntax
fetchData(from: url) { result in
    switch result {
    case .success(let data): process(data)
    case .failure(let error): print(error)
    }
}
```

```with
// With
let double = (x: i32) => x * 2
let names = users.iter() |> map(u => u.name) |> collect[Vec]()
let adults = users.iter() |> filter(u => u.age >= 18) |> collect[Vec]()
let sorted = users.iter() |> sorted_by((a, b) => a.name.cmp(&b.name)) |> collect[Vec]()

// No trailing closure syntax — use pipeline or named functions
let result = fetch_data(url).await
match result
    Ok(data) => process(data)
    Err(e) => println("{e}")
```

`{ $0.name }` → `u => u.name` or just `it.name`. Swift's `$0` maps
to With's `it` for single-parameter closures:

```with
let names = users |> map(it.name)
let adults = users |> filter(it.age >= 18)
```

No trailing closure syntax — With uses pipelines and `match`.

## Async/Await and Structured Concurrency

```swift
// Swift
func fetchUser(id: Int) async throws -> User {
    let data = try await api.get("/users/\(id)")
    return try JSONDecoder().decode(User.self, from: data)
}

// Task group
try await withThrowingTaskGroup(of: User.self) { group in
    for id in ids {
        group.addTask {
            try await fetchUser(id: id)
        }
    }
    var users: [User] = []
    for try await user in group {
        users.append(user)
    }
    return users
}
```

```with
// With
async fn fetch_user(id: i32) -> Result[User, ApiError]:
    let data = api.get("/users/{id}").await?
    json.parse[User](&data)

// async scope (= Swift's withThrowingTaskGroup)
async scope s =>
    let tasks = ids.iter()
        |> map(id => s.track(fetch_user(id)))
        |> collect[Vec]()
    tasks |> map(t => t.await) |> collect[Vec]()
```

`async throws` → `async fn ... -> Result[T, E]`.
`try await` → `.await?`. `withThrowingTaskGroup` → `async scope`.
`group.addTask` → `s.track()`.

Key difference: With's async is based on fibers, not Swift's
actor/continuation model. No `@Sendable` annotations. No
`MainActor` isolation. `.await` works everywhere, including
inside `map` and `filter`.

## Concurrent Await (Rust Mapping)

Rust commonly uses `tokio::join!`, `join_all`, or
`FuturesUnordered` for concurrent waits. With uses tuple `.await`
for fixed-size heterogeneous sets and pipeline combinators for
collections.

```rust
// Rust
let (user, posts) = tokio::join!(
    fetch_user(id),
    fetch_posts(id),
);

let users: Vec<User> = futures::future::join_all(
    ids.iter().map(|id| fetch_user(*id))
).await;
```

```with
// With
let (user, posts) = (fetch_user(id), fetch_posts(id)).await
let users = ids |> map(fetch_user) |> await_all
let users_limited = ids |> map(fetch_user) |> with_concurrency(10) |> await_all
```

`tokio::join!` maps to tuple `.await`. `join_all` maps to
`await_all`. `FuturesUnordered` + bounded parallelism maps to
`with_concurrency(n) |> await_all`.

## ARC → Ownership

This is the conceptual shift. Swift uses ARC (Automatic Reference
Counting) to manage `class` instances. With uses compile-time
ownership.

```swift
// Swift — ARC manages this automatically
class Service {
    let db: Database
    let cache: Cache
}

let service = Service(db: database, cache: redis)
let ref1 = service  // ARC: refcount = 2
let ref2 = service  // ARC: refcount = 3
// refcount hits 0 → freed
```

```with
// With — ownership, no refcount
type Service = {
    db: Database,
    cache: Cache,
}

let service = Service { db: database, cache: redis }
let ref1 = &service     // borrow — no refcount, compile-time checked
let ref2 = &service     // another borrow — both valid simultaneously

// For genuinely shared ownership (rare):
let shared = Arc.new(Service { db: database, cache: redis })
let clone = shared.clone()   // explicit — refcount = 2
```

**Translation rules:**

| Swift | With |
|-------|------|
| `class` with single owner | `type` (owned value) |
| `class` shared across closures/callbacks | `Arc[T]` |
| `weak var delegate: Delegate?` | `&dyn Delegate` (borrow) or restructure |
| `unowned` | (not needed — compiler enforces lifetime) |
| `[weak self] in` | (not needed — capture rules are compile-time) |

Most Swift classes are used as single-owner values. Convert
these to plain `type` first. Only reach for `Arc` when you
genuinely need shared ownership across concurrent boundaries.

## Enums with Associated Values

```swift
// Swift
enum NetworkResult {
    case success(Data)
    case failure(Error)
    case loading(progress: Double)
}

switch result {
case .success(let data):
    process(data)
case .failure(let error):
    print("Error: \(error)")
case .loading(let progress):
    updateProgress(progress)
}
```

```with
// With
type NetworkResult =
    | Success(Vec[u8])
    | Failure(NetworkError)
    | Loading(progress: f64)

match result
    .Success(data) => process(data)
    .Failure(error) => println("Error: {error}")
    .Loading(progress) => update_progress(progress)
```

Nearly identical. `.success` → `.Success`. `case` keyword dropped.
`switch` → `match`. Enum accessor methods are auto-generated:
`result.is_success()`, `result.as_success() -> Option[Vec[u8]]`,
`result.as_success_ref() -> Option[&Vec[u8]]`.

Exhaustiveness rule differs by position:
- expression-position `match` must be exhaustive;
- statement-position `match` may be partial (unmatched variants no-op).

## Collections

```swift
// Swift
var items: [Int] = [1, 2, 3]
items.append(4)
var dict: [String: Int] = ["a": 1, "b": 2]
dict["c"] = 3
let val = dict["a"]  // Optional<Int>
let set: Set<Int> = [1, 2, 3]
```

```with
// With
var items: Vec[i32] = vec![1, 2, 3]
items.push(4)
var dict = HashMap[str, i32].new()
dict.insert("a", 1)
dict.insert("b", 2)
dict.insert("c", 3)
let val = dict.get("a")   // Option[&i32]
let set = HashSet[i32].from([1, 2, 3])
```

`[T]` → `Vec[T]`. `[K: V]` → `HashMap[K, V]`. `Set<T>` →
`HashSet[T]`. `.append` → `.push`. Subscript assignment →
`.insert`.

## Quick Reference: Syntax Mapping

| Swift | With |
|-------|------|
| `let x = 5` | `let x = 5` |
| `var x = 5` | `var x = 5` |
| `func foo(_ x: Int) -> Int` | `fn foo(x: i32) -> i32` |
| `T?` | `Option[T]` |
| `nil` | `None` |
| `x?.property` | `x?.property` |
| `x ?? default` | `x ?? default` |
| `guard let x = opt else { return }` | `let Some(x) = opt else return` |
| `throws` / `try` | `-> Result[T, E]` / `?` |
| `do { } catch { }` | `match result` |
| `protocol Foo` | `trait Foo` |
| `extension Foo: Bar` | `impl Bar for Foo` |
| `class` | `type` (or `Arc[T]` if shared) |
| `struct` | `type` |
| `enum { case a(T) }` | `type Foo = A(T) \| B(U)` |
| `switch x { case .a: }` | `match x` ⟨newline⟩ `.A =>` |
| `\(expr)` | `{expr}` |
| `async throws` | `async fn -> Result[T, E]` |
| `try await expr` | `expr.await?` |
| `withThrowingTaskGroup` | `async scope s =>` |
| `group.addTask` | `s.track(task)` |
| `defer { }` | `defer expr` |
| `[T]` (Array) | `Vec[T]` |
| `[K: V]` (Dictionary) | `HashMap[K, V]` |
| `Set<T>` | `HashSet[T]` |
| `weak var` | `&T` (borrow) or restructure |
| `@Sendable` | (not needed) |
| `MainActor` | (not needed — no actor isolation) |
| `@Published` / Combine | (no equivalent — use channels) |

---

# From Kotlin

Kotlin and With share a fondness for concise syntax, null safety,
and expression-oriented design. The main shifts are: nullable
types (`T?`) become `Option[T]`, coroutines become fiber-based
`async fn`, and the GC/JVM goes away in favour of compile-time
ownership.

## Assertions and Preconditions

Kotlin's `require`, `check`, and `assert` map directly to With
builtins with the same names and semantics:

```kotlin
// Kotlin
fun withdraw(account: Account, amount: Long) {
    require(amount > 0) { "amount must be positive" }
    require(amount <= account.balance)

    account.balance -= amount
    check(account.balance >= 0) { "balance invariant violated" }
}

fun testWithdraw() {
    val acct = Account(balance = 100)
    withdraw(acct, 50)
    assert(acct.balance == 50L)
}
```

```with
// With
fn withdraw(account: &mut Account, amount: i64):
    require(amount > 0, "amount must be positive")
    require(amount <= account.balance)

    account.balance -= amount
    check(account.balance >= 0, "balance invariant violated")

fn test_withdraw:
    var acct = Account { balance: 100 }
    withdraw(&mut acct, 50)
    assert(acct.balance == 50)
```

| Kotlin | With |
|--------|------|
| `require(cond)` | `require(cond)` |
| `require(cond) { "msg" }` | `require(cond, "msg")` |
| `check(cond)` | `check(cond)` |
| `check(cond) { "msg" }` | `check(cond, "msg")` |
| `assert(cond)` | `assert(cond)` |
| `IllegalArgumentException` | `IllegalArgumentError` |
| `IllegalStateException` | `IllegalStateError` |

`require` raises `IllegalArgumentError` (the caller passed bad
input). `check` raises `IllegalStateError` (internal state is
corrupt). `assert` panics unconditionally (test/debug assertion).

---

# Universal Patterns

Patterns that apply regardless of your source language.

## The Pipeline Operator

With's `|>` replaces method chaining on iterators and
transforms data left-to-right:

```with
let result = raw_data
    |> parse
    |> validate?
    |> transform
    |> serialize
```

This is equivalent to `serialize(transform(validate(parse(raw_data))?))`,
but reads in execution order.

## The `with` Block

Four forms, one keyword:

```with
// Form 1: Scoped resource (mutex, file, connection)
with mutex.lock() as data:
    data.process()
// lock released automatically

// Form 2: Builder (mutable init, then freeze)
let config = with Config {} as mut c:
    c.timeout = compute_timeout(env)
    c.retries = if production then 3 else 1
// c is frozen and returned
// (For simple cases, default field values let you write
// Config { timeout: 30, retries: 3 } directly — see §4.3)

// Form 3: Scoped binding (temporary name)
let area = with shape.bounding_box() as bb:
    bb.width * bb.height
// bb doesn't leak into enclosing scope

// Form 4: Record update
let updated = { user with name: "Alice", active: true }
```

## String Handling

```with
// Owned string (heap-allocated, growable)
let name = "Alice"                   // str is the default type

// Borrowed view (ephemeral, zero-copy)
let view: &str = name.as_view()

// Interpolation calls Display
let msg = "Hello, {name}! You have {count} items."

// Runtime &str → str requires explicit .to_string()
fn take_owned(view: &str) -> str:
    view.to_string()                 // explicit allocation
```

## Testing

```with
fn test_basic_math:
    assert_eq(2 + 2, 4)
    assert_ne(2 + 2, 5)
    assert(is_positive(1))

fn test_error_case:
    let result = parse("invalid")
    assert_matches(result, Err(ParseError.InvalidSyntax(..)))

fn test_async_operation:
    let user = fetch_user(42).await.unwrap()
    assert_eq(user.name, "Alice")
```

Run with `with test`. Functions prefixed with `test_` are
automatically discovered.

## Common Idioms

```with
// Discard a must-use value intentionally
let _ = cache.delete(key).await

// Fire-and-forget task (do not use `let _ = task_expr`)
spawn send_analytics(event)

// Early return on None/Err
let user = find_user(id) ?? return Err(.NotFound)

// Exhaustive enum handling
match status
    .Active => process()
    .Inactive => skip()
    .Deleted => unreachable()

// Parallel work with structured concurrency
let (a, b) = async scope s =>
    let ta = s.track(compute_a())
    let tb = s.track(compute_b())
    (ta.await?, tb.await?)

// Collection comprehension
let squares = [x * x for x in 0..10]
let names = [u.name for u in users if u.active]

// Scoped mutex access
with state.lock() as data:
    data.counter += 1
    data.last_updated = Instant.now()
```

## Freestanding Mode (`no_std`)

For embedded, kernel, and bare-metal targets, With can run without
the standard library. Pass `--no-std` to the compiler:

```
with build --no-std firmware.w
```

**What you keep:** All primitives (`i8`–`i64`, `u8`–`u64`, `f32`,
`f64`, `bool`), `Option[T]`, `Result[T, E]`, fixed arrays, tuples,
`c_import`, full ownership/borrowing, `comptime`, `unsafe`, and
`match`. Everything that doesn't need a heap or an OS works.

**What you lose:** `str` (heap-allocated), `Vec[T]`, `HashMap`,
`HashSet`, `Box[T]`, `println`/`print` (needs stdout), `async fn`
(needs fiber runtime), and all of `std.io`/`std.fs`/`std.net`.

**Custom entry point:** Use `@[entry]` to name your entry point
something other than `main`:

```with
@[entry]
fn start -> i32:
    // initialize hardware via c_import
    0
```

**Three tiers:**

| Tier | Flag | What you get |
|------|------|--------------|
| Full | (default) | Everything |
| Alloc | `--no-std --alloc` | Core + heap types (Vec, str, HashMap) |
| Freestanding | `--no-std` | Core only — no heap |

---

## Rust Shadowing to Pipeline Cookbook

With disallows shadowing-style rebinding. Use `|>` (and `?` / `??`) for transformation chains.

```rust
// Rust
let input = std::fs::read_to_string(path)?;
let input = input.trim();
let input = serde_json::from_str(&input)?;
```

```with
// With
let input = read_file(path)? |> trim |> parse_json?
```

```rust
// Rust
let port = std::env::var("PORT")?;
let port: u16 = port.parse()?;
```

```with
// With
let port = env.get("PORT")? |> parse[u16]?
```

```rust
// Rust
let response = client.get(url).send()?;
let response = response.error_for_status()?;
let data = response.json::<Data>()?;
```

```with
// With
let data = client.get(url).send()? |> error_for_status? |> json[Data]?
```

```rust
// Rust
let cfg = load_config(path)?;
let cfg = cfg.validate()?;
```

```with
// With
let cfg = load_config(path)? |> validate?
```

## Rust Literal/Binding Mappings You Should Apply Early

- Numeric separators map directly (`1_000_000`, `0xFF_AA_22`, `0b1111_0000`).
- Trailing commas remain optional and are recommended in multiline lists.
- Raw strings map directly (`r"..."`, `r#"..."#`).
- Byte literals map directly (`b'A'`, `b'\x41'`).
- Unused bindings use `_` (`let _ = side_effect()`).

## No-shadowing Diagnostics

When porting Rust code that relied on rebinding, expect diagnostics like:

```
shadowing is not allowed for 'name'
```

Migration strategy:

1. Collapse rebinding chains into a single pipeline expression.
2. Use `with ... as` when a named intermediate is needed temporarily.
3. Use `_` for intentionally unused values.
