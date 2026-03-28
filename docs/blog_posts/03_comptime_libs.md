# From Header-Only Libraries to Compile-Time Libraries

In C, there’s a well-known pattern:

> **header-only libraries**

Instead of compiling and linking a `.c` file, you just include a `.h` file — and everything works.

No linker errors.
No build system headaches.
Just drop it in and go.

This pattern shows up everywhere:

* stb libraries
* single-file game engines
* embedded codebases

It’s simple. It’s portable. It works.

But it’s also… a hack.

---

## Why Header-Only Exists

C doesn’t have generics.
It doesn’t have metaprogramming.
It barely has modules.

So developers found a workaround:

> **Just copy the code everywhere.**

That’s what `#include` really does.

```c
#include "mylib.h"
```

becomes:

```c
// literally paste the file here
```

To make this work, header-only libraries rely on:

* `static inline` functions
* macros
* include guards

And if you get it wrong?

* duplicate symbols
* linker errors
* undefined behavior

It’s powerful — but fragile.

---

## A Different Idea

Now consider a different approach.

Instead of copying code everywhere…

> **What if the compiler just ran your code at compile time?**

This idea comes from Zig:

> **Compile-time execution is just normal execution — moved earlier.**

With builds on that idea and integrates it into a language with:

* ownership
* borrow checking
* strong types

---

## With’s Version: Pure-Comptime Libraries

In With, you can write libraries that exist **only at compile time**.

No runtime code.
No linking.
No symbols.

Just:

* `comptime fn`
* type inspection
* code generation

---

### Example

```with
// serialize.with

comptime fn derive_serialize[T: type]:
    for field in T.fields():
        // generate serialization code
```

Use it:

```with
use serialize

@[derive(Serialize)]
type User { name: str, age: i32 }
```

What happens?

* The compiler runs `derive_serialize`
* Generates real code
* Type-checks it
* Emits it into your program

At runtime:

> **The library does not exist.**

Only the generated code remains.

---

## This Is Not Header-Only

At first glance, this looks similar to C header-only libraries.

But it’s fundamentally different.

### C:

* copies text
* hopes it compiles
* relies on macros

### With:

* executes code
* generates typed output
* verifies everything

---

## The Key Differences

### 1. No Text Substitution

C macros:

```c
#define MAX(a, b) ((a) > (b) ? (a) : (b))
```

No types. No safety.

With:

```with
comptime fn max[T](a: T, b: T) -> T:
    if a > b then a else b
```

Real code. Fully checked.

---

### 2. No Duplication Problems

Header-only libraries must carefully avoid:

* multiple definitions
* symbol collisions

With doesn’t have this problem.

Code is:

* generated once
* scoped correctly
* compiled normally

---

### 3. Zero Runtime Cost

Header-only libraries still exist in the binary.

With comptime libraries:

> **disappear completely**

They leave behind only the result.

---

### 4. Type-Driven Code Generation

With lets you *inspect types* at compile time:

```with
comptime fn debug_fields[T: type]:
    for field in T.fields():
        println(field.name)
```

This enables:

* serializers
* ECS systems
* database mappers
* protocol code

Without macros.

---

## Why This Matters

Header-only libraries were a workaround for missing features.

With turns that workaround into a **first-class capability**:

> **libraries that run at compile time instead of runtime**

This gives you:

* zero overhead
* full type safety
* no build complexity

---

## A Better Mental Model

Think of it like this:

* C → copy code
* Zig → execute code at compile time
* With → execute code at compile time **with guarantees**

---

## The Bigger Picture

With is trying to simplify systems programming:

* remove lifetimes
* simplify async
* eliminate boilerplate

`comptime` fits directly into that:

> Instead of writing generators, macros, or build scripts —
> you just write code.

---

## Closing

Header-only libraries were always a clever hack.

With makes them unnecessary.

Not by removing power —
but by making the compiler powerful enough that you don’t need the hack anymore.
