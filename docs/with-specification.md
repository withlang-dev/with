# The With Programming Language — Specification v6.5

**Status:** Reference specification for prototype implementation
**Positioning:** Systems programming that feels like a modern language.
**Principle:** Make the common case delightful. Be safe where it matters. Trust the programmer at the edges.

---

# Part I — Language Design

---

## 1. Design Goals

With is a systems programming language that wants you to have a good
time. No garbage collector. No lifetime annotations. No fighting the
compiler for an hour to do something obvious.

You get memory safety, native performance, and code that reads like
you'd explain it to a colleague. The compiler is smart, catches real
bugs, and stays out of your way for everything else.

### 1.1 Identity

With is **systems programming that feels like a modern language.**

Most lifetime complexity comes from storing references in structs.
Ban that, and 90% of the borrow checker pain disappears.
The remaining 10%? The compiler is smart about it, the stdlib handles
the tricky parts internally, and if you hit a genuine edge case,
`unsafe` is right there — no shame, no ceremony.

**The philosophy:**

- **Common case first.** If 95% of code does the obvious thing, make
  the obvious thing work. Don't penalize everyone for edge cases.
- **Safe where it matters.** Use-after-free, double-free, data races —
  these are caught at compile time. Always.
- **Pragmatic at the edges.** HashMap::get just works. Iterators just
  work. The compiler is smart about common patterns even when it can't
  formally prove safety. If it's wrong, the stdlib uses `unsafe`
  internally. You never see it.
- **Trust the programmer.** If you write something weird, the compiler
  warns you. It doesn't block you. You're an adult.

**With thrives in:**

- Service architecture (async, DI, error handling)
- Game engines and ECS (dense storage, handle-based entities)
- Database wrappers and infrastructure (FFI, resource guards)
- Anything where you'd use Rust but don't want to fight the compiler

**What With looks like in practice:**

```
async fn handle_signup(req: HttpRequest, db: &Database) -> Result[HttpResponse, ApiError]:
    let body = req.json[SignupRequest]() ?? return Err(.InvalidJson)

    if not body.email.is_valid() then
        return Err(.ValidationError("Invalid email format"))

    if db.find_user(body.email).await?.is_some() then
        return Err(.ValidationError("Email already exists"))

    let email = body.email
    let user = User { email, role: .Member, created: Instant.now() }

    db.insert(user).await?
    HttpResponse.json(201, "User created successfully")
```

No garbage collector. No lifetime annotations. No `Ok(())`. No
`.to_owned()`. No `unsafe`. Zero explicit memory management,
fully statically typed, native-compiled, memory-safe. It reads
like Python, runs like C.

### 1.2 Positioning

- **Safety without the ceremony.** Compile-time memory safety
  works. With takes that proof and asks: "what if it was fun?"
  No lifetime annotations, no `Pin`, no `PhantomData`, no `where`
  clauses that scroll off the screen.

- **Explicit control, compile-time safety.** Explicit allocation, C interop
  on day one, no hidden runtime costs — with compile-time safety
  that Zig deliberately omits.

- **Data-oriented by default.** The language naturally pushes you
  toward good architecture: data in pools, handles over pointers,
  clear ownership. Not because of restrictions, but because the
  ergonomics make it the path of least resistance.

### 1.3 Target Domains

With is built for **game engines, databases, and servers** — domains
where:

1. Data lives in large, contiguous pools (arenas, SlotMaps, ECS stores)
2. Entities reference each other by ID, not by pointer
3. Ownership is clear — the pool owns the data
4. Concurrent access must be high-performance and easy to read
5. C interoperability is non-negotiable

The name reflects the core abstraction: working *with* data through
scoped access. The `with` keyword is the language's signature
construct — it appears in guarded resource access (`with lock.read()
as data:`), object initialization (`with Config.default() as mut c:`),
intermediate computation (`with expr as name:`), and record update
(`{ entity with position: new_pos }`). Most With files contain `with`.
It is the language's answer to lifetimes: instead of annotating how
long a reference lives, you state what you're working with and let the
scope handle the rest.

### 1.4 Ownership Philosophy

```
Ownership is persistent.    — Values have exactly one owner.
Borrowing is ephemeral.     — References exist only in local scope.
Relationships are handles.  — Long-lived references use typed indices.
```

This is the fundamental invariant. It removes 90% of Rust's cognitive
load (no `'a`, no `where` clauses full of lifetime bounds, no
`PhantomData<&'a T>`) while preserving compile-time guarantees against
use-after-free, double-free, and data races.

The trade-off is explicit: you cannot store references in structs. You
cannot write `struct Lexer { source: &str }`. You cannot return a lazy
iterator that borrows from its input. Instead, you pass `(&Tree, NodeId)`
pairs, you `collect()` into owned containers, and you use `with` blocks
for scoped access to locked or guarded data. This forces Data-Oriented
Design patterns that are healthier for cache locality, serialization,
and concurrent access.

### 1.5 Explicit Non-Goals

The following are deliberately unsupported in safe code:

- Self-referential structs
- Stored references in data structures
- Borrow-based lazy iterators that escape their scope
- Safe intrusive linked lists
- Higher-kinded types
- Lifetime annotations
- State-machine-based async (no Futures, no Pin, no Unpin, no Poll)
- Garbage collection
- Transparent reference counting
- Pluggable async runtimes / executors

Each has a documented workaround. None require reintroducing the
features listed above. This is the core design invariant.

### 1.6 Comparison

| | Rust | With |
|---|---|---|
| **Memory safety** | Compile-time | Compile-time |
| **Lifetime annotations** | Yes (`'a`) | None |
| **Stored references** | Yes | No (handles) |
| **Borrow checker** | Full | Simplified |
| **Async model** | State machines | Fibers |
| **Runtime** | Optional | Optional |
| **Generics** | Yes | Yes |
| **C interop** | Via FFI | Native |
| **Learning curve** | Steep | Gentle |
| **Coding feel** | Explicit | Expressive |

---

### 1.7 Ergonomics

With prioritizes joy. The common case should be effortless:

- **Clean function syntax** — `fn greet:` for no-arg void functions.
  Parentheses optional when you have no parameters. `:` introduces
  the body. Return type only when you return something. (§9.1)
- **Implicit `Ok` wrapping** — functions returning `Result` don't
  need `Ok(value)` at the end. Just return the value. (§4.9)
- **No `Ok(())`** — functions returning `Result[Unit, E]` don't
  need a trailing `Ok()`. Just end the function. (§4.9)
- **String literals just work** — `"hello"` is `str` by default.
  No type annotations, no `.to_owned()`. (§15.3)
- **Auto-ref** — pass `alice` where `&User` is expected. The
  compiler borrows for you. (§3.8)
- **Auto-deref** — `box_user.name` works through any number of
  pointers. No `(*x).field`. (§3.7)
- **Implicit trait coercion** — pass `&my_log` where `&dyn Logger`
  is expected. If it implements the trait, just pass it. (§3.9)
- **Comprehensions** — `[x * x for x in 0..10]` builds a list.
  Obviously it allocates. That's fine. (§13.6)
- **Iterators just work** — hold two items, zip, peek. The compiler
  is smart about stdlib iterators. (§13.2)
- **`with` infers guards** — `with lock.read() as data:` — the
  compiler knows it's a guard from the type. No keyword. (§7.1)
- **C functions just call** — `c_import` functions are callable
  directly. No `unsafe {}` wrapper on every FFI call. (§16.1)
- **Postfix `.await`** — chains naturally with `?` and `|>` (§14.5)
- **Pipeline operator** — `data |> filter(it.active) |> map(it.name)` (§12)
- **Membership test** — `if x in [1, 2, 3]:` and `if x not in banned:`
  — reads like English, works on any collection, optimized for
  literals (§9.9)
- **Field shorthand** — `User { name, email }` when variable names
  match field names (§4.3)
- **Default field values** — `ServerConfig { port: 9090 }` omits
  fields that have defaults (§4.3)
- **Enum variant shorthand** — `.Member` when the type is known from
  context (§4.4)
- **Optional chaining** — `user.address?.city` for nested Option
  access (§10.3)
- **Default operator** — `x ?? default` for unwrap-or (§10.4)
- **Error context** — `fs.open(path).context("loading config")?`
  wraps errors with human-readable messages (§10.6)
- **Builder blocks** — `with Config.default() as mut c:` with
  flexible return values (§7.2)
- **Cancellation just works** — no `From[TaskCancelled]` on every
  error type. Cancellation unwinds cleanly. (§14.7)
- **Chained `if let`** — `if let Some(a) = x, let Some(b) = y:`
  kills the pyramid of doom (§9.7)
- **Enum `_ref` accessors** — `.as_str_ref()`, `.as_num_mut()`
  auto-generated. Navigate ASTs and JSON without cloning. (§4.4)
- **`@[derive(Builder)]`** — one annotation generates the entire
  builder pattern (§11.8)
- **Comptime cascade** — inside `comptime fn`, everything is
  comptime. No redundant prefixes. (§17.4)
- **`T.fields()`** — types are objects at compile time. Natural
  reflection-style metaprogramming. (§17.2)

### 1.8 Known Tradeoffs

Eliminating lifetime annotations has real costs. With handles them
pragmatically:

**No stored references.** References can't live in structs. Service
architectures use `Arc` for shared ownership, handles for entity
relationships. This is more verbose than Rust's `&'a T` but
eliminates lifetime annotations on every struct.

**Conservative borrow analysis.** When a function returns a reference
and takes multiple reference parameters, the compiler conservatively
assumes the return borrows from all inputs. For common patterns
(HashMap::get, split_at_mut, iterators), the **compiler has built-in
knowledge** of stdlib types and does the right thing. For user code,
returning references from multi-parameter functions may over-borrow.
Workaround: return an index/handle, or restructure.

**Generator yield restriction.** Generators cannot yield references
to their own locals. Use ephemeral iterator structs (§5.5) or the
callback/visitor pattern for zero-copy iteration.

**FFI stack switching.** Fibers calling C code pay ~10–50 ns for
stack switching. Use `@[ffi_stack]` to batch FFI-heavy functions.

These are the real costs. For the target domain — services, games,
infrastructure — they're the right trade.

---

## 2. Values and Ownership

### 2.1 Values

All values have a single owner. When a variable binding goes out of
scope, its value is destroyed. Destruction is deterministic.

### 2.2 Move Semantics

Assignment moves by default. After a move, the source binding is
invalid.

```
let a = Vec.new()
let b = a            // a is moved; b is the new owner
// a.push(1)         // COMPILE ERROR: use of moved value `a`
```

### 2.3 Copy Types

Types that implement the `Copy` trait are implicitly copied on
assignment, parameter passing, and other value uses. The original
binding remains valid.

```
let a: i32 = 5
let b = a            // copy; both a and b are valid
```

**Safety rules:**

1. **All fields must be `Copy`.** A type can only implement `Copy` if
   every field is itself `Copy`. This is checked recursively by the
   compiler.

2. **`Copy` and `Drop` are mutually exclusive.** A type that
   implements `Drop` cannot implement `Copy`. Bitwise duplication of
   a value with a destructor would cause double-free — the two copies
   would both run `Drop`.

3. **Types containing owning pointers** (`Box[T]`, `String`, `Vec[T]`,
   `Rc[T]`, `Arc[T]`) are not `Copy` because those types implement
   `Drop`. This is enforced by rule 1 (their fields are not `Copy`).

```
type Point = { x: f64, y: f64 }         // OK: f64 is Copy
impl Copy for Point                       // OK

type Handle = { id: u32, gen: u32 }      // OK: u32 is Copy
impl Copy for Handle                      // OK

type Buffer = { data: Vec[u8] }          // Vec is NOT Copy (has Drop)
impl Copy for Buffer                      // ERROR: field `data` is not Copy

type File = { fd: i32 }
impl Drop for File:
    fn drop(self): ...
impl Copy for File                        // ERROR: Copy + Drop is forbidden
```

These rules guarantee that `Copy` is always safe in safe code — it
cannot cause double-free, use-after-free, or resource leaks.

**Size warning:** The compiler emits a **warning** (not an error)
when `Copy` is implemented for types exceeding a size threshold. The
default threshold is 128 bytes. It is configurable via `with.toml`
(`copy_warn_threshold`). The warning does not affect semantics — the
type is still `Copy`.

### 2.4 Destructors and `defer`

Types may implement a `Drop` trait whose `drop` method is called when
the value goes out of scope. The `drop` method takes `self` **by
value** — the value is consumed:

```
impl Drop for Database:
    fn drop(self: Self):
        sqlite3_close(self.handle)
```

Because `drop` consumes `self`, there is no need to defensively
null out fields to prevent double-free — the value ceases to exist
after `drop` returns. The compiler handles the details: fields you
use in your drop body are consumed, remaining fields are dropped
automatically. No recursion, no leaks, no ceremony:

```
impl Drop for Database:
    fn drop(self: Self):
        sqlite3_close(self.handle)
        // self.handle was consumed by the close call
        // compiler drops remaining fields automatically
```

Drop order within a scope is reverse declaration order.

**Partial moves from Drop types are forbidden** in normal code.
Inside `drop` itself, you can access and consume fields freely.
Outside of `drop`, moving a field out of a Drop type is a compile
error:

```
type FileWrapper = { fd: File, name: String }
impl Drop for FileWrapper:
    fn drop(self: Self): close_file(self.fd)

let w1 = FileWrapper { fd: open_file(), name: "A" }
let w2 = { w1 with name: "B" }   // ERROR: partial move from Drop type
//        ^^^ w1 implements Drop; cannot move w1.fd out

// Fix: clone the field, or consume the entire value:
let w2 = FileWrapper { fd: w1.fd.clone(), name: "B" }
// or restructure so FileWrapper doesn't implement Drop
```

For non-`Drop` types, partial moves and record update syntax work
as described in §4.3.

For explicit cleanup of resources not tied to a value's lifetime, `defer`
executes a statement when the enclosing scope exits:

```
fn process(path: str) -> Result[Unit, IoError]:
    let f = fs.open(path)?
    defer f.close()
    // ... use f ...
    // f.close() runs here, regardless of early returns
    // implicit Ok(()) — no trailing expression needed
```

`defer` statements execute in LIFO order.

**Control flow restriction:** `return`, `break`, `continue`, and
`?` are **compile errors** inside `defer` blocks. Defer runs during
scope cleanup — non-local control flow would silently swallow the
function's actual return value or jump to unexpected locations:

```
// ERROR: return inside defer
defer if file.has_error() then return Err(IoError)
//                             ^^^^^^ ERROR E0901: non-local control
//                             flow is forbidden inside defer

// ERROR: ? inside defer
defer conn.close()?
//                ^ ERROR E0901: ? may return early from defer

// OK: handle errors locally inside defer
defer conn.close().unwrap_or(())
defer if let Err(e) = f.sync(): log.warn("sync failed: {e}")
```

---

## 3. References and Borrowing

### 3.1 Reference Types

```
&T          shared (immutable) borrow
&mut T      exclusive (mutable) borrow
```

### 3.2 Aliasing Rule

Within any scope, for a given value, either:

- Any number of `&T` references exist, OR
- Exactly one `&mut T` reference exists

Never both simultaneously. Enforced at compile time.

### 3.3 Second-Class Restriction

References are **ephemeral** (Section 5). They may appear as:

- Function parameters
- Local variable bindings
- Arguments to non-escaping closures
- Return values from functions (with ephemeral propagation; see 3.4)

References may NOT appear as:

- Struct or enum fields
- Elements of heap containers
- Captures of escaping closures
- Global or static storage

This restriction eliminates lifetime annotations entirely.

### 3.4 Returning References

A function may return a reference or a type containing a reference
(e.g., `Option[&T]`). The returned value is ephemeral: the caller may
bind it to a local and use it, but may not store it in a struct, place
it in a container, capture it in an escaping closure, or return it from
a function whose return type is not itself ephemeral.

A function whose declared return type is or contains an ephemeral type
is permitted. Both `fn foo -> StrView` and `fn bar -> Option[StrView]`
are legal. Any function that calls such a function and returns its
result must also have an ephemeral return type. This forms a chain:
ephemerality propagates upward through callers until a function
consumes the ephemeral value (by copying data out, converting to
owned, etc.) rather than returning it.

```
fn first(xs: &Vec[i32]) -> Option[&i32]:
    if xs.is_empty() then None else Some(&xs[0])

fn caller(xs: &Vec[i32]):
    let r = first(xs)        // OK: ephemeral local binding
    match r
        Some(v) -> println(v) // OK: local use
        None    -> ()

// OK: wraps ephemeral return in another ephemeral return
fn get_name(user: &User) -> StrView: user.name.as_view()

// OK: chains ephemeral through caller
fn get_name_upper(user: &User) -> StrView:
    get_name(user).to_upper_view()

// OK: consumes ephemeral, returns owned (chain ends here)
fn get_name_owned(user: &User) -> String:
    get_name(user).to_string()
```

When a function returns an ephemeral value and accepts multiple
reference parameters, the returned value is conservatively treated as
borrowing from all reference inputs.

### 3.5 Borrow Scope: Non-Lexical Lifetimes

A borrow is active from the point it is created until its **last use**,
not until the end of the enclosing block.

```
var x = 5
let r = &x
println(r)       // last use of r; borrow ends here
x = 10           // OK: no active borrow
```

### 3.6 Disjoint Field Borrowing

The compiler guarantees that simultaneous borrows of structurally
disjoint fields are permitted, at any nesting depth.

```
let a = &mut world.physics.positions
let b = &world.physics.velocities     // OK: different field paths
```

Disjointness is defined over **static field paths**. Two paths are
disjoint if they diverge at any field access.

**Array/slice index disjointness is NOT guaranteed.** Use `get2_mut`,
`split_at_mut`, or similar APIs for safe simultaneous element access.

**Disjoint capture in closures:** Closures capture only the
specific fields they access, not the enclosing struct as a whole.
This is critical for parallel data-oriented code:

```
// Each closure captures disjoint fields of `world`
scope |s|:
    s.spawn(|| run_physics(&world.transforms, &mut world.velocities))
    s.spawn(|| run_render(&world.transforms, &world.sprites))
// OK: both closures borrow world.transforms immutably,
// only the first borrows world.velocities mutably.
// No conflict — the captures are disjoint.
```

Without disjoint closure capture, the above code would fail because
both closures would capture `world` as a whole, creating conflicting
borrows. With disjoint capture, the compiler sees that the two
closures access non-overlapping field paths and permits the code.

### 3.7 Auto-Dereferencing

The compiler automatically follows references, boxes, and smart
pointers to find fields and methods. You never write `(*x).field`:

```
let u: Box[User] = Box.new(User { name: "Alice" })
let name = u.name           // auto-derefs Box → User → .name

let r: &User = &alice
let name = r.name           // auto-derefs &User → .name

let rr: &&User = &&alice
let name = rr.name          // follows multiple layers automatically
```

Auto-deref applies to `&T`, `&mut T`, `Box[T]`, `Arc[T]`, `Rc[T]`,
and any type implementing the `Deref` trait. The compiler inserts as
many dereferences as needed to reach the target field or method.

**The vibe:** "I don't care how many layers of indirection there
are, just give me the `.name` field."

### 3.8 Auto-Referencing

When a function takes `&T` and you pass an owned `T`, the compiler
automatically borrows it:

```
fn print_user(u: &User): println(u.name)

let alice = User { name: "Alice" }
print_user(alice)           // compiler inserts &alice automatically
```

This also works for method calls: `alice.greet()` works whether
`greet` takes `self: &Self` or `self: Self`.

**Restriction:** Auto-referencing only applies to shared borrows
(`&T`). Mutable borrows (`&mut T`) must be explicit — when data
might be modified, the call site should show it:

```
fn update(u: &mut User): u.name = "Bob"

var alice = User { name: "Alice" }
update(&mut alice)          // explicit: mutation is visible
update(alice)               // ERROR: won't auto-ref to &mut
```

**The vibe:** "The function just wants to look at the data. I
shouldn't have to manually type `&`."

### 3.9 Implicit Trait Object Coercion

When a function takes `&dyn Trait` and you pass `&T` where `T`
implements the trait, the compiler coerces automatically. No cast
needed — if it implements the trait, just pass it:

```
trait Logger:
    fn log(self: &Self, msg: &str)
type ConsoleLog = {}
impl Logger for ConsoleLog:
    fn log(self: &Self, msg: &str): println(msg)

fn process(logger: &dyn Logger): logger.log("processing")

let my_log = ConsoleLog {}
process(&my_log)            // auto-coerces &ConsoleLog → &dyn Logger
```

This is the Go interface feel — structural satisfaction, implicit
coercion. The same applies to `Box[T]` → `Box[dyn Trait]`:

```
let logger: Box[dyn Logger] = Box.new(ConsoleLog {})  // auto-coerced
```

**The vibe:** "It implements the trait. Just take it."

---

## 4. Types

### 4.1 Primitive Types

Signed integers: `i8`, `i16`, `i32`, `i64`
Unsigned integers: `u8`, `u16`, `u32`, `u64`
Floating point: `f32`, `f64`
Boolean: `bool`
Unit: `Unit` (zero-sized)

`Int` is an alias for `i64`. `UInt` is an alias for `u64`. Always
64-bit, never platform-dependent.

**Compile-time types:** At compile time, `type` is a first-class
value (see §17.3). `comptime` functions can accept `T: type` as a
parameter, enabling type-generic metaprogramming. `type` is not a
runtime value — it exists only during compilation and is erased
before code generation.

### 4.2 Arithmetic

Arithmetic is checked in safe code by default. Integer overflow causes
a panic in debug builds. Release builds may be configured for panic,
wrap, or saturation; the default is panic.

Explicit wrapping operators: `+%`, `-%`, `*%`.

**Implicit widening** is only allowed for lossless numeric conversions:
- Signed integers: `i8 -> i16 -> i32 -> i64`
- Unsigned integers: `u8 -> u16 -> u32 -> u64`
- Floats: `f32 -> f64`
- Unsigned to signed only when destination is strictly wider
  (`u8 -> i16`, `u16 -> i32`, `u32 -> i64`)

No other implicit numeric conversion is allowed.

**Implicit narrowing is a compile error:**

```
let big: i64 = 100000
let small: i32 = big          // ERROR: possible truncation
let small: i32 = big as i32   // OK: explicit intent

let x: u32 = 300
let y: u8 = x                 // ERROR: possible truncation
let y: u8 = x as u8           // OK: explicit intent

let f: f64 = 3.14
let g: f32 = f                // ERROR: possible precision loss
let g: f32 = f as f32         // OK: explicit intent
```

This catches a class of silent data corruption bugs inherited from
C. The `as` keyword signals that the programmer understands the
conversion may lose data. Signed-to-unsigned and unsigned-to-signed
conversions also require `as`, even at the same width.

### 4.3 Structs

```
type Point = { x: f64, y: f64 }
```

No methods, no constructors, no inheritance. Functions are associated
with types via extension blocks (Section 9.5).

**Record update syntax:**

```
let p1 = Point { x: 1.0, y: 2.0 }
let p2 = { p1 with x: 3.0 }        // p2 = Point { x: 3.0, y: 2.0 }
```

`{ base with field: value }` copies (or moves) all fields from `base`,
then overwrites the named fields. If the type is `Copy`, the base is
copied and remains valid. If not, the base is moved — non-overwritten
fields are moved into the new record, and **overwritten fields are
dropped** (the compiler emits `drop` calls for them). The base is
fully consumed.

Multiple fields may be updated:

```
let entity2 = { entity with
    position: new_pos,
    velocity: Vec3.zero(),
    health: entity.health - 10,
}
```

This is the primary mechanism for functional-style immutable updates.
It replaces the need for lenses or builder patterns. This is Form 4
of the `with` construct — see §7.4.

**Field shorthand:**

When a variable has the same name as a struct field, the `: value`
part may be omitted:

```
let name = "Alice"
let email = "alice@example.com"
let active = true

// Shorthand: name, email, active inferred from variable names
let user = User { name, email, role: Role.Member, active }

// Equivalent to:
let user = User { name: name, email: email, role: Role.Member, active: active }
```

This applies in all struct construction contexts including record
update syntax:

```
let new_email = "new@example.com"
let updated = { user with email: new_email }

// Shorthand also works here:
let email = "new@example.com"
let updated = { user with email }
```

**Default field values:**

Struct fields may declare default values. Fields with defaults may
be omitted at construction sites:

```
type ServerConfig = {
    host: str = "127.0.0.1",
    port: u16 = 8080,
    max_conns: usize = 1000,
    timeout: Duration = Duration.seconds(30),
}

// Omitted fields use their defaults
let config = ServerConfig { port: 9090 }
// Equivalent to:
let config = ServerConfig {
    host: "127.0.0.1",
    port: 9090,
    max_conns: 1000,
    timeout: Duration.seconds(30),
}

// All defaults (every field has a default)
let default_config = ServerConfig {}
```

Default expressions are evaluated at the construction site, not at
type definition time. Each construction gets a fresh evaluation:

```
type Request = {
    id: RequestId = RequestId.generate(),   // unique per construction
    created_at: Instant = Instant.now(),    // evaluated when constructed
    headers: Vec[Header] = Vec.new(),       // fresh Vec each time
}
```

**Rules:**

1. Default expressions must be valid at any construction site (no
   capturing locals from the definition scope).
2. Fields without defaults must always be provided at construction.
3. Fields with defaults may be explicitly provided to override.
4. Default field values compose with field shorthand and record
   update syntax.
5. Defaults are a comptime transformation — the compiler inserts
   the default expressions for missing fields at the call site.

**Common pattern — config structs:**

```
type PoolConfig = {
    min_conns: usize = 5,
    max_conns: usize = 20,
    idle_timeout: Duration = Duration.seconds(300),
    allocator: Allocator = std.heap.page_allocator(),
}

// Library function takes config with all-defaultable fields
fn connect(url: str, config: PoolConfig) -> Result[Pool, DbError]

// Usage: all defaults — just pass an empty struct literal
let pool = connect("postgres://localhost/mydb", PoolConfig {})?

// Usage: override what matters
let pool = connect("postgres://localhost/mydb", PoolConfig {
    max_conns: 50,
})?
```

### 4.4 Enums (Algebraic Data Types)

```
type Shape =
    | Circle(radius: f64)
    | Rectangle(w: f64, h: f64)
    | Triangle(a: f64, b: f64, c: f64)
```

**Variant constructors are importable and usable unqualified:**

```
use Shape.{Circle, Rectangle, Triangle}

let s = Circle(5.0)            // idiomatic
let s = Shape.Circle(5.0)      // also valid, fully qualified
```

The standard library prelude automatically imports:
- `Option.{Some, None}`
- `Result.{Ok, Err}`

These never require qualification in normal code.

**Variant shorthand (`.Variant`):**

When the expected type is statically known from context, variant
names may be prefixed with `.` instead of the full type path:

```
type Role = Admin | Member | Guest

// Return type is known → .Member is unambiguous
fn default_role -> Role: .Member

// Match subject type is known → .Admin, .Member, .Guest work
fn describe(role: Role) -> str:
    match role
        .Admin   -> "Administrator"
        .Member  -> "Member"
        .Guest   -> "Guest"

// Parameter type is known → .Urgent works
fn send(msg: str, priority: Priority): ...
send("hello", .Urgent)

// Struct field type is known → .Member works
let user = User { name, email, role: .Member, active: true }
```

The compiler infers the type from: return type annotations, match
subject type, function parameter types, struct field types, variable
type annotations, and generic type arguments. If the type cannot be
inferred, the compiler requires the full path and suggests it:

```
// ERROR: cannot infer type for `.Member`
let x = .Member
//      ^^^^^^^ help: specify the type: `Role.Member`
```

**Auto-generated accessor methods:**

Every enum variant with data automatically generates accessor methods.
For a variant `Foo(T)`, the compiler generates:

```
fn is_foo(self: &MyEnum) -> bool
fn as_foo(self: MyEnum) -> Option[T]         // by value (moves)
fn as_foo_ref(self: &MyEnum) -> Option[&T]   // by shared ref
fn as_foo_mut(self: &mut MyEnum) -> Option[&mut T]  // by mutable ref
```

Method names are the variant name converted to `snake_case`.

```
type Token =
    | TInt(i64)
    | TStr(str)
    | TBool(bool)
    | TNull

// Auto-generated:
// .is_tint() -> bool
// .as_tint() -> Option[i64]           .as_tint_ref() -> Option[&i64]
// .as_tstr() -> Option[str]           .as_tstr_ref() -> Option[&str]
// .as_tbool() -> Option[bool]         .as_tbool_ref() -> Option[&bool>
// (no .as_tnull — no data)
```

The `_ref` variants are essential for navigating tree structures
without cloning:

```
type JsonValue =
    | Null | Bool(bool) | Number(f64) | Str(str)
    | Array(Vec[JsonValue]) | Object(HashMap[str, JsonValue])

// Navigate a JSON tree without cloning anything:
let stars = config
    .as_object_ref()?
    .get("meta")?
    .as_object_ref()?
    .get("stars")?
    .as_number_ref()
    ?? &0.0
```

These compose with optional chaining and `??`:

```
// Extract a value you know is there (test/prototype code)
let b = self.expect_token("bool")?.as_tbool() ?? unreachable()

// Safely check and extract by reference
let name = token.as_tstr_ref()?.to_upper()

// Filter a collection
let strings = tokens.iter()
    |> filter(|t| t.is_tstr())
    |> map(|t| t.as_tstr_ref().unwrap())
    |> collect()
```

For variants with multiple fields, `.as_variant()` returns
`Option[(A, B)]` (a tuple):

```
type Shape =
    | Circle(radius: f64)
    | Rectangle(w: f64, h: f64)

shape.as_circle()       // Option[f64]
shape.as_rectangle()    // Option[(f64, f64)]
```

Unit variants (no data) generate only `.is_variant()`.

These methods are generated unconditionally for all enums — no
`@[derive]` needed. They are always available.

### 4.5 Distinct Types

```
type UserId = distinct i64
type Meters = distinct f64
```

Zero-cost wrappers that prevent accidental mixing of semantically
different values.

### 4.6 Type Inference

Bidirectional, local inference. Inside function bodies, types are
inferred. At module boundaries, types must be explicit. Inference does
not cross compilation unit boundaries.

### 4.7 Ranges

```
0..10       // exclusive: 0, 1, 2, ..., 9
0..=10      // inclusive: 0, 1, 2, ..., 10
```

Ranges are values of type `Range[T]` or `RangeInclusive[T]`. They
implement `Iter[T]` for integer types and `Contains[T]` for ordered
types, making them usable in `for` loops, slicing, pattern matching,
and membership tests.

```
for i in 0..n:
    process(i)

let slice = data[2..5]         // elements at index 2, 3, 4

if x in 1..=100:               // membership test (§9.9)
    handle_valid(x)

match code
    200..=299 -> "success"
    400..=499 -> "client error"
    _         -> "other"
```

---

### 4.8 Tuples

Tuples are anonymous product types for quick groupings of values:

```
let pair: (i32, str) = (42, "hello")
let triple = (1.0, 2.0, 3.0)       // type inferred: (f64, f64, f64)
```

**Destructuring:**

```
let (x, y) = get_position()
let (first, _, third) = triple      // _ ignores a field
let (head, ..rest) = tuple5         // ..rest captures remaining
```

**Access by index:**

```
let x = pair.0                       // 42
let s = pair.1                       // "hello"
```

**Use in generics and containers:**

```
fn swap[A, B](pair: (A, B)) -> (B, A):
    (pair.1, pair.0)

// HashMap iteration yields (K, V) tuples
for (key, value) in map:
    println("{key}: {value}")

// Functions can return multiple values naturally
fn divmod(a: i32, b: i32) -> (i32, i32):
    (a / b, a % b)
```

**Ownership:** Tuples follow normal ownership rules. A tuple is
`Copy` if all elements are `Copy`. A tuple is `Send` if all elements
are `Send`. Ephemeral elements make the tuple ephemeral.

**Unit:** The unit type `Unit` is equivalent to the empty tuple `()`.

**Unit elision:** When a function, method, or variant constructor
expects a single argument of type `Unit`, the argument may be
omitted. The compiler inserts `()` automatically:

```
unwrap_or()   // desugars to .unwrap_or(())
Some()        // desugars to Some(())
```

In practice, `Ok()` is rarely needed because of implicit `Ok`
wrapping (§4.9). But Unit elision still helps with other types.

**Applicability:** Unit elision applies **only when the expected
parameter type is statically known to be `Unit`** at the call site
via bidirectional type inference. It does NOT apply to unconstrained
generics:

```
unwrap_or()          // OK: Option[Unit].unwrap_or → expected Unit

fn id[T](val: T) -> T: val
id()                 // ERROR: expected 1 argument, got 0
                     // T is unconstrained — elision does not apply
```

More examples:

```
// These patterns used to need Ok() — now just let the function end:
async fn send_email(to: &str, body: &str) -> Result[Unit, SmtpError]:
    transport.send(to, body).await?
    // implicit Ok(()) — just end the function

fn run_migrations -> Result[Unit, DbError]:
    for m in migrations:
        m.execute(&conn)?
    // implicit Ok(()) — no ceremony needed

// unwrap_or with Unit still uses elision
let _ = cache.set(key, value).await.unwrap_or()   // instead of .unwrap_or(())
```

### 4.9 Implicit `Ok` Wrapping

When a function's return type is `Result[T, E]`, the compiler
automatically wraps the final expression:

- If the last expression has type `T` (not `Result`), it's wrapped
  in `Ok(...)`.
- If the function returns `Result[Unit, E]` and the block ends with
  a statement (no trailing expression), `Ok(())` is returned.
- `?` still early-returns `Err` as normal.

```
// Before: manual Ok wrapping
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    let user = User.from_row(row)
    Ok(user)

// After: implicit Ok wrapping
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    User.from_row(row)                   // auto-wrapped in Ok(...)

// Result[Unit, E] — no trailing expression needed
fn save_all(items: &Vec[Item]) -> Result[Unit, DbError]:
    for item in items:
        db.insert(item)?
    // implicitly returns Ok(())

// Explicit Err still works normally
fn validate(age: i32) -> Result[Unit, ValidationError]:
    if age < 0 then return Err(.InvalidAge)
    if age > 150 then return Err(.InvalidAge)
    // implicitly returns Ok(())
```

**The rule is simple:** `?` handles the sad path. The happy path
just returns the value. No wrapping needed.

**When implicit wrapping does NOT apply:**

- If the last expression already has type `Result[T, E]`, no
  wrapping occurs (would produce `Result[Result[T, E], E]`).
- If the return type is not `Result`, implicit Ok wrapping doesn't
  apply (but see §4.10 for implicit default return).
- Explicit `Ok(...)` and `Err(...)` still work everywhere.

**Guideline:** Tuples above 3 elements should usually be replaced
with a named struct for readability. The compiler does not enforce
this, but `with fmt` may suggest it.

### 4.10 Implicit Default Return

When a function's return type implements the `Default` trait and the
body's last expression is `Unit` (a statement like `println`), the
compiler implicitly returns `T.default()`.

```
// Before: manual trailing 0
fn demo_strings -> i32:
    let hello = "Hello, C interop!"
    puts(hello)
    println("strlen = {strlen(hello)}")
    0                                      // annoying boilerplate

// After: implicit default return
fn demo_strings -> i32:
    let hello = "Hello, C interop!"
    puts(hello)
    println("strlen = {strlen(hello)}")
    // implicitly returns 0 (i32.default())
```

**The `Default` trait:**

```
trait Default:
    fn default -> Self
```

Built-in implementations:

| Type | `default()` |
|------|-------------|
| `i8`, `i16`, `i32`, `i64` | `0` |
| `u8`, `u16`, `u32`, `u64` | `0` |
| `usize` | `0` |
| `f32`, `f64` | `0.0` |
| `bool` | `false` |
| `str` | `""` |
| `Option[T]` | `None` |
| `Vec[T]` | empty vec |
| `HashMap[K, V]` | empty map |
| `HashSet[T]` | empty set |

User types can implement `Default` manually or via `@[derive(Default)]`
(requires all fields to implement `Default`):

```
@[derive(Default)]
type Config = {
    port: i32,          // defaults to 0
    debug: bool,        // defaults to false
    name: str,          // defaults to ""
}

fn make_config -> Config:
    println("Creating default config...")
    // implicitly returns Config.default()
```

**Interaction with implicit Ok wrapping:**

Both features compose. If the return type is `Result[T, E]` and the
body ends with a `Unit` statement, implicit Ok wrapping takes
priority (returns `Ok(T.default())` if `T` implements `Default`, or
`Ok(())` if `T` is `Unit`).

**When implicit default return does NOT apply:**

- If the last expression has a non-Unit type, no default insertion
  occurs (the expression is the return value as usual).
- If the return type does not implement `Default`, the compiler
  reports a type mismatch as usual.
- If the return type is `Unit`, no return value is needed (already
  handled).
- Explicit return values always work and are never overridden.

**Implicit unreachable on unproven paths:** If the compiler cannot
statically prove that all code paths return a value of the declared
return type, it silently inserts `unreachable` at the function exit.
If this path is reached at runtime, the program panics with a
diagnostic that includes file and line. You may add an explicit
`unreachable` for clarity, but it is never required.

---

## 5. Ephemeral Types

### 5.1 Definition

`ephemeral` is a type qualifier that marks a type as second-class.

```
type StrView = ephemeral { ptr: *const u8, len: usize }
```

Ephemeral values may exist as local bindings and function parameters.
They may be returned from functions (with propagation). They may be
captured by non-escaping closures.

Ephemeral values may NOT be stored in struct fields, enum variants,
heap containers, global storage, or escaping closures.

### 5.2 Propagation

Ephemerality propagates through type constructors:

- If `T` is ephemeral, then `Option[T]`, `Result[T, E]`, `(T, U)`,
  and any generic `F[T]` are ephemeral.
- If any field of a struct is ephemeral, the struct is ephemeral. A
  struct definition with ephemeral fields is rejected unless the
  struct itself is marked `ephemeral`.

### 5.3 Canonical Ephemeral Types

- References: `&T`, `&mut T`
- Views: `StrView` / `&str`, `&[T]`, `&mut [T]`
- Lock guards: `MutexGuard[T]`, `RwLockReadGuard[T]`, `RwLockWriteGuard[T]`
- Iterators over borrowed data

### 5.4 Views: Ephemeral vs Storable

View types are pointer-and-length values that reference memory they do
not own. They are ephemeral to prevent dangling.

For long-lived references into owned buffers, use offset-based types:

```
type BufSlice = { offset: usize, len: usize } with Copy
```

Pattern: structs store `BufSlice` (storable offsets); accessor methods
compute ephemeral `&str`/`&[u8]` on demand from an owned buffer.

```
type Request = {
    buf:     Bytes,
    path:    BufSlice,
    headers: Vec[Header],
}

extend Request:
    fn path_str(self: &Request) -> StrView:
        self.buf.view(self.path.offset, self.path.len)
```

---

### 5.5 Ephemeral Structs

Structs may be marked `ephemeral` to hold references and views.
This is the idiomatic pattern for parsers, tokenizers, iterators,
and any "processing context" that borrows from input data:

```
type Token = ephemeral {
    text: StrView,          // borrows from source
    kind: TokenKind,
    span: Span,
}

type Parser = ephemeral {
    source: StrView,        // borrows from input
    pos: usize,
}

fn next_token(parser: &mut Parser) -> Option[Token]:
    // ... returns Token borrowing from parser.source
```

Ephemeral structs follow all the same rules as ephemeral values
(§5.1): they can be local bindings, parameters, and return values,
but cannot be stored in long-lived containers or non-ephemeral
structs.

```
// OK: local use, pattern matching, passing around
let tok = next_token(&mut parser)?
match tok.kind
    .Ident   -> handle_ident(tok.text)
    .Number  -> handle_number(tok.text)
    .String  -> handle_string(tok.text)

// OK: for-loop processes each token — tok drops at iteration end
while let Some(tok) = next_token(&mut parser):
    process(tok)

// LIMITATION: Cannot collect ephemeral tokens into a Vec directly.
// Each Token borrows &mut parser (Rule 6, §21.1), so holding one
// Token prevents calling next_token() again.
//
// To collect, use owned tokens with offset indices:
type OwnedToken = { start: u32, end: u32, kind: TokenKind, span: Span }

fn next_owned_token(parser: &mut Parser) -> Option[OwnedToken]:
    let tok = next_raw_token(parser)?
    Some(OwnedToken { start: tok.start, end: tok.end, kind: tok.kind, span: tok.span })

let tokens = with Vec.new() as mut toks:
    while let Some(tok) = next_owned_token(&mut parser):
        toks.push(tok)    // OwnedToken is NOT ephemeral — no borrows
// tokens: Vec[OwnedToken] is storable

// ERROR: cannot store in a non-ephemeral struct
type Module = { tokens: Vec[Token] }   // REJECTED: ephemeral field
```

**When to use ephemeral structs vs tuples:**

| Values | Use |
|--------|-----|
| 2 unnamed values | Tuple: `(StrView, TokenKind)` |
| 3+ values, or named fields matter | Ephemeral struct: `Token { text, kind, span }` |
| Value must outlive its borrow | Storable struct with offsets (§5.4) |

Ephemeral structs are cheap — they're stack values with no heap
allocation, just like the references they contain.

---

## 6. Handles and Generational Arenas

### 6.1 Handles

A handle is a typed index with a generation counter.

```
type Handle[T] = { index: u32, generation: u32 }
    with Copy, Eq, Hash
```

Handles are `Copy`, type-parameterized (`Handle[Texture]` incompatible
with `Handle[Mesh]`), not an ownership relationship, and safe against
use-after-remove (generation mismatch returns `None`).

### 6.2 SlotMap (Standard Library Requirement)

The standard library must provide:

```
type SlotMap[T]
```

| Method | Signature | Notes |
|--------|-----------|-------|
| `insert` | `(&mut Self, T) -> Handle[T]` | |
| `get` | `(&Self, Handle[T]) -> Option[&T]` | Ephemeral return |
| `get_mut` | `(&mut Self, Handle[T]) -> Option[&mut T]` | Ephemeral return |
| `remove` | `(&mut Self, Handle[T]) -> Option[T]` | |
| `replace` | `(&mut Self, Handle[T], T) -> Option[T]` | |
| `for_each` | `(&Self, fn(Handle[T], &T))` | |
| `for_each_mut` | `(&mut Self, fn(Handle[T], &mut T))` | |
| `get2_mut` | `(&mut Self, Handle[T], Handle[T]) -> Option[(&mut T, &mut T)]` | `None` if equal |
| `contains` | `(&Self, Handle[T]) -> bool` | |
| `len` | `(&Self) -> usize` | |

### 6.3 Performance Characteristics

A handle dereference involves: one array index lookup, one bounds
check (branch, usually predicted), and one generation comparison
(branch, usually predicted). This is roughly 2-3ns per access versus
~0.3ns for a raw pointer dereference.

For bulk operations, use `for_each` / `iter` which amortize the
per-element overhead. In rare hot paths where handle indirection is
measurably costly, `unsafe` raw pointer access is available.

The trade-off is explicit: **safety over raw pointer speed** for
individual accesses, with batch iteration as the escape hatch for
performance-critical loops.

---

## 7. `with` — Scoped Access

`with` is the language's central construct. It means: **access this
value within this scope.** It appears in four forms, all expressing
the same idea — bounded, explicit interaction with data.

| Form | Meaning | Appears in |
|------|---------|------------|
| `with as name:` | Guarded access (lock, arena, file) | Concurrent/resource code |
| `with value as mut name:` | Scoped mutation (builder pattern) | Initialization, configuration |
| `with expr as name:` | Scoped binding (named temporary) | Pipelines, intermediate values |
| `{ expr with field: val }` | Record update (functional copy) | Data transformation |

### 7.1 Form 1: Guarded Access

When data lives behind a lock, arena, or resource guard, `with`
provides scoped access. If the expression's type implements
`Scoped` or `ScopedMut`, the compiler **automatically** dispatches
through the guard. No keyword needed — the type tells the compiler
everything.

```
with lock.read() as data:
    data.iter() |> filter(|x| x.active) |> count()

with db.connection() as conn:
    conn.query("SELECT * FROM users WHERE id = ?", user_id)

with world.entities[player_id] as mut player:
    player.health -= damage
    player.last_hit = now()
```

This form activates when the expression's type implements `Scoped`
or `ScopedMut`. The block body receives a reference. The reference
is ephemeral — it cannot escape the block.

**Traits:**

```
trait Scoped[T]:
    fn enter[R](self: &Self, f: fn(&T) -> R) -> R

trait ScopedMut[T]:
    fn enter_mut[R](self: &Self, f: fn(&mut T) -> R) -> R
```

**Desugaring:**
```
with lock.read() as data: body
// → lock.read().enter(|data| body)

with store.write() as mut data: body
// → store.write().enter_mut(|data| body)
```

Multiple guarded bindings are flat, nesting left-to-right:
```
with a.read() as textures,
     b.read() as meshes,
     c.write() as mut materials:
    body
// → a.read().enter(|textures|
//     b.read().enter(|meshes|
//       c.write().enter_mut(|materials| body)))
```

### 7.2 Form 2: Scoped Mutation (Builder Pattern)

When constructing a complex value, `with` provides a mutable scope
for staged initialization. The value is owned and mutable inside the
block, then returned as the block's result.

```
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3
    c.verbose = true

let request = with HttpRequest.new("GET", "/api/users") as mut r:
    r.header("Authorization", token)
    r.header("Accept", "application/json")
    r.timeout(Duration.seconds(30))

let sprite = with Sprite.new() as mut s:
    s.position = Vec2.new(100.0, 200.0)
    s.scale = Vec2.one()
    s.color = Color.white()
    s.layer = 5
```

**Implicit return rule:** In `with expr as mut x:`, if the block's
last statement evaluates to `Unit` (assignment, void method call),
the block returns `x` (the builder). If the last expression is
non-Unit, the block returns that expression's value.

```
// Builder: last statement is assignment → returns config
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3            // Unit → block returns c

// Extract: last expression is non-Unit → returns length
let len = with Vec.new() as mut v:
    v.push(1)
    v.push(2)
    v.len()                  // usize → block returns 2

// Builder with method that returns a value? Just add a trailing
// statement or use let _ = :
let config = with Config.default() as mut c:
    c.headers.insert("Auth", tok)   // returns Option[V]...
    c.timeout = 30                   // ...but this is Unit → returns c
```

This gives you both builder and extraction patterns from the same
construct. The type system tells you what you're getting.

This form is used when the expression's type does **not** implement
`Scoped`/`ScopedMut`. The value is bound as a mutable local inside
the block.

**Desugaring:**
```
let config = with Config.default() as mut c:
    c.timeout = 30
// → let config = { var c = Config.default(); c.timeout = 30; c }
```

This replaces the need for builder types, method chaining, or
mutable-then-freeze patterns. The mutation is visually contained
within the `with` block — nothing outside it can observe the
intermediate mutable state.

### 7.3 Form 3: Scoped Binding

When an intermediate computation needs a name for a small scope
without polluting the enclosing namespace, `with` provides a
scoped binding.

```
let damage = with calculate_armor_reduction(attacker, defender) as reduction:
    base_damage * (1.0 - reduction) + bonus_damage

let label = with user.display_name.unwrap_or(user.username) as name:
    "{name} ({user.role})"

let normalized = with vec.len() as len:
    if len > 1e-6 then vec.scale(1.0 / len) else Vec2.zero()
```

This form is used when the expression's type does not implement
`Scoped`/`ScopedMut` and `mut` is absent. The value is bound as
an immutable local.

**Desugaring:**
```
with expr as name: body
// → { let name = expr; body }
```

This is lightweight. It is equivalent to a `let` binding inside an
anonymous block, but reads more naturally in expression chains and
avoids name leakage.

### 7.4 Form 4: Record Update

Functional immutable update of struct fields. Defined in §4.3 and
included here for completeness.

```
let moved = { entity with position: new_pos }
let damaged = { player with health: player.health - 10 }
let config = { defaults with verbose: true, retries: 5 }
```

For `Copy` types, all fields are copied. For non-`Copy` types,
non-overridden fields are moved from the source (the source is
consumed).

### 7.5 Dispatch Rule

The `with` block form is determined by the **type** of the
expression:

```
// If expr implements Scoped → guarded access
with lock.read() as data:          →  expr.enter(|data| body)
with store.write() as mut data:    →  expr.enter_mut(|data| body)

// Otherwise → simple binding
with expr as mut name:             →  { var name = expr; body }
with expr as name:                 →  { let name = expr; body }
```

The compiler checks: does the expression's type implement `Scoped`
or `ScopedMut`? If yes, it's guarded access. If no, it's a simple
binding. No keyword needed — the type system does the work.

```
// Guarded access — lock.read() returns a Scoped type
with lock.write() as data:
    data.x = 1                         // guard released at block exit

// Builder — Config.default() doesn't implement Scoped
let config = with Config.default() as mut c:
    c.retries = 3
```

**Semver note:** If a library type adds `Scoped` or `ScopedMut`
in a new version, existing `with` blocks using that type will
change dispatch. This is intentional — implementing `Scoped` is a
deliberate API decision that says "this type is a guard." Types
don't implement `Scoped` by accident.

### 7.6 `with` as Expression

All forms of `with` are expressions. Their value is the value of
the body.

```
// Guarded access — result must be non-ephemeral
let count = with store.read() as textures:
    textures.iter() |> count()

// Builder — result is the configured value (implicit return)
let config = with Config.default() as mut c:
    c.timeout = 30

// Scoped binding — result is computed from the named value
let area = with shape.bounding_box() as bb:
    bb.width * bb.height
```

For guarded access (Form 1), the result must be non-ephemeral
(it cannot be a reference into the guarded data, since the guard
releases at block exit).

### 7.7 Control Flow Inside `with` Blocks

All `with` forms are **transparent for control flow** (analogous to
inline lambdas or non-escaping closures):

- **`return`** inside a `with` block returns from the **enclosing
  function**, not from the desugared closure.
- **`break`** and **`continue`** inside a `with` block within a loop
  affect the **enclosing loop**.
- **`?`** propagates errors to the **enclosing function**.

```
fn find_value(lock: &Mutex[HashMap[str, i32]], key: &str) -> Option[i32]:
    with lock.lock() as map:
        match map.get(key)
            Some(v) -> return Some(v)   // returns from find_value
            None    -> ()
    None

fn process_all(lock: &Mutex[Vec[Item]]) -> Result[Unit, AppError]:
    with lock.lock() as items:
        for item in items:
            if item.is_invalid():
                continue                 // continues enclosing for loop
            validate(item)?              // propagates to process_all
    // implicit Ok(())
```

This is possible because `with` blocks are always non-escaping and
synchronous — the compiler can inline the control flow transformation.
This is NOT a general property of closures; it applies only to `with`
blocks and other compiler-known non-escaping constructs.

### 7.8 `with` Frequency

In a typical codebase, `with` appears pervasively:

```
// Initializing a game entity (Form 2: builder)
let enemy = with Enemy.new(enemy_type) as mut e:
    e.position = spawn_point
    e.health = with difficulty.health_multiplier() as mult:  // Form 3: binding
        base_health * mult
    e.ai_state = AiState.Idle

// Updating game state (Form 1: guarded + Form 4: record update)
with world.entities[enemy.id] as mut entity:
    let new_pos = { entity.position with             // Form 4: record update
        x: entity.position.x + velocity.x * dt
    }
    entity.position = new_pos

// Building an HTTP response (Form 2: builder)
let response = with HttpResponse.new(200) as mut r:
    r.header("Content-Type", "application/json")
    r.body(json_encode(data))

// Processing a batch (Form 1: guarded + Form 3: binding)
with db.transaction() as tx:
    let results = users.traverse(|u|
        with calculate_discount(u.tier, u.years) as discount:  // Form 3
            tx.update_price(u.id, u.base_price * (1.0 - discount))
    )
    results?
```

### 7.9 `with` Idioms and Rules

**`@[no_await_guard]` enforcement is NLL-based, not syntax-based:**

Some synchronization guard types must not be held across suspension
points — holding a mutex lock while a fiber suspends blocks all
other fibers waiting for that lock. These types are annotated
`@[no_await_guard]`:

```
@[no_await_guard]
type MutexGuard[T] = { ... }

@[no_await_guard]
type ReadGuard[T] = { ... }

@[no_await_guard]
type WriteGuard[T] = { ... }
```

The compiler rejects `.await` **or any `may_suspend` function call**
while a `@[no_await_guard]` value is **live in the NLL sense** —
regardless of whether it was created via `with` or a plain
`let` binding (see Invariant 5, §14.3):

```
// ERROR: guard is live across .await (via with block)
with lock.read() as data:
    let result = fetch(data.url).await   // compile error E0701

// ERROR: guard is live across .await (via plain let binding)
let guard = lock.lock()
let data = guard.deref()
fetch(data.url).await                    // compile error E0701!
//              ^^^^^^ @[no_await_guard] MutexGuard is live

// ERROR: helper() is may_suspend (it contains .await internally)
with lock.read() as data:
    let result = helper(data.url)        // compile error E0701
    //           ^^^^^^ may_suspend function called while
    //                  @[no_await_guard] ReadGuard is live

// FIX: drop guard before awaiting
let snapshot = with lock.read() as data:
    data.clone()
// guard dropped here
let result = fetch(snapshot.url).await   // OK: no guard live
```

Other `Scoped` types — connection pools, transactions, file handles
— are not annotated and work naturally with `await`:

```
// OK: ConnectionPool's guard is NOT @[no_await_guard]
with self.pool.acquire() as conn:
    let row = conn.query("SELECT ...").await?   // fine
    Ok(row_to_user(row))

// OK: Transaction guard is NOT @[no_await_guard]
with conn.begin() as tx:
    tx.execute("INSERT ...").await?
    tx.execute("UPDATE ...").await?
    tx.commit()
```

This is the correct distinction. A connection pool lease does not
block other fibers from acquiring their own connections — holding it
across `await` is the entire point. A mutex lock does block other
fibers — holding it across `await` is almost always a bug.

| Type | `@[no_await_guard]` | `.await` in `with`? |
|------|---------------------|-------------------|
| `Mutex[T]` guard | Yes | **Error** |
| `RwLock[T]` guard | Yes | **Error** |
| `Arena` scope | Yes | **Error** |
| `ConnectionPool` lease | No | Fine |
| `Transaction` | No | Fine |
| `File` | No | Fine |

Standard library types that carry `@[no_await_guard]`: `MutexGuard`,
`ReadGuard`, `WriteGuard`, and `ArenaScope`. Library authors should
apply this annotation to any guard type that blocks shared access
while held.

Forms 2 and 3 (`with expr as mut name:` and `with expr as name:`
on non-`Scoped` types) are unaffected — they desugar to plain
`let`/`var` blocks with no guard to hold.

**Clone at boundary:**

Escaping data from a guarded `with` block requires the data to be
owned, not borrowed. This means cloning is the standard pattern for
extracting values from behind a guard:

```
// Clone at boundary: the idiomatic pattern
let name = with db.read() as users:
    users.get(id)
        .map(|u| u.name.clone())   // clone to escape the guard

// If the value is Copy, no explicit clone needed:
let count = with store.read() as data:
    data.len()                      // usize is Copy, escapes freely
```

This is by design — the clone marks the exact point where borrowed
data becomes owned data. Library authors should provide `.cloned()`
and `.copied()` convenience methods on iterators and Option/Result
to make this ergonomic.

---

## 8. Memory Management

### 8.1 No Garbage Collector

Memory is freed deterministically when owners go out of scope.

### 8.2 No Transparent Reference Counting

Reference counting exists only when explicitly used:
- `Rc[T]` — single-threaded
- `Arc[T]` — thread-safe

No hidden refcount operations.

### 8.3 Allocators

First-class. Standard library provides:
- `Arena` — region-based; all allocations freed at once
- `FrameArena` — resets each frame
- `PoolAllocator` — fixed-size blocks

Standard containers accept an optional allocator parameter.

**Ephemeral virality with allocators:** If a container is initialized
with a borrowed allocator (`&Arena`), the container stores the
reference internally and becomes **ephemeral** (§5.2). This means
it can only be used as a local variable — it cannot be stored in
structs or returned from functions:

```
fn example(arena: &FrameArena):
    // Vec borrows the arena → ephemeral
    var candidates = Vec.new_in(arena)
    candidates.push(1)           // OK: used as local
    // candidates cannot escape this scope

    // For storable containers, use an owned allocator handle:
    var stored = Vec.new_in(Rc.clone(&shared_arena))
    // stored is NOT ephemeral — it owns its allocator handle
```

This is a deliberate consequence of the ephemeral system: borrowed
resources create ephemeral containers, owned resources create
storable ones. The compiler enforces this automatically.

### 8.4 Convenience Type

```
type Shared[T] = Arc[RwLock[T]]
```

Implements `Scoped[T]` and `ScopedMut[T]` for `with` blocks.

---

## 9. Functions and Expressions

### 9.1 Functions

```
fn add(a: i32, b: i32) -> i32: a + b

fn clamp(x: i32, lo: i32, hi: i32) -> i32:
    if x < lo then lo
    else if x > hi then hi
    else x
```

**Syntax:**

```
fn NAME(PARAMS) -> TYPE: BODY    // parameters + return type
fn NAME(PARAMS): BODY            // parameters, returns Unit
fn NAME -> TYPE: BODY            // no parameters, has return type
fn NAME: BODY                    // no parameters, returns Unit
```

Parentheses are required when a function takes parameters. When a
function takes no parameters, parentheses may be included or
omitted — `fn greet:` and `fn greet():` are both legal. The
idiomatic style omits them. The return type `-> TYPE` is omitted
when the function returns `Unit` (void). The colon `:` introduces
the body — either inline on the same line or indented on the next.

```
fn greet: println("hello")               // no args, no return type
fn greet(): println("hello")             // also legal, parens optional
fn get_pi -> f64: 3.14159                // no args, returns f64
fn double(x: i32) -> i32: x * 2         // args + return type
fn log(msg: str): println(msg)           // args, returns Unit
```

### 9.1a Default Function Parameters

Parameters may have default values, specified with `= expr` after the type annotation:

```
fn greet(name: str, greeting: str = "Hello"):
    println("{greeting}, {name}!")

greet("Alice")              // greeting defaults to "Hello"
greet("Bob", "Hey")         // explicit override
```

**Rules:**
- Default parameters must appear after all non-default parameters.
- Default expressions are evaluated at the call site, not at the definition site.
- Only literal values and `__FILE__`/`__LINE__` are allowed as default expressions (phase 1).
- The compiler fills in missing trailing arguments from defaults at code generation time.

```
fn assert_eq(left: i32, right: i32, file: str = __FILE__, line: u32 = __LINE__):
    if left != right:
        println("assertion failed at {file}:{line}")
        abort()
```

### 9.2 Tail Call Optimization

Functions marked `@[tailrec]` are guaranteed to compile to loops.
If the function is not tail-recursive, the compiler rejects it.

```
@[tailrec]
fn factorial(n: Int, acc: Int) -> Int:
    match n
        0 -> acc
        _ -> factorial(n - 1, n * acc)
```

Mutual tail recursion supported when all functions in the cycle are
marked `@[tailrec]`. Non-tail-position recursive calls in a
`@[tailrec]` function are compile errors.

### 9.3 Closures

```
|x| x + 1
|x, y| x * y
|| println("hello")
```

Implicit `it` parameter (see §9.3.1):
```
items |> filter(it.age > 21) |> map(it.name)
```

#### 9.3.1 Implicit `it` Parameter

When a function expects a single-parameter closure, the expression can
use `it` to refer to the implicit parameter instead of declaring an
explicit closure with `|param|` syntax:

```
items |> filter(it.age > 21)     // equivalent to |x| x.age > 21
items |> map(it.name)            // equivalent to |x| x.name
items |> filter(it % 2 == 0)    // equivalent to |n| n % 2 == 0
items |> sort_by(it.score)       // equivalent to |x| x.score
```

`it` is a reserved keyword. It may only appear in expression positions
where the surrounding call site expects a single-parameter function type.
The compiler infers `it`'s type from the expected function parameter type.

**Nested `it` is forbidden:** If an `it`-expression appears inside
another `it`-expression, the inner closure must use explicit `|param|`
syntax. This prevents ambiguity about which closure level `it` refers to.

```
// OK: outer uses it, inner uses explicit parameter
items |> map(it.children |> filter(|c| c.active))

// ERROR: nested it is ambiguous
items |> map(it.children |> filter(it.active))
```

**`_` is not a closure placeholder.** `_` means discard (in patterns)
or placeholder (in partial application). For closure shorthand, `it` is
the one way.

### 9.4 Partial Application

Functions can be partially applied with `_` as placeholder:

```
fn add(a: i32, b: i32) -> i32: a + b
let add5 = add(5, _)        // fn(i32) -> i32
add5(3)                      // 8

values |> map(clamp(0, 255, _))
```

Currying is not automatic. Partial application via `_` is the explicit,
controlled equivalent.

### 9.5 Extension Blocks

```
extend Vec[T]:
    fn is_empty(self: &Vec[T]) -> bool: self.len() == 0
```

**Method call syntax** applies to all `self` parameter forms:

| First parameter | Call syntax | Semantics |
|-----------------|-------------|-----------|
| `self: &T` | `x.method()` | Borrows `x` immutably |
| `self: &mut T` | `x.method()` | Borrows `x` mutably |
| `self: T` | `x.method()` | Moves (consumes) `x` |

**By-value `self` enables consuming method chains:**

```
type Builder = { host: str, port: u16 }

extend Builder:
    fn host(self: Builder, h: str) -> Builder: { self with host: h }
    fn port(self: Builder, p: u16) -> Builder: { self with port: p }
    fn build(self: Builder) -> Result[Server, ConfigError]: ...

// Dot-notation chains naturally — each call moves the builder
let server = Builder.new()
    .host("localhost")
    .port(8080)
    .build()?
```

This eliminates the need for pipeline placeholder syntax in builder
patterns. The pipeline operator `|>` remains available for free
functions and partial application.

**When to use which builder pattern:**

| Pattern | Best for | Example |
|---------|----------|---------|
| `with ... as mut` (§7.2) | Configuring fields on an existing struct with defaults | `with Config.default() as mut c: c.timeout = 30` |
| Method chains (§9.5) | Progressive construction with type-state, validation, or multiple steps | `Builder.new().host("x").build()?` |

Use `with ... as mut` when you have a struct with default values and
just need to set some fields. Use method chains when each step
transforms or validates the builder, especially when `.build()`
can fail. Both are idiomatic — they solve different problems.

### 9.6 Pipeline and Composition Operators

**Pipeline (forward application):**
```
data |> parse |> validate? |> transform |> summarize
```

`x |> f(a)` desugars to `f(x, a)`. Left-associative.

**Backward application:**
```
println <| format("{}: {}", key, value)
```

`f <| x` desugars to `f(x)`. Right-associative. Useful for avoiding
parentheses in nested calls:

```
// These are equivalent:
assert(is_valid(parse(input)))
assert <| is_valid <| parse(input)
```

**Function composition:**
```
let process = parse >> validate >> transform
let prepare = transform << validate << parse
```

`f >> g` produces a function `|x| g(f(x))` (left-to-right).
`f << g` produces a function `|x| f(g(x))` (right-to-left).

Composition creates a closure. It has zero runtime cost beyond what
the closure itself has. Useful when building functions to pass to
`map`, `filter`, or store for later use:

```
let normalize = trim >> lowercase >> strip_accents
names |> map(normalize) |> collect[Vec]()
```

### 9.7 Pattern Matching

Pattern matching is the primary control flow for algebraic data types.
It is expression-oriented, exhaustive, and supports deep structural
matching.

**Basic:**
```
match shape
    Circle(r)         -> pi * r * r
    Rectangle(w, h)   -> w * h
    Triangle(a, b, c) -> herons_formula(a, b, c)
```

**Guards:**
```
match value
    x if x > 0 -> "positive"
    x if x < 0 -> "negative"
    _           -> "zero"
```

**Nested / deep patterns:**
```
match expr
    Add(Lit(a), Lit(b))                 -> Lit(a + b)
    Add(Lit(0), rhs)                    -> rhs
    Mul(Lit(0), _) | Mul(_, Lit(0))     -> Lit(0)
    other                               -> other
```

**Or-patterns** share a body:
```
match day
    Monday | Tuesday | Wednesday | Thursday | Friday -> "weekday"
    Saturday | Sunday -> "weekend"
```

**`@` binding:**
```
match event
    click @ MouseClick { button: Left, pos } ->
        log("click at {pos}")
        handle(click)
```

**Literal and range patterns:**
```
match status_code
    200         -> "ok"
    301 | 302   -> "redirect"
    400..=499   -> "client error"
    _           -> "unknown"
```

**`in` patterns:**

An `in` pattern matches when the scrutinee is contained in the given
expression. It works with any `Contains` type — arrays, ranges, sets,
or user types:

```
match method
    in ["map", "filter", "take", "skip"] -> handle_lazy()
    in ["collect", "fold", "sum", "count"] -> handle_eager()
    _ -> handle_other()
```

This is syntactic sugar for a guard:

```
match method
    m if m in ["map", "filter", "take", "skip"] -> handle_lazy()
    m if m in ["collect", "fold", "sum", "count"] -> handle_eager()
    _ -> handle_other()
```

The `in` pattern does not introduce a binding. Use `@` if you need
one:

```
match status_code
    code @ in 200..=299 -> log("success: {code}")
    code @ in 400..=499 -> log("client error: {code}")
    code @ in 500..=599 -> log("server error: {code}")
    other               -> log("unexpected: {other}")
```

`in` patterns compose naturally with other match features:

```
fn categorize(token: TokenKind) -> Category:
    match token
        in [Plus, Minus, Star, Slash]  -> .Operator
        in [LParen, RParen, LBrace, RBrace] -> .Delimiter
        in [If, Else, While, For, Match]    -> .Keyword
        Ident(_)                             -> .Identifier
        IntLit(_) | FloatLit(_)              -> .Literal
        _                                    -> .Other
```

**Struct patterns with `..` rest:**
```
match user
    { name, age } if age >= 18 -> grant_access(name)
    { name, .. }               -> deny_access(name)
```

**Tuple patterns:**
```
match (x, y)
    (0, 0) -> "origin"
    (x, 0) -> "x-axis at {x}"
    _      -> "elsewhere"
```

**Slice patterns:**
```
match items
    []              -> "empty"
    [only]          -> "single"
    [first, ..rest] -> "head: {first}, {rest.len()} more"
```

**`let` destructuring:**

All pattern forms are available in `let`/`var` bindings:

```
// Tuple destructuring
let (x, y, z) = compute_position()
let (first, _) = split_first(text)       // _ ignores a field
let (head, ..tail) = get_items()          // ..rest captures remaining

// Struct destructuring
let { name, age, .. } = get_user()        // .. ignores remaining fields
let { x, y } = point                      // field shorthand in patterns too

// Slice destructuring
let [first, second, ..rest] = items

// Nested destructuring
let (Ok({ name, email, .. }), status) = (parse_user(data), 200)
```

**`let ... else` (refutable patterns):**

When a pattern might not match, `let ... else` provides the
fallback. The `else` branch must diverge (`return`, `break`,
`continue`, `panic`):

```
let Some(user) = find_user(id) else return Err(.NotFound)
let Ok(value) = try_parse(input) else return Err(.ParseError)
let [first, ..rest] = items else return Err(.Empty)
```

**`if let`:**
```
if let Some(user) = find_user(id):
    println("found: {user.name}")
```

**Chained `if let`:** Multiple conditional bindings in a single `if`,
separated by commas. All bindings must succeed for the body to
execute. This eliminates the pyramid of doom:

```
// Before: nested if let
if let Some(b) = b_store.get(entity):
    if let Some(c) = c_store.get(entity):
        yield (entity, a, b, c)

// After: chained if let
if let Some(b) = b_store.get(entity),
   let Some(c) = c_store.get(entity):
    yield (entity, a, b, c)
```

Chains can mix `let` bindings with boolean conditions:

```
if let Some(user) = find_user(id),
   user.is_active(),
   let Some(email) = user.email:
    send_welcome(email)
```

Each binding in the chain is in scope for subsequent bindings and
the body. If any binding fails, the entire `if` is skipped (or the
`else` branch runs).

**`let ... else` with enum shorthand:**

`let ... else` works especially well with enum variant shorthand
for asserting expectations:

```
let .TString(key) = self.expect_token("object key")? else
    return Err(.UnexpectedChar(self.pos))

let .Colon = self.expect_token("':'")? else
    return Err(.UnexpectedChar(self.pos))

// Cleaner than the match equivalent
```

**Pattern matching in function parameters:**
```
fn distance({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point) -> f64:
    let dx = x2 - x1
    let dy = y2 - y1
    (dx * dx + dy * dy).sqrt()

fn origin: Point { x: 0.0, y: 0.0 }

fn head([first, ..]: &[T]) -> Option[&T]: Some(first)
fn head([]: &[T]) -> Option[&T]: None
```

Parameter patterns desugar to a match on the parameter at the
function entry. They are sugar, not a separate mechanism. Irrefutable
patterns (structs, tuples) need no special handling. Refutable
patterns (like slice patterns) require multiple function clauses or
an `else`.

**`match` in pipelines:**
```
let result = input |> parse |> match
    Ok(ast)  -> transform(ast)
    Err(e)   -> default_ast()
```

**Destructuring in `for` loops:**
```
for (id, entity) in world.entities():
    process(id, entity)

for { name, age, .. } in users:
    println("{name}: {age}")
```

Exhaustiveness depends on position:

- **Expression-position match** (value is used/returned): must be exhaustive.
- **Statement-position match** (value ignored): may be partial; unmatched
  variants are a no-op.
- **`@[must_use]` types** (e.g. `Result`, `Task`): match must always be
  exhaustive or include an explicit `_ -> ...` catch-all arm, regardless
  of position. Partial match on `@[must_use]` types is a compile error.
  This prevents silently ignoring `Err` arms, which would contradict
  `@[must_use]` semantics.

Examples:

```
// expression-position: exhaustive required
let label = match status
    Ok(v) -> "ok"
    Err(e) -> "err"

// statement-position: partial allowed (non-must_use enum)
match event
    Click(pos) -> handle_click(pos)
    KeyDown(k) -> handle_key(k)
// other variants are ignored

// statement-position on @[must_use] type: catch-all required
match result
    Ok(v) -> process(v)
    _ -> {}                  // explicit: "I'm intentionally ignoring errors"
// without the _ arm, this would be a compile error
```

**Reference pattern ergonomics:** When a pattern is matched against
a reference type `&T`, the pattern automatically binds variables as
references to the inner fields. No explicit `&` is needed in the
pattern:

```
let items: Vec[(str, i32)] = vec![("alice", 1), ("bob", 2)]

// .iter() yields &(str, i32)
// Destructuring binds key: &str, val: &i32 automatically
for (key, val) in items:
    println("{key}: {val}")

// Equivalent explicit form (also valid but unnecessary):
for &(key, val) in items:
    println("{key}: {val}")

// Works with match on borrowed enums:
fn describe(opt: &Option[String]) -> &str:
    match opt
        Some(s) -> s       // s: &String, not String
        None    -> "none"
```

This rule applies transitively: matching `&(A, &B)` against a
pattern `(a, b)` gives `a: &A` and `b: &&B`. The compiler inserts
reference bindings to match the actual type. This is critical for
ergonomic iteration, since `for` loops with implicit `.iter()`
always yield references.

### 9.8 Pipeline DSL Patterns

The `|>` operator plus extension blocks plus closures is sufficient
to build fluent domain-specific APIs that read like language features.
No macros or special syntax required.

**Query DSL:**
```
let results = world
    |> query[Position, Velocity]()
    |> where(|(pos, _)| pos.x > 0.0)
    |> order_by(|(_, vel)| vel.magnitude())
    |> limit(100)
    |> collect[Vec]()
```

**HTTP request builder:**
```
let response = HttpClient.new()
    |> base_url("https://api.example.com")
    |> header("Authorization", "Bearer {token}")
    |> get("/users")
    |> query_param("page", "1")
    |> send()
    |> await?
```

**Shader pipeline:**
```
let shader = ShaderBuilder.new()
    |> vertex_input(VertexLayout.pos_normal_uv())
    |> uniform("camera", CameraUniforms)
    |> stage(ShaderStage.Vertex, vertex_main)
    |> stage(ShaderStage.Fragment, fragment_main)
    |> build()
```

These patterns require no language support beyond `|>`, extension
blocks, and closures. The gap between "library code" and "language
feature" is intentionally small in With — the pipeline operator makes
well-designed libraries feel like built-in syntax.

### 9.9 The `in` Operator

`in` is a boolean operator that tests membership. It works on any
type that implements the `Contains` trait. The compiler optimizes
literal cases to zero-allocation comparisons.

```
if method in ["map", "and_then", "filter", "map_err", "ok", "err"]:
    handle_combinator(method)
```

**Expression forms:**

```
expr in expr       → bool
expr not in expr   → bool
```

`in` is a binary operator at the same precedence level as comparison
operators (`==`, `!=`). Like comparisons, it is non-associative —
`a in b in c` is a compile error.

**Operator precedence** (low to high):

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `or` | Left |
| 2 | `and` | Left |
| 3 | `==`, `!=`, `in`, `not in` | Non-associative |
| 4 | `<`, `>`, `<=`, `>=` | Non-associative |
| 5 | `\|>` (pipeline) | Left |
| 6 | `\|` | Left |
| 7 | `^` | Left |
| 8 | `&` | Left |
| 9 | `<<`, `>>` | Left |
| 10 | `+`, `-`, `++`, `??` | Left |
| 11 | `*`, `/`, `%` | Left |
| 12 | Unary prefix (`not`, `-`, `&`, `&mut`) | — |
| 13 | Postfix (`.await`, `?`, `.field`, `[i]`, `()`) | Left |

This means:

```
x in list and y in list       // (x in list) and (y in list)
x + 1 in values               // (x + 1) in values
not x in list                  // not (x in list) — but prefer `x not in list`
```

`not in` is a single two-keyword operator, not `not (x in y)`.
This matches Python's `not in` and reads naturally:

```
if x in [1, 2, 3]:               // membership test
if x not in [1, 2, 3]:           // negated membership
if name in names:                 // variable collection
if ch in 'a'..='z':              // range membership
if key in map:                    // key existence
if "hello" in text:               // substring search
```

**Desugaring:** `x in collection` desugars to
`collection.contains(&x)`. `x not in collection` desugars to
`not collection.contains(&x)`. The `Contains` trait is defined in
§11.7.

**`not in` vs `not` + `in`:**

`not in` is parsed as a single operator, not as `not (expr in expr)`.
Both `x not in list` and `not x in list` produce the same result.
The `not in` form is idiomatic. The linter suggests `x not in y`
when it sees `not (x in y)`.

**Type checking:**

1. Left operand type `T`
2. Right operand type `C` where `C: Contains[T]`
3. Result type is `bool`

If `C` does not implement `Contains[T]`, the compiler emits:

```
error[E0277]: cannot test membership of `Foo` in `Bar`
  --> src/main.w:12:15
   |
12 |     if x in bar:
   |           ^^ `Bar` does not implement `Contains[Foo]`
   |
   = help: implement `Contains[Foo] for Bar`
```

**Type inference:** The right-hand side provides type context for the
left-hand side, just as with `==`:

```
if 42 in values:    // 42 inferred as element type of values
if .Red in colors:  // .Red inferred as enum variant matching element type
```

Literal arrays on the right infer element type from the left:

```
let x: u8 = 5
if x in [1, 2, 3]:  // array inferred as [u8; 3], elements as u8
```

**Compiler optimizations:**

*Literal array elimination.* When the right-hand side of `in` is an
array literal where all elements are compile-time constants, the
compiler eliminates the array entirely and emits a chain of
comparisons:

```
// Source:
if method in ["map", "and_then", "filter"]:

// Compiles to (no allocation, no array):
if method == "map" or method == "and_then" or method == "filter":
```

This applies to any array literal of constants: integers, floats,
strings, enum variants, bool. For small arrays (≤8 elements), this
is always done. For larger literal arrays, the compiler may emit a
switch/jump table or sorted binary search. The threshold is
implementation-defined.

*Range optimization.* Ranges are always optimized to two comparisons:

```
// Source:
if x in 1..=100:

// Compiles to:
if x >= 1 and x <= 100:
```

No `Contains` trait call, no range object allocation.

*HashSet / HashMap.* These go through the actual `.contains()` method,
which is O(1). No special compiler treatment needed.

**Interaction with `for` loops:**

`in` already appears in `for` loops (`for x in collection:`). The
`for` loop uses the `Iter` trait. The `in` operator uses the
`Contains` trait. The parser distinguishes them structurally:
`for PATTERN in EXPR:` is a loop, `EXPR in EXPR` is a membership
test. No ambiguity.

**Interaction with comprehensions:**

`in` in comprehensions is the `for` loop form, not the membership
test. The membership test appears in filter expressions:

```
[x * x for x in 0..10]              // for-in loop
[x for x in 0..100 if x in primes]  // for-in loop + membership test in filter
```

**Interaction with pipelines:**

`in` works naturally inside pipeline closures:

```
let valid = tokens
    |> filter(|t| t.kind in [Ident, Number, String])
    |> collect[Vec]()
```

**Interaction with match patterns:**

`in` patterns are described in §9.7. Range patterns (`400..=499`)
remain valid in match. There is no ambiguity because `in` patterns
always start with the `in` keyword.

**Examples:**

```
// Basic membership
let vowels = ['a', 'e', 'i', 'o', 'u']
if ch in vowels:
    println("vowel")

// String search
if "error" in log_line:
    alert(log_line)

if '@' in email:
    validate_email(email)

// Enum variant sets
type Color = Red | Green | Blue | Yellow | Cyan | Magenta

fn is_primary(c: Color) -> bool:
    c in [.Red, .Green, .Blue]

// Map key existence
if key in cache:
    cache[key]
else:
    let val = compute(key)
    cache[key] = val
    val

// Range checks
fn is_ascii_letter(c: char) -> bool:
    c in 'a'..='z' or c in 'A'..='Z'

fn is_valid_port(port: u16) -> bool:
    port in 1..=65535

// Filtering
let dangerous_ops = ["rm", "format", "drop", "truncate"]
let safe_commands = commands
    |> filter(|cmd| cmd.op not in dangerous_ops)
    |> collect[Vec]()

// Compound conditions
if user.role in ["admin", "moderator"] and action in allowed_actions:
    execute(action)
```

**Grammar:**

```
// Expression
in_expr     = expr "in" expr
            | expr "not" "in" expr

// Pattern (in match arms)
in_pattern  = "in" expr

// With @ binding
in_pattern  = IDENT "@" "in" expr
```

The `in` keyword is already reserved (used by `for`). `not` is
already a keyword. No new keywords needed.

---

## 10. Error Handling

### 10.1 Result and Option

```
type Result[T, E] = Ok(T) | Err(E)
type Option[T] = Some(T) | None
```

No exceptions. Errors are values.

**`@[must_use]`:** Both `Result` and `Option` are annotated
`@[must_use]`. Ignoring a `Result` silently swallows an error.
Ignoring an `Option` silently discards a value. Both produce
**warnings**:

```
// WARNING: unused Result — error may be silently swallowed
db.execute("DROP TABLE users")

// Fix: propagate, handle, or explicitly discard
db.execute("DROP TABLE users")?                    // propagate
db.execute("DROP TABLE users").unwrap_or(())       // handle
let _ = db.execute("DROP TABLE users")             // intentional discard
```

This catches the single most common class of "why isn't this
working?" bugs in systems code. `let _ = expr` makes intentional
discard visible and grep-able. Projects that want stricter
enforcement can promote `@[must_use]` warnings to errors via
`with.toml`:

```toml
[lint]
must_use = "error"    # promote to compile error
```

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
for example, parser result types or validation types.

### 10.3 Optional Chaining (`?.`)

The `?.` operator accesses a field or method on an `Option` or
`Result`, returning `None`/`Err` if the value is absent:

```
// Without optional chaining
let city = user.address.and_then(|a| a.city)

// With optional chaining
let city = user.address?.city

// Chains naturally
let zip = user.address?.city?.zip_code
```

**Desugaring:** The desugaring is **type-aware** to avoid producing
`Option[Option[T]]`:

- If `field` has type `U` (non-Optional): `expr?.field` → `expr.map(|v| v.field)` — result is `Option[U]`.
- If `field` has type `Option[U]`: `expr?.field` → `expr.and_then(|v| v.field)` — result is `Option[U]` (flattened).
- `expr?.method(args)` → `expr.and_then(|v| v.method(args))` when the method returns `Option`/`Result`.

```
type Address = { city: Option[str], zip: str }
type Profile = { address: Option[Address] }

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

**Desugaring:** `expr ?? default` desugars to `expr.unwrap_or(default)`.
The right-hand side is lazily evaluated (only computed if left is
`None`).

**Early exit form:** `??` can be followed by `return`, `break`, or
`continue` for early exit on `None`:

```
let user = find_user(id) ?? return Err(.NotFound)
let item = stack.pop() ?? break
let next = iter.next() ?? continue
```

This replaces the need for `if let` / `let-else` in the most common
cases. The desugaring is:

```
// user = find_user(id) ?? return Err(.NotFound)
// desugars to:
let user = match find_user(id)
    Some(v) -> v
    None -> return Err(.NotFound)
```

### 10.5 Option Combinators (Standard Library Requirement)

The standard library must provide these methods on `Option[T]`:

| Method | Signature | Description |
|--------|-----------|-------------|
| `map` | `(fn(T) -> U) -> Option[U]` | Transform the inner value |
| `and_then` | `(fn(T) -> Option[U]) -> Option[U]` | Chain fallible operations |
| `or_else` | `(fn() -> Option[T]) -> Option[T]` | Fallback provider |
| `unwrap_or` | `(T) -> T` | Default value |
| `unwrap_or_else` | `(fn() -> T) -> T` | Lazy default |
| `unwrap` | `() -> T` | Extract value; **panics** if `None` |
| `expect` | `(msg: &str) -> T` | Extract value; **panics** with message if `None` |
| `filter` | `(fn(&T) -> bool) -> Option[T]` | Keep if predicate holds |
| `is_some` | `() -> bool` | Check presence |
| `is_none` | `() -> bool` | Check absence |
| `zip` | `(Option[U]) -> Option[(T, U)]` | Combine two options |
| `unzip` | `() -> (Option[A], Option[B])` | Split paired option |
| `flatten` | `() -> Option[T]` where Self = `Option[Option[T]]` | Remove nesting |
| `cloned` | `() -> Option[T]` where T: Clone | Clone inner value |
| `inspect` | `(fn(&T)) -> Option[T]` | Side effect without consuming |
| `transpose` | `() -> Result[Option[T], E]` where Self = `Option[Result[T, E]]` | Swap Option/Result nesting |

**Examples:**
```
// Without combinators:
let name = match find_user(id)
    Some(user) -> match user.display_name
        Some(n) -> n
        None    -> user.username
    None -> "anonymous"

// With combinators:
let name = find_user(id)
    .and_then(|u| u.display_name.or_else(|| Some(u.username)))
    .unwrap_or("anonymous")
```

### 10.6 Result Combinators (Standard Library Requirement)

| Method | Signature | Description |
|--------|-----------|-------------|
| `map` | `(fn(T) -> U) -> Result[U, E]` | Transform Ok value |
| `map_err` | `(fn(E) -> F) -> Result[T, F]` | Transform Err value |
| `and_then` | `(fn(T) -> Result[U, E]) -> Result[U, E]` | Chain operations |
| `or_else` | `(fn(E) -> Result[T, F]) -> Result[T, F]` | Recover from error |
| `unwrap_or` | `(T) -> T` | Default on error |
| `unwrap_or_else` | `(fn(E) -> T) -> T` | Lazy default |
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
    .with_context(|| "failed to find user {id}")?
```

`ContextError[E]` implements `Error` when `E: Error`, and the
error chain is traversable via the `source` field:

```
type ContextError[E] = {
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
    .map_err(|e| AppError.Io(e))
    .and_then(|text| parse_config(text))
    .unwrap_or_else(|_| Config.default())
```

### 10.7 Collection Combinators: `sequence` and `traverse`

These bridge collections and Option/Result. They are among the most
frequently used combinators in functional programming and are required
in the standard library.

**`sequence`** converts a collection of wrappers into a wrapper of
a collection. If any element is `None` or `Err`, the whole result is:

```
// Vec[Option[T]] → Option[Vec[T]]
let inputs: Vec[Option[i32]] = vec![Some(1), Some(2), Some(3)]
let result = inputs.sequence()       // Some(vec![1, 2, 3])

let bad: Vec[Option[i32]] = vec![Some(1), None, Some(3)]
let result = bad.sequence()          // None

// Vec[Result[T, E]] → Result[Vec[T], E]
let results: Vec[Result[i32, str]] = vec![Ok(1), Ok(2), Ok(3)]
let all = results.sequence()         // Ok(vec![1, 2, 3])

let mixed: Vec[Result[i32, str]] = vec![Ok(1), Err("bad"), Ok(3)]
let all = mixed.sequence()           // Err("bad")
```

**`traverse`** maps a function over a collection, then sequences.
It is `map` + `sequence` fused into one pass:

```
// Apply a fallible function to each element, collect successes
// or fail on first error
let names = vec!["1", "2", "three"]
let parsed = names.traverse(|s| s.parse_int())
// Err(ParseError) — "three" fails

let names = vec!["1", "2", "3"]
let parsed = names.traverse(|s| s.parse_int())
// Ok(vec![1, 2, 3])
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

---

## 11. Traits

### 11.1 Definition and Implementation

```
trait Show:
    fn show(self: &Self) -> String

impl Show for Point:
    fn show(self: &Point) -> String: "({self.x}, {self.y})"
```

### 11.2 Generic Bounds

```
fn debug[T: Show + Hash](x: &T):
    println("{x.show()} (hash: {x.hash()})")
```

### 11.3 Static Dispatch by Default

Trait calls are monomorphized. Dynamic dispatch via explicit `dyn Trait`.

**Object safety:** A trait can be used as `dyn Trait` only if all
its methods are **object-safe**. A method is object-safe if:

1. It takes `self` by **reference** (`&Self` or `&mut Self`), OR
2. It takes `self` by value (`Self`) and the trait specifies
   `Self: Sized` — but `dyn Trait` is unsized, so by-value self
   methods are excluded from the vtable.

```
trait Drawable:
    fn draw(self: &Self)        // OK: &Self, object-safe
    fn name(self: &Self) -> str // OK: &Self, object-safe

trait Consumable:
    fn consume(self: Self)      // by-value self: NOT object-safe

let d: &dyn Drawable = &circle    // OK: all methods are object-safe
let c: &dyn Consumable = &item    // ERROR: consume() takes self by value
```

**By-value `self` behind `Box`:** To call a by-value method through
a trait object, wrap it in `Box[dyn Trait]`. The compiler generates
a shim that moves the value out of the box (which has a known
pointer size):

```
trait Builder:
    fn build(self: Self) -> Config     // by-value self
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

Supported: generic type parameters with bounds, multiple bounds,
default methods, async methods in traits.

Not supported in v1.0: associated types, higher-kinded types,
lifetime parameters on traits.

**Why associated types are deferred:** Associated types complicate
trait resolution and coherence rules. v1.0 prioritizes simplicity
and a correct, well-tested trait resolver over feature breadth.

**Impact of missing associated types:** The primary cost is in
iterator and collection traits. Without associated types, `Iter[T]`
requires the element type to be a type parameter on the trait rather
than an output type determined by the implementor. This means a type
cannot implement `Iter` for multiple element types, and the element
type must always be specified at the call site. In practice this
affects custom container types most:

```
// Without associated types, cannot do:
//   trait Container { type Item; fn get(...) -> &Self::Item }

// Instead, parameterize the implementing type:
type MyMap[K, V] = { ... }

impl Iter[(K, V)] for MyMap[K, V]: ...
```

Async methods in traits are **not affected** by this limitation —
they work because `async fn` lowers to `Task[T]`, not because of
associated types.

Associated types are a planned v2.0 feature. The standard library is
designed to avoid patterns that require them. Third-party library
authors should expect to restructure some APIs when they land.

### 11.7 Syntax Traits

Certain traits, when implemented, unlock participation in language
syntax. This is a deliberate design pattern: library types opt into
language constructs by implementing a known trait. The set of syntax
traits is **fixed and closed** — users cannot define new syntax hooks.

| Trait | Unlocks | Syntax |
|-------|---------|--------|
| `Iter[T]` | `for` loops | `for x in expr:` |
| `Contains[T]` | Membership test | `x in collection`, `x not in collection` |
| `Scoped[T]` | `with` blocks (guarded) | `with expr as name:` |
| `ScopedMut[T]` | `with` blocks (guarded, mutable) | `with expr as mut name:` |
| `Index[I, O]` | Subscript read | `expr[index]` |
| `IndexMut[I, O]` | Subscript write | `expr[index] = val` |
| `Add`, `Sub`, `Mul`, `Div`, `Neg` | Arithmetic operators | `a + b`, `-x`, etc. |
| `Eq`, `Ord` | Comparison operators | `a == b`, `a < b` |
| `Try[T, E]` | `?` operator | `expr?` |
| `Drop` | Destructor | automatic at scope exit |

**Examples:**

```
// A matrix type that supports m[row, col] syntax
type Matrix = { data: Vec[f64], rows: usize, cols: usize }

impl Index[(usize, usize), f64] for Matrix:
    fn index(self: &Self, (r, c): (usize, usize)) -> &f64:
        &self.data[r * self.cols + c]

let m = Matrix.new(3, 3)
let val = m[(1, 2)]    // calls Matrix::index
```

```
// A parser result that supports ? propagation
type ParseResult[T] = ParseOk(T, remaining: str)
                    | ParseErr(msg: str, pos: usize)

impl Try[T, ParseError] for ParseResult[T]:
    fn branch(self: Self) -> ControlFlow[ParseError, T]:
        match self
            ParseOk(v, _) -> ControlFlow.Continue(v)
            ParseErr(m, p) -> ControlFlow.Break(ParseError { msg: m, pos: p })

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
   implementation controls each syntactic form.
4. Pattern matching extensibility (Scala-style `unapply`) is **not
   included** in v1.0. It introduces hidden runtime behavior into
   match resolution and conflicts with exhaustiveness checking. This
   may be revisited in a future version.

**Arithmetic operator traits:**

```
trait Add[Rhs, Output]:
    fn add(self: Self, rhs: Rhs) -> Output

trait Sub[Rhs, Output]:
    fn sub(self: Self, rhs: Rhs) -> Output
trait Mul[Rhs, Output]:
    fn mul(self: Self, rhs: Rhs) -> Output
trait Div[Rhs, Output]:
    fn div(self: Self, rhs: Rhs) -> Output
trait Neg[Output]:
    fn neg(self: Self) -> Output
```

**One-implementation rule for operator output:** A type may implement

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
type Whitelist = { allowed: HashSet[str] }

impl Contains[str] for Whitelist:
    fn contains(self: &Self, value: &str) -> bool:
        value in self.allowed

if user.name in whitelist:
    grant_access()
```

**One-implementation rule for operator output:** A type may implement
`Add[Rhs, Output]` for a given `(Self, Rhs)` pair **at most once**.
The `Output` type is uniquely determined by `Self` and `Rhs`:

```
impl Add[Vector, Vector] for Vector: ...    // OK: Vector + Vector = Vector
impl Add[f32, Vector] for Vector: ...       // OK: Vector + f32 = Vector

impl Add[Vector, Matrix] for Vector: ...    // ERROR: conflicting Output
    // Vector + Vector already defined with Output = Vector
    // Cannot also be Output = Matrix
```

This is the same principle as the `Iter[T]` one-implementation
rule (§13.2). It substitutes for associated types in v1.0: given
`Self` and `Rhs`, the compiler determines `Output` unambiguously.
The compiler resolves `a + b` by looking up the unique `Output`
for `(typeof a, typeof b)` — no type annotation needed:

```
let v1 = Vector.new(1.0, 2.0)
let v2 = Vector.new(3.0, 4.0)
let v3 = v1 + v2              // Output uniquely determined: Vector
```

### 11.8 Derive

`@[derive(...)]` generates trait implementations based on a type's
structure. The following **structural traits** may be derived:

| Trait | Condition | Behavior |
|-------|-----------|----------|
| `Copy` | All fields are `Copy`, no `Drop` | Bitwise copy |
| `Clone` | All fields are `Clone` | Field-by-field clone |
| `Default` | All fields are `Default` | Field-by-field default |
| `Eq` | All fields are `Eq` | Field-by-field equality |
| `Hash` | All fields are `Hash` | Hash all fields in order |
| `Ord` | All fields are `Ord` | Lexicographic comparison |
| `Debug` | Always | "{TypeName} { field: value, ... }" |
| `Display` | Always (enums) | Variant name as string |

```
@[derive(Eq, Hash, Debug, Clone)]
type Point = { x: f64, y: f64 }

@[derive(Eq, Debug)]
type Role = Admin | Member | Guest
```

**`@[derive(all)]`** derives every structural trait the type
qualifies for:

```
@[derive(all)]
type Color = { r: u8, g: u8, b: u8, a: u8 }
// Derives: Copy, Clone, Default, Eq, Hash, Ord, Debug
// (all fields are u8, which implements all of these)

@[derive(all)]
type User = { name: str, email: str, age: i32 }
// Derives: Clone, Default, Eq, Hash, Debug
// (NOT Copy — String is not Copy)
// (NOT Ord — not all fields implement Ord by default)
```

`@[derive(all)]` is conservative — it only derives traits where all
fields satisfy the trait's requirements. If a field is added that
doesn't implement `Eq`, the type silently loses its derived `Eq`.
This is by design — no compile error, because `@[derive(all)]` means
"whatever you can."

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
type DatabaseConfig = {
    host: str,
    port: i32 = 5432,
    max_connections: i32 = 10,
    timeout: Duration = Duration.secs(30),
    ssl: bool = false,
}

// Generates:
// type DatabaseConfigBuilder = {
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

### 11.9 Debug Trait and `:?` Format Specifier

The `Debug` trait provides a programmer-facing string representation of a value:

```
trait Debug:
    fn debug(&self) -> str
```

Types can implement `Debug` manually or via `@[derive(Debug)]`. Derived
implementations produce `"TypeName { field1: value1, field2: value2 }"` for
structs and variant names for enums.

The `:?` format specifier in string interpolation calls the `debug()` method:

```
@[derive(Debug)]
type Point = { x: f64, y: f64 }

let p = Point { x: 1.0, y: 2.0 }
println("{p:?}")    // prints "Point { x: 1.0, y: 2.0 }"
```

If no `debug()` method is found, the value falls through to default formatting.

The `Display` trait (§11.7) is used for user-facing output via `println("{value}")`.
The `Debug` trait is used for programmer-facing output via `println("{value:?}")`.

---

## 12. Closures and Escaping

### 12.1 Non-Escaping Closures

A closure is **non-escaping** if passed directly as an argument to a
function that consumes it synchronously. Non-escaping closures may
capture ephemeral values.

### 12.2 Escaping Closures

A closure is **escaping** if stored, returned, or sent to another
thread. Escaping closures may NOT capture ephemeral values.

### 12.3 Precise Rules (v1.0)

A closure is non-escaping if and only if it appears as a **direct
argument to a function call**. All other closures are escaping.

Specifically, the following are all **escaping** in v1.0:

```
let f = |x| x + 1           // bound to a named variable: escaping
let closures = vec![|x| x]  // stored in a container: escaping
return |x| x + 1            // returned from function: escaping
some_struct.callback = |x| x // stored in a field: escaping
```

The following are **non-escaping**:

```
items.for_each(|x| println(x))      // direct argument: non-escaping
items |> filter(|x| x > 0)          // direct argument: non-escaping
with lock.read() as data:           // with block body: non-escaping
    data.iter() |> map(|x| x + 1)   // direct argument: non-escaping
```

This is deliberately conservative. A closure bound to a named local
variable is treated as escaping even if analysis could prove it never
escapes the scope. This avoids complex escape analysis in v1.0 and
can be relaxed in future versions.

---

## 13. Iteration and Collection Operations

### 13.1 Iterators Over Borrowed Data Are Ephemeral

Iterators holding references to collections are ephemeral. They can be
used in pipelines within scope but not stored, returned, or captured by
escaping closures.

**What this means in practice:** You cannot return an *opaque* lazy
iterator that borrows from its inputs (e.g., `-> impl Iter[StrView]`
or `-> dyn Iter[StrView]`). However, you CAN return a *concrete
ephemeral struct* that implements `Iter`:

```
// IMPOSSIBLE: opaque return type hides the ephemerality
fn find_matches(text: &str, pat: &str) -> dyn Iter[StrView]

// POSSIBLE: concrete ephemeral struct — caller inherits restriction
type MatchIter = ephemeral { text: StrView, pat: StrView, pos: usize }
impl Iter[StrView] for MatchIter: ...

fn find_matches(text: &str, pat: &str) -> MatchIter:
    MatchIter { text: text.as_view(), pat: pat.as_view(), pos: 0 }
// Caller's binding is ephemeral — cannot store, must use in this scope
```

The concrete ephemeral struct approach works because the caller can
see the type is ephemeral and inherits the restriction (Rule 8,
§22.1). The opaque approach fails because trait objects erase the
ephemerality, preventing the caller from knowing the restriction.

**Additional workarounds (when concrete ephemeral structs are too verbose):**

```
// 1. Collect into owned container (small allocation cost)
fn find_matches(text: &String, pat: &str) -> Vec[String]:
    text.split(pat) |> map(|s| s.to_string()) |> collect()

// 2. Generator that owns its data (lazy, no allocation)
gen fn find_matches(text: String, pat: String) -> String:
    for segment in text.split(&pat):
        yield segment.to_string()

// 3. Callback / visitor pattern (zero allocation, inversion of control)
fn find_matches(text: &String, pat: &str, f: fn(StrView)):
    for segment in text.split(pat):
        f(segment)

// 4. Process inline (no function boundary)
let results = text.split(pat)
    |> filter(|s| s.len() > 0)
    |> map(|s| s.to_string())
    |> collect[Vec]()
```

This trade-off is fundamental to With's design. Rust allows returning
borrowing iterators at the cost of lifetime annotations on every struct
and function in the chain. With eliminates those annotations at the
cost of occasional allocation or ownership transfer at function
boundaries. For most code, the ergonomic difference is small. For
zero-copy parsing pipelines, it is real.

### 13.2 The Iterator Trait

```
trait Iter[T]:
    fn next(self: &mut Self) -> Option[T]
```

**One-implementation rule:** A type may implement `Iter[T]` for
**at most one `T`**. This ensures that `for x in expr:` always has
unambiguous type inference — the compiler knows exactly what type
`x` is without annotation:

```
// OK: Vec[i32]'s iterator yields &i32
for x in my_vec:
    println(x)           // x: &i32, unambiguous

// ERROR: conflicting Iter implementations
impl Iter[u8] for MyBuffer: ...
impl Iter[String] for MyBuffer: ...   // REJECTED: MyBuffer already implements Iter[u8]
```

This restriction replaces the need for associated types on `Iter`
in v1.0. A type that genuinely needs to yield different element
types should provide named methods returning different iterator
types (e.g., `.bytes() -> ByteIter`, `.lines() -> LineIter`).

**Iterators just work.** The compiler has built-in knowledge of
stdlib collection iterators (Vec, HashMap, Slice, etc.). When
`next()` returns a reference, the compiler knows the reference
borrows the *underlying collection*, not the iterator struct itself.
This means normal iteration patterns work naturally:

```
let iter = names.iter()
let a = iter.next()   // borrows from names, not iter
let b = iter.next()   // OK — iter is not locked by a
process(a, b)         // both references live simultaneously
```

`for` loops, `.zip()`, `.peekable()`, `.windows()` — all work as
you'd expect. The compiler is smart. If you hit an edge case with a
custom iterator, the worst that happens is a conservative borrow
error with a clear message.

### 13.3 Collection Operations (Standard Library)

**Transformations** (lazy, produce iterators):

| Operation | Description |
|-----------|-------------|
| `map(fn(T) -> U)` | Transform each element |
| `filter(fn(&T) -> bool)` | Keep matching elements |
| `filter_map(fn(T) -> Option[U])` | Transform + filter |
| `flat_map(fn(T) -> Iter[U])` | Map then flatten |
| `flatten()` | Flatten nested iterators |
| `take(n)` | First n elements |
| `drop(n)` | Skip first n |
| `take_while(fn(&T) -> bool)` | Take while predicate holds |
| `drop_while(fn(&T) -> bool)` | Skip while predicate holds |
| `zip(Iter[U])` | Pair from two iterators |
| `enumerate()` | Attach index |
| `chain(Iter[T])` | Concatenate |
| `peekable()` | Allow lookahead |
| `chunks(n)` | Fixed-size groups |
| `windows(n)` | Sliding window |
| `dedup()` | Remove consecutive duplicates |
| `unique()` | Remove all duplicates |
| `intersperse(sep)` | Insert separator |
| `scan(init, fn(S, T) -> (S, U))` | Stateful map |
| `step_by(n)` | Every nth element |
| `zip_with(Iter[U], fn(T, U) -> V)` | Zip and transform in one step |

**Consumers** (eager, produce final value):

| Operation | Description |
|-----------|-------------|
| `collect[C]()` | Build a collection |
| `reduce(fn(T, T) -> T)` | Reduce with first element as initial |
| `fold(init, fn(U, T) -> U)` | Fold with explicit initial |
| `sum()` / `product()` | Arithmetic aggregation |
| `count()` | Count elements |
| `min()` / `max()` | Extremes |
| `min_by(cmp)` / `max_by(cmp)` | By custom comparison |
| `find(fn(&T) -> bool)` | First match |
| `position(fn(&T) -> bool)` | Index of first match |
| `any(pred)` / `all(pred)` / `none(pred)` | Boolean tests |
| `for_each(fn(T))` | Side effect per element |
| `join(sep)` | Join as string |
| `sorted()` / `sorted_by(cmp)` | Collect and sort |
| `group_by(fn(&T) -> K)` | Group into buckets |
| `partition(fn(&T) -> bool)` | Split by predicate |
| `unzip()` | Separate pairs |

**Standalone iterator constructors** (not methods on existing iterators):

| Constructor | Description |
|-------------|-------------|
| `Iter.empty()` | Empty iterator |
| `Iter.once(value)` | Single element |
| `Iter.repeat(value)` | Infinite repetition |
| `Iter.unfold(init, fn(S) -> Option[(T, S)])` | Generate from state |
| `Iter.from_fn(fn() -> Option[T])` | Generate from closure |

**Examples:**
```
let total = numbers.iter() |> fold(0, |acc, x| acc + x)

let words = lines.iter()
    |> flat_map(|line| line.split(' '))
    |> collect[Vec[String]]()

let (adults, minors) = people.iter()
    |> partition(|p| p.age >= 18)

// zip_with: combine two iterators with a function
let distances = xs.iter()
    |> zip_with(ys.iter(), |x, y| (x - y).abs())
    |> collect[Vec]()

// unfold: generate sequence from state
let powers_of_2 = Iter.unfold(1, |n| Some((n, n * 2)))
    |> take(10) |> collect[Vec]()
// [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]

let report = transactions.iter()
    |> filter(|t| t.amount > 100.0)
    |> sorted_by(|a, b| b.date.cmp(a.date))
    |> take(10)
    |> map(|t| "{t.date}: ${t.amount}")
    |> join("\n")
```

**HashMap convenience methods:**

Beyond the standard iterator operations, `HashMap` provides
ergonomic mutation methods:

```
// Entry API (Rust-style)
worker_counts.entry(id).or_insert(0)

// Convenience: update with default and transform
worker_counts.update(id, 0, |n| n + 1)
// equivalent to: entry(id).or_insert(0); *entry += 1

// Convenience: increment/decrement
worker_counts.increment(id)       // .update(id, 0, |n| n + 1)
worker_counts.decrement(id)       // .update(id, 0, |n| n - 1)

// Convenience: append to collection values
event_log.append(user_id, event)  // .entry(id).or_insert(Vec.new()).push(event)
```

These methods cover the most common HashMap mutation patterns
without requiring the entry API's verbose ceremony.

### 13.4 Generators (`yield`)

Generators produce sequences lazily, suspending between each `yield`.

```
gen fn fibonacci -> Int:
    var a = 0
    var b = 1
    loop:
        yield a
        let next = a + b
        a = b
        b = next

let first_10 = fibonacci() |> take(10) |> collect[Vec]()
```

Generators are declared with `gen fn`, use `yield`, and return
iterators implementing `Iter[T]`.

**Return type convention:** In `gen fn f -> T`, the `-> T`
specifies the **yielded element type**, not the function's actual
return type. The function actually returns an opaque iterator
(`impl Iter[T]`). This is analogous to `async fn f -> T`
meaning "returns `Task[T]`" — the keyword modifies the return
type's meaning:

```
gen fn fibonacci -> Int: ...
// Actual type of fibonacci(): impl Iter[Int]
// Each yield produces an Int

async fn fetch(url: str) -> String: ...
// Actual type of fetch(url): Task[String]
```

**Compilation model:** Generators compile to **state machines**, not
fibers. They do not use the fiber scheduler. They do not imply async.
They are pure, synchronous iteration constructs. The compiler
transforms each `yield` point into a state transition, and the
generator's local variables become fields of the state machine struct.
This is a compile-time transformation with zero runtime overhead beyond
the state struct itself.

**No references across `yield` points.** Because generator locals
become fields of the state machine struct, a reference to a local
variable that is live across a `yield` would create a self-referential
struct (the struct contains both the field and a pointer to it).
Since With has no `Pin`, this is forbidden:

```
gen fn bad_generator -> &str:
    let s = "hello".to_owned()
    let r = &s           // r borrows s
    yield r              // ERROR: reference `r` to local `s` is live across yield

gen fn ok_generator -> str:
    let s = "hello".to_owned()
    yield s.clone()      // OK: yields an owned value
    let r = &s           // OK: r does not cross a yield
    println(r)
```

This restriction does NOT apply to `async fn` — fibers have real
stacks that don't move, so references across `.await` are safe
(§14.13). Generators are the exception because they compile to
movable structs.

**Zero-copy iteration:** Generators cannot yield references to
their own locals, which means `gen fn tokenize(src: &str) -> &str`
that yields slices of `src` is impossible (src is stored in the
state machine, yielding a slice creates a self-referential struct).
For zero-copy iteration that yields references, use **concrete
ephemeral iterator structs** (§5.5, §13.1) or the **callback/visitor
pattern**. Generators are best for owned-value sequences (Fibonacci,
generated data, transformations).

```
// Zero-copy: ephemeral iterator struct
type TokenIter = ephemeral { source: StrView, pos: usize }
impl Iter[StrView] for TokenIter: ...

// Zero-copy: callback pattern
fn each_token(src: &str, f: fn(StrView)): ...
```

**Generators are not coroutines.** They are pull-based (the caller
drives iteration by calling `next()`), not push-based (no scheduler
involved). They cannot use `.await`. They cannot be suspended by the
runtime.

**Escaping rules:**

- A `gen fn` that captures **no references** produces a storable
  iterator. It can be stored in structs, returned from functions,
  and passed to other threads (if `Send`).
- A `gen fn` that captures **references** is ephemeral. It follows
  the same rules as any other ephemeral value.
- A `gen fn` with **no captures at all** (including the common case
  of generators that only use their parameters) is always storable.

**State allocation:** Generator state is stack-allocated at the call
site. It is moved to the heap only if explicitly boxed by the user.

### 13.5 For-In Loops

```
for item in collection:
    process(item)

for (i, item) in collection.enumerate():
    println("{i}: {item}")
```

**Implicit iteration:** When the expression after `in` implements
`Iter[T]` directly (e.g., ranges, iterators), it is used as-is.
When it does not implement `Iter[T]` but has an `.iter()` method
that returns an `Iter[T]`, the compiler inserts `.iter()`
automatically:

```
// These are equivalent:
for item in my_vec:           // compiler inserts .iter()
for item in my_vec.iter():    // explicit (also valid)

// For mutable or consuming iteration, be explicit:
for item in my_vec.iter_mut():    // mutable references
for item in my_vec.into_iter():   // consuming (moves elements)
```

`for x in expr: body` desugars to calling `next()` in a loop.
The implicit `.iter()` insertion means `for x in collection:`
borrows the collection immutably — the collection remains valid
after the loop.

### 13.6 Collection Comprehensions

Comprehensions build collections from iteration with filtering:

```
let squares = [x * x for x in 0..10]
// [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]

let evens = [x for x in 0..100 if x % 2 == 0]
// [0, 2, 4, ..., 98]

let coords = [(x, y) for x in 0..3 for y in 0..3 if x != y]
// [(0,1), (0,2), (1,0), (1,2), (2,0), (2,1)]
```

**Desugaring:**

```
[expr for x in iter if cond]
// →
iter |> filter(|x| cond) |> map(|x| expr) |> collect[Vec]()
```

Yes, this allocates a `Vec`. It's obvious from the syntax — you're
building a list. This is the same philosophy as string interpolation:
the allocation is inherent to what you're asking for, and the syntax
makes it clear.

Comprehensions are pure sugar. For lazy evaluation, use pipeline
syntax with iterators directly.

**Disambiguation with `in` operator:** In comprehensions, `for x in`
is always the iteration form (`Iter` trait). The `in` membership
operator (§9.9) may appear in the `if` filter clause:

```
[x for x in 0..100 if x in primes]  // for-in loop + membership test in filter
```

The parser resolves this structurally — `for PATTERN in EXPR` is
always iteration, `EXPR in EXPR` in the filter is always membership.

---

## 14. Concurrency

### 14.1 Design Principles

Three hard constraints govern the concurrency model:

1. **Suspension must be visible.** A systems programmer must see where
   a function can yield. Hidden suspension violates "predictable from
   source." This rules out Go-style implicit yielding.

   **Controlled exception:** Dropping an ephemeral `Task` without
   explicit `.await` or `cancel` may yield the current fiber (§14.7)
   to ensure memory safety. This is the only implicit suspension
   point in the language. The compiler emits a **warning** at any
   scope exit where an ephemeral Task is implicitly dropped without
   being awaited or cancelled, recommending explicit handling.
   Ephemeral Tasks cannot be created on OS threads or in FFI
   callbacks, because these contexts cannot suspend.

2. **No colored functions.** A function's callability must not depend on
   whether the caller is "async." This rules out Rust-style async.

3. **No type-system infection.** Concurrency must not introduce new
   trait bounds, wrapper types, or lifetime complications into code
   that doesn't need them.

The solution: `async`/`await` keywords that compile to **lightweight
thread (fiber) operations**, not state machine transformations.

### 14.2 What `async`/`.await` Mean in With

`async fn` declares a function that may suspend. Calling it spawns a
lightweight thread and returns a `Task[T]` handle immediately. `.await`
suspends the current fiber until a task completes.

```
async fn fetch_user(id: UserId) -> Result[User, ApiError]:
    let resp = http.get("/users/{id}").await
    let body = resp.read_body().await
    json.decode(body)?
```

`.await` is postfix, chaining naturally with `?` and `|>`:

```
// Postfix .await chains cleanly with ? and method calls
let user = pool.acquire().await?.query("SELECT ...").await?

// Compare with prefix await (not used in With):
// let user = await (await pool.acquire())?.query("SELECT ...")?
```

Each fiber has a **real stack**. References across `.await` points work
normally — they live on the stack, not in a compiler-generated struct.
No Pin, no Unpin, no Future, no Poll. These concepts do not exist in
With.

### 14.3 Formal Invariants

The following are **hard guarantees** that may never be violated:

**INVARIANT 1: No async function type exists.**
A function containing `await` does not change its type signature.
There is no `async fn` type distinct from `fn`. There is no trait
bound, wrapper type, or lifetime complication introduced by using
`.await`. Calling an `async fn` from a non-async `fn` is permitted —
the call spawns a fiber and returns a `Task[T]`, which the caller
may store, pass, or later `.await`.

**What "no colored functions" means here:** In Rust, an `async fn`
cannot be called from a non-async context without an executor and
explicit block-on machinery. In With, any function can call any
`async fn` — the call returns a `Task[T]` and execution continues.
The function is not "infected" by the call.

**What it does not mean:** `await` itself requires a fiber runtime.
Using `.await` in a `no_runtime` build is a compile error (Invariant
4). This is narrower than Rust's coloring: the restriction is on
*suspending*, not on *calling* async functions. A function that calls
`fetch_user(id)` but never awaits the result works in any build.
Only the `.await` operator is gated.

**INVARIANT 2: No Future trait exists.**
`Task[T]` is an opaque handle. It has no `poll` method, no `Waker`,
no `Pin<&mut Self>`. It is not a trait. It cannot be implemented.

**INVARIANT 3: No pluggable executors.**
There is exactly one fiber scheduler. It is part of the standard
library. It is not a trait. It cannot be replaced. This prevents
ecosystem fragmentation.

**INVARIANT 4: `async` requires the fiber runtime.**
On `no_runtime` targets (embedded, bare-metal), `async fn` is a
**compile error**. This is not a fallback — it is a hard gate. If
you see `async` in the source, a fiber scheduler exists. If no
scheduler exists, `async` does not compile. The cost model is
always honest.

**INVARIANT 5: Suspension is trackable.**
The compiler statically computes a **`may_suspend`** property for
every function. A function is `may_suspend` if it directly contains
`.await`, or if it calls any function that is `may_suspend`. This
is a whole-program boolean propagation, not lifetime inference —
it is cheap to compute.

`may_suspend` is **never written by the programmer.** It is purely
an internal compiler property used for safety checks:

1. **`@[no_await_guard]` enforcement:** Calling any `may_suspend`
   function while a `@[no_await_guard]` guard is live is a compile
   error — even if the `.await` is buried three calls deep.
2. **FFI callback safety:** Functions passed as `extern "C"`
   callbacks must not be `may_suspend` (see §14.19).

This is NOT function coloring. There are no separate `async` and
`sync` function types. No traits split. No closure type changes.
`.await` works in any closure passed to `map`, `filter`, etc.
The `may_suspend` property is invisible to the programmer — it
only manifests as compile errors in unsafe contexts (holding
non-suspendable guards, or C callbacks).

```
fn helper:
    some_io().await        // makes helper() may_suspend

with lock.write() as data:
    helper()               // ERROR E0701: may_suspend function called
                           // while @[no_await_guard] WriteGuard is live
    data.x = 1             // OK: no suspension
```

### 14.4 `async fn` Semantics

```
async fn fetch(url: str) -> Result[String, IoError]: ...
```

Calling `fetch(url)` does the following:

1. Allocates a lightweight thread (fiber) with its own stack.
2. Begins executing the function body on that fiber.
3. Returns a `Task[Result[String, IoError]]` handle immediately
   to the caller.

The fiber runs concurrently. It suspends at `await` points and is
resumed by the scheduler when the awaited operation completes.

### 14.5 `.await` Semantics

```
let result = task.await
```

`.await` does the following:

1. If the task is already complete, returns the result immediately.
2. If the task is still running, **suspends the current fiber** and
   yields to the scheduler. When the task completes, the current
   fiber is resumed.
3. If called from an OS thread with no fiber runtime, this is a
   **compile error** (see Invariant 4).

`.await` is the only way to extract a value from a `Task[T]`. It is
the only point where a fiber can suspend. Suspension is always
visible in the source code.

`.await` is postfix — it appears after the expression it operates
on. This allows natural chaining:

```
// Chain with ? for error propagation
let body = http.get(url).await?.read_body().await?

// Chain with |> for pipelines
let users = fetch_all(ids).await?
    |> filter(|u| u.active)
    |> collect()
```

### 14.6 `async:` Blocks

An `async:` block creates and immediately starts a fiber inline,
returning a `Task[T]`:

```
let task = async:
    let a = fetch("http://a.com").await?
    let b = fetch("http://b.com").await?
    Ok(a + b)
// task: Task[Result[String, IoError]]
```

**Semantics:** `async: body` allocates a fiber, begins execution
of `body`, and returns a `Task[T]` where `T` is the type of `body`.
The fiber runs concurrently with the caller.

This is the async analog of a regular block expression and is
essential for inline structured concurrency:

```
async scope |s|:
    s.track(async:
        for i in 0..5:
            sleep(50.millis()).await
            tx.send("msg-{i}").await
    )
    s.track(async:
        for msg in rx:
            println(msg)
    )
```

Without `async:` blocks, users would need to define a separate
`async fn` for every inline concurrent task — significant
boilerplate when the logic is small and context-specific.

**Capture rules:** `async:` blocks follow the same capture rules
as closures. They may capture references (making the resulting
`Task` ephemeral) or owned values (storable `Task`). See §14.22.

### 14.7 `Task[T]`

```
type Task[T]       // opaque handle to a running fiber
```

| Method | Signature | Description |
|--------|-----------|-------------|
| `.await` | postfix keyword | Suspend fiber until complete |
| `cancel` | `(Task[T]) -> Unit` | Cooperative cancellation |
| `is_done` | `(&Task[T]) -> bool` | Check without blocking |

`Task[T]` is `Send` when `T: Send` and `T` is not ephemeral. It is
an owned value. It can be stored in data structures when non-ephemeral.

A `Task[T]` that captures references is **ephemeral** (see §14.22).
Ephemeral tasks cannot be stored, returned, or sent to other threads.
They must be awaited or tracked in a scope before the borrowed data
goes out of scope.

**`@[must_use]`:** `Task[T]` is annotated `@[must_use]`. Dropping a
`Task` without `await`ing or explicitly `cancel`ing it is a compile
error:

```
error[E0801]: unused `Task` will be cancelled on drop
  --> src/service.w:42:9
   |
42 |     send_analytics("page_view")
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Task[Result[Unit, NotifyError]] created but not used
   |
   = note: dropping a Task cancels the fiber cooperatively
   = help: use `spawn send_analytics(...)` for fire-and-forget
   = help: use `.await` to wait for the result
   = help: use `cancel(task)` to explicitly cancel
```

This catches accidental task drops — a common source of "why isn't
this code running?" bugs in concurrent systems.

**`spawn` for fire-and-forget:** The `spawn` keyword creates a
**detached task** that runs to completion independently. It is not
owned by any scope or variable — the runtime keeps it alive:

```
spawn send_analytics("page_view")  // runs to completion, no handle
```

`spawn` returns `Unit`, not `Task[T]`. The spawned fiber is
unowned — it runs until it completes, panics, or the program exits.
This is the only correct way to do fire-and-forget.

**WARNING: `let _ = task` is NOT fire-and-forget.** Writing
`let _ = send_analytics(...)` immediately drops the task, which
cancels the fiber. The analytics request will abort at its first
`.await` point — almost certainly before it completes. The compiler
emits a warning for `let _ = <Task expression>`:

```
warning: `let _ = ...` on a Task immediately cancels it
  --> src/service.w:42:9
   |
   = help: use `spawn ...` for fire-and-forget
   = help: use `cancel(task)` for explicit cancellation
```

See §20b.3.

**Cancellation semantics:**

Cancellation is **cooperative, not preemptive** for non-ephemeral
tasks. When `cancel()` is called or a non-ephemeral `Task` is dropped:

1. A cancellation flag is set on the fiber.
2. The fiber continues executing until it reaches its next `await`
   point.
3. At that `await` point, instead of suspending, the fiber begins
   unwinding.
4. **Destructors are guaranteed to run** during unwinding, in reverse
   declaration order, just as with normal scope exit.
5. Cancellation **propagates to child tasks**: if a fiber is cancelled,
   any tasks it spawned via `async scope` are also cancelled.
6. **Awaiting a cancelled task:** Awaiting a cancelled task triggers
   **cancellation unwinding** — similar to a panic, but structured
   and catchable at `async scope` boundaries.

   ```
   async scope |s|:
       let t1 = s.spawn(fetch_user(id))
       let t2 = s.spawn(fetch_posts(id))
       let user = t1.await?           // if this fails...
       // t2 is cancelled, unwinds, destructors run
       let posts = t2.await?          // returns CancelledError
   ```

   `async scope` automatically catches cancellation unwinding from
   its child tasks. No error types need to change. No `From` impls
   needed. `IoError`, `DbError`, `ApiError` — they all work
   unchanged.

   If you need to distinguish cancellation from real errors, match
   on the scope's result:

   ```
   match task.await
       Ok(value) -> use(value)
       Err(e) if e.is_cancelled() -> log("task was cancelled")
       Err(e) -> return Err(e)
   ```

   `TaskCancelled` is a standard library error type that all error
   types can be checked against via `.is_cancelled()`. But you
   never need to add a `Cancelled` variant to your own types.

**Cancellation of ephemeral tasks:** If a `Task` is ephemeral
(captures references), dropping or cancelling it must ensure the
fiber has stopped before the caller proceeds. This is mandatory for
memory safety: the fiber holds references to the caller's stack.

**The runtime handles this without blocking the OS thread:**

1. The cancellation flag is set on the child fiber.
2. If the child fiber is idle (suspended at an `.await`), it is
   immediately unwound. The parent continues.
3. If the child fiber is scheduled on the **same** OS thread (i.e.,
   it is in the thread's run queue, not currently executing — the
   parent is currently running), the runtime immediately switches
   to the child fiber and runs it until its next `.await` point,
   then unwinds it and resumes the parent. No scheduler involvement.
4. If the child fiber is actively running on a **different** OS
   thread, the parent fiber **yields** (not blocks the OS thread)
   and the scheduler prioritizes the child for cancellation. When
   the child reaches `.await` and unwinds, the parent is resumed.

This avoids the deadlock scenario where N OS threads all block
waiting for fibers that can never be scheduled. The key insight is
that fiber drops happen inside fibers (which can yield), not inside
raw OS thread code.

```
var data = vec![1, 2, 3]
let _ = process(&mut data)  // ephemeral task: runtime ensures fiber
                             // stops before proceeding (may yield)
// data is safe — fiber is guaranteed stopped
```

Non-ephemeral tasks (capturing only owned values) use cooperative
cancellation — the fiber continues until it hits `.await` on its
own schedule, with no urgency.

A fiber that is blocked in a long synchronous computation (no `await`
points) cannot be cancelled until it reaches an `await`. For
ephemeral tasks, this means the parent fiber waits (yielding to the
scheduler) for the duration of that computation. If both fibers are
on the same OS thread, the computation runs inline. This is the
trade-off of memory safety without `Pin`.

**Restriction:** Ephemeral tasks can only be created inside fibers
(async contexts). Creating an ephemeral task on a bare OS thread
(e.g., inside `thread.spawn_os`) or in an FFI callback is a
**compile error**, because these contexts cannot yield to the
scheduler and dropping the task would deadlock. Non-ephemeral tasks
(capturing only owned values) can be created anywhere.

### 14.8 Parallel Execution

```
async fn fetch_profile(id: UserId) -> Result[Profile, ApiError]:
    let user_task = fetch_user(id)       // fiber starts
    let posts_task = fetch_posts(id)     // fiber starts
    // both running concurrently
    let user = user_task.await?
    let posts = posts_task.await?
    Ok(Profile { user, posts })
```

### 14.9 Structured Concurrency

`async scope` creates a scope in which tasks are tracked with the
guarantee that **all tasks complete before the scope exits**.

**Formal semantics:**

```
async scope |s|:
    body
```

desugars to:

```
runtime::structured_scope(|s| { body })
```

The scope object `s` provides:

| Method | Signature | Description |
|--------|-----------|-------------|
| `track` | `(Task[T]) -> ScopedTask[T]` | Register an existing task with this scope |

**Why `track`, not `spawn`:** In With, calling an `async fn` eagerly
allocates a fiber and returns a `Task[T]` (§14.4). If a scope took
a closure like `s.spawn(|| async_fn())`, the closure would run on
one fiber and `async_fn()` would spawn a second — creating a
detached task that escapes structured concurrency. Instead,
`s.track()` accepts the `Task[T]` directly:

```
async scope |s|:
    // fetch_user(id) eagerly spawns a fiber, returns Task
    // s.track() registers it with the scope
    let task = s.track(fetch_user(id))
    task.await
```

**`ScopedTask[T]`:** The value returned by `s.track()`. It behaves
like `Task[T]` (supports `.await`, `cancel`, `is_done`) but is
**exempt from `@[must_use]`**. The scope guarantees cleanup: when
the scope exits (normally or via early `?` return), all tracked
tasks that haven't been awaited are cancelled and joined.

This solves the `?` interaction problem:

```
async scope |s|:
    let posts_task = s.track(self.repo.count_posts(id))
    let followers_task = s.track(self.repo.count_followers(id))

    // If this fails and returns early via ?,
    // followers_task is cancelled by the scope's destructor.
    // No @[must_use] error — ScopedTask is scope-managed.
    let posts = posts_task.await?
    let followers = followers_task.await?
    (posts, followers)
```

**Guarantees:**

1. All tasks tracked via `s.track` will complete (or be cancelled)
   before `async scope` returns.
2. If any tracked task panics, all sibling tasks are cancelled and
   the panic propagates to the scope.
3. The scope is an expression — it returns the value of `body`.
4. `s` cannot escape the scope. It is ephemeral.

```
async fn handle_batch(ids: Vec[UserId]) -> Vec[Result[User, ApiError]]:
    async scope |s|:
        let tasks = ids.iter()
            |> map(|id| s.track(fetch_user(id)))
            |> collect[Vec]()
        tasks |> map(|t| t.await) |> collect()
    // all tracked tasks guaranteed complete here
```

For CPU-bound parallelism on OS threads (no fiber runtime required):

```
scope |s|:
    s.spawn(|| compute_chunk_a())
    s.spawn(|| compute_chunk_b())
// both complete here
```

The non-async `scope` uses `s.spawn(|| closure)` because OS-thread
work items are sync closures — no eager fiber spawning occurs.
`scope` is available in `no_runtime` builds.

### 14.10 Select Await

`select await` races multiple async expressions and executes the
branch of the first to complete. Remaining expressions are cancelled.

```
select await
    msg = rx_fast.recv() -> println("fast: {msg}")
    msg = rx_slow.recv() -> println("slow: {msg}")
    _ = timeout(1.secs()) -> println("timeout")
```

Each branch has the form `pattern = async_expr -> body`. The runtime
starts all expressions concurrently, the first to resolve fires its
branch, and all siblings are cancelled (structured cancellation).

**Type safety:** Each branch handles its own return type
independently — no shared enum wrapper needed. This scales to any
number of branches without `First`/`Second`/`Third` boilerplate.

**Composing with `?` and loops:**

```
// Select in a loop (event loop pattern)
loop:
    select await
        msg = inbox.recv() ->
            process(msg)?
        _ = shutdown.recv() ->
            break
        _ = timeout(idle_timeout) ->
            send_heartbeat().await?

// Select with error propagation
select await
    data = stream.next() -> process(data?)?
    _ = cancel.cancelled() -> return Err(.Cancelled)
```

**Fair selection (default):** If multiple expressions complete
simultaneously, the runtime selects a **ready branch at random**
(pseudo-random, not cryptographic). This prevents starvation: a
high-throughput data channel cannot indefinitely starve a shutdown
signal or heartbeat timer.

```
loop:
    select await
        data = fast_stream.recv() -> handle(data)
        _ = shutdown.recv() -> break    // will eventually fire
```

**Biased selection:** For cases where deterministic priority is
needed, use `select await biased`. This selects the first textual
branch that is ready (top-to-bottom priority):

```
select await biased
    urgent = priority_rx.recv() -> handle_urgent(urgent)
    normal = normal_rx.recv() -> handle_normal(normal)
    _ = timeout(1.secs()) -> send_heartbeat().await
```

Use `biased` when you need guaranteed priority ordering and
understand the starvation risk.

**Handling `Option`/`Result` in branches:** Use `let ... else`
inside the branch body to destructure the completed value. This
reuses existing syntax and keeps the grammar simple:

```
loop:
    select await
        opt_msg = rx.recv() ->
            let Some(msg) = opt_msg else break
            process(msg)
        result = listener.accept() ->
            let Ok(conn) = result else continue
            handle(conn)
        _ = timeout(idle_timeout) ->
            send_heartbeat().await
```

**Exhaustiveness:** `select await` does not require a default branch.
At least one branch must be present. If all expressions complete
with values that don't match their patterns, the select panics
(same as a non-exhaustive match).

### 14.11 Concurrent Await

When `.await` is applied to a tuple of tasks, all elements execute
concurrently and the result is a tuple of their results.

```
let (user, posts) = (fetch_user(id), fetch_posts(id)).await
let (user, posts) = (fetch_user(id), fetch_posts(id)).await?
let (a, b, c) = (fetch_a(), fetch_b(), fetch_c()).await
```

Given `(Task[A], Task[B], ..., Task[N])`, tuple `.await` returns
`(A, B, ..., N)`.

Calling an `async fn` eagerly spawns a fiber (§14.4), so tuple
`.await` is a join operation over already-running tasks.

Error handling with `?` composes in tuple order:

`(Task[Result[A, E]], Task[Result[B, E]]).await?` has type `(A, B)`.

If `?` triggers early return from an `async scope`, tracked siblings
are cancelled by normal scope unwinding rules. Outside `async scope`,
normal `Task` drop semantics apply (§14.7).

```
async scope |s|:
    let (user, posts) = (
        s.track(fetch_user(id)),
        s.track(fetch_posts(id)),
    ).await
    (user?, posts?)
```

Tuple `.await` supports tuple sizes 2..12 (same as tuple arity limits
in §4.6). For dynamic or larger sets, use collection combinators.

Desugaring (2-tuple):

```
(task_a, task_b).await
// desugars to:
{
    let __ta = task_a
    let __tb = task_b
    (__ta.await, __tb.await)
}
```

Runtime implementations may use a multi-wait join internally; observable
semantics are completion of all tasks with results in tuple order.

| Need | Construct |
|------|-----------|
| Await 2–12 heterogeneous tasks | `(task_a, task_b).await` |
| Await N homogeneous tasks | `tasks |> await_all` |
| First task to complete | `tasks |> await_first` |
| First successful task | `tasks |> await_any` |
| All results including errors | `tasks |> await_settled` |
| First of N with pattern dispatch | `select await` (§14.10) |
| Dynamic spawn + cancellation scope | `async scope` (§14.9) |
| Fire-and-forget | `spawn expr` (§14.7) |

#### 14.11.1 Collection Await (Standard Library)

Collection await is a standard-library surface, not special syntax:

```
let users = ids |> map(fetch_user) |> await_all?
let fastest = tasks |> await_first
let winner = tasks |> await_any?
let results = tasks |> await_settled
```

Collection combinators follow deterministic semantics:

- `await_all(Task[T]) -> Vec[T]` waits for all tasks and returns results in input order.
- `await_all(Task[Result[T, E]]) -> Result[Vec[T], E]` is fail-fast: on first `Err`, it cancels and joins remaining tasks, then returns that `Err`.
- `await_first(Task[T]) -> T` returns the first completed result, then cancels and joins losers before returning.
- `await_any(Task[Result[T, E]]) -> Result[T, Vec[E]]` returns first `Ok(T)` (then cancels + joins losers); if all fail, returns `Err(Vec[E])` in input order.
- `await_settled(Task[Result[T, E]]) -> Vec[Result[T, E]]` never cancels, waits for all, and returns in input order.

Empty-input behavior:

- `await_first([])` panics with stable message:
  `"await_first: empty input"`.
- `await_any([])` returns `Err(Vec.new())`.
- For non-empty input, `await_any` all-fail result is guaranteed
  non-empty (`Err(errors)` where `errors.len() > 0`).

Ordering guarantee for `await_any` all-fail:

- Errors are aggregated in **input order**, not completion order.

Cancellation/drop contract for collection combinators:

- If a combinator returns early (winner found or fail-fast trigger),
  it cancels all remaining owned tasks and joins them before return.
- If the combinator itself is cancelled/dropped mid-flight, it
  cancels remaining owned tasks and joins them before unwinding.

See `lib/std/async.w` and `lib/std/async/` docs for API details.

### 14.12 Why Fibers, Not State Machines?

| | Rust async | With |
|---|---|---|
| **Mechanism** | State machine (stackless) | Fiber (stackful) |
| **Stack** | Captured in Future struct | Real stack per fiber |
| **Refs across await** | Requires Pin | Just work |
| **Colored functions** | Yes | No (Invariant 1) |
| **Runtime** | Pluggable executors | One blessed scheduler (Invariant 3) |
| **Send bounds** | Infect async return types | Not needed |
| **Trait support** | Requires boxing or GATs | Just works |
| **Cancellation** | Drop the Future | Cancel the Task |

The fiber model was chosen because it preserves the ownership model's
invariants without special-casing for async code. References on the
stack survive suspension. No lifetime gymnastics required.

### 14.13 Interaction with Ownership

Because fibers have real stacks, references across `await` are safe:

```
async fn process(data: &mut Vec[i32]):
    let first = &data[0]
    some_io().await              // fiber suspends; reference still valid
    println(first)               // safe to use
    data.push(42)
```

In Rust, this requires `Pin<&mut Self>` because the Future is a
struct and references into it invalidate on move. Here, the fiber
stack doesn't move.

**`.await` works inside standard higher-order functions.** Because
fibers have real stacks, `.await` is valid anywhere — including
inside closures passed to `map`, `filter`, `fold`, and `for_each`.
No specialized `AsyncIterator` or `Stream` traits are needed:

```
// This is valid With code — impossible in Rust without Stream
let results = urls.iter()
    |> map(|url| fetch(url).await)
    |> filter(|r| r.is_ok())
    |> collect[Vec]()

// .await inside fold
let total = ids.iter()
    |> fold(0, |sum, id| sum + get_count(id).await)
```

This is one of the most significant ergonomic advantages of the
fiber model. In Rust, any use of `.await` inside an iterator
closure requires rewriting to use `Stream`, `futures::join_all`,
or manual loops. In With, standard synchronous iteration and
standard async functions compose freely.

**Implementation note:** The language guarantees **semantic stack
preservation** — safe references remain valid across `await` points.
Implementations may relocate or segment physical stacks, but the
compiler ensures safe references are updated or indirected
transparently. Raw pointers (`*const T`, `*mut T`) obtained via
`unsafe` are **not** updated — they are bare addresses. This is why
§19.3 forbids raw pointers to stack locals across `await`. Safe code
is never affected.

### 14.14 OS Threads (Always Available)

OS threads exist independently of the fiber runtime and are available
in all builds, including `no_runtime`:

```
thread.spawn_os(closure) -> JoinHandle[T]
JoinHandle.join() -> T
```

For structured CPU-bound parallelism:

```
scope |s|:
    s.spawn(|| compute_chunk_a())
    s.spawn(|| compute_chunk_b())
// both complete here
```

### 14.15 Channels

```
let (tx, rx) = chan[Message](buffer: 10)

tx.send(msg).await          // suspends fiber if full
let msg = rx.recv().await   // suspends fiber if empty

// Non-blocking:
match rx.try_recv()
    Some(msg) -> handle(msg)
    None      -> ()
```

Channels transfer ownership: sending moves the value. **Channel
element types must be `Send`, not merely `ScopedSend`.** This is
critical: a channel decouples the lifetime of data from the sender's
stack frame. Even inside an `async scope`, Fiber 1 can send a
reference to its own local and then drop that local before Fiber 2
reads the message. `ScopedSend` guarantees the *scope* outlives the
fibers, but not that Fiber 1's locals outlive Fiber 2's reads.

```
// ERROR: ephemeral values cannot be sent over channels
async scope |s|:
    let (tx, rx) = chan[&str](10)
    s.track(async:
        let local = "hello".to_owned()
        tx.send(local.as_view()).await  // ERROR: &str is not Send
    )
    s.track(async:
        let msg = rx.recv().await       // would be use-after-free
    )

// OK: send owned values over channels
let (tx, rx) = chan[String](10)
tx.send("hello").await                  // str literal, String is Send
```

### 14.16 Send, Sync, and ScopedSend

- `Send`: safe to transfer across thread boundaries (value may
  outlive the sender). Ephemeral types are **not** `Send`.
- `Sync`: safe to share via `&T` across threads
- `ScopedSend`: safe to **capture in a closure** sent to a scoped
  thread or fiber that is guaranteed to join before the current
  scope exits.
  All `Send` types implement `ScopedSend`. **Ephemeral types also
  implement `ScopedSend`** — they can be captured by scoped fibers
  because the scope guarantees the fiber joins before the borrowed
  data goes out of scope.

  **Important:** `ScopedSend` does NOT mean "safe to send over a
  channel." Channels decouple sender and receiver lifetimes.
  `ScopedSend` only covers direct capture in the spawned closure —
  the reference's lifetime is guaranteed by the scope's join.
  Channel element types require full `Send` (see §14.15).

```
// thread.spawn_os requires Send — no ephemerals
thread.spawn_os(|| use_ref(&local))   // ERROR: &local is not Send

// scope requires ScopedSend — ephemerals allowed
scope |s|:
    s.spawn(|| use_ref(&local))       // OK: ScopedSend, joins before scope exits

// async scope requires ScopedSend — ephemerals allowed
async scope |s|:
    s.track(process(&local))          // OK: ScopedSend, tracked task joins
```

| Type | `Send` | `ScopedSend` |
|------|--------|--------------|
| `i32`, `String`, owned types | Yes | Yes |
| `Arc[T]` where `T: Send + Sync` | Yes | Yes |
| `Rc[T]` | No | No |
| `&T`, `&mut T` | No | Yes |
| Ephemeral structs | No | Yes |
| `Task[T]` (non-ephemeral) | Yes (if `T: Send`) | Yes |
| `Task[T]` (ephemeral) | No | Yes |

### 14.17 Synchronization Primitives

- `Mutex[T]` — mutual exclusion with scoped access
- `RwLock[T]` — reader-writer lock with scoped access
- `Atomic[T]` — lock-free atomic operations
- `Condvar` — condition variable

All implement `Scoped`/`ScopedMut` for `with` blocks. Lock operations
are fiber-aware: contended locks yield the fiber, not the OS thread.

### 14.18 The Fiber Runtime

The fiber scheduler is part of the standard library. It is:

- Initialized automatically on program start for hosted targets
- Work-stealing across OS threads
- Not a trait, not pluggable, not replaceable
- Absent in `no_runtime` builds (and `async` is then a compile error)

The runtime is the one component with hidden scheduling cost. This is
acceptable because: (a) it is opt-in via `async`, (b) suspension
points are always marked with `await`, and (c) `no_runtime` builds
can disable it entirely.

### 14.19 Fiber Stack Management

Each fiber has a dedicated stack. Stack memory is the primary resource
cost of the fiber model and must be understood to use `async`
effectively.

**Default stack size:** 64 KB per fiber. Sufficient for typical
I/O-bound code. Configurable per-application in `with.toml`:

```toml
[runtime]
fiber_stack_size = "64KB"     # default
fiber_initial_stack = "8KB"   # initial allocation (growable)
fiber_pool_size = 1024        # pre-allocated stack pool
```

**Growable stacks:** The reference implementation uses growable
stacks. A fiber starts with a small initial allocation (default
8 KB) and grows on demand. Stack overflow does not silently corrupt
memory — growth is detected at each function call's stack probe and
handled by allocating a new segment (implementation-defined). This
allows most fibers to use far less than 64 KB in practice while
supporting deep call stacks when needed.

**FFI stack switching:** C code called via `c_import` has no
knowledge of With's segmented stacks and may exceed remaining stack
space. The compiler statically determines which call paths
transitively invoke C functions. Fibers that call FFI functions
**automatically switch to an OS-thread-sized stack** at the FFI
boundary:

1. The compiler marks functions as `ffi_reachable` if they (directly
   or transitively) call any `c_import` function.
2. At the FFI call site, the runtime saves the fiber stack pointer
   and switches to a pre-allocated OS-thread stack (typically 2–8 MB)
   from a per-thread pool.
3. The C function executes on the full-size stack.
4. On return, the runtime restores the fiber stack pointer.

The stack switch costs approximately 10–50 ns (save/restore a few
registers). This is honest overhead — not zero-cost, but
predictable and safe. Pure-With fibers that never call C code pay
nothing.

```
// Pure With — stays on 8KB fiber stack, no switch
async fn compute(x: i32) -> i32: x * x + 1

// Calls C — auto-switches to OS stack at the boundary
async fn query(db: &Database, sql: &str) -> Result[Row, DbError]:
    sqlite3_step(db.handle)  // runs on OS-thread stack
```

For performance-critical paths that call C frequently, the `@[ffi_stack]`
attribute forces an entire function to run on an OS-thread stack,
avoiding per-call switching:

```
@[ffi_stack]
fn process_image(data: &[u8]) -> Image:
    // All C calls in this function run on the OS stack
    // without per-call switching overhead
    ...
```

**No suspension while C frames are on the stack.** If C code calls
back into With (e.g., via a function pointer passed to `qsort`),
the With callback **must not suspend**. Suspending a fiber while C
frames are active on the OS stack would corrupt the stack — another
fiber resuming on the same OS thread would overwrite the paused C
frames.

The compiler enforces this via `may_suspend` analysis (Invariant 5,
§14.3): any function used as an `extern "C"` callback, or
transitively called while C frames are on the stack, must not be
`may_suspend`:

```
// ERROR: callback must not suspend
unsafe { c_sort(items.ptr, items.len, |a, b|
    fetch_weight(a).await <=> fetch_weight(b).await
    //              ^^^^^^ ERROR: may_suspend in extern "C" callback
) }

// OK: no suspension in callback
unsafe { c_sort(items.ptr, items.len, |a, b|
    a.weight <=> b.weight
) }

// OK: spawn a detached task (no .await needed)
unsafe { c_on_event(|event|
    spawn handle_event(event)   // detached, runs to completion
) }
```

**Memory budget:**

| Model | Per-task overhead | 100K concurrent tasks |
|-------|------------------|----------------------|
| Rust stackless futures | ~state machine size | ~state machine sizes |
| With fibers (8 KB initial) | 8–64 KB (grows on demand) | ~800 MB worst case |
| OS threads (8 MB typical) | ~8 MB | Not viable |

The 800 MB worst case is pathological — it requires all 100K fibers
to grow to the full 64 KB limit and remain active simultaneously.
Realistic suspended fibers doing typical I/O work often use less
than 2 KB of actual stack.

**Fiber stack pooling:** The runtime maintains a pool of
pre-allocated fiber stacks. Creating a fiber grabs a stack from the
pool (one atomic operation, not `malloc`). When a fiber exits, its
stack is returned to the pool for reuse. This makes fiber
creation/destruction extremely cheap — comparable to grabbing an
object from a free list.

This is critical for async trait dispatch: calling
`repo.find_by_id(id).await` through a `Box[dyn UserRepository]`
creates and destroys a fiber, but the stack is recycled from the
pool. The cost is a pool grab + context switch, not a heap
allocation.

Pool size is configurable. The runtime lazily grows the pool as
needed and may shrink it under memory pressure.

**Scale guidance:** Fibers are appropriate for web servers and
database backends targeting 10K–100K concurrent connections. For
systems requiring millions of simultaneous in-flight tasks, collect
into owned data structures and process with a smaller fixed pool of
worker fibers. For >100K suspended tasks, prefer channel-driven
worker pool architectures.

### 14.20 Generators vs. Async: A Clarification

Generators (`gen fn`) and async functions (`async fn`) look
syntactically similar but compile to fundamentally different
mechanisms:

|  | `gen fn` | `async fn` |
|--|---------|-----------|
| **Mechanism** | State machine (compile-time) | Fiber (runtime) |
| **Runtime required** | No | Yes |
| **Suspends** | At `yield` | At `await` |
| **Driver** | Caller calls `next()` | Fiber scheduler |
| **Allocation** | Stack at call site | Heap stack per fiber |
| **Storable** | Yes (if no captured refs) | `Task[T]` is always storable |
| **`no_runtime` builds** | Works | Compile error |

`gen fn` compiles entirely away — the compiler rewrites it into a
struct and a `next()` method. It has no scheduler dependency and
works in `no_runtime` builds. It cannot use `.await`.

`async fn` allocates a fiber with a real stack and requires the fiber
runtime. It can suspend at any `await` point and be driven by the
scheduler.

If you want a lazy sequence that works everywhere, use `gen fn`. If
you want concurrent I/O, use `async fn`. They are complementary
tools, not alternatives.

### 14.21 Real-World Example

```
async fn main:
    let listener = net.listen("0.0.0.0:8080").await
    println("Listening on :8080")

    loop:
        let conn = listener.accept().await
        spawn handle_connection(conn)

async fn handle_connection(conn: TcpStream):
    let req = http.parse_request(&conn).await

    let response = match req.path_str()
        "/users" ->
            let users = db.query("SELECT * FROM users").await
            http.json_response(200, users)
        "/health" ->
            http.text_response(200, "ok")
        _ ->
            http.text_response(404, "not found")

    conn.write_all(response.as_bytes()).await
```

Reads like synchronous code. Each connection is a fiber. Thousands
concurrent. No callbacks, no state machines, no type gymnastics.

### 14.22 Task Ephemerality and Send

A `Task[T]` may capture values from its spawning environment. The
ephemerality and `Send`-ability of the task depends on what it
captures:

**Rule:** A `Task[T]` is ephemeral if its spawned fiber environment
contains any ephemeral values (references, views, guards). A `Task[T]`
is `Send` only if all captured values are `Send` and the task is not
ephemeral.

```
// Owned-argument task: fully storable, Send
let task = fetch_user(id)              // id: UserId is owned
// task is Task[Result[User, DbError]], storable, Send

// Borrowing task: ephemeral — cannot be stored or sent
async fn process(data: &mut Vec[i32]) -> Unit: ...
let task = process(&mut my_vec)        // captures &mut my_vec
// task is ephemeral — it borrows my_vec
// Cannot store in a struct, cannot send to another thread
```

**How the compiler tracks this:** Ephemerality is a per-binding
property, not a per-type property. The type `Task[i32]` is the
same whether ephemeral or storable. The compiler determines
ephemerality at the creation site by analyzing the arguments: if
any argument is a reference or ephemeral value, the resulting Task
binding is marked ephemeral. This marking propagates through
assignments and function calls.

**Passing ephemeral values to functions:** Ephemeral values can be
passed to functions — by reference or by value. The compiler tracks
ephemerality and warns if a value might escape its safe scope:

```
fn process_task(t: Task[i32]):
    t.await                          // OK: consumes the task

fn store_globally(t: Task[i32]):
    GLOBAL_TASKS.push(t)            // WARNING: storing a value that
                                     // may be ephemeral at some call sites

var v = vec![1, 2, 3]
let task = process(&mut v)          // ephemeral task
process_task(task)                   // OK: compiler sees task is consumed
store_globally(task)                 // ERROR: compiler detects storage of
                                     // ephemeral value in a global
```

The compiler catches the clear bugs (storing ephemeral refs in
globals, sending them across threads). For ambiguous cases, it
warns rather than blocks. You're a systems programmer — you can
read a warning.

**Ephemeral tasks CAN be returned from functions** — the caller's
binding inherits the ephemerality (Rule 8, §22.1). This is
essential: `async fn get_profile(self: &UserService)` returns a
`Task` that captures `&self`. The returned task is ephemeral at
the call site, preventing the caller from outliving `&self`:
the call site, preventing the caller from storing it or outliving
the referenced data:

```
let task = svc.get_profile(id)   // ephemeral: borrows &svc
task.await?                       // OK: used immediately
// task cannot be stored in a struct or global
```

**`async scope` is the ergonomic solution** for borrowing tasks:

```
async fn process_all(data: &mut Vec[i32]):
    async scope |s|:
        // These tasks borrow data — ephemeral
        let t1 = s.track(transform(&data[0..100]))
        let t2 = s.track(transform(&data[100..200]))
        t1.await
        t2.await
    // Scope guarantees both tasks complete here.
    // Borrows of data are released.
```

Because `async scope` guarantees all tracked tasks complete before
the scope exits, the compiler knows the borrows cannot outlive their
referents — no lifetime annotations needed.

**Summary:**

| Task captures | Ephemeral? | Storable? | `Send`? |
|---------------|-----------|-----------|---------|
| Only owned values | No | Yes | Yes (if `T: Send`) |
| References/views | Yes | No | No |
| `@[no_await_guard]` guards | N/A | N/A | Compile error (§7.9) |

This is the same rule as generators (§14.20): if the suspended
environment contains ephemerals, the handle is ephemeral. This
avoids reintroducing lifetime annotations while preserving safety.

---

## 15. Strings

### 15.1 String Types

**There are two string types you need to know:**

| Type | What it is | When to use |
|------|-----------|-------------|
| `str` | Owned, heap-allocated, UTF-8 string | Storing strings, struct fields, return values |
| `&str` | Borrowed view into a string | Function parameters, read-only access |

That's it. `str` for owning, `&str` for borrowing. Everything else
is an implementation detail or FFI-specific.

```
type User = { name: str, email: str }    // owned strings in structs
fn greet(name: &str): println("Hello, {name}")  // borrowed for reading
fn get_name -> str: "Alice"            // return owned string
```

**String literals** (`"hello"`) are `str` by default (owned). The
compiler is smart about this — when it can prove the string is only
read (never stored, never returned, never mutated), it silently
optimizes away the allocation and uses a static reference internally.
You don't think about this. You write strings, the compiler does the
right thing:

```
let greeting = "hello"       // str — just a string
let user = User { name: "Alice", email: "a@b.com" }  // str fields
```

**When you explicitly want a borrowed view** (e.g., for performance
in a tight loop over slices), annotate it:

```
let view: &str = "hello"     // &str — static reference, no allocation
fn greet(name: &str): ...   // parameter context: callers can pass &str
```

**Advanced types** (you rarely need these directly):

| Type | What it is |
|------|-----------|
| `String` | Same as `str` — `str` is an alias for `String` |
| `StrView` | Same as `&str` — `&str` is an alias for `StrView` |
| `CStr` | NUL-terminated C string view (FFI only) |
| `CString` | Owned NUL-terminated C string (FFI only) |

### 15.2 Conversions

| From | To | How |
|------|----|-----|
| `str` | `&str` | auto-borrow or `.as_view()` |
| `&str` | `str` | `.to_owned()` (allocates) |
| `"literal"` | `str` | direct (default) |
| `"literal"` | `&str` | when type context is `&str`, zero-cost static ref |
| `str` | `CString` | `.to_cstring()` (appends NUL) |
| `CString` | `CStr` | `.as_cstr()` |

### 15.3 String Literals

String literals like `"hello"` default to owned `str`. You never
need a type annotation to use a string:

```
// These all just work — no annotations needed
let name = "Alice"
let config = ServerConfig { host: "localhost", port: 8080 }
fn get_name -> str: "Alice"

fn register(name: str): ...
register("Alice")                                          // just works

// Passing to fn(&str) auto-borrows (no allocation):
fn greet(name: &str): println("hello {name}")
greet("world")                               // OK: str auto-borrows to &str

// Explicit &str for zero-cost static reference:
let view: &str = "hello"                     // no allocation, static memory
```

**How it works:** A bare string literal produces an owned `str`.
The compiler is free to optimize this — when it can prove the
string is never mutated, never stored in a heap structure, and
never escapes the current scope, it may use a static reference
internally. But the *type* is always `str` unless you annotate
`&str`.

When the type context is `&str` (function parameter, explicit
annotation), the literal is a zero-cost static reference with no
allocation. This is an optimization the compiler applies
automatically.

```
let s = "hello"        // s: str (owned — the default)
let s: &str = "hello"  // s: &str (static reference, no allocation)
```

**Interpolated literals** (`"user {id}"`) always produce `str`
(owned) because they must allocate to build the result.

**C-string literals:** `c"hello"` produces a `&CStr` — a compile-
time reference to a NUL-terminated string in static memory. The NUL
byte is appended automatically by the compiler; the user does not
write `\0`:

```
// c"hello" is &CStr pointing to static "hello\0"
puts(c"hello".ptr)     // .ptr gives *const u8

// For dynamic C strings, use CString:
let name = CString.new("Alice")   // heap-allocates with NUL
puts(name.as_cstr().ptr)
```

`c"..."` does not support string interpolation. For dynamic C
strings, construct a `CString` from an owned `str`.

---

## 16. FFI and C Interoperability

C interoperability is not a bolt-on feature. It is a **day-zero
requirement**. A systems language that cannot trivially use existing
C libraries — libc, OpenSSL, SQLite, Vulkan, POSIX, Win32 — is
not a systems language. It is a toy.

### 16.1 `c_import`: Automatic C Header Import

The primary mechanism for C interop is direct header import:

```
use c_import("SDL2/SDL.h")
use c_import("sqlite3.h")
use c_import("openssl/ssl.h", link: "ssl", "crypto")
```

`c_import` reads a C header file at compile time, parses it, and
makes all declarations available as With symbols. This includes:

- **Functions** → callable directly (the `c_import` is the opt-in)
- **Structs** → `@[repr(C)]` struct types
- **Enums** → integer constants or With enums
- **Typedefs** → type aliases
- **`#define` constants** → `const` values (integer and string literals)
- **Function-like macros** → not translated (warning emitted; see §16.2)

```
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    var db: *mut sqlite3 = null
    let rc = sqlite3_open(":memory:", &mut db)   // direct call
    if rc != SQLITE_OK:
        panic("Failed to open database")
    defer sqlite3_close(db)
    // ... use sqlite3 API directly
```

**Why no `unsafe` on every call?** The `c_import` itself is the
opt-in. You imported a C library — you know you're calling C code.
Wrapping every call in `unsafe {}` is ceremony without safety. The
real safety boundary is the **With wrapper** that the stdlib
provides (e.g., `Database.open()` wraps `sqlite3_open` with proper
error handling and resource management).

`unsafe` is still required for raw pointer operations (dereferencing
`*mut T`, pointer arithmetic, transmutes). But calling an imported
C function that takes normal arguments is just a function call.

**Raw pointer operations still need `unsafe`:**

```
use c_import("my_lib.h")

// Direct call — no unsafe needed
let handle = my_lib_init()

// Pointer dereference — unsafe required
let value = unsafe { *handle }
```

**Null-safe pointer conversion:** Raw pointers from C are
inherently nullable. The `.as_option()` method on raw pointers
converts them to `Option`, making null handling ergonomic:

```
// C function returns nullable pointer
let name_ptr: *const c_char = get_user_name(id)

// Convert to Option — null becomes None
let name = name_ptr.as_option()
    .map(|p| CStr.from_ptr(p).to_str())
    .unwrap_or("unknown")

// Also works with ?? 
let name = ptr_to_string(name_ptr.as_option() ?? return default_name())
```

`.as_option()` is safe — it only checks for null, it doesn't
dereference the pointer. The resulting `Option[*const T]` or
`Option[*mut T]` still requires `unsafe` to dereference.

**The C toolchain is a dependency.** `c_import` invokes the system
C compiler's preprocessor (configurable, default: `cc -E`) to expand
includes, resolve `#ifdef`s, and handle platform-specific headers.
The With compiler then parses the preprocessed output.

**Cross-compilation limitation:** Unlike Zig (which embeds Clang),
With's Phase 0 `c_import` depends on the host system's C toolchain.
Cross-compiling for a different target requires a cross-compiler
(e.g., `aarch64-linux-gnu-gcc`) to be installed and configured in
`with.toml`. Phase 2+ may embed a C header parser to eliminate this
dependency and enable self-contained cross-compilation.

**Build configuration:**

```toml
# with.toml
[c_import]
cc = "cc"                           # C compiler for preprocessing
include_paths = ["/usr/include"]    # additional -I paths
defines = { "DEBUG" = "1" }         # additional -D flags
```

### 16.2 Macro Handling

C macros that are simple constants are translated automatically:

```c
#define SQLITE_OK 0              // → const SQLITE_OK: i32 = 0
#define PATH_MAX 4096            // → const PATH_MAX: i32 = 4096
#define NULL ((void*)0)          // → recognized as null
```

Function-like macros are **not automatically translated in Phase 0.**
C macros are preprocessor token replacements — they do not exist in
the C AST that `libclang` parses. Translating function-like macros
requires heuristic token-stream analysis (which Zig spent years
perfecting). Phase 0 translates only `#define` constants:

```c
#define MAX(a,b) ((a) > (b) ? (a) : (b))
// → NOT translated. Compiler warning: untranslated macro MAX
// User must write: fn max[T: Ord](a: T, b: T) -> T: if a > b then a else b
```

Complex macros (token pasting, stringification, variadic macros,
statement-expression macros) are never translated. The compiler
emits a warning listing all untranslated macros. Users wrap these
in a thin C shim file or write manual `extern "C"` bindings.

Phase 2+ may add best-effort function-like macro translation for
simple expression macros.

### 16.3 Manual Declarations

For cases where `c_import` is insufficient or when fine-grained
control is needed, manual declarations are supported:

```
extern "C" {
    fn puts(s: *const u8) -> i32
    fn custom_fn(ctx: *mut c_void) -> i32
}
```

All `extern "C"` calls require `unsafe`.

**The `c_void` type:** C's `void*` maps to `*mut c_void` (or
`*const c_void`) in With. `c_void` is an opaque, zero-sized type
defined in `std.ffi` that cannot be instantiated — it exists only
to be pointed at. `void` is not a keyword or built-in type in With
(the unit type is `Unit`). `c_import` automatically translates C's
`void*` parameters to `*mut c_void`.

### 16.4 Layout Control

```
@[repr(C)]
type Point = { x: f64, y: f64 }
```

Types imported via `c_import` automatically have `repr(C)` layout.
Manually defined types intended for C interop must be explicitly
annotated.

### 16.5 Exporting to C

```
@[c_export("my_lib_init")]
fn init(config: *const Config) -> i32: ...
```

The toolchain generates C header files for all `@[c_export]` symbols.
This enables With libraries to be consumed by C, C++, or any
language with a C FFI.

### 16.6 Function Pointers

Only non-capturing closures coerce to `extern "C" fn` pointers.

### 16.7 Callback Pattern

```
@[repr(C)]
type Callback = {
    func:    extern "C" fn(ctx: *mut c_void, arg: i32) -> i32,
    ctx:     *mut c_void,
    destroy: extern "C" fn(ctx: *mut c_void),
}
```

Standard library provides helpers for boxing/unboxing closure context.

### 16.8 Link Directives

Libraries to link are specified either in `c_import` or in `with.toml`:

```toml
# with.toml
[link]
libs = ["sqlite3", "ssl", "crypto"]
search_paths = ["/usr/local/lib"]
```

Or inline:

```
use c_import("sqlite3.h", link: "sqlite3")
```

The `with build` command passes these to the linker.

---

## 17. Metaprogramming

With does not have macros. It has `comptime` — compile-time execution
of regular With code with access to type information. This replaces
derive macros, reflection-based codegen, and most uses of procedural
macros from other languages. The key property: generated code is
regular With code that goes through the full type checker and borrow
checker. Nothing is hidden from the safety machinery.

### 17.0 Magic Constants

With provides two built-in magic constants, evaluated at the point of use:

| Constant | Type | Value |
|----------|------|-------|
| `__FILE__` | `str` | Path of the current source file |
| `__LINE__` | `u32` | Line number of the expression |

```
println(__FILE__)    // prints "src/main.w"
println(__LINE__)    // prints the current line number
```

These are especially useful as default parameter values for assertion
and logging functions:

```
fn log(msg: str, file: str = __FILE__, line: u32 = __LINE__):
    println("[{file}:{line}] {msg}")

log("hello")  // prints "[src/main.w:5] hello"
```

### 17.1 Compile-Time Evaluation

`comptime` executes code at compile time. Deterministic, side-effect-free.

```
comptime fn build_table(keys: [str]) -> HashMap[str, usize]:
    var table = HashMap.new()
    var i = 0
    for key in keys:
        table.insert(key, i)
        i += 1
    table

const ROUTES = comptime build_table(["/", "/health", "/users"])
```

Any function marked `comptime fn` can only call other `comptime`
functions and use types that are available at compile time. It cannot
perform I/O, allocate heap memory that persists to runtime, or call
FFI functions. The result must be a value that can be embedded in the
binary as a constant.

### 17.2 Compile-Time Type Introspection

Comptime code can inspect type metadata by calling methods on type
parameters directly. Inside comptime context, types are objects:

**Type methods (available at compile time):**

| Method | Returns | Description |
|--------|---------|-------------|
| `T.fields()` | `[FieldInfo]` | Struct field names, types, offsets |
| `T.variants()` | `[VariantInfo]` | Enum variant names and payloads |
| `T.size()` | `usize` | Size in bytes |
| `T.align()` | `usize` | Alignment in bytes |
| `T.name()` | `str` | Type name as string |
| `T.implements(Trait)` | `bool` | Whether T implements Trait |
| `T.is_copy()` | `bool` | Whether T is Copy |

```
comptime fn print_fields[T: type]:
    for field in T.fields():           // T is a type object
        println("field: {field.name}, size: {field.size}")
```

The `TypeInfo` module provides the same API for non-generic contexts:
`TypeInfo.fields[SomeType]()`, `TypeInfo.size[SomeType]()`, etc.
Inside comptime generic functions, `T.fields()` is preferred — it
reads like natural reflection.

`FieldInfo` contains:

```
type FieldInfo = {
    name: str,
    type_name: str,
    offset: usize,
    size: usize,
    is_ephemeral: bool,
}
```

### 17.3 Derive-Like Code Generation

The primary use case: generating trait implementations from type
structure.

```
// Generate a JSON serializer for any struct at compile time
comptime fn derive_serialize[T: type] -> impl Serialize for T:
    let fields = T.fields()
    impl Serialize for T:
        fn serialize(self: &T, out: &mut JsonWriter):
            out.begin_object()
            for field in fields:       // cascade: inside comptime fn
                out.key(field.name)
                self.{field.name}.serialize(out)
            out.end_object()

// Usage: just annotate the type
@[derive(Serialize)]
type User = { name: String, age: i32, email: String }

// The compiler generates (conceptually):
// impl Serialize for User:
//     fn serialize(self: &User, out: &mut JsonWriter):
//         out.begin_object()
//         out.key("name"); self.name.serialize(out)
//         out.key("age"); self.age.serialize(out)
//         out.key("email"); self.email.serialize(out)
//         out.end_object()
// }
```

`@[derive(Serialize)]` is sugar for invoking `derive_serialize[User]()`
at compile time. The generated code is regular With code — it goes
through type checking and borrow checking like any hand-written
implementation.

### 17.4 comptime Loops

`comptime for` unrolls at compile time. The loop body is stamped out
once per iteration with compile-time constants substituted:

```
comptime fn register_components[Ts: [type]]():
    for T in Ts:                       // already in comptime context
        world.register_storage[T](
            T.name(),
            T.size(),
        )

// Usage:
register_components[Position, Velocity, Health, Transform]()
```

**Comptime cascade:** Inside a `comptime fn` or `comptime for`, all
code is already executing at compile time. You don't need to prefix
inner `for`, `if`, or other statements with `comptime` — it
cascades automatically:

```
comptime fn generate_storage[T: type]:
    // These are all comptime — no prefix needed inside comptime fn:
    for field in T.fields():
        if field.type_name.starts_with("Vec["):
            emit_vec_storage(field)
        else:
            emit_scalar_storage(field)
```

The `comptime` prefix is only needed at the **entry point** — the
outermost `comptime fn`, `comptime for`, or `comptime if`. Everything
inside is already compile-time by context.

### 17.5 Compile-Time Branching

`comptime if` selects code paths at compile time. Dead branches are
not compiled:

```
fn serialize_value[T](val: &T, out: &mut Writer):
    comptime if T.is_copy():
        // Fast path for small Copy types
        out.write_bytes(val as *const u8, T.size())
    else if T.implements(Serialize):         // cascade: already comptime
        val.serialize(out)
    else:
        comptime_error("Type {T.name()} is not serializable")
```

`comptime_error` produces a compile error with a custom message.
This is the mechanism for "concept checking" — enforcing constraints
that can't be expressed as trait bounds.

### 17.6 Real-World Examples

**ECS component registration:**

```
@[component]
type Transform = { position: Vec3, rotation: Quat, scale: f32 }

// @[component] is a comptime annotation that generates:
// - Storage type (SoA layout via TypeInfo.fields)
// - Component ID (compile-time hash of type name)
// - Query accessors
// - Serialization
```

**Struct-of-Arrays transform:**

```
// Automatically generate SoA layout from AoS definition
comptime fn make_soa[T: type](capacity: usize) -> SoaStorage[T]:
    let fields = T.fields()
    // Generates a struct with one Vec per field:
    // { positions: Vec[Vec3], rotations: Vec[Quat], scales: Vec[f32] }
    // Plus accessors that reconstruct T from the parallel arrays
```

**Compile-time string hashing:**

```
comptime fn hash_str(s: str) -> u64:
    var h: u64 = 5381
    for c in s.bytes():
        h = h * 33 + c as u64
    h

const SHADER_PARAM_ID = comptime hash_str("world_matrix")
```

### 17.7 Constraints

1. **No runtime reflection.** `TypeInfo` is only available in
   `comptime` contexts. There is no way to inspect types at runtime.
2. **Generated code is checked.** All code produced by comptime goes
   through the type checker and borrow checker. comptime cannot
   violate language invariants.
3. **No I/O.** comptime code cannot read files, make network calls,
   or access the environment.
4. **Deterministic.** The same comptime expression with the same
   inputs always produces the same output.
5. **No macros.** With does not have token-level or AST-level macros.
   comptime with type introspection replaces the need for them. This
   is a deliberate choice to keep the compilation model simple — one
   phase, not two.

**Comptime in generic functions:** When a generic function contains
`comptime if` branches that depend on the type parameter `T`, the
type checker uses **deferred branch checking**: the initial generic
check verifies syntax and validates code *outside* comptime branches
normally, but code *inside* `comptime if` branches that depend on
`T` is deferred until monomorphization. When `T` is known, the
`comptime if` condition is evaluated, the taken branch is type-
checked against the concrete `T`, and the erased branch is discarded
without checking.

This is narrower than C++ templates (the non-comptime body is still
fully checked against the declared bounds on `T`) and broader than
Rust generics (comptime branches can use capabilities not declared
in bounds). The trade-off: a comptime branch error only appears
when that branch is instantiated with a specific `T`, similar to
Zig's compile-time generics.

```
fn process[T](val: &T):
    val.len()   // ERROR at generic check: T has no .len() method
    comptime if T.implements(Serialize):
        val.serialize()   // Deferred: checked only when T: Serialize
```

---

## 18. Modules and Packages

### 18.1 Modules

```
module math.vector

use std.collections.HashMap
```

### 18.2 Imports

Names are imported with `use`. Variant constructors, functions, and
types can all be imported:

```
use std.collections.{HashMap, HashSet}
use Shape.{Circle, Rectangle, Triangle}
use math.vector.{Vec3, dot, cross}
```

**Prelude:** The following are automatically imported into every module:
- `Option.{Some, None}`
- `Result.{Ok, Err}`
- `Bool.{true, false}`
- Primitive types (`i32`, `i64`, `f64`, `bool`, `Int`, `UInt`, etc.)
- `Unit`
- `Vec[T]`, `String` / `str`
- Traits: `Eq`, `Ord`, `Hash`, `Debug`, `Display`, `Default`, `Drop`, `Scoped`, `ScopedMut`
- `print`, `println`, `eprint`, `eprintln`
- `assert`, `assert_eq`, `assert_ne`, `require`, `check`, `panic`, `unreachable`, `todo`
- `drop[T](val: T)` — explicitly drop a value to trigger cleanup

Name precedence is deterministic: local bindings and explicit `use`
imports win over prelude names. If you define `print` in a module,
calls to `print(...)` resolve to your definition in that scope.

`drop` is a built-in identity function that takes any value by
move and does nothing — the value is destroyed when the argument
goes out of scope:

```
fn drop[T](val: T): ()
```

This is used to trigger resource cleanup at a specific point:

```
let (tx, rx) = chan[i32](10)
// ... send items ...
drop(tx)                 // close the send half, receivers see None
for item in rx:          // drains remaining items
    process(item)
```

### 18.3 Visibility

`pub` exports names. No `pub` = module-private.

### 18.4 Packages

Directory with `with.toml`. Single-file programs need no manifest.
Dependencies hash-pinned in lockfile.

### 18.5 Toolchain

A single binary provides all tools:

```
with build [--release] [--target <triple>]
with run <file>
with test
with fmt
with doc [--open]
with repl
```

Cross-compilation is a normal mode, not special.

### 18.6 Standard Library Design

The standard library is layered. Users write idiomatic With code
against `std.*` modules. They should never need `c_import` for
ordinary programming tasks.

**Layer 0: `c_import`** — compiler built-in (Phase 0). The mechanism
by which the standard library itself accesses platform APIs.

**Layer 1: `std.os`** — thin safe wrappers around platform APIs
(libc, POSIX, Win32). Written using `c_import` internally. Not
intended for direct use by application developers.

**Layer 2: `std.*`** — idiomatic, safe, cross-platform APIs. This is
what users import.

#### Module Map

**`std.io`** — I/O primitives and streams.

| Type / Function | Description |
|-----------------|-------------|
| `stdin()`, `stdout()`, `stderr()` | Standard streams |
| `Reader` trait | Read bytes from a source |
| `Writer` trait | Write bytes to a destination |
| `BufReader[R]` | Buffered reader wrapper |
| `BufWriter[W]` | Buffered writer wrapper |
| `print(s)`, `println(s)` | Write to stdout (prelude) |
| `eprint(s)`, `eprintln(s)` | Write to stderr |

Replaces: `stdio.h` (printf, fread, fwrite, stdin, stdout, stderr)

**`std.fs`** — File system operations.

| Type / Function | Description |
|-----------------|-------------|
| `File` | Owned file handle (implements Reader, Writer, Scoped) |
| `read_file(path) -> Result[String, IoError]` | Read entire file to string |
| `read_bytes(path) -> Result[Vec[u8], IoError]` | Read entire file to bytes |
| `write_file(path, data) -> Result[Unit, IoError]` | Write string to file |
| `create_dir(path)`, `create_dir_all(path)` | Directory creation |
| `remove_file(path)`, `remove_dir(path)` | Deletion |
| `rename(from, to)` | Move / rename |
| `exists(path) -> bool` | Path existence check |
| `metadata(path) -> Result[Metadata, IoError]` | File size, timestamps, permissions |
| `read_dir(path) -> Result[Vec[DirEntry], IoError]` | Directory listing |

Replaces: `stdio.h` (fopen, fclose, fread, fwrite), `unistd.h`
(read, write, close, unlink), `fcntl.h` (open, O_RDONLY),
`dirent.h` (opendir, readdir), `sys/stat.h` (stat, fstat)

**`std.time`** — Clocks and durations.

| Type / Function | Description |
|-----------------|-------------|
| `Instant` | Monotonic timestamp (for measuring elapsed time) |
| `Instant.now() -> Instant` | Current monotonic time |
| `Duration` | Time span (nanosecond precision) |
| `Duration.seconds(n)`, `.millis(n)`, `.nanos(n)` | Constructors |
| `Instant.elapsed(self) -> Duration` | Time since this instant |
| `SystemTime` | Wall-clock time (for display, logging) |
| `SystemTime.now() -> SystemTime` | Current wall-clock time |
| `sleep(duration)` | Block current thread/fiber |

Replaces: `time.h` (time, clock_gettime, nanosleep, difftime),
`sys/time.h` (gettimeofday)

**`std.math`** — Mathematical functions.

Most math functions are methods on `f32` and `f64`:
`x.sin()`, `x.cos()`, `x.sqrt()`, `x.pow(n)`, `x.abs()`,
`x.floor()`, `x.ceil()`, `x.round()`, `x.log()`, `x.log2()`,
`x.atan2(y)`, `x.clamp(min, max)`, `x.min(y)`, `x.max(y)`.

Constants: `std.math.PI`, `std.math.E`, `std.math.TAU`,
`std.math.INFINITY`, `std.math.NAN`.

Replaces: `math.h` (sin, cos, sqrt, pow, fabs, floor, ceil, log,
atan2, fmin, fmax)

**`std.collections`** — Data structures.

| Type | Description |
|------|-------------|
| `Vec[T]` | Growable array (prelude) |
| `HashMap[K, V]` | Hash map |
| `HashSet[T]` | Hash set |
| `BTreeMap[K, V]` | Ordered map |
| `BTreeSet[T]` | Ordered set |
| `VecDeque[T]` | Double-ended queue |
| `SlotMap[T]` | Generational arena (§6) |
| `Handle[T]` | Generational index into SlotMap |

All collection types provide `.len()` returning `usize`, plus
**convenience narrowing methods** that avoid the ubiquitous
`.len() as i32` cast:

| Method | Return | Behavior |
|--------|--------|----------|
| `.len()` | `usize` | Length (always available) |
| `.len32()` | `i32` | Panics if len > `i32.max` |
| `.len64()` | `i64` | Panics if len > `i64.max` |
| `.ulen32()` | `u32` | Panics if len > `u32.max` |

All collection types implement `Contains[T]` (§11.7), enabling the
`in` operator for membership tests: `if key in map:`,
`if x in my_vec:`, etc. See §9.9 for details and the full
implementation table.

```
// Before: manual casting
let count: i32 = results.len() as i32

// After: bounds-checked narrowing
let count: i32 = results.len32()
```

These are bounds-checked: they panic if the collection is larger
than the target type can represent. In practice, collections with
more than 2 billion elements are rare — `.len32()` is safe for
nearly all real code.

Replaces: no C equivalent (C has no standard collections)

**`std.string`** — String types and operations.

Built into the language: `String` (owned, heap, UTF-8),
`StrView` (ephemeral view), `CStr` (ephemeral C string view),
`CString` (owned C string). See §15.

Rich methods on `String` and `StrView`: `split`, `trim`,
`starts_with`, `ends_with`, `contains`, `replace`, `to_upper`,
`to_lower`, `find`, `rfind`, `chars`, `bytes`, `len`,
`is_empty`, `repeat`, `join`.

`String` and `str` implement `Contains[str]` and `Contains[char]`,
enabling `if "error" in log_line:` and `if '@' in email:`. See §9.9.

Replaces: `string.h` (strlen, strcmp, strcpy, strstr, memcpy,
memset), `ctype.h` (isalpha, isdigit, toupper, tolower)

**`std.net`** — Networking.

| Type / Function | Description |
|-----------------|-------------|
| `TcpListener` | TCP server socket |
| `TcpStream` | TCP connection (implements Reader, Writer) |
| `UdpSocket` | UDP socket |
| `SocketAddr` | IP address + port |
| `resolve(host) -> Result[Vec[IpAddr], NetError]` | DNS resolution |

Replaces: `sys/socket.h` (socket, bind, listen, accept, connect),
`netdb.h` (getaddrinfo), `arpa/inet.h` (inet_pton)

**`std.thread`** — OS-level threading.

| Type / Function | Description |
|-----------------|-------------|
| `spawn_os(fn() -> T) -> JoinHandle[T]` | Spawn OS thread |
| `JoinHandle[T]` | Handle to join a thread |
| `current() -> ThreadId` | Current thread identifier |
| `yield_now()` | Yield to scheduler |
| `available_parallelism() -> usize` | Number of CPU cores |

Replaces: `pthread.h` (pthread_create, pthread_join),
`threads.h` (thrd_create)

**`std.sync`** — Synchronization primitives.

| Type | Description |
|------|-------------|
| `Mutex[T]` | Mutual exclusion lock (implements ScopedMut) |
| `RwLock[T]` | Reader-writer lock (implements Scoped / ScopedMut) |
| `Atomic[T]` | Atomic integer/bool/pointer operations |
| `Condvar` | Condition variable |
| `Barrier` | Thread barrier |
| `Once` | One-time initialization |

Guard types (`MutexGuard`, `ReadGuard`, `WriteGuard`) are annotated
`@[no_await_guard]` — the compiler rejects `.await` inside `with`
blocks holding these guards. See §7.9.

Replaces: `pthread.h` (pthread_mutex_*, pthread_rwlock_*,
pthread_cond_*), `stdatomic.h`

**`std.process`** — Process control.

| Type / Function | Description |
|-----------------|-------------|
| `exit(code: i32)` | Terminate process |
| `args() -> Vec[String]` | Command-line arguments |
| `env(name) -> Option[String]` | Environment variable |
| `set_env(name, value)` | Set environment variable |
| `Command` | Builder for spawning child processes |

Replaces: `stdlib.h` (exit, getenv, setenv, system),
`unistd.h` (execve, fork)

**`std.mem`** — Low-level memory operations.

| Type / Function | Description |
|-----------------|-------------|
| `Allocator` trait | Custom allocator interface |
| `GlobalAlloc` | Default system allocator |
| `mmap(len, prot) -> Result[MappedMem, IoError]` | Memory-mapped region |
| `copy[T](src, dst, count)` | Typed memcpy |
| `zero[T](ptr, count)` | Typed memset zero |
| `size_of[T]() -> usize` | Size at compile time |
| `align_of[T]() -> usize` | Alignment at compile time |

Replaces: `stdlib.h` (malloc, free, realloc), `string.h`
(memcpy, memset, memmove), `sys/mman.h` (mmap, munmap)

**`std.alloc`** — Allocator utilities.

| Type | Description |
|------|-------------|
| `Arena` | Bump allocator (bulk free) |
| `Pool[T]` | Fixed-size object pool |

Replaces: no C equivalent

**`std.signal`** — Signal handling (thin wrapper, inherently unsafe).

| Function | Description |
|----------|-------------|
| `on_signal(sig, handler)` | Register signal handler |
| `Signal` enum | SIGINT, SIGTERM, SIGHUP, etc. |

Replaces: `signal.h` (signal, sigaction)

**`std.random`** — Random number generation.

| Type / Function | Description |
|-----------------|-------------|
| `Rng` | Pseudo-random number generator |
| `Rng.new() -> Rng` | Seed from system entropy |
| `Rng.from_seed(seed) -> Rng` | Deterministic seed |
| `rng.next_i32()`, `.next_f64()`, `.next_bool()` | Generate values |
| `rng.range(lo, hi) -> i32` | Uniform range |
| `rng.shuffle(slice)` | In-place shuffle |

Replaces: `stdlib.h` (rand, srand, random)

**`std.hash`** — Hashing.

| Type | Description |
|------|-------------|
| `Hasher` trait | Hashable interface |
| `DefaultHasher` | General-purpose hash |
| `hash(val) -> u64` | Hash any `Hash`-implementing value |

Replaces: no C equivalent

**`std.fmt`** — Formatting and display.

| Trait | Description |
|-------|-------------|
| `Display` | Human-readable formatting |
| `Debug` | Developer-readable formatting |
| `format(template, args...) -> String` | String formatting |

String interpolation (`"hello {name}"`) desugars to `Display::fmt`
calls.

Replaces: `stdio.h` (sprintf, snprintf, fprintf)

**`std.testing`** — Test utilities and assertions.

| Function | Description |
|----------|-------------|
| `assert(condition: bool)` | Panics if false (prelude) |
| `require(condition: bool, message: str)` | Panics with "IllegalArgumentError: {message}" if false (prelude) |
| `check(condition: bool, message: str)` | Panics with "IllegalStateError: {message}" if false (prelude) |
| `assert_eq(left, right)` | Panics if `left != right`, shows both values |
| `assert_ne(left, right)` | Panics if `left == right`, shows both values |
| `assert_matches(value, pattern)` | Panics if `value` does not match `pattern` |
| `panic(msg: &str) -> Never` | Unconditional panic with message (prelude) |
| `unreachable() -> Never` | Panics with "entered unreachable code" (prelude) |
| `unreachable(msg: &str) -> Never` | Panics with custom message (prelude) |
| `todo() -> Never` | Panics with "not yet implemented" (prelude) |
| `todo(msg: &str) -> Never` | Panics with custom "not yet implemented" message |

`assert`, `require`, `check`, `panic`, `unreachable`, and `todo` are
in the prelude — no import needed.

`require` and `check` are contract-style assertions that distinguish
between caller errors and internal invariant violations:

```
fn withdraw(amount: i64, balance: i64) -> i64:
    require(amount > 0, "amount must be positive")
    require(amount <= balance, "insufficient funds")
    let result = balance - amount
    check(result >= 0, "balance went negative after withdrawal")
    result
```

`require` signals that the **caller** violated a precondition — it
panics with `IllegalArgumentError: {message}`. `check` signals that
an **internal invariant** was violated — it panics with
`IllegalStateError: {message}`. Both have lazy message evaluation:
the message string is not constructed when the condition is true.

`assert_matches` checks a value against a pattern:

```
// Before:
match result
    Err(.Db(.NotFound(..))) -> assert(true)
    _ -> assert(false)

// After:
assert_matches(result, Err(.Db(.NotFound(..))))
```

`unreachable()` documents code paths that should never execute.
The return type is `Never`, so it satisfies any type context:

```
match direction
    .North -> go_north()
    .South -> go_south()
    .East  -> go_east()
    .West  -> go_west()
    _      -> unreachable()     // enum is exhaustive

fn get_config -> Config:
    // This function always succeeds in our deployment
    load_config() ?? unreachable("config must exist")
```

`todo()` marks unfinished code. It compiles (returns `Never`) but
panics at runtime:

```
fn complex_algorithm(data: &[i32]) -> i32:
    todo("implement after benchmarking")
```

#### The errno Principle

C's `errno` does not exist **as a user-facing API pattern** in With.
Every fallible operation returns `Result[T, E]` with a specific error
type. Error types are enums, not integers. They carry context (file
paths, operation names, OS error codes) as structured data, not
global mutable state.

```
// C: open() returns -1, check errno
// With:
let file = std.fs.File.open(path)?    // returns Result[File, IoError]
```

**Stdlib access to `errno`:** The standard library *internally* reads
the C `errno` value via the compiler intrinsic `std.os.c_errno()`.
This is not a `c_import` translation (since `errno` on glibc is a
complex macro `(*__errno_location())`). Instead, the compiler
lowers `c_errno()` to the platform-appropriate thread-local access:

```
// Inside std.fs (user never sees this):
let fd = open(path_cstr.ptr, O_RDONLY)
if fd == -1:
    let code = std.os.c_errno()    // compiler intrinsic
    return Err(IoError.from_errno(code, path))
```

Users writing safe With code never touch `errno`. Users writing
`unsafe` FFI bindings can call `std.os.c_errno()` to read the
thread-local errno value after a C function returns.

#### Platform Abstraction

`std.os.posix` and `std.os.windows` exist for platform-specific
access. Cross-platform modules in `std.*` use conditional
compilation internally:

```
// Inside std.fs (user never sees this):
comptime if cfg.target_os == "linux":
    use c_import("fcntl.h", link: "c")
comptime else if cfg.target_os == "windows":
    use c_import("windows.h")
```

Users writing portable code import `std.fs`, not `std.os.posix`.
Users writing platform-specific code (system daemons, kernel
modules) can reach through to `std.os` or use `c_import` directly.

### 18.7 Freestanding Mode (`no_std`)

For embedded, kernel, bootloader, and bare-metal targets, the
standard library can be skipped entirely. Set `std = false` in
`with.toml`:

```toml
[package]
name = "my-firmware"
std = false
```

Or pass `--no-std` to the compiler:

```
with build --no-std --target thumbv7em-none-eabi
```

**What you keep (`core`):**

The `core` library is always available. It contains everything
that doesn't need a heap allocator or OS:

| Category | What's included |
|----------|----------------|
| Primitives | `i8`–`i64`, `u8`–`u64`, `f32`, `f64`, `bool`, `usize` |
| Traits | `Copy`, `Clone`, `Drop`, `Default`, `Debug`, `Eq`, `Ord`, `Hash` |
| Option/Result | `Option[T]`, `Result[T, E]` and all methods |
| Slices | `&[T]`, `&mut [T]` — borrowed views into arrays |
| Fixed arrays | `[T; N]` — stack-allocated |
| Tuples | `(A, B, ...)` |
| Ranges | `0..10`, `0..=10` |
| Math | Integer and float arithmetic, `min`, `max`, `abs` |
| Bitwise | All bit operations on integer types |
| Pointers | `*T`, `*mut T`, raw pointer operations (unsafe) |
| Comptime | All compile-time evaluation (§17) |
| `c_import` | Full C interop — this is how you talk to hardware |
| Ownership | Full borrow checker, move semantics, drop — all compile-time, zero cost |
| `@[panic_handler]` | Custom panic behavior (see below) |
| `Never` type | For diverging functions |
| `unsafe` blocks | Full unsafe capabilities |
| `comptime if` | Conditional compilation |

**What you lose (`std` only):**

| Category | Requires `std` | Why |
|----------|---------------|-----|
| `str`, `String` | Yes | Heap-allocated |
| `Vec[T]` | Yes | Heap-allocated |
| `HashMap`, `HashSet` | Yes | Heap-allocated |
| `Box[T]` | Yes | Heap-allocated |
| `println`, `print` | Yes | Needs stdout |
| `std.io`, `std.fs` | Yes | Needs OS |
| `std.net` | Yes | Needs OS |
| `async fn`, `.await` | Yes | Needs fiber runtime |
| `std.sync` (channels) | Yes | Needs OS threads |

**String literals in `no_std`:** Bare `"hello"` is `&str` (static
reference) in `no_std` mode — there is no allocator to create
an owned `str`. This is the one context where the default type of
a string literal changes. If you need owned strings in `no_std`,
bring your own allocator and use `FixedString[N]` or a similar
stack-allocated string type.

**Panic handler:** In `no_std` mode, you must provide a panic
handler. Without one, the compiler errors:

```
@[panic_handler]
fn on_panic(info: &PanicInfo) -> Never:
    // Option 1: spin forever
    loop {}

    // Option 2: reset the chip
    // cortex_m.SCB.system_reset()
```

**Entry point:** There is no `fn main` in `no_std` unless you
define it yourself. Use `@[entry]` to mark your entry point,
or `@[no_main]` to handle startup entirely through C interop
or linker scripts:

```
@[no_main]
@[entry]
fn start -> Never:
    // Initialize hardware
    let peripherals = c_import("stm32f4xx.h")
    // ...
    loop
        // main loop
```

**Allocator opt-in:** You can get `Vec`, `str`, `Box`, and
other heap types back without pulling in the full `std` by
providing a global allocator:

```toml
[package]
name = "my-firmware"
std = false
alloc = true       # enables core + alloc (heap types, no OS)
```

```
@[global_allocator]
static ALLOC: BumpAllocator = BumpAllocator.new(
    start: 0x2000_0000,
    size: 64 * 1024,    // 64KB SRAM
)
```

With `alloc = true`, you get `Vec[T]`, `Box[T]`, `str`,
`String`, `HashMap`, and `HashSet` — but still no I/O, no
filesystem, no async runtime, no OS-dependent features.

**Three tiers:**

| Tier | `with.toml` | What you get |
|------|-------------|--------------|
| Full | `std = true` (default) | Everything |
| Alloc | `std = false`, `alloc = true` | `core` + heap types |
| Freestanding | `std = false` | `core` only — no heap |

**Embedded hello world:**

```
// with.toml: std = false, target = "thumbv7em-none-eabi"

use c_import("stm32f4xx_hal.h", link: "hal")

@[panic_handler]
fn on_panic(info: &PanicInfo) -> Never:
    loop {}

@[entry]
fn start -> Never:
    let led = gpio_init(GPIOA, PIN_5, .Output)
    loop
        gpio_toggle(led)
        delay_ms(500)
```

Everything With gives you — ownership, borrow checking, `c_import`,
`match`, `comptime`, type inference — works in freestanding mode.
You're just writing With without a heap or an OS.

---

## 19. Safety Boundaries

### 19.1 Safe by Default

All code is safe unless explicitly `unsafe`.

### 19.2 `unsafe` Required For

- Raw pointer dereference
- FFI function calls
- Intrusive / self-referential structures
- Manual memory management beyond allocators
- Calling functions marked `unsafe`

### 19.3 `unsafe` Constraints Across Suspension Points

**Language rule:** Unsafe code must not retain raw pointers (`*const T`,
`*mut T`) to fiber stack locals across `await` points. A raw pointer
to a stack-allocated value is valid only until the next `await` in the
same fiber.

```
// UNDEFINED BEHAVIOR:
async fn bad:
    let x = 42
    let p: *const i32 = &raw x
    some_io().await          // stack may be relocated
    unsafe { *p }            // UB: p may be dangling

// OK: pointer used before await
async fn ok:
    let x = 42
    let p: *const i32 = &raw x
    unsafe { use(p) }        // fine: no intervening await
    some_io().await
```

Safe code is not affected by this rule — ephemeral references across
`await` points are handled correctly by the compiler. This constraint
applies only to raw pointers obtained through `unsafe`.

### 19.4 Unnecessary `unsafe` is a Compile Error

An `unsafe` block that contains no unsafe operations is a compile
error:

```
// ERROR: unnecessary unsafe block
unsafe {
    let x = 1 + 2    // nothing here requires unsafe
}
```

Every `unsafe` block in a codebase is a place reviewers must
scrutinize. False positives dilute that signal. If the block contains
no raw pointer dereference, no FFI call, and no `unsafe fn` call,
the compiler rejects it.

---

## 20. Performance Guarantees

1. **Allocations are obvious.** You can see where allocation
   happens — `Vec.new()`, `.to_owned()`, `[x for x in ...]`,
   `"hello {name}"`. No allocation hides behind innocent syntax.
   But the language doesn't force you to type `collect[Vec]()` when
   the intent is already clear.
2. **No hidden copies.** Values move unless `Copy`.
3. **No hidden reference counting.** Only via explicit `Rc`/`Arc`.
4. **No hidden synchronization.** Locks, atomics always explicit.
5. **No hidden runtime in `no_runtime` builds.** The fiber scheduler
   is the one blessed runtime; it is opt-in via `async` and absent
   when disabled. Suspension is always marked with `await`.
6. **Deterministic destruction.** Reverse declaration order.
7. **Disjoint borrow analysis guaranteed.**

---

## 20b. Denied Patterns (Compile Errors)

With forbids patterns that are almost always bugs and have clean
alternatives. These are compile errors, not warnings. The philosophy:
if a pattern is wrong 99% of the time, don't warn — forbid.

### 20b.1 `.await` Inside `@[no_await_guard]` Guard

Types annotated `@[no_await_guard]` (synchronization guards like
`MutexGuard`, `ReadGuard`, `WriteGuard`, `ArenaScope`) must not be
held across suspension points. Holding a mutex across `.await` blocks
all other fibers waiting for that lock.

```
// ERROR: RwLock guard is @[no_await_guard]
with lock.read() as data:
    fetch(data.url).await

// FIX: clone out, release guard, then await
let url = with lock.read() as data:
    data.url.clone()
fetch(url).await
```

This does NOT apply to connection pools, transactions, file handles,
or other `Scoped` types that don't carry the annotation. See §7.9.

### 20b.2 Unused `Result` or `Option`

Ignoring a `Result` silently swallows an error. Ignoring an `Option`
discards a value.

```
// ERROR:
db.execute("DROP TABLE users")

// FIX: propagate, handle, or explicitly discard
db.execute("DROP TABLE users")?
let _ = db.execute("DROP TABLE users")
```

See §10.1.

### 20b.3 Unused `Task`

Dropping a `Task` without `await`ing or `cancel`ing it silently
cancels work.

```
// ERROR:
send_analytics("page_view")

// FIX — await the result:
send_analytics("page_view").await

// FIX — fire-and-forget (runs to completion, detached):
spawn send_analytics("page_view")

// FIX — explicit cancellation:
let task = send_analytics("page_view")
cancel(task)
```

**WARNING:** `let _ = send_analytics(...)` is NOT fire-and-forget.
It immediately drops the Task, cancelling it before it completes.
The compiler warns about this pattern. Use `spawn` for true
fire-and-forget.

See §14.7.

### 20b.4 Unnecessary `unsafe` Block

An `unsafe` block with no unsafe operations dilutes the safety
signal.

```
// ERROR:
unsafe { let x = 1 + 2 }

// FIX: remove the unsafe block
let x = 1 + 2
```

See §19.4.

### 20b.5 Implicit Numeric Narrowing

Assigning a wider type to a narrower type silently truncates.

```
// ERROR:
let big: i64 = 100000
let small: i32 = big

// FIX: explicit cast
let small: i32 = big as i32
```

Signed/unsigned conversions at the same width also require `as`.
See §4.2.

### 20b.6 Unreachable Code

Code after an unconditional `return`, `break`, `continue`, or
diverging expression is dead. It is always either a bug or
leftover from refactoring.

```
// ERROR:
fn example -> i32:
    return 42
    println("hello")    // unreachable

// ERROR:
for x in items:
    if should_skip(x) then
        continue
        log("skipped")  // unreachable
```

The compiler detects unreachable code via control flow analysis and
rejects it. This applies to all code after unconditional control
flow transfers, including `return`, `break`, `continue`, and calls
to functions with return type `Never` (e.g., `exit()`, `panic()`).

**Exception for `comptime if`:** The unreachable code check runs
**after** comptime evaluation. Branches eliminated by `comptime if`
are erased before the check, so code that is only unreachable due
to comptime decisions does not trigger an error:

```
comptime if cfg.is_debug:
    return debug_value()
// In debug builds, this code is erased — no "unreachable" error
// In release builds, comptime if is false — code is reachable
let result = expensive_computation()
```
---

# Part II — Normative Rules

These sections define **what** the compiler must enforce. Implementation
strategies (algorithms, data structures, lowering approaches) are in
the companion document: *Implementation Notes*.

---

## 21. Borrow Checker Rules

The borrow checker is intra-procedural only. Because references cannot
be stored and cannot escape except as ephemeral returns, cross-function
lifetime reasoning is never required.

### 21.1 Rules

At every program point, the following must hold:

1. **Aliasing rule.** For any place (variable or field path), either
   any number of shared borrows (`&T`) are active, or exactly one
   exclusive borrow (`&mut T`) is active. Never both.

2. **Move validity.** A move of a place must not occur while any
   borrow of that place (or an overlapping place) is active.

3. **Use-after-move.** A binding that has been moved from must not
   be used.

4. **NLL scoping.** A borrow is active from its creation to the
   last program point that uses the borrowed reference. Not to the
   end of the enclosing block.

5. **Disjoint field borrowing.** Two borrows of field paths that
   diverge at any field access are non-overlapping and may coexist,
   even if one is exclusive. Array/slice indices are conservatively
   treated as overlapping.

6. **Ephemeral return conservation.** When a function returns an
   ephemeral value and accepts multiple reference parameters, the
   compiler **by default** treats the return as borrowing from all
   reference inputs. However, the compiler has built-in knowledge
   of stdlib types (HashMap, Vec, slice iterators, etc.) and
   correctly narrows the borrow to the relevant parameter. For user
   code, the conservative default applies. The stdlib achieves
   correct narrowing via `unsafe` internally — users never see it.

7. **Implicit drop is a use.** When a variable implementing `Drop`
   goes out of scope, its implicit destructor call is treated as a
   **use** of that variable for borrow-checking purposes. This
   prevents use-after-free in cases like:

   ```
   var v: Vec[&i32] = Vec.new()
   var x = 5
   v.push(&x)
   // End of scope: x drops first, then v drops.
   // v.drop() accesses &x, but x is already freed!
   // Rejected: v's implicit drop uses &x after x is destroyed.
   ```

   The compiler inserts implicit drop points at scope exit in
   reverse declaration order. Each drop point is a "use" of the
   variable being dropped, extending the borrow lifetime through
   the destructor.

---

## 22. Ephemeral Type Rules

Post-type-check analysis. No dataflow required — ephemerality is
determined structurally by types.

### 22.1 Rules

| # | Condition | Result |
|---|-----------|--------|
| 1 | Type is `&T`, `&mut T`, `StrView`, `&[T]`, `&mut [T]` | Ephemeral |
| 2 | Type is declared `ephemeral` | Ephemeral |
| 3 | Generic `F[T]` where `T` is ephemeral | Ephemeral |
| 4 | Struct has ephemeral field but is not marked `ephemeral` | Reject definition |
| 5 | `let x = expr` where expr is ephemeral | Bind `x` as ephemeral |
| 6 | Struct field declared with ephemeral type | Reject |
| 7 | Ephemeral value inserted into heap container | Container becomes ephemeral |
| 8 | Function returns ephemeral type | Callers inherit restriction |
| 9 | Escaping closure captures ephemeral value | Reject |
| 10 | Guarded `with` block (Form 1) result is ephemeral | Reject |

Rule 7: A `Vec[T]` where `T` is ephemeral becomes an ephemeral
`Vec`. It can be used as a local variable but cannot be stored in
structs, returned from functions, or sent to other threads. This
enables common patterns like collecting tokens from a parser:

```
// Token is ephemeral (contains StrView)
let tokens = with Vec.new() as mut toks:
    while let Some(tok) = next_token(&mut parser):
        toks.push(tok)
// tokens: Vec[Token] is itself ephemeral — valid only in this scope
// Cannot store tokens in a struct or return it from the function
```

This is consistent with Rule 3 (generic container inherits
ephemerality from its type parameter).

Rule 10 applies only to Form 1 (where the expression implements
`Scoped`/`ScopedMut`). The guard is released when the block exits,
so any ephemeral borrowing from the guard's payload would dangle.
Forms 2 and 3 desugar to plain `let`/`var` blocks — their results
follow normal ephemeral rules (rules 5, 8).

### 22.2 Closure Escaping (v1.0)

A closure is non-escaping if and only if it appears as a direct
argument to a function call. All other closures are escaping.

---

## 23. `with` Block Semantics

### 23.1 Dispatch Rule

The compiler selects the `with` form based on the expression's type:

| Syntax | Type has `Scoped`/`ScopedMut`? | Desugaring |
|--------|-------------------------------|------------|
| `with e as x: body` | Yes (`Scoped`) | `e.enter(\|x\| body)` |
| `with e as mut x: body` | Yes (`ScopedMut`) | `e.enter_mut(\|x\| body)` |
| `with e as mut x: body` | No | `{ var x = e; body }` |
| `with e as x: body` | No | `{ let x = e; body }` |

`Scoped`/`ScopedMut` implementations take priority. If the type
implements the trait, the guarded form is used.

### 23.2 Multiple Bindings

Multiple bindings nest left-to-right:
`with a as x, b as mut y: body` is equivalent to
`a.enter(|x| b.enter_mut(|y| body))`.

Multiple bindings in the non-guarded (binding) forms follow the
same nesting: each binding is in scope for all subsequent bindings
and the body.

### 23.3 Non-Local Control Flow

All `with` forms are transparent for control flow. The following
observable behaviors are required:

- `return` inside a `with` block returns from the **enclosing function**.
- `break` inside a `with` block breaks the **enclosing loop**.
- `continue` inside a `with` block continues the **enclosing loop**.
- `?` inside a `with` block propagates to the **enclosing function**.

The mechanism by which the compiler achieves this is unspecified.
Possible approaches include tagged-union returns, inlining the
`enter` call, or compiler-special-cased lowering.

---

## 24. `async`/`.await` Equivalences

### 24.1 `async fn` Equivalence

`async fn foo(x: T) -> U: body` is equivalent to a function that
spawns a fiber executing `body` and returns a `Task[U]`:

```
fn foo(x: T) -> Task[U]
```

There is no separate "async function type." `foo` is a regular
function that returns `Task[U]`. This is why Invariant 1 (no async
function type) holds.

### 24.2 `.await` Equivalence

`task.await` suspends the current fiber until `task` completes,
then evaluates to the task's result. If the task is already complete,
no suspension occurs.

### 24.3 `no_runtime` Gate

In `no_runtime` builds, any occurrence of `async fn`, `.await`, or
`async scope` is a **compile error**. This is a hard gate, not a
runtime fallback.

---

# Part III — Test Suite

---

## 25. Test Cases

### 25.1 Ownership and Moves (Section 2)

```
// PASS: basic move
fn test:
    let a = Vec.new()
    let b = a
    b.push(1)

// FAIL: use after move
fn test:
    let a = Vec.new()
    let b = a
    a.push(1)            // ERROR: use of moved value

// PASS: copy type
fn test:
    let a: i32 = 5
    let b = a
    let c = a            // OK: Copy

// FAIL: use after move to function
fn takes(v: Vec[i32]): ()
fn test:
    let a = Vec.new()
    takes(a)
    a.len()              // ERROR: moved
```

### 25.2 References and Second-Class Rule (Section 3)

```
// PASS: reference as local
fn test:
    let x = 42
    let r = &x
    println(r)

// FAIL: reference in struct
type Bad = { data: &i32 }        // ERROR

// FAIL: reference in container
fn test:
    let x = 42
    var v = Vec.new()
    v.push(&x)                   // ERROR

// PASS: non-escaping closure captures ref
fn test:
    let x = 42
    let r = &x
    vec![1, 2, 3].for_each(|item| println("{item} {r}"))

// FAIL: escaping closure captures ref
fn test:
    let x = 42
    let r = &x
    thread.spawn_os(|| println(r))   // ERROR
```

### 25.3 Returning References (Section 3.4)

```
// PASS: return ref, use locally
fn first(xs: &Vec[i32]) -> Option[&i32]:
    if xs.is_empty() then None else Some(&xs[0])

fn test:
    let v = vec![1, 2, 3]
    match first(&v)
        Some(x) -> println(x)
        None    -> ()

// PASS: ephemeral to owned conversion
fn get_name(user: &User) -> StrView: user.name.as_view()
fn owned(user: &User) -> String: get_name(user).to_string()
```

### 25.4 NLL Borrow Scoping (Section 3.5)

```
// PASS: borrow ends at last use
fn test:
    var x = 5
    let r = &x
    println(r)
    x = 10           // OK

// FAIL: mutation while borrow active
fn test:
    var x = 5
    let r = &x
    x = 10           // ERROR
    println(r)

// PASS: mutable then shared
fn test:
    var x = 5
    let r = &mut x
    *r = 10          // last use
    let s = &x       // OK
    println(s)
```

### 25.5 Disjoint Field Borrowing (Section 3.6)

```
type Pair = { a: Vec[i32], b: Vec[i32] }

// PASS: distinct fields
fn test(p: &mut Pair):
    let a = &mut p.a
    let b = &mut p.b
    a.push(1); b.push(2)

// FAIL: same field twice
fn test(p: &mut Pair):
    let a1 = &mut p.a
    let a2 = &mut p.a     // ERROR

// PASS: nested disjoint
type Deep = { inner: Pair }
fn test(d: &mut Deep):
    let a = &mut d.inner.a
    let b = &mut d.inner.b
    a.push(1); b.push(2)

// FAIL: field then whole struct
fn test(p: &mut Pair):
    let a = &mut p.a
    let whole = &p         // ERROR: overlaps p.a
```

### 25.6 Ephemeral Types (Section 5)

```
// PASS: ephemeral local
fn test:
    let v = "hello".as_view()
    println(v)

// FAIL: ephemeral in struct
type Bad = { view: StrView }      // ERROR

// PASS: explicit ephemeral struct
type Ok = ephemeral { view: StrView }

// FAIL: ephemeral in container
fn test:
    let v = "hello".as_view()
    var vec = Vec.new()
    vec.push(Some(v))             // ERROR: Option[StrView] is ephemeral
```

### 25.7 `with` Blocks (Section 7)

```
// PASS: basic
fn test(lock: &Mutex[HashMap[str, i32]]):
    with lock.lock() as mut map:
        map.insert("key", 42)

// PASS: multi
fn test(a: &RwLock[Vec[i32]], b: &RwLock[Vec[i32]]):
    with a.read() as xs, b.read() as ys:
        println(xs.len() + ys.len())

// PASS: expression returning owned
fn test(lock: &Mutex[HashMap[str, i32]]) -> Option[i32]:
    with lock.lock() as map:
        map.get("key").cloned()

// FAIL: expression returning ephemeral
fn test(lock: &Mutex[Vec[i32]]):
    let r = with lock.lock() as data:
        &data[0]                  // ERROR

// PASS: collect pipeline escapes
fn test(store: &Shared[SlotMap[Texture]]) -> Vec[Handle[Texture]]:
    with store.read() as textures:
        textures.iter()
        |> filter(|(_h, t)| t.width > 1024)
        |> map(|(h, _)| h)
        |> collect()

// PASS: error propagation with implicit Ok wrapping
fn test(lock: &Mutex[File]) -> Result[Unit, IoError]:
    with lock.lock() as mut f:
        f.write_all(b"hello")?
        f.flush()?
    // implicit Ok(())

// PASS: non-local return from with block
fn find_val(lock: &Mutex[HashMap[str, i32]], key: &str) -> Option[i32]:
    with lock.lock() as map:
        match map.get(key)
            Some(v) -> return Some(v)    // returns from find_val
            None    -> ()
    None

// PASS: break/continue inside with block inside loop
fn process(lock: &Mutex[Vec[Item]]):
    for i in 0..10:
        with lock.lock() as items:
            if items[i].is_done():
                continue                  // continues enclosing for loop
            items[i].process()

// --- Form 2: Builder pattern (scoped mutation) ---

// PASS: basic builder
type Config = { timeout: i32, retries: i32, verbose: bool }
fn test:
    let c = with Config { timeout: 0, retries: 0, verbose: false } as mut c:
        c.timeout = 30
        c.retries = 3
        c.verbose = true
    assert(c.timeout == 30)
    assert(c.retries == 3)

// PASS: builder is an expression
fn make_config -> Config:
    with Config { timeout: 0, retries: 0, verbose: false } as mut c:
        c.timeout = 30

// PASS: nested with in builder
fn test:
    let sprite = with Sprite.new() as mut s:
        s.position = Vec2.new(100.0, 200.0)
        s.health = with difficulty_mult() as mult:
            base_health * mult

// --- Form 3: Scoped binding ---

// PASS: basic scoped binding
fn test:
    let area = with shape.bounding_box() as bb:
        bb.width * bb.height
    assert(area > 0.0)

// PASS: scoped binding avoids name leakage
fn test:
    let x = with expensive_compute() as result:
        result + 1
    // `result` is not visible here

// PASS: scoped binding in pipeline context
fn test:
    let label = with user.display_name.unwrap_or(user.username) as name:
        "{name} ({user.role})"
```

### 25.8 Handles and SlotMap (Section 6)

```
// FAIL: handle type mismatch
fn test:
    var textures = SlotMap[Texture].new()
    var meshes = SlotMap[Mesh].new()
    let h = textures.insert(Texture.default())
    meshes.get(h)                 // ERROR: Handle[Texture] vs Handle[Mesh]

// PASS: get2_mut
fn test:
    var map = SlotMap[i32].new()
    let a = map.insert(10)
    let b = map.insert(20)
    match map.get2_mut(a, b)
        Some((va, vb)) -> { *va += 1; *vb += 1 }
        None -> ()

// PASS: handles in containers
fn test:
    var map = SlotMap[String].new()
    let h1 = map.insert("hello")
    let h2 = map.insert("world")
    let handles = vec![h1, h2]    // OK: Copy, storable
```

### 25.9 Error Handling (Section 10)

```
error ParseError = InvalidSyntax(pos: usize)
error IoError = NotFound(path: String)
error AppError from IoError, ParseError

// PASS: propagation with conversion
fn load(path: &str) -> Result[Ast, AppError]:
    let text = read_file(path)?        // IoError -> AppError
    parse(&text)?                      // ParseError -> AppError

// PASS: match converted error
fn handle(e: AppError):
    match e
        AppError.Io(io)    -> println("io: {io}")
        AppError.Parse(pe) -> println("parse: {pe}")

// FAIL: non-exhaustive
fn bad(e: AppError):
    match e
        AppError.Io(_) -> ()          // ERROR: missing Parse
```

### 25.10 Traits and Coherence (Section 11)

```
trait Show:
    fn show(self: &Self) -> String

// FAIL: orphan rule
impl Show for Vec[i32]:             // ERROR
    fn show(self: &Vec[i32]) -> String: "vec"

// PASS: own type
type MyType = { x: i32 }
impl Show for MyType:
    fn show(self: &MyType) -> String: "MyType"
```

### 25.11 FFI and `c_import` (Section 16)

```
// PASS: c_import makes C functions callable directly
use c_import("stdio.h")
fn test:
    printf(c"hello %d\n".ptr, 42)             // no unsafe needed

// PASS: c_import with link directive
use c_import("sqlite3.h", link: "sqlite3")
fn test:
    var db: *mut sqlite3 = null
    let rc = sqlite3_open(c":memory:".ptr, &mut db)  // direct call
    assert(rc == SQLITE_OK)
    sqlite3_close(db)

// PASS: c_import structs are usable
use c_import("time.h")
fn test:
    var t: time_t = 0
    time(&mut t)                               // direct call

// PASS: extern C manual declaration
extern "C" { fn puts(s: *const u8) -> i32 }
fn test: puts(c"hello".ptr)

// PASS: non-capturing closure to fn ptr
fn test:
    let f: extern "C" fn(i32) -> i32 = |x| x + 1

// FAIL: capturing closure to fn ptr
fn test:
    let offset = 5
    let f: extern "C" fn(i32) -> i32 = |x| x + offset  // ERROR

// PASS: c_import constants available
use c_import("limits.h")
fn test:
    assert(PATH_MAX > 0)
    assert(INT_MAX == 2147483647)
```

### 25.12 Tail Recursion (Section 9.2)

```
// PASS: valid
@[tailrec]
fn factorial(n: Int, acc: Int) -> Int:
    match n { 0 -> acc; _ -> factorial(n - 1, n * acc) }

// FAIL: not in tail position
@[tailrec]
fn bad(n: Int) -> Int:
    match n { 0 -> 1; _ -> n * bad(n - 1) }  // ERROR
```

### 25.13 Partial Application (Section 9.4)

```
// PASS
fn add(a: i32, b: i32) -> i32: a + b
fn test:
    let add5 = add(5, _)
    assert(add5(3) == 8)

// PASS: in pipeline
fn test:
    let result = vec![1, 2, 3] |> map(add(10, _)) |> collect[Vec]()
    assert(result == vec![11, 12, 13])
```

### 25.14 Pattern Matching (Section 9.7)

```
// PASS: nested
type Expr = Lit(i32) | Add(Expr, Expr) | Mul(Expr, Expr)
fn simplify(e: Expr) -> Expr:
    match e
        Add(Lit(0), rhs) -> rhs
        Mul(Lit(0), _) | Mul(_, Lit(0)) -> Lit(0)
        other -> other

// PASS: or-patterns
fn classify(day: Day) -> str:
    match day
        Monday | Tuesday | Wednesday | Thursday | Friday -> "weekday"
        Saturday | Sunday -> "weekend"

// PASS: if-let
fn test(opt: Option[i32]):
    if let Some(x) = opt: println(x)

// PASS: range
fn category(code: i32) -> str:
    match code
        200 -> "ok"; 400..=499 -> "client error"; _ -> "unknown"

// PASS: slice
fn describe(items: &[i32]) -> str:
    match items
        [] -> "empty"
        [x] -> "one"
        [first, ..rest] -> "{rest.len()} more"

// FAIL: non-exhaustive nested
fn bad(e: Expr):
    match e
        Lit(_) -> "lit"
        Add(_, _) -> "add"       // ERROR: missing Mul
```

### 25.15 Collection Operations (Section 13.3)

```
// PASS: reduce
fn test:
    let sum = vec![1, 2, 3, 4].iter() |> reduce(|a, b| a + b)
    assert(sum == Some(10))

// PASS: fold
fn test:
    let sum = vec![1, 2, 3].iter() |> fold(0, |acc, x| acc + x)
    assert(sum == 6)

// PASS: flat_map
fn test:
    let words = vec!["hello world", "foo bar"].iter()
        |> flat_map(|s| s.split(' '))
        |> collect[Vec]()
    assert(words.len() == 4)

// PASS: zip
fn test:
    let pairs = vec![1, 2].iter()
        |> zip(vec!["a", "b"].iter())
        |> collect[Vec]()
    assert(pairs == vec![(1, "a"), (2, "b")])

// PASS: partition
fn test:
    let (evens, odds) = vec![1, 2, 3, 4].iter()
        |> partition(|x| x % 2 == 0)
    assert(evens == vec![2, 4])

// PASS: complex pipeline
fn test:
    let result = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10].iter()
        |> filter(|x| x % 2 == 0)
        |> map(|x| x * x)
        |> take(3)
        |> sum()
    assert(result == 56)
```

### 25.16 Generators (Section 13.4)

```
// PASS: basic
gen fn countdown(from: i32) -> i32:
    var i = from
    while i >= 0: yield i; i -= 1

fn test:
    let result = countdown(3) |> collect[Vec]()
    assert(result == vec![3, 2, 1, 0])

// PASS: infinite with take
gen fn naturals -> Int:
    var n = 0
    loop: yield n; n += 1

fn test:
    let first_5 = naturals() |> take(5) |> collect[Vec]()
    assert(first_5 == vec![0, 1, 2, 3, 4])

// PASS: compose with pipeline
gen fn fibonacci -> Int:
    var a = 0; var b = 1
    loop: yield a; let n = a + b; a = b; b = n

fn test:
    let even_fibs = fibonacci()
        |> take_while(|x| x < 100)
        |> filter(|x| x % 2 == 0)
        |> collect[Vec]()
    assert(even_fibs == vec![0, 2, 8, 34])
```

### 25.17 Async/Await (Section 14)

```
// PASS: basic async function
async fn fetch_data(url: str) -> Result[String, IoError]:
    let resp = http.get(url).await
    resp.read_body().await

// PASS: await from any function
fn test:
    let data = fetch_data("http://example.com").await

// PASS: parallel tasks
fn test:
    let t1 = fetch_data("http://a.com")
    let t2 = fetch_data("http://b.com")
    let (a, b) = (t1.await, t2.await)

// PASS: references across await
async fn process(data: &mut Vec[i32]):
    let len = data.len()
    some_io().await
    data.push(len as i32)          // OK: stack preserved

// PASS: structured concurrency
async fn test_scope:
    async scope |s|:
        s.track(fetch_data("http://a.com"))
        s.track(fetch_data("http://b.com"))

// PASS: task is storable
fn test:
    let task = fetch_data("http://example.com")
    var tasks = Vec.new()
    tasks.push(task)               // OK: Task[T] is storable

// PASS: error propagation with await
async fn load(url: str) -> Result[Config, AppError]:
    let text = fetch_data(url).await?
    json.decode(text)?

// FAIL: async in no_runtime build
// (when with.toml has runtime = false)
async fn bad -> i32: 42        // ERROR: async requires fiber runtime
```

### 25.18 Async Calling Is Unrestricted (Section 14.3)

```
// PASS: any function can call an async fn (gets Task[T] back)
fn regular_function:
    let task = fetch_data("http://example.com")
    // task is Task[Result[String, IoError]]
    // can store it, pass it around
    let result = task.await
    println(result)

// WARNING: let _ = ... immediately CANCELS the task
fn bad_fire_and_forget:
    let _ = send_analytics("page_view")
    // WARNING: task is dropped — fiber is cancelled immediately!
    // Use `spawn` for true fire-and-forget

// PASS: fire-and-forget (spawn, runs to completion)
fn fire_and_forget:
    spawn send_analytics("page_view")
    // task runs in background, detached, not tied to caller

// PASS: store tasks, compose them as values
fn test:
    let tasks = urls
        |> map(|u| fetch_data(u))  // no .await here — just Task values
        |> collect[Vec]()
    let results = tasks
        |> map(|t| t.await)
        |> collect[Vec]()

// PASS: async fn in trait (just works)
trait DataSource:
    async fn fetch(self: &Self, id: i32) -> Result[Data, Error]

impl DataSource for RemoteDb:
    async fn fetch(self: &RemoteDb, id: i32) -> Result[Data, Error]:
        let row = self.conn.query(id).await
        Ok(row.into_data())

// No boxing, no GATs, no special handling.
// async fn in traits returns Task[T] like any other async fn.
```

### 25.19 Numerics (Section 4.2)

```
// RUNTIME PANIC (debug): overflow
fn test:
    let x: u8 = 255
    let y = x + 1                  // panic

// PASS: wrapping
fn test:
    let x: u8 = 255
    assert(x +% 1 == 0)

// PASS: implicit widening
fn test:
    let x: i32 = 42
    let y: i64 = x                 // OK

// FAIL: implicit narrowing
fn test:
    let x: i64 = 42
    let y: i32 = x                 // ERROR
```

### 25.20 Exhaustiveness (Section 9.7)

```
type Color = Red | Green | Blue

// PASS
fn name(c: Color) -> str:
    match c
        Red -> "red"; Green -> "green"; Blue -> "blue"

// FAIL
fn name(c: Color) -> str:
    match c
        Red -> "red"; Green -> "green"   // ERROR: missing Blue

// PASS: wildcard
fn name(c: Color) -> str:
    match c
        Red -> "red"; _ -> "other"
```

### 25.21 Record Update Syntax (Section 4.3)

```
type Point = { x: f64, y: f64 } with Copy

// PASS: basic update
fn test:
    let p1 = Point { x: 1.0, y: 2.0 }
    let p2 = { p1 with x: 3.0 }
    assert(p2.x == 3.0)
    assert(p2.y == 2.0)
    assert(p1.x == 1.0)        // p1 still valid (Copy)

// PASS: update non-Copy (moves base)
type Entity = { name: String, hp: i32, pos: Point }
fn test:
    let e = Entity { name: "hero", hp: 100, pos: Point { x: 0.0, y: 0.0 } }
    let e2 = { e with hp: 90 }
    // e is moved; e2 owns the String
    assert(e2.hp == 90)
    assert(e2.name == "hero")

// PASS: multiple field update
fn test:
    let p = Point { x: 1.0, y: 2.0 }
    let p2 = { p with x: 10.0, y: 20.0 }
    assert(p2.x == 10.0 && p2.y == 20.0)
```

### 25.22 Option/Result Combinators (Section 10.3, 10.4)

```
// PASS: option chaining
fn test:
    let x: Option[i32] = Some(5)
    let y = x.map(|n| n * 2).unwrap_or(0)
    assert(y == 10)

// PASS: and_then chains
fn test:
    let result = Some(10)
        .filter(|x| x > 5)
        .and_then(|x| if x < 20 then Some(x) else None)
        .unwrap_or(0)
    assert(result == 10)

// PASS: result map_err
fn test:
    let r: Result[i32, String] = Err("bad")
    let r2 = r.map_err(|s| s.len())
    assert(r2 == Err(3))

// PASS: option on None
fn test:
    let x: Option[i32] = None
    let y = x.map(|n| n * 2).unwrap_or(42)
    assert(y == 42)
```

### 25.23 Ranges (Section 4.7)

```
// PASS: range in for loop
fn test:
    var sum = 0
    for i in 0..5: sum += i
    assert(sum == 10)

// PASS: inclusive range
fn test:
    var sum = 0
    for i in 0..=5: sum += i
    assert(sum == 15)

// PASS: range as iterator
fn test:
    let squares = (0..5) |> map(|x| x * x) |> collect[Vec]()
    assert(squares == vec![0, 1, 4, 9, 16])

// PASS: range in pattern
fn test(code: i32) -> str:
    match code
        200..=299 -> "ok"
        _ -> "other"
```

### 25.24 Function Composition (Section 9.6)

```
// PASS: forward composition
fn double(x: i32) -> i32: x * 2
fn add1(x: i32) -> i32: x + 1
fn test:
    let f = double >> add1
    assert(f(5) == 11)       // add1(double(5)) = 11

// PASS: backward composition
fn test:
    let f = add1 << double
    assert(f(5) == 11)       // add1(double(5)) = 11

// PASS: composition with map
fn test:
    let process = trim >> lowercase
    let result = names |> map(process) |> collect[Vec]()
```

### 25.25 Parameter Patterns (Section 9.7)

```
// PASS: struct destructuring in parameters
fn distance({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point) -> f64:
    let dx = x2 - x1
    let dy = y2 - y1
    (dx * dx + dy * dy).sqrt()

fn test:
    let d = distance(Point { x: 0.0, y: 0.0 }, Point { x: 3.0, y: 4.0 })
    assert(d == 5.0)

// PASS: tuple destructuring in parameters
fn swap((a, b): (i32, i32)) -> (i32, i32): (b, a)

fn test:
    assert(swap((1, 2)) == (2, 1))

// PASS: destructuring in for loop
fn test:
    let pairs = vec![(1, "a"), (2, "b")]
    for (num, letter) in pairs:
        println("{num}: {letter}")
```

### 25.26 Enum Constructor Imports (Section 4.4, 18.2)

```
type Color = Red | Green | Blue

// PASS: unqualified after import
use Color.{Red, Green, Blue}
fn test:
    let c = Red                // no prefix needed
    match c
        Red   -> "red"
        Green -> "green"
        Blue  -> "blue"

// PASS: Option/Result always unqualified (prelude)
fn test:
    let x: Option[i32] = Some(5)    // not Option.Some
    let y: Result[i32, str] = Ok(5)  // not Result.Ok
```

### 25.27 Comprehensions (Section 13.6)

```
// PASS: basic comprehension
fn test:
    let squares = [x * x for x in 0..5]
    assert(squares == vec![0, 1, 4, 9, 16])

// PASS: comprehension with filter
fn test:
    let evens = [x for x in 0..10 if x % 2 == 0]
    assert(evens == vec![0, 2, 4, 6, 8])

// PASS: nested comprehension
fn test:
    let pairs = [(x, y) for x in 0..3 for y in 0..3 if x != y]
    assert(pairs.len() == 6)
```

### 25.27b Implicit Ok Wrapping (Section 4.9)

```
// PASS: value auto-wrapped in Ok
fn get_number -> Result[i32, str]:
    42                       // auto-wrapped to Ok(42)

// PASS: Result[Unit, E] with no trailing expression
fn do_stuff -> Result[Unit, IoError]:
    let f = fs.open("test.txt")?
    f.write_all(b"hello")?
    // implicit Ok(())

// PASS: explicit Ok still works
fn explicit -> Result[i32, str]:
    Ok(42)

// PASS: explicit Err still works
fn fail -> Result[i32, str]:
    Err("nope")

// PASS: ? still propagates errors
fn chain -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    User.from_row(row)       // auto-wrapped in Ok(...)
```

### 25.27c Implicit Default Return (Section 4.10)

```
// PASS: i32 function ending with println — returns 0
fn demo -> i32:
    println("hello")
    // implicit 0

// PASS: bool function ending with statement — returns false
fn setup -> bool:
    println("initializing...")
    // implicit false

// PASS: f64 function ending with statement — returns 0.0
fn measure -> f64:
    println("measuring...")
    // implicit 0.0

// PASS: Option[T] function ending with statement — returns None
fn maybe_find -> Option[i32]:
    println("searching...")
    // implicit None

// PASS: explicit return still works
fn explicit_return -> i32:
    println("hello")
    42                       // not Unit — returned as-is

// FAIL: return type without Default — type mismatch
fn bad -> SomeTypeWithoutDefault:
    println("oops")
    // error: last expression is Unit but return type
    // SomeTypeWithoutDefault does not implement Default

// PASS: derive Default on user type
@[derive(Default)]
type Config = { port: i32, debug: bool }

fn make_config -> Config:
    println("creating config...")
    // implicit Config { port: 0, debug: false }

// PASS: composes with implicit Ok wrapping
fn init -> Result[i32, IoError]:
    fs.create_dir("data")?
    // implicit Ok(0) — Ok wrapping + default return
```

### 25.28 sequence / traverse / transpose (Section 10.5)

```
// PASS: sequence on Vec[Option]
fn test:
    let xs: Vec[Option[i32]] = vec![Some(1), Some(2), Some(3)]
    assert(xs.sequence() == Some(vec![1, 2, 3]))

// PASS: sequence short-circuits on None
fn test:
    let xs: Vec[Option[i32]] = vec![Some(1), None, Some(3)]
    assert(xs.sequence() == None)

// PASS: sequence on Vec[Result]
fn test:
    let rs: Vec[Result[i32, str]] = vec![Ok(1), Ok(2)]
    assert(rs.sequence() == Ok(vec![1, 2]))

// PASS: traverse applies function then sequences
fn test:
    let strs = vec!["1", "2", "3"]
    let parsed = strs.traverse(|s| s.parse_int())
    assert(parsed == Ok(vec![1, 2, 3]))

// PASS: traverse fails on first error
fn test:
    let strs = vec!["1", "bad", "3"]
    assert(strs.traverse(|s| s.parse_int()).is_err())

// PASS: transpose Option[Result] → Result[Option]
fn test:
    let x: Option[Result[i32, str]] = Some(Ok(5))
    assert(x.transpose() == Ok(Some(5)))

    let y: Option[Result[i32, str]] = None
    assert(y.transpose() == Ok(None))

    let z: Option[Result[i32, str]] = Some(Err("bad"))
    assert(z.transpose() == Err("bad"))
```

### 25.29 Backward Application (Section 9.6)

```
// PASS: basic backward application
fn double(x: i32) -> i32: x * 2
fn test:
    let result = double <| 5
    assert(result == 10)

// PASS: chained backward application (right-associative)
fn add1(x: i32) -> i32: x + 1
fn test:
    let result = add1 <| double <| 3
    assert(result == 7)      // add1(double(3)) = add1(6) = 7
```

### 25.30 Denied Patterns (Section 20b)

```
// FAIL: await inside @[no_await_guard] with
fn test:
    let lock = RwLock.new(42)
    with lock.read() as data:
        sleep(Duration.millis(1)).await    // ERROR: ReadGuard is @[no_await_guard]

// PASS: await inside non-@[no_await_guard] with
async fn test(pool: &ConnectionPool):
    with pool.acquire() as conn:
        let row = conn.query("SELECT 1").await?  // OK: Connection not @[no_await_guard]
        Ok(row)

// FAIL: unused Result
fn fallible -> Result[i32, String]: Ok(1)
fn test:
    fallible()              // ERROR: unused Result

// PASS: explicitly discarded Result
fn fallible -> Result[i32, String]: Ok(1)
fn test:
    let _ = fallible()      // OK: intentional discard

// FAIL: unused Task
async fn background -> Unit: ()
fn test:
    background()             // ERROR: unused Task

// PASS: explicitly discarded Task
async fn background -> Unit: ()
fn test:
    let _ = background()     // OK: intentional discard

// FAIL: unnecessary unsafe
fn test:
    unsafe { let x = 1 + 2 }   // ERROR: no unsafe operations

// FAIL: implicit narrowing
fn test:
    let big: i64 = 42
    let small: i32 = big        // ERROR: implicit narrowing

// PASS: explicit narrowing
fn test:
    let big: i64 = 42
    let small: i32 = big as i32  // OK: explicit cast

// PASS: implicit widening
fn test:
    let small: i32 = 42
    let big: i64 = small         // OK: widening is lossless

// FAIL: signed/unsigned at same width
fn test:
    let x: i32 = 42
    let y: u32 = x               // ERROR: sign conversion requires as

// FAIL: unreachable code after return
fn test -> i32:
    return 42
    println("hello")             // ERROR: unreachable

// FAIL: unreachable code after break
fn test:
    for x in 0..10:
        break
        println("hello")        // ERROR: unreachable

// FAIL: unreachable code after continue
fn test:
    for x in 0..10:
        continue
        println("hello")        // ERROR: unreachable

// PASS: conditionally reachable code
fn test(flag: bool) -> i32:
    if flag then return 42
    println("still reachable")   // OK: return is conditional
    0
```

### 25.31 Copy Safety (Section 2.3)

```
// PASS: Copy on all-Copy struct
type Point = { x: f64, y: f64 }
impl Copy for Point

// FAIL: Copy on struct with non-Copy field
type Buffer = { data: Vec[u8] }
impl Copy for Buffer              // ERROR: field `data` is not Copy

// FAIL: Copy + Drop on same type
type Handle = { fd: i32 }
impl Drop for Handle:
    fn drop(self): close(self.fd)
impl Copy for Handle              // ERROR: Copy + Drop is forbidden

// PASS: Copy on struct with only primitives
type Color = { r: u8, g: u8, b: u8, a: u8 }
impl Copy for Color               // OK: all fields are Copy
```

### 25.32 Task Ephemerality (Section 14.22)

```
// PASS: owned-argument task is storable
async fn fetch(id: i32) -> String: ...
fn test:
    let task = fetch(42)                // Task[String], storable
    let tasks: Vec[Task[String]] = vec![task]  // OK: can store

// FAIL: borrowing task is ephemeral, cannot store
async fn process(data: &mut Vec[i32]) -> Unit: ...
fn test:
    var v = vec![1, 2, 3]
    let task = process(&mut v)
    let stored: Vec[Task[Unit]] = vec![task]  // ERROR: ephemeral Task

// PASS: borrowing task in async scope
async fn test:
    var v = vec![1, 2, 3]
    async scope |s|:
        let t = s.track(process(&mut v))
        t.await                            // OK: completes before scope exit
```

### 25.33 Postfix `.await` (Section 14.5)

```
// PASS: basic postfix .await
async fn fetch(url: str) -> Result[String, IoError]: ...
async fn test:
    let data = fetch("http://example.com").await
    assert(data.is_ok())

// PASS: chaining .await with ?
async fn test:
    let text = fetch("http://example.com").await?
    assert(text.len() > 0)

// PASS: chaining .await through method calls
async fn test(pool: &Pool):
    let row = pool.acquire().await?.query("SELECT 1").await?
    assert(row.is_some())

// PASS: .await on stored task
async fn test:
    let task = fetch("http://example.com")   // Task, not awaited yet
    let result = task.await                   // await later
    assert(result.is_ok())
```

### 25.34 Field Shorthand (Section 4.3)

```
// PASS: field shorthand in construction
type Point = { x: f64, y: f64 }
fn test:
    let x = 1.0
    let y = 2.0
    let p = Point { x, y }
    assert(p.x == 1.0)
    assert(p.y == 2.0)

// PASS: mixed shorthand and explicit
type User = { name: str, email: str, active: bool }
fn test:
    let name = "Alice"
    let email = "alice@example.com"
    let u = User { name, email, active: true }
    assert(u.active)

// PASS: shorthand in record update
fn test:
    let u = User { name: "Alice", email: "a@b.com", active: true }
    let email = "new@b.com"
    let u2 = { u with email }
    assert(u2.email == "new@b.com")
```

### 25.35 Enum Variant Shorthand (Section 4.4)

```
type Color = Red | Green | Blue

// PASS: shorthand in return position
fn default_color -> Color: .Blue

// PASS: shorthand in match arms
fn describe(c: Color) -> str:
    match c
        .Red   -> "red"
        .Green -> "green"
        .Blue  -> "blue"

// PASS: shorthand in function arguments
fn paint(c: Color): ...
fn test:
    paint(.Red)

// PASS: shorthand in struct field
type Config = { theme: Color }
fn test:
    let cfg = Config { theme: .Green }
    assert(describe(cfg.theme) == "green")

// FAIL: ambiguous shorthand
fn test:
    let x = .Red    // ERROR: cannot infer type for `.Red`
```

### 25.36 Tuples (Section 4.8)

```
// PASS: tuple construction and destructuring
fn test:
    let pair = (42, "hello")
    let (n, s) = pair
    assert(n == 42)

// PASS: tuple access by index
fn test:
    let t = (1, 2, 3)
    assert(t.0 == 1)
    assert(t.2 == 3)

// PASS: tuple return from function
fn divmod(a: i32, b: i32) -> (i32, i32): (a / b, a % b)
fn test:
    let (q, r) = divmod(17, 5)
    assert(q == 3)
    assert(r == 2)

// PASS: nested destructuring
fn test:
    let ((a, b), c) = ((1, 2), 3)
    assert(a == 1)
    assert(c == 3)

// PASS: tuples in for loops
fn test:
    let pairs = vec![(1, "a"), (2, "b")]
    for (n, s) in pairs:
        assert(n > 0)

// PASS: tuple is Copy when all elements are Copy
fn test:
    let t: (i32, bool) = (1, true)
    let t2 = t                    // copy
    assert(t.0 == 1)              // original still valid
```

### 25.37 Optional Chaining (Section 10.3)

```
type Address = { city: Option[str], zip: Option[str] }
type Profile = { address: Option[Address] }

// PASS: optional chaining on Option
fn test:
    let profile = Profile { address: Some(Address { city: Some("NYC"), zip: None }) }
    let city = profile.address?.city
    assert(city == Some("NYC"))

// PASS: chained optional access
fn test:
    let profile = Profile { address: None }
    let city = profile.address?.city
    assert(city == None)

// PASS: optional chaining with ?? default
fn test:
    let profile = Profile { address: None }
    let city = profile.address?.city ?? "unknown"
    assert(city == "unknown")
```

### 25.38 Default Operator `??` (Section 10.4)

```
// PASS: basic default
fn test:
    let x: Option[i32] = None
    let y = x ?? 42
    assert(y == 42)

// PASS: chained defaults
fn test:
    let a: Option[i32] = None
    let b: Option[i32] = None
    let c: Option[i32] = Some(3)
    let result = a ?? b ?? c ?? 0
    assert(result == 3)

// PASS: default with early return
fn find(id: i32) -> Option[str]: None
fn get_or_fail(id: i32) -> Result[str, str]:
    let name = find(id) ?? return Err("not found")
    Ok(name)

fn test:
    assert(get_or_fail(1).is_err())
```

### 25.39 Destructuring Let (Section 9.7)

```
// PASS: tuple destructuring
fn test:
    let (a, b, c) = (1, 2, 3)
    assert(a + b + c == 6)

// PASS: struct destructuring
type Point = { x: f64, y: f64 }
fn test:
    let p = Point { x: 3.0, y: 4.0 }
    let { x, y } = p
    assert(x == 3.0)

// PASS: rest pattern in struct
type User = { name: str, email: str, age: i32 }
fn test:
    let u = User { name: "A", email: "a@b", age: 30 }
    let { name, .. } = u
    assert(name == "A")

// PASS: let-else with Option
fn test:
    let opt: Option[i32] = Some(42)
    let Some(val) = opt else return
    assert(val == 42)

// PASS: nested destructuring
fn test:
    let (a, { x, y }) = (1, Point { x: 2.0, y: 3.0 })
    assert(a == 1)
    assert(x == 2.0)
```

### 25.40 Derive (Section 11.8)

```
// PASS: explicit derive
@[derive(Eq, Hash, Debug, Clone)]
type Color = { r: u8, g: u8, b: u8 }
fn test:
    let a = Color { r: 255, g: 0, b: 0 }
    let b = Color { r: 255, g: 0, b: 0 }
    assert(a == b)

// PASS: derive(all) on Copy-eligible type
@[derive(all)]
type Vec2 = { x: f64, y: f64 }
fn test:
    let a = Vec2 { x: 1.0, y: 2.0 }
    let b = a              // Copy (derived)
    assert(a.x == b.x)    // both valid

// PASS: derive(all) on non-Copy type
@[derive(all)]
type Name = { first: str, last: str }
fn test:
    let a = Name { first: "A", last: "B" }
    let b = a.clone()     // Clone (derived), not Copy
    assert(b.first == "A")

// FAIL: explicit derive on ineligible type
@[derive(Copy)]
type Buffer = { data: Vec[u8] }   // ERROR: field `data` is not Copy
```

### 25.41 Ephemeral Structs (Section 5.5)

```
type TokenKind = Ident | Number | String | LParen | RParen

// PASS: ephemeral struct with view fields
type Token = ephemeral {
    text: StrView,
    kind: TokenKind,
    line: usize,
}

fn first_token(src: StrView) -> Option[Token]:
    if src.len() == 0 then return None
    Some(Token { text: src.slice(0, 1), kind: .Ident, line: 1 })

fn test:
    let src = "hello world"
    let tok = first_token(src.as_view())?
    assert(tok.kind == .Ident)

// PASS: ephemeral struct in pattern matching
fn describe(tok: Token) -> str:
    match tok.kind
        .Ident  -> "identifier: {tok.text}"
        .Number -> "number: {tok.text}"
        _       -> "other"

// PASS: Vec of ephemeral struct (Vec itself becomes ephemeral)
fn tokenize(src: StrView) -> Vec[Token]:
    // Vec[Token] is ephemeral — cannot escape scope of src
    Vec.new()

// FAIL: non-ephemeral struct with ephemeral field
type BadToken = {
    text: StrView,     // ERROR: ephemeral field in non-ephemeral struct
    kind: TokenKind,
}

// FAIL: store ephemeral struct in long-lived container
type Module = {
    tokens: Vec[Token]  // ERROR: ephemeral field in non-ephemeral struct
}
```

### 25.42 Default Field Values (Section 4.3)

```
type Config = {
    host: str = "localhost",
    port: u16 = 8080,
    debug: bool = false,
}

// PASS: omit fields with defaults
fn test:
    let c = Config { port: 9090 }
    assert(c.host == "localhost")
    assert(c.port == 9090)
    assert(c.debug == false)

// PASS: all defaults
fn test_all_defaults:
    let c = Config {}
    assert(c.port == 8080)

// PASS: override all fields
fn test_all_explicit:
    let c = Config { host: "0.0.0.0", port: 443, debug: true }
    assert(c.debug == true)

// PASS: defaults with field shorthand
fn test_shorthand:
    let host = "example.com"
    let c = Config { host, debug: true }
    assert(c.host == "example.com")
    assert(c.port == 8080)

// PASS: fresh evaluation per construction
type Counter = { id: usize = next_id() }
fn test_fresh:
    let a = Counter {}
    let b = Counter {}
    assert(a.id != b.id)

// FAIL: omit field without default
type Required = {
    name: str,              // no default
    age: i32 = 0,
}
fn test_fail:
    let r = Required { age: 25 }   // ERROR: missing field `name`
```

### 25.43 Error Context (Section 10.6)

```
// PASS: basic .context()
fn load(path: &str) -> Result[str, ContextError[IoError]]:
    let text = fs.read_to_string(path)
        .context("failed to read config")?
    Ok(text)

fn test:
    match load("/nonexistent")
        Err(e) ->
            assert(e.message == "failed to read config")
            assert(e.source.is_not_found())
        Ok(_) -> panic("expected error")

// PASS: chained context
fn load_and_parse(path: &str) -> Result[Config, AppError]:
    let text = fs.read_to_string(path)
        .context("reading config file")?
    let config = toml.parse(text)
        .context("parsing config")?
    Ok(config)

// PASS: lazy context with .with_context()
fn find_user(id: UserId) -> Result[User, ContextError[DbError]]:
    db.query_one("SELECT * FROM users WHERE id = $1", &[&id])
        .with_context(|| "failed to find user {id}")?
```

### 25.44 String Literals (Section 15.3)

```
// PASS: string literal is str by default (owned)
fn test:
    let s = "hello"                          // s: str — no annotation needed
    assert(s.len() == 5)

// PASS: explicit &str annotation gives static reference
fn test:
    let view: &str = "hello"                 // &str — zero-cost static ref
    assert(view.len() == 5)

// PASS: str in struct fields — no annotation on the literal
fn test:
    type Config = { host: str, port: i32 }
    let c = Config { host: "localhost", port: 8080 }
    assert(c.host == "localhost")

// PASS: str in function args
fn register(name: str): assert(name.len() > 0)
fn test: register("Alice")

// PASS: &str parameter context — auto-borrows, no allocation
fn greet(name: &str): assert(name.len() > 0)
fn test: greet("Alice")

// PASS: return type str — literal just works
fn get_name -> str: "Alice"
fn test: assert(get_name() == "Alice")
```

### 25.45 Unit Elision (Section 4.8)

```
// PASS: Ok() with Unit elision
fn do_work -> Result[Unit, str]: Ok()
fn test:
    assert(do_work().is_ok())

// PASS: Ok(()) still works
fn do_work2 -> Result[Unit, str]: Ok(())
fn test:
    assert(do_work2().is_ok())

// PASS: unwrap_or with Unit elision
fn test:
    let r: Result[Unit, str] = Err("fail")
    r.unwrap_or()                   // desugars to .unwrap_or(())

// PASS: Unit elision in match
fn test:
    let r: Result[Unit, str] = Ok()
    match r
        Ok() -> assert(true)
        Err(_) -> assert(false)

// PASS: no elision when T != Unit (Ok still requires argument)
fn test:
    let r: Result[i32, str] = Ok(42)   // 42 required, not Unit
    assert(r.unwrap_or(0) == 42)
```

### 25.46 Implicit Iteration (Section 13.5)

```
// PASS: for-in auto-inserts .iter()
fn test:
    let items = vec![1, 2, 3]
    var sum = 0
    for x in items:              // compiler inserts .iter()
        sum += x
    assert(sum == 6)
    assert(items.len() == 3)     // items not consumed

// PASS: explicit .iter() still works
fn test:
    let items = vec![1, 2, 3]
    var sum = 0
    for x in items.iter():
        sum += x
    assert(sum == 6)

// PASS: ranges don't need .iter() (implement Iter directly)
fn test:
    var sum = 0
    for i in 0..4:
        sum += i
    assert(sum == 6)

// PASS: destructuring in for loop
fn test:
    let pairs = vec![(1, "a"), (2, "b")]
    for (n, s) in pairs:         // .iter() auto-inserted
        assert(n > 0)

// PASS: mutable iteration requires explicit .iter_mut()
fn test:
    var items = vec![1, 2, 3]
    for x in items.iter_mut():
        *x *= 2
    assert(items == vec![2, 4, 6])
```

### 25.47 Collection Length Methods (Section 18.6)

```
// PASS: .len32() returns i32
fn test:
    let items = vec![1, 2, 3, 4, 5]
    let count: i32 = items.len32()
    assert(count == 5)

// PASS: .len64() returns i64
fn test:
    let items = vec![1, 2, 3]
    let count: i64 = items.len64()
    assert(count == 3)

// PASS: .len() still returns usize
fn test:
    let items = vec![1, 2, 3]
    let count: usize = items.len()
    assert(count == 3)
```

### 25.48 Unwrap and Expect (Section 10.6)

```
// PASS: .unwrap() on Some
fn test:
    let x: Option[i32] = Some(42)
    assert(x.unwrap() == 42)

// PASS: .unwrap() on Ok
fn test:
    let r: Result[i32, str] = Ok(10)
    assert(r.unwrap() == 10)

// PASS: .expect() on Some
fn test:
    let x = Some("hello")
    assert(x.expect("must have value") == "hello")

// PASS (panics): .unwrap() on None
fn test_panics:
    let x: Option[i32] = None
    x.unwrap()    // PANICS: "called unwrap() on None"

// PASS (panics): .expect() on Err
fn test_panics:
    let r: Result[i32, str] = Err("bad")
    r.expect("operation failed")    // PANICS: "operation failed: bad"
```

### 25.49 Unreachable, Todo, Assert_matches (Section 18.6)

```
// PASS: unreachable() has type Never
type Direction = North | South | East | West
fn go(d: Direction) -> i32:
    match d
        .North -> 1
        .South -> 2
        .East  -> 3
        .West  -> 4
        _      -> unreachable()

// PASS: todo() compiles but panics at runtime
fn future_feature(x: i32) -> str:
    todo("implement after v2")

// PASS: assert_matches with enum pattern
fn test:
    let r: Result[i32, str] = Err("not found")
    assert_matches(r, Err(_))

// PASS: assert_matches with nested pattern
type AppError = Db(DbError) | Auth(str)
type DbError = NotFound(str, str) | Timeout
fn test:
    let e = AppError.Db(DbError.NotFound("users", "42"))
    assert_matches(e, .Db(.NotFound(..)))

// PASS: assert_eq shows both values on failure
fn test:
    assert_eq(2 + 2, 4)
    assert_ne(2 + 2, 5)
```

### 25.50 Builder Block Return (Section 7.2)

```
// PASS: last statement is assignment (Unit) → returns builder
fn test:
    let c = with Config { timeout: 0, retries: 0 } as mut c:
        c.timeout = 30
        c.retries = 3
    assert(c.timeout == 30)
    assert(c.retries == 3)

// PASS: push returns Unit → returns builder
fn test:
    let v = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
        v.push(3)
    assert(v.len() == 3)

// PASS: last statement is Unit (assignment) → builder returned
// even though insert() returns Option[i32]
fn test:
    let m = with HashMap.new() as mut m:
        m.insert("a", 1)    // returns Option[i32]
        m.insert("b", 2)    // returns Option[i32]... but:
        m.len()              // this is non-Unit — block returns 2!
    // m is now i32, not HashMap
    assert(m == 2)

// PASS: extract value from builder
fn test:
    let len = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
        v.len()              // non-Unit → block returns 2
    assert(len == 2)

// PASS: works as function return value
fn make_config -> Config:
    with Config.default() as mut c:
        c.timeout = 30
```

### 25.51 Select Await (Section 14.9)

```
// PASS: basic select with timeout
async fn test:
    let (tx, rx) = channel[str]()
    tx.send("hello").await
    select await
        msg = rx.recv() -> assert(msg == "hello")
        _ = timeout(1.secs()) -> unreachable()

// PASS: select in a loop with break
async fn test:
    let (tx, rx) = channel[i32]()
    var sum = 0
    tx.send(1).await
    tx.send(2).await
    tx.close()
    loop:
        select await
            n = rx.recv() -> sum += n
            _ = timeout(100.millis()) -> break
    assert(sum == 3)

// PASS: select with error propagation
async fn do_work(rx: Receiver[str], cancel: CancelToken) -> Result[str, AppError]:
    select await
        msg = rx.recv() -> Ok(msg)
        _ = cancel.cancelled() -> Err(.Cancelled)
```

### 25.52 Enum Accessor Methods (Section 4.4)

```
// PASS: .is_variant() on data variants
type Token = TInt(i64) | TStr(str) | TBool(bool) | TNull
fn test:
    let t = Token.TInt(42)
    assert(t.is_tint())
    assert(!t.is_tstr())
    assert(!t.is_tnull())

// PASS: .as_variant() returns Option
fn test:
    let t = Token.TStr("hello")
    assert(t.as_tstr() == Some("hello"))
    assert(t.as_tint() == None)

// PASS: chaining with ?? and optional chaining
fn test:
    let t = Token.TInt(42)
    let n = t.as_tint() ?? 0
    assert(n == 42)

// PASS: multi-field variant returns tuple
type Shape = Circle(f64) | Rect(f64, f64)
fn test:
    let s = Shape.Rect(3.0, 4.0)
    let (w, h) = s.as_rect() ?? unreachable()
    assert(w == 3.0)
    assert(h == 4.0)

// PASS: unit variants only get .is_variant()
type Color = Red | Green | Blue
fn test:
    let c = Color.Red
    assert(c.is_red())
    assert(!c.is_green())

// PASS: works with enum variant shorthand
type Result2 = Success(i32) | Failure(str)
fn test:
    let r: Result2 = .Success(10)
    assert(r.as_success() == Some(10))
    assert(r.as_failure() == None)
```

### 25.53 Scoped Task Tracking (Section 14.8)

```
// PASS: s.track registers task with scope
async fn test:
    async scope |s|:
        let t = s.track(fetch_data("http://example.com"))
        let result = t.await
        assert(result.is_ok())

// PASS: ScopedTask is exempt from @[must_use] — scope handles cleanup
async fn test:
    async scope |s|:
        s.track(fire_and_forget_in_scope())
        // ScopedTask dropped — no compile error
        // scope will cancel+join it on exit

// PASS: early ? return with ScopedTask — no E0801
async fn test -> Result[i32, AppError]:
    async scope |s|:
        let task_a = s.track(compute_a())
        let task_b = s.track(compute_b())
        // If task_a.await? fails, task_b is cancelled by scope
        let a = task_a.await?
        let b = task_b.await?
        Ok(a + b)

// PASS: scatter-gather pattern
async fn test:
    let results = async scope |s|:
        let tasks = vec![1, 2, 3].iter()
            |> map(|id| s.track(fetch_user(id)))
            |> collect[Vec]()
        tasks |> map(|t| t.await) |> collect[Vec]()
    assert(results.len() == 3)

// FAIL: bare Task (not ScopedTask) is still @[must_use]
async fn test_fail:
    fetch_data("http://example.com")    // ERROR E0801: unused Task
```

### 25.54 By-Value Self Method Chaining (Section 9.5)

```
// PASS: consuming self with dot-notation
type Builder = { host: str, port: u16 }
extend Builder:
    fn new -> Builder: Builder { host: "", port: 0 }
    fn host(self: Builder, h: str) -> Builder: { self with host: h }
    fn port(self: Builder, p: u16) -> Builder: { self with port: p }

fn test:
    let b = Builder.new()
        .host("localhost")
        .port(8080)
    assert(b.host == "localhost")
    assert(b.port == 8080)

// PASS: consuming self in final method
extend Builder:
    fn build(self: Builder) -> Result[Server, str]:
        if self.host.is_empty() then Err("missing host")
        else Ok(Server { host: self.host, port: self.port })

fn test:
    let server = Builder.new()
        .host("localhost")
        .port(8080)
        .build().unwrap()

// FAIL: use after consuming move
fn test_fail:
    let b = Builder.new()
    let b2 = b.host("x")     // b is moved
    b.port(80)                // ERROR: use of moved value `b`
```

### 25.55 Disjoint Closure Captures (Section 3.6)

```
type World = { positions: Vec[Vec2], velocities: Vec[Vec2], sprites: Vec[Sprite] }

// PASS: closures capture disjoint fields
fn test:
    var world = World { ... }
    scope |s|:
        s.spawn(|| update_physics(&mut world.velocities, &world.positions))
        s.spawn(|| render(&world.positions, &world.sprites))
    // OK: first captures velocities (mut) + positions (shared)
    //     second captures positions (shared) + sprites (shared)
    //     no conflict — disjoint mutable access

// FAIL: overlapping mutable capture
fn test_fail:
    var world = World { ... }
    scope |s|:
        s.spawn(|| modify(&mut world.positions))
        s.spawn(|| modify(&mut world.positions))  // ERROR: conflicting borrows
```

### 25.56 Select Await with Let-Else in Branches (Section 14.9)

```
// PASS: let...else inside branch body
async fn test(rx: Receiver[i32]):
    var items = Vec.new()
    loop:
        select await
            opt = rx.recv() ->
                let Some(item) = opt else break
                items.push(item)
            _ = timeout(1.secs()) -> break

// PASS: multiple branches with let...else
async fn serve(listener: TcpListener, ctrl: Receiver[str]):
    loop:
        select await
            result = listener.accept() ->
                let Ok(conn) = result else continue
                handle(conn)
            opt = ctrl.recv() ->
                let Some(msg) = opt else break
                process(msg)
```

### 25.57 Drop in Prelude (Section 18.2)

```
// PASS: drop closes channel sender
fn test:
    let (tx, rx) = chan[i32](10)
    tx.send(1)
    tx.send(2)
    drop(tx)                     // close sender
    let items: Vec[i32] = rx.iter() |> collect()
    assert(items == vec![1, 2])
```

### 25.58 Await Inside Iterators (Section 14.13)

```
// PASS: .await inside map closure
async fn test:
    let urls = vec!["http://a.com", "http://b.com"]
    let results = urls.iter()
        |> map(|url| fetch(url).await)
        |> collect[Vec]()
    assert(results.len() == 2)

// PASS: .await inside fold
async fn test:
    let ids = vec![1, 2, 3]
    let total = ids.iter()
        |> fold(0, |sum, id| sum + get_count(id).await)
    assert(total > 0)
```

### 25.59 Async Blocks (Section 14.6)

```
// PASS: async: block returns Task[T]
async fn test:
    let task = async:
        sleep(10.millis()).await
        42
    let result = task.await
    assert(result == 42)

// PASS: async: block in structured concurrency
async fn test:
    async scope |s|:
        s.track(async:
            println("hello from fiber 1")
        )
        s.track(async:
            println("hello from fiber 2")
        )

// PASS: async: block captures variables
async fn test:
    let url = "http://example.com"
    let task = async:
        fetch(url).await    // captures url by reference
    let result = task.await
```

### 25.60 Reference Pattern Ergonomics (Section 9.7)

```
// PASS: for loop destructuring auto-borrows
fn test:
    let items = vec![("alice", 1), ("bob", 2)]
    for (name, val) in items:        // yields &(str, i32)
        assert(name.len() > 0)       // name: &str
        assert(*val > 0)              // val: &i32

// PASS: match on borrowed Option
fn describe(opt: &Option[String]) -> &str:
    match opt
        Some(s) -> s.as_str()         // s: &String
        None    -> "none"

fn test:
    let x = Some("hello".to_string())
    assert(describe(&x) == "hello")

// PASS: nested tuple destructuring through reference
fn test:
    let pairs: Vec[(i32, i32)] = vec![(1, 2), (3, 4)]
    for (a, b) in pairs:
        assert(*a + *b > 0)           // a: &i32, b: &i32
```

### 25.61 By-Value Drop (Section 2.4)

```
// PASS: drop takes self by value — no double-free risk
type Handle = { fd: i32 }
impl Drop for Handle:
    fn drop(self: Self):
        close(self.fd)
        // self is consumed — no need to null out fd

// PASS: field destructors run after user drop body
type Wrapper = { name: String, handle: Handle }
impl Drop for Wrapper:
    fn drop(self: Self):
        println("dropping {self.name}")
        // after this returns, Handle::drop runs for self.handle
        // then String::drop runs for self.name

// FAIL: Copy + Drop is still forbidden
type Bad = { x: i32 } with Copy
impl Drop for Bad:
    fn drop(self: Self): ()  // ERROR: Copy + Drop conflict
```

### 25.62 Ephemeral Task Cancellation (Section 14.7)

```
// Ephemeral task drop blocks until fiber stops
async fn test:
    var data = vec![1, 2, 3]
    let _ = process(&mut data)       // ephemeral task: drop blocks
    // data is safe here — fiber guaranteed stopped

// Non-ephemeral task drop is cooperative (non-blocking)
async fn test:
    let _ = fetch("http://example.com")  // owned task: cooperative cancel
    // fetch fiber may still be running briefly
```

### 25.63 ScopedSend (Section 14.16)

```
// PASS: scoped thread can use &mut local
fn test:
    var data = vec![1, 2, 3]
    scope |s|:
        s.spawn(|| data.push(4))     // OK: &mut data is ScopedSend
    assert(data.len() == 4)

// PASS: async scope can track ephemeral tasks
async fn test:
    var data = vec![1, 2, 3]
    async scope |s|:
        s.track(process(&mut data))  // OK: ScopedSend
    assert(data.len() > 0)

// FAIL: unscoped thread.spawn_os rejects ephemeral
fn test_fail:
    var data = vec![1, 2, 3]
    thread.spawn_os(|| data.push(4)) // ERROR: &mut Vec is not Send
```

### 25.64 Partial Move from Drop Types (Section 2.4)

```
type Wrapper = { fd: File, name: String }
impl Drop for Wrapper:
    fn drop(self: Self): close(self.fd)

// FAIL: partial move from Drop type
fn test_fail:
    let w = Wrapper { fd: open(), name: "A" }
    let w2 = { w with name: "B" }  // ERROR: partial move from Drop type

// PASS: clone field instead
fn test:
    let w = Wrapper { fd: open(), name: "A" }
    let w2 = Wrapper { fd: w.fd.clone(), name: "B" }
```

### 25.65 No References Across Yield (Section 13.4)

```
// FAIL: reference to local crosses yield
gen fn bad -> &str:
    let s = "hello".to_owned()
    let r = &s
    yield r                          // ERROR: borrow of `s` live across yield

// PASS: owned value across yield
gen fn ok -> str:
    let s = "hello".to_owned()
    yield s.clone()
    yield s
```

### 25.66 Comptime Unreachable Exemption (Section 20b.6)

```
// PASS: code after comptime if return is not flagged unreachable
fn compute(x: i32) -> i32:
    comptime if cfg.is_debug:
        return 0
    // In release: reachable. In debug: erased by comptime.
    x * x + 1

// FAIL: code after unconditional return is still unreachable
fn test_fail -> i32:
    return 0
    1 + 1                            // ERROR: unreachable code
```

### 25.67 May-Suspend Analysis (Section 14.3, Invariant 5)

```
// FAIL: may_suspend function called while guard is live
fn helper:
    some_io().await

fn test_fail:
    let lock = Mutex.new(42)
    with lock.lock() as data:
        helper()                     // ERROR E0701: may_suspend function
                                     // called while @[no_await_guard] is live

// PASS: no suspension in guarded block
fn safe_helper(x: i32) -> i32: x * 2

fn test:
    let lock = Mutex.new(42)
    with lock.lock() as data:
        safe_helper(*data)           // OK: safe_helper is not may_suspend
```

### 25.68 FFI Callback No-Suspend (Section 14.19)

```
// FAIL: may_suspend in extern "C" callback
fn test_fail:
    unsafe { c_sort(items.ptr, items.len, |a, b|
        fetch_weight(a).await <=> fetch_weight(b).await
        //              ^^^^^^ ERROR: may_suspend in C callback
    ) }

// PASS: no suspension in callback
fn test:
    unsafe { c_sort(items.ptr, items.len, |a, b|
        a.weight <=> b.weight        // OK: no suspension
    ) }
```

### 25.69 With Type-Based Dispatch (Section 7.5)

```
// PASS: Scoped type → automatic guarded access
fn test:
    let lock = Mutex.new(vec![1, 2, 3])
    with lock.lock() as data:          // Mutex implements Scoped → guard
        assert(data.len() == 3)

// PASS: non-Scoped type → simple builder binding
fn test:
    let config = with Config.default() as mut c:
        c.retries = 3                  // Config is not Scoped → builder
    assert(config.retries == 3)
```

### 25.70 Iter One-Implementation Rule (Section 13.2)

```
// FAIL: conflicting Iter implementations
type MyBuffer = { data: Vec[u8] }
impl Iter[u8] for MyBuffer: ...
impl Iter[String] for MyBuffer: ...  // ERROR: MyBuffer already implements Iter[u8]

// PASS: named methods for alternate iteration
type MyBuffer = { data: Vec[u8] }
impl Iter[u8] for MyBuffer: ...
extend MyBuffer:
    fn lines(self: &Self) -> LineIter: ...   // separate iterator type
```

### 25.71 Operator One-Impl Rule (Section 11.7)

```
// PASS: unique Output per (Self, Rhs) pair
impl Add[Vector, Vector] for Vector:
    fn add(self: Vector, rhs: Vector) -> Vector: ...
impl Add[f32, Vector] for Vector:   // different Rhs = OK
    fn add(self: Vector, rhs: f32) -> Vector: ...
let v = vec1 + vec2   // Output uniquely determined: Vector

// FAIL: conflicting Output for same (Self, Rhs)
impl Add[Vector, Matrix] for Vector: ...   // ERROR: Vector + Vector
                                               // already has Output = Vector
```

### 25.72 Fair Select Await (Section 14.10)

```
// PASS: fair select (default — random among ready branches)
loop:
    select await
        data = fast_stream.recv() -> handle(data)
        _ = shutdown.recv() -> break    // will eventually fire

// PASS: biased select (explicit — top-to-bottom priority)
select await biased
    urgent = priority_rx.recv() -> handle_urgent(urgent)
    normal = normal_rx.recv() -> handle_normal(normal)
```

### 25.73 Defer Control Flow Restriction (Section 2.4)

```
// FAIL: return inside defer
fn test_fail:
    defer return 42                    // ERROR E0901: non-local control flow in defer

// FAIL: ? inside defer
fn test_fail:
    defer conn.close()?                // ERROR E0901: ? in defer

// PASS: handle errors locally
fn test:
    defer conn.close().unwrap_or(())   // OK: error handled locally
```

### 25.74 Spawn Fire-and-Forget (Section 14.7)

```
// PASS: spawn for fire-and-forget
fn test:
    spawn send_analytics("page_view")  // runs to completion, detached

// WARNING: let _ = task cancels immediately
fn test_bad:
    let _ = send_analytics("page_view") // WARNING: immediately cancelled!
```

### 25.75 Iterator Borrowing (Section 13.2)

```
// PASS: stdlib slice iterators work naturally
fn test:
    let names = vec!["alice", "bob", "charlie"]
    let iter = names.iter()
    let a = iter.next().unwrap()    // borrows names, not iter
    let b = iter.next().unwrap()    // OK — no conflict
    assert(a == "alice")
    assert(b == "bob")

// PASS: for loop works with custom iterators too
fn test:
    while let Some(tok) = next_token(&mut parser):
        process(tok)                   // tok drops here, releases &mut parser

// NOTE: custom iterators returning ephemerals may still hit
// conservative borrowing on user-defined types
fn test_custom:
    let tokens = with Vec.new() as mut toks:
        while let Some(tok) = next_owned_token(&mut parser):
            toks.push(tok)             // OwnedToken has no borrows
```

### 25.76 Channel Send Requires Send (Section 14.15)

```
// FAIL: ephemeral values cannot be sent over channels
fn test_fail:
    async scope |s|:
        let (tx, rx) = chan[&str](10)
        s.track(async:
            let local = "hello".to_owned()
            tx.send(local.as_view()).await  // ERROR: &str is not Send
        )

// PASS: owned values over channels
fn test:
    let (tx, rx) = chan[String](10)
    tx.send("hello").await                  // str literal, String is Send
```

### 25.77 Ephemeral Owned Passing Restriction (Section 14.22)

```
// FAIL: ephemeral by-value to external function
fn store_globally(t: Task[i32]): ...  // separately compiled

fn test_fail:
    var x = 42
    let task = my_fn(&mut x)
    store_globally(task)                // ERROR: ephemeral value cannot be
                                        // passed as owned to external fn

// PASS: ephemeral by reference
fn inspect(t: &Task[i32]): ...

fn test:
    var x = 42
    let task = my_fn(&mut x)
    inspect(&task)                      // OK: passed by reference
```

### 25.78 Disjoint Slice Operations (Section 3.4)

```
// PASS: split_at_mut returns disjoint slices — compiler knows
fn test:
    var data = vec![1, 2, 3, 4, 5]
    let (left, right) = data.split_at_mut(3)
    left[0] = 10                        // OK: disjoint
    right[0] = 40                       // OK: no aliasing
```

### 25.79 Optional Chaining Type-Aware Desugaring (Section 10.3)

```
type Address = { city: Option[str], zip: str }
type Profile = { address: Option[Address] }

// PASS: field is non-Option → map
fn test:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let zip: Option[str] = p.address?.zip    // map → Option[str]

// PASS: field is Option → and_then (flattened)
fn test:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let city: Option[str] = p.address?.city  // and_then → Option[str], NOT Option[Option[str]]

// PASS: chaining works correctly
fn test:
    let p = Profile { address: Some(Address { city: Some("NYC"), zip: "10001" }) }
    let len: Option[usize] = p.address?.city?.len()  // chains naturally
```

### 25.80 Drop Field Moves (Section 2.4)

```
// PASS: field moves allowed INSIDE drop
type FileWrapper = { fd: File, name: String }
impl Drop for FileWrapper:
    fn drop(self: Self):
        close_file(self.fd)   // OK: field move inside drop
        // self.name NOT moved → compiler drops it automatically

// FAIL: field moves forbidden OUTSIDE drop
fn test_fail:
    let w = FileWrapper { fd: open_file(), name: "A" }
    let fd = w.fd             // ERROR: partial move from Drop type
```

### 25.81 HashMap Lookup Borrowing (Section 13.2)

```
// PASS: HashMap::get borrows from the map, not the key
fn test:
    var map = HashMap.new()
    map.insert("admin", User { name: "Alice" })
    let user = {
        let key: str = "admin"
        map.get(key.as_view())    // compiler knows: borrows map, not key
    }                              // key drops here, user still valid
    assert(user.is_some())
```

---

### 25.82 NLL-Based @[no_await_guard] (Section 7.9)

```
// FAIL: guard live across .await via plain let binding
fn test_fail:
    let guard = lock.lock()        // @[no_await_guard] type
    fetch(url).await               // ERROR E0701: guard is live

// PASS: guard dropped before .await
fn test:
    let data = with lock.read() as d:
        d.clone()
    fetch(data.url).await          // OK: guard already dropped
```

### 25.83 Object Safety (Section 11.3)

```
// PASS: trait with &Self methods is object-safe
trait Drawable:
    fn draw(self: &Self)
fn render(d: &dyn Drawable): d.draw()

// FAIL: trait with by-value self is not object-safe (without Box)
trait Consumable:
    fn consume(self: Self)
fn bad(c: &dyn Consumable): ...   // ERROR: Consumable is not object-safe

// PASS: by-value self through Box
fn good(c: Box[dyn Consumable]): c.consume()  // OK via generated shim
```

### 25.84 C-String Literals (Section 15.3)

```
// PASS: c"..." produces &CStr
fn test:
    let s: &CStr = c"hello"
    assert(s.len() == 5)           // "hello" without NUL
    puts(s.ptr)         // NUL is present in memory
```

### 25.85 Record Update Drops Overwritten Fields (Section 4.3)

```
// PASS: overwritten fields are dropped, non-overwritten are moved
fn test:
    let p1 = NamedPoint { x: "first", y: "second" }
    let p2 = { p1 with x: "third" }
    // p1.x ("first") was dropped, p1.y ("second") was moved to p2.y
    assert(p2.x == "third")
    assert(p2.y == "second")
```

### 25.86 Ephemeral Task OS Thread Restriction (Section 14.7)

```
// FAIL: ephemeral task on bare OS thread
fn test_fail:
    thread.spawn_os(||
        var data = vec![1, 2, 3]
        let task = process(&mut data)  // ERROR: ephemeral task in OS thread
    )

// PASS: ephemeral task inside fiber (async context)
async fn test:
    var data = vec![1, 2, 3]
    let task = process(&mut data)      // OK: inside async context
    task.await
```

### 25.87 String Literal Default Type (Section 15.3)

```
// PASS: literal is str by default — no annotation
fn test:
    let s = "hello"
    assert(s.len() == 5)

// PASS: str in struct field — no annotation on literal
fn test:
    type Config = { host: str, port: i32 }
    let c = Config { host: "localhost", port: 8080 }
    assert(c.host == "localhost")

// PASS: str in function parameter
fn greet(name: str): assert(name.len() > 0)
fn test: greet("Alice")

// PASS: str in return type
fn name -> str: "Alice"
fn test: assert(name() == "Alice")

// PASS: explicit &str annotation gives static reference
fn test:
    let view: &str = "hello"  // &str — zero-cost, no allocation
    assert(view.len() == 5)
```

### 25.88 FFI Direct Call (Section 16.1)

```
// PASS: c_import functions callable directly
use c_import("stdio.h")
fn test: puts(c"hello".ptr)      // no unsafe needed

// PASS: unsafe still required for pointer deref
fn test:
    let p: *mut i32 = alloc(4)
    unsafe { *p = 42 }               // pointer deref needs unsafe
    free(p)                           // C function call: no unsafe
```

### 25.89 With Type-Based Guard Inference (Section 7.1)

```
// PASS: Scoped type auto-detected
fn test:
    let lock = Mutex.new(42)
    let val = with lock.read() as data:    // auto-detected as guard
        *data
    assert(val == 42)

// PASS: non-Scoped type → builder
fn test:
    let v = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
    assert(v.len() == 2)
```

### 25.90 Auto-Dereferencing (Section 3.7)

```
// PASS: auto-deref through Box
fn test:
    type User = { name: str }
    let u: Box[User] = Box.new(User { name: "Alice" })
    assert(u.name == "Alice")             // auto-deref Box → User → .name

// PASS: auto-deref through multiple references
fn test:
    let x = 42
    let r = &x
    let rr = &r
    assert(rr == 42)                      // auto-deref through &&i32

// PASS: auto-deref for method calls
fn test:
    let v: Box[Vec[i32]] = Box.new(vec![1, 2, 3])
    assert(v.len() == 3)                  // auto-deref Box → Vec → .len()
```

### 25.91 Auto-Referencing (Section 3.8)

```
// PASS: auto-ref for shared borrow parameter
fn len(s: &str) -> usize: s.len()
fn test:
    let name: str = "Alice"
    assert(len(name) == 5)               // compiler inserts &name

// PASS: auto-ref for method receiver
fn test:
    type Point = { x: f64, y: f64 }
    impl Point
        fn magnitude(self: &Self) -> f64: (self.x * self.x + self.y * self.y).sqrt()
    let p = Point { x: 3.0, y: 4.0 }
    assert(p.magnitude() == 5.0)          // auto-ref: p → &p

// FAIL: no auto-ref for &mut
fn mutate(s: &mut str): s.push_str("!")
fn test_fail:
    var name: str = "Alice"
    mutate(name)                          // ERROR: won't auto-ref to &mut
    mutate(&mut name)                     // OK: explicit &mut
```

### 25.92 Implicit Trait Object Coercion (Section 3.9)

```
// PASS: &T → &dyn Trait
trait Greet:
    fn hello(self: &Self) -> str
type English = {}
impl Greet for English:
    fn hello(self: &Self) -> str: "Hello"

fn say_hi(g: &dyn Greet) -> str: g.hello()
fn test:
    let eng = English {}
    assert(say_hi(&eng) == "Hello")       // auto-coerce &English → &dyn Greet

// PASS: Box[T] → Box[dyn Trait]
fn test:
    let g: Box[dyn Greet] = Box.new(English {})  // auto-coerced
    assert(g.hello() == "Hello")

// PASS: combined auto-ref + trait coercion
fn test:
    let eng = English {}
    assert(say_hi(eng) == "Hello")        // auto-ref + auto-coerce
```

### 25.93 Enum Auto-Generated _ref and _mut (Section 4.4)

```
// PASS: as_variant_ref returns Option[&T]
type Value = Str(str) | Num(f64) | Null

fn test:
    let v = Value.Str("hello")
    assert(v.as_str_ref() == Some(&"hello"))
    assert(v.as_num_ref() == None)

// PASS: as_variant_mut returns Option[&mut T]
fn test:
    var v = Value.Num(42.0)
    if let Some(n) = v.as_num_mut():
        *n = 99.0
    assert(v.as_num_ref() == Some(&99.0))

// PASS: navigating tree structures by reference
type Json = Null | Bool(bool) | Num(f64) | Str(str)
         | Array(Vec[Json]) | Object(HashMap[str, Json])

fn test:
    let data = Json.Object(/* ... */)
    let name = data.as_object_ref()?.get("name")?.as_str_ref()
    assert(name.is_some())
```

### 25.94 Chained if let (Section 9.7)

```
// PASS: chained if let bindings
fn test:
    let a: Option[i32] = Some(1)
    let b: Option[i32] = Some(2)
    var result = 0
    if let Some(x) = a, let Some(y) = b:
        result = x + y
    assert(result == 3)

// PASS: chain fails if any binding fails
fn test:
    let a: Option[i32] = Some(1)
    let b: Option[i32] = None
    var result = 0
    if let Some(x) = a, let Some(y) = b:
        result = x + y
    assert(result == 0)

// PASS: mixed boolean and let bindings
fn test:
    let users = vec![User { name: "Alice", active: true }]
    if let Some(user) = users.first(), user.active:
        assert(user.name == "Alice")
```

### 25.95 Comptime Cascade (Section 17.4)

```
// PASS: no comptime prefix needed inside comptime fn
comptime fn count_fields[T: type] -> usize:
    let mut n = 0
    for field in T.fields():       // cascade: no comptime prefix
        n += 1
    n

@[test]
fn test:
    assert(count_fields[Point]() == 2)

// PASS: type method syntax
comptime fn type_name[T: type] -> str: T.name()

@[test]
fn test:
    assert(type_name[i32]() == "i32")
```

### 25.96 derive(Builder) (Section 11.8)

```
// PASS: generated builder with required and optional fields
@[derive(Builder)]
type Config = {
    host: str,
    port: i32 = 8080,
}

fn test:
    let c = Config.builder()
        .host("localhost")
        .build()
        .unwrap()
    assert(c.host == "localhost")
    assert(c.port == 8080)

// PASS: override defaults
fn test:
    let c = Config.builder()
        .host("prod.example.com")
        .port(443)
        .build()
        .unwrap()
    assert(c.port == 443)
```

### 25.97 Raw Pointer .as_option() (Section 16.1)

```
// PASS: non-null pointer → Some
fn test:
    var x: i32 = 42
    let p: *mut i32 = &mut x
    assert(p.as_option().is_some())

// PASS: null pointer → None
fn test:
    let p: *mut i32 = null
    assert(p.as_option().is_none())

// PASS: as_option composes with ?? 
fn test:
    let p: *const i32 = null
    let val = p.as_option().map(|p| unsafe { *p }).unwrap_or(0)
    assert(val == 0)
```

### 25.98 HashMap Convenience Methods (Section 13.3)

```
// PASS: update with default and transform
fn test:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.update("alice", 0, |n| n + 1)
    counts.update("alice", 0, |n| n + 1)
    assert(counts.get("alice") == Some(&2))

// PASS: increment shorthand
fn test:
    var counts: HashMap[str, i32] = HashMap.new()
    counts.increment("bob")
    counts.increment("bob")
    counts.increment("bob")
    assert(counts.get("bob") == Some(&3))
```

### 25.99 Freestanding Mode (Section 18.7)

```
// PASS: core types available in no_std
// @[cfg(no_std)]
fn test:
    let x: i32 = 42
    let y: bool = true
    let opt: Option[i32] = Some(10)
    let arr: [u8; 4] = [1, 2, 3, 4]
    assert(opt.unwrap() == 10)

// PASS: c_import works in no_std
// @[cfg(no_std)]
fn test:
    use c_import("stdint.h")
    let x: u32 = 0xFF

// PASS: match and ownership work in no_std
// @[cfg(no_std)]
fn test:
    type Command = Reset | Set(u8) | Get
    let cmd = Command.Set(42)
    match cmd
        .Set(val) -> assert(val == 42)
        _ -> panic("wrong variant")

// FAIL: Vec requires std or alloc
// @[cfg(no_std)]
fn test:
    let v = Vec.new()     // ERROR: Vec requires alloc

// FAIL: println requires std
// @[cfg(no_std)]
fn test:
    println("hello")      // ERROR: println requires std (stdout)

// FAIL: str literal is &str in no_std (no allocator for owned str)
// @[cfg(no_std)]
fn test:
    let s = "hello"       // s: &str (not str) in no_std
    let owned: str = "x"  // ERROR: str requires alloc

// PASS: &str works in no_std
// @[cfg(no_std)]
fn test:
    let s: &str = "hello"
    assert(s.len() == 5)

// PASS: alloc tier gives back Vec and str
// @[cfg(no_std, alloc)]
fn test:
    let v = Vec.from([1, 2, 3])
    let s = "hello"       // s: str (owned, allocator available)
    assert(v.len() == 3)

// FAIL: missing panic handler in no_std
// @[cfg(no_std)]
// ERROR: no_std requires @[panic_handler]
```

### 25.100 The `in` Operator (Section 9.9)

```
// PASS: basic array membership
fn test:
    let x = 3
    assert(x in [1, 2, 3, 4, 5])
    assert(not (x in [6, 7, 8]))

// PASS: not in operator
fn test:
    let x = 10
    assert(x not in [1, 2, 3])
    assert(not (x not in [10, 20, 30]))

// PASS: range membership
fn test:
    assert(5 in 1..10)
    assert(not (10 in 1..10))     // exclusive upper bound
    assert(10 in 1..=10)          // inclusive upper bound
    assert(not (0 in 1..10))

// PASS: string contains substring
fn test:
    let text = "hello world"
    assert("hello" in text)
    assert("xyz" not in text)

// PASS: char in string
fn test:
    let email = "user@example.com"
    assert('@' in email)
    assert('!' not in email)

// PASS: HashMap key membership
fn test:
    var map: HashMap[str, i32] = HashMap.new()
    map.insert("alice", 1)
    map.insert("bob", 2)
    assert("alice" in map)
    assert("charlie" not in map)

// PASS: HashSet membership
fn test:
    var set: HashSet[i32] = HashSet.new()
    set.insert(10)
    set.insert(20)
    assert(10 in set)
    assert(30 not in set)

// PASS: enum variant shorthand in array
fn test:
    type Color = Red | Green | Blue | Yellow
    let c = Color.Red
    assert(c in [.Red, .Green, .Blue])
    assert(c not in [.Yellow])

// PASS: in with pipeline filter
fn test:
    let nums = Vec.from([1, 2, 3, 4, 5, 6])
    let evens = nums.iter()
        |> filter(|x| *x in [2, 4, 6])
        |> collect[Vec]()
    assert(evens.len() == 3)

// PASS: match with in patterns
fn test:
    let method = "map"
    let result = match method
        in ["map", "filter", "take"] -> "lazy"
        in ["collect", "fold", "sum"] -> "eager"
        _ -> "other"
    assert(result == "lazy")

// PASS: match with in pattern and @ binding
fn test:
    let code = 404
    let msg = match code
        c @ in 200..=299 -> "ok: {c}"
        c @ in 400..=499 -> "client error: {c}"
        _ -> "other"
    assert(msg == "client error: 404")

// PASS: user type implementing Contains
fn test:
    type Whitelist = { allowed: HashSet[i32] }
    impl Contains[i32] for Whitelist =
        fn contains(self: &Self, value: &i32) -> bool:
            *value in self.allowed
    var wl = Whitelist { allowed: HashSet.from([1, 2, 3]) }
    assert(1 in wl)
    assert(4 not in wl)

// PASS: in with compound conditions
fn test:
    let role = "admin"
    let action = "delete"
    let allowed = ["read", "write", "delete"]
    assert(role in ["admin", "moderator"] and action in allowed)

// PASS: literal array optimization (semantic equivalence)
fn test:
    let x = "filter"
    // These should produce identical results
    let a = x in ["map", "filter", "reduce"]
    let b = x == "map" or x == "filter" or x == "reduce"
    assert(a == b)

// FAIL: in requires Contains implementation
fn test:
    type Foo = { x: i32 }
    type Bar = { y: i32 }
    let f = Foo { x: 1 }
    let b = Bar { y: 2 }
    f in b              // ERROR: `Bar` does not implement `Contains[Foo]`

// FAIL: in is non-associative
fn test:
    let x = 1
    x in [1, 2] in [true, false]   // ERROR: `in` is non-associative

// PASS: for-in loop is distinct from membership in
fn test:
    let items = [1, 2, 3, 4, 5]
    var count = 0
    for x in items:             // for-in loop (Iter trait)
        if x in [2, 4]:        // membership test (Contains trait)
            count += 1
    assert(count == 2)

// PASS: comprehension with membership filter
fn test:
    let primes = HashSet.from([2, 3, 5, 7, 11, 13])
    let prime_squares = [x * x for x in 1..=15 if x in primes]
    assert(prime_squares.len() == 6)
```

---

# Part IV — Implementation Roadmap

---

## 26. Phased Implementation

### Phase 0: Bootstrap + C Interop

Lexer, parser, AST. Module system (with prelude imports). Basic types
including record update syntax and ranges. Type checker (local
inference, explicit signatures). Backend: C codegen or Cranelift.

**`c_import` and FFI are Phase 0.** `extern "C"` declarations,
`@[repr(C)]`, `unsafe` blocks, raw pointer types, and `c_import`
header parsing are implemented in the bootstrap phase. Without C
interop, the language cannot call libc, cannot open files, cannot
allocate memory, cannot write tests against real libraries. Every
subsequent phase depends on this.

**Milestone:** Can `c_import("stdio.h")` and call `printf` from With.

### Phase 1: Ownership Core

Move semantics. Copy. Borrow checker (NLL, disjoint fields). Ephemeral
type qualifier. Reference return with propagation.

**Milestone:** Tests 25.1–25.6 pass.

### Phase 2: Ergonomic Surface

`with` blocks. Closures with escaping detection. Partial application.
Pipelines and function composition (`>>`, `<<`). `in` / `not in`
operator with `Contains` trait and literal optimizations. Pattern
matching (full: nested, or-patterns, `@` binding, `if let`, `in`
patterns, slice, parameter patterns). Error types. Tail call
optimization.

**Milestone:** Tests 25.7, 25.9, 25.12–25.14, 25.20–25.26, 25.100 pass.

### Phase 3: Standard Library

Implement the standard library module map defined in §18.6:

**Phase 3a (Core):** `std.io` (Reader, Writer, print/println),
`std.fs` (File, read_file, write_file), `std.mem` (size_of,
align_of, copy), `std.fmt` (Display, Debug, format),
`std.collections` (Vec, HashMap, HashSet, SlotMap, Handle),
`std.string` (String, StrView methods). Option and Result with
full combinator APIs including sequence/traverse/transpose.

**Phase 3b (Systems):** `std.time` (Instant, Duration, SystemTime),
`std.math` (f32/f64 methods, constants), `std.process` (args, env,
exit), `std.random` (Rng), `std.hash` (Hasher, DefaultHasher).

**Phase 3c (Concurrency foundations):** `std.thread` (spawn_os,
JoinHandle), `std.sync` (Mutex, RwLock, Atomic, Condvar).
Generator lowering.

All modules use `c_import` internally for platform bindings (libc,
POSIX, Win32). Users never see `c_import` for standard operations.

**Milestone:** Tests 25.8, 25.15, 25.16, 25.19, 25.22 pass.
Users can write file I/O, string processing, timing, and
collections code without any `c_import`.

### Phase 4: Concurrency

Fiber runtime (§14.18–14.19). `async`/`await` lowering. Task type.
Structured concurrency. Channels. Select. `no_runtime` gate.
Send/Sync trait enforcement. `std.net` (TcpListener, TcpStream,
UdpSocket, DNS). `std.signal`.

**Milestone:** Tests 25.17, 25.18 pass. A simple HTTP server runs
with concurrent connection handling.

### Phase 5: Traits and Generics

Definitions, implementations, orphan rules, generic bounds,
monomorphization.

**Milestone:** Tests 25.10 pass.

### Phase 6: Polish

Comptime. Formatter. Doc generator. LSP. REPL. Diagnostics.
Optimization. `c_import` macro translation improvements.

---

## 27. Known Limitations and Trade-Offs (v1.0)

| Limitation | Cost | Workaround |
|------------|------|------------|
| Cannot store references in structs | Forces `(&Tree, NodeId)` pairs instead of `&Node` | Use handles, owned values, or `with` blocks |
| Cannot return iterators that borrow | May require allocation at function boundaries | Use `collect`, generators, callbacks, or inline pipelines (§13.1) |
| Cannot build self-referential structs | Must restructure as separate arena + handle | Use arenas with handles |
| Handle dereference slower than pointer | ~2-3ns vs ~0.3ns per access | Use `for_each`/`iter` for bulk; `unsafe` for rare hot paths (§6.3) |
| Fibers use 8–64KB stack each | 100K fibers ≈ 800MB worst case (vs state-machine-sized for Rust futures) | Growable stacks; channel-driven worker pools for >100K tasks (§14.19) |
| No RAII wrappers around borrowed resources | Cannot `Drop` a struct holding `&mut File` | Use `defer` or `with` blocks |
| No higher-kinded types | Cannot abstract over `Option`/`Result`/etc. generically | Use concrete generic parameters |
| No associated types on traits | Verbose generic signatures | Use additional generic parameters |
| Array index disjointness not proven | Conservative rejection of safe code | Use `get2_mut` or `split_at_mut` |
| Closure escaping analysis conservative | Some valid closures rejected | Pass closure directly as argument |
| Fiber runtime required for async | `async` unavailable on bare-metal | OS threads always available; `no_runtime` for embedded |

---

## 28. Future Work

- Associated types on traits
- Hot-reload for debug builds
- Relaxed orphan rules
- Relaxed closure escaping analysis
- Inferred borrow provenance (compiler infers which parameter a
  return value borrows from, eliminating conservative multi-borrow)
- Fiber scheduler work-stealing optimizations
- Distributed async
- Nested record update syntax (`{ e with transform.pos.x: ... }`)
- Persistent immutable collections (`ImmMap`, `ImmVec`) as explicit types
- Extractor patterns (constrained Scala-style `unapply`, if provably
  safe for exhaustiveness checking)
- Unified ECS query combinator: `world.query[A, B]()` as a single
  entry point for compile-time-optimized multi-component queries,
  replacing per-arity functions like `query2`, `query3`

---

## 29. Additional Lexical and Binding Rules (Wave Language Rules)

### 29.1 Numeric separators

Numeric literals permit `_` separators for readability:

- Decimal: `1_000_000`
- Hex: `0xFF_AA_22`
- Binary: `0b1111_0000`
- Float: `3.141_592_653`

Separators are ignored for numeric value parsing.

### 29.2 Trailing commas

Trailing commas are **permitted but never required** in list-like grammar positions, including:

- Function parameter lists and argument lists
- Type parameter and type argument lists
- Record/struct field lists
- Tuple/array literal element lists
- Match arms and import/use lists

### 29.3 Raw string literals

Raw string forms are supported:

- `r"..."`  
- `r#"..."#`  
- `r##"..."##` (and higher `#` counts)

Raw strings disable escape and interpolation parsing in the lexer/parser path; delimiter matching uses the same `#` count.

### 29.4 Triple-quoted multiline strings

`"""..."""` literals:

- May start with an optional newline immediately after the opening delimiter.
- May end with a trailing newline immediately before the closing delimiter.
- Are dedented by common leading indentation across non-empty lines.

### 29.5 Byte literals

`b'X'` and escaped forms (for example `b'\x41'`) are accepted.

Bootstrap lowering treats character and byte literals as integer literal values during AST construction; type-checking follows normal integer coercion rules.

### 29.6 Unused bindings

`_` is an explicit discard binding. It is legal in binding positions (for example `let _ = expr`, parameter bindings, pattern bindings) and does not introduce a usable name.

### 29.7 String escape parity

String processing supports:

- Standard escapes: `\\`, `\"`, `\n`, `\r`, `\t`
- Null byte: `\0`
- Hex byte: `\xNN` (two hexadecimal digits)

These rules apply consistently to standard and C-string literal processing.

### 29.8 No-shadowing

Shadowing is disallowed for local bindings. Rebinding an existing visible name emits a diagnostic (for example, `shadowing is not allowed for 'x'`).

### 29.9 Pipeline-first guidance

Because rebinding/shadowing is disallowed, stepwise transformations should use pipelines (`|>`) and scoped `with` bindings instead of repeated `let name = ...` rebinding.

### 29.10 `todo` and `unreachable`

`todo()` and `unreachable()` are divergence-oriented builtins with type `Never`.

- They accept zero arguments or one `str`-compatible message argument.
- Their type is `Never`, which is compatible in value position with any expected type.
- They are treated as diverging control-flow points for typing and reachability analysis.

---

*The With Programming Language — End of specification.*
