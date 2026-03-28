# Compile-Time Programming Without Magic

One of the most powerful features in With is also one of the simplest to explain:

> **`comptime` lets you run normal code at compile time.**

No macros.
No separate language.
No AST manipulation.

Just code.

---

## The Problem With Macros

Most systems languages eventually need metaprogramming.

You want to:

* generate boilerplate
* specialize code for types
* avoid runtime overhead
* inspect types

Different languages solve this in different ways:

* C → macros (text substitution, unsafe)
* Rust → procedural macros (powerful, complex)
* C++ → templates (powerful, unreadable)

These approaches all have a problem:

> They introduce a *second language inside your language*

You stop writing normal code and start writing code that generates code.

---

## With’s Approach

With takes a different path:

> **Compile-time programming is just programming.**

```with
comptime fn hash_str(s: str) -> u64:
    var h: u64 = 5381
    for c in s.bytes():
        h = h * 33 + c as u64
    h

const ID = comptime hash_str("user_id")
```

That’s it.

* It looks like normal code
* It runs at compile time
* The result is embedded in the binary

No macros. No special syntax beyond `comptime`.

---

## Types Are Values

The real power comes from this idea:

> **At compile time, types are objects.**

You can inspect them directly:

```with
comptime fn print_fields[T: type]:
    for field in T.fields():
        println(f"{field.name}: {field.type_name}")
```

This is not reflection at runtime.

This is:

* zero cost
* fully type-checked
* resolved before your program even runs

---

## Derive Without Macros

In many languages, something like this requires macros:

```rust
#[derive(Serialize)]
struct User { name: String, age: i32 }
```

In With, this is just `comptime`:

```with
@[derive(Serialize)]
type User { name: str, age: i32 }
```

Under the hood, that’s just a function running at compile time:

```with
comptime fn derive_serialize[T: type]:
    for field in T.fields():
        // generate serialization code
```

The important part:

> **The generated code is just normal With code.**

It goes through:

* the type checker
* the borrow checker
* all the same rules as handwritten code

Nothing is “special.”

---

## Compile-Time Control Flow

`comptime` also gives you real branching:

```with
fn serialize[T](val: &T):
    comptime if T.is_copy():
        write_bytes(val)
    else if T.implements(Serialize):
        val.serialize()
    else:
        comptime_error("Type is not serializable")
```

This isn’t runtime branching.

* The wrong branches are **deleted**
* Only valid code is compiled

---

## No Hidden Magic

There are some strict rules:

* ❌ No I/O
* ❌ No network calls
* ❌ No FFI
* ❌ No runtime allocation

Everything must be:

* deterministic
* known at compile time

This keeps the model simple:

> If it compiles, you know exactly what code exists.

---

## Why This Matters

`comptime` isn’t just about convenience.

It enables things that would otherwise require:

* code generation tools
* build scripts
* macro systems

### Example: ECS Registration

```with
@[component]
type Transform { position: Vec3, rotation: Quat }
```

At compile time, this can generate:

* storage layout
* IDs
* query systems

No runtime cost. No manual wiring.

---

### Example: Zero-Cost Specialization

```with
fn process[T](val: &T):
    comptime if T.is_copy():
        fast_path(val)
    else:
        safe_path(val)
```

You get:

* specialization
* no dynamic dispatch
* no runtime checks

---

## Compared to Other Approaches

| Feature    | Macros             | Templates          | `comptime`    |
| ---------- | ------------------ | ------------------ | ------------- |
| Syntax     | Different language | Different language | Same language |
| Type-safe  | Often not          | Eventually         | Always        |
| Readable   | Often not          | Often not          | Yes           |
| Debuggable | Hard               | Very hard          | Normal        |

---

## Philosophy

With follows one rule everywhere:

> **If the compiler knows it, don’t make the programmer write it.**

`comptime` is the extension of that idea.

Instead of:

* writing boilerplate
* writing macros
* writing generators

You just write code.

---

## The Bigger Picture

`comptime` fits into a broader goal:

* remove lifetimes
* simplify async
* eliminate boilerplate
* keep performance

It’s not about adding power.

It’s about:

> **making powerful things feel normal**

---

## Closing

Most languages treat metaprogramming as something separate.

With doesn’t.

There is only one language.

And sometimes, it runs earlier.