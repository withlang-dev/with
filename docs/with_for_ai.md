# With for AI — Compact Project Primer

**Purpose:** Give an AI assistant enough context to read, write, review, and modify With code meaningfully without loading the full language specification.

This is not the full spec. It is the operational 90%: syntax, safety model, idioms, common patterns, and mistakes to avoid.

---

## 0. Identity

With is a systems programming language: **no garbage collector, native-compiled, memory-safe at compile time**, with explicit control and modern ergonomics.

It targets:

- game engines and ECS
- databases and infrastructure
- servers and service architecture
- C interop-heavy systems code

The pitch:

```text
Rust-like safety without Rust-like ceremony.
No lifetime annotations.
No Pin.
No PhantomData.
No Futures/Poll model.
No garbage collector.
```

The trade-off:

```text
Safe With code cannot store references in long-lived data structures.
```

The core model:

```text
Ownership is persistent.    Values have exactly one owner.
Borrowing is ephemeral.     References exist only in local/scoped use.
Relationships are handles.  Long-lived links use typed indices, not pointers.
Scope is explicit.          `with` is the central construct.
```

Do **not** think of With as "Rust with nicer syntax." With gets safety through a different design: second-class references, ephemeral types, view-liveness analysis, handles, and scoped access.

---

## 1. Syntax Basics

With supports three body forms for block-introducing constructs.

```with
if x > 0: print("positive")       // inline colon

if x > 0:
    print("positive")             // indented colon

if x > 0 { print("positive") }    // braced
```

This applies broadly: `fn`, `if`, `while`, `for`, `with`, `defer`, `errdefer`, `comptime`, match arms, and labeled blocks. `unsafe` is narrower: use `unsafe:` only as a newline block, `unsafe { ... }` for inline blocks, or `unsafe *p`/`unsafe p[i]` for raw access.

**Use whichever block style makes the most sense for the code you are currently writing.** It is common and idiomatic to switch between inline colon, indented colon, and braced forms depending on the exact circumstances — block length, nesting depth, readability, and surrounding code. Do not force a single style everywhere.

`else if` is a two-token chain continuation:

```with
if x < 0:
    negative()
else if x == 0:
    zero()
else:
    positive()
```

Do **not** write:

```with
else: if x == 0: ...
```

Inline conditional expressions use the same body markers:

```with
let abs = if x >= 0: x else: -x
```

Comments use `//`.

```with
// line comment
```

String interpolation uses f-strings:

```with
print(f"hello {name}, score={score}")
```

String concatenation uses `++`:

```with
let full = first ++ " " ++ last
```

---

## 2. Variables, Constants, and Mutability

```with
let x = 5                // immutable binding
var y = 10               // mutable binding
const MAX: i32 = 1024    // compile-time constant
```

Local shadowing is disallowed. Prefer scoped `with` bindings and pipelines over repeated rebinding.

```with
let normalized = with vec.len() as len:
    if len > 0: vec.scale(1.0 / len) else: Vec2.zero()
```

---

## 3. Functions and Methods

### Functions

```with
fn greet:
    print("hello")

fn add(a: i32, b: i32) -> i32:
    a + b

fn double(x: i32) -> i32: x * 2
```

No-argument functions may omit parentheses.

```with
fn main:
    print("hello")
```

### Result functions use implicit `Ok`

If a function returns `Result[T, E]`, the final happy-path value is automatically wrapped.

```with
fn get_user(id: UserId) -> Result[User, DbError]:
    let row = db.query(id)?
    User.from_row(row)     // implicit Ok(...)
```

For `Result[Unit, E]`, ending the function normally returns `Ok(())`.

```with
fn save_all(items: &Vec[Item]) -> Result[Unit, DbError]:
    for item in items:
        db.insert(item)?
    // implicit Ok(())
```

Explicit `Ok(value)` is legal, but usually unnecessary at tail position.

### Named, default, and implicit parameters

```with
fn connect(host: str, port: u16 = 8080, timeout: i32 = 30) -> Connection

connect("localhost")
connect("localhost", port: 9090)
connect(timeout: 60, host: "localhost")
```

Implicit parameters are filled from lexical `with context(...)` blocks.

```with
fn log(msg: str, ctx: implicit &Context):
    ctx.logger.log(msg)

with context(ctx):
    log("started")
```

### Methods live in `extend` blocks

```with
extend User:
    fn display_name(self: &Self) -> str:
        self.name

    fn deactivate(mut self: Self):
        self.active = false

    fn into_id(move self: Self) -> UserId:
        self.id
```

Receiver forms:

| Receiver | Meaning |
|---|---|
| `self: &Self` | borrow/read |
| `mut self: Self` | mutate caller's place |
| `move self: Self` | consume/move |

Do **not** write safe `&mut T`; With does not have it.

---

## 4. Types

### Primitive types

```text
i8 i16 i32 i64
u8 u16 u32 u64
f32 f64
bool
str
Unit
```

Aliases:

```text
Int  = i64
UInt = u64
```

Unsuffixed integer literals default to `i32`; floats default to `f64`, unless context says otherwise.

### Structs

```with
type Point { x: f64, y: f64 }

type Config:
    host: str = "127.0.0.1"
    port: u16 = 8080
```

Construction:

```with
let p = Point { x: 1.0, y: 2.0 }

let host = "localhost"
let port = 8080
let cfg = Config { host, port }       // field shorthand
let cfg2 = Config { port: 9090 }      // host uses default
```

Record update:

```with
let p2 = { p with x: 3.0 }
```

For non-`Copy` types, record update consumes the base.

### Enums

```with
enum Shape:
    Circle(radius: f64)
    Rectangle(w: f64, h: f64)
    Triangle(a: f64, b: f64, c: f64)

enum Direction { North | South | East | West }
```

Variant shorthand works when the expected type is known:

```with
fn default_role -> Role: .Member
```

Enum variants with data get generated accessors:

```with
shape.is_circle()
shape.as_circle()
shape.as_circle_ref()
```

### Discriminant enums

```with
enum Color: i32:
    Red = 1
    Green = 2
    Blue = 4
```

Auto-increment: if a variant omits `= N`, it defaults to the previous variant's value plus one (or zero for the first).

`@[flags]` changes auto-increment to power-of-two doubling:

```with
@[flags]
enum Perms: i32:
    Read         // 1
    Write        // 2
    Execute      // 4
```

### Tuples

```with
let pair: (i32, str) = (42, "hello")
let (x, y) = get_position()
```

### Fixed arrays

```with
let a: [i32; 4] = [1, 2, 3, 4]
let b: [f32; 8] = [0.0; 8]
```

### Slices

```with
[]T       // shared borrowed slice
[]mut T   // exclusive mutable slice
```

Slices are ephemeral borrowed views.

---

## 5. Ownership and References

### Ownership

Values have one owner. Assignment moves by default.

```with
let a = Vec.new()
let b = a
// a is invalid after move
```

Types implementing `Copy` are copied instead.

### References

With has exactly one safe reference type:

```with
&T
```

It is shared/read-only.

There is **no safe `&mut T`**. Mutation is expressed through:

```text
- `var` local bindings
- `mut self: Self` receivers
- `with ... as mut`
- IndexPlace projections
```

### Second-class references

References may appear as:

```text
- function parameters
- local bindings
- non-escaping closure arguments
- ephemeral return values
```

References may **not** appear in:

```text
- ordinary struct fields
- enum payloads
- heap containers that escape
- globals
- escaping closure captures
```

Wrong:

```with
type Lexer {
    source: &str,     // ERROR
}
```

Right for scoped parsing:

```with
type Lexer = ephemeral {
    source: &str,
    pos: usize,
}
```

Right for long-lived storage:

```with
type LexerState {
    source_id: SourceId,
    pos: usize,
}
```

### View-liveness

Active borrows are invalidated when the borrowed place is mutated. Borrow lifetimes are non-lexical: a borrow ends at its last use, not at the end of the block.

```with
var x = 5
let r = &x
print(r)     // last use of r
x = 10       // OK
```

### Auto-ref and auto-deref

```with
fn print_user(u: &User):
    print(u.name)

let alice = User { name: "Alice" }
print_user(alice)    // compiler borrows automatically
```

Auto-deref follows references, boxes, and smart pointers:

```with
let name = box_user.name
```

---

## 6. Ephemeral Types

`ephemeral` marks a type as second-class.

```with
type Token = ephemeral {
    text: &str,
    kind: TokenKind,
    span: Span,
}
```

Ephemeral values can be:

```text
- local bindings
- parameters
- return values, with propagation
- captures of non-escaping closures
```

Ephemeral values cannot be:

```text
- stored in ordinary structs
- stored in globals
- captured by escaping closures
- returned through opaque type erasure that hides ephemerality
- sent across threads/channels as `Send`
```

Ephemerality propagates:

```text
&T is ephemeral
Option[&T] is ephemeral
Vec[&T] becomes an ephemeral Vec
Structs with ephemeral fields must be marked ephemeral
```

A container containing ephemeral values may exist as a local ephemeral container, but it cannot escape.

```with
let refs: Vec[&str] = collect_refs()
process(refs)
// OK only if refs remains local/ephemeral and does not escape
```

---

## 7. Handles and SlotMaps

Long-lived relationships use typed handles, not references or raw pointers.

```with
type Handle[T] { index: u32, generation: u32 } with Copy, Eq, Hash
```

`SlotMap[T]` owns values and returns `Handle[T]`.

```with
let entity: Handle[Entity] = world.entities.insert(Entity { ... })

with world.entities.slot(entity) as mut e:
    e.health -= damage
```

Handles are:

```text
- typed
- Copy
- generation-checked
- safe against use-after-remove
```

Use handles for ECS entities, graph relationships, database rows, resource IDs, and long-lived cross-links.

---

## 8. `with` — The Central Construct

`with` means "work with this value inside this scope."

### 1. Guarded access

```with
with lock.read() as data:
    process(data)

with world.entities.slot(id) as mut entity:
    entity.health -= damage
```

The binding cannot escape the block.

### 2. Scoped mutation / builder

```with
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3
```

If the last statement is `Unit`, the block returns the mutated binding.

### 3. Scoped binding

```with
let damage = with armor_reduction(attacker, defender) as reduction:
    base_damage * (1.0 - reduction)
```

### 4. Implicit context

```with
with context(ctx):
    log("started")
```

### 5. Record update

```with
let moved = { entity with position: new_pos }
```

### Guard boundary rule

Data borrowed from guarded `with` blocks cannot escape. Clone/copy at the boundary.

```with
let name = with users.read() as data:
    data.get(id).map(u => u.name.clone())
```

---

## 9. Error Handling

With has no exceptions. Errors are values.

```with
type Option[T] = Some(T) | None
type Result[T, E] = Ok(T) | Err(E)
```

Use `?` to propagate:

```with
let user = find_user(id)?
```

Use `??` for defaults or early exits:

```with
let port = config.port ?? 8080
let user = find_user(id) ?? return Err(.NotFound)
let item = stack.pop() ?? break
```

Optional chaining:

```with
let city = user.address?.city
```

Context:

```with
let text = fs.read_to_string(path)
    .context("reading config")?
```

Error declarations:

```with
error ParseError =
    UnexpectedChar(pos: usize, got: u8)
    UnexpectedEof
    InvalidNumber(pos: usize)
```

Error conversion:

```with
error AppError from IoError, ParseError, DbError
```

`errdefer` runs only on error return:

```with
fn connect(url: str) -> Result[Connection, Error]:
    let conn = open_socket(url)?
    errdefer conn.close()
    authenticate(conn)?
    Connection { conn }
```

---

## 10. Pattern Matching

```with
match shape:
    Circle(r) => 3.14 * r * r
    Rectangle(w, h) => w * h
    _ => 0.0
```

Match can be expression-position or statement-position.

Expression-position must be exhaustive:

```with
let label = match result:
    Ok(_) => "ok"
    Err(_) => "err"
```

Useful patterns:

```with
match status:
    200..=299 => "success"
    404 => "not found"
    _ => "other"

match token:
    Ident(name) if name.len() > 0 => handle(name)
    in [Plus, Minus, Star, Slash] => .Operator
    _ => .Other
```

`let ... else`:

```with
let Some(user) = find_user(id) else return Err(.NotFound)
```

Chained `if let`:

```with
if let Some(user) = find_user(id),
   user.is_active(),
   let Some(email) = user.email:
    send_welcome(email)
```

---

## 11. Iteration, Pipelines, and Collections

For loops:

```with
for item in items:
    process(item)

for (key, value) in map:
    print(f"{key}: {value}")

for Some(item) in optional_items:
    process(item)
```

Pipelines:

```with
let names = users
    |> filter(it.active)
    |> map(it.name)
    |> collect[Vec]()
```

`it` is an implicit single-argument closure parameter. Do not nest `it`; use explicit closure parameters inside nested closures.

```with
items |> map(it.children |> filter(c => c.active))
```

Comprehensions allocate:

```with
let squares = [x * x for x in 0..10]
```

Membership:

```with
if role in [.Admin, .Member]:
    allow()

if name not in banned:
    continue_login()
```

---

## 12. Strings and Formatting

Two user-facing string types:

```text
str   owned UTF-8 string
&str  borrowed string view
```

String literals default to owned `str`, but if the expected type is `&str`, they become zero-cost static views.

```with
let s = "hello"        // str
let v: &str = "hello"  // &str
```

F-strings are the formatting mechanism:

```with
print(f"user={user.name} score={score}")
print(f"point={point:?}")  // debug
```

Output functions:

| Function | Target | Newline |
|---|---|---|
| `print(s)` | stdout | yes |
| `eprint(s)` | stderr | yes |
| `write(s)` | stdout | no |
| `ewrite(s)` | stderr | no |

There is no `println`.

---

## 13. Traits and Dynamic Dispatch

Traits:

```with
trait Show:
    fn show(self: &Self) -> str

impl Show for Point:
    fn show(self: &Self) -> str:
        f"({self.x}, {self.y})"
```

Generic bounds are optional:

```with
fn double[T](x: T): x + x
```

The body is checked when instantiated. Explicit bounds are available:

```with
fn debug[T: Show + Hash](x: &T):
    print(x.show())
```

Dynamic dispatch uses explicit `dyn`:

```with
fn process(logger: &dyn Logger):
    logger.log("processing")
```

With has implicit trait-object coercion:

```with
let logger = ConsoleLogger {}
process(&logger)
```

Important syntax traits:

| Trait | Enables |
|---|---|
| `Iter[T]` | `for x in expr` |
| `Contains[T]` | `x in collection` |
| `IndexGet` / `IndexPlace` | indexing and indexed assignment |
| `Try` | `?` |
| `Drop` | destructor at scope exit |

---

## 14. Async and Concurrency

With async is fiber-based.

```with
async fn fetch(url: str) -> Result[str, IoError]:
    let resp = http.get(url).await?
    resp.read_body().await
```

Calling an `async fn` immediately starts a fiber and returns `Task[T]`.

```with
let task = fetch(url)
let body = task.await?
```

There is:

```text
- no Future trait
- no Pin
- no Poll
- no async function type
- one built-in fiber scheduler
```

### Structured concurrency

`async scope` uses `s.track(task)` to register already-started fibers with the scope. Do **not** use `s.spawn()` in async scopes — that is for non-async OS-thread scopes only.

```with
async scope s =>
    let t1 = s.track(fetch(url1))
    let t2 = s.track(fetch(url2))

    let r1 = t1.await?
    let r2 = t2.await?
    (r1, r2)
```

Why `track`, not `spawn`: calling an `async fn` eagerly spawns a fiber and returns `Task[T]`. `s.track()` registers that task with the scope. If you used `s.spawn(() => async_fn())`, the closure would run on one fiber and the async fn would spawn a second — escaping structured concurrency.

For CPU-bound parallelism on OS threads (non-async):

```with
scope s =>
    s.spawn(() => compute_chunk_a())
    s.spawn(() => compute_chunk_b())
```

### Fire-and-forget

```with
spawn send_analytics(event)
```

Do **not** write:

```with
let _ = send_analytics(event)  // cancels task; not fire-and-forget
```

### Guarded await rule

Do not hold `@[no_await_guard]` guards across `.await`.

Wrong:

```with
with lock.read() as data:
    fetch(data.url).await
```

Right:

```with
let url = with lock.read() as data:
    data.url.clone()

fetch(url).await
```

### Channels

Channels require `Send` element types, not merely `ScopedSend`. Do not send ephemeral references over channels.

---

## 15. Unsafe

Safe by default. Use `unsafe` only for operations that can violate memory safety.

Requires `unsafe`:

```text
- raw pointer dereference
- raw pointer indexing
- manual extern "C" calls
- unsafe fn calls
- inline asm
- transmute
```

Does not require `unsafe`:

```text
- raw pointer arithmetic
- raw pointer comparison
- address-of
- pointer/integer casts
```

Example:

```with
fn use_ptr(p: *mut i32):
    let offset = p + 2        // safe pointer arithmetic

    unsafe:
        *offset = 10          // dereference requires unsafe
```

Unnecessary `unsafe` blocks are compile errors.

---

## 16. C Interop

Use `c_import`:

```with
use c_import("sqlite3.h", link: "sqlite3")
```

Functions imported via `c_import` are callable directly. The import is the opt-in.

Manual `extern "C"` functions require `unsafe` to call. Prefer `c_import` when a header is available; manual `extern` declarations are lower-level and should be used only when no header exists or fine-grained control is needed.

```with
extern "C" {
    fn puts(s: *const u8) -> i32
}

unsafe:
    puts(c"hello".ptr)
```

Raw pointer dereference always requires `unsafe`.

C interop should be honest:

```text
- translate what can be translated correctly
- emit diagnostics or comptime_error for unsupported constructs
- never silently fake completeness
```

Layout:

```with
@[repr(C)]
type Point { x: f64, y: f64 }
```

Export:

```with
@[c_export("my_lib_init")]
fn init(config: *const Config) -> i32:
    ...
```

---

## 17. Comptime and Code Generation

With has `comptime`, not macros.

```with
comptime fn hash_str(s: str) -> u64:
    var h: u64 = 5381
    for c in s.bytes():
        h = h * 33 + c as u64
    h

const ID = comptime hash_str("world_matrix")
```

Type introspection at compile time:

```with
comptime fn print_fields[T: type]:
    for field in T.fields():
        print(field.name)
```

Common type methods:

```text
T.fields()
T.variants()
T.size()
T.align()
T.name()
T.implements(Trait)
T.is_copy()
```

Derives are comptime-based:

```with
@[derive(Debug, Clone)]
type Point { x: f64, y: f64 }
```

Constraints:

```text
- no arbitrary I/O in ordinary comptime
- no FFI
- deterministic
- no runtime reflection by default
- no token macros
- no AST macros
- generated code goes through normal type checking
```

For generated code, prefer braced bodies to avoid indentation-sensitivity.

---

## 18. Memory and Allocators

No GC. Destruction is deterministic.

Explicit reference counting:

```with
Rc[T]
Arc[T]
```

Standard allocator families:

```text
Arena
FrameArena
PoolAllocator
```

If a container borrows an allocator, the container becomes ephemeral:

```with
fn example(arena: &FrameArena):
    var xs = Vec.new_in(arena)
    xs.push(1)
    // xs cannot escape
```

---

## 19. Operators Quick Reference

| Category | Operators |
|---|---|
| Arithmetic | `+` `-` `*` `/` `%` `@` |
| Wrapping | `+%` `-%` `*%` |
| Saturating | `+\|` `-\|` `*\|` |
| Bitwise | `&` `\|` `^` `~` `<<` `>>` |
| Comparison | `==` `!=` `<` `>` `<=` `>=` |
| Logical | `and` `or` `not` |
| String | `++` |
| Pipeline | `\|>` `<\|` |
| Error / option | `?` `??` `?.` |
| Membership | `in` `not in` |
| Cast | `as` |
| Raw address | `&raw mut` |

Comparisons such as `0 < x < 1` chain naturally. Equality and membership do not chain.

---

## 20. Key Patterns to Imitate

### Config with defaults

```with
let config = ServerConfig { port: 9090 }
```

### Builder with scoped mutation

```with
let req = with HttpRequest.new("GET", "/api") as mut r:
    r.header("Authorization", token)
    r.timeout(Duration.seconds(30))
```

### Handle-based relationships

```with
let entity = world.entities.insert(Entity { health: 100 })

with world.entities.slot(entity) as mut e:
    e.health -= damage
```

### Iterator pipeline

```with
let names = users
    |> filter(it.active)
    |> map(it.name)
    |> collect[Vec]()
```

### Error chain

```with
fn load(path: str) -> Result[Config, AppError]:
    let text = read_file(path).context("reading config")?
    let config = parse_toml(text).context("parsing config")?
    config
```

### Clone at guard boundary

```with
let snapshot = with state.read() as s:
    s.current_user.clone()
```

### Ephemeral parser

```with
type Parser = ephemeral {
    source: &str,
    pos: usize,
}

extend Parser:
    fn next_token(mut self: Self) -> Option[Token]:
        ...
```

---

## 21. What NOT to Write

### Do not store references in ordinary structs

```with
type Lexer { source: &str }   // ERROR
```

Use:

```with
type Lexer = ephemeral { source: &str, pos: usize }
```

or store offsets/handles.

### Do not write safe `&mut`

```with
fn process(data: &mut Vec[i32])  // wrong With
```

Use `mut self: Self`, `move self: Self`, `var`, `with ... as mut`, or place projections.

### Do not write `else: if`

```with
if a: x else: if b: y else: z    // wrong
if a: x else if b: y else: z     // right
```

### Do not return opaque borrowing iterators

```with
fn matches(text: &str) -> dyn Iter[&str]  // wrong
```

Use a concrete ephemeral iterator:

```with
type MatchIter = ephemeral { text: &str, pos: usize }
```

### Do not ignore tasks

```with
send_analytics(event)       // wrong: unused Task
let _ = send_analytics(event)  // wrong: cancels task
spawn send_analytics(event)    // right
```

### Do not hold mutex/RwLock guards across await

```with
with lock.read() as data:
    fetch(data.url).await   // wrong
```

Clone/copy owned data out first.

### Do not silently stub generated code

Use diagnostics or `comptime_error`. Incomplete generated output must be visible.

### Do not add macros

Use `comptime`, derives, type introspection, and explicit generated source.

### Do not write `-1` when you mean `-1`

```with
let x = -1    // wrong: verbose and confusing
let x = -1        // right
```

This applies to all constant negative values. Write the literal directly: `-1`, `-42`, `-1.0`. Never construct a negative constant by subtracting from zero.

### Do not use `s.spawn()` in async scopes

```with
async scope s =>
    let t = s.spawn(fetch(url))    // wrong: spawn is for OS-thread scopes
    let t = s.track(fetch(url))    // right: track registers the fiber
```

---

## 22. AI Contribution Rules

When contributing to a With project:

1. **Preserve core invariants.**
   - no safe `&mut`
   - no stored safe references
   - no hidden GC/refcounting/sync
   - no silent interop/codegen failure
   - no runtime reflection by default
   - no macro system

2. **Use With-native idioms.**
   - `with` for scoped resources, mutation, bindings, and contexts
   - handles/SlotMaps for long-lived relationships
   - ephemeral structs for scoped borrowed views
   - `Result`, `Option`, `?`, `??`, `.context()`
   - f-strings for formatting
   - `async scope` with `s.track()` for structured concurrency

3. **Choose the right block style.**
   Use inline colon for short single expressions, indented colon for multi-line blocks, and braces when they improve readability (e.g., inside match arms, deeply nested code, or generated code). Switch freely between styles as the code demands.

4. **Make incomplete work loud.**
   Prefer compiler diagnostics, failing tests, or `comptime_error` over silent placeholders.

5. **Respect project phase.**
   If the compiler/migrator/std library is still stabilizing, prefer small spec-aligned changes over large ecosystem-level features.

6. **Add tests for language behavior.**
   Good tests cover parse, typecheck, sema, borrow/ephemeral analysis, codegen, runtime behavior, and negative diagnostics as appropriate.

7. **Be careful around generated code.**
   Generated With should use braced bodies when possible and should remain readable enough to debug.

---

## 23. Compiler and Toolchain Context

Useful project facts for AI contributors:

```text
- The With compiler is self-hosting.
- Bootstrap uses a multi-stage fixpoint; stage outputs should match.
- LLVM is the backend.
- Build system: `build.w` using With code (`with build`).
- `with build`, `with run`, `with test`, `with fmt`, `with doc`, `with repl` are the CLI surface.
- `with migrate` translates C source to With.
- C interop is a day-zero requirement.
```

When proposing build/tooling changes, keep the distinction clear:

```text
with.toml = declarative package configuration
build.w   = executable build behavior in tool-mode With
```

Ordinary `comptime` is deterministic and side-effect-free. Build scripts and future compiler hooks are tool-mode compiler-driver execution, not ordinary pure comptime.

---

## 24. Minimal Cheat Sheet

```with
// function
fn add(a: i32, b: i32) -> i32: a + b

// result
fn load(path: str) -> Result[Config, Error]:
    let text = fs.read_to_string(path)?
    parse_config(text)

// struct
type User {
    name: str,
    email: str,
    active: bool = true,
}

// ephemeral struct
type Parser = ephemeral {
    source: &str,
    pos: usize,
}

// enum
enum Token:
    Ident(str)
    Number(i64)
    Eof

// extension methods
extend User:
    fn display(self: &Self) -> str: self.name
    fn deactivate(mut self: Self):
        self.active = false

// with builder
let cfg = with Config.default() as mut c:
    c.port = 8080

// guarded access
with lock.read() as data:
    print(data.len())

// implicit context
fn log(msg: str, ctx: implicit &Context):
    ctx.logger.log(msg)

with context(ctx):
    log("hello")

// match
match token:
    Ident(name) => handle(name)
    Eof => finish()

// let else
let Some(user) = find_user(id) else return Err(.NotFound)

// pipeline
let active = users |> filter(it.active) |> collect[Vec]()

// f-string
print(f"user={user.name} score={score:?}")

// async
async scope s =>
    let t = s.track(fetch_user(id))
    t.await?

// defer
let f = fs.open(path)?
defer f.close()
```