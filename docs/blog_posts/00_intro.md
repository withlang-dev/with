# ✨ Improved Combined Blog Post

---

# With

With is a systems programming language built around a simple idea:

> **What if you could have Rust’s safety, without lifetimes — and without friction?**

It compiles to native code, has no garbage collector, and no runtime unless you ask for one.

```
fn main:
    println("Hello, World!")
```

37 bytes of source.
33K binary.
Smaller than Zig. Smaller than Rust.

---

## The Problem

Rust proved something important:

* Memory safety **can** be enforced at compile time
* You don’t need a garbage collector

But it also introduced something many developers struggle with:

**lifetimes**

They’re powerful — but they’re also the biggest barrier to adoption.

---

## The Core Idea

With removes lifetimes entirely by enforcing one rule:

> **You cannot store references in structs**

Instead:

* references are **scoped**
* references are **visible**
* references are **ephemeral**

The compiler never needs lifetime annotations — because lifetimes never escape.

You still get:

* no use-after-free
* no double-free
* no data races

But without `'a`, `'b`, `'static`, or borrow-checker gymnastics.

---

## What This Leads To

That one constraint naturally pushes code toward:

* **arenas**
* **handles instead of pointers**
* **data-oriented design**

Which turns out to be *better* for:

* cache locality
* serialization
* concurrency

This isn’t just simpler — it’s often the architecture you wanted anyway.

---

## Async Without the Pain

Async in With avoids the complexity people hit in Rust:

* no `Future`
* no `Pin`
* no state machines
* no async trait hacks

Instead:

* `async fn` runs on **lightweight fibers with real stacks**
* references work naturally across `.await`
* `.await` is just suspension — nothing more

```with
let results = urls
    |> map(fetch(it).await)
    |> collect()
```

No special async iterators.
No rewrite of your code.
Just normal control flow.

---

## C Interop as a Foundation

Interop isn’t an afterthought — it’s built in:

```
with init
with get c.sqlite3
```

* `c.*` pulls from Conan
* everything else pulls from git (like `go get`)

You can:

* import any C header
* call any function
* export any function

No bindings layer. No glue code. No ceremony.

---

## What With Borrows

Every language stands on the shoulders of others.

**From Rust**

* Ownership and borrow checking
* `Result[T, E]` + `?`
* Algebraic data types
* Pattern matching

**From Zig**

* `c_import`
* `comptime`
* Arena allocation
* Single binary toolchain

**From Python**

* Indentation-based syntax
* Readable, linear code
* String interpolation

**From Kotlin**

* `it` for implicit closures

```
items |> filter(it.active)
```

**From Go**

* `defer`
* Opinionated tooling
* Simplicity in workflows

---

## Where With Diverges

### From Rust

* No lifetimes
* No `Pin`, `Future`, `Poll`
* No `Ok(())`

You write:

```
fn load -> Result[Config, Error]:
    let text = read_file("config.toml")?
    parse(text)
```

The happy path just returns the value.

---

### From Zig

Zig gives control.

With gives:

* control **and**
* compile-time safety

You don’t choose between them.

---

### From Go

Go gives simplicity.

With gives:

* simplicity
* **and correctness guarantees**

No data races. No silent memory bugs.

---

### From C

With is what C would be if designed today:

* same performance model
* same control
* but with safety

---

## The Language at a Glance

### Functions

```
fn greet(name: str):
    println("Hello, {name}!")
```

No braces. No semicolons. No noise.

---

### Pipelines

```
let names = users
    |> filter(it.active)
    |> map(it.name)
    |> take(10)
```

---

### Error Handling

```
let config = load_config("app.toml") ?? Config.default()
```

No exceptions. No boilerplate.

---

### Pattern Matching

```
match response
    Ok({ users: [first, ..rest], total }) if total > 100 =>
        process(first, rest)
    Err(.Timeout(t)) if t > 30.secs() =>
        retry()
```

---

### Concurrency

```
let (user, posts) = (fetch_user(id), fetch_posts(id)).await
```

Structured. Predictable. No hidden machinery.

---

## Design Philosophy

**If the compiler knows it, don’t type it.**

* No lifetimes
* No redundant types
* No boilerplate

---

**Safety by default.**

* unsafe is explicit
* everything else is checked

---

**One way to do things.**

* one formatter
* one toolchain
* one mental model

---

## Real Work

With is designed for:

* services
* game engines
* infrastructure
* databases
* embedded systems

Anywhere you’d reach for Rust or C — but want less friction.

---

## Numbers

|                | With   | Zig | Rust    |
| -------------- | ------ | --- | ------- |
| Binary size    | 33K    | 50K | 360K    |
| GC             | No     | No  | No      |
| Borrow checker | Yes    | No  | Yes     |
| Lifetimes      | No     | N/A | Yes     |
| Async model    | Fibers | N/A | Futures |

---

## Closing

With isn’t trying to replace everything.

It’s trying to answer a specific question:

> **What if systems programming felt… easy?**

Not less powerful.
Not less safe.

Just — easier.

---

## If you're interested

I’m about a week away from release.

If you want early access or a walkthrough, reach out — I’d love feedback before it ships.

---
