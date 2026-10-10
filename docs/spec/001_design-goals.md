# 1. Design Goals

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
`PhantomData<&'a T>`) while preserving Rust-level guarantees against
use-after-free, double-free, and data races.

Those guarantees are enforced by **runtime facts** (§2.5), not by lifetime
tracking: a move blanks its source (reset-on-move), so the moved-from value
owns nothing and its later implicit drop is a caught no-op rather than a
double-free; a handle (§6) carries a per-slot generation, so a stale handle
reads back a checked `None` rather than dangling. The compiler's static move
analysis is an *optimizer and a diagnostic* over this runtime guarantee, never
the guarantee itself (§2.5.2) — so a bug in the analysis can cost performance
but never safety. All three rows above share one philosophy, each with the
mechanism its lifetime needs: ownership is reset-on-move, borrowing is ephemeral
(so it needs none), and a handle is a generation made explicit and long-lived.

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

With targets Rust-level safety and C-level reach while removing explicit
lifetime annotation ceremony from the common path.

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

Eliminating lifetime annotations moves complexity into compiler analysis and
diagnostics. When the compiler cannot prove a reference or view is safe, it must
reject the program loudly rather than ask the user to write ceremonial lifetime
syntax.

---
