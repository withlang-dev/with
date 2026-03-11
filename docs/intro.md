# With

With is a systems programming language that combines Rust's safety
model with a philosophy of radical brevity: if the compiler already
knows it, don't make the developer type it.

```
fn main:
    println("Hello, World!")
```

37 bytes of source. 33K binary. Smaller than Zig. Smaller than Rust.
No garbage collector. No runtime unless you ask for one.

---

## What With Borrows

Every language stands on the shoulders of others. With is explicit
about its influences.

**From Rust:** ownership and borrow checking. Memory safety without
garbage collection. `Result[T, E]` error handling with `?`
propagation. Algebraic data types. Traits for polymorphism.
Exhaustive pattern matching. No null.

**From Zig:** `c_import` — parse C headers at compile time and call
C functions directly. `comptime` — compile-time evaluation and
generic specialization. Arena allocation patterns. Intern pools
with integer handles. Single-binary toolchain. The bootstrap
compiler was written in Zig.

**From Python:** indentation-based syntax. No braces, no semicolons.
Blocks are opened by `:` and closed by dedentation. String
interpolation with `"hello, {name}"`. The language reads top to
bottom like prose, not like a template engine.

**From Kotlin:** `it` as the implicit single-parameter closure
keyword. `items |> filter(it > 0)` instead of
`items.filter(x => x > 0)`. If a closure takes one argument
and the body is short, don't name it.

**From Go:** `defer` for deterministic cleanup. A single mandatory
formatter (`with fmt`) that ends all style debates. Zero-config
test runner (`with test`). The belief that tooling is part of the
language, not an afterthought.

**From Swift:** named arguments at call sites (`serve(app, port: 8080)`).
Default field values in structs. Strong type inference that rarely
requires annotation.

---

## Where With Diverges

### From Rust

Rust requires lifetime annotations. With doesn't. References in
With are **ephemeral** — they cannot be stored in structs, returned
from functions, or sent across thread boundaries. This eliminates
the need for `'a`, `'b`, `'static`, and the entire lifetime system.
The borrow checker still runs. It still prevents use-after-free,
dangling references, and data races. It just doesn't need you to
annotate the lifetimes yourself.

Rust requires `Pin`, `Unpin`, `Future`, `Poll`, `Waker` for async.
With uses **fibers** — lightweight threads with real stacks. References
work across `.await` points because the stack doesn't move. There is
no `Future` trait. There is no `Pin`. `async fn` spawns a fiber and
returns a `Task[T]`. `.await` suspends the current fiber. That's it.

Rust requires `Ok(())` at the end of fallible functions. With has
**implicit Ok wrapping** — if a function returns `Result[T, E]` and
the body evaluates to a `T`, the compiler wraps it in `Ok`
automatically. The happy path just returns the value. `?` handles
the sad path.

Rust's hello world is 44 bytes of source and 360K binary.
With's is 37 bytes and 33K.

### From Zig

Zig has no ownership model. With does. Zig trusts the programmer
to manage memory correctly and provides safety checks in debug
mode. With enforces safety at compile time through the borrow
checker — use-after-free is a compile error, not a runtime crash.

Zig requires explicit allocator parameters on every function that
allocates. With manages allocation through ownership — when a value
goes out of scope, its memory is freed. You can still use explicit
allocators when you need control, but the default case is automatic.

Zig's generics use `comptime` parameters: `fn foo(comptime T: type)`.
With uses familiar syntax: `fn foo[T]`. Both monomorphize. With
adds trait bounds: `fn foo[T: Display + Eq]` constrains what `T`
can be. Zig uses duck typing at comptime instead.

Zig's hello world is 95 bytes of source and 50K binary.
With's is 37 bytes and 33K.

### From Go

Go has a garbage collector. With doesn't. Go's concurrency model
(goroutines + channels) shares the concept of lightweight threads
with With's fibers, but Go provides no compile-time safety for
shared data. With's borrow checker prevents data races at compile
time.

Go has no generics worth mentioning (they arrived late and are
limited). With has full parametric generics with trait bounds,
associated types, and monomorphization.

Go has no sum types. `if err != nil` is the error handling story.
With has `Result[T, E]`, `Option[T]`, exhaustive `match`, `?`,
`??`, `?.`, and `let ... else`. Errors are values with types,
not nullable interfaces.

### From C

With is what C would be if designed today with safety in mind.
`c_import` means With can call any C library directly — same as
C calling C. But With adds: ownership tracking, borrow checking,
bounds checking, null safety, algebraic types, pattern matching,
closures, generics, and a module system.

`unsafe` exists for the places where C semantics are needed — raw
pointer derefs, memory-mapped IO, FFI pointer manipulation. Everything
outside `unsafe` is memory-safe by construction.

With compiles to native code through LLVM with a 33K hello world.
No interpreter, no VM, no JIT. The performance model is the same
as C: you pay for what you use, you can predict what the machine
does, and you can use every trick C programmers know — arenas,
pools, SIMD via `c_import`, inline assembly, custom allocators.

---

## The Language at a Glance

### Functions

```
fn greet(name: str):
    println("Hello, {name}!")

fn double(x: i32) -> i32: x * 2

fn main:
    greet("World")
```

No return type means `Unit`. No parens on zero-arg functions.
Single-expression bodies go on one line after the colon.

### Error Handling

```
fn load_config(path: str) -> Result[Config, Error]:
    let text = read_file(path)?
    let parsed = parse_toml(text)?
    validate(parsed)?
    parsed                          // implicit Ok wrapping

fn main:
    let config = load_config("app.toml") ?? Config.default()
    serve(config)
```

`?` propagates errors. `??` provides defaults. No `try`/`catch`,
no exceptions, no `if err != nil`.

### Closures and Pipelines

```
let result = users
    |> filter(it.active)
    |> filter(it.age >= 18)
    |> map(it.name |> uppercase)
    |> sort_by(it)
    |> take(10)

let total = items |> reduce(0, (acc, x) => acc + x.price)
```

`it` for single-parameter closures. `=>` for named parameters.
`|>` pipes data left to right through a chain of transformations.

### Pattern Matching

```
match response
    Ok({ users: [first, ..rest], total }) if total > 100 =>
        process(first, rest)
    Ok({ users: [], .. }) =>
        handle_empty()
    Err(.Timeout(duration)) if duration > 30.secs() =>
        retry()
```

Exhaustive. Nested destructuring. Slice patterns. Guards.
Variant shorthand (`.Timeout` instead of `Error.Timeout`).

### Concurrency

```
// Concurrent fetch — tuple await
let (user, posts) = (fetch_user(id), fetch_posts(id)).await

// Collection of futures
let results = ids |> map(fetch_user) |> await_all

// Structured concurrency
async scope |s|:
    let t1 = s.track(process_batch(batch_a))
    let t2 = s.track(process_batch(batch_b))
    (t1.await?, t2.await?)

// Fire and forget
spawn send_analytics(event)
```

Fibers with real stacks. No `Pin`. No `Unpin`. No `Future` trait.
References work across `.await`. One scheduler, no executor choice.

### C Interop

```
use c_import("sqlite3.h", link: "sqlite3")

fn query(db: &Database, sql: str) -> Result[Row, DbError]:
    let stmt = sqlite3_prepare_v2(db.handle, c"{sql}".ptr, -1)
    defer sqlite3_finalize(stmt)
    // ... use SQLite API directly
```

Parse C headers at compile time. Call C functions with zero
overhead. No wrapper generation, no binding layer, no marshaling.

### Freestanding

```
// ESP32, kernel module, bare metal
// No runtime, no stdlib, no allocator
use c_import("esp_gpio.h")

fn main:
    gpio_set_direction(GPIO_NUM_2, GPIO_MODE_OUTPUT)
    gpio_set_level(GPIO_NUM_2, 1)
```

Strip everything. Language primitives only. `c_import` talks
to hardware. You bring your own everything.

---

## Design Principles

**If the compiler knows it, don't type it.** No lifetime annotations.
No `Ok(())`. No return type on main. No parens on zero-arg functions.
No explicit `.iter()` on collections. Type inference handles the rest.

**One way to do it.** Indentation for blocks, always. `=>` for
"produces," always. `->` for return types, always. `with fmt`
enforces the one style. No configuration, no debate.

**Safety by default, control when needed.** The borrow checker runs
on everything. `unsafe` is the explicit opt-out for raw pointers.
`c_import` is the bridge to C. Freestanding mode strips the runtime.
Each layer of control is opt-in.

**The compiler is the product.** `with build`, `with test`,
`with fmt`, `with run` — one binary, one toolchain. No package
manager to install, no test framework to configure, no formatter
to argue about. It works out of the box.

---

## Numbers

| | With | Zig | Rust |
|---|---|---|---|
| Hello world source | 37 bytes | 95 bytes | 44 bytes |
| Hello world binary (stripped, macOS ARM64) | 33K | 50K | 360K |
| Garbage collector | No | No | No |
| Borrow checker | Yes | No | Yes |
| Lifetime annotations | No | N/A | Yes |
| `c_import` (C header parsing) | Yes | Yes | No |
| `comptime` | Yes | Yes | No |
| Algebraic types | Yes | No | Yes |
| Fibers (stackful async) | Yes | No | No |
| Freestanding mode | Yes | Yes | Yes |
| Self-hosted | Yes | Yes | Yes |