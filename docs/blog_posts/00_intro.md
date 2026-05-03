# Intro to The With Programming Language

With is a systems programming language built around a simple idea:

> **What if you could have memory safety, native performance, and code that reads like you’d explain it to a colleague?**

No garbage collector. No lifetime annotations. No fighting the compiler for an hour to do something obvious.

```
fn main:
    print("Hello, World!")
```

37 bytes of source. 33K binary. Smaller than it has any right to be.

---

## The key insight

Most lifetime complexity comes from storing references in structs.

So With makes one rule: **you can’t store references in structs.**  
Instead, references are ephemeral. They exist only inside functions, only for a clearly visible scope. The compiler tracks them automatically—no annotations, no `'a`, no `'static`.

The language’s answer to lifetimes is a single keyword: **`with`**.  
Instead of annotating how long a reference lives, you state what you’re working with and let the scope handle the rest.

```with
// Guarded access: the lock releases automatically
with lock.read() as data:
    data.iter() |> filter(it.active) |> count()

// Builder pattern: the value is mutable inside, then frozen
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3

// Scoped binding: a named temporary that doesn’t leak
let area = with shape.bounding_box() as bb:
    bb.width * bb.height
```

The compiler is smart about it. The stdlib handles the tricky parts internally. If you hit a genuine edge case, `unsafe` is right there—no shame, no ceremony.

---

## Code that reads like Python, runs like C

With prioritizes joy. The common case is effortless.

**Functions.**  
Punctuation is minimal. Parentheses optional when you have no parameters. Return type only when you return something.

```
fn greet:
    print("Hello!")

fn add(a: i32, b: i32) -> i32:
    a + b
```

**Error handling.**  
Result type, `?` operator—but the happy path doesn’t need ceremony.

```
fn load_config(path: str) -> Result[Config, Error]:
    let text = read_file(path)?
    parse(text)                     // implicitly Ok(...)
```

No `Ok(())` to clutter your returns. No exception stacks to unwind. Errors are values, handled where they matter.

```
let config = load_config("app.toml") ?? Config.default()
```

**Pattern matching.**  
Concise, exhaustive, with guards and deep destructuring.

```
match response:
    Ok({ users: [first, ..rest], total }) if total > 100 =>
        process(first, rest)
    Err(.Timeout(t)) if t > 30.secs() =>
        retry()
```

**Pipelines and data flow.**  
A pipeline operator `|>` lets you express data transformations linearly, without deep nesting.

```
let active_names = users
    |> filter(it.active)
    |> map(it.name)
    |> take(10)
    |> collect()
```

`it` is an implicit parameter for single-argument closures. It disappears when you don’t need it.

---

## Async that feels synchronous

With’s async model uses lightweight fibers with real stacks, not compiler-generated state machines. That means:

- No function coloring: any function can call an async function.
- References work normally across `.await` points—no `Pin`, no `Future` trait.
- Standard iteration and async compose freely.

```with
let results = urls
    |> map(url => fetch(url).await)
    |> filter(r => r.is_ok())
    |> collect()
```

No special async iterators. No rewrite of your logic. Just normal control flow that happens to suspend when needed.

Structured concurrency is built in. You group tasks in a scope, and the language guarantees they all finish (or are cancelled) before you leave.

```
async scope s =>
    let user_task = s.track(fetch_user(id))
    let posts_task = s.track(fetch_posts(id))
    let (user, posts) = (user_task, posts_task).await
    Profile { user, posts }
```

Cancellation is cooperative and safe. Drop a task, and destructors run. No `TaskCancelled` variant needed on every error type.

For extreme connection density (100 K+), the standard library offers opt-in state-machine futures. Same `Task` type, same `.await`—just zero stack memory. Most code never needs them, but they’re there if you do.

---

## C interop that actually delivers on the promise

Every systems language says “easy C interop.” With makes it a reality with three simple tools.

### `c_import` — headers become native APIs

Import a C header at compile time. The compiler parses it and gives you fully typed, callable functions. No bindings, no glue.

```
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    var db: *mut sqlite3 = null
    sqlite3_open(":memory:", &mut db)
    defer sqlite3_close(db)
```

Null-terminated strings? `c"hello"` produces a `&CStr` in static memory. `void*` parameters auto-coerce when the intent is obvious. The compiler even spots `structname_do_something(self, …)` patterns and gives you idiomatic method syntax—`table.insert("key", "value")` instead of `g_hash_table_insert(table, …)`.

You stop fighting C’s rough edges. You just *use* the library.

### `with get c.<package>` — one command, fully linked

Dependencies are handled through Conan Center, the massive C/C++ package repository. No hunting for headers, no manual `-I` and `-l` flags.

```
with get c.sqlite3
with get c.glib
```

Your `with.toml` records the dependency. From that point on, `c_import` automatically finds the right include paths and link libraries. `with build` and it just works.

### `with migrate` — bring your existing C code with you

The biggest barrier to adopting a new systems language is leaving behind your existing codebase. With says: don’t leave it—migrate it gradually.

```bash
with migrate src/legacy/
```

The tool ingests a C library’s source, generates a clean `with.toml` module, wraps the public API in safe With functions, and gives you a project that compiles alongside your new code. It’s not a perfect automatic translator, but it handles the boilerplate: include paths, build setup, a native module you can start refactoring into idiomatic With at your own pace.

You can:

1. Take an existing C project.
2. Run `with migrate` to get a working With package that calls the C code under the hood.
3. Gradually replace C functions with With implementations, one file at a time, while the whole thing keeps compiling and running.

This means With slots into existing ecosystems without a rewrite cliff. You start using it *next to* your C code, not instead of it.

Together, `c_import`, `with get c.`, and `with migrate` make C interop not just possible but *effortless*. They’re the bedrock of a language that meets you where you are—and then takes you forward.

---

## The tools know what you mean

- **Auto-ref:** pass `alice` where `&User` is expected, and the compiler borrows for you.
- **Auto-deref:** `box_user.name` works through any number of indirections.
- **Optional chaining:** `user.address?.city` for nested Option access.
- **F-strings** as the one true formatter: `f"elapsed: {secs:.3}s"`.

The compiler catches real bugs at compile time—use-after-free, double-free, data races. But it stays out of your way for everything else. If you write something weird, it warns you. It doesn’t block you. You’re an adult.

---

## A single, coherent philosophy

**Make the common case delightful.**  
No lifetimes, no `Ok(())`, no `::new()` incantations unless you want them.

**Safe where it matters.**  
The hard guarantees are compile-time. The edge cases are handled by the standard library, not by infecting your code.

**Trust the programmer.**  
`unsafe` is there when you need it. No apologies, no secrecy.

**One toolchain, one formatter, one mental model.**  
`with build`, `with run`, `with test`, `with fmt`. Everything lives in a single binary. No config sprawl.

---

## Where With thrives

It’s built for the kind of software where control matters:

- Services and APIs
- Game engines and ECS
- Databases and query engines
- Infrastructure and tools
- Embedded systems (with `no_std` support, no heap required)

Any place you’d reach for a systems language but want less friction between you and the machine.

---

## If you’re curious

With is open source, MIT licensed and is available on GitHub.  

https://github.com/withlang-dev/with

Users, tinkerers, and contributors are welcome.

My dev log is here:

https://github.com/withlang-dev/with/discussions/185