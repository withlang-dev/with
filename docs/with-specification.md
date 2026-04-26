# The With Programming Language — Specification v6.7

**Status:** Reference specification for prototype implementation
**Changelog v6.7:** Reorganized — extracted test cases to `test/spec/`,
roadmap to `docs/roadmap.md`, design rationale to `docs/design-rationale.md`,
stdlib API tables to `docs/libstd-spec.md`. Added grammar appendix (§30).
Added labels on arbitrary statements and `goto` (§13.5a, §13.5b).
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

    if not body.email.is_valid():
        return Err(.ValidationError("Invalid email format"))

    if db.find_user(body.email).await?.is_some():
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

*For a detailed comparison with Rust, see `docs/design-rationale.md`.*

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
- **Short-circuit `for` comprehensions** — `for user in get_user(id);
  profile in get_profile(user): yield profile.name` chains `Option`
  and `Result` without pyramid-shaped `match` nests. (§13.6a)
- **Pattern `for` loops** — `for (key, value) in map:` and
  `for Some(item) in optional_items:` destructure directly in the
  loop header. (§13.5)
- **Labeled break and continue** — `'outer for ...` plus
  `break 'outer` or `continue 'outer` targets outer loops and
  labeled blocks without flag-variable cascades. (§13.5a)
- **Iterators just work** — hold two items, zip, peek. The compiler
  is smart about stdlib iterators. (§13.2)
- **`with` infers guards** — `with lock.read() as data:` — the
  compiler knows it's a guard from the type. No keyword. (§7.1)
- **Implicit contexts** — `with context(default_device()): sin(x)`
  wires `implicit` parameters from lexical scope. (§7.3a)
- **C functions just call** — `c_import` functions are callable
  directly. No `unsafe {}` wrapper on every FFI call. (§16.1)
- **Postfix `.await`** — chains naturally with `?` and `|>` (§14.5)
- **Pipeline operator** — `data |> filter(it.active) |> map(it.name)` (§12)
- **Named arguments** — `connect("localhost", port: 8080)` can mix
  positional and named arguments, and defaults can be skipped by name. (§9.1a)
- **Chained comparisons** — `0 < x < 1` evaluates interior terms once
  and reads like the math you meant. (§4.2.7)
- **Membership test** — `if x in [1, 2, 3]:` and `if x not in banned:`
  — reads like English, works on any collection, optimized for
  literals (§9.9)
- **Multi-dimensional indexing** — `tensor[2:5, :, newaxis]` is
  trait-driven syntax, not a special built-in container. (§11.7)
- **`@` operator** — `a @ b` reads as matrix multiplication and lowers
  through trait dispatch like other operators. (§4.2.2, §11.7)
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

*For a discussion of trade-offs from eliminating lifetime annotations,
see `docs/design-rationale.md`.*

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
type Point { x: f64, y: f64 }         // OK: f64 is Copy
impl Copy for Point                       // OK

type Handle { id: u32, gen: u32 }      // OK: u32 is Copy
impl Copy for Handle                      // OK

type Buffer { data: Vec[u8] }          // Vec is NOT Copy (has Drop)
impl Copy for Buffer                      // ERROR: field `data` is not Copy

type File { fd: i32 }
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

**Drop on reassignment:** When a `var` binding of a Drop type is
reassigned, the compiler drops the old value before storing the new
one. This prevents resource leaks in loops:

```
var h = create_resource()
for i in 0..n:
    h = transform(h)
    // old h dropped here — resource released before new value stored
```

**Drop on expression temporaries:** Temporaries created within an
expression are dropped at the end of the enclosing statement. This
frees intermediate resources automatically:

```
let c = process(combine(a, b))
// combine's result is a temporary — dropped after process reads it
// only c survives
```

**Partial moves from Drop types are forbidden** in normal code.
Inside `drop` itself, you can access and consume fields freely.
Outside of `drop`, moving a field out of a Drop type is a compile
error:

```
type FileWrapper { fd: File, name: String }
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

**Control flow restriction:** `return`, labeled or unlabeled `break`,
labeled or unlabeled `continue`, `goto`, and `?` are **compile errors**
inside `defer` or `errdefer` blocks. Defer runs during scope cleanup
— non-local control flow would silently swallow the function's actual
return value or jump to unexpected locations:

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

**`errdefer`:** Like `defer` but only executes when the function returns an
error (via `?` propagation). On normal return paths, `errdefer` is skipped:

```
fn connect(url: str) -> Result[Connection, Error]:
    let conn = open_socket(url)?
    errdefer conn.close()       // only runs if a later ? fails
    let auth = authenticate(conn)?  // if this fails, conn.close() runs
    Connection { conn, auth }       // success: errdefer does NOT run
```

`errdefer` and `defer` execute in LIFO order relative to each other. On error
return, both `errdefer` and `defer` blocks run. On success return, only `defer`
blocks run.

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
    match r:
        Some(v) => print(v) // OK: local use
        None    => ()

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
print(r)       // last use of r; borrow ends here
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
scope s =>
    s.spawn(() => run_physics(&world.transforms, &mut world.velocities))
    s.spawn(() => run_render(&world.transforms, &world.sprites))
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

**Raw pointers:** Auto-deref also applies to `*const T` and
`*mut T`. When `p` has type `*mut Sha256`, `p.state[0]` is
equivalent to `(*p).state[0]`. The dereference is still unsafe —
the access must be inside an `unsafe` block or `unsafe fn`.

```
unsafe fn compress(ctx: *mut Sha256):
    let a = ctx.state[0]        // auto-deref: (*ctx).state[0]
    ctx.buf[3] = 0x80           // auto-deref: (*ctx).buf[3] = 0x80
```

**The vibe:** "I don't care how many layers of indirection there
are, just give me the `.name` field."

### 3.8 Auto-Referencing

When a function takes `&T` and you pass an owned `T`, the compiler
automatically borrows it:

```
fn print_user(u: &User): print(u.name)

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
type ConsoleLog {}
impl Logger for ConsoleLog:
    fn log(self: &Self, msg: &str): print(msg)

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

### 4.2 Arithmetic and Operators

#### 4.2.1 Numeric Literals

```
42              // decimal integer
1_000_000       // underscores for readability (ignored)
0xFF            // hexadecimal (prefix 0x or 0X)
0b1010          // binary (prefix 0b or 0B)
0o77            // octal (prefix 0o or 0O)
0u8             // suffixed integer literal
0x7FFF_FFFFu32  // suffixed hexadecimal integer literal
3.14            // floating point
1.0e-5          // scientific notation
1.0f32          // suffixed float literal
0x1.0p10        // hex float (value: 1024.0)
```

Underscores may appear between digits in any literal for
readability: `1_000_000`, `0xFF_FF`, `0b1111_0000`.

Integer and float literals may carry a type suffix directly on the
literal token:

- Integer suffixes: `u8`, `u16`, `u32`, `u64`, `i8`, `i16`, `i32`, `i64`
- Float suffixes: `f32`, `f64`

Examples:

```
255u8
0xDEAD_BEEFu32
42i64
3.14f32
```

The suffix is part of the literal. It is written without whitespace and
without a separator underscore. `0u64` is valid; `0_u64` is not part of
the language surface syntax.

**Default literal types:** if no suffix and no surrounding context forces
another numeric type:

- Unsuffixed integer literals default to `i32`
- Unsuffixed float literals default to `f64`

**Contextual numeric inference:** unsuffixed numeric literals are resolved
from surrounding type context before falling back to the defaults above.
The compiler may infer an unsuffixed literal's type from:

1. The target type of a typed binding or assignment
2. A function parameter type at the call site
3. The peer operand in a numeric binary operator
4. The enclosing function's declared return type for tail expressions
5. A known array element type
6. A known struct field type

Examples:

```
var acc: u64 = 0          // 0 is inferred as u64
take_u32(42)              // 42 is inferred as u32
let y = x + 1             // if x is u64, 1 is inferred as u64
let z = x >> 31           // shift amount defaults independently to u32
fn zero() -> u64: 0       // tail literal is inferred as u64
let p = Point { x: 0, y: 0 } // field literals infer from field types
```

Suffixed literals are explicit and do not participate in contextual
retyping. If a context expects `u32` and the literal is `42u8`, the
program is ill-typed unless an explicit conversion is written.

**Range checking:** a suffixed literal must fit in its declared type. For
example, `256u8` is invalid.

#### 4.2.2 Arithmetic Operators

```
a + b       // addition
a - b       // subtraction
a * b       // multiplication
a / b       // division (integer: truncates toward zero)
a % b       // remainder (sign follows dividend, like C)
a @ b       // matrix multiplication / generalized matmul
-a          // unary negation
```

All arithmetic operators work on all integer types (`i8`–`i64`,
`u8`–`u64`) and floating point types (`f32`, `f64`).

`@` is a distinct infix operator at the same precedence level as
`*`, `/`, and `%`. It is intended for matrix multiplication and
generalized tensor products. Primitive numeric types do not provide
built-in `@`; user-defined types participate through the `MatMul`
operator trait (§11.7).

#### 4.2.3 Integer Overflow

Arithmetic is checked in safe code by default. Integer overflow
causes a panic in debug builds. Release builds may be configured
for panic, wrap, or saturation; the default is panic.

```toml
# with.toml
[build]
overflow = "panic"      # default: panic on overflow
overflow = "wrap"       # two's complement wrapping
overflow = "saturate"   # clamp to min/max
```

**Explicit wrapping operators** bypass the overflow check:

```
a +% b      // wrapping addition
a -% b      // wrapping subtraction
a *% b      // wrapping multiplication
```

These always produce the two's complement result, regardless of
build mode. Use them for hash functions, checksums, and
cryptographic code.

**Explicit saturating operators** clamp to the type's representable range:

```
a +| b      // saturating addition
a -| b      // saturating subtraction
a *| b      // saturating multiplication
```

When the mathematical result exceeds the type's maximum, the result
is the maximum. When it falls below the minimum, the result is the
minimum. This is useful for audio processing, color blending, health
bars, and any domain where clamping is the correct overflow behavior.

```
let x: u8 = 250
let y: u8 = x +| 20        // 255 (clamped, not 14 or panic)

let a: i8 = 120
let b: i8 = a +| 20        // 127 (clamped)

let c: u8 = 5
let d: u8 = c -| 10        // 0 (clamped, not 251 or panic)
```

Saturating operators are defined for all integer types. They are not
defined for floating-point types (floats already saturate to ±infinity
per IEEE 754). Using them with floats is a compile error.

**All three overflow modes coexist:**

```
x + y       // checked: panic on overflow (default)
x +% y      // wrapping: two's complement wrap
x +| y      // saturating: clamp to min/max
```

#### 4.2.4 Bitwise Operators

```
a & b       // bitwise AND
a | b       // bitwise OR
a ^ b       // bitwise XOR
~a          // bitwise NOT (one's complement)
a << n      // left shift
a >> n      // right shift
```

All bitwise operators work on all integer types (`i8`–`i64`,
`u8`–`u64`). Mixed-width operands are promoted to the wider type.

**Right shift semantics:**

- **Signed types** (`i8`–`i64`): arithmetic right shift
  (sign-extending — the sign bit is replicated into vacated bits).
- **Unsigned types** (`u8`–`u64`): logical right shift
  (zero-filling — vacated bits are filled with zeros).

```
let x: i32 = -8
x >> 1          // -4 (arithmetic: sign preserved)

let y: u32 = 0x80000000
y >> 1          // 0x40000000 (logical: zero-filled)
```

**Shift operations:** The shift operators `<<` (left shift) and `>>`
(right shift) take a left operand of any integer type and a right
operand of any unsigned integer type. A signed right operand is a type
error; callers must cast explicitly.

When the right operand is less than the bit width of the left operand,
the shift has its usual arithmetic meaning.

When the right operand is greater than or equal to the bit width of the
left operand, the result is defined as follows:

- Left shift (`<<`) produces `0`.
- Logical right shift (`>>` on an unsigned value) produces `0`.
- Arithmetic right shift (`>>` on a signed value) produces `0` for
  non-negative values and `-1` for negative values (the sign bit
  repeated).

Shift operations are defined for all well-typed inputs and cannot cause
undefined behavior.

**Rotation:**

```
x.rotate_left(n)    // bitwise left rotation
x.rotate_right(n)   // bitwise right rotation
```

Rotation is available as a method on all integer types. It wraps
bits that shift off one end back onto the other end. Compiles to
a single `ror`/`rol` instruction on all modern architectures
(via LLVM's `fshl`/`fshr` intrinsics).

```
let x: u32 = 0x12345678
x.rotate_right(8)       // 0x78123456
x.rotate_left(4)        // 0x23456781
```

**Byte swap:**

```
x.swap_bytes()      // reverse byte order of integer value
```

Available on all integer types ≥16 bits. Identity for `i8`/`u8`.
Compiles to LLVM's `@llvm.bswap` intrinsic (single `bswap`
instruction on x86/ARM).

```
let x: u32 = 0x12345678
x.swap_bytes()              // 0x78563412
x.swap_bytes().swap_bytes() // roundtrip: 0x12345678
```

**Byte-order encoding/decoding:**

The `std.crypto.endian` module provides functions for big-endian
and little-endian encoding/decoding from byte buffers:

```
use std.crypto.endian

// Decode from byte buffer at offset
u16_from_be(buf: *const u8, offset: i32) -> u16
u32_from_be(buf: *const u8, offset: i32) -> u32
u64_from_be(buf: *const u8, offset: i32) -> u64
u16_from_le(buf: *const u8, offset: i32) -> u16
u32_from_le(buf: *const u8, offset: i32) -> u32
u64_from_le(buf: *const u8, offset: i32) -> u64

// Encode to byte buffer at offset
u16_to_be(buf: *mut u8, offset: i32, val: u16)
u32_to_be(buf: *mut u8, offset: i32, val: u32)
u64_to_be(buf: *mut u8, offset: i32, val: u64)
u16_to_le(buf: *mut u8, offset: i32, val: u16)
u32_to_le(buf: *mut u8, offset: i32, val: u32)
u64_to_le(buf: *mut u8, offset: i32, val: u64)
```

Usage:

```
let word = u32_from_be(buf, 0)      // read big-endian u32
u32_to_le(out, 4, value)            // write little-endian u32
```

**Bit counting:**

```
x.popcount()        // count set bits (number of 1-bits)
x.clz()             // count leading zeros (from MSB)
x.ctz()             // count trailing zeros (from LSB)
```

Available on all integer types. Return type is `i32` regardless of
input width. Returns the type's bit width when the value is zero
(for `clz` and `ctz`).

```
let x: u32 = 0b00010000
x.popcount()        // 1
x.clz()             // 27
x.ctz()             // 4

let zero: u32 = 0
zero.clz()          // 32
zero.ctz()          // 32

0xFFu8.popcount()   // 8
```

Compiles to single hardware instructions on all modern architectures
(via LLVM's `ctpop`, `ctlz`, `cttz` intrinsics).

**Bit reversal:**

```
x.bitreverse()      // reverse the order of all bits
```

Available on all integer types. Return type matches the input type.
Bit 0 becomes the MSB, bit 1 becomes MSB-1, etc.

```
let x: u8 = 0b10110000
x.bitreverse()      // 0b00001101

let y: u32 = 0x80000000
y.bitreverse()      // 0x00000001
```

Compiles to LLVM's `llvm.bitreverse` intrinsic.

**Compile-time evaluation:** All bit manipulation methods can be
evaluated at compile time when the receiver is a constant.

#### 4.2.5 Compound Assignment Operators

```
a += b      // a = a + b
a -= b      // a = a - b
a *= b      // a = a * b
a /= b      // a = a / b
a %= b      // a = a % b
a &= b      // a = a & b
a |= b      // a = a | b
a ^= b      // a = a ^ b
a <<= n     // a = a << n
a >>= n     // a = a >> n
a +%= b     // a = a +% b (wrapping addition)
a -%= b     // a = a -% b (wrapping subtraction)
a *%= b     // a = a *% b (wrapping multiplication)
a +|= b     // a = a +| b (saturating addition)
a -|= b     // a = a -| b (saturating subtraction)
a *|= b     // a = a *| b (saturating multiplication)
```

Compound assignment requires `a` to be a mutable binding (`var`)
or a mutable reference. The operation and assignment are atomic
from the language's perspective (no intermediate observable state).

For Drop types, compound assignment is equivalent to: evaluate
`a op b`, drop the old value of `a`, store the result. This
ensures resources are properly released.

#### 4.2.6 Implicit Widening

Implicit widening is only allowed for lossless numeric conversions:
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

#### 4.2.7 Comparison Operators and Chaining

```
a == b
a != b
a < b
a <= b
a > b
a >= b
```

Ordered comparisons (`<`, `<=`, `>`, `>=`) may be chained:

```
let valid = 0.0 < x < 1.0
let in_range = lo <= x <= hi
let sorted = a < b < c < d
```

`a < b < c` is equivalent to `(a < b) and (b < c)`, except each
interior operand is evaluated exactly once. When an interior operand
is non-trivial, the compiler introduces a hidden temporary:

```
left() < mid() < right()
// equivalent to:
let __cmp_tmp = mid()
left() < __cmp_tmp and __cmp_tmp < right()
```

Only ordered comparisons chain. Equality and membership operators do
not: `a == b == c` and `x in y in z` are compile errors. Chained
comparisons require each pairwise comparison to produce `bool`. If a
type wants elementwise or non-boolean comparison results, write the
pairwise comparisons explicitly and combine them yourself.

### 4.3 Structs

Structs are declared with `type` using either inline braces or an
indented block:

```
type Point { x: f64, y: f64 }

type Config:
    host: str
    port: i32
```

No methods, no constructors, no inheritance. Functions are associated
with types via extension blocks (Section 9.5).

**Struct literal forms:**

```
Point { x: 1.0, y: 2.0 }     // named inline
let p = Point:               // named block
    x: 1.0
    y: 2.0
Point { 1.0, 2.0 }           // positional inline
```

Named literals require all non-defaulted fields; fields may appear in
any order. Positional literals require all fields in declaration order.
Mixing named and positional fields in one literal is a compile error.
Positional form is inline only. Block form is named only. Field access
is always by name, regardless of construction form. Inline forms use
commas between fields; block form uses newlines.

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
of the `with` construct — see §7.4. Record update supports named
inline and named block fields only; positional record update is invalid.

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
type ServerConfig {
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

The block form also supports defaults:

```
type ServerConfig:
    host: str = "127.0.0.1"
    port: u16 = 8080
    max_conns: usize = 1000
    timeout: Duration = Duration.seconds(30)
```

Default expressions are evaluated at the construction site, not at
type definition time. Each construction gets a fresh evaluation:

```
type Request {
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
type PoolConfig {
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

### 4.3a Fixed-Size Arrays

Fixed-size arrays have a compile-time-known length and are
stack-allocated value types:

```
let a: [i32; 4] = [1, 2, 3, 4]
let x = a[0]                    // 1
let y = a[3]                    // 4

var b: [f32; 8] = [0.0; 8]     // fill with 0.0
b[2] = 3.14
```

**Syntax:**

```
[T; N]           // type: array of N elements of type T
[v0, v1, ..., vN] // literal: array from elements
[value; N]       // repeat: array of N copies of value
arr[i]           // index: access element i
arr.len()        // length: returns N (compile-time constant)
```

**Semantics:**

- Length `N` must be a compile-time constant (integer literal or `const`).
- `[T; N]` has size `N * sizeof(T)` and alignment `alignof(T)`.
- Passed by value (copied on assignment). For large arrays, pass
  by reference.
- Bounds checking in debug mode, unchecked in release.
- `Copy` if the element type is `Copy`.

#### 4.3a.1 Array-to-Pointer Decay
With has no implicit array-to-pointer decay. Use explicit decay:
`&arr[0] as *const T` (or `*mut T`). This applies in all contexts:
assignment, function arguments, and comparisons.

```
fn sum(arr: [i32; 4]) -> i32:
    var total = 0
    for i in 0..4:
        total = total + arr[i]
    total

// Fixed arrays in structs (inline, no pointer indirection):
type Shape { dims: [usize; 8], rank: i32 }
```

**Interaction with pattern matching:**

```
match items:
    []              => "empty"
    [only]          => "single"
    [first, ..rest] => "head: {first}, {rest.len()} more"
```

### 4.3b Bitpacked Structs

The `@[bitpacked]` attribute provides bit-level field packing where
fields occupy exactly their declared bit width with no padding.

```
@[bitpacked]
type Flags = {
    enabled: bool,         // 1 bit
    priority: u3,          // 3 bits
    mode: u4,              // 4 bits
}
// Total: 8 bits = 1 byte. sizeof[Flags]() == 1
```

```
@[bitpacked]
type IpHeader = {
    version: u4,           // 4 bits
    ihl: u4,               // 4 bits
    dscp: u6,              // 6 bits
    ecn: u2,               // 2 bits
    total_length: u16,     // 16 bits
    identification: u16,   // 16 bits
    flags_frag: u16,       // 16 bits
    ttl: u8,               // 8 bits
    protocol: u8,          // 8 bits
    checksum: u16,         // 16 bits
    src_addr: u32,         // 32 bits
    dst_addr: u32,         // 32 bits
}
// Total: 160 bits = 20 bytes
```

**Rules:**

1. Fields are laid out MSB-first (network byte order) from first
   field to last, with no gaps.
2. Total size is `ceil(sum_of_field_bits / 8)` bytes.
3. All field types must have a known bit width. Pointers, slices,
   strings, structs (except nested bitpacked), and Vecs are not
   allowed. Compile error: "bitpacked fields must be integer, bool,
   or bitpacked struct type."
4. `bool` occupies 1 bit. `true` is `1`, `false` is `0`.
5. Non-byte-sized integer types are valid field types (see below).
6. Nested `@[bitpacked]` structs are allowed; their bits are inlined.

**Field access** uses the same dot syntax as regular structs. The
compiler generates shift-and-mask operations:

```
var flags = Flags { enabled: true, priority: 5, mode: 12 }
let p = flags.priority        // extracts bits, returns u3
flags.mode = 3                // inserts bits
```

**Pointers to bitpacked fields** are a compile error. The field may
not be byte-aligned:

```
let f = Flags { enabled: true, priority: 5, mode: 12 }
let p = &f.priority     // error: cannot take address of bitpacked field
```

**Casting** to and from the backing integer type:

```
let flags = Flags { enabled: true, priority: 5, mode: 12 }
let byte = flags as u8    // 0b_1_101_1100 = 0xBC

let flags2 = 0xBCu8 as Flags
// flags2.enabled == true, flags2.priority == 5, flags2.mode == 12
```

The backing integer type is the smallest unsigned integer that holds
all bits: `u8` for 1-8 bits, `u16` for 9-16, `u32` for 17-32,
`u64` for 33-64.

**Non-byte-sized integer types:**

To support bitpacked structs, With provides integer types with
non-standard widths:

```
u1, u2, u3, u4, u5, u6, u7     // unsigned sub-byte
i1, i2, i3, i4, i5, i6, i7     // signed sub-byte
u12, u21, u24                    // selected wider non-standard widths
```

When used as local variables, non-byte-sized integers are stored in
the next larger standard-width register (e.g., `u3` occupies an `i32`
register with the upper bits zeroed). Arithmetic works normally; the
result is masked to the type's range.

### 4.4 Enums (Algebraic Data Types)

Enums are declared with the `enum` keyword using either an indented
block or inline braces:

```
enum Shape:
    Circle(radius: f64)
    Rectangle(w: f64, h: f64)
    Triangle(a: f64, b: f64, c: f64)

enum Direction { North | South | East | West }
```

An optional leading `|` is allowed in block form:

```
enum Shape:
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
enum Role { Admin | Member | Guest }

// Return type is known → .Member is unambiguous
fn default_role -> Role: .Member

// Match subject type is known → .Admin, .Member, .Guest work
fn describe(role: Role) -> str:
    match role:
        .Admin   => "Administrator"
        .Member  => "Member"
        .Guest   => "Guest"

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

**Qualified patterns in `match`:**

Match patterns may use qualified `Type.Variant` syntax:

```
fn describe(c: Color) -> str:
    match c:
        Color.Red   => "red"
        Color.Green => "green"
        _           => "other"
```

Qualified patterns also work with payloads:

```
fn area(s: Shape) -> f64:
    match s:
        Shape.Circle(r)       => 3.14159 * r * r
        Shape.Rectangle(w, h) => w * h
        _                     => 0.0
```

The compiler validates that the qualifying type matches the match
subject type, producing a compile error for mismatches.

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
enum Token:
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
enum JsonValue:
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
    |> filter(t => t.is_tstr())
    |> map(t => t.as_tstr_ref().unwrap())
    |> collect()
```

For variants with multiple fields, `.as_variant()` returns
`Option[(A, B)]` (a tuple):

```
enum Shape:
    | Circle(radius: f64)
    | Rectangle(w: f64, h: f64)

shape.as_circle()       // Option[f64]
shape.as_rectangle()    // Option[(f64, f64)]
```

Unit variants (no data) generate only `.is_variant()`.

These methods are generated unconditionally for all enums — no
`@[derive]` needed. They are always available.

### 4.4a Discriminant Enums

Enums can specify an integer representation type and explicit discriminant
values for each variant. Discriminant enums use the `enum` keyword with a
representation type:

```
enum Color: i32:
    Red = 1
    Green = 2
    Blue = 4
```

Inline form is also supported:

```
enum Color: i32 { Red = 1, Green = 2, Blue = 4 }
```

The type after the first colon is the **representation type** — an integer type
(`i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`) that determines the
underlying storage. Each variant
is assigned an explicit integer value with `= N`.

**Auto-incrementing:** If a variant omits the `= N`, it defaults to the previous
variant's value plus one (or zero for the first variant):

```
enum Status: i32:
    Pending = 0
    Active          // 1 (auto)
    Suspended = 10
    Archived        // 11 (auto)
```

**Discriminant enums with payloads:** Variants can carry associated data just
like regular enums, combined with explicit discriminant values:

```
enum Msg: i32:
    Quit = 0
    Move(i32, i32) = 1
    Write(str) = 2
```

When any variant has a payload, the LLVM representation is a tagged union
`{ repr_ty, [max_payload_size x i8] }` — the same layout as regular enums but
with the tag being the discriminant value. Pattern matching extracts payloads
the same way as regular enums.

**`@[flags]` attribute:** For bitflag enums, `@[flags]` changes auto-increment
to power-of-two doubling:

```
@[flags]
enum Perms: i32:
    Read         // 1 (default first)
    Write        // 2
    Execute      // 4
```

Bitwise operations work naturally since the enum **is** its integer value.

**Conversion:** `Type.from_int(n)` converts an integer to `Option[Type]`,
returning `.None` for values that don't match any defined discriminant:

```
let c = Color.from_int(2)    // Some(Color.Green)
let x = Color.from_int(99)   // None
```

**Casting:** `value as i32` extracts the underlying integer (identity cast).

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

Ranges are ordinary first-class values: they can be stored in
variables, passed to functions, and returned like any other value.

```
for i in 0..n:
    process(i)

let window = 100..200
publish_window(window)

let slice = data[2..5]         // elements at index 2, 3, 4

if x in 1..=100:               // membership test (§9.9)
    handle_valid(x)

match code:
    200..=299 => "success"
    400..=499 => "client error"
    _         => "other"
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
    print(f"{key}: {value}")

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

### 4.8a Slices

Slices are borrowed views into contiguous memory (arrays, Vecs):

```
[]T         shared (immutable) slice
[]mut T     exclusive (mutable) slice
```

A slice is a fat pointer: `(ptr: *const T, len: usize)`. It does
not own the data — it borrows from an array, Vec, or other
contiguous storage.

```
fn sum(data: []f32) -> f32:
    var total: f32 = 0.0
    for i in 0..data.len():
        total = total + data[i]
    total

let arr: [f32; 4] = [1.0, 2.0, 3.0, 4.0]
let s = sum(arr[..])      // slice of entire array
let s2 = sum(arr[1..3])   // slice of elements 1, 2
```

Slices are ephemeral (§5) — they cannot be stored in structs or
returned from functions (they borrow the underlying storage).
Bounds-checked in debug mode.

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
body's last expression is `Unit` (a statement like `print`), the
compiler implicitly returns `T.default()`.

```
// Before: manual trailing 0
fn demo_strings -> i32:
    let hello = "Hello, C interop!"
    puts(hello)
    print(f"strlen = {strlen(hello)}")
    0                                      // annoying boilerplate

// After: implicit default return
fn demo_strings -> i32:
    let hello = "Hello, C interop!"
    puts(hello)
    print(f"strlen = {strlen(hello)}")
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
type Config {
    port: i32,          // defaults to 0
    debug: bool,        // defaults to false
    name: str,          // defaults to ""
}

fn make_config -> Config:
    print("Creating default config...")
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
type BufSlice { offset: usize, len: usize } with Copy
```

Pattern: structs store `BufSlice` (storable offsets); accessor methods
compute ephemeral `&str`/`&[u8]` on demand from an owned buffer.

```
type Request {
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
match tok.kind:
    .Ident   => handle_ident(tok.text)
    .Number  => handle_number(tok.text)
    .String  => handle_string(tok.text)

// OK: for-loop processes each token — tok drops at iteration end
while let Some(tok) = next_token(&mut parser):
    process(tok)

// LIMITATION: Cannot collect ephemeral tokens into a Vec directly.
// Each Token borrows &mut parser (Rule 6, §21.1), so holding one
// Token prevents calling next_token() again.
//
// To collect, use owned tokens with offset indices:
type OwnedToken { start: u32, end: u32, kind: TokenKind, span: Span }

fn next_owned_token(parser: &mut Parser) -> Option[OwnedToken]:
    let tok = next_raw_token(parser)?
    Some(OwnedToken { start: tok.start, end: tok.end, kind: tok.kind, span: tok.span })

let tokens = with Vec.new() as mut toks:
    while let Some(tok) = next_owned_token(&mut parser):
        toks.push(tok)    // OwnedToken is NOT ephemeral — no borrows
// tokens: Vec[OwnedToken] is storable

// ERROR: cannot store in a non-ephemeral struct
type Module { tokens: Vec[Token] }   // REJECTED: ephemeral field
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
type Handle[T] { index: u32, generation: u32 }
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
value within this scope.** It appears in five forms, all expressing
the same idea — bounded, explicit interaction with data.

| Form | Meaning | Appears in |
|------|---------|------------|
| `with as name:` | Guarded access (lock, arena, file) | Concurrent/resource code |
| `with value as mut name:` | Scoped mutation (builder pattern) | Initialization, configuration |
| `with expr as name:` | Scoped binding (named temporary) | Pipelines, intermediate values |
| `with name(expr):` | Scoped implicit context | Allocators, devices, loggers, ambient config |
| `{ expr with field: val }` | Record update (functional copy) | Data transformation |

### 7.1 Form 1: Guarded Access

When data lives behind a lock, arena, or resource guard, `with`
provides scoped access. If the expression's type implements
`Scoped` or `ScopedMut`, the compiler **automatically** dispatches
through the guard. No keyword needed — the type tells the compiler
everything.

```
with lock.read() as data:
    data.iter() |> filter(x => x.active) |> count()

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
// → lock.read().enter(data => body)

with store.write() as mut data: body
// → store.write().enter_mut(data => body)
```

Multiple guarded bindings are flat, nesting left-to-right:
```
with a.read() as textures,
     b.read() as meshes,
     c.write() as mut materials:
    body
// → a.read().enter(textures =>
//     b.read().enter(meshes =>
//       c.write().enter_mut(materials => body)))
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

### 7.3a Form 3a: Implicit Context

`with name(expr):` introduces an **implicit context binding**. Any
function parameter declared with the `implicit` modifier may be
filled from the innermost matching implicit context in scope.

```
fn sin(x: &Array, ctx: implicit &Context) -> Array: ...

with context(default_device()):
    let y = sin(x)                // ctx resolved implicitly
    let z = a @ b                 // implicit context applies here too
    let w = sin(x, ctx: other)    // explicit argument overrides implicit
```

Implicit resolution is **lexical and type-based**:

- Positional arguments are matched first.
- Named arguments are matched second.
- Unfilled `implicit` parameters are searched from the innermost
  enclosing `with name(expr):` block outward.
- Remaining omitted parameters may then be filled from defaults.

Additional rules:

- Auto-ref applies during implicit lookup, so `Context` and `&Context`
  compose naturally with existing call ergonomics.
- A function may not declare two `implicit` parameters of the same
  type.
- An `implicit` parameter may not also have a default value.
- Inner implicit contexts shadow outer contexts of the same type.
- Closures capture the implicit contexts visible at their definition
  site, just like ordinary lexical bindings.

The identifier in `with name(expr):` is descriptive. Resolution is
driven by type, not by the identifier text.

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
with name(expr):                  →  introduce implicit context for body

// If expr implements Scoped → guarded access
with lock.read() as data:          →  expr.enter(data => body)
with store.write() as mut data:    →  expr.enter_mut(data => body)

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
- Labeled `break 'label` and `continue 'label` inside a `with`
  block may target any visible label in the enclosing function;
  `with` does not create a label-scope boundary.
- **`goto 'label`** inside a `with` block may target a visible label
  in the enclosing function, subject to the normal goto restrictions
  (§13.5b).
- **`?`** propagates errors to the **enclosing function**.

```
fn find_value(lock: &Mutex[HashMap[str, i32]], key: &str) -> Option[i32]:
    with lock.lock() as map:
        match map.get(key):
            Some(v) => return Some(v)   // returns from find_value
            None    => ()
    None

fn process_all(lock: &Mutex[Vec[Item]]) -> Result[Unit, AppError]:
    with lock.lock() as items:
        for item in items:
            if item.is_invalid():
                continue                 // continues enclosing for loop
            validate(item)?              // propagates to process_all
    // implicit Ok(())

fn process_until_done(lock: &Mutex[Vec[Item]]):
    'outer for i in 0..10:
        with lock.lock() as items:
            if items[i].is_terminal():
                break 'outer             // exits the labeled outer loop
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
    let results = users.traverse(u =>
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
type MutexGuard[T] { ... }

@[no_await_guard]
type ReadGuard[T] { ... }

@[no_await_guard]
type WriteGuard[T] { ... }
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

Forms 2, 3, and 3a (`with expr as mut name:`, `with expr as name:`,
and `with name(expr):`) are unaffected — they do not create a guard
value and therefore introduce no `@[no_await_guard]` obligation by
themselves.

**Clone at boundary:**

Escaping data from a guarded `with` block requires the data to be
owned, not borrowed. This means cloning is the standard pattern for
extracting values from behind a guard:

```
// Clone at boundary: the idiomatic pattern
let name = with db.read() as users:
    users.get(id)
        .map(u => u.name.clone())   // clone to escape the guard

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

Function bodies may use either colon form or brace form (§29.13):

```
fn NAME(PARAMS) -> TYPE { BODY }
fn NAME(PARAMS) { BODY }
fn NAME -> TYPE { BODY }
fn NAME { BODY }
```

Parentheses are required when a function takes parameters. When a
function takes no parameters, parentheses may be included or
omitted — `fn greet:` and `fn greet():` are both legal. The
idiomatic style omits them. The return type `-> TYPE` is omitted
when the function returns `Unit` (void). The body is introduced by
either `:` (colon form) or `{ }` (brace form) — see §29.13 for
the full rules.

```
fn greet: print("hello")               // colon inline
fn greet { print("hello") }            // brace inline
fn greet(): print("hello")             // also legal, parens optional
fn get_pi -> f64: 3.14159              // no args, returns f64
fn double(x: i32) -> i32: x * 2       // args + return type
fn double(x: i32) -> i32 { x * 2 }    // same, brace form
fn log(msg: str): print(msg)           // args, returns Unit
```

**Conditional syntax:**

Block `if` uses `:` plus an indented body. Inline `if` uses `then`
and may appear in statement or expression position:

```
if cond:
    body
else:
    body

if cond then body
if cond then body else body
let x = if cond then a else b

if x < lo then lo
else if x > hi then hi
else x

if x < 0:
    handle_negative()
else if x == 0:
    handle_zero()
else:
    handle_positive()
```

Both forms support arbitrarily long `else if` chains. `else if` is
parsed as `else` followed by a new `if`. A single chain must use one
form throughout; mixing inline and block forms in one chain is a
compile error. Inline-if uses `then`; `else` is required in expression
position unless the then-branch is `Never`-typed. `then` is reserved
and valid only in inline-if syntax. Colon-based and brace-based
inline-if forms are rejected.

### 9.1a Named Arguments, Default Parameters, and Implicit Parameters

Function parameters may be passed positionally or by name. Parameters
may declare a default value with `= expr`, and may declare an
`implicit` modifier to request resolution from an enclosing
`with name(expr):` scope (§7.3a).

```
fn connect(host: str, port: u16, timeout: i32 = 30) -> Connection
fn sin(x: &Array, ctx: implicit &Context) -> Array

connect("localhost", 8080, 60)
connect("localhost", port: 8080)
connect(timeout: 60, host: "localhost", port: 8080)

with context(default_device()):
    sin(x)
    sin(x, ctx: fallback_device)
```

**Rules:**

- Positional arguments must come before named arguments.
- A parameter may not be specified more than once.
- Named arguments must match parameter names exactly.
- Named arguments may appear in any order relative to one another.
- Default parameters may be omitted positionally only from the end of
  the parameter list, or skipped arbitrarily when the caller uses
  named arguments.
- Default expressions are evaluated at the call site on every call
  where the argument is omitted.
- Call resolution order is: positional arguments, named arguments,
  implicit parameters, then defaults.
- `extern fn` values, closure values, and placeholder-based partial
  application calls do not support named arguments.
- A function may not declare two `implicit` parameters of the same
  type, and an `implicit` parameter may not also have a default.

```
fn greet(name: str, greeting: str = "Hello"):
    print(f"{greeting}, {name}!")

greet("Alice")                  // greeting defaults to "Hello"
greet("Bob", "Hey")             // explicit positional override
greet(name: "Cara")             // named + default
greet(greeting: "Hi", name: "Dae")
```

### 9.1b `const` Declarations

Compile-time constants are declared with `const`:

```
const MAX_SIZE: i32 = 1024
const PI: f64 = 3.14159
const HEADER: str = "X-Custom"
```

**Syntax:** `const NAME: TYPE = EXPR`

The type annotation is required. The expression must be evaluable at compile
time — integer literals, arithmetic (`+`, `-`, `*`, `/`, `%`), unary negate,
logical `not`, and references to other `const` values.

```
const WIDTH: i32 = 80
const HEIGHT: i32 = 24
const AREA: i32 = WIDTH * HEIGHT    // computed at compile time
```

`const` values are inlined at every use site. They have no runtime address and
cannot be mutated. They may appear at module scope or inside function bodies.

**Difference from `let`:** `let` bindings are runtime values (even if initialized
from a constant). `const` values are guaranteed to be compile-time constants and
are always inlined.

### 9.2 Tail Call Optimization

Tail calls may be optimized even without annotations. `@[tailrec]`
turns that optimization into a guarantee: if the compiler cannot
eliminate stack growth for the annotated recursive calls, it rejects
the program.

```
@[tailrec]
fn factorial(n: Int, acc: Int) -> Int:
    match n { 0 => acc, _ => factorial(n - 1, n * acc) }
```

Tail position means:

- The final expression of a function body
- The final expression of a block already in tail position
- Both branches of an `if`/`else` already in tail position
- Every arm of a `match` already in tail position

The following are **not** tail position:

- Any call followed by additional work (`1 + recur(...)`, field access,
  method call, etc.)
- Loop bodies
- Calls with an active `defer` or `errdefer`
- Calls that leave a `Drop`-implementing local live across the call

```
@[tailrec]
fn bad(n: Int) -> Int:
    if n <= 0: 0
    else: 1 + bad(n - 1)        // compile error: not tail position
```

Self-recursive `@[tailrec]` functions must compile to a loop or
equivalent frame-reusing form. Mutual tail recursion is permitted
only when every function in the cycle is annotated `@[tailrec]` and
the compiler can verify the cycle without stack growth; otherwise the
program is ill-formed.

### 9.3 Closures

```
x => x + 1
(x, y) => x * y
() => print("hello")
```

The `=>` token means "produces this value" and is used in both closures
and match arms. The `->` token is reserved exclusively for return type
annotations (e.g., `fn foo() -> i32`).

Implicit `it` parameter (see §9.3.1):
```
items |> filter(it.age > 21) |> map(it.name)
```

#### 9.3.1 Implicit `it` Parameter

When a function expects a single-parameter closure, the expression can
use `it` to refer to the implicit parameter instead of declaring an
explicit closure with `x => expr` syntax:

```
items |> filter(it.age > 21)     // equivalent to x => x.age > 21
items |> map(it.name)            // equivalent to x => x.name
items |> filter(it % 2 == 0)    // equivalent to n => n % 2 == 0
items |> sort_by(it.score)       // equivalent to x => x.score
```

`it` is a reserved keyword. It may only appear in expression positions
where the surrounding call site expects a single-parameter function type.
The compiler infers `it`'s type from the expected function parameter type.

**Nested `it` is forbidden:** If an `it`-expression appears inside
another `it`-expression, the inner closure must use explicit `param => expr`
syntax. This prevents ambiguity about which closure level `it` refers to.

```
// OK: outer uses it, inner uses explicit parameter
items |> map(it.children |> filter(c => c.active))

// ERROR: nested it is ambiguous
items |> map(it.children |> filter(it.active))
```

**`_` is not a closure placeholder.** `_` means discard (in patterns)
or placeholder (in partial application). For closure shorthand, `it` is
the one way.

**Error codes:**
- E0951: nested implicit `it` is ambiguous — use explicit `param => expr` for inner closure
- E0952: `it` used in context expecting N != 1 parameters
- E0953: `it` is a reserved keyword and cannot be used as an identifier

### 9.4 Partial Application

Functions can be partially applied with `_` placeholders inside a call
argument list:

```
fn add(a: i32, b: i32) -> i32: a + b
let add5 = add(5, _)        // fn(i32) -> i32
add5(3)                      // 8

let pair = make_pair(_, 10, _)   // fn(T0, T2) -> Pair
pair("x", true)

values |> map(clamp(0, 255, _))
```

Currying is not automatic. Partial application via `_` is the explicit,
controlled equivalent.

**Rules:**

- `_` is a placeholder only inside a call argument list.
- A placeholder call with `N` placeholders produces a closure taking
  `N` arguments in left-to-right placeholder order.
- Non-placeholder arguments are captured into the generated closure.
- `_` in callee position is an error.
- `add(5)` is an ordinary wrong-argument-count error, not partial
  application.
- Placeholder calls use positional arguments only; named arguments are
  not permitted in the same call.

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
type Builder { host: str, port: u16 }

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
print <| f"{key}: {value}"
```

`f <| x` desugars to `f(x)`. Right-associative. Useful for avoiding
parentheses in nested calls:

```
// These are equivalent:
assert(is_valid(parse(input)))
assert <| is_valid <| parse(input)
```

**Bitwise shift operators:**

`<<` (left shift) and `>>` (right shift) are binary operators at
precedence level 9, between bitwise operators and additive operators.

```
let flags = 1 << 4          // 16
let high = value >> 8        // extract high byte
let mask = 0xFF << (n * 8)   // position-dependent mask
```

Right shift is arithmetic (sign-extending) for signed types and
logical (zero-filling) for unsigned types.

**Function composition** uses the pipeline operator or explicit
closures:

```
let normalize = x => strip_accents(lowercase(trim(x)))
names |> map(normalize) |> collect[Vec]()
```

### 9.7 Pattern Matching

Pattern matching is the primary control flow for algebraic data types.
It is expression-oriented, exhaustive, and supports deep structural
matching. `match` has two forms:

- **Block match** uses `:` after the subject and separates arms with
  newlines.
- **Inline match** uses `{}` around arms and separates arms with
  commas.

Semicolons are not valid match arm separators.

**Block form:**
```
match shape:
    Circle(r)         => pi * r * r
    Rectangle(w, h)   => w * h
    Triangle(a, b, c) => herons_formula(a, b, c)
```

The colon is required in block form. Omitting it is a syntax error.
Block arms are separated by newlines; commas and leading `|` arm
separators are not used.

**Inline form:**
```
match n { 0 => 1, _ => n * factorial(n - 1) }
let x = match result { Ok(v) => v, Err(_) => default }
```

Inline match is an expression form. Arms are written as
`pattern => expr`; guards use `pattern if cond => expr`. Arms are
comma-separated, and a trailing comma is allowed under §29.2. The
semicolon-separated form used in earlier examples is invalid.

**Guards:**
```
match value:
    x if x > 0 => "positive"
    x if x < 0 => "negative"
    _           => "zero"
```

**Nested / deep patterns:**
```
match expr:
    Add(Lit(a), Lit(b))                 => Lit(a + b)
    Add(Lit(0), rhs)                    => rhs
    Mul(Lit(0), _) | Mul(_, Lit(0))     => Lit(0)
    other                               => other
```

**Or-patterns** share a body:
```
match day:
    Monday | Tuesday | Wednesday | Thursday | Friday => "weekday"
    Saturday | Sunday => "weekend"
```

**`@` binding:**
```
match event:
    click @ MouseClick { button: Left, pos } =>
        log("click at {pos}")
        handle(click)
```

**Literal and range patterns:**
```
match status_code:
    200         => "ok"
    301 | 302   => "redirect"
    400..=499   => "client error"
    _           => "unknown"
```

**`in` patterns:**

An `in` pattern matches when the scrutinee is contained in the given
expression. It works with any `Contains` type — arrays, ranges, sets,
or user types:

```
match method:
    in ["map", "filter", "take", "skip"] => handle_lazy()
    in ["collect", "fold", "sum", "count"] => handle_eager()
    _ => handle_other()
```

This is syntactic sugar for a guard:

```
match method:
    m if m in ["map", "filter", "take", "skip"] => handle_lazy()
    m if m in ["collect", "fold", "sum", "count"] => handle_eager()
    _ => handle_other()
```

The `in` pattern does not introduce a binding. Use `@` if you need
one:

```
match status_code:
    code @ in 200..=299 => log("success: {code}")
    code @ in 400..=499 => log("client error: {code}")
    code @ in 500..=599 => log("server error: {code}")
    other               => log("unexpected: {other}")
```

`in` patterns compose naturally with other match features:

```
fn categorize(token: TokenKind) -> Category:
    match token:
        in [Plus, Minus, Star, Slash]  => .Operator
        in [LParen, RParen, LBrace, RBrace] => .Delimiter
        in [If, Else, While, For, Match]    => .Keyword
        Ident(_)                             => .Identifier
        IntLit(_) | FloatLit(_)              => .Literal
        _                                    => .Other
```

**Struct patterns with `..` rest:**
```
match user:
    { name, age } if age >= 18 => grant_access(name)
    { name, .. }               => deny_access(name)
```

Positional struct patterns match fields in declaration order:

```
match point:
    Point(x, y) => plot(x, y)
```

**Tuple patterns:**
```
match (x, y):
    (0, 0) => "origin"
    (x, 0) => "x-axis at {x}"
    _      => "elsewhere"
```

Parentheses around a single pattern are grouping: `(p)` is the same
pattern as `p`. A one-element tuple pattern requires a comma: `(p,)`.
`()` matches the empty tuple.

**Slice patterns:**
```
match items:
    []              => "empty"
    [only]          => "single"
    [first, ..rest] => "head: {first}, {rest.len()} more"
```

For fixed-size arrays, the compiler performs compile-time length matching:
- `[a, b, c]` matches exactly 3 elements
- `[first, ..rest]` matches any array with 1+ elements, `rest` is bound to the remaining count
- `[first, ..mid, last]` matches 2+ elements, extracting both ends
- `[]` matches empty arrays (`[0]T`)

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
    print(f"found: {user.name}")
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
let result = input |> parse |> match:
    Ok(ast)  => transform(ast)
    Err(e)   => default_ast()
```

**Destructuring in `for` loops:**
```
for (id, entity) in world.entities():
    process(id, entity)

for { name, age, .. } in users:
    print(f"{name}: {age}")
```

Exhaustiveness depends on position:

- **Expression-position match** (value is used/returned): must be exhaustive.
- **Statement-position match** (value ignored): may be partial; unmatched
  variants are a no-op.
- **`@[must_use]` types** (e.g. `Result`, `Task`): match must always be
  exhaustive or include an explicit `_ => ...` catch-all arm, regardless
  of position. Partial match on `@[must_use]` types is a compile error.
  This prevents silently ignoring `Err` arms, which would contradict
  `@[must_use]` semantics.

Examples:

```
// expression-position: exhaustive required
let label = match status:
    Ok(v) => "ok"
    Err(e) => "err"

// statement-position: partial allowed (non-must_use enum)
match event:
    Click(pos) => handle_click(pos)
    KeyDown(k) => handle_key(k)
// other variants are ignored

// statement-position on @[must_use] type: catch-all required
match result:
    Ok(v) => process(v)
    _ => {}                  // explicit: "I'm intentionally ignoring errors"
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
    print(f"{key}: {val}")

// Equivalent explicit form (also valid but unnecessary):
for &(key, val) in items:
    print(f"{key}: {val}")

// Works with match on borrowed enums:
fn describe(opt: &Option[String]) -> &str:
    match opt:
        Some(s) => s       // s: &String, not String
        None    => "none"
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
    |> where((pos, _) => pos.x > 0.0)
    |> order_by((_, vel) => vel.magnitude())
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

`in` is a binary operator at the same precedence level as equality
operators (`==`, `!=`). It is non-associative — `a in b in c` is a
compile error. Ordered comparisons (`<`, `<=`, `>`, `>=`) may chain;
see §4.2.7.

**Operator precedence** (low to high):

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `or` | Left |
| 2 | `and` | Left |
| 3 | `==`, `!=`, `in`, `not in` | Non-associative |
| 4 | `<`, `>`, `<=`, `>=` | Chained |
| 5 | `\|>` (pipeline) | Left |
| 6 | `\|` | Left |
| 7 | `^` | Left |
| 8 | `&` | Left |
| 9 | `<<`, `>>` | Left |
| 10 | `+`, `-`, `++`, `??` | Left |
| 11 | `*`, `/`, `%`, `@` | Left |
| 12 | Unary prefix (`not`, `-`, `~`, `&`, `&mut`) | — |
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
    |> filter(t => t.kind in [Ident, Number, String])
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
    print("vowel")

// String search
if "error" in log_line:
    alert(log_line)

if '@' in email:
    validate_email(email)

// Enum variant sets
enum Color { Red | Green | Blue | Yellow | Cyan | Magenta }

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
    |> filter(cmd => cmd.op not in dangerous_ops)
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

**Desugaring:** `expr ?? default` desugars to `expr.unwrap_or(default)`.
The right-hand side is lazily evaluated (only computed if left is
`None`).

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
let parsed = names.traverse(s => s.parse_int())
// Err(ParseError) — "three" fails

let names = vec!["1", "2", "3"]
let parsed = names.traverse(s => s.parse_int())
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
Arithmetic and comparison operators are the main exception: they use
fixed method names on the concrete type (`add`, `sub`, `mul`, `div`,
`matmul`, `eq`, `lt`, and so on). The prelude traits `Add`, `Sub`,
`Mul`, `Div`, `MatMul`, `Neg`, `Eq`, and `Ord` remain available for
explicit bounds and documentation, but an unbounded generic does not
need to name them.

| Trait | Unlocks | Syntax |
|-------|---------|--------|
| `Iter[T]` | `for` loops | `for x in expr:` |
| `Contains[T]` | Membership test | `x in collection`, `x not in collection` |
| `Scoped[T]` | `with` blocks (guarded) | `with expr as name:` |
| `ScopedMut[T]` | `with` blocks (guarded, mutable) | `with expr as mut name:` |
| `Index[I, O]` | Subscript read | `expr[index]` |
| `IndexMut[I, O]` | Subscript write | `expr[index] = val` |
| `MultiIndex[O]` | Generalized subscript read | `expr[i, j]`, `expr[1:4, :, ...]` |
| `MultiIndexMut[V]` | Generalized subscript write | `expr[i, j] = val`, `expr[:, 0] = val` |
| `Try[T, E]` | `?` operator | `expr?` |
| `Drop` | Destructor | automatic at scope exit |

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
type ParseResult[T] = ParseOk(T, remaining: str)
                    | ParseErr(msg: str, pos: usize)

impl Try[T, ParseError] for ParseResult[T]:
    fn branch(self: Self) -> ControlFlow[ParseError, T]:
        match self:
            ParseOk(v, _) => ControlFlow.Continue(v)
            ParseErr(m, p) => ControlFlow.Break(ParseError { msg: m, pos: p })

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

Arithmetic and comparison operators use fixed method names on the
concrete type:

| Operator | Method |
|----------|--------|
| `+` | `add` |
| `-` | `sub` |
| `*` | `mul` |
| `/` | `div` |
| `@` | `matmul` |
| unary `-` | `neg` |
| `==` | `eq` |
| `!=` | `ne` |
| `<` | `lt` |
| `<=` | `le` |
| `>` | `gt` |
| `>=` | `ge` |

The prelude also defines optional traits with matching names and
signatures for explicit bounds and documentation:

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
type Point { x: f64, y: f64 }

@[derive(Eq, Debug)]
enum Role { Admin | Member | Guest }
```

**`@[derive(all)]`** derives every structural trait the type
qualifies for:

```
@[derive(all)]
type Color { r: u8, g: u8, b: u8, a: u8 }
// Derives: Copy, Clone, Default, Eq, Hash, Ord, Debug
// (all fields are u8, which implements all of these)

@[derive(all)]
type User { name: str, email: str, age: i32 }
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

Debug formatting is generated inline by the compiler at compile time
— each struct field is extracted and formatted without trait dispatch
or runtime reflection. For primitives, `:?` produces the same output
as default display, except strings are quoted (`"hello"` instead of
`hello`).

A `Debug` trait exists in the standard library for manual
implementations, but the `:?` f-string specifier does not dispatch
through it. The compiler generates the formatting directly.

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
let f = x => x + 1           // bound to a named variable: escaping
let closures = vec![x => x]  // stored in a container: escaping
return x => x + 1            // returned from function: escaping
some_struct.callback = x => x // stored in a field: escaping
```

The following are **non-escaping**:

```
items.for_each(x => print(x))      // direct argument: non-escaping
items |> filter(x => x > 0)          // direct argument: non-escaping
with lock.read() as data:           // with block body: non-escaping
    data.iter() |> map(x => x + 1)   // direct argument: non-escaping
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
    text.split(pat) |> map(s => s.to_string()) |> collect()

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
    |> filter(s => s.len() > 0)
    |> map(s => s.to_string())
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
    print(x)           // x: &i32, unambiguous

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
let total = numbers.iter() |> fold(0, (acc, x) => acc + x)

let words = lines.iter()
    |> flat_map(line => line.split(' '))
    |> collect[Vec[String]]()

let (adults, minors) = people.iter()
    |> partition(p => p.age >= 18)

// zip_with: combine two iterators with a function
let distances = xs.iter()
    |> zip_with(ys.iter(), (x, y) => (x - y).abs())
    |> collect[Vec]()

// unfold: generate sequence from state
let powers_of_2 = Iter.unfold(1, n => Some((n, n * 2)))
    |> take(10) |> collect[Vec]()
// [1, 2, 4, 8, 16, 32, 64, 128, 256, 512]

let report = transactions.iter()
    |> filter(t => t.amount > 100.0)
    |> sorted_by((a, b) => b.date.cmp(a.date))
    |> take(10)
    |> map(t => "{t.date}: ${t.amount}")
    |> join("\n")
```

**HashMap convenience methods:**

Beyond the standard iterator operations, `HashMap` provides
ergonomic mutation methods:

```
// Entry API (Rust-style)
worker_counts.entry(id).or_insert(0)

// Convenience: update with default and transform
worker_counts.update(id, 0, n => n + 1)
// equivalent to: entry(id).or_insert(0); *entry += 1

// Convenience: increment/decrement
worker_counts.increment(id)       // .update(id, 0, n => n + 1)
worker_counts.decrement(id)       // .update(id, 0, n => n - 1)

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
    print(r)
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
    print(f"{i}: {item}")
```

The binding position is a full pattern, not just an identifier:

```
for (key, value) in map:
    println(f"{key} = {value}")

for { name, age, .. } in users:
    print(f"{name}: {age}")

for Some(item) in optional_items:
    process(item)
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

`for pattern in expr: body` desugars to calling `next()` in a loop.
The implicit `.iter()` insertion means `for x in collection:`
borrows the collection immutably — the collection remains valid
after the loop.

Pattern matching uses the same pattern language as `let` and `match`.
Irrefutable patterns bind every element. Refutable patterns are
allowed; elements that do not match are skipped and iteration
continues. Reference-pattern ergonomics (§9.7) apply here too, so
patterns over `.iter()` output usually bind references without
explicit `&`.

### 13.5a Labels, Labeled Break, and Continue

Labels provide named control-flow targets within a function. A label
declaration is an identifier prefixed with a single quote:

```
'outer
'search
'L0
```

A label appears as the first token of a statement. It may precede any
statement: a block, a loop, a `let` or `var` binding, a `return`, an
expression statement, or another label. The label and the statement
it precedes are syntactically a single statement; the label does not
declare a new scope. A label may appear alone on a line and label the
next statement:

```
'top
if done:
    goto 'finish

'outer for row in grid:
    ...

'parse:
    ...

'finish return
```

A label has no trailing colon of its own. Labeled `while` and `for`
loops may use either colon-form or brace-form bodies; the body
introducer is the same `:` or `{ }` the loop would use without a
label. A labeled block uses a body directly after the label: `:` for
colon form or `{` for brace form.

Every label name must be unique within its function. The label
namespace is shared by `goto`, `break`, and `continue`, but is
separate from ordinary identifiers, types, and keywords. A variable
named `outer` and a label named `'outer` do not collide.

Labels are function-local control-flow targets. They are not visible
inside a nested `fn`, closure, `async:` block, or `gen fn` body.
`with` blocks are transparent for label scoping: a label declared
outside a `with` block remains visible inside the `with` body.

```
'outer for item in items:
    with item.acquire() as guard:
        if guard.is_done():
            break 'outer       // valid: with is label-transparent
```

The existing unlabeled forms are unchanged:

```
break       // exits the innermost enclosing loop
continue    // continues the innermost enclosing loop
```

`break` and `continue` also accept an optional label operand:

```
break 'outer       // exits the loop or block labeled 'outer
continue 'outer    // continues the loop labeled 'outer
```

Labeled `break` and `continue` are statements and have no value.
`break 'label value` is reserved for a future value-carrying
labeled-block design and is invalid in this version.

`break 'label` transfers control to the statement immediately after
the construct labeled `'label`. The target label must be declared on
a labeled `while`, labeled `for`, or labeled block that lexically
encloses the `break`.

`continue 'label` transfers control to the next iteration of the
loop labeled `'label`. For a `while` loop, this means the condition
check. For a `for` loop, this means the iterator-advance or
next-element step. The target label must be declared on a labeled
`while` or `for` that lexically encloses the `continue`.

Labels on other statement forms are valid `goto` targets (§13.5b),
but they are not valid targets for `break` or `continue`.

Labeled blocks are statement-position only. They are not expressions,
and they do not produce a value. This is valid:

```
fn parse_header(input: bytes) -> Result[Header, Error]:
    'parse:
        if input.len() < 4: break 'parse
        let magic = input[0..4]
        if magic != EXPECTED_MAGIC: break 'parse
        return Ok(read_header(input))
    Err("malformed header")
```

This is not valid:

```
let result = 'parse:          // ERROR: labeled block is not an expression
    ...
```

A label token that is not the first token of a statement is a syntax
error:

```
if cond: 'outer while true:    // ERROR: label must start a statement
    tick()
```

A labeled `break` or `continue` exits every intervening scope between
the statement and the target. Cleanup is the same as for ordinary
structured control flow, repeated across each exited scope in reverse
entry order:

- `defer` blocks run.
- `Drop` destructors for owned values run.
- `with` guards are released.

`errdefer` blocks do not run for labeled `break` or `continue`,
because these are normal control transfers, not error returns.

The compiler must diagnose at least these errors:

- Duplicate label name in the same function.
- Undefined label.
- `break` targeting a label that is not on an enclosing loop or block.
- `continue` targeting a label that is not on an enclosing loop.
- Label token not at the start of a statement.
- Label use across a nested function, closure, `async:`, or `gen fn`
  boundary.

A label that is not targeted by `goto`, `break`, or `continue`
produces an `unused-label` warning. Labels exist to name control-flow
targets; code that wants to name a construct purely for readability
should use a comment.

### 13.5b Goto Statement

`goto` transfers control unconditionally to a labeled statement
within the same function:

```
goto 'label
```

Conditional gotos are written by composition with `if`:

```
if cond: goto 'label
```

Example:

```
fn example:
    var i = 0
    'top
    if i >= 10:
        goto 'done
    process(i)
    i = i + 1
    goto 'top
    'done
    print("finished")
```

The compiler rejects any `goto` that violates these static
restrictions:

**Function-local.** The target label must be declared in the same
function as the `goto` statement. `goto` cannot cross function,
closure, `async:`, or `gen fn` boundaries.

**No entry into a block from outside.** The target label's enclosing
scope chain must be a prefix of the goto site's enclosing scope
chain. Equivalently, a `goto` may exit scopes, but it may not enter a
scope that is not already active at the goto site.

This forbids jumping from outside a loop into the loop body, jumping
from one branch of an `if` into the other branch, and jumping from
outside a `match` into one of its arms.

**No skipping of variable initialization.** A `goto` must not jump
over a binding declaration when that binding would be in scope at the
target. Otherwise the target scope could observe, drop, or assign over
a value that was never initialized.

When a `goto` exits one or more scopes, cleanup is identical to
falling out of those scopes normally or to an equivalent labeled
`break`:

- `defer` blocks run.
- `Drop` destructors for owned values run.
- `with` guards are released.

`errdefer` blocks do not run for `goto`, because `goto` is a normal
control transfer, not an error return.

A backward `goto` to a point before a local binding's declaration ends
that binding's current lifetime before the jump. Its cleanup runs
before control transfers, and the binding is initialized again if
execution later reaches its declaration.

The compiler must diagnose at least these errors:

- Undefined target label.
- Target label declared outside the current function.
- `goto` across a nested function, closure, `async:`, or `gen fn`
  boundary.
- `goto` that would enter a block from outside.
- `goto` that would skip variable initialization.

`with migrate` may emit `goto` when C source contains control flow
that cannot be expressed with structured constructs, such as an
irreducible control-flow graph. For reducible C, the migrator should
prefer structured With using `while`, `if`, labeled `break`, and
labeled `continue`. For irreducible C, each basic block may become a
labeled statement at function scope, and each control-flow edge may
become a `goto` or conditional `goto`.

Computed goto (`goto *ptr`) and non-local jumps such as
`setjmp`/`longjmp` are not supported. If `with migrate` encounters a
function that requires one of those patterns, it must emit a
diagnostic naming the function and source location, produce no
misleading placeholder translation, and exit non-zero.

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
iter |> filter(x => cond) |> map(x => expr) |> collect[Vec]()
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

### 13.6a Option and Result For-Comprehensions

`for` can also express short-circuiting chains over `Option` and
`Result`. Clauses are separated by `;`. Each binding clause unwraps
one successful value and binds it for the following clauses.

```
let name: Option[str] =
    for user in get_user(id);
        profile in get_profile(user):
    yield profile.display_name

let data: Result[Response, Error] =
    for conn in connect(host);
        auth in conn.authenticate(token);
        resp in auth.fetch(path):
    yield resp
```

The first clause determines the carrier family:

- `Option[T]` comprehensions unwrap `Some(...)` and short-circuit on
  `None`.
- `Result[T, E]` comprehensions unwrap `Ok(...)` and short-circuit on
  `Err(...)`.

The expression form ends with `yield expr`, which re-wraps the final
value in `Some(...)` or `Ok(...)`. The statement form omits `yield`
and runs its body only when every clause succeeds:

```
for user in get_user(id); profile in get_profile(user):
    update_profile(profile)
```

This is equivalent to nested `match` expressions over the relevant
success and failure constructors.

Option comprehensions also support boolean guard clauses:

```
let active_name =
    for user in get_user(id);
        if user.is_active();
        profile in get_profile(user):
    yield profile.name
```

If the guard is false, the comprehension produces `None`. `Result`
comprehensions do not have an implicit guard-failure error value; use
an explicit `if`/`match` inside the comprehension body when guard
failure must choose an `Err`.

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

This is **restricted coloring**. Callers are not generally restricted
by callee color: any function can call an async function and receive a
`Task[T]`. However, specific safety contexts enforce constraints based
on callee color:

1. **`@[no_await_guard]` enforcement:** Calling any `may_suspend`
   function while a `@[no_await_guard]` guard is live is a compile
   error — even if the `.await` is buried three calls deep.
2. **FFI callback safety:** Functions passed as `extern "C"`
   callbacks must not be `may_suspend` (see §14.19).

Programmers do not declare or annotate `may_suspend`. The compiler
computes it internally; it may appear in diagnostics when a safety
violation occurs. There are no separate `async` and `sync` function
types, no trait split, and no closure type changes.

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
    |> filter(u => u.active)
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
async scope s =>
    s.track(async:
        for i in 0..5:
            sleep(50.millis()).await
            tx.send("msg-{i}").await
    )
    s.track(async:
        for msg in rx:
            print(msg)
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
   async scope s =>
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
   match task.await:
       Ok(value) => use(value)
       Err(e) if e.is_cancelled() => log("task was cancelled")
       Err(e) => return Err(e)
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
async scope s =>
    body
```

desugars to:

```
runtime::structured_scope(s => { body })
```

The scope object `s` provides:

| Method | Signature | Description |
|--------|-----------|-------------|
| `track` | `(Task[T]) -> ScopedTask[T]` | Register an existing task with this scope |

**Why `track`, not `spawn`:** In With, calling an `async fn` eagerly
allocates a fiber and returns a `Task[T]` (§14.4). If a scope took
a closure like `s.spawn(() => async_fn())`, the closure would run on
one fiber and `async_fn()` would spawn a second — creating a
detached task that escapes structured concurrency. Instead,
`s.track()` accepts the `Task[T]` directly:

```
async scope s =>
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
async scope s =>
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
    async scope s =>
        let tasks = ids.iter()
            |> map(id => s.track(fetch_user(id)))
            |> collect[Vec]()
        tasks |> map(t => t.await) |> collect()
    // all tracked tasks guaranteed complete here
```

For CPU-bound parallelism on OS threads (no fiber runtime required):

```
scope s =>
    s.spawn(() => compute_chunk_a())
    s.spawn(() => compute_chunk_b())
// both complete here
```

The non-async `scope` uses `s.spawn(() => closure)` because OS-thread
work items are sync closures — no eager fiber spawning occurs.
`scope` is available in `no_runtime` builds.

### 14.10 Select Await

`select await` races multiple async expressions and executes the
branch of the first to complete. Remaining expressions are cancelled.

```
select await
    msg = rx_fast.recv() => print(f"fast: {msg}")
    msg = rx_slow.recv() => print(f"slow: {msg}")
    _ = timeout(1.secs()) => print("timeout")
```

Each branch has the form `pattern = async_expr => body`. The runtime
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
        msg = inbox.recv() =>
            process(msg)?
        _ = shutdown.recv() =>
            break
        _ = timeout(idle_timeout) =>
            send_heartbeat().await?

// Select with error propagation
select await
    data = stream.next() => process(data?)?
    _ = cancel.cancelled() => return Err(.Cancelled)
```

**Fair selection (default):** If multiple expressions complete
simultaneously, the runtime selects a **ready branch at random**
(pseudo-random, not cryptographic). This prevents starvation: a
high-throughput data channel cannot indefinitely starve a shutdown
signal or heartbeat timer.

```
loop:
    select await
        data = fast_stream.recv() => handle(data)
        _ = shutdown.recv() => break    // will eventually fire
```

**Biased selection:** For cases where deterministic priority is
needed, use `select await biased`. This selects the first textual
branch that is ready (top-to-bottom priority):

```
select await biased
    urgent = priority_rx.recv() => handle_urgent(urgent)
    normal = normal_rx.recv() => handle_normal(normal)
    _ = timeout(1.secs()) => send_heartbeat().await
```

Use `biased` when you need guaranteed priority ordering and
understand the starvation risk.

**Handling `Option`/`Result` in branches:** Use `let ... else`
inside the branch body to destructure the completed value. This
reuses existing syntax and keeps the grammar simple:

```
loop:
    select await
        opt_msg = rx.recv() =>
            let Some(msg) = opt_msg else break
            process(msg)
        result = listener.accept() =>
            let Ok(conn) = result else continue
            handle(conn)
        _ = timeout(idle_timeout) =>
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
async scope s =>
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

*For design rationale on fibers vs state machines, see
`docs/design-rationale.md`.*

### 14.13 Interaction with Ownership

Because fibers have real stacks, references across `await` are safe:

```
async fn process(data: &mut Vec[i32]):
    let first = &data[0]
    some_io().await              // fiber suspends; reference still valid
    print(first)               // safe to use
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
    |> map(url => fetch(url).await)
    |> filter(r => r.is_ok())
    |> collect[Vec]()

// .await inside fold
let total = ids.iter()
    |> fold(0, (sum, id) => sum + get_count(id).await)
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
scope s =>
    s.spawn(() => compute_chunk_a())
    s.spawn(() => compute_chunk_b())
// both complete here
```

### 14.15 Channels

```
let (tx, rx) = chan[Message](buffer: 10)

tx.send(msg).await          // suspends fiber if full
let msg = rx.recv().await   // suspends fiber if empty

// Non-blocking:
match rx.try_recv():
    Some(msg) => handle(msg)
    None      => ()
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
async scope s =>
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
thread.spawn_os(() => use_ref(&local))   // ERROR: &local is not Send

// scope requires ScopedSend — ephemerals allowed
scope s =>
    s.spawn(() => use_ref(&local))       // OK: ScopedSend, joins before scope exits

// async scope requires ScopedSend — ephemerals allowed
async scope s =>
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

#### 14.17.1 Atomic[T]

`Atomic[T]` provides lock-free atomic operations on integer and
pointer types. `T` must be an integer type (`i32`, `i64`, `u32`,
`u64`, etc.) or a pointer type.

```
use std.collections

var counter: Atomic[i32] = Atomic { val: 0 }

counter.store(42, .Release)
let val = counter.load(.Acquire)

let old = counter.fetch_add(1, .SeqCst)
```

**Memory orderings:**

```
.Relaxed       // no ordering guarantees (fastest)
.Acquire       // reads after this see writes before a paired release
.Release       // writes before this are visible after a paired acquire
.AcqRel        // both acquire and release
.SeqCst        // total order across all threads (strongest, default)
```

**Operations:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `Atomic.new(val)` | `fn(T) -> Atomic[T]` | Create with initial value |
| `.load(order)` | `fn(Order) -> T` | Atomic read |
| `.store(val, order)` | `fn(T, Order) -> void` | Atomic write |
| `.swap(val, order)` | `fn(T, Order) -> T` | Exchange, return old |
| `.fetch_add(val, order)` | `fn(T, Order) -> T` | Add, return old |
| `.fetch_sub(val, order)` | `fn(T, Order) -> T` | Subtract, return old |
| `.fetch_and(val, order)` | `fn(T, Order) -> T` | Bitwise AND, return old |
| `.fetch_or(val, order)` | `fn(T, Order) -> T` | Bitwise OR, return old |
| `.fetch_xor(val, order)` | `fn(T, Order) -> T` | Bitwise XOR, return old |
| `.fetch_min(val, order)` | `fn(T, Order) -> T` | Min, return old |
| `.fetch_max(val, order)` | `fn(T, Order) -> T` | Max, return old |
| `.compare_exchange(expected, desired, success, failure)` | `fn(T, T, Order, Order) -> Result[T, T]` | CAS, strong |
| `.compare_exchange_weak(expected, desired, success, failure)` | `fn(T, T, Order, Order) -> Result[T, T]` | CAS, weak |

`compare_exchange` returns `Ok(old_value)` on success or
`Err(actual_value)` on failure.

**Atomic fences:**

```
use std.sync.fence

fence(.Acquire)
fence(.Release)
fence(.SeqCst)
```

**Ordering constraints (compile-time validated):**

- `.store` cannot use `.Acquire` or `.AcqRel`
- `.load` cannot use `.Release` or `.AcqRel`
- `compare_exchange` failure ordering cannot be stronger than
  success ordering, and cannot be `.Release` or `.AcqRel`

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
unsafe { c_sort(items.ptr, items.len, (a, b) =>
    fetch_weight(a).await <=> fetch_weight(b).await
    //              ^^^^^^ ERROR: may_suspend in extern "C" callback
) }

// OK: no suspension in callback
unsafe { c_sort(items.ptr, items.len, (a, b) =>
    a.weight <=> b.weight
) }

// OK: spawn a detached task (no .await needed)
unsafe { c_on_event(event =>
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
    print("Listening on :8080")

    loop:
        let conn = listener.accept().await
        spawn handle_connection(conn)

async fn handle_connection(conn: TcpStream):
    let req = http.parse_request(&conn).await

    let response = match req.path_str():
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
    async scope s =>
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
type User { name: str, email: str }    // owned strings in structs
fn greet(name: &str): print(f"Hello, {name}")  // borrowed for reading
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
fn greet(name: &str): print(f"hello {name}")
greet("world")                               // OK: str auto-borrows to &str

// Explicit &str for zero-cost static reference:
let view: &str = "hello"                     // no allocation, static memory
```

**How it works:** A bare string literal produces an owned `str`.
The compiler may elide the allocation when it can prove the string
is never mutated, never stored in a heap structure, and never
escapes the current scope — but this is an optimization, not a
source-level guarantee. Performance-sensitive code should not rely
on the optimizer proving allocation unnecessary. Use an explicit
`&str` annotation or pass to an `&str` parameter for guaranteed
zero-cost static storage.

When the type context is `&str` (function parameter, explicit
annotation), the literal is a zero-cost static reference with no
allocation. This guarantee is unconditional — it does not depend
on optimizer analysis.

```
let s = "hello"        // s: str (owned — the default)
let s: &str = "hello"  // s: &str (static reference, no allocation)
```

**F-string literals** (`f"user {id}"`) always produce `str`
(owned) because they must allocate to build the result. Plain
string literals (`"hello"`) do not support interpolation.

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

### 15.4 Formatted String Interpolation (F-Strings)

F-strings are the sole formatting mechanism in With. There is no
`printf`, no `format()` function, no format-string varargs. `print`
takes `str`. `f"..."` returns `str`. One way to format.

```
let s = f"elapsed: {secs:.3}s"
print(s)
print(f"count: {n}, flag: {flag}")
```

An f-string is a string literal prefixed with `f` containing
interpolation holes delimited by `{}`. Each hole contains an
expression and an optional format specification separated by `:`.
An f-string evaluates to `str`.

```
f"literal {expr} literal {expr:spec} literal"
```

The expression may be any With expression: variable, field access,
method call, arithmetic, index, function call. The format spec
controls how the value is rendered as text.

Literal `{` and `}` characters are written as `{{` and `}}`:

```
f"set = {{{val}}}"    // "set = {42}"
```

Plain string literals (`"hello"`) do not support interpolation.
F-strings may not be nested.

**Semantics:**

- Each `{expr}` is type-checked at compile time.
- Non-`str` expressions are converted to `str` via built-in
  formatting functions (no trait dispatch).
- The `++` operator is `str`-only. Non-`str` operands are a
  compile-time error. Use f-strings to format values into strings.
- F-strings always produce owned `str` (they allocate).

#### 15.4.1 Format Specification Grammar

```
spec := [[fill]align][sign]['#']['0'][width]['.' precision][mode]
```

All fields are optional. Omitting the entire spec (`{expr}` with
no colon) uses the type's default display.

| Field | Syntax | Description |
|-------|--------|-------------|
| fill | any single byte except `{` `}` | Padding character (default: space) |
| align | `<` left, `>` right, `^` center | Alignment within width |
| sign | `+` always show sign, `-` negative only (default) | Sign display for numbers |
| `#` | literal `#` | Alternate form: `0x`/`0b`/`0o` prefix |
| `0` | literal `0` | Zero-pad shorthand (equivalent to `0>` fill+align) |
| width | positive integer | Minimum field width |
| precision | `.` followed by non-negative integer | Decimal places (floats) or max chars (strings) |
| mode | single letter | Rendering mode (see below) |

The fill character is only recognized when followed immediately by
an align character (`<`, `>`, `^`). Otherwise the character is
parsed as a later field. This matches Python's rule.

#### 15.4.2 Modes

| Mode | Valid types | Meaning | Example |
|------|------------|---------|---------|
| `d` | integers | Decimal (default for integers) | `42` |
| `x` | integers | Lowercase hexadecimal | `2a` |
| `X` | integers | Uppercase hexadecimal | `2A` |
| `b` | integers | Binary | `101010` |
| `o` | integers | Octal | `52` |
| `f` | floats | Fixed-point | `3.140000` |
| `e` | floats | Scientific notation | `3.14e+00` |
| `g` | floats | General: shortest of fixed/scientific (default) | `3.14` |
| `s` | strings | String (default for strings) | `hello` |
| `?` | any type | Debug representation | `Point { x: 1, y: 2 }` |

#### 15.4.3 Integer Formatting

Default (no spec): decimal with no padding.

```
f"{42}"          // "42"
f"{-7}"          // "-7"
```

Hex, binary, octal:

```
f"{255:x}"       // "ff"
f"{255:X}"       // "FF"
f"{255:#x}"      // "0xff"
f"{7:b}"         // "111"
f"{7:#b}"        // "0b111"
f"{63:o}"        // "77"
```

Width and zero-padding:

```
f"{42:8}"        // "      42"  (right-aligned by default)
f"{42:08}"       // "00000042"  (zero-pad)
f"{42:<8}"       // "42      "  (left-aligned)
f"{42:^8}"       // "   42   "  (centered)
f"{42:_>8}"      // "______42"  (custom fill)
```

Sign:

```
f"{42:+}"        // "+42"
f"{-42:+}"       // "-42"
```

Precision on integers is a compile-time error.

#### 15.4.4 Float Formatting

Default (no spec): general format. When precision is specified
without a mode letter, the mode defaults to `f` (fixed-point).

```
f"{3.14}"          // "3.14"
f"{3.14159:.2}"    // "3.14"       (precision → fixed-point)
f"{3.14159:.2f}"   // "3.14"       (explicit fixed)
f"{3.14159:.2e}"   // "3.14e+00"   (scientific)
f"{3.14:+.2}"      // "+3.14"
```

Integer modes on floats are compile-time errors.

#### 15.4.5 String Formatting

Default (no spec): the string itself, unmodified.

```
f"{'hello'}"           // "hello"
f"{'hi':>10}"          // "        hi"  (right-align)
f"{'hi':<10}"          // "hi        "  (left-align, default)
f"{'hello world':.5}"  // "hello"       (truncation)
```

Numeric modes on strings are compile-time errors.

#### 15.4.6 Boolean Formatting

Default: `true` or `false`. Only `?` mode and width/alignment
are valid. All other modes are compile-time errors.

#### 15.4.7 Debug Mode `:?`

Available for all types. Prints a structural representation:

| Type | Debug output |
|------|-------------|
| integer | Same as default: `42` |
| float | Same as default: `3.14` |
| str | Quoted: `"hello"` |
| bool | `true` / `false` |
| struct | `TypeName { field: value, field: value }` |

```
f"{42:?}"        // "42"
f"{'hi':?}"      // "\"hi\""
f"{point:?}"     // "Point { x: 1, y: 2 }"
```

Debug mode for structs generates inline formatting code at compile
time — each field is extracted and formatted. No runtime reflection
or trait dispatch is used.

#### 15.4.8 Compile-Time Validation

All invalid type/mode combinations produce clear compile-time
errors:

| | `d` | `x/X/b/o` | `f/e/g` | `s` | `?` |
|---|---|---|---|---|---|
| **integer** | ✓ | ✓ | error | error | ✓ |
| **float** | error | error | ✓ | error | ✓ |
| **str** | error | error | error | ✓ | ✓ |
| **bool** | error | error | error | error | ✓ |
| **struct** | error | error | error | error | ✓ |

Using `{some_struct}` without `:?` is a compile-time error:

```
f"{player}"      // error: struct type Player has no default
                 //   display; use :? for debug
```

#### 15.4.9 String Concatenation (`++`)

The `++` operator concatenates two `str` values. Both operands
must be `str` — non-`str` operands are a compile-time error.

```
let greeting = "hello" ++ " " ++ "world"  // "hello world"
let msg = f"count: {n}" ++ "!"            // f-string ++ str
```

To include non-string values in a string, use f-strings:

```
// Correct:
let s = f"value: {x}"

// Error:
let s = "value: " ++ x    // error if x is not str
```

### 15.7 Output Functions

Four output functions. `print` and `eprint` append a newline.
`write` and `ewrite` do not.

| Function | Target | Newline |
|----------|--------|---------|
| `print(s)` | stdout | Always |
| `eprint(s)` | stderr | Always |
| `write(s)` | stdout | Never |
| `ewrite(s)` | stderr | Never |

```
print("hello")               // stdout: hello\n
print(f"count: {n}")         // stdout: count: 42\n
eprint("warning: not found") // stderr: warning: not found\n
write("loading...")           // stdout: loading... (no newline)
write(f"\r{pct}%")           // overwrite current line
ewrite("progress: ")          // stderr, no newline
```

All four take a single `str` argument. Formatting is done via
f-strings, not via the output function itself. There are no format
arguments, no varargs, no separator or end parameters.

```
let name = "alice"
let score = 42
print(f"{name}: {score}")    // alice: 42\n

// Multiple values: use f-strings, not multiple arguments
print(f"{x} {y} {z}")       // not print(x, y, z)
```

**`println` and `eprintln` do not exist.** `print` and `eprint`
always append a newline. Use `write` when raw output without a
newline is needed.

**Design rationale:**
- The overwhelmingly common case is line-terminated output
- Forgetting a newline produces garbled terminal output; forgetting
  to suppress one is harmless
- The `ln` suffix is visual noise on nearly every print call
- F-strings handle all formatting — no need for `sep`/`end` parameters
- `write`/`ewrite` are the explicit opt-in for no-newline output
  (progress bars, prompts, terminal control)

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
    .map(p => CStr.from_ptr(p).to_str())
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
// User must write: fn max[T](a: T, b: T) -> T: if a > b then a else b
```

Complex macros (token pasting, stringification, variadic macros,
statement-expression macros) are never translated. The compiler
emits a warning listing all untranslated macros. Users wrap these
in a thin C shim file or write manual `extern "C"` bindings.

**Function-like macro translation:** Simple expression macros are
translated to generic functions:

```c
#define MAX(a, b) ((a) > (b) ? (a) : (b))
// → fn MAX[T](a: T, b: T) -> T: if a > b: a else: b

#define ABS(x) ((x) < 0 ? -(x) : (x))
// → fn ABS[T](a: T) -> T: if a < 0: 0 - a else: a
```

Macros with bodies that cannot be pattern-matched to With expressions
emit a stub with `comptime_error`:

```
fn COMPLEX_MACRO():
    comptime_error("c_import: macro COMPLEX_MACRO not translatable")
```

**Constant expression evaluation:** `#define` macros with arithmetic
expressions, bitwise operations, casts, and references to other macros
are evaluated via the C compiler's constant evaluator:

```c
#define PAGE_SIZE 4096
#define PAGE_MASK (~(PAGE_SIZE - 1))     // → const PAGE_MASK: i32 = -4096
#define FLAGS (FLAG_A | FLAG_B | 0x10)   // → const FLAGS: i32 = evaluated_value
```

**Collision mangling:** When `c_import` encounters duplicate names
from transitive includes, numeric suffixes are appended: `name_2`,
`name_3`, etc.

### 16.2a Auto-Method Generation

When `c_import` translates a C header, the compiler detects naming
patterns like `structname_method(self, ...)` and auto-generates
method syntax so C APIs feel like native With APIs. This is sugar —
`table.insert("key", "val")` compiles to exactly
`g_hash_table_insert(table, "key", "val")`. Zero runtime cost.

```
// Raw c_import calls:
let table = g_hash_table_new(g_str_hash, g_str_equal)
g_hash_table_insert(table, "name", "Eric")
g_hash_table_destroy(table)

// With auto-methods:
let table = GHashTable()
table.insert("name", "Eric")
// table.destroy() called automatically at scope exit
```

**Detection rules.** For each struct `S` from `c_import`, the
compiler converts the name to snake_case (`GHashTable` →
`g_hash_table_`) and checks if imported functions start with that
prefix. A function is a **method candidate** if its first parameter
is `*S`, `*mut S`, `*const S`, or `S`. A function is a
**constructor candidate** if it returns `*S` / `*mut S` without
taking self. The method name is the function name with the prefix
stripped:

```
g_hash_table_new       → GHashTable.new(...)      // constructor
g_hash_table_insert    → .insert(...)              // method
g_hash_table_lookup    → .lookup(...)              // method
g_hash_table_destroy   → .destroy()                // destructor
```

**Constructor syntax.** If a type has a `.new` method, the type
name itself becomes callable: `GHashTable(args)` is sugar for
`GHashTable.new(args)`.

**Destructor detection and auto-defer.** Functions matching
`prefix_destroy`, `prefix_free`, `prefix_close`, `prefix_unref`,
or `prefix_release` are tagged as destructors. When a constructor
result is bound to a non-escaping `let`, the compiler inserts
`defer obj.destructor()` automatically. Auto-defer does NOT apply
when the value is returned, stored in a collection, bound to `var`,
or passed to an ownership-transferring function.

**Opt-out.** Per-type: `use c_import("lib.h", no_methods: "Type")`.
Global: `use c_import("lib.h", no_methods: true)`. Flat C functions
are always available regardless.

**Ambiguity.** If multiple structs could claim the same function,
the longest prefix wins. If equal length, neither claims it.
User-written `impl` methods always take priority over auto-generated
ones.

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

### 16.3b External Variables

Global variables defined in C libraries can be declared with
`extern var` (mutable) or `extern let` (read-only):

```
extern var errno: i32
extern var stdin: *mut c_void
extern let sys_nerr: i32
```

**Semantics:**
- No initializer — the symbol is resolved at link time.
- `extern let` produces a compile error if assigned to.
- `extern var` is mutable — assignment stores to the global.
- The type must be concrete (no generics, no inference).
- Access does not require `unsafe` (the declaration is the opt-in).

`c_import` emits `extern var` for C globals with non-const types
and `extern let` for const-qualified globals.

**The `c_void` type:** C's `void*` maps to `*mut c_void` (or
`*const c_void`) in With. `c_void` is an opaque, zero-sized type
defined in `std.ffi` that cannot be instantiated — it exists only
to be pointed at. `void` is not a keyword or built-in type in With
(the unit type is `Unit`). `c_import` automatically translates C's
`void*` parameters to `*mut c_void`.

### 16.3c Auto-Coercion at `c_import` Boundaries

C APIs use `void*` as an opaque data type. glib, CoreFoundation,
Win32, POSIX — every major C library passes data through opaque
pointers. Requiring explicit casts on every call defeats With's
"C interop should feel native" promise.

The compiler auto-coerces at `c_import` function call boundaries
when the conversion is unambiguous. The user writes normal With
types. The compiler inserts the ABI translation.

```
// Without auto-coercion (explicit casts):
g_hash_table_insert(table, "name" as *mut c_void, "Eric" as *mut c_void)
let val = g_hash_table_lookup(table, "name" as *mut c_void) as *const u8

// With auto-coercion (compiler inserts conversions):
table.insert("name", "Eric")
let val: str = table.lookup("name")
```

**Parameter coercions (With → C).** When calling a function
imported via `c_import`, if an argument type doesn't match the
parameter type, the compiler attempts auto-coercion:

| Argument type   | Parameter type    | Coercion                                  |
|-----------------|-------------------|-------------------------------------------|
| `str`           | `*mut c_void`     | pointer to string data                    |
| `str`           | `*const c_void`   | pointer to string data                    |
| `str`           | `*const u8`       | pointer to string data                    |
| `str`           | `*const c_char`   | pointer to string data (null-terminated)  |
| `str`           | `*mut c_char`     | pointer to copy (caller must free — warn) |
| `i32`           | `c_int`           | identity (same repr)                      |
| `bool`          | `c_int`           | 1 or 0                                    |
| `*mut T`        | `*mut c_void`     | pointer cast                              |
| `*const T`      | `*const c_void`   | pointer cast                              |

These coercions ONLY apply at `c_import` function call sites.
They do not apply to user-defined functions, assignments, or
any other context.

**Return coercions (C → With).** When the return type of a
`c_import` function is `*mut c_void` or `*const c_void`, the
compiler coerces based on the receiving context:

| Return type     | Receiving context   | Coercion                       |
|-----------------|---------------------|--------------------------------|
| `*mut c_void`   | `let x: str = ...`   | null-check + strlen → str view |
| `*mut c_void`   | `let x: *mut T = ...`| pointer cast                   |
| `*const c_void` | `let x: str = ...`   | null-check + strlen → str view |
| `*const c_void` | `let x: *mut T = ...`| pointer cast                   |
| `*mut c_void`   | no annotation        | stays `*mut c_void` (no guess) |

Without a type annotation, no return coercion happens — the value
stays as the C return type.

**Null safety.** The `*mut c_void` → `str` coercion always inserts
a runtime null check. If the pointer is null, the result is `""`
(empty string, not a crash).

```
// Option form for explicit null handling:
let name: Option[str] = table.lookup("name")
// None if null, Some(str) if non-null
```

**What does NOT auto-coerce:**

- `str` → `*mut i32` (not a void pointer)
- `i32` → `*mut c_void` (integer to pointer — never implicit)
- `f64` → `c_int` (lossy — never implicit)
- `Vec[T]` → `*mut c_void` (complex type — never implicit)
- `str` → `*mut c_void` in non-`c_import` functions

The rule: coercions are only between types where the conversion is
unambiguous and lossless at the representation level.

### 16.4 Layout Control

```
@[repr(C)]
type Point { x: f64, y: f64 }
```

Types imported via `c_import` automatically have `repr(C)` layout.
Manually defined types intended for C interop must be explicitly
annotated.

**Packed layout:**

```
@[repr(packed)]
type PackedHeader {
    magic: u8,
    version: u16,
    size: u32,
}
```

`repr(packed)` implies `repr(C)` and sets alignment to 1 for all
fields (no padding). The compiler emits unaligned loads/stores.
Creating a reference to a packed field is a compile error (the
reference would be unaligned).

**Union types:**

```
@[repr(C)]
type Value = union {
    i: i32,
    f: f32,
    p: *mut c_void,
}

let v = Value { i: 42 }
let as_float = unsafe: v.f    // reinterpret bits as f32
```

Unions have the size of their largest field. All fields share offset 0.
Reading a field that wasn't last written requires `unsafe`. Writing any
field is safe. Construction requires exactly one field initializer.
`c_import` translates C union declarations directly.

**Custom alignment:**

Variables, struct fields, and function parameters can specify custom
alignment using the `align` attribute:

```
type CacheLine = {
    @[align(64)]
    data: [64]u8,
}

@[align(16)]
var buffer: [256]u8 = [0; 256]

fn process(@[align(16)] data: *[4]f32):
    // data is guaranteed 16-byte aligned
```

Rules:

1. Alignment must be a power of two.
2. Alignment must be at least the natural alignment of the type.
3. Alignment cannot exceed a platform-defined maximum (65536).
4. Violations are compile-time errors.

When a local variable has custom alignment, the compiler emits an
aligned stack allocation. When a struct has an aligned field, the
struct's own alignment becomes the maximum of all field alignments.

**Bitpacked layout** is described in §4.3b.

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
type Callback {
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

### 16.9 Opaque Types

```
type FILE = opaque
type DIR = opaque
```

Opaque types have unknown size and layout. They can only appear as
pointer targets (`*mut FILE`, `*const FILE`). Any attempt to create
a value, copy, `sizeof`, or access fields of an opaque type is a
compile error. `c_import` emits `type Name = opaque` for forward-
declared C structs (no body) and structs with bitfields.

### 16.10 Null Pointer Literal

```
let p: *mut i32 = null
if p == null:
    print("null pointer")
```

`null` is a typed null pointer constant. Its type is inferred from
context — it requires a pointer type annotation. Using `null` without
type context is a compile error. `null` is not the same as `0`.
Dereferencing `null` is undefined behavior (caught by `unsafe`).

### 16.11 Unsafe Context

```
fn use_ptr(p: *mut i32, end: *mut i32):
    let third = p + 2          // pointer arithmetic is safe
    let diff = end - p         // pointer difference is safe

    unsafe:
        let val = *third       // raw pointer dereference
        let val2 = p[2]        // raw pointer indexing
        p[0] = 42              // write through raw pointer
```

Certain operations in With can violate memory safety if misused.
These operations are permitted only within an `unsafe` context:
the body of an `unsafe fn` or the scope of an `unsafe:` block.

The operations that require an unsafe context are:

- Raw pointer dereference (`*p` for read or write)
- Raw pointer indexing (`p[i]` for read, `p[i] = v` for write)
- Calls to `extern` functions
- Other operations explicitly marked as unsafe in their definition

The following operations involving raw pointers are safe and do
not require an unsafe context:

- Raw pointer arithmetic (`p + n`, `p - n`, `p - q`)
- Raw pointer comparison (`p == q`, `p < q`, etc.)
- Taking the address of a value (`&x`, `&mut x`)
- Casting a pointer to an integer (`p as usize`)
- Casting an integer to a pointer (`n as *T`)

Raw pointer arithmetic uses element units:

- `ptr + n` advances by `n * sizeof(T)` bytes.
- `ptr - n` retreats by `n * sizeof(T)` bytes.
- `ptr1 - ptr2` returns the element count between pointers.
- Result preserves mutability: `*mut T + n` -> `*mut T`.

Computing a pointer value cannot by itself read invalid memory,
write invalid memory, or violate type invariants. The unsafe
requirement is placed at the access site, not at every intermediate
computation:

> `unsafe` is required when you are about to touch memory through
> a raw pointer, not when you are merely computing one.

Users may freely compute pointer addresses in safe code. The
resulting pointer value carries the same responsibility as any raw
pointer: it may only be used to access memory within an unsafe
context.

### 16.12 Intrinsics

**`sizeof` and `alignof`:**

```
let size = sizeof[i32]()      // 4
let align = alignof[f64]()    // 8
```

Built-in generic functions that return the size (in bytes) and
ABI alignment of a type at compile time. Required for allocator
implementations, C interop buffer sizing, and packed struct
calculations.

**`transmute`:**

```
let bits: u32 = unsafe: transmute[u32](3.14f32)
```

Reinterprets the bits of one type as another. Both types must have
the same size (compile error otherwise). Requires `unsafe` context.

### 16.13 Inline Assembly

The `asm` expression embeds target-specific assembly instructions.
It requires `unsafe` context.

```
let sp: u64 = unsafe:
    asm("mov %sp, {out}" : out("x0") -> u64)

unsafe:
    asm("dmb sy" ::: "memory")
```

**Full syntax:**

```
asm(template : outputs : inputs : clobbers)
```

Each section is optional. A trailing `:` section can be omitted.

**Template:** A string literal containing assembly instructions.
Register placeholders use `{name}` syntax, where `name` matches
an output or input binding.

**Outputs:** Comma-separated list of `name(constraint) -> type`.

```
asm("mrs {out}, CNTPCT_EL0" : out("x0") -> u64)
```

**Inputs:** Comma-separated list of `name(constraint) value`.

```
asm("add {out}, {a}, {b}"
    : out("x0") -> i32
    : a("x1") val_a, b("x2") val_b)
```

**Clobbers:** Comma-separated list of registers or `"memory"` /
`"cc"` that the assembly modifies but that are not outputs.

```
asm("syscall"
    : out("rax") -> i64
    : a("rax") syscall_num, b("rdi") arg1
    : "rcx", "r11", "memory")
```

**Volatile:** Marks the assembly as having side effects that the
optimizer must not eliminate:

```
asm volatile("wfe" :::)
```

Assembly is inherently non-portable. The `@[target("aarch64")]` or
`@[target("x86_64")]` attribute can guard architecture-specific
blocks.

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
print(__FILE__)    // prints "src/main.w"
print(__LINE__)    // prints the current line number
```

These are especially useful as default parameter values for assertion
and logging functions:

```
fn log(msg: str, file: str = __FILE__, line: u32 = __LINE__):
    print(f"[{file}:{line}] {msg}")

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
        print(f"field: {field.name}, size: {field.size}")
```

The `TypeInfo` module provides the same API for non-generic contexts:
`TypeInfo.fields[SomeType]()`, `TypeInfo.size[SomeType]()`, etc.
Inside comptime generic functions, `T.fields()` is preferred — it
reads like natural reflection.

`FieldInfo` contains:

```
type FieldInfo {
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
type User { name: String, age: i32, email: String }

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

**`comptime_error` semantics:**

`comptime_error(msg)` is an expression of type `never`. It does not
fire when parsed — it fires only when the containing code is actually
compiled (instantiated for a specific set of type arguments, or
called). A function whose body is only `comptime_error(...)` is legal
to declare and reference — the error fires on call.

```
fn legacy_api():
    comptime_error("legacy_api has been removed; use new_api instead")

// No error here — the function exists but is never called.
// Calling legacy_api() anywhere → immediate compile error.
```

`c_import` uses `comptime_error` for untranslatable C constructs:

```
fn __builtin_complex():
    comptime_error("c_import: __builtin_complex not translatable")
```

### 17.6 Real-World Examples

**ECS component registration:**

```
@[component]
type Transform { position: Vec3, rotation: Quat, scale: f32 }

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

### 17.6a Compiler Intrinsics

**`src()`** returns the source location of the call site as a string
in `"file:line:col"` format:

```
fn log(msg: str):
    print(src() ++ ": " ++ msg)

log("hello")    // prints "src/main.w:4:5: hello"
```

**`embed_file(path)`** reads a file at compile time and embeds its
contents as a string constant:

```
const HELP_TEXT: str = embed_file("help.txt")
const TEMPLATE: str = embed_file("templates/page.html")
```

The path is resolved relative to the source file. If the file does not
exist, a compile error is emitted. The file contents are embedded verbatim
as a string constant in the binary.

**Numeric builtins:**

```
a.min(b)            // smaller of two values
a.max(b)            // larger of two values
x.abs()             // absolute value
a.mul_add(b, c)     // fused multiply-add: a * b + c
```

**`min` and `max`** — Return the smaller or larger of two values.
Both operands must be the same type. Defined for all integer and
floating-point types. Return type matches the input type.

```
3.min(7)            // 3
3.max(7)            // 7
3.14.min(2.71)      // 2.71
```

For floats, `min` and `max` follow IEEE 754-2019 minimum/maximum
semantics: NaN is never selected unless both operands are NaN.

**`abs`** — Returns the absolute value. For signed integers, the
return type is the corresponding unsigned type to avoid `abs(INT_MIN)`
undefined behavior:

```
(-42).abs()         // 42     (i32 → u32)
42.abs()            // 42     (i32 → u32)
(-3.14).abs()       // 3.14   (f64 → f64)
```

For unsigned integers: identity function. For floats: return type is
the same float type (clears the sign bit per IEEE 754).

**`mul_add`** — Fused multiply-add. Computes `a * b + c` as a single
floating-point operation with one rounding step. Available for `f32`
and `f64` only. Critical for numerical algorithms where accumulated
rounding error matters.

```
let result = 3.0.mul_add(4.0, 5.0)    // 17.0
```

Maps to a single hardware instruction on all modern architectures
(via LLVM's `llvm.fma` intrinsic).

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
type checker uses **deferred branch checking**. The compiler validates
syntax and declared types up front, but operations that depend on the
concrete capabilities of `T` are checked when the generic is
instantiated. Code inside `comptime if` branches that depend on `T`
is likewise deferred until monomorphization. When `T` is known, the
`comptime if` condition is evaluated, the taken branch is type-
checked against the concrete `T`, and the erased branch is discarded
without checking.

This is intentionally close to C++ and Zig style instantiation-time
checking, but With keeps optional explicit bounds for APIs that want
the contract written at the signature.

```
fn process[T](val: &T):
    val.len()   // Checked when process[T] is instantiated
    comptime if T.implements(Serialize):
        val.serialize()   // Checked only in instantiations that take this branch
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
- `print`, `eprint`
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

| Module | Purpose | Replaces |
|--------|---------|----------|
| `std.io` | I/O primitives, Reader/Writer traits, buffered streams | `stdio.h` |
| `std.fs` | File system operations | `unistd.h`, `dirent.h`, `sys/stat.h` |
| `std.time` | Clocks, durations, sleep | `time.h`, `sys/time.h` |
| `std.math` | f32/f64 methods, constants | `math.h` |
| `std.collections` | Vec, HashMap, HashSet, BTreeMap, SlotMap, Handle | — |
| `std.string` | String/StrView types and methods | `string.h`, `ctype.h` |
| `std.net` | TCP, UDP, DNS | `sys/socket.h`, `netdb.h` |
| `std.thread` | OS-level threading | `pthread.h` |
| `std.sync` | Mutex, RwLock, Atomic, Condvar, Barrier, Once | `pthread.h`, `stdatomic.h` |
| `std.process` | Process control, args, env, Command | `stdlib.h`, `unistd.h` |
| `std.mem` | Low-level memory, Allocator trait, mmap | `stdlib.h`, `sys/mman.h` |
| `std.alloc` | Arena, Pool | — |
| `std.signal` | Signal handling | `signal.h` |
| `std.random` | Rng, seeded PRNG | `stdlib.h` |
| `std.hash` | Hasher trait, DefaultHasher | — |
| `std.fmt` | Debug trait, f-string internals | `stdio.h` (sprintf) |
| `std.testing` | assert, require, check, assert_eq, assert_matches, panic, todo, unreachable | — |

All collection types provide `.len()` returning `usize`, plus
convenience narrowing methods (`.len32()`, `.len64()`, `.ulen32()`)
that panic on overflow.

All collection types implement `Contains[T]` (§11.7), enabling the
`in` operator for membership tests. See §9.9.

For complete API specifications, see `docs/libstd-spec.md`.

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
| `print`, `eprint`, `write`, `ewrite` | Yes | Needs stdout/stderr |
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

### 18.7 Package Management

With has two dependency sources managed through the same CLI and
`with.toml`:

- **With packages** — `with get json`, `with get http`
- **C packages** — `with get c.glib`, `with get c.sqlite3`

The `c.` prefix routes through Conan Center (conan.io/center).
With packages come from the With package registry (future). Both
produce entries in `with.toml`:

```toml
[project]
name = "myapp"
version = "0.1.0"

[deps]
c.glib = "2.78"
c.sqlite3 = "3.45"
```

**`with get c.X`** resolves the package from Conan Center, downloads
headers, prebuilt libraries, and transitive deps into
`.with/deps/c/<name>/<version>/`, and updates `with.toml`. Each
package includes a `metadata.json` with include paths, library
paths, library names, and transitive dependencies.

**Build integration.** When `with build` encounters
`use c_import("<glib.h>")`, the compiler reads `with.toml`, finds
all `c.*` deps, reads their `metadata.json`, and constructs include
and link paths automatically. The user never writes `-I` or `-l`
flags. `c_import` headers are found by searching each dep's include
paths, and the matching package's libraries are linked automatically.

**Explicit override.** If auto-resolution picks the wrong library:

```
use c_import("<glib.h>", link: "glib-2.0", "gio-2.0")
```

**Manual C deps** work without Conan by specifying paths directly:

```toml
[deps.c.custom_lib]
include = "/opt/custom/include"
lib = "/opt/custom/lib"
link = ["custom"]
```

**CLI commands:**

| Command | Action |
|---------|--------|
| `with init` | Create new project with `with.toml` and `src/main.w` |
| `with get c.X` | Add C dependency via Conan |
| `with get c.X@2.78` | Pin specific version |
| `with remove c.X` | Remove dependency |
| `with update` | Update all deps to latest compatible |
| `with get` (no args) | Restore deps from lock file |

**Directory structure:**

```
.with/
├── deps/c/<name>/<version>/   # headers + libraries
├── cache/c_import/            # c_import translation cache
└── lock.json                  # exact version pins
```

`.with/` is gitignored. `with.toml` and `lock.json` are committed.

---

## 19. Safety Boundaries

### 19.1 Safe by Default

All code is safe unless explicitly `unsafe`.

### 19.2 `unsafe` Required For

- Raw pointer dereference
- Raw pointer indexing
- FFI function calls
- Inline assembly (`asm` expressions)
- Intrusive / self-referential structures
- Manual memory management beyond allocators
- Calling functions marked `unsafe`

### 19.2a `unsafe fn` — Function-Level Unsafe Context

Functions that pervasively perform unsafe memory accesses may be
declared `unsafe fn`:

```
unsafe fn sha256_compress(ctx: &mut Sha256):
    ctx.state[0] +%= a          // raw pointer indexing permitted
    let b = ctx.buf[off]        // auto-deref through pointer permitted
```

Inside an `unsafe fn` body, all operations that would normally
require `unsafe:` or `unsafe {}` are permitted without a wrapper.
The `unsafe` keyword on the function signature is the declaration
of intent — every line in the body is implicitly unsafe.

**Callers must acknowledge the unsafety:** Calling an `unsafe fn`
from safe code requires `unsafe:` at the call site (or being
inside another `unsafe fn`):

```
unsafe: sha256_compress(&mut ctx)    // caller acknowledges
```

This preserves the audit trail — `grep unsafe` finds every
boundary where safe code transitions to unsafe code.

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

Code after an unconditional `return`, labeled or unlabeled `break`,
labeled or unlabeled `continue`, `goto`, or diverging expression is
dead. It is always either a bug or leftover from refactoring.

```
// ERROR:
fn example -> i32:
    return 42
    print("hello")    // unreachable

// ERROR:
for x in items:
    if should_skip(x) then
        continue
        log("skipped")  // unreachable
```

The compiler detects unreachable code via control flow analysis and
rejects it. This applies to all code after unconditional control
flow transfers, including `return`, labeled or unlabeled `break`,
labeled or unlabeled `continue`, `goto`, and calls to functions with
return type `Never` (e.g., `exit()`, `panic()`).

A labeled statement may be reachable only via `goto`. Ordinary
unreachable-code diagnostics are suppressed for a labeled statement
and for following statements until the next control-flow terminator
or the next labeled statement:

```
fn example:
    goto 'done
    print("never")    // unreachable
    'done
    print("finished") // reachable via goto
```

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

### 20b.7 Pointer Compared to Array
Arrays never implicitly decay to pointers, so comparing a pointer
directly with an array is rejected:

```
// ERROR:
ptr == arr
```

Use explicit decay (`&arr[0] as *const T`). See §4.3a.1.

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

8. **Reborrowing.** When a function holds `&mut T` and calls
   another function that also takes `&mut T`, the original borrow
   is **reborrowed** for the duration of the call. This is not a
   violation of the aliasing rule — only one `&mut` is active at
   any point. The original borrow is suspended during the call
   and resumes after it returns.

   ```
   fn update(self: &mut Sha256, data: *const u8, len: i32):
       // self is &mut Sha256
       compress(&mut self)    // OK: reborrow of self for call duration
       // self is usable again after compress returns
   ```

   Without reborrowing, methods that delegate to helper functions
   taking `&mut Self` would require raw pointers. Reborrowing
   makes `&mut` method chains composable.

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
| `with e as x: body` | Yes (`Scoped`) | `e.enter(x => body)` |
| `with e as mut x: body` | Yes (`ScopedMut`) | `e.enter_mut(x => body)` |
| `with e as mut x: body` | No | `{ var x = e; body }` |
| `with e as x: body` | No | `{ let x = e; body }` |

`Scoped`/`ScopedMut` implementations take priority. If the type
implements the trait, the guarded form is used.

### 23.2 Multiple Bindings

Multiple bindings nest left-to-right:
`with a as x, b as mut y: body` is equivalent to
`a.enter(x => b.enter_mut(y => body))`.

Multiple bindings in the non-guarded (binding) forms follow the
same nesting: each binding is in scope for all subsequent bindings
and the body.

### 23.3 Non-Local Control Flow

All `with` forms are transparent for control flow. The following
observable behaviors are required:

- `return` inside a `with` block returns from the **enclosing function**.
- `break` inside a `with` block breaks the **enclosing loop**.
- `continue` inside a `with` block continues the **enclosing loop**.
- Labeled `break 'label` and `continue 'label` inside a `with` block
  may target visible labels in the enclosing function; `with` blocks
  do not hide labels.
- `goto 'label` inside a `with` block may target a visible label in
  the enclosing function, subject to the normal goto restrictions
  (§13.5b).
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

# Part III — Appendices

---

## 25. Test Cases

*Moved to `test/spec/`. Files are named `spec_ss<N>_<topic>.w` where
`<N>` is the spec section tested. See `test/spec/README.md` for the
mapping from old section 25.x numbers to test files.*

    ./scripts/run_tests.sh test/spec/*.w

---

## 26. Phased Implementation

*Moved to `docs/roadmap.md`.*

## 27. Known Limitations and Trade-Offs (v1.0)

*Moved to `docs/roadmap.md`.*

## 28. Future Work

*Moved to `docs/roadmap.md`.*

---

## 29. Additional Lexical and Binding Rules (Wave Language Rules)

### 29.1 Numeric separators

Numeric literals permit `_` separators for readability:

- Decimal: `1_000_000`
- Hex: `0xFF_AA_22`
- Binary: `0b1111_0000`
- Float: `3.141_592_653`

Separators are ignored for numeric value parsing.

Type suffixes, when present, begin after the numeric portion of the
literal ends. The suffix itself does not contain separators:

- Valid: `1_000u64`, `0xFF_FFu32`, `3.25f32`
- Invalid: `1_000_u64`, `0xFF_FF_u32`

The suffix is matched greedily from the closed set of numeric suffixes
defined in §4.2.1.

### 29.2 Trailing commas

Trailing commas are **permitted but never required** in list-like grammar positions, including:

- Function parameter lists and argument lists
- Type parameter and type argument lists
- Record/struct field lists
- Tuple/array literal element lists
- Match arms and import/use lists

Inside matched `()`, `[]`, and `{}`, list-like grammar positions treat optional
newlines like separator whitespace. This means multiline parameter lists,
argument lists, tuple literals, array literals, struct literals, indexing, and
type/generic lists are legal as long as the delimiters are balanced.

This rule applies to the delimited list itself, not to nested block bodies.
Newlines that start a block after `:` or `=>` retain their normal significance.

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

### 29.5a Labels

A `LABEL` token is a single quote followed immediately by an identifier,
with no whitespace between the quote and the identifier:

```
'outer
'search
'L0
```

The identifier part follows the ordinary identifier spelling rules:
it starts with a letter or underscore and may contain letters,
digits, and underscores. Labels are syntactically distinct from
ordinary identifiers because of the leading quote and live in a
separate namespace. That namespace is shared by label declarations
and the target operands of `goto`, `break`, and `continue`.

Single-quoted character literals are also valid syntax. A character
literal is a single quote, followed by one character or escape
sequence, followed by a closing single quote:

```
'a'
'@'
'\n'
```

Lexer priority for apostrophe-related tokens is:

1. Byte literals such as `b'X'` or `b'\n'`.
2. Closed character literals such as `'a'`, `'@'`, or `'\n'`.
3. Labels such as `'outer`, `'L0`, or `'scan`.

A label has no closing quote. A character literal must have a closing
quote. Inside string literals, apostrophe is ordinary string content
and never starts a label or character literal.

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

### 29.11 Reserved Keywords

The following keywords are reserved and cannot be used as identifiers:

| Keyword | Purpose |
|---------|---------|
| `fn` | Function declaration |
| `let` | Variable binding |
| `mut` | Mutable binding modifier |
| `type` | Type declaration |
| `use` | Import |
| `extern` | External function declaration |
| `if` | Conditional |
| `then` | Inline conditional body separator |
| `else` | Conditional branch |
| `match` | Pattern matching |
| `for` | Loop over iterables |
| `while` | Conditional loop |
| `goto` | Unconditional jump to label |
| `yield` | Generator / comprehension yield |
| `return` | Early return |
| `break` | Break from loop or labeled block |
| `continue` | Continue to next loop iteration |
| `true`, `false` | Boolean literals |
| `and`, `or`, `not` | Logical operators |
| `in` | Membership/iteration operator |
| `as` | Type cast |
| `defer` | Deferred execution |
| `errdefer` | Error-path deferred execution |
| `async`, `await` | Async function/await |
| `spawn` | Fiber creation |
| `trait`, `impl` | Trait definition/implementation |
| `pub` | Visibility modifier |
| `const` | Compile-time constant |
| `implicit` | Implicit parameter modifier |
| `newaxis` | Multi-index dimension insertion |
| `it` | Implicit closure parameter |
| `where` | Trait bound clauses |
| `move` | Move closure (reserved for future use) |
| `unsafe` | Unsafe block |
| `comptime` | Compile-time evaluation |

### 29.12 Error Codes

| Code | Description |
|------|-------------|
| E0901 | Non-local control flow (`return`, `break`, `continue`, `goto`, `?`) inside `defer`/`errdefer` |
| E0951 | Nested implicit `it` is ambiguous — use explicit `param => expr` for inner closure |
| E0952 | `it` used in context expecting N != 1 parameters |
| E0953 | `it` is a reserved keyword and cannot be used as an identifier |
| E1101 | Orphan rule violation: impl requires a local trait or local type |
| E1102 | Duplicate implementation of trait for type |
| E1201 | Overlapping trait implementations |

### 29.13 Block Body Syntax

Block bodies may use either `:` (colon form) or `{ }` (brace form).
Both forms are semantically identical and interchangeable wherever a
block body appears: `fn`, `if`, `else`, `while`, `for`, `match`,
`with`, `type`, `enum`, `impl`, `trait`, closures, and any future
block-introducer.

**Colon form (`:`):**

- **Inline:** same-line single-expression body.
  ```
  fn add(a: i32, b: i32) -> i32: a + b
  fn is_empty(self: &Vec[T]) -> bool: self.len() == 0
  ```
- **Multi-line:** newline after `:`, body indented one level deeper
  than the header.
  ```
  fn main:
      let x = 5
      print(x)
  ```
- Colon followed by a newline without indentation is a **syntax
  error**.
- Colon with a body that mixes same-line content plus subsequent
  indented lines is a **syntax error**.

**Brace form (`{ }`):**

- Body delimited by `{` and matching `}`.
- Whitespace inside braces is insignificant.
- Statements are separated by newlines or semicolons (`;`).
- Single-line:
  ```
  fn add(a: i32, b: i32) -> i32 { a + b }
  fn main { print("hello") }
  ```
- Multi-line:
  ```
  fn main {
      let x = 5
      print(x)
  }
  ```
- Empty brace body `{}` is legal (returns `Unit`).
- Unindented bodies are legal (generators may emit flat output):
  ```
  fn main {
  let x = 5
  print(x)
  }
  ```

**Illegal combinations:**

- Mixed colon + brace: `fn main: { body }` — syntax error.
- Brace + colon: `fn main { : body }` — syntax error.
- Empty colon body: `fn main:` with nothing following — syntax error.

**Labeled bodies:**

Labels are statement prefixes (§13.5a). A label may prefix any
statement, either on the same line or on its own line immediately
before the statement it labels. A label has no trailing colon of its
own; when the labeled statement is a block, loop, or other body form,
that construct still supplies its normal body introducer:

```
'outer while running:
    tick()

'outer while running { tick() }

'scan for item in list:
    process(item)

'scan for item in list { process(item) }

'early:
    maybe_exit()

'early { maybe_exit() }

'done return
```

For labeled `while` and `for`, the loop still has its own body
introducer. For colon-form labeled blocks, the colon after the label
is the block-body introducer. Labels on non-body statements, such as
`'done return`, do not introduce a block.

**Applies uniformly to all block-introducers:**

```
// Functions
fn greet: print("hello")
fn greet { print("hello") }

// Conditionals
if x > 0:
    handle_positive()
if x > 0 { handle_positive() }

// Loops
while running:
    tick()
while running { tick() }

for item in list:
    process(item)
for item in list { process(item) }

// Match (block form)
match shape:
    Circle(r) => pi * r * r
    _ => 0.0
match shape {
    Circle(r) => pi * r * r,
    _ => 0.0,
}

// Type definitions
type Point { x: f64, y: f64 }

// Trait definitions
trait Drawable:
    fn draw(self: &Self)
trait Drawable {
    fn draw(self: &Self)
}
```

**Semicolons as statement separators:**

The semicolon (`;`) is a statement separator, not a terminator.
It may be used anywhere a newline separates statements:

```
let x = 1; let y = 2; print(x + y)
fn add(a: i32, b: i32) -> i32 { a + b; }   // trailing ; is legal (ignored)
```

Consecutive semicolons and mixed semicolons/newlines collapse to a
single separator, just as consecutive newlines do:

```
let x = 1;; let y = 2      // same as: let x = 1; let y = 2
let a = 1;
let b = 2                   // semicolon + newline = one separator
```

`with fmt` normalizes semicolons to newlines — semicolons never
appear in formatted output.

Semicolons inside `[…]` retain their existing meaning (array fill
and for-comprehension monadic chaining) and are not affected by
this rule.

**Style guidance:** Hand-written code typically uses colon form.
Generated code (code generators, derive macros, comptime expansions)
should use brace form to avoid indentation-sensitivity issues.

**Formatter behavior:**

- `with fmt` (default): preserves the author's chosen form.
- `with fmt --prefer-brace`: converts inline colon to inline brace.
  `fn f: expr` becomes `fn f { expr }`. Multi-line colon becomes
  multi-line brace. Lossless.
- `with fmt --prefer-colon`: converts inline brace to inline colon
  when the body is a single expression. Multi-statement braced
  bodies convert to multi-line colon form. Lossless.

---

## 30. Formal Grammar (Informative)

This appendix collects syntactic productions from throughout the
specification into a unified reference. The normative definitions
remain in their respective sections; this is a convenience index.

### 30.1 Notation

Productions use EBNF-like notation:

- `|` alternatives
- `[ ]` optional
- `{ }` zero or more repetitions
- `( )` grouping
- `'...'` terminal tokens
- `UPPER` non-terminal symbols

### 30.2 Lexical Grammar

**Identifiers** (§29.11):

```
IDENT       := LETTER { LETTER | DIGIT | '_' }
LETTER      := 'a'..'z' | 'A'..'Z' | '_'
DIGIT       := '0'..'9'
```

**Numeric literals** (§4.2.1, §29.1):

```
INT_LIT     := DEC_LIT | HEX_LIT | BIN_LIT | OCT_LIT
DEC_LIT     := DIGIT { DIGIT | '_' } [ INT_SUFFIX ]
HEX_LIT     := '0x' HEX_DIGIT { HEX_DIGIT | '_' } [ INT_SUFFIX ]
BIN_LIT     := '0b' BIN_DIGIT { BIN_DIGIT | '_' } [ INT_SUFFIX ]
OCT_LIT     := '0o' OCT_DIGIT { OCT_DIGIT | '_' } [ INT_SUFFIX ]
FLOAT_LIT   := DIGIT { DIGIT | '_' } '.' DIGIT { DIGIT | '_' } [ FLOAT_SUFFIX ]
INT_SUFFIX   := 'i8' | 'i16' | 'i32' | 'i64' | 'u8' | 'u16' | 'u32' | 'u64' | 'usize' | 'isize'
FLOAT_SUFFIX := 'f32' | 'f64'
```

**String literals** (§15.3, §29.3, §29.4):

```
STR_LIT     := '"' { CHAR | ESCAPE } '"'
RAW_STR     := 'r' HASHES '"' { CHAR } '"' HASHES
FSTRING     := 'f"' { CHAR | ESCAPE | '{' EXPR [ ':' FMT_SPEC ] '}' } '"'
CSTR_LIT    := 'c"' { CHAR | ESCAPE } '"'
CHAR_LIT    := "'" ( CHAR | ESCAPE ) "'"
BYTE_LIT    := "b'" BYTE_OR_ESCAPE "'"
HASHES      := { '#' }
```

When the lexer sees a bare apostrophe, it tries `CHAR_LIT` before
`LABEL`. A label has no closing apostrophe.

**Labels** (§13.5a, §29.5a):

```
LABEL       := "'" IDENT
```

`LABEL` may appear as a statement prefix or as the target operand of
`goto`, `break`, and `continue`. As a statement prefix, it must be
the first token of the statement and has no trailing colon of its own.

### 30.3 Declarations

**Function declaration** (§9.1):

```
FN_DECL     := [ PUB ] 'fn' IDENT [ TYPE_PARAMS ] [ '(' PARAMS ')' ] [ '->' TYPE ] BODY
PARAMS      := PARAM { ',' PARAM } [ ',' ]
PARAM       := IDENT ':' TYPE [ '=' EXPR ]
TYPE_PARAMS := '[' IDENT { ',' IDENT } [ ':' BOUND ] ']'
PUB         := 'pub'
```

**Struct declaration** (§4.3):

```
STRUCT_DECL := [ PUB ] 'type' IDENT [ TYPE_PARAMS ] '{' FIELDS '}'
FIELDS      := FIELD { ',' FIELD } [ ',' ]
FIELD       := [ PUB ] IDENT ':' TYPE [ '=' EXPR ]
```

**Enum declaration** (§4.4):

```
ENUM_DECL   := [ PUB ] 'type' IDENT [ TYPE_PARAMS ] '=' VARIANTS
VARIANTS    := VARIANT { '|' VARIANT }
VARIANT     := IDENT [ '(' TYPES ')' ] [ '=' INT_LIT ]
```

**Trait and impl** (§11):

```
TRAIT_DECL  := [ PUB ] [ '@[sealed]' ] 'trait' IDENT [ TYPE_PARAMS ] BODY
IMPL_DECL   := 'impl' [ TYPE_PARAMS ] [ TRAIT 'for' ] TYPE BODY
```

**Import** (§18.2):

```
USE_DECL    := 'use' MODULE_PATH [ '.' '{' IMPORT_LIST '}' ]
MODULE_PATH := IDENT { '.' IDENT }
```

**Const declaration** (§9.1b):

```
CONST_DECL  := 'const' IDENT ':' TYPE '=' EXPR
```

### 30.4 Statements

**Variable binding** (§2):

```
LET_STMT    := 'let' [ 'mut' ] PATTERN [ ':' TYPE ] '=' EXPR
VAR_STMT    := 'var' IDENT [ ':' TYPE ] '=' EXPR
```

**Control flow** (§9, §13.5a, §13.5b):

```
STMT        := LABEL_STMT | LET_STMT | VAR_STMT | IF_STMT | MATCH_STMT
              | FOR_STMT | WHILE_STMT | WITH_STMT
              | RETURN_STMT | BREAK_STMT | CONTINUE_STMT | GOTO_STMT
              | DEFER_STMT | EXPR
LABEL_STMT  := LABEL ( STMT | COLON_BODY | BRACE_BODY )
IF_STMT     := 'if' EXPR BODY [ 'else' ( IF_STMT | BODY ) ]
              | 'if' EXPR 'then' EXPR [ 'else' EXPR ]
              | 'if' 'let' PATTERN '=' EXPR BODY [ 'else' BODY ]
MATCH_STMT  := 'match' EXPR BODY_ARMS
MATCH_ARM   := PATTERN [ 'if' EXPR ] '=>' EXPR
FOR_STMT    := 'for' PATTERN 'in' EXPR BODY
WHILE_STMT  := 'while' EXPR BODY
WITH_STMT   := 'with' EXPR 'as' [ 'mut' ] IDENT BODY
RETURN_STMT := 'return' [ EXPR ]
BREAK_STMT  := 'break' [ LABEL ]
CONTINUE_STMT := 'continue' [ LABEL ]
GOTO_STMT   := 'goto' LABEL
DEFER_STMT  := 'defer' EXPR
```

### 30.5 Expressions

**Operator precedence** (§9.9) — low to high:

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `or` | Left |
| 2 | `and` | Left |
| 3 | `==`, `!=`, `in`, `not in` | Non-associative |
| 4 | `<`, `>`, `<=`, `>=` | Chained |
| 5 | `\|>` (pipeline) | Left |
| 6 | `\|` | Left |
| 7 | `^` | Left |
| 8 | `&` | Left |
| 9 | `<<`, `>>` | Left |
| 10 | `+`, `-`, `++`, `??` | Left |
| 11 | `*`, `/`, `%`, `@` | Left |
| 12 | Unary prefix (`not`, `-`, `~`, `&`, `&mut`) | — |
| 13 | Postfix (`.await`, `?`, `.field`, `[i]`, `()`) | Left |

**Comprehensions** (§13.6):

```
LIST_COMP   := '[' EXPR 'for' PATTERN 'in' EXPR [ 'if' EXPR ] ']'
SET_COMP    := '{' EXPR 'for' PATTERN 'in' EXPR [ 'if' EXPR ] '}'
MAP_COMP    := '{' EXPR ':' EXPR 'for' PATTERN 'in' EXPR [ 'if' EXPR ] '}'
```

### 30.6 Patterns

**Pattern syntax** (§9.7):

```
PATTERN     := LITERAL_PAT | IDENT_PAT | TUPLE_PAT | STRUCT_PAT
              | ENUM_PAT | SLICE_PAT | RANGE_PAT | OR_PAT
              | BIND_PAT | WILDCARD | IN_PAT | REST_PAT
LITERAL_PAT := INT_LIT | STR_LIT | CHAR_LIT | 'true' | 'false'
IDENT_PAT   := IDENT
TUPLE_PAT   := '(' PATTERN { ',' PATTERN } ')'
STRUCT_PAT  := [ TYPE ] '{' FIELD_PAT { ',' FIELD_PAT } [ ',' '..' ] '}'
ENUM_PAT    := [ '.' ] IDENT [ '(' PATTERN { ',' PATTERN } ')' ]
SLICE_PAT   := '[' [ PATTERN { ',' PATTERN } [ '..' [ IDENT ] ] ] ']'
RANGE_PAT   := PATTERN '..' PATTERN | PATTERN '..=' PATTERN
OR_PAT      := PATTERN { '|' PATTERN }
BIND_PAT    := IDENT '@' PATTERN
IN_PAT      := 'in' '[' EXPR { ',' EXPR } ']'
WILDCARD    := '_'
REST_PAT    := '..'
```

### 30.7 Format Specification

**Format spec grammar** (§15.4.1):

```
FMT_SPEC    := [ [ FILL ] ALIGN ] [ SIGN ] [ '#' ] [ '0' ] [ WIDTH ] [ '.' PRECISION ] [ MODE ]
FILL        := <any single byte except '{' '}'>
ALIGN       := '<' | '>' | '^'
SIGN        := '+' | '-'
WIDTH       := DIGIT { DIGIT }
PRECISION   := DIGIT { DIGIT }
MODE        := 'd' | 'x' | 'X' | 'b' | 'o' | 'f' | 'e' | 'g' | 's' | '?'
```

### 30.8 Block Syntax

**Body forms** (§29.13):

```
BODY        := COLON_BODY | BRACE_BODY
COLON_BODY  := ':' INLINE_EXPR
              | ':' NEWLINE INDENT STMT { NEWLINE STMT } DEDENT
BRACE_BODY  := '{' [ STMT { ( NEWLINE | ';' ) STMT } ] '}'
```

Both forms are interchangeable for all constructs: `fn`, `if`,
`else`, `while`, `for`, labeled blocks, `match`, `type`, `enum`,
`impl`, `trait`, and closures.

### 30.9 Reserved Keywords

The following identifiers are reserved (§29.11):

```
and       as        async     await     break     comptime
const     continue  defer     else      enum      errdefer
false     fn        for       gen       goto      if
impl      import    in        is        it        let
match     mod       move      mut       not       or
pub       return    self      sealed    struct    then
todo      trait     true      type      unsafe    use
var       where     while     with      yield
```

---

*The With Programming Language — End of specification.*
