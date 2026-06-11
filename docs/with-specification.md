# The With Programming Language — Specification v7.1

**Author:** Eric Hartford
**Status:** Reference specification for prototype implementation
**Changelog v7.1:** Global declarations specified (§9.1c): `global`
(stable) / `global var` (rebindable), pre-`main` initialization, and
the usage-based data-race rule — never-mutated and synchronized
globals always safe; bare mutation safe iff the program is provably
single-threaded, `unsafe` past the proof (E0921). §19.4 amended:
proof-dependent operations inside `unsafe` warn (not error) when
newly proven safe. **Integrated collections syntax** (Scala-inspired
target polymorphism): one bracket comprehension family with
expected-type-driven targets and `key: value` map form (§13.6);
collection literals incl. map literals `[k: v]` and `[:]` (§4.3c);
`vec![...]` examples replaced with collection literals; §30.5
grammar updated. **`loop` specified** (§13.5d): expression-valued
via `break expr`; §13.5a value-break text refined; §30.4 grammar.
**Regular expressions promoted to language surface** (§15.8): regex
literals `/pattern/flags`, `=~`/`!~` at precedence level 3,
branch-scoped `$capture` bindings as a refutable-binding condition
form; §18.5b.6 now defers to §15.8; `std.regex` added to §18.6.
`@[effect]` declared-effect contracts for bodiless declarations
(§16.3d). §14.19 `[runtime]` config for fiber stack and pool sizing.
CLI table completed (§18.5); module map extended with
regex/json/http/crypto + internal-modules note (§18.6); Attribute
Index appendix (§29.14). Named arguments: `pub` parameter names are
API surface (§9.1a). §18.7's `static` example corrected to `global`.
**Changelog v7.0:** Parameter passing: the signature states the mode —
`&T` borrows, plain `T` consumes; share-place call semantics removed
(§3.8; §12.4 retains by-place capture for closures; §21.1 example
fixed). Cancellation observation moved to the `Task` handle
(`was_cancelled`); the `TaskCancelled`/`.is_cancelled()` error story
removed — awaiting a cancelled task unwinds, never returns `Err`
(§14.7). `Result` removed from `@[must_use]` match exhaustiveness
(§9.7). `with ... as mut` always returns the binding (§7.2, §23.1).
Iterator borrow-origin via `@[iter_of_self]` specified for all
libraries (§13.2). `[]mut T` exclusivity rules and
`split_at`/`split_at_mut` (§4.8a). Ephemeral diagnostic contract
(§22.3). Fiber stack conforming baseline = fixed pooled stacks;
growth and FFI stack switching are roadmap (§14.19). c_import
contract metadata sources named, including the curated libc overlay
(§16.3c). Implicit default return gated to bodies with no explicit
value return (§4.10). Consuming-rebind shadowing exception (§29.8).
String-literal elision is an optimization, not a guarantee (§15.3,
§20). Hygiene: enum-only sum-type syntax swept (§10.1, §11.7, §30.3);
keyword list synced to the lexer (§29.11, §30.9 now defers to it);
`usize`/`isize` documented (§4.1, §4.2.1); duplicate §18.7 renumbered
to §18.8; `let mut` removed from §30.4 grammar; §14.21 match arms
fixed to `=>`; f-string examples fixed (§15.4.5, §15.4.7); generator
return type wording fixed (§13.1, §13.4); select-await dead panic
clause removed (§14.10); §22.1 Rule 6 distinguished from Rule 4;
module resolution and `pub` enforcement stated (§18.1, §18.3).
**Changelog v6.9:** CLI one-liners (`with -e`, `with -n`, `with -p`)
are specified as normal compiled With entry sources with implicit-main
semantics, stdin line bindings, `args`, semicolon splitting, and regex
capture behavior (§18.5b).
**Changelog v6.8:** Three universal body forms (§29.13) — inline colon,
indented colon, and braced — now apply to every block-introducing construct
including `defer`, `errdefer`, `comptime`, and `unsafe`. `if`, `else if`,
and `else` use those same body forms; every arm requires `:` or `{`.
`else if` is a two-token keyword pair parsed as a chain continuation.
**Changelog v6.7:** Reorganized — extracted test cases to `test/spec/`,
roadmap to `docs/roadmap.md`, design rationale to `docs/design-rationale.md`,
stdlib API tables to `docs/libstd-spec.md`. Added grammar appendix (§30).
Added labels on arbitrary statements and `goto` (§13.5a, §13.5b).
**Positioning:** Systems programming that feels like a modern language.
**Principle:** Make the common case delightful. Be as safe as Rust without front-loading Rust's ceremony. Trust the programmer at the edges without accepting safety-contract violations.

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
- **Trust the programmer within the safety contract.** Warn for weird-but-safe code when the compiler can preserve its meaning.
  Reject code that violates safety, ownership, concurrency, determinism, or code-generation correctness.

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
`.to_owned()`. In ordinary safe application code: no `unsafe`, no
explicit memory-management ceremony. At the systems edge, explicit
unsafe boundaries (§19), raw pointer access (§16.11), allocator-aware
APIs (§8), and manual resource-management APIs remain available. The
common path stays fully statically typed, native-compiled, and
memory-safe. It reads like Python, runs like C.

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
- **C functions just call when modeled** — `c_import` bindings
  are callable directly when the importer has modeled the contract.
  No blanket `unsafe {}` wrapper around C interop. (§16.1)
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
- **Cancellation just works** — no `Cancelled` variants or `From`
  impls on your error types. Cancellation unwinds cleanly. (§14.7)
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
defer if file.has_error(): return Err(IoError)
//                         ^^^^^^ ERROR E0901: non-local control
//                         flow is forbidden inside defer

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
&T          shared (read-only) borrow
```

With has a single reference type: `&T`. There is no `&mut T` in safe
code. Mutation is expressed through owned values (`mut self: Self`
receivers), `with` scoped access, and `IndexPlace` projections.

For unsafe FFI, raw pointers (`*const T`, `*mut T`) and address-of
(`&raw mut x`) provide mutable pointer semantics (§19).

### 3.2 Aliasing Rule

Active shared borrows (`&T`) of a place are invalidated when that
place is mutated. Mutation occurs through:

- Assignment to the place (`x = value`)
- Calling a `mut self` method on the place (`x.push(v)`)
- Mutation through `with` scoped access or `IndexPlace` projection

Enforced at compile time via view-liveness analysis.

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
    if xs.is_empty(): None else: Some(&xs[0])

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
potential origin parameters, the returned value is tracked as
borrowing from the set of parameters the body may actually derive it
from. This origin set is inferred from the function body and enforced
at the call site.

### 3.5 Borrow Scope: Non-Lexical Lifetimes

A borrow is active from the point it is created until its **last use**,
not until the end of the enclosing block.

```
var x = 5
let r = &x
print(r)       // last use of r; borrow ends here
x = 10           // OK: no active borrow
```

### 3.6 Disjoint Field Access

The compiler guarantees that simultaneous access to structurally
disjoint fields is permitted, at any nesting depth.

```
world.physics.positions[i] = new_pos    // mutates one field
let v = &world.physics.velocities       // borrows a different field — OK
```

Disjointness is defined over **static field paths**. Two paths are
disjoint if they diverge at any field access.

**Array/slice index disjointness is NOT guaranteed at compile time.**
Use `get_disjoint(i, j)` for safe simultaneous element access.

**Disjoint capture in closures:** Closures capture only the
specific fields they access, not the enclosing struct as a whole.
This is critical for parallel data-oriented code:

```
// Each closure captures disjoint fields of `world`
scope s =>
    s.spawn(() => run_physics(world.transforms, world.velocities))
    s.spawn(() => run_render(world.transforms, world.sprites))
// OK: both closures access non-overlapping field paths.
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

Auto-deref applies to `&T`, `Box[T]`, `Arc[T]`, `Rc[T]`, and any
type implementing the `Deref` trait. The compiler inserts as many
dereferences as needed to reach the target field or method.

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

This also works for method calls: `alice.greet()` works when
`greet` takes `self: &Self`.

**Restriction:** Auto-referencing only creates shared borrows
(`&T`). Mutation uses `mut self` receivers on owned values:

```
extend User:
    fn update(mut self: Self):
        self.name = "Bob"

var alice = User { name: "Alice" }
alice.update()              // mutates in place via mut self receiver
```

**The parameter's declared type states the mode.** A `&T` parameter
borrows: auto-ref erases the sigil at the call site, and the caller's
binding remains valid afterward. A plain `T` parameter consumes: the
argument is moved into the callee (copied, for `Copy` types), and the
caller's binding is invalidated. No call-site annotation is ever
required for either mode — a plain call `f(x)` is always legal and
means whatever the signature says. `move x`, `copy x`, and `&x`
remain available as explicit spellings of intent:

```with
take(alice)        // signature take(a: User): consumes alice
peek(alice)        // signature peek(a: &User): borrows alice
take(move alice)   // explicit spelling of the same consume
dup(copy xs)       // duplicate via Copy or Clone instead of consuming
```

The mode is declared exactly once, in the signature — the boundary
where §4.6 already requires explicitness — and never at call sites.
A function that only reads a by-value parameter, or returns a view
derived from one, should take `&T` instead; when the compiler can see
this mistake (for example, a view of a consumed parameter escaping
through the return value), it emits a directed suggestion naming the
parameter and the `&T` fix.

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
Pointer-sized integers: `usize`, `isize` (64-bit on all supported targets)
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

- Integer suffixes: `u8`, `u16`, `u32`, `u64`, `i8`, `i16`, `i32`, `i64`, `usize`, `isize`
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
causes a panic in all builds unless the project explicitly configures
wrapping or saturating arithmetic; the default is panic.

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
`u8`–`u64`).

For `&`, `|`, and `^`, the operation preserves bit patterns, not
numeric values. The operand rules are therefore narrower than
arithmetic promotion:

1. An untyped integer literal adopts the other operand's integer type.
   The literal is valid if its bit pattern fits that type's width, not
   if its signed numeric value fits the type's range.

   ```
   let flags: u32 = 0xf000
   let a = flags | 0xff           // 0xff is a 32-bit mask

   let byte: i8 = -1
   let b: i8 = byte & 0xff        // OK: 0xff is an 8-bit pattern
   let c: i8 = byte & 0x1ff       // ERROR: 9-bit pattern
   ```

2. Two typed operands with the same signedness and different widths
   widen to the wider type. Unsigned operands zero-extend; signed
   operands sign-extend.

   ```
   let a: u8 = 1
   let b: u32 = 0xff00
   let c = a | b                  // u32

   let x: i8 = -1
   let y: i32 = 0xff00
   let z = x & y                  // i32
   ```

3. Two typed operands with different signedness require an explicit
   `as` cast. There is no implicit third-type widening for bitwise
   operators.

   ```
   let u: u32 = 1
   let i: i32 = -1

   u | i                          // ERROR: mixed signedness
   (u as i32) | i                 // OK: caller chose signed bits
   u | (i as u32)                 // OK: caller chose unsigned bits
   (u as i64) | (i as i64)        // OK: caller chose 64-bit signed bits
   ```

The result type is the adopted operand type from rule 1, the wider
same-signedness type from rule 2, or the explicit cast type chosen by
the caller in rule 3.

Unary `~` preserves the operand type.

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
- Fixed-size arrays are value types and follow normal ownership
  rules.
- `[T; N]` is `Copy` only when `T` is `Copy`; otherwise assignment
  moves the array.
- Argument passing follows the normal call-mode and effect rules for
  the callee. For large arrays, pass by reference unless by-value
  movement or copying is intended.
- Bounds checking in debug mode, unchecked in release.

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

### 4.3c Collection Literals

Bracket literals are With's one collection-literal family. The
element form builds sequences and sets; the `key: value` form builds
maps. The concrete collection is selected by **expected type**, with
sensible defaults — the same rule as numeric literals (§4.2.1) and
enum variant shorthand (§4.4):

```
let a = [1, 2, 3]                      // [i32; 3] — fixed array (default)
let v: Vec[i32] = [1, 2, 3]            // Vec via expected type
let s: HashSet[str] = ["a", "b"]       // HashSet via expected type
let o: BTreeSet[i32] = [3, 1, 2]       // BTreeSet via expected type

let colors = ["red": 0xFF0000, "green": 0x00FF00]
// HashMap[str, i32] — the map-literal default

let ranks: BTreeMap[str, i32] = ["a": 1, "b": 2]

let empty: HashMap[str, i32] = [:]     // the empty map literal
let none: Vec[i32] = []                // empty sequence (type from context)
```

**Rules:**

1. The element form `[a, b, c]` defaults to a fixed array `[T; N]`
   (§4.3a). When the expected type is `Vec[T]`, `HashSet[T]`, or
   `BTreeSet[T]`, the literal builds that collection instead.
2. The map form `[k: v, ...]` defaults to `HashMap[K, V]`. When the
   expected type is `BTreeMap[K, V]`, it builds that instead. `[:]`
   is the empty map and requires an expected map type.
3. Set and map construction from literals follows insertion order;
   for duplicate keys/elements, later entries win (last-write,
   matching repeated `insert`).
4. Element and map forms cannot be mixed in one literal.
5. The map form requires the target's key type to satisfy the
   container's bound (`Hash + Eq` for `HashMap`, `Ord` for
   `BTreeMap`), checked as for any construction.

There are no brace-delimited collection literals; `{ }` remains
blocks, struct literals, and record update. The colon key separator
is unambiguous inside brackets (array types and repeats use `;`,
§4.3a).

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

**`@[specified]` attribute:** For boundary-facing discriminant enums,
`@[specified]` requires every variant to provide an explicit value.
It is intended for wire formats, file formats, FFI constants, protocol
messages, and other values where auto-increment would make source
ordering part of the external ABI.

```
@[specified]
enum MessageType: u16:
    Ping = 1
    Pong = 2
    Data = 3
```

`@[specified]` requires an explicit integer representation type and
rejects any variant without `= value`:

```
@[specified]
enum MessageType: u16:
    Ping = 1
    Pong       // ERROR: @[specified] requires explicit variant values
```

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

**Exclusivity rules for `[]mut T`:** a mutable slice is an exclusive
view of its range. While a `[]mut T` is live (NLL: until its last
use), the borrowed range may not be read or written through any other
path — creating one invalidates outstanding `&T` and `[]T` views of
the same place, and creating a second overlapping `[]mut T` is
rejected (§21.1 Rule 1). Disjoint mutable views are obtained
explicitly:

```
let (left, right) = data.split_at_mut(mid)
// left: []mut T over [0, mid)   right: []mut T over [mid, len)
```

The standard library must provide `split_at(i)` and `split_at_mut(i)`
on slices, arrays, and `Vec[T]`. As with array indices (§3.6), range
disjointness is not inferred at compile time — `split_at_mut` is the
safe primitive for simultaneous mutable access to disjoint ranges. In
parameter position, `[]T` and `[]mut T` follow §3.8's borrow mode:
the caller's collection coerces to the slice view, and the caller's
binding remains valid after the call (for `[]mut T`, the exclusive
borrow ends when the callee returns).

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
    if age < 0: return Err(.InvalidAge)
    if age > 150: return Err(.InvalidAge)
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

- If any path in the body explicitly returns a value (a `return expr`
  or a non-Unit tail expression on another branch), implicit default
  return does not apply — a function that demonstrably produces
  values elsewhere but falls off the end is reported as a missing
  return, not defaulted. The implicit default exists for functions
  that never spell a return value (entry points, handlers); it never
  papers over a forgotten one.
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

- References: `&T`
- Views: `StrView` / `&str`, `&[T]`
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

extend Parser:
    fn next_token(mut self: Self) -> Option[Token]:
        // ... returns Token borrowing from self.source
```

Ephemeral structs follow all the same rules as ephemeral values
(§5.1): they can be local bindings, parameters, and return values,
but cannot be stored in long-lived containers or non-ephemeral
structs.

```
// OK: local use, pattern matching, passing around
let tok = parser.next_token()?
match tok.kind:
    .Ident   => handle_ident(tok.text)
    .Number  => handle_number(tok.text)
    .String  => handle_string(tok.text)

// OK: for-loop processes each token — tok drops at iteration end
while let Some(tok) = parser.next_token():
    process(tok)

// LIMITATION: Cannot collect ephemeral tokens into a Vec directly.
// Each Token borrows from parser.source (Rule 6, §21.1), so holding
// one Token prevents calling next_token() again.
//
// To collect, use owned tokens with offset indices:
type OwnedToken { start: u32, end: u32, kind: TokenKind, span: Span }

extend Parser:
    fn next_owned_token(mut self: Self) -> Option[OwnedToken]:
        let tok = self.next_raw_token()?
        Some(OwnedToken { start: tok.start, end: tok.end, kind: tok.kind, span: tok.span })

let tokens = with Vec.new() as mut toks:
    while let Some(tok) = parser.next_owned_token():
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
| `insert` | `(mut self: Self, T) -> Handle[T]` | |
| `get` | `(self: &Self, Handle[T]) -> Option[&T]` | Ephemeral return |
| `slot` | Scoped via `with sm.slot(h) as mut s:` | Place-based mutation |
| `remove` | `(mut self: Self, Handle[T]) -> Option[T]` | |
| `replace` | `(mut self: Self, Handle[T], T) -> Option[T]` | |
| `for_each` | `(self: &Self, fn(Handle[T], &T))` | |
| `get_disjoint` | `with sm.get_disjoint(h1, h2) as mut (a, b):` | Panics if equal |
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
provides scoped access. The compiler ensures the binding cannot
escape the block — the guard is released when the block exits.

```
with lock.read() as data:
    data.iter() |> filter(x => x.active) |> count()

with db.connection() as conn:
    conn.query("SELECT * FROM users WHERE id = ?", user_id)

with world.entities[player_id] as mut player:
    player.health -= damage
    player.last_hit = now()
```

`with` is built-in compiler semantics. The binding is scoped to
the block — it cannot escape. The `as mut` variant creates a
mutable binding; without `mut`, the binding is read-only.

```
with lock.read() as data: body
// data is scoped to block, read-only

with store.write() as mut data: body
// data is scoped to block, mutable
```

Multiple bindings are flat, nesting left-to-right:
```
with a.read() as textures,
     b.read() as meshes,
     c.write() as mut materials:
    body
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

**Return rule:** `with expr as mut x:` **always returns `x`** (the
builder), regardless of the type of the body's last expression. One
construct, one meaning — the block's result never silently changes
because a setter gained or lost a return value.

```
// Builder: always returns c
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3

// Methods that return values are fine — their results are
// discarded, and the block still returns c:
let config = with Config.default() as mut c:
    c.headers.insert("Auth", tok)   // returns Option[V], discarded
    c.timeout = 30

// To extract a computed value, bind the builder, then compute:
let v = with Vec.new() as mut v:
    v.push(1)
    v.push(2)
let len = v.len()
```

For a scoped computation whose result is something other than the
binding, use Form 3 (`with expr as name:`, §7.3), whose result is
the body value.

The value is bound as a mutable local inside the block.

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
    if len > 1e-6: vec.scale(1.0 / len) else: Vec2.zero()
```

When `mut` is absent, the value is bound as an immutable local.

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

`std.context` defines the standard context shape for common execution
services. `Context` is ephemeral and currently carries a temporary
arena, logger, cancellation token, and trace id. Library APIs that need
these cross-cutting services should accept an `implicit Context`
parameter instead of adding unrelated positional parameters.

```
use std.context

fn trace_id(ctx: implicit Context) -> i64:
    ctx.trace_id.value

with active(default_context()):
    let id = trace_id()
```

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

Full `with` dispatch is syntax-first, type/protocol-driven, and
`mut`-refined.

1. The parser first distinguishes the syntactic shape:
   `with e`, `with e as x`, `with e as mut x`,
   `with name(expr):`, and record-update forms.
2. For forms that can be either guarded access or plain binding,
   the expression's type and protocols decide the path. If the
   expression implements a guarded-access protocol such as `Scoped[T]`
   or `ScopedMut[T]`, the form is guarded. Otherwise it is a plain
   scoped binding.
3. `mut` refines mutability within the selected path. It is not the
   global dispatcher.

```
// Plain binding path
with expr as name:                 →  { let name = expr; body }
with expr as mut name:             →  { var name = expr; body; name }
```

In the guarded path, the guard protocol supplies acquire/release
behavior and the payload type. `mut` requests mutable access to the
guarded value and must be supported by a mutable guard capability. For
example, `with lock.read() as mut data:` is invalid if `lock.read()`
produces only an immutable guard; the keyword does not select a
different protocol.

```
// Guarded access — lock.write() returns a guard
with lock.write() as data:
    data.x = 1                         // guard released at block exit

// Builder — plain scoped mutation
let config = with Config.default() as mut c:
    c.retries = 3

// Implicit context
with context(default_context()):
    log("started")
```

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

The compiler rejects any same-fiber operation that may suspend the
current fiber while a `@[no_await_guard]` value is **live in the NLL
sense** — regardless of whether it was created via `with` or a plain
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
    //           ^^^^^^ same-fiber may_suspend call while
    //                  @[no_await_guard] ReadGuard is live

// FIX: drop guard before awaiting
let snapshot = with lock.read() as data:
    data.clone()
// guard dropped here
let result = fetch(snapshot.url).await   // OK: no guard live
```

Other guarded types — connection pools, transactions, file handles
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

### 8.3a Temporary Arenas

`std.alloc` provides `TempArena` for short-lived scratch allocation:

```
use std.alloc

let scratch = scratch_arena()
with scratch as mut arena:
    let bytes = arena.alloc(1024)
    use_scratch(bytes)
```

`scratch_arena()` returns a fresh `TempArena`. `TempArena.alloc(size)`
and `TempArena.alloc_zeroed(count, size)` allocate raw memory and
record it in the arena. `TempArena.reset()` frees all allocations made
through that arena and clears the allocation list. `TempArena` also has
a destructor that calls `reset()`, so a scoped arena created for a
block releases its allocations when the arena value goes out of scope.

`TempArena` is distinct from the longer-lived arena types:

| Type | Reset authority | Primary use case |
|------|-----------------|------------------|
| `Arena` | User-controlled reset/drop | Long-lived region allocation |
| `FrameArena` | External reset per frame/tick | Game loops, render passes |
| `TempArena` | Lexical owner scope or explicit `reset()` | Scratch computation |

References or containers that borrow arena-backed storage follow the
normal ephemeral rules: they cannot be stored somewhere that outlives
the arena scope.

### 8.4 Convenience Type

```
type Shared[T] = Arc[RwLock[T]]
```

Usable with `with` blocks for scoped access.

---

## 9. Functions and Expressions

### 9.1 Functions

```
fn add(a: i32, b: i32) -> i32: a + b

fn clamp(x: i32, lo: i32, hi: i32) -> i32:
    if x < lo: lo
    else if x > hi: hi
    else: x
```

**Syntax:**

```
fn NAME(PARAMS) -> TYPE: BODY    // parameters + return type
fn NAME(PARAMS): BODY            // parameters, returns Unit
fn NAME -> TYPE: BODY            // no parameters, has return type
fn NAME: BODY                    // no parameters, returns Unit
```

Function bodies support three interchangeable forms (§29.13):

```
fn NAME(PARAMS) -> TYPE: BODY    // inline or indented colon
fn NAME(PARAMS) -> TYPE { BODY } // braced
```

Parentheses are required when a function takes parameters. When a
function takes no parameters, parentheses may be included or
omitted — `fn greet:` and `fn greet():` are both legal. The
idiomatic style omits them. The return type `-> TYPE` is omitted
when the function returns `Unit` (void). The body is introduced by
`:` (colon form) or `{ }` (brace form) — see §29.13 for the full
rules.

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

`if` supports the three normal body forms. `else if` is a two-token keyword pair
that continues the chain; `else` without `if` ends it:

```
// Inline colon — body introducer is ':'
if x < 0: handle_negative()
else if x == 0: handle_zero()
else: handle_positive()

// Inline colon expression arms
let y = if x > 0: x else if x == 0: 0 else: -x
let clamped = if x < lo: lo else if x > hi: hi else: x

// Indented colon
if x < 0:
    handle_negative()
else if x == 0:
    handle_zero()
else:
    handle_positive()

// Braced
if x < 0 { handle_negative() } else if x == 0 { handle_zero() } else { handle_positive() }
```

Every `if`, `else if`, and `else` arm uses a normal body introducer:
inline colon, indented colon, or braces. There is no `then` body form,
and a naked `else expr` is not valid; write `else: expr` or `else { expr }`.

```
let clamped =
    if x < lo:
        lo
    else if x > hi:
        hi
    else: x
```

`else if` is always parsed as a chain continuation — the parser
consumes `else`, sees `if`, and continues the same chain rather than
nesting an `if` inside the else body. The forms may be mixed freely
within a single chain. `else` is required in expression position
unless the if-branch is `Never`-typed.

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
- Parameter names of `pub` functions are part of the API surface:
  renaming a `pub` parameter is a breaking change for named call
  sites.
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
const MAX_SIZE = 1024
const PI = 3.14159
const HEADER: str = "X-Custom"
```

**Syntax:** `const NAME [: TYPE] = EXPR`

The type annotation may be omitted when the initializer determines an
unambiguous type. If omitted, ordinary expression inference and default
literal rules choose the type. The annotation is required when the
initializer cannot determine a concrete type, and public exported constants
must include an explicit type so the API surface is stable.

`const NAME: TYPE = EXPR` remains the spelling for API clarity and
disambiguation. Use it whenever the default literal type would be
surprising.

The expression must be evaluable at compile time — integer literals,
arithmetic (`+`, `-`, `*`, `/`, `%`), unary negate, logical `not`, and
references to other `const` values.

```
const WIDTH = 80
const HEIGHT = 24
const AREA = WIDTH * HEIGHT    // computed at compile time

pub const PROTOCOL_VERSION: u16 = 3
```

`const` values are inlined at every use site. They have no runtime address and
cannot be mutated. They may appear at module scope or inside function bodies.

**Difference from `let`:** `let` bindings are runtime values (even if initialized
from a constant). `const` values are guaranteed to be compile-time constants and
are always inlined.

### 9.1c Global Declarations

Module-level runtime state is declared with `global`:

```
global cache = Cache.new()        // stable binding: cannot be rebound
global var current: Option[User] = None   // rebindable binding
```

`global` is the module-level analog of `let`; `global var` is the
analog of `var`. A stable `global` cannot be reassigned, but its
value may still mutate through `mut self` methods, field assignment,
or `IndexPlace` writes if the type supports them. A `global var` may
additionally be reassigned to a new value of the same type.

**Initialization.** Global initializers are ordinary expressions.
They run before `main`, on the initial thread, in declaration order
within a module. Because concurrency in With can only be created by
program code (§14, Invariant 3), initialization is race-free by
construction.

**Safety rule (data races).** Globals are places; §21.1's access
rules apply. Cross-thread safety is usage-based — the compiler
proves what it can, and asks for `unsafe` only past the proof:

1. **Never-mutated globals are always safe.** If the program never
   mutates a global after initialization (no reassignment, no
   `mut self` call, no field or index write, no mutable borrow),
   every read is race-free and requires nothing.
2. **Synchronized globals are always safe.** Globals of `Sync`
   synchronization types — `Atomic[T]`, `Mutex[T]`, `RwLock[T]`, and
   other types whose mutation flows through their own thread-safe
   APIs — are safe in all programs. This is the idiom for shared
   mutable state (§12.3 of the mutability model: scoped
   synchronization via `with`).
3. **Bare mutation is safe iff the program is provably
   single-threaded.** Mutating any other global (rebinding or
   interior mutation), and reading a global that is mutated anywhere,
   is safe when the compiler proves the program never gains
   concurrency. The proof obligations are enumerable, because With
   has exactly one concurrency source (§14, Invariant 3): the program
   uses no `async` construct, never calls `thread.spawn_os`, exports
   no `@[c_export]` symbols, and coerces no With function to an
   `extern "C"` callback. When the proof fails, each such access
   requires an `unsafe` context — the programmer is asserting the
   absence of a data race the compiler cannot prove, exactly as with
   raw pointers (§16.11).

The diagnostic for a failed proof must name the construct that
introduced concurrency and offer the remedies (wrap in `Atomic` /
`Mutex`, or `unsafe`):

```
error[E0921]: mutation of global `counter` may race
  --> src/serve.w:40:5
   |
40 |     counter += 1
   |     ^^^^^^^^^^^^ global mutated here
   |
  ::: src/serve.w:12:9
   |
12 |     let task = handle(conn)     // program creates fibers here
   |
   = help: use Atomic[i32], wrap in Mutex, or assert with `unsafe`
```

The proof is a whole-program analysis and may be conservative; a
conservative implementation may treat the proof as failed whenever it
cannot establish all obligations. Improving its precision is compiler
quality work (§22.3), never a semantic change: strengthening the
proof only makes more programs safe.

Migrated C globals (`with migrate`) translate to `global` /
`global var` and land under these same rules — single-threaded C
programs translate without ceremony; concurrent ones surface their
shared state loudly, which is the raw-stays-explicit contract
(§16.1).

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
- `return f(...)` only when the call result can be returned directly
  with no post-call coercion, wrapping, storage, cleanup, or ABI
  reshaping

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

In the currently guaranteed mutual-recursion subset, every recursive
edge in the SCC must be in verified tail position, every member of the
SCC must have a compatible signature and calling convention, and no
active `defer` or `errdefer` cleanup may remain across the recursive
edge. When those conditions are not met, the compiler must reject the
program rather than falling back to ordinary stack-growing calls.

The full `@[tailrec]` contract, diagnostics, ABI constraints, and
current guaranteed lowering subset are specified in
`docs/tco-spec.md`.

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
| `mut self: Self` | `x.method()` | Mutates `x` in place |
| `move self: Self` | `x.method()` | Moves (consumes) `x` |

**Consuming `self` enables consuming method chains:**

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
- **`@[must_use]` types** (e.g. `Task`): match must always be
  exhaustive or include an explicit `_ => ...` catch-all arm, regardless
  of position. Partial match on a `@[must_use]` type is a compile error.
  `Result` is **not** `@[must_use]`: discarding or partially matching a
  `Result` carries no obligation (§10.1) — a statement-position match
  on `Result` follows the ordinary partial-match rule. (An opt-in lint
  may flag partial statement matches for projects that want
  exhaustiveness everywhere.)

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

// statement-position on Result: partial match is allowed (§10.1)
match result:
    Ok(v) => process(v)
// unmatched Err arms are a no-op — no catch-all required
```

**Reference pattern ergonomics:** When a pattern is matched against
a reference type `&T`, the pattern automatically binds variables as
references to the inner fields. No explicit `&` is needed in the
pattern:

```
let items: Vec[(str, i32)] = [("alice", 1), ("bob", 2)]

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
| 3 | `==`, `!=`, `in`, `not in`, `=~`, `!~` | Non-associative |
| 4 | `<`, `>`, `<=`, `>=` | Chained |
| 5 | `\|>` (pipeline) | Left |
| 6 | `\|` | Left |
| 7 | `^` | Left |
| 8 | `&` | Left |
| 9 | `<<`, `>>` | Left |
| 10 | `+`, `-`, `++`, `??` | Left |
| 11 | `*`, `/`, `%`, `@` | Left |
| 12 | Unary prefix (`not`, `-`, `~`, `&`, `&raw mut`) | — |
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
enum Result[T, E] { Ok(T) | Err(E) }
enum Option[T] { Some(T) | None }
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
let inputs: Vec[Option[i32]] = [Some(1), Some(2), Some(3)]
let result = inputs.sequence()       // Some([1, 2, 3])

let bad: Vec[Option[i32]] = [Some(1), None, Some(3)]
let result = bad.sequence()          // None

// Vec[Result[T, E]] → Result[Vec[T], E]
let results: Vec[Result[i32, str]] = [Ok(1), Ok(2), Ok(3)]
let all = results.sequence()         // Ok([1, 2, 3])

let mixed: Vec[Result[i32, str]] = [Ok(1), Err("bad"), Ok(3)]
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
| `IndexGet[I, O]` | Subscript read | `expr[index]` |
| `IndexPlace[I, O]` | Subscript read/write (place) | `expr[index] = val` |
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
enum ParseResult[T]:
    ParseOk(T, remaining: str)
    ParseErr(msg: str, pos: usize)

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
let closures = [x => x]  // stored in a container: escaping
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

### 12.4 Capture Semantics and Effects

Closure captures are **by place**. Unlike function parameters
(§3.8), whose mode is declared in the signature, a closure body sits
lexically next to the variables it captures — by-place capture stays
visible to the reader, so no signature is needed:

- For `Copy` values, default capture copies the value.
- For non-`Copy` values, default capture is by place: the closure
  observes or mutates the original place according to its body.
- `move ||` captures transfer ownership into the closure.

Closure bodies receive inferred effect summaries over their captures.
Invoking a closure is checked exactly like invoking a function: if a
closure consumes, mutates, returns, or returns a view derived from a
capture, those effects apply to the originating captured place.

```with
let xs = Vec.new()
let f = || xs.push(1)   // capture effect on xs: {write}
f()                     // mutates xs

let n = 42
let g = || n + 1        // n is Copy, captured by copy
let m = g()             // n remains unchanged

let owned = Vec.from([1, 2, 3])
let h = move || owned.len()
// owned is invalid after closure creation
```

---

## 13. Iteration and Collection Operations

### 13.1 Iterators Over Borrowed Data Are Ephemeral

Iterators holding references to collections are ephemeral. They can be
used in pipelines within scope but not stored, returned, or captured by
escaping closures.

**What this means in practice:** You cannot return an *opaque* lazy
iterator that borrows from its inputs (e.g., `-> dyn Iter[StrView]`
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
    fn next(mut self: Self) -> Option[T]
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

**Iterators just work — for every library, not just the stdlib.**
The mechanism is the `@[iter_of_self]` attribute on an
iterator-returning method: it declares that the returned iterator
borrows the *receiver* (the underlying collection), not the iterator
struct itself. The registered borrow on the receiver is shared, lives
as long as the iterator, and is the origin of any references the
iterator's `next()` yields. The stdlib applies it to `Vec.iter()`,
`HashMap.iter()`, and the other collection iterators; any library may
apply it to its own iterator constructors (tensor views, ECS queries,
dataset readers). Future versions may infer this property from the
constructor body; the semantics are normative either way. This means
normal iteration patterns work naturally:

```
let iter = names.iter()
let a = iter.next()   // borrows from names, not iter
let b = iter.next()   // OK — iter is not locked by a
process(a, b)         // both references live simultaneously
```

`for` loops, `.zip()`, `.peekable()`, `.windows()` — all work as
you'd expect. A custom iterator constructor without `@[iter_of_self]`
falls back to conservative borrowing (the iterator value itself is
treated as holding the borrow), which is safe but may reject patterns
the attribute would allow.

### 13.3 Collection Operations (Standard Library)

The collection surface is one integrated design at three altitudes:
literals (§4.3c) when the elements are known, comprehensions (§13.6)
when iteration has a shape, and these pipeline operations for
everything else. The operation set is deliberately lodash-grade —
grouping, chunking, deduplication, and partitioning are standard
vocabulary, not exotica — and everything funnels through the same
`collect[C]` targets the literals and comprehensions use.

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
return type. The function actually returns a **compiler-generated
iterator type** implementing `Iter[T]` — the generator's state
struct, whose name is not denotable in source. This is analogous to
`async fn f -> T` meaning "returns `Task[T]`" — the keyword modifies
the return type's meaning:

```
gen fn fibonacci -> Int: ...
// Actual type of fibonacci(): a generated iterator implementing Iter[Int]
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
    print(f"{key} = {value}")

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

// For place-based or consuming iteration, be explicit:
for item in my_vec.iter_place():  // yields VecSlot handles for in-place mutation
for item in my_vec.iter_ref():    // yields &T references (zero-copy)
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
`break value` and `break 'label value` are valid when the targeted
construct is a `loop` (§13.5d), where they supply the loop's result
value. For `while`, `for`, `do`-`while`, and labeled blocks,
value-carrying break remains reserved for a future design and is
invalid in this version (those constructs can complete without
`break`, so they have no value to guarantee).

`break 'label` transfers control to the statement immediately after
the construct labeled `'label`. The target label must be declared on
a labeled `while`, labeled `for`, or labeled block that lexically
encloses the `break`.

`continue 'label` transfers control to the next iteration of the
loop labeled `'label`. For a `while` loop, this means the condition
check. For a `for` loop, this means the iterator-advance or
next-element step. For a `do`-`while` loop, this means the trailing
condition check (§13.5c). The target label must be declared on a
labeled `while`, `for`, or `do` that lexically encloses the
`continue`.

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
prefer structured With using `while`, `do`-`while` (§13.5c), `if`,
labeled `break`, and labeled `continue`. In particular, C
`do { ... } while (cond)` loops should be translated directly to
With `do: ... while cond`, preserving `continue`-to-condition
semantics. For irreducible C, each basic block may become a
labeled statement at function scope, and each control-flow edge may
become a `goto` or conditional `goto`.

Computed goto (`goto *ptr`) and non-local jumps such as
`setjmp`/`longjmp` are not supported. If `with migrate` encounters a
function that requires one of those patterns, it must emit a
diagnostic naming the function and source location, produce no
misleading placeholder translation, and exit non-zero.

### 13.5c `do`-`while` Loop

A `do`-`while` loop executes its body at least once, then repeats
while the trailing condition is true.

```
do_loop := 'do' body 'while' condition
```

The body uses the standard three forms:

```
// Indented colon
do:
    stmt1
    stmt2
while condition

// Braced
do {
    stmt1
    stmt2
} while condition

// Inline colon (single statement)
do: stmt
while condition
```

The `while` keyword following the body introduces the loop
condition. It is not a separate `while` loop — the parser
recognizes `while` at the same nesting level as `do` as the
loop's trailing condition, not as a new statement.

No colon or brace follows the trailing `while` — the condition
is a single expression terminated by a newline or the end of the
enclosing block.

**Semantics:**

1. The body executes unconditionally on the first iteration.
2. After each iteration, the condition is evaluated.
3. If the condition is true, the body executes again.
4. If the condition is false, the loop exits.

`break` exits the loop immediately.

`continue` jumps to the **condition check**, not to the top of
the body. This matches C semantics: any side-effects in the
condition expression are executed on every `continue`.

```
// Equivalent to C: do { ... continue; ... } while (*(++p))
var p = start
do:
    if should_skip:
        continue        // jumps to the while condition below
    process(p)
while { p = p + 1; unsafe *p != 0 }
```

**Labeled form:**

`do` loops may be labeled for use with `break` and `continue`:

```
'outer do:
    'inner do:
        if done: break 'outer
        if skip: continue 'inner
        process()
    while inner_condition
while outer_condition
```

**Type:**

A `do`-`while` loop is a statement. It does not produce a value.
Unlike `loop` (which can produce a value via `break expr`), a
`do`-`while` loop always evaluates to `Unit`.

**Condition with side-effects:**

The trailing condition may contain side-effects. When the
condition is a block expression (braced), all statements in the
block execute before the truthiness of the final expression
determines whether to continue looping:

```
do:
    process(current)
while { current = current.next; current != null }
```

This is the direct translation of C's:

```c
do {
    process(current);
} while ((current = current->next) != NULL);
```

When the condition is a simple expression, it is evaluated
normally:

```
do:
    attempt()
while retry_count > 0
```

**Desugaring:**

The compiler treats `do`-`while` as a primitive loop form, not
as syntactic sugar over `loop`. This ensures `continue` has the
correct target (the condition check, not the body top).

Conceptually, the semantics are equivalent to:

```
loop:
    body
    if not condition: break
```

except that `continue` anywhere in `body` jumps to the condition
evaluation, not to the top of `loop`. This distinction only
matters when the body contains `continue` statements.

**Interaction with `defer` and `errdefer`:**

`defer` statements inside the body execute at scope exit as
usual — either when the loop exits via `break`, when the
enclosing function returns, or at the end of a braced body on
each iteration.

`errdefer` follows the same scoping rules as in other loop
bodies.

**Examples:**

Retry loop:

```
var attempts = 0
do:
    attempts = attempts + 1
    let result = try_connect(host)
    if result.is_ok():
        return result
while attempts < max_retries
return Err(.MaxRetriesExceeded)
```

Processing a non-empty list:

```
var node = list.head
do:
    process(node.value)
    node = node.next
while node != null
```

Iterator with lookahead:

```
var p = start
do:
    let ch = unsafe *p
    if ch == delimiter: break
    buffer.push(ch)
while { p = p + 1; p < end }
```

C migration — PCRE2 list iteration:

C source:
```c
do {
    if (*list < new_start) {
        if (*list + 1 == new_start) { new_start--; continue; }
    } else if (*list > new_end) {
        if (*list - 1 == new_end) { new_end++; continue; }
    } else {
        continue;
    }
    result += 2;
    if (buffer != NULL) {
        buffer[0] = *list;
        buffer[1] = *list;
        buffer += 2;
    }
} while (*(++list) != NOTACHAR);
```

With translation:
```
do:
    if (unsafe *list) < new_start:
        if (unsafe *list) + 1 == new_start:
            new_start = new_start - 1
            continue
    else if (unsafe *list) > new_end:
        if (unsafe *list) - 1 == new_end:
            new_end = new_end + 1
            continue
    else:
        continue
    result = result + 2
    if buffer != null:
        unsafe buffer[0] = unsafe *list
        unsafe buffer[1] = unsafe *list
        buffer = buffer + 2
while { list = list + 1; (unsafe *list) != NOTACHAR }
```

No `goto` required. `continue` correctly jumps to the `while`
condition, which increments `list` and checks the terminator.

### 13.5d The `loop` Construct

`loop` is the infinite loop. It supports the three standard body
forms (§29.13) and may be labeled (§13.5a):

```
loop:
    tick()
    if done(): break

'outer loop { poll(); if quit(): break 'outer }
```

**`loop` is an expression.** `break expr` supplies its value; plain
`break` supplies `Unit`. The loop's type is the unified type of its
`break` values. A `loop` with no reachable `break` has type `Never`
and may appear anywhere a diverging expression is valid:

```
let session = loop:
    let attempt = try_connect(host)
    if attempt.is_ok():
        break attempt.unwrap()      // loop evaluates to Connection
    sleep(backoff()).await

fn serve -> Never:
    loop:
        accept_and_handle()         // no break: type is Never
```

`break 'label expr` targets a labeled `loop` the same way. All
`break` values within one loop must unify to a single type (plain
`break` contributes `Unit`); mixing valued and plain breaks where the
type is not `Unit` is a compile error. `continue` behaves as in other
loops. `while`, `for`, and `do`-`while` loops are statements and do
not produce values (§13.5a, §13.5c).

### 13.6 Collection Comprehensions

Comprehensions build collections from iteration with filtering.
There is **one comprehension family, polymorphic over its target
collection** (the Scala lesson: don't invent a syntax per container).
The element form builds sequences and sets; the `key: value` form
builds maps. The target is selected by expected type — the same
inference rule as enum variant shorthand (§4.4) and numeric literals
(§4.2.1) — with `Vec` and `HashMap` as the defaults:

```
let squares = [x * x for x in 0..10]
// Vec[i32]: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]

let evens = [x for x in 0..100 if x % 2 == 0]
// Vec[i32]: [0, 2, 4, ..., 98]

let coords = [(x, y) for x in 0..3 for y in 0..3 if x != y]
// Vec[(i32, i32)]: [(0,1), (0,2), (1,0), (1,2), (2,0), (2,1)]

// Expected type selects the target collection:
let words: HashSet[str] = [w for w in tokens]
let ordered: BTreeSet[i32] = [x for x in xs if x > 0]

// Map form: key-colon-value builds a map (HashMap by default)
let index = [w: i for (i, w) in vocab.enumerate()]
let sorted_index: BTreeMap[str, i32] = [w: i for (i, w) in vocab.enumerate()]
```

**Desugaring:**

```
[expr for x in iter if cond]
// →
iter |> filter(x => cond) |> map(x => expr) |> collect[C]()
// where C is the expected collection type, defaulting to Vec

[k_expr: v_expr for x in iter if cond]
// →
iter |> filter(x => cond) |> map(x => (k_expr, v_expr)) |> collect[M]()
// where M is the expected map type, defaulting to HashMap
```

Yes, this allocates. It's obvious from the syntax — you're building
a collection. This is the same philosophy as string interpolation:
the allocation is inherent to what you're asking for, and the syntax
makes it clear.

Comprehensions are pure sugar over the pipeline operations of §13.3
and `collect[C]` — the same machinery, three altitudes: literals
(§4.3c) for known elements, comprehensions for shaped iteration,
pipelines for everything else. For lazy evaluation, use pipeline
syntax with iterators directly.

For duplicate keys in a map comprehension, later elements win
(last-write semantics, matching repeated `insert`).

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

   **Controlled exception:** Explicit cancellation or cleanup of an
   ephemeral `Task` may yield the current fiber (§14.7) to ensure
   memory safety. This is the only implicit suspension point in the
   language. The compiler does not silently detach ephemeral tasks:
   a task expression in statement position may detach only when the
   detach-safety check proves the task can outlive the current scope.
   If that proof fails, the statement is a compile error and the task
   must be awaited, cancelled, returned, or tracked before scope exit.
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
Only current-fiber suspension operations are gated; plain async calls
that only create a `Task[T]` are not.

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
With does not choose syntactic suspension visibility. It chooses
compiler suspension visibility. The compiler statically computes a
**`may_suspend`** property for every function and for callable type
information. Suspension need not be written at every call site, but it
must always be known to the compiler and surfaced in diagnostics when
it matters.

`may_suspend` is a **current-fiber** property, and fiber creation is
the firewall. A function is `may_suspend` if it directly performs a
primitive current-fiber suspension, or if it makes a same-fiber call
through a callable whose type is `may_suspend`. Calling an `async fn`
does not by itself make the caller `may_suspend`: it creates or starts
a separate fiber and returns a `Task[T]`. The caller suspends only if
it awaits, joins, performs async-scope cleanup, or otherwise invokes a
current-fiber suspension operation.

The primitive current-fiber suspension set is closed and deterministic:

- `.await`;
- collection / select await;
- explicit yield primitives;
- async-scope await-all and other structured-concurrency joins;
- implicit cleanup await at scope exit for a live ephemeral task;
- fiber-aware runtime operations that yield the current fiber when they
  cannot complete immediately: lock acquire when unavailable, channel
  send when full, channel receive when empty, timer/sleep until its
  deadline, and socket/file read or write when not ready.

Fiber-aware I/O and synchronization must choose one model explicitly:
either the operation is a direct current-fiber suspension primitive and
therefore participates in `may_suspend`, or it returns a `Task` and
suspends only when that task is awaited. The specification must not
leave that boundary ambiguous.

`may_suspend` is part of callable type information for function
pointers, closures, trait and `dyn` callables, callbacks, and every
other indirect-call surface. This does not reintroduce call-site
coloring: ordinary calls remain unannotated, and the typing burden
appears only when a function becomes a value.

Specific safety contexts enforce constraints based on current-fiber
suspension:

1. **`@[no_await_guard]` enforcement:** Making a same-fiber
   `may_suspend` call while a `@[no_await_guard]` guard is live is a
   compile error — even if the `.await` or yield primitive is buried
   three calls deep.
2. **FFI callback safety:** Functions passed as `extern "C"`
   callbacks must not be `may_suspend` (see §14.19).
3. **`no_suspend` blocks:** Expert code may assert that a region
   contains no operation that yields to the scheduler. The compiler
   rejects direct `.await`, collection/select await, same-fiber
   `may_suspend` calls, structured-concurrency joins, implicit cleanup
   awaits, and direct fiber-aware runtime operations in that region.

Programmers do not declare or annotate `may_suspend`. The compiler
computes it internally; it may appear in diagnostics when a safety
violation occurs. There are no separate `async` and `sync` function
types and no trait split. Callable values still carry whether invoking
them may suspend the current fiber, because indirect calls must be
checkable.

```
fn helper:
    some_io().await        // makes helper() may_suspend

with lock.write() as data:
    helper()               // ERROR E0701: same-fiber may_suspend call
                           // while @[no_await_guard] WriteGuard is live
    data.x = 1             // OK: no suspension
```

#### 14.3.1 `no_suspend` Blocks

`no_suspend` is an expert assertion for code that must not yield to
the fiber scheduler:

```
no_suspend:
    update_intrusive_state()
    poll_fast_path()

let inline_value = no_suspend: compute_without_waiting()

let value = no_suspend {
    compute_without_waiting()
}
```

The body is otherwise an ordinary expression block: it has the type of
its tail expression and participates in inference normally. Creating an
async task handle is allowed because calling an `async fn` returns a
`Task[T]` immediately; actually awaiting that task inside the block is
not allowed.

The compiler rejects any scheduler-yielding operation inside the block,
including:

- direct `.await`, collection await, or `select await`
- same-fiber calls through `may_suspend` callables
- async-scope await-all and other structured-concurrency joins
- implicit cleanup await for an ephemeral `Task`
- direct fiber-aware runtime operations that may yield the current
  fiber

This check exists because suspending inside such a region can deadlock
or expose partially-updated state to other fibers. It is independent of
whether the compiler implements fibers with real stacks or state
machines.

### 14.4 `async fn` Semantics

```
async fn fetch(url: str) -> Result[String, IoError]: ...
```

Calling `fetch(url)` does the following:

1. Allocates a lightweight thread (fiber) with its own stack.
2. Begins executing the function body on that fiber.
3. Returns a `Task[Result[String, IoError]]` handle immediately
   to the caller.

The fiber runs concurrently. It suspends at compiler-known
current-fiber suspension points and is resumed by the scheduler when
the awaited operation or runtime wait completes.

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

`.await` is the primary explicit suspension operator for observing a
single `Task[T]` result. Tuple `.await`, collection await combinators,
and `select await` are also result-observing suspension forms for
multiple tasks.

`.await` is not the only operation that can suspend the current fiber.
Any operation classified by the compiler as `may_suspend` may yield the
current fiber. Suspension is always known to the compiler and surfaced
in diagnostics, but it is not necessarily spelled at every call site.

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
| `was_cancelled` | `(&Task[T]) -> bool` | True if the task was cancelled before completing normally; never suspends |

`Task[T]` has one type spelling. Storability and sendability are
properties of the task value and binding, inferred from what the task
captures and returns:

- **Ephemeral vs non-ephemeral** is the lifetime gate. A task is
  ephemeral if its captured environment or result contains references,
  allocator-borrowed values, scope-bound resources, or any other
  ephemeral value.
- **Storable** means the task may be placed in long-lived data. A task
  is storable iff it is non-ephemeral. Storage alone does not require
  `Send`; a non-`Send` task may be stored in same-thread data, and that
  container is then itself non-`Send`.
- **Sendable** means the task may cross a thread boundary. A task is
  sendable iff it is non-ephemeral, `T: Send`, and its captured
  environment is `Send`.

A `Task[T]` that captures references is **ephemeral** (see §14.22).
Ephemeral tasks cannot be stored, returned, or sent to other threads.
They must be awaited or tracked in a scope before the borrowed data
goes out of scope.

**Task disposition:** A `Task` handle represents running work. The
compiler uses syntactic position as the programmer's intent.

A `Task` in **statement position** is intentional fire-and-forget
detachment:

```
send_analytics("page_view")  // detach if both checks below pass
```

This means: start the work, do not await it, and discard interest in
its result or failure. It is allowed only when two independent checks
both pass:

1. **must-observe:** the API author has not marked the task's
   completion or failure as requiring observation.
2. **detach-safety:** the compiler proves the task may safely outlive
   the current scope. It must not carry borrowed stack data, ephemeral
   captures, allocator-borrowed or scope-bound resources, or structured
   concurrency cleanup obligations out of the scope that owns them.

Author intent never substitutes for the lifetime proof, and the
lifetime proof never overrides author intent. Both gates must clear.

When statement-position detachment fails, the compiler emits a hard
error naming the failed check:

```
error[E0801]: task result must be observed
  --> src/service.w:42:9
   |
42 |     send_invoice(invoice)
   |     ^^^^^^^^^^^^^^^^^^^^^ this task is marked must-observe
   |
   = help: await, cancel, return, store, or otherwise handle the task

error[E0802]: task cannot be detached safely
  --> src/service.w:51:9
   |
51 |     borrow_until_done(&buffer)
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^ task captures data owned by this scope
   |
   = help: await, cancel, return, or restructure so the task no longer carries scope-bound state out of scope
```

A task **bound to a name** declares intent to observe:

```
let task = send_invoice(invoice)
task.await?
```

An unused bound task handle is a compile error. The handle must be
awaited, cancelled, returned, stored when non-ephemeral, tracked in an
`async scope`, or otherwise given a valid disposition before it is
lost.

**`let _ = task` is not the fire-and-forget spelling.** Statement
position already expresses detachment. The compiler rejects
`let _ = <Task expression>` for task values; use a bare statement for
permitted fire-and-forget work, or bind the task and call `cancel`
when cancellation is the intended effect.

See §20b.2.

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
   and absorbed at `async scope` boundaries. Awaiting a cancelled
   task never produces an `Err` value of the task's error type:
   cancellation is a control transfer, not an error value.
   Destructors and `defer` blocks run during unwinding as usual.

   ```
   async scope s =>
       let t1 = s.track(fetch_user(id))
       let t2 = s.track(fetch_posts(id))
       let user = t1.await?           // if this fails...
       // t2 is cancelled, unwinds, destructors run
       let posts = t2.await?          // cancellation unwinds through
                                      // this await to the scope
   ```

   `async scope` absorbs cancellation unwinding from its child
   tasks. No error types change. No `From` impls are needed.
   `IoError`, `DbError`, `ApiError` — they all work unchanged. There
   is no `TaskCancelled` error type and no `.is_cancelled()` method
   on errors; user error types never represent cancellation.

   To distinguish cancellation from completion or failure, observe
   the **task handle**, not the error channel:

   ```
   cancel(task)
   if task.was_cancelled():
       log("task was cancelled before producing a result")
   else:
       let value = task.await
       use(value)
   ```

   `was_cancelled(&Task[T]) -> bool` reports whether the task was
   cancelled before completing normally. It never suspends.

**Cancellation of ephemeral tasks:** If a `Task` is ephemeral
(captures references), cancelling it or unwinding the scope that owns
it must ensure the fiber has stopped before the caller proceeds. This
is mandatory for memory safety: the fiber holds references to the
caller's stack.

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
that ephemeral task cleanup happens inside fibers (which can yield),
not inside raw OS thread code.

```
var data = [1, 2, 3]
let task = process(data)
cancel(task)                // runtime ensures fiber stops before
                            // proceeding (may yield)
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
scheduler and ephemeral cleanup could need to yield. Non-ephemeral
tasks (capturing only owned values) can be created anywhere.

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

As with other block-introducing constructs, the body may use an
inline expression, an indented colon block, or a braced block:

```
async scope s => fetch().await
async scope s =>:
    fetch().await
async scope s { fetch().await }
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
`ScopedTask[T]` is ephemeral: it may be used inside the scope, but
the scope body may not return it or store it in non-ephemeral data.

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
5. The scope result cannot be ephemeral. Await or copy the value
   before it leaves the scope.

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
`s.spawn(worker)` returns a `ScopedJoinHandle`, which supports
`.join() -> i32` and is joined automatically at scope exit if it has
not already been joined. `ScopedJoinHandle` is ephemeral: it may not
leave the `scope` result or be stored in non-ephemeral data. `scope`
supports the same inline, colon, and braced body forms and is
available in `no_runtime` builds.

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
At least one branch must be present. Branch patterns are irrefutable
bindings; refutable handling belongs in the branch body via
`let ... else` (above).

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

Tuple `.await` supports tuple sizes 2..12. For dynamic or larger
sets, use collection combinators.

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
| Fire-and-forget | task expression statement (§14.7) |

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

**Latency note:** "cancels and joins" means the combinator does not
return until every losing task has actually stopped. Cancellation is
cooperative (§14.7): a loser inside a long synchronous computation
delays the combinator's return until that loser reaches its next
suspension point.

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
async fn process(mut data: Vec[i32]) -> Vec[i32]:
    let first = &data[0]
    some_io().await              // fiber suspends; reference still valid
    print(first)               // safe to use
    data.push(42)
    data
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
The conforming baseline uses fixed, non-relocating pooled stacks
(§14.19), where preservation is trivial. An implementation may
relocate or segment physical stacks only if the compiler ensures safe
references are updated or indirected transparently. Raw pointers (`*const T`, `*mut T`) obtained via
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
| `&T` | No | Yes |
| Ephemeral structs | No | Yes |
| `Task[T]` (non-ephemeral) | Yes (if `T: Send`) | Yes |
| `Task[T]` (ephemeral) | No | Yes |

### 14.17 Synchronization Primitives

- `Mutex[T]` — mutual exclusion with scoped access
- `RwLock[T]` — reader-writer lock with scoped access
- `Atomic[T]` — lock-free atomic operations
- `Condvar` — condition variable

All are usable with `with` blocks for scoped access. Lock operations
are fiber-aware: contended locks yield the fiber, not the OS thread.
Any synchronization primitive that can yield the current fiber must be
represented in `may_suspend` analysis, either as a direct
scheduler-yielding operation or as an operation returning a `Task` that
suspends only when awaited.

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
acceptable because: (a) it is opt-in via `async`, (b) current-fiber
suspension is known to the compiler and enforced by `may_suspend`
checks, and (c) `no_runtime` builds can disable it entirely.

### 14.19 Fiber Stack Management

Each fiber has a dedicated stack. Stack memory is the primary resource
cost of the fiber model and must be understood to use `async`
effectively.

**Conforming baseline: fixed-size pooled stacks.** Each fiber gets a
fixed-size stack (default 64 KB unless configured) with a guard page; stacks are
recycled through a pool, so fiber creation is a pool grab, not an
allocation. Stack overflow faults on the guard page — it never
silently corrupts memory. This is the reference implementation's
model and the behavior programs may rely on. Stack sizing is
implementation-defined configuration. The reference implementation
reads the optional `[runtime]` `with.toml` section:

```toml
[runtime]
fiber_stack_size = 131072
fiber_pool_size = 64
```

Both values are positive integers. Missing keys use implementation
defaults. `fiber_stack_size` sets the default stack size for fibers
whose call site does not provide an explicit stack size; an explicit
`@[stack_size(N)]` on an async function has higher priority.
`fiber_pool_size` caps the number of completed fiber stacks retained
for reuse; stacks completed beyond the cap are released instead of
cached. Runtime configuration is applied before the runtime is
initialized and before the first fiber spawn.

**Growable stacks (roadmap, implementation-defined):** an
implementation may start fibers on a smaller initial allocation and
grow on demand, provided growth is detected safely (e.g. stack
probes) and §14.13's semantic stack preservation holds. Growth is an
optimization, never an observable semantic — programs must be
correct under the fixed-size baseline.

**FFI stack headroom:** C code called via `c_import` has no knowledge
of With's fiber stacks and may exceed remaining stack space. Under
the fixed-size baseline, the 64 KB default provides the headroom for
typical C calls; fibers driving deep C call trees should be sized via
`fiber_stack_size`.

**FFI stack switching (roadmap, implementation-defined):** an
implementation may instead switch to an OS-thread-sized stack at the
FFI boundary:

1. The compiler marks functions as `ffi_reachable` if they (directly
   or transitively) call any `c_import` function.
2. At the FFI call site, the runtime saves the fiber stack pointer
   and switches to a pre-allocated OS-thread stack (typically 2–8 MB)
   from a per-thread pool.
3. The C function executes on the full-size stack.
4. On return, the runtime restores the fiber stack pointer.

The stack switch costs approximately 10–50 ns (save/restore a few
registers) — honest overhead: not zero-cost, but predictable and
safe. Pure-With fibers that never call C code pay nothing. The
`@[ffi_stack]` attribute is reserved for this mode: it forces an
entire function to run on an OS-thread stack, avoiding per-call
switching. Neither the switching nor the attribute is part of the
conforming baseline.

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

// OK: start a detached task (no .await needed)
unsafe { c_on_event(event =>
    handle_event(copy_event(event))   // detached if both checks pass
) }
```

**Memory budget:**

| Model | Per-task overhead | 100K concurrent tasks |
|-------|------------------|----------------------|
| Rust stackless futures | ~state machine size | ~state machine sizes |
| With fibers (64 KB pooled) | 64 KB virtual per fiber | ~6.4 GB virtual / resident scales with touched pages |
| OS threads (8 MB typical) | ~8 MB | Not viable |

The headline number is virtual address space, not resident memory —
a fiber's resident cost is only the stack pages it has actually
touched. Realistic suspended fibers doing typical I/O work often use
less than 2 KB of actual stack. (A growable-stack implementation,
§14.19 roadmap, reduces the virtual footprint too.)

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
| **Suspends** | At `yield` | At compiler-known current-fiber suspension points |
| **Driver** | Caller calls `next()` | Fiber scheduler |
| **Allocation** | Stack at call site | Heap stack per fiber |
| **Storable** | Yes (if no captured refs) | Task handle; storable only when non-ephemeral |
| **Sendable** | Yes if state is `Send` | Only when non-ephemeral, `T: Send`, and captures are `Send` |
| **`no_runtime` builds** | Works | Compile error |

`gen fn` compiles entirely away — the compiler rewrites it into a
struct and a `next()` method. It has no scheduler dependency and
works in `no_runtime` builds. It cannot use `.await`.

`async fn` allocates a fiber with a real stack and requires the fiber
runtime. It can suspend at compiler-known current-fiber suspension
points and be driven by the scheduler.

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
        handle_connection(conn)

async fn handle_connection(conn: TcpStream):
    let req = http.parse_request(&conn).await

    let response = match req.path_str():
        "/users" =>
            let users = db.query("SELECT * FROM users").await
            http.json_response(200, users)
        "/health" =>
            http.text_response(200, "ok")
        _ =>
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
async fn process(data: &Vec[i32]) -> Unit: ...
let task = process(&my_vec)            // captures &my_vec
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
passed to functions — by reference or by value — only when the
compiler can prove the value remains within its valid scope, or when
the callee's effect summary propagates the ephemerality/origin
information to its result. Ephemerality is part of With's safety
contract: if the compiler cannot prove that an ephemeral value's
origin outlives every use, the program is not safe With code.

Clear ephemeral escapes are compile errors. Ambiguous or unproven
ephemeral escapes are also compile errors, because ambiguity means the
compiler cannot prove safety. The user can resolve the error by
keeping the value within scope, returning it with propagated
ephemerality, converting or copying into owned data, or crossing an
explicit `unsafe` boundary.

```
fn process_task(t: Task[i32]):
    t.await                          // OK: consumes the task

fn store_globally(t: Task[i32]):
    GLOBAL_TASKS.push(t)            // ERROR: storing a value that
                                     // may be ephemeral at some call sites

var v = [1, 2, 3]
let task = process(&v)              // ephemeral task
process_task(task)                   // OK: compiler sees task is consumed
store_globally(task)                 // ERROR: compiler cannot prove the
                                     // ephemeral task stays in scope
```

Warnings are appropriate for weird-but-safe code, performance
guidance, style, or suspicious but semantically valid patterns. They
are not sufficient when accepting the program could produce a dangling
reference, cross-thread borrowed value, detached ephemeral task, or
erased origin.

**Ephemeral tasks CAN be returned from functions** — the caller's
binding inherits the ephemerality (Rule 8, §22.1). This is
essential: `async fn get_profile(self: &UserService)` returns a
`Task` that captures `&self`. The returned task is ephemeral at
the call site, preventing the caller from storing it or outliving the
referenced data:

```
let task = svc.get_profile(id)   // ephemeral: borrows &svc
task.await?                       // OK: used immediately
// task cannot be stored in a struct or global
```

**`async scope` is the ergonomic solution** for borrowing tasks:

```
async fn process_all(mut data: Vec[i32]) -> Vec[i32]:
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
| Only owned `Send` values | No | Yes | Yes (if `T: Send`) |
| Owned but non-`Send` values | No | Yes | No |
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
read (never stored, never returned, never mutated), it may optimize
away the allocation and use a static reference internally.
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

**How it works:** Type context decides the storage class
deterministically.

- In `&str` context, the literal is a zero-cost static reference.
  This guarantee is unconditional.
- In owned `str` context, the literal produces an owned `str` and may
  allocate. The compiler may elide the allocation when the owned value
  is observably equivalent to a static immutable string, but elision
  is an optimization, never a guarantee — code that requires zero
  allocation must use `&str` context.

Performance-sensitive code that requires zero allocation should use an
explicit `&str` annotation or pass to an `&str` parameter for guaranteed
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
let s = "hello"
let t = "hi"
let w = "hello world"
f"{s}"        // "hello"
f"{t:>10}"    // "        hi"  (right-align)
f"{t:<10}"    // "hi        "  (left-align, default)
f"{w:.5}"     // "hello"       (truncation)
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
f"{name:?}"      // "\"hi\""   (name = "hi")
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

### 15.8 Regular Expressions

Regular expressions are first-class language surface, not a
CLI-only feature. (The one-liner behavior in §18.5b.6 is this
section applied to generated entry sources.)

**Regex literals.** `/pattern/flags` is a literal of type `Regex`
(`std.regex`):

```
let r = /hello/i
r.is_match("HELLO")                  // true
let words = /\w+/g
```

Flags: `g` (global), `i` (case-insensitive), `m` (multi-line),
`s` (dot matches newline), `x` (extended), `U` (ungreedy),
`u` (Unicode). An unknown flag is a compile-time error. The pattern
syntax is owned by `std.regex` (a PCRE2-derived engine; see
`docs/libstd-spec.md` for the full `Regex`, `Match`, and `Captures`
API: `compile`, `compile_flags`, `is_match`, `find`, `find_all`,
`captures`, `replace`, ...).

**Match operators.** `=~` (matches) and `!~` (does not match) test a
`str` against a `Regex`:

```
if line =~ /error/: alert(line)
if line !~ /debug/: keep(line)
```

Both produce `bool`. They sit at precedence level 3 with `==`/`in`
(§9.9) and are non-associative. The right operand may be a regex
literal or any `Regex` value.

**Capture bindings.** When the condition of an `if` (or a clause of
a chained `if let`, §9.7) is a **direct positive** match whose right
side is a regex literal, the captures bind in the success branch:
`$0` (whole match), `$1`..`$N` (numbered groups), and `$name` (named
groups, declared `(?<name>...)`):

```
if line =~ /status=(\d+)/:
    print($1)                         // scoped to this branch

if line =~ /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/:
    log(f"{$level}: {$msg}")
```

This is a refutable-binding condition form, like `if let`: the
bindings exist only where the match succeeded. The `$` sigil keeps
captures in their own namespace — they can never collide with the
no-shadowing rule (§29.8). `!~` and compound boolean conditions do
not create capture bindings (nest the logic when combining capture
use with other conditions). For everything else — iteration over
matches, replacement, splitting — use the `std.regex` API
explicitly.

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

- **Functions** → generated bindings; modeled-safe bindings are
  callable directly, raw/unmodeled ABI bindings stay explicit
- **Structs** → `@[repr(C)]` struct types
- **Enums** → integer constants or With enums
- **Typedefs** → type aliases
- **`#define` constants** → `const` values (integer and string literals)
- **Function-like macros** → not translated (warning emitted; see §16.2)

```
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    let threadsafe = sqlite3_threadsafe()   // modeled value call
    if threadsafe == 0:
        panic("SQLite must be built with mutex support")
    // Higher-level wrappers model handles, ownership, errors, and cleanup.
```

**Why no `unsafe` on every call?** The unsafe boundary is not
"foreign call." It is an unmodeled memory, ownership, or lifetime
contract. `c_import` is the opt-in for importing the C library, and
when the importer can model a function's contract sufficiently, the
generated binding is an ordinary With call. Wrapping those calls in
`unsafe {}` is ceremony without safety.

The importer's job is to import the raw ABI accurately, model every
contract it can infer, import, or prove into a safe With surface, and
refuse to present unmodeled danger as ordinary safe code. Value
parameters, value returns, safe handle wrappers, slice parameters for
buffers, `Option` for nullable returns, owned resource wrappers with
`Drop`, and `CStr`/`CString` for C string contracts are examples of
modeled surfaces that can be directly callable.

For APIs such as `memcpy`, `strcpy`, `free`, out-parameter fills,
borrowed pointer returns, ownership transfers, mutable buffers, or
other contracts the importer cannot model, the unsafe effect may be
at the call boundary. The answer is still not "all C calls are
unsafe." The answer is: generate a safe wrapper when the contract is
known, or keep the raw ABI surface explicit when it is not.

`unsafe` is still required for operations whose correctness depends on
facts the compiler cannot prove: raw pointer dereference, raw pointer
indexing that reads or writes, raw-pointer-to-reference/slice/view
conversion, allocation-relative pointer distance when same-allocation
facts are not proven, transmute, pointer-domain casts not specified as
safe validity-less raw conversions by the target model, unsafe calls,
and manual or unmodeled raw ABI calls. Raw pointer arithmetic, null
checks, raw address comparison and difference, pointer-to-address
observation, address-to-raw-pointer construction, same-domain raw
pointer relabeling, and raw-address-of operations that do not create
safe references are safe raw pointer computations; see §16.11. Calling
a modeled `c_import` binding with ordinary value arguments is just a
function call.

**Raw pointer access still needs `unsafe`:**

```
use c_import("my_lib.h")

// Modeled value call — no unsafe needed
let version = my_lib_version()

// Raw ABI call — unsafe may be needed at the call boundary
let handle = unsafe { my_lib_raw_handle() }

// Pointer dereference — unsafe required
let value = unsafe { *handle }

// Pointer arithmetic — no unsafe, because no memory is touched
let next = handle + 1
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

**Compiler-owned C parsing.** `c_import` uses With's compiler-owned
libclang bridge, not a random system C compiler. Release compilers
statically link the LLVM/Clang/lld SDK built by the With project, and
embed Clang's builtin resource headers. At compile time, the compiler
materializes those embedded resources to a cache and passes that
resource dir to libclang.

The normal `c_import` path parses the header with this embedded Clang
resource setup. It does not probe a system LLVM install, does not
depend on `llvm-config`, and does not invoke `cc -E` as the core
header-import mechanism.

**Target C headers are inputs.** Platform libc headers, operating
system SDKs, vendor headers, and package headers are part of the
target environment being imported. They may be supplied by the host
platform SDK, by package metadata such as `with get c.*`, by
`with.toml`, or by build target include paths. Those headers are
target inputs, not a dependency on an arbitrary host LLVM/Clang
installation.

**Cross-compilation.** The parser and Clang resource headers are
self-contained in the With compiler. Cross-target C interop requires
the target's headers, sysroot/SDK, and link libraries, but it does not
fundamentally require an external cross-compiler as a preprocessing
step. Any remaining shell-out to host tools for SDK discovery or
macro/preprocessor helper paths is an implementation gap, not a
language requirement.

**Build configuration:**

```toml
# with.toml
[c_import]
include_paths = ["vendor/include"]  # additional target header roots
```

Build targets can also contribute target-specific C import inputs:

```
target.include_path("vendor/include")
target.define("DEBUG=1")
target.link_system_lib("sqlite3")
```

### 16.2 Macro Handling

C macros that are simple constants are translated automatically:

```c
#define SQLITE_OK 0              // → const SQLITE_OK: i32 = 0
#define PATH_MAX 4096            // → const PATH_MAX: i32 = 4096
#define NULL ((void*)0)          // → recognized as null
```

Not every function-like macro can be translated automatically. C
macros are preprocessor token replacements — they do not exist in the
C AST that `libclang` parses. Translating function-like macros
requires heuristic token-stream analysis. The importer always
translates straightforward object-like `#define` constants:

```c
#define MAX(a,b) ((a) > (b) ? (a) : (b))
// → NOT translated. Compiler warning: untranslated macro MAX
// User must write: fn max[T](a: T, b: T) -> T: if a > b: a else: b
```

Complex macros (token pasting, stringification, variadic macros,
statement-expression macros) are not part of the modeled safe surface
unless the importer can prove an equivalent With expression. Users
wrap these in a thin C shim file, use the raw surface when one exists,
or write manual `extern "C"` bindings.

**Function-like macro translation:** Simple expression macros are
translated to generic functions:

```c
#define MAX(a, b) ((a) > (b) ? (a) : (b))
// → fn MAX[T](a: T, b: T) -> T: if a > b: a else: b

#define ABS(x) ((x) < 0 ? -(x) : (x))
// → fn ABS[T](a: T) -> T: if a < 0: 0 - a else: a
```

**Honest generated surface:** A generated `c_import` surface contains
only real bindings:

1. safely modeled bindings, callable as ordinary With APIs; or
2. raw ABI bindings per §16.1 when the C construct is ABI-expressible
   but not safely modeled.

An untranslatable construct is inexpressible even as a raw binding: for
example, a token-paste macro with no stable value or type meaning, a
compiler extension With cannot represent, or a type that cannot be
expressed in either the safe or raw surface. Such constructs are
omitted from the generated binding surface and recorded in the import
manifest with their name, source location, and reason. Dependent
bindings that require an omitted inexpressible construct are also
omitted and recorded with the same reason chain.

Generated bindings must never contain `comptime_error` placeholders or
any other callable/value stub that pretends an inexpressible C
construct is part of the usable With surface. `comptime_error` remains
a user-authored language feature, not a compiler-generated fallback for
failed C translation.

**Acknowledged omissions:** `allow_untranslated` names declarations,
macros, or other imported C entities that the project explicitly
accepts as unavailable. The compiler includes this allow-list in the
`c_import` cache key so changing it cannot reuse stale generated
bindings.

```
use c_import("complex_lib.h",
    link: "complex",
    allow_untranslated: ["WEIRD_MACRO", "PLATFORM_HACK"],
)
```

This is not a silent fallback. Allow-listed omissions are still omitted
and recorded as unavailable; they are not emitted as callable
placeholder APIs. Anything outside the allow-list that is
inexpressible must also be omitted and reported.

The requested surface of a bare `use c_import("h")` is the available
surface of that header under the selected platform and preprocessor
configuration. Inexpressible constructs in that surface are
partial-but-honest omissions: ordinary import reports every gap but
does not fail merely because such a construct exists. Referencing an
omitted symbol is a directional compile error that names the symbol,
why it could not be translated, and the alternative: use the raw
surface if this is a §16.1 unsafe/raw-modeling case, or accept that the
C construct has no With representation if it is genuinely
inexpressible.

Whole-import non-zero failure is reserved for:

- an explicit selective import request that names an inexpressible
  symbol;
- completeness mode (`with migrate`, or an explicit strict import flag)
  where incomplete translation is itself the error; and
- import failures such as a missing header, parse failure, unsupported
  target configuration, or toolchain crash.

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

// With modeled owning wrapper, when ownership evidence exists:
let table = GHashTable()
table.insert("name", "Eric")
// Drop calls g_hash_table_destroy when table's value lifetime ends.
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
g_hash_table_destroy   → .destroy()                // method candidate
```

**Constructor syntax.** If a type has a `.new` method, the type
name itself becomes callable: `GHashTable(args)` is sugar for
`GHashTable.new(args)`.

**Proven ownership cleanup.** Method-name detection and ownership are
separate facts. Name heuristics such as `prefix_destroy`,
`prefix_free`, `prefix_close`, `prefix_unref`, and `prefix_release`
may produce candidates, import-manifest notes, or diagnostics
suggesting a likely constructor/destructor pairing. They may not, by
themselves, insert cleanup, call a destructor, generate an owning
wrapper, or mark a raw C value as owned.

`c_import` may treat a C resource as owned only when ownership is known
from evidence that proves or asserts the contract:

- an explicit annotation;
- author-supplied or imported metadata;
- conservative source/header analysis strong enough to prove the
  ownership contract;
- a curated, library-specific convention that asserts facts about a
  known library; or
- a hand-written owning wrapper.

Generic naming conventions and speculative source analysis are not
ownership evidence.

When ownership is established, cleanup is expressed only as a generated
owning wrapper type whose `Drop` calls the correct C destructor. The
compiler does not insert scope-local `defer` for C resources. A
`Drop`-owning wrapper handles locals, returned values, and values
stored inside other owning structures because cleanup follows the
value's lifetime rather than a lexical scope.

Raw pointers and raw handles stay raw unless wrapped by a proven
ownership model. Reference-counted resources are modeled according to
their actual contract: a `Drop` wrapper that calls `unref` is generated
only for values built from an owning constructor or retain/copy/create
operation that returns a +1 reference. Borrowing accessors produce
non-owning handles with no `Drop`.

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

Manual `extern "C"` declarations are raw ABI declarations. A call to a
value-only manual extern function is safe when the signature carries no
raw pointer, slice, callback, variadic, ownership, lifetime, or other
unmodeled safety contract. A manual extern call that does carry such a
contract requires `unsafe` unless it is wrapped by a safe With API that
models the memory, ownership, and lifetime contract. An `unsafe` block
around a value-only manual extern call is still permitted as an explicit
raw-ABI-boundary acknowledgement; it is not required.

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

### 16.3c Contract-Driven Coercion at `c_import` Boundaries

C APIs use strings, byte buffers, mutable buffers, and `void*` through
contracts that are not fully present in the C type spelling. With keeps
those APIs ergonomic by modeling the contract in the binding and
generating the correct bridge. It does not reinterpret values from type
spelling or receiving context alone.

The compiler may auto-coerce at a `c_import` boundary only when the
compiler or binding models the full contract needed for that
conversion: sentinel, length or capacity, lifetime and retention,
nullability, mutability, ownership, allocation, cleanup, and copy-back.
If those facts are missing, the operation stays on the raw surface.

**Contract metadata sources.** The facts that make a binding modeled
come from, in priority order: explicit annotations in the importing
project, curated contract overlays shipped with the toolchain, and
package-supplied binding metadata (`with get c.*`). The toolchain
maintains a **curated libc overlay** as a standard deliverable, so
common calls such as `fopen`, `strlen`, and `write` present modeled
surfaces out of the box; libraries without overlays import with raw
surfaces until contracts are supplied. An overlay supplies evidence,
never exemptions — it cannot weaken the rules below.

```
// Modeled input C string contract:
fopen(path, mode)        // compiler supplies call-scoped C strings

// Modeled byte-buffer contract:
write(fd, data)          // compiler supplies data.ptr and data.len together

// Raw surface when the contract is unknown:
raw_register_callback(name_ptr as *const c_char)
```

**`str` → input C string (`*const c_char`).** A `str` may be passed
automatically to a `*const c_char` parameter only when the binding
establishes all of these facts:

1. the parameter is a read-only, NUL-terminated input string;
2. the value has no interior NUL, or the conversion handles one loudly;
3. the C callee does not retain the pointer after the call.

If the argument is a string literal or another value the compiler can
prove already lives in valid NUL-terminated storage, the compiler may
pass it directly. Otherwise it generates a call-scoped
NUL-terminated temporary and frees it when the call returns.

Interior NUL is never silently truncated. A proven interior NUL is a
compile error; a dynamic interior NUL is checked at runtime and
reported according to the binding's error model. The conversion passes
the `str` bytes unchanged and does not silently transcode.

When the binding cannot prove non-retention, or knows that C stores the
pointer, a call-scoped temporary is forbidden. The safe surface must
require caller-managed storage such as `CStr`, `CString`, or a
generated wrapper with a suitable lifetime, or the API remains raw.

**`str` → byte buffer (`*const u8`).** A safe byte-buffer binding must
convey both the data pointer and its paired length or equivalent bound.
`str` may be adapted to C APIs such as `write(fd, data.ptr, data.len)`
when the binding models that pair. Passing only `data.ptr` to an
unbounded C reader is raw pointer interop.

**`str` → mutable C string or writable buffer (`*mut c_char`).** There
is no implicit `str` to `*mut c_char` conversion with a hidden
caller-must-free allocation. A writable C buffer requires a modeled
buffer contract: a caller-provided `mut` slice or buffer with known
capacity, a generated owned buffer type whose `Drop` handles cleanup,
or a generated wrapper that defines allocation, capacity, initialized
length, mutation behavior, cleanup, and whether contents copy back into
With.

**`void*` and opaque pointers.** `*mut c_void` and `*const c_void` are
opaque. Expected-type context does not prove pointee type, lifetime,
ownership, nullability, or validity. A `void*` may be converted
automatically only when trusted binding metadata or a generated wrapper
proves what it represents. Otherwise it remains `*c_void`; using it
requires the raw surface or an explicit cast.

In particular, `void*` to `str` is never generated merely because the
receiving context is `str`. Calling `strlen` on an arbitrary `void*`
is an unsafe memory read based on a guess. It is allowed only when the
binding proves the pointer is a valid NUL-terminated string with known
lifetime and nullability.

**Nullability.** Null is information. A nullable C string or pointer
return is modeled as `Option[str]`, `Option[*T]`, or an equivalent
generated wrapper. `None` and `Some("")` are distinct unless the C
contract explicitly states that null means empty.

**Always raw unless modeled:** arbitrary `void*`, retained or
unknown-lifetime string pointers, mutable C buffers without a modeled
contract, pointer-only byte buffers with no bound, explicit pointer
casts, and any API whose lifetime, ownership, or nullability cannot be
proven.

No safe conversion may silently truncate at an interior NUL, allocate
hidden caller-owned memory, pass a call-scoped temporary to an API that
retains it, silently transcode string bytes, erase nullability, call
`strlen` on an unproven pointer, or reinterpret a `void*` from expected
type alone.

### 16.3d `@[effect]` — Declared Effect Contracts

Parameter effects (read, write, consume, escape) are normally
**inferred** from function bodies (§3.8, §21.1). Some declarations
have no body to infer from: `extern` functions, intrinsic-backed
stdlib stubs, and raw ABI bindings. For these, `@[effect]` declares
the contract explicitly:

```
@[effect(dst: write, src: read)]
extern "C" fn memcpy(dst: *mut c_void, src: *const c_void, n: usize) -> *mut c_void

@[effect(handle: consume)]
extern "C" fn close_handle(handle: *mut c_void)
```

Recognized effect names: `read`, `write`, `consume`, `escape_value`,
`escape_view`.

**Scope rules:**

1. `@[effect]` is **required information** only where no body exists
   (extern, intrinsics). Bindings without it stay on the raw surface
   for the affected parameters.
2. On an ordinary function with a body, `@[effect]` may optionally
   **pin** the inferred summary at a `pub` boundary (§4.6
   explicitness): if inference disagrees with the pin, that is a
   compile error — the pin is a checked contract, not an override.
3. `@[effect]` is library-author surface (stdlib, FFI bindings,
   contract overlays §16.3c). Ordinary application code never needs
   it; requiring it there would be annotation ceremony (§1.7).

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
let as_float = unsafe { v.f }    // reinterpret bits as f32
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

`fn(...) -> T` is a With callable value. It may carry closure context and is
not C ABI compatible.

`extern "C" fn(...) -> T` is a raw C ABI function pointer. It is pointer-sized,
`Copy`, and may be stored in `repr(C)` structs or passed to C imports. Named
functions and non-capturing closures coerce to `extern "C" fn` when their
signature matches. Capturing closures do not coerce, because a C function
pointer has no place to store With closure context.

Function pointer type parameters may be written with or without names:

```
extern "C" fn(i32, i32) -> i32
extern "C" fn(lhs: i32, rhs: i32) -> i32
```

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

### 16.11 Raw Pointer Operations and `unsafe`

```
fn use_ptr(p: *mut i32, end: *mut i32):
    let q = p + 2              // raw pointer arithmetic is safe
    let at_end = q == end      // raw pointer comparison is safe
    let addr = p as usize      // address observation is safe
    let r = addr as *mut i32   // validity-less raw pointer construction
    let bytes = q as *mut u8   // same-domain raw pointer relabeling

    unsafe:
        let val = *q           // raw pointer dereference
        let val2 = p[2]        // raw pointer indexing that reads
        p[0] = 42              // raw pointer indexing that writes
        let ref = q as &i32    // raw pointer to safe reference
        let s = slice(q, 2)    // raw pointer to safe slice/view
```

Certain operations in With can violate memory safety if misused.
These operations are permitted only within an `unsafe` context:
the body of an `unsafe fn`, the scope of an `unsafe:`/`unsafe {}` block,
or the narrow `unsafe *p` / `unsafe p[i]` raw-access prefix.

The boundary is:

> Address computation, comparison, and same-domain raw-pointer
> relabeling are safe. Memory access or validity assertion is unsafe.

`unsafe` is not a tax on foreignness, and it is not a tax on pointers.
It marks the operation whose safety the compiler cannot prove. Pointer
arithmetic computes an address. Pointer comparison compares addresses.
Same-domain raw-pointer casts relabel raw pointer values. None of these
operations reads memory, writes memory, creates a safe reference, or
proves bounds, alignment, liveness, initialization, ownership,
uniqueness, permissions, or provenance.

The operations that require an unsafe context are:

- Raw pointer dereference (`*p` for read or write)
- Raw pointer indexing (`p[i]` for read, `p[i] = v` for write)
- Raw-pointer-to-reference conversion (`p as &T`)
- Raw-pointer-to-slice/view conversion (`slice(p, len)` or equivalent)
- Allocation-relative pointer distance when same-allocation facts are
  not proven
- `transmute`, or reinterpretation into a non-raw value, safe
  reference, safe memory abstraction, or other type whose invariants
  safe code will trust
- Pointer-domain casts not specified as safe validity-less raw
  conversions by the target model
- Calls to `unsafe fn`
- Calls to manual `extern` functions with raw/unmodeled safety
  contracts, or raw/unmodeled ABI bindings
- Any operation whose correctness depends on the pointer being valid,
  live, aligned, initialized, in bounds, dereferenceable, owned,
  uniquely writable, carrying the required permissions, or carrying the
  required provenance
- Other operations explicitly marked as unsafe in their definition

For the common raw-memory access case, `unsafe` may be used as a
narrow prefix over one contiguous raw access chain:

```
let x = unsafe *p
let y = unsafe p[i]
let z = unsafe **pp
let item = unsafe *(p + 1)

unsafe *p = 42
unsafe p[i] = 42
```

The prefix does not wrap arbitrary expressions. `unsafe *p + 1`
means `(unsafe *p) + 1`; a second raw access must be marked
separately or placed in an unsafe block. Use `unsafe { ... }` or a
newline `unsafe:` block for unsafe calls, transmutes, asm, and
compound unsafe expressions.

The following operations involving raw pointers are safe and do not
require an unsafe context:

- Raw pointer arithmetic (`p + n`, `p - n`)
- Raw pointer offset calculation
- Raw pointer equality comparison
- Raw pointer null checks
- Raw address ordering/comparison (`p < q`, `p >= q`, etc.)
- Raw address difference, when specified as integer address subtraction
- Pointer-to-address/integer observation (`p as usize`)
- Integer/address-to-raw-pointer construction of a validity-less raw
  pointer value (`n as *T`)
- Same-domain raw-pointer-to-raw-pointer casts that relabel the pointee
  type or source-level mutability qualifier
- Raw-address-of operations that do not materialize a safe reference

These operations compute, compare, observe, or relabel raw pointer
values only. They do not read memory, write memory, create a safe
reference, create a slice/view, or assert that the resulting pointer is
valid to use.

For typed pointer arithmetic, `p + n` means address computation scaled
by the pointee size: conceptually `addr(p) + n * sizeof(T)` under the
target raw-pointer model. Under the flat-address default, both the
scaling and the address addition use deterministic wrapping arithmetic
over the target pointer-address width. The result is still only a raw
pointer value, not a validity claim.

An overflowing raw pointer offset produces a raw pointer value by
deterministic wrapping address computation under the flat-address
default. It does not produce an implicit validity claim. The resulting
pointer may be invalid to dereference, but computing it is defined.

Raw pointer difference is safe only when it is specified as
address-value subtraction. If an operation instead claims
same-allocation element distance, then same-allocation provenance and
bounds are being asserted. That stronger operation is safe only when
proven; otherwise it belongs behind `unsafe` or on the raw surface.

A raw-pointer-to-raw-pointer cast is safe when it relabels the pointee
type or source-level mutability qualifier (`*const` <-> `*mut`) without
changing the pointer's domain or representation. Such a cast relabels
the raw pointer value. It is not the value-bit transmute of the unsafe
list, and it asserts nothing about the new pointee type. Alignment,
validity, initialization, aliasing permission, and provenance for the
new type are asserted only when the pointer is dereferenced or
converted to a safe abstraction, which already requires `unsafe`.

Changing the source-level mutability qualifier is a relabel, not a
capability grant. Casting `*const T` to `*mut U` constructs only a raw
mutable pointer value; it grants no write capability, uniqueness,
ownership, or validity, and any write through the result remains unsafe
under the ordinary raw-pointer access contract.

A **pointer-domain cast** changes the pointer's address space,
capability class, segment class, function/data-pointer class,
host/device domain, hardware or capability permission bits, or
representation. It is not an ordinary relabel. Which such casts exist
and how they behave is governed by the target raw-pointer model. A
pointer-domain cast is safe only if the target model specifies it as a
validity-less raw pointer conversion; otherwise it requires `unsafe` or
is rejected through an explicit target-defined cast form rather than the
ordinary `as` relabel.

The source-level mutability qualifier is not a permission in this
target-model sense. Hardware or capability permission bits, such as
CHERI load/store/execute permissions, are target-defined facts;
manufacturing or stripping them is a pointer-domain cast, not a
same-domain relabel.

Converting a raw pointer into a safe memory abstraction is also an
unsafe access boundary. A reference, slice, view, span, or similar safe
type asserts validity, bounds, alignment, lifetime, initialization, and,
where applicable, provenance. That assertion must be made in an unsafe
context at the conversion site; it is not deferred until later safe code
uses the converted value.

Passing a raw pointer to a function is not unsafe by itself. The
obligation, if any, lives in the callee's signature or wrapper contract.
A function that dereferences, retains, mutates through, converts, or
otherwise relies on caller-guaranteed validity of a raw pointer
parameter has a safety precondition that the raw pointer type does not
encode. Such a function is an `unsafe fn`, unless the compiler or
binding wraps the contract into a safe surface.

For in-language functions, the compiler may prove that the function
does not rely on the pointer's validity: it never dereferences, retains,
mutates through, converts to a safe reference/view, or passes the
pointer to a contract that relies on validity. A function proven not to
rely on the pointer's validity may be safe, and passing a raw pointer to
it is safe.

For foreign functions, the compiler cannot infer that contract across
the boundary. A foreign function that takes raw pointers is unsafe by
default unless the binding declares the pointer contract safe, or
generates a safe wrapper that validates and models the relevant
nullability, bounds, lifetime, ownership, retention, mutation, and
permission rules.

Indexing must distinguish address calculation from memory access. If
`p + i` computes the address of element `i`, it is safe. If `p[i]`
reads or writes element `i`, it is unsafe. If the language provides an
address-only form such as `&raw p[i]` or equivalent, that form is safe
only if it is specified to compute a raw address without materializing a
safe reference. A form that creates `&T` from a raw pointer is unsafe,
even if the reference exists only transiently.

If With's memory model carries pointer provenance, the safe/unsafe
split remains the same. Raw pointer arithmetic computes a raw pointer
value without asserting that the pointer has the provenance required for
any future access. Integer-to-pointer conversion constructs a raw
pointer value without asserting valid provenance. Same-domain raw
pointer casts relabel the raw pointer value without asserting provenance
for the new pointee type.

The unsafe dereference, raw-pointer-to-reference conversion,
raw-pointer-to-slice conversion, or unsafe call is where the programmer
asserts that the pointer has the required validity and provenance. This
section defines that constructing, computing, comparing, and relabeling
raw pointer values is safe, while relying on them as memory requires
`unsafe`. It does not decide which integer-derived or relabeled pointers
are actually usable under With's memory model.

Under an exposed/permissive-provenance model, a later unsafe access may
be valid when the programmer upholds the contract. Under a
strict-provenance model, some integer-derived pointers may remain
invalid to dereference regardless of `unsafe`. That determination
belongs to the memory-model section. Provenance does not move the unsafe
boundary to arithmetic or relabeling; it is part of what the unsafe
access or conversion asserts.

On capability, segmented, or otherwise non-flat-address targets, the
target-specific raw-pointer model governs and overrides the flat-address
default. Such a target must specify how safe raw pointer arithmetic
behaves: preferably by producing a deterministic validity-less,
narrowed, untagged, or otherwise invalid raw pointer value whose later
use is where failure occurs; or, if the hardware or ABI genuinely
requires arithmetic itself to trap, by documenting that target-defined
trapping behavior explicitly. A backend for such a target is not
required to fabricate flat wrapping semantics it cannot provide, but it
must specify its raw-pointer model and keep the safe/unsafe boundary
honest for that target.

**Backend obligation:** Safe raw pointer arithmetic, comparison, address
difference, and same-domain raw-pointer relabeling must lower as raw
address operations. The compiler must not introduce undefined behavior,
poison, trapping behavior, or optimizer assumptions unless the
corresponding fact has been proven, subject to the specified target
raw-pointer model.

For these operations the backend must not attach or imply in-bounds,
in-range, dereferenceability, alignment, no-overflow,
allocation-membership, provenance, ownership, uniqueness,
write-permission, or lifetime assumptions unless those facts are
proven. For LLVM backends, ordinary raw pointer arithmetic must not be
lowered with `inbounds` or `inrange` GEP, or equivalent metadata, unless
those facts have been proven. It also must not use `nuw`/`nsw`-style
assumptions for address arithmetic unless overflow has been proven
impossible. Absent such proof, arithmetic lowers to the target's
specified raw address computation, which is deterministic wrapping
arithmetic under the flat-address default.

Raw pointer comparison must lower to address-value comparison without
range, provenance, allocation-membership, dereferenceability, or
lifetime assumptions. LLVM pointer `icmp` or target-approved
integer-address comparison may be used when it preserves With's raw
address comparison semantics. C relational pointer comparison is not an
acceptable lowering for arbitrary raw addresses, because C imposes
restrictions on relational comparison of pointers from unrelated
objects.

Raw address difference carries the same obligation as comparison: it
must lower to integer subtraction of the address values, with no
same-allocation, provenance, or allocation-membership assumption. It
must not be lowered as C pointer subtraction, whose result is defined
only for pointers into the same object. Allocation-relative element
distance is a distinct, stronger operation and is lowered only where the
same-allocation facts have been proven.

A same-domain raw-pointer relabeling cast lowers to a no-op, bitcast, or
target-approved raw pointer cast that preserves the raw pointer value
without adding alignment, dereferenceability, provenance, address-space,
capability, permission, or lifetime assumptions for the new pointee
type. Pointer-domain casts lower according to the target raw-pointer
model.

This does not forbid optimization. If the compiler has proven a stronger
fact, such as a checked slice index being in bounds, it may use a
stronger lowering for that proven case. The rule forbids assuming those
facts for arbitrary raw pointer arithmetic, comparison, difference, or
relabeling.

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
let bits: u32 = unsafe { transmute[u32](3.14f32) }
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

With provides three built-in magic constants, evaluated at the point of use:

| Constant | Type | Value |
|----------|------|-------|
| `__FILE__` | `str` | Path of the current source file |
| `__LINE__` | `u32` | Line number of the expression |
| `__FN__` | `str` | Name of the current function |

```
print(__FILE__)    // prints "src/main.w"
print(__LINE__)    // prints the current line number
print(__FN__)      // prints the current function name
```

These are especially useful as default parameter values for assertion
and logging functions:

```
fn log(msg: str, file: str = __FILE__, line: u32 = __LINE__):
    print(f"[{file}:{line}] {msg}")

log("hello")  // prints "[src/main.w:5] hello"
```

### 17.1 Compile-Time Evaluation

`comptime` executes code at compile time. The invariant is not "no
effects"; it is: no build output may depend on undeclared, untracked,
ambient state. Comptime may use information only when that information is
declared, authorized, and tracked.

There are two independent questions:

1. **Determinism:** is the result a deterministic function of declared,
   tracked inputs?
2. **Access authority:** is the operation allowed to touch the thing it
   wants to touch?

A capability grants access authority. It does not grant permission to
produce nondeterministic output.

With has three comptime modes:

1. **Pure comptime** — deterministic computation over values.
2. **Tracked-input comptime** — deterministic reads of explicitly named
   or purely-computed authorized inputs, each recorded as a build
   dependency.
3. **Capability-bearing comptime** — build, package, C interop,
   migration, code generation, and tool effects mediated by
   driver-minted capabilities.

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
perform ambient I/O, inspect directories, read the environment or clock,
make network calls, spawn processes, call FFI, mint capabilities, depend
on host-global state, call the runtime heap allocator, or carry runtime
allocator identity across the compile/runtime boundary. It may allocate
inside the compiler evaluator and produce static program data such as
constants, generated tables, generated bytes, and embedded assets. The
result must be a value that can be embedded in the binary as a constant.

Pure comptime may not call FFI. Capability-bearing comptime may invoke
trusted, tracked foreign tools through explicit capabilities, preferring
sandboxable subprocesses. In-process FFI is restricted to compiler-owned
pinned toolchain integrations or explicitly trusted local build code; it
is never ambient authority for dependency code.

### 17.1a Tracked-Input Comptime

Some comptime operations read external inputs and still remain
deterministic because the input is explicitly named, authorized, and
tracked. `embed_file("logo.png")` is the canonical example: it is not
general file I/O, it is a declaration that `logo.png` is a compile-time
input.

A tracked-input operation is allowed when:

1. the input is resolved by pure comptime before it is read;
2. the resolved input is inside an authorized package/source root, or
   access is granted by an explicit capability;
3. the operation is deterministic over that resolved input;
4. the input is recorded in the build graph before or as it is read.

The decisive distinction is declared input versus discovered input.
Computing `"assets/" ++ name ++ ".png"` from pure comptime constants is
allowed if the resolved path is registered before the read. Globbing a
directory, listing files, reading `$HOME`, consulting the environment, or
inspecting the filesystem to decide what to read is input discovery. If
discovery is needed, it belongs in capability-bearing comptime, where the
discovery itself becomes part of the build graph, manifest, or
reproducibility record.

The model may extend beyond `embed_file`, but only through
compiler-recognized APIs that declare their inputs to the build graph
before reading them. Ordinary pure comptime does not get ambient file I/O
by promising to be deterministic.

### 17.1b Capability-Bearing Comptime

Capability-bearing comptime is a separate mode for build orchestration,
package integration, C interop, migration, code generation, and tool
execution. Build orchestration and compiler-driver tools use the same
comptime evaluator, but with explicit driver-minted capabilities. A
capability-bearing comptime entry point declares the capabilities it
requires with a `comptime with` clause.

Capabilities are unforgeable values granting specific authority:
filesystem access, process execution, package/network access,
environment access, output writing, tool invocation, or similar. They
bound what build code may touch, especially for untrusted fetched
dependencies. A dependency's `build.w` does not receive ambient access to
the user's machine merely because the package was fetched.

Capabilities are not a determinism waiver. Any effect that affects the
compiled output must still be deterministic over declared, tracked, or
pinned inputs. A package fetch must be pinned and content-addressed. A
code generator must run hermetically or record its inputs. A process
invocation that affects output must track its command, inputs, outputs,
environment, and relevant tool identity. An environment variable that
affects output must be declared as a build input.

If an effect is genuinely nondeterministic, that nondeterminism must be
visible: recorded, marked non-reproducible, or rejected in strict mode.
Self-hosting compiler builds reject nondeterminism; the fixpoint requires
it to be absent.

`c_import` is the canonical cross-case. It reads C headers, which are
declared and tracked inputs, and it uses the compiler-owned C
parser/toolchain. That toolchain identity is itself a tracked input. The
embedded LLVM/Clang SDK is therefore part of the reproducibility model:
using an ambient system Clang would make bindings depend on undeclared
host state.

`with migrate` is capability-bearing tooling. Its output is normally
reviewable source that the user commits, so nondeterminism there is a
quality and trust issue before it is a fixpoint issue. If migration or
code generation is invoked as part of a build action, the normal
capability-bearing rules apply.

The canonical form names both the capability type and the local binding:

```with
comptime with BuildCtx as ctx:
pub fn build -> Build:
    var out = ctx.new_build()
    var app = target_new(.Executable, "app", "src/main.w")
    out = out.add_target(app)
    out.default("app")
```

Capability access is through this local binding. The `with` clause does not
create implicit globals; it binds driver-minted capability values into the
function's lexical scope.

The shorthand omits `as name` only when the capability type has a
standard default binding:

```with
comptime with BuildCtx:
pub fn build -> Build:
    ctx.new_build()
```

This desugars to:

```with
comptime with BuildCtx as ctx:
```

Default bindings are part of the standard library capability contract.
Initial defaults:

| Capability | Default binding |
|------------|-----------------|
| `BuildCtx` | `ctx` |
| `ActionCtx` | `ctx` |
| `ToolFs` | `fs` |
| `ProcessRunner` | `proc` |
| `Diagnostics` | `diag` |
| `SourceEmitter` | `emit` |
| `ProjectInfo` | `project` |
| `Workspace` | `workspace` |

Multiple capabilities compose with commas:

```with
comptime with ToolFs as fs, ProcessRunner as proc:
fn run_codegen(input: str, output: str) -> i32:
    let result = proc.run_capture(["codegen", input, output], "out/tmp/codegen.out", "out/tmp/codegen.err", 30000)
    if result.rc != 0:
        return result.rc
    fs.read_text(output).len() as i32
```

If two capabilities would use the same default binding in one `with`
clause, the shorthand is ambiguous and the program must use explicit
`as` bindings. Reusing a local capability binding name in the same
`with` clause is an error.

Pure comptime cannot forge or construct capability values. Only the
compiler driver and explicitly privileged test harnesses can mint
capabilities. A function that requires capabilities can be invoked only
from a comptime context that already has those capabilities in scope or
from a driver-discovered entry point such as `build.w` or an action
target.

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
        fn serialize(self: &T, mut out: JsonWriter) -> JsonWriter:
            out.begin_object()
            for field in fields:       // cascade: inside comptime fn
                out.key(field.name)
                out = self.{field.name}.serialize(out)
            out.end_object()
            out

// Usage: just annotate the type
@[derive(Serialize)]
type User { name: String, age: i32, email: String }

// The compiler generates (conceptually):
// impl Serialize for User:
//     fn serialize(self: &User, mut out: JsonWriter) -> JsonWriter:
//         out.begin_object()
//         out.key("name"); out = self.name.serialize(out)
//         out.key("age"); out = self.age.serialize(out)
//         out.key("email"); out = self.email.serialize(out)
//         out.end_object()
//         out
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
fn serialize_value[T](val: &T, mut out: Writer) -> Writer:
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

Compiler-generated `c_import` bindings do not use `comptime_error` as
a fallback for untranslatable C constructs. User-authored
`comptime_error` is for concept checks, removed APIs, and other
intentional compile-time failures. Failed C translation is handled by
the honest-surface rule in §16.2: omit and report inexpressible
constructs, and never generate callable placeholder bindings.

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

`embed_file` is a tracked-input comptime intrinsic, not ordinary file
I/O. The path expression must resolve by pure comptime before the read.
The resolved path is relative to the source file and must be inside an
authorized package/source root unless an explicit capability grants
broader access. The compiler records the file as a build dependency
before or as it reads it, and rebuilds when the file changes. If the file
does not exist, a compile error is emitted. The file contents are
embedded verbatim as a string constant in the binary.

`embed_file` reads declared inputs. It does not inspect directories,
expand globs, consult the environment, or discover which files to embed
from ambient filesystem state.

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
3. **No ambient effects.** Pure comptime cannot read files, inspect
   directories, make network calls, access the environment, read the
   clock, spawn processes, call FFI, mint capabilities, or depend on
   host-global state. Tracked-input intrinsics and capability-bearing
   comptime are separate modes described in §17.1.
4. **Deterministic over tracked inputs.** The same comptime expression
   with the same declared, authorized, tracked inputs always produces the
   same output. No comptime mode may let undeclared ambient state affect
   the build output silently.
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

The `module` header is optional; a file without one is addressed by
its path. One file is one module; directories group modules into
hierarchical paths. `use` resolution searches, in order: the embedded
standard library, paths relative to the importing module's directory,
the project's `lib/` roots, and the project root.

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
- Traits: `Eq`, `Ord`, `Hash`, `Debug`, `Display`, `Default`, `Drop`
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

`pub` exports names. No `pub` = module-private. Cross-module access
to a non-`pub` symbol is a compile error; this applies uniformly to
functions, types, constants, and globals.

### 18.4 Packages

Directory with `with.toml`. Single-file programs need no manifest.
Dependencies hash-pinned in lockfile.

### 18.5 Toolchain

A single binary provides all tools:

```
with build [--release] [--target <triple>]   # build the project
with run <file>                              # compile and run
with check <file>                            # typecheck only, no codegen
with test                                    # run the test suite
with fmt                                     # format source
with doc [--open]                            # generate documentation
with repl                                    # interactive session
with init                                    # create a new project
with migrate <c-sources>                     # translate C to With (§13.5b, §16)
with version | with help
with -e <code> | -n <code> | -p <code>      # one-liners (§18.5b)
```

Additional flags: `--emit-c` (C source backend, used for
bootstrapping new platforms), `--emit-obj`, `--overflow=<mode>`
(§4.2.3), `--no-std` (§18.7), `--strict-effects` (§17.1b),
`-O0`..`-O3`. The `--dump-*` family
(`tokens`, `ast`, `resolved`, `typed`, `mir`, `async-mir`,
`project-info`) and the `ir`/`ast`/`tokens` subcommands are
compiler-diagnostic surface: available, but implementation-internal
and not covered by stability guarantees.

Cross-compilation is a normal mode, not special.

### 18.5a Project Builds

`build.w` is executable build behavior written in With. `with.toml`
is declarative package configuration. Imperative build concerns belong
in `build.w`, not in `with.toml`.

Allowed in `with.toml`:

- Package identity such as name and version
- Dependencies and version constraints
- Target defaults and feature flags
- C include paths, defines, link libraries, and link search paths
- Publishing metadata and lint/runtime policy

Not allowed in `with.toml`:

- Conditionals or loops
- Generated-file steps
- Asset pipelines or shader compilation
- Custom shell commands
- Target graph construction
- Platform-specific branching logic
- Multi-binary or multi-library build behavior

Those belong in `build.w`.

For simple projects with no `build.w`, the compiler synthesizes the
default recipe:

```
use std.build

comptime with BuildCtx as ctx:
pub fn build -> Build:
    let info = ctx.project_info()
    ctx.new_build().executable(info.package_name(), "src/main.w")
```

The standard build graph API lives in `std.build`. It defines
`Package`, `Build`, `Target`, `BuildKind`, `BuildTarget`, and
`OptimizeMode`, plus target construction methods such as
`Build.executable`, `Build.library`, `Build.test`,
`Build.generated_source`, `Target.optimize`, `Target.link_system_lib`,
`Target.include_path`, and `Target.define`.

`build.w` runs as capability-bearing comptime, not ordinary pure
`comptime`. Build code may perform effects only through `std.build`
capabilities supplied by the driver. Those capabilities grant authority,
not nondeterminism: any output-affecting effect must be deterministic
over declared, tracked, or pinned inputs, or it must be recorded as
nondeterministic and rejected in strict and self-hosting builds.
Untrusted fetched build code receives only the capabilities the driver
grants it; compiling a project does not give dependencies ambient access
to the user's filesystem, environment, network, process table, or
toolchain.

The compiler driver discovers `build.w`, evaluates the `build` entry
point with a driver-minted `BuildCtx`, consumes the returned typed build
graph, and builds executable, library, and test targets. Per-target
`link_system_lib`, `include_path`, and `define` settings are honored by
the corresponding compile/test path. `Build.generated_source(path,
contents)` declares a generated source file to write before target
compilation; generated paths are project-relative and escaping paths
must fail loudly. `BuildTarget` can represent non-native targets, but
until cross-target codegen/linking is implemented those selections must
fail loudly instead of falling back to native output. Unsupported graph
features must likewise fail loudly instead of being ignored. A compiler
version that recognizes project `build.w` files but does not execute
them must likewise fail loudly instead of silently building some other
target.

### 18.5b CLI One-Liners

The `with` CLI supports small programs directly on the command line:

```
with -e 'print("hello")'
cat log.txt | with -n 'if line =~ /error (\d+)/: print($1)'
cat names.txt | with -p 'line = line.upper()'
```

One-liners are not interpreted and do not use a separate execution
model. The CLI constructs a synthetic With entry source file, compiles
it through the normal build/run pipeline, runs the resulting binary,
and returns that binary's exit code. The generated source uses
top-level executable statements — a form defined for CLI entry
sources by this section; the CLI does not generate an explicit
`fn main` wrapper. Ordinary module files require an explicit
`fn main` (top-level executable statements are not a general module
feature).

Exactly one one-liner mode may be used in a single invocation:

| Mode | Meaning |
|------|---------|
| `-e CODE` | Compile and run `CODE` as top-level executable statements |
| `-n CODE` | Loop over stdin lines and run `CODE` for each line |
| `-p CODE` | Like `-n`, then print the current `line` after `CODE` |

Multiple flags of the same mode are allowed and concatenate as separate
generated lines:

```
with -e 'var total = 0' -e 'total = total + 1' -e 'print(total)'
```

One-liner code cannot be combined with a source file argument.

#### 18.5b.1 Generated Environment

All one-liner modes implicitly import common modules, including I/O,
string helpers, regex support, math, collections, and builtins. The
exact generated helper names are implementation-defined; the following
bindings are user-visible:

| Binding | Modes | Type / Meaning |
|---------|-------|----------------|
| `args` | all | `Vec[str]` containing arguments after `--` |
| `line` | `-n`, `-p` | current stdin line, without trailing newline or CRLF `\r` |
| `nr` | `-n`, `-p` | 1-based line number, `i64` |

Arguments after `--` are passed to `args` and are not parsed as With CLI
options:

```
with -e 'for a in args: print(a)' -- foo bar
```

#### 18.5b.2 `-e`

`-e CODE` emits `CODE` as top-level executable statements after the
implicit imports and `args` binding:

```
with -e 'print("hello")'
```

is equivalent, modulo implementation-defined helper names, to an entry
file containing:

```
use std.io
use std.str
use std.regex
use std.math
use std.collections
use std.builtins

let args: Vec[str] = ...
print("hello")
```

#### 18.5b.3 `-n`

`-n CODE` emits a top-level loop over `stdin.lines()`. For each input
line, `line` is bound to the current line and `nr` is incremented before
the user code runs:

```
cat access.log | with -n 'if line =~ /404/: print(f"{nr}: {line}")'
```

is equivalent to:

```
var nr: i64 = 0
for line in stdin.lines():
    nr = nr + 1
    if line =~ /404/: print(f"{nr}: {line}")
```

`stdin.lines()` used by one-liners removes the trailing newline. For
CRLF input, the trailing `\r` is also removed.

#### 18.5b.4 `-p`

`-p CODE` is like `-n`, but prints `line` after `CODE` runs. `line` is a
mutable per-line binding in `-p`, so assignments affect the printed
value:

```
cat names.txt | with -p 'line = line.upper()'
```

is equivalent to:

```
var nr: i64 = 0
for __line in stdin.lines():
    nr = nr + 1
    var line = __line
    line = line.upper()
    print(line)
```

For filtering, use `-n`; `-p` always prints once per input line.

#### 18.5b.5 Semicolons

Shell one-liners often need multiple statements. Within `-e`, `-n`, and
`-p` code strings, semicolons act as line separators:

```
with -e 'var x = 0; x = x + 1; print(x)'
```

The semicolon pass is lexical. It must not split semicolons inside
string literals, regex literals, character literals, or balanced
delimiter groups. Braced blocks may still contain ordinary semicolon
separators:

```
with -e 'if true { print("yes"); print("also yes") }'
```

#### 18.5b.6 Regex One-Liners

Regex one-liners use the normal With regex syntax — this is §15.8
applied to generated entry sources, not a one-liner-only feature:

| Feature | Syntax |
|---------|--------|
| literal | `/pattern/flags` |
| positive match | `text =~ /pattern/` |
| negative match | `text !~ /pattern/` |
| numbered captures | `$0`, `$1`, `$2`, ... |
| named captures | `$name` |

Capture bindings are created only for direct positive regex conditions
whose right side is a regex literal:

```
cat log.txt | with -n 'if line =~ /status=(\d+)/: print($1)'
cat log.txt | with -n 'if line =~ /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/: print(f"{nr}: {$level} {$msg}")'
```

Named captures include the `$` prefix. A regex capture named `level`
is referenced as `$level`, including inside f-string holes:

```
print(f"{$level}: {$msg}")
```

`!~` is valid for boolean matching but does not create capture
bindings:

```
cat log.txt | with -n 'if line !~ /debug/: print(line)'
```

Compound boolean expressions do not create capture bindings for their
subexpressions. To combine capture use with other conditions, nest the
logic:

```
cat log.txt | with -n 'if line =~ /error (\d+)/ { if line.len() > 0: print($1) }'
```

Regex literals are ordinary `Regex` values in one-liners:

```
with -e 'let r = /hello/i; print(r.is_match("HELLO"))'
```

#### 18.5b.7 Diagnostics

Compiler errors from one-liner user code must point at the user's CLI
argument, not at generated imports, helper bindings, temporary files, or
wrapper code. Diagnostic source names identify the originating argument:

```
with -e 'let x = '
```

reports against `<cli -e #1>`. Multiple same-mode code arguments use
`#1`, `#2`, and so on. Failed one-liner compilation should emit the
normal compiler diagnostic and exit non-zero; it must not add vague
wrapper errors such as "one-liner compilation failed".

#### 18.5b.8 Non-Goals

One-liners do not add shell execution, `s///` substitution syntax, a
REPL execution model, or a separate data-processing mini-language.
Replacement, splitting, and more advanced regex operations use the
normal `std.regex` API.

### 18.6 Standard Library Design

The standard library is layered. Users write idiomatic With code
against `std.*` modules. They should never need `c_import` for
ordinary programming tasks.

**Layer 0: `c_import`** — compiler built-in. The mechanism by which
the standard library itself accesses platform APIs.

**Layer 1: `std.os`** — thin safe wrappers around platform APIs
(libc, POSIX, Win32). Written using `c_import` internally. Not
intended for direct use by application developers.

**Layer 2: `std.*`** — idiomatic, safe, cross-platform APIs. This is
what users import.

#### Module Map

| Module | Purpose | Replaces |
|--------|---------|----------|
| `std.os` | Layer-1 thin safe platform wrappers | libc, POSIX, Win32 |
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
| `std.alloc` | Arena, TempArena, Pool | — |
| `std.build` | Typed project build graph construction | Make/CMake project files |
| `std.context` | Standard implicit execution context | ad hoc context parameters |
| `std.signal` | Signal handling | `signal.h` |
| `std.random` | Rng, seeded PRNG | `stdlib.h` |
| `std.hash` | Hasher trait, DefaultHasher | — |
| `std.fmt` | Debug trait, f-string internals | `stdio.h` (sprintf) |
| `std.testing` | assert, require, check, assert_eq, assert_matches, panic, todo, unreachable | — |
| `std.regex` | `Regex`, `Match`, `Captures`; engine behind §15.8 literals and `=~` | PCRE2 (migrated) |
| `std.json` | JSON parse/serialize | — |
| `std.http` | HTTP client | libcurl |
| `std.crypto` | sha256, aes, chacha20, ecdsa, rsa, x509, endian, ... | OpenSSL (subset) |
Modules under `std.internal` (and compiler-support modules such as
`std.str_abi`) are compiler/runtime implementation surface, not user
API; they may change without notice.

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
| Slices | `&[T]` — borrowed views into arrays |
| Fixed arrays | `[T; N]` — stack-allocated |
| Tuples | `(A, B, ...)` |
| Ranges | `0..10`, `0..=10` |
| Math | Integer and float arithmetic, `min`, `max`, `abs` |
| Bitwise | All bit operations on integer types |
| Pointers | `*T`, `*mut T`, safe raw address arithmetic/comparison, unsafe raw memory access/conversion (§16.11) |
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
global ALLOC: BumpAllocator = BumpAllocator.new(
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

### 18.8 Package Management

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
| `with get --force-reinstall c.X@2.78` | Delete and recreate the local installed C package |
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
- Manual `extern` calls and raw/unmodeled ABI calls
- Inline assembly (`asm` expressions)
- Intrusive / self-referential structures
- Manual memory management beyond allocators
- Calling functions marked `unsafe`

### 19.2a `unsafe fn` — Function-Level Unsafe Context

Functions that pervasively perform unsafe memory accesses may be
declared `unsafe fn`:

```
unsafe fn sha256_compress(ctx: *mut Sha256):
    ctx.state[0] +%= a          // raw pointer indexing permitted
    let b = ctx.buf[off]        // auto-deref through pointer permitted
```

Inside an `unsafe fn` body, all operations that would normally
require `unsafe`, `unsafe:`, or `unsafe {}` are permitted without a wrapper.
The `unsafe` keyword on the function signature is the declaration
of intent — every line in the body is implicitly unsafe.

**Callers must acknowledge the unsafety:** Calling an `unsafe fn`
from safe code requires an unsafe block at the call site (or being
inside another `unsafe fn`):

```
unsafe { sha256_compress(&raw mut ctx) }    // caller acknowledges
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
no raw pointer dereference, no raw ABI call, and no `unsafe fn` call,
the compiler rejects it.

**Proof-dependent operations are the exception.** Some operations
require `unsafe` only when a whole-program proof fails — e.g. bare
global mutation under §9.1c's single-thread proof. When the compiler
*can* prove such an operation safe, an `unsafe` block containing it
produces a **warning** (not an error): otherwise, improving the
compiler's proof precision would turn previously-required `unsafe`
blocks into hard errors and break existing code. Categorically safe
contents (plain arithmetic, safe calls) remain a hard error as above.

---

## 20. Performance Guarantees

1. **Allocation is attributable.** Allocation need not be spelled as
   `malloc`, but every allocation must be attributable to a visible
   construct, owning type, explicit allocation API, or compiler-owned
   adapter whose cost model is documented and diagnosable.
2. **Allocation-producing constructs are enumerated.** Examples include
   allocator calls, `Vec.new()`, `.to_owned()`, owned buffer
   constructors, comprehensions, f-strings, owned string literals when
   not elided, `async fn` calls and `async:` blocks that allocate
   fibers/tasks, and modeled FFI temporaries such as call-scoped
   C-string adapters. The construct or owning result type is the signal;
   the language does not force users to spell allocation machinery when
   the intent is already clear.
3. **Allocation cost models are documented.** Each allocation-producing
   construct specifies what may allocate, which allocator or allocation
   policy is used, whether allocation may be elided, what happens on
   allocation failure, and what owns the result. String-literal
   allocation guarantees live in §15.3: `&str` context is guaranteed
   zero-allocation; owned-context elision is an optimization. Fiber
   allocation is legible through `Task` and compiler-visible allocation
   analysis, not call-site coloring.
4. **No invisible allocation obligations.** An allocation must never
   create an invisible ownership, lifetime, cleanup, or caller-must-free
   responsibility. Compiler-generated allocations must be
   compiler-owned with a non-escaping lifetime, or represented by a
   visible owning type whose `Drop` handles cleanup. Hidden caller
   obligations are forbidden. A call-scoped FFI temporary is valid only
   when it cannot escape and the compiler frees it; retained pointers,
   mutable buffers, copy-back, and ownership transfer require modeled
   contracts or visible owning types.
5. **Allocation is checkable.** Allocation-producing constructs are
   visible to compiler diagnostics and no-allocation checking.
   No-allocation contexts, co-designed with the tier and allocator
   model, reject allocating constructs unless the allocation is proven
   elided or routed through an explicit arena, allocator, or capability.
   Conservative false rejection is a compiler-precision bug, not a
   reason to require user ceremony.
6. **No hidden copies.** Values move unless `Copy`.
7. **No hidden reference counting.** Only via explicit `Rc`/`Arc`.
8. **No hidden synchronization.** Locks, atomics always explicit.
9. **No hidden runtime in `no_runtime` builds.** The fiber scheduler
   is the one blessed runtime; it is opt-in via `async` and absent
   when disabled. Suspension is always known to the compiler; ordinary
   call sites are not colored merely because the callee may suspend.
10. **Deterministic destruction.** Reverse declaration order.
11. **Disjoint borrow analysis guaranteed.**

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
or other guarded types that don't carry the annotation. See §7.9.

### 20b.2 Task Disposition

A task in statement position is intentional fire-and-forget
detachment, allowed only when the API does not require observation and
the compiler proves the task can safely outlive the current scope.

```
// OK when `send_analytics` is best-effort and detach-safe:
send_analytics("page_view")

// OK: await the result:
send_invoice(invoice).await?

// OK: explicit cancellation:
let task = warm_cache(key)
cancel(task)

// ERROR: a bound handle says "I will observe this"
let task = send_invoice(invoice)

// ERROR: not the detach spelling
let _ = send_analytics("page_view")
```

When detachment is rejected, the diagnostic must say whether the task
is must-observe or whether detach-safety failed, because the remedies
are different.

See §14.7.

### 20b.3 Unnecessary `unsafe` Block

An `unsafe` block with no unsafe operations dilutes the safety
signal.

```
// ERROR:
unsafe { let x = 1 + 2 }

// FIX: remove the unsafe block
let x = 1 + 2
```

See §19.4.

### 20b.4 Implicit Numeric Narrowing

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

### 20b.5 Unreachable Code

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
    if should_skip(x):
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

### 20b.6 Pointer Compared to Array
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

The borrow checker is primarily local, but function boundaries do
participate in lifetime reasoning through inferred effect summaries.
In particular, when a function returns a view derived from one or more
parameters, the compiler tracks which parameters may be origins of that
returned view and enforces that those origins outlive all uses of the
result.

### 21.1 Rules

At every program point, the following must hold:

1. **View-liveness rule.** Active shared borrows (`&T`) of a place
   are invalidated when the place is mutated. Mutation includes
   assignment, calling a `mut self` method, and modification through
   `with` or `IndexPlace`. The compiler rejects code that uses a
   borrow after the borrowed place has been mutated.

2. **Move validity.** A move of a place must not occur while any
   borrow of that place (or an overlapping place) is active.

3. **Use-after-move.** A binding that has been moved from must not
   be used.

4. **NLL scoping.** A borrow is active from its creation to the
   last program point that uses the borrowed reference. Not to the
   end of the enclosing block.

5. **Disjoint field access.** Two borrows of field paths that
   diverge at any field access are non-overlapping and may coexist.
   Array/slice indices are conservatively treated as overlapping.

6. **Returned-view origin tracking.** When a function returns a
   reference or other view derived from one or more parameters, the
   compiler records the set of possible origin parameters in the
   function's effect summary. At the call site, the result is tied to
   the intersection of those origin lifetimes. If any possible origin
   dies before the view's last use, the program is rejected.

   ```
   fn longest(a: &String, b: &String) -> &str:
       if a.len() > b.len():
           a.as_str()
       else:
           b.as_str()

   let s1 = String.from("hello")
   let view: &str
   {
       let s2 = String.from("world")
       view = longest(s1, s2)
   }
   print(view) // ERROR: view may originate from s2
   ```

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

8. **Mutation composability.** Mutation through `mut self` receivers
   does not require reborrowing — the receiver is the caller's place,
   so method chains compose naturally. Each `mut self` call mutates
   that place and leaves it valid for subsequent calls.

---

## 22. Ephemeral Type Rules

The programmer writes no lifetime or ephemerality annotations. The
compiler carries the origin and provenance facts needed to make that safe.

Type-level ephemerality is structural. References carry origin
constraints. Declared-ephemeral types are ephemeral by declaration.
Aggregates and generic containers whose type structurally contains an
ephemeral component are ephemeral by structure, such as `Vec[&T]`. This
determines which type shapes can carry ephemeral constraints.

Value-level ephemerality is provenance-tracked. Binding-level
ephemerality, returned-origin sets, task capture ephemerality, closure
capture ephemerality, assignment propagation, call propagation,
returned-view checking, and escape checks require deterministic
provenance analysis.

Tasks are value-level. `Task[T]` has one spelling whether ephemeral or
non-ephemeral. A task binding is ephemeral when the task captures or
depends on an ephemeral origin. That fact is inferred and propagated, not
determined from the structural type alone.

Closures and callable values carry summaries. An implementation may
encode captures structurally in anonymous closure types, but the spec
guarantee is a compiler-carried callable summary: captures, origin sets,
ephemerality, and `may_suspend` facts are carried across closure,
function pointer, trait object, and wrapper boundaries.

The analysis is modular and inferred: intra-procedural dataflow inside
each function body, plus inferred summaries across interfaces, including
returned-origin sets, task ephemerality, closure/callable capture
provenance, and `may_suspend` facts. The user writes no lifetime or
ephemerality annotations.

The analysis is deterministic and conservative. Verdicts are
reproducible. If the compiler cannot prove that an ephemeral value does
not escape, it rejects. False rejection of actually-safe code is compiler
precision debt, not user ceremony.

### 22.1 Rules

| # | Condition | Result |
|---|-----------|--------|
| 1 | Type is `&T`, `StrView`, `&[T]` | Ephemeral |
| 2 | Type is declared `ephemeral` | Ephemeral |
| 3 | Generic `F[T]` where `T` is ephemeral | Ephemeral |
| 4 | Struct has ephemeral field but is not marked `ephemeral` | Reject definition |
| 5 | `let x = expr` where expr is ephemeral | Bind `x` as ephemeral |
| 6 | Enum variant payload declared with ephemeral type | Reject unless the enum is marked `ephemeral` |
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
    while let Some(tok) = parser.next_token():
        toks.push(tok)
// tokens: Vec[Token] is itself ephemeral — valid only in this scope
// Cannot store tokens in a struct or return it from the function
```

This is consistent with Rule 3 (generic container inherits
ephemerality from its type parameter).

Rule 10 applies only to Form 1 (guarded access). The guard is
released when the block exits, so any ephemeral borrowing from the
guard's payload would dangle. Forms 2 and 3 desugar to plain
`let`/`var` blocks — their results follow normal ephemeral rules
(rules 5, 8).

### 22.2 Closure Escaping (v1.0)

A closure is non-escaping if and only if it appears as a direct
argument to a function call. All other closures are escaping.

### 22.3 Diagnostic Contract

Because the programmer cannot annotate lifetimes or ephemerality, the
diagnostic is the only interface to this analysis. Every rejection
produced by the ephemeral/origin rules (§22.1) and the view-liveness
rules (§21.1) must report, with source locations:

1. where the borrowed/ephemeral value was created (the origin),
2. where it escapes or is invalidated (the violation), and
3. where it is later used, when a later use is what makes the program
   unsafe.

The diagnostic must also name at least one idiomatic remedy
(clone/copy out, collect into owned data, use a handle, restructure
into a `with` scope, or take `&T`). A single-location "value escapes"
error does not satisfy this contract. False rejection of safe code is
compiler precision debt; an unclear rejection is diagnostic debt.
Both are compiler bugs, never user obligations.

---

## 23. `with` Block Semantics

### 23.1 Plain Binding Desugaring

Section 7 owns the full `with` dispatch rule. This section specifies
only the desugaring of plain, non-guarded `with e as x` and
`with e as mut x` forms after full dispatch has selected the plain
binding path. It does not define guarded access, implicit context,
record update, or the global `with` dispatch order.

| Syntax | Desugaring |
|--------|------------|
| `with e as mut x: body` | `{ var x = e; body; x }` |
| `with e as x: body` | `{ let x = e; body }` |

The binding is scoped to the block and cannot escape. In the plain
binding path, `mut` selects a mutable local binding; without `mut`, the
binding is immutable. In the guarded path, `mut` is checked against the
selected guard protocol instead.

### 23.2 Multiple Bindings

Multiple bindings nest left-to-right:
`with a as x, b as mut y: body` desugars to nested scoped blocks.

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

**Consuming-rebind exception:** a new binding may reuse a visible
local name when its initializer consumes that binding — i.e. the old
binding's last use is inside the initializer expression:

```
let x = read_input()
let x = parse(x)?        // OK: old x is consumed by the initializer
```

This removes the naming ceremony of pure narrowing chains (`s`,
`s2`, `trimmed`) without permitting shadowing at a distance: if the
old binding would still be live after the new declaration, the rebind
is still an error.

### 29.9 Pipeline-first guidance

Because rebinding/shadowing is disallowed, stepwise transformations should use pipelines (`|>`) and scoped `with` bindings instead of repeated `let name = ...` rebinding.

### 29.10 `todo` and `unreachable`

`todo()` and `unreachable()` are divergence-oriented builtins with type `Never`.

- They accept zero arguments or one `str`-compatible message argument.
- Their type is `Never`, which is compatible in value position with any expected type.
- They are treated as diverging control-flow points for typing and reachability analysis.

### 29.11 Reserved Keywords

The following keywords are reserved and cannot be used as
identifiers. This list is normative and matches the implementation's
lexer keyword table:

```
and       as        asm       async     await     break
c_import  comptime  const     continue  copy      defer
do        dyn       else      enum      ephemeral errdefer
error     extend    extern    false     fn        for
gen       global    goto      if        impl      in
it        let       loop      match     module    move
mut       no_suspend not      null      opaque    or
pub       return    select    spawn     trait     true
type      union     unsafe    use       var       where
while     with      yield
```

Notes:

- `then` is not a reserved keyword and is not an `if` body
  introducer.
- `newaxis` and `implicit` are **contextual**: they have special
  meaning only in index lists (§11.7) and parameter declarations
  (§9.1a) respectively, and remain usable as ordinary identifiers
  elsewhere.
- `else if` is a two-token keyword pair (§9.1), not a single
  keyword.
- `spawn` is reserved; it currently has no construct in §14 and its
  surface is under review.

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

Most constructs that introduce a statement or expression body support
three interchangeable body forms. The choice is purely stylistic; all
three produce identical AST and compiled output. The three-form rule
applies to `fn`, `while`, `for`, `loop`, `with`, `defer`, `errdefer`,
`comptime`, labeled blocks, match arms, and any future block-introducing
construct unless that construct states a narrower syntax.

`unsafe` is the deliberate exception: `unsafe:` is always a newline
block, `unsafe { ... }` is the inline block expression form, and
`unsafe *p` / `unsafe p[i]` is the narrow raw-access prefix form.

`if`/`else if`/`else` support all three forms. They do not support a
separate `then` expression shorthand; see §9.1 for the full `if` syntax.

**Form 1 — Inline colon.** A colon immediately followed by content
on the same line.

```
fn add(a: i32, b: i32) -> i32: a + b
if ready: launch()
for x in xs: total = total + x
defer: f.close()
```

The body is a single block item. The inline body ends at the first
top-level newline. Newlines inside balanced delimiters (parentheses,
brackets, braces) do not terminate the inline body.

**Form 2 — Indented colon.** The colon ends the line; the body is
the indented block on subsequent lines.

```
fn main:
    let x = 5
    print(x)

while running:
    tick()
    render()
```

The body ends when indentation returns to or below the introducing
construct's level. A colon at end of line with nothing following
(no indented block) is a syntax error.

**Form 3 — Braced.** Curly braces follow the construct's header
directly, with no intervening colon.

```
fn add(a: i32, b: i32) -> i32 { a + b }
fn main {
    let x = 5
    print(x)
}
while running { tick(); render() }
```

Whitespace inside braces is insignificant. Statements are separated
by newlines or semicolons. Empty brace body `{}` is legal (returns
`Unit`).

**After a construct's header, a body introducer is required.** For all
constructs, including `if`, `else if`, and `else`, the introducer must be
`:` or `{`; omitting it is a parse error. `then` is not a body introducer.

**Illegal combinations:**

- Colon-then-brace: `fn f: { body }` — the `{ }` is parsed as an
  inline body expression (e.g. a record literal), not a braced body.
  This is valid only if `{ body }` is a meaningful expression.
- No introducer: `while cond\n    body` — parse error; `:` or `{`
  is required after the condition.

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

### 29.14 Attribute Index

All `@[...]` attributes, with their owning sections. This list is
normative for the *user-facing* set; an attribute not listed here and
not marked internal is invalid.

| Attribute | Section | Purpose |
|-----------|---------|---------|
| `@[derive(...)]` | §11.8 | Generate trait implementations |
| `@[must_use]` | §9.7, §14.7 | Match-exhaustiveness obligation |
| `@[tailrec]` | §9.2 | Guaranteed tail-call elimination |
| `@[inline]` / `@[noinline]` | §9.2 | Inlining hints |
| `@[sealed]` | §11.6 | Closed trait implementor set |
| `@[flags]` | §4.4a | Power-of-two enum auto-increment |
| `@[specified]` | §4.4a | Require explicit discriminants |
| `@[bitpacked]` | §4.3b | Bit-level struct packing |
| `@[repr(C)]` / `@[repr(packed)]` | §16.4 | Layout control |
| `@[align(N)]` | §16.4 | Custom alignment |
| `@[c_export("name")]` | §16.5 | Export a C ABI symbol |
| `@[effect(...)]` | §16.3d | Declared effect contracts (bodiless decls) |
| `@[no_await_guard]` | §7.9 | Guard must not live across suspension |
| `@[iter_of_self]` | §13.2 | Iterator borrows the receiver |
| `@[ffi_stack]` | §14.19 | Reserved: OS-stack execution (roadmap) |
| `@[panic_handler]` / `@[entry]` / `@[no_main]` / `@[global_allocator]` | §18.7 | Freestanding-mode hooks |
| `@[target("arch")]` | §16.13 | Architecture-guarded items |

**Implementation-internal (unstable):** `@[bench]`, `@[test]`,
`@[before]`, `@[after]`, `@[stack_size]`, `@[callconv]`,
`@[compiler_hook]`, `@[packed]`, `@[weak]`. These exist for compiler,
test harness, migrator/runtime, and stdlib development, may change or
vanish without notice, and are not part of the language.

---

## 30. Formal Grammar (Informative)

This appendix collects syntactic productions from throughout the
specification into a unified reference. The normative definitions
remain in their respective sections; this is a convenience index.
If this appendix drifts from a normative section, the normative
section wins. Requirements, conformance tests, and implementation
work must cite the owning normative section; this appendix may be
cited only as related context.

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
ENUM_DECL   := [ PUB ] 'enum' IDENT [ TYPE_PARAMS ] [ ':' REPR_TYPE ] ENUM_BODY
ENUM_BODY   := '{' [ '|' ] VARIANT { ( '|' | ',' ) VARIANT } '}'
             | ':' NEWLINE INDENT [ '|' ] VARIANT { NEWLINE [ '|' ] VARIANT } DEDENT
VARIANT     := IDENT [ '(' VARIANT_FIELDS ')' ] [ '=' INT_LIT ]
REPR_TYPE   := 'i8' | 'i16' | 'i32' | 'i64' | 'u8' | 'u16' | 'u32' | 'u64'
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
CONST_DECL  := 'const' IDENT [ ':' TYPE ] '=' EXPR
```

### 30.4 Statements

**Variable binding** (§2):

```
LET_STMT    := 'let' PATTERN [ ':' TYPE ] '=' EXPR
VAR_STMT    := 'var' IDENT [ ':' TYPE ] '=' EXPR
```

**Control flow** (§9, §13.5a, §13.5b, §13.5c):

```
STMT        := LABEL_STMT | LET_STMT | VAR_STMT | IF_STMT | MATCH_STMT
              | FOR_STMT | WHILE_STMT | DO_WHILE_STMT | WITH_STMT
              | RETURN_STMT | BREAK_STMT | CONTINUE_STMT | GOTO_STMT
              | DEFER_STMT | EXPR
LABEL_STMT  := LABEL ( STMT | COLON_BODY | BRACE_BODY )
IF_STMT     := 'if' EXPR BODY { 'else' 'if' EXPR BODY } [ 'else' BODY ]
              | 'if' 'let' PATTERN '=' EXPR BODY [ 'else' BODY ]
MATCH_STMT  := 'match' EXPR BODY_ARMS
MATCH_ARM   := PATTERN [ 'if' EXPR ] '=>' EXPR
FOR_STMT    := 'for' PATTERN 'in' EXPR BODY
WHILE_STMT  := 'while' EXPR BODY
DO_WHILE_STMT := 'do' BODY 'while' EXPR
WITH_STMT   := 'with' EXPR 'as' [ 'mut' ] IDENT BODY
RETURN_STMT := 'return' [ EXPR ]
BREAK_STMT  := 'break' [ LABEL ] [ EXPR ]   // EXPR only when targeting a loop (§13.5d)
LOOP_EXPR   := 'loop' BODY
CONTINUE_STMT := 'continue' [ LABEL ]
GOTO_STMT   := 'goto' LABEL
DEFER_STMT  := 'defer' BODY
ERRDEFER_STMT := 'errdefer' BODY
```

### 30.5 Expressions

**Operator precedence** (§9.9) — low to high:

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `or` | Left |
| 2 | `and` | Left |
| 3 | `==`, `!=`, `in`, `not in`, `=~`, `!~` | Non-associative |
| 4 | `<`, `>`, `<=`, `>=` | Chained |
| 5 | `\|>` (pipeline) | Left |
| 6 | `\|` | Left |
| 7 | `^` | Left |
| 8 | `&` | Left |
| 9 | `<<`, `>>` | Left |
| 10 | `+`, `-`, `++`, `??` | Left |
| 11 | `*`, `/`, `%`, `@` | Left |
| 12 | Unary prefix (`not`, `-`, `~`, `&`, `&raw mut`) | — |
| 13 | Postfix (`.await`, `?`, `.field`, `[i]`, `()`) | Left |

**Comprehensions** (§13.6):

```
COMPREHENSION := '[' EXPR { 'for' PATTERN 'in' EXPR } [ 'if' EXPR ] ']'
              | '[' EXPR ':' EXPR { 'for' PATTERN 'in' EXPR } [ 'if' EXPR ] ']'
MAP_LIT       := '[' EXPR ':' EXPR { ',' EXPR ':' EXPR } [ ',' ] ']'
              | '[' ':' ']'
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
BODY          := COLON_INLINE | COLON_INDENTED | BRACE_BODY
COLON_INLINE  := ':' BLOCK_ITEM NEWLINE      // single item, same line
COLON_INDENTED := ':' NEWLINE INDENT STMT { NEWLINE STMT } DEDENT
BRACE_BODY    := '{' [ STMT { ( NEWLINE | ';' ) STMT } ] '}'
```

All three forms are interchangeable for every block-introducing
construct: `fn`, `if`, `else if`, `else`, `while`, `for`, `loop`, `with`,
`defer`, `errdefer`, `comptime`, `unsafe`, labeled blocks, and match arms.
`then EXPR` is not a body form. Missing body introducers are parse errors.

### 30.9 Reserved Keywords

The reserved keyword list is normative in §29.11. This appendix does
not maintain a separate copy.

---

*The With Programming Language — End of specification.*
