# Mutability and Calling Convention

With separates several concerns that other languages typically conflate under a single mutability keyword. This section defines the language's complete model.

## Overview

The model has these axes:

1. **Binding stability** — whether a name can be reassigned to a different value (`let` vs `var`).
2. **Value mutation** — whether a value's contents can change through methods or place operations (governed by the type's API and the borrow checker).
3. **Calling convention** — what happens to an argument when a function is called (default share-place or copy, `copy`, or `move`).
4. **Receiver mode** — how a method uses its receiver (`&self`, `mut self`, or `move self`).
5. **Effect summary** — the per-function record of how parameters are used (read, write, consume, escape_value, escape_view), inferred from the body and exported as part of the compiled interface.
6. **Effect pinning** — optional explicit declarations that lock in a function's effect contract for API stability.

These axes are independent. A binding can be stable while its value is mutated; a function can mutate an argument while the caller's binding is non-rebindable; a method can be a read-only view while its receiver binding is rebindable.

## Binding Stability

A binding's *stability* is whether the name can be reassigned. This is controlled by `let` and `var`:

- `let x = value` — stable. The name `x` cannot be reassigned. `x = new_value` is a compile error.
- `var x = value` — rebindable. `x = new_value` is permitted.

```with
let x = 5
x = 7         // ERROR: cannot reassign let-binding

var y = 5
y = 7         // OK
```

Binding stability is independent of value mutation. A `let` binding's value can still mutate through methods:

```with
let xs = Vec.new()
xs.push(1)        // OK — push mutates the place; let only restricts rebinding
xs = Vec.new()    // ERROR — cannot reassign let-binding
```

Function parameters and `with` bindings follow these rules:

- **Function parameters** are implicitly rebindable inside the function body. There is no `mut x: T` parameter modifier.
- **`with` bindings** are not rebindable. Mutations happen through the type's methods, not by rebinding the name.

```with
fn f(x: i32):
    x = x + 1     // OK — parameters are implicitly rebindable

with lock.write() as data:
    data = other  // ERROR — with-bindings are not rebindable
    data.push(1)  // OK — mutating through methods is unrelated to rebinding
```

## Value Mutation

A value's contents can be mutated through:

1. **Methods** declared with `mut self` receiver mode.
2. **Place operations** — assignment to fields, indexed places, or other lvalue contexts.
3. **Mutating function calls** — when a function takes a parameter by share-place (default for non-`Copy` types) and mutates it.

Value mutation is governed by the type's API and the borrow checker, never by binding keywords.

## Calling Convention

When a function is called, an argument is passed in one of three modes:

- **Default (`f(x)`)** — for `Copy` types, the value is copied. For non-`Copy` types, the function receives an *ephemeral shared-place alias* to the caller's place, valid for the duration of the call.
- **Copy (`f(copy x)`)** — the function receives an independent owned value, created by cloning. Requires the type to implement `Copy` or `Clone`.
- **Move (`f(move x)`)** — ownership is transferred to the function. The caller's binding is invalidated. Applies uniformly to Copy and non-Copy types.

The function body may use the parameter for any purpose: reading, mutating, consuming, returning, escaping. The body's use determines the function's effect summary. The call site must use a passing mode that satisfies the function's effects.

### Default Calls and Copy-ness

The default call mode behaves differently for Copy and non-Copy types:

- **For `Copy` types**, `f(x)` copies the value. The callee receives ownership of the copied value. No borrow of the caller's place persists after argument evaluation. The caller's `x` remains valid and any existing references to it are unaffected by the call.

- **For non-`Copy` types**, `f(x)` provides an ephemeral shared-place alias. The callee receives access to the caller's place for the duration of the call. The caller retains ownership; the destructor runs in the caller's scope.

This distinction matters for both safety and effect satisfaction. Default Copy calls automatically provide ownership through copying; default non-Copy calls do not.

```with
let n = 1
let r = &n            // reference to caller's n
bump(n)               // n is Copy; bump mutates its own copy
print(r)              // OK — caller's n unchanged; r still valid
```

For non-Copy types, the same code would be a borrow conflict: `bump(buf)` where `buf: Buffer` would take a write borrow during the call, conflicting with `r = &buf`.

### Call-Mode Satisfaction Table

The following table summarizes which call modes satisfy which effects:

| Effect         | Default `Copy`         | Default non-`Copy`           | `copy x`         | `move x`         |
|----------------|------------------------|------------------------------|------------------|------------------|
| `read`         | yes                    | yes                          | yes              | yes              |
| `write`        | local copy only        | yes, caller-visible          | local copy only  | yes, owned       |
| `consume`      | yes                    | no                           | yes              | yes              |
| `escape_value` | yes                    | no                           | yes              | yes              |
| `escape_view`  | no (copy dies)         | yes, with origin tracking    | no (copy dies)   | no (source dies) |

For `&T` parameters, `escape_view` is satisfied because the parameter type itself preserves the source across the call.

The "local copy only" entries for `write` mean that the function may mutate its parameter, but those mutations affect only the callee's owned copy; the caller's binding is unaffected.

### The Ephemeral Shared-Place Alias

For non-`Copy` types, the default `f(x)` does **not** transfer ownership. The function receives a temporary alias to the caller's place. The caller retains ownership across the call. The destructor does not run at function exit; it runs in the caller's scope when the caller's binding goes out of scope.

The parameter alias itself does not escape the call. A function may return a view that borrows from the caller's place under the `escape_view` effect (see below), but that view borrows from the caller's original place, not from the ephemeral alias.

A function whose effect summary on a non-Copy parameter includes only `read` or `write` can be called with the default mode. A function whose effect summary includes `consume` or `escape_value` for a non-Copy parameter requires the caller to use `move` or `copy`. A function whose effect summary includes `escape_view` is governed by view-origin lifetime tracking (see The Owned vs View Distinction below).

For Copy parameters, the default call provides ownership through copying, automatically satisfying `consume` and `escape_value` effects. The caller does not need to use `move` or `copy` explicitly for Copy types, though they may.

```with
fn rename(user: User):
    user.name = "Bob"        // body mutates; effect = write

fn store(user: User):
    global_users.push(user)  // body escapes owned value; effect = escape_value

let alice = User { name: "Alice", age: 30 }   // User is non-Copy

rename(alice)        // OK: write effect satisfied by share-place
store(alice)         // ERROR: escape_value on non-Copy requires move or copy
store(move alice)    // OK
store(copy alice)    // OK

fn id_i32(x: i32) -> i32:
    x                // escape_value effect

let n = 1
let m = id_i32(n)    // OK — i32 is Copy; default call provides ownership via copying
print(n)             // OK — n still valid
```

The key rule: **function bodies are unrestricted in what they do with parameters. Call sites must use a mode that satisfies the function's effects, accounting for the type's Copy-ness.**

### Parameter Rebinding

Local rebinding of a parameter inside the function body changes only the callee's local binding. The rebinding operation itself does not contribute to the parameter's effect summary on the caller's place.

```with
fn process(user: User):
    user = User { name: "Default" }  // local rebinding; no effect on caller
    user.name = "Bob"                 // local mutation of the rebound value
```

After this function returns, the caller's `user` is unaffected because the local rebinding replaced the parameter with a fresh local. The rebinding operation itself contributes nothing to the effect summary on the original parameter; only operations that touch the caller's place do.

However, evaluating the right-hand side of a rebinding assignment contributes effects normally:

```with
fn f(x: User):
    x = transform(x)    // assignment to x contributes nothing
                        // but the call to transform(x) contributes whatever
                        // effects transform has on its argument
```

If `transform(x)` has an `escape_value` or `consume` effect on its parameter, those effects propagate to `x`'s effect summary in `f`.

Effect contributions to the summary are:

- **`field = value` or `place[i] = value` on the parameter or its components** — contributes `write`.
- **Calling a `mut self` method on the parameter** — contributes `write`.
- **Passing the parameter to a function whose effect summary requires consume/escape** — contributes that effect transitively.
- **Returning or storing the parameter as an owned value** — contributes `escape_value`.
- **Internally consuming the parameter (moving it to another binding for use within the call)** — contributes `consume`.
- **Returning or storing a reference into the parameter** — contributes `escape_view`.
- **The local rebinding operation itself (`x = ...`)** — contributes nothing, though the RHS expression contributes effects normally.

This rule lets users freely rebind parameters as a normal idiom (`x = x + 1`, `x = transform(x)`) without forcing every caller to use `move` or `copy` — provided the RHS doesn't itself impose ownership-providing effects.

### `copy` and Trait Requirements

The `copy` annotation requires the type to support copying:

- For types implementing `Copy` (primitives, types explicitly declared `Copy`): `copy x` is permitted but redundant. The compiler may optimize it away.
- For types implementing `Clone` (heap-allocated containers, types with deep-copy semantics): `copy x` invokes the type's `clone` method to produce an independent owned value.
- For types implementing neither: `copy x` is a compile error.

```with
let n = 42
f(copy n)        // OK — i32 implements Copy

let xs = Vec.new()
f(copy xs)       // OK — Vec implements Clone

let lock = Mutex.new()
f(copy lock)     // ERROR — Mutex implements neither Copy nor Clone
```

**Note on `Clone` semantics.** For `Clone` types, `copy x` invokes user-defined clone code. This is not necessarily a bitwise copy. The clone implementation may allocate memory, log, panic, perform I/O, or do anything `Clone` allows. Users should not assume `copy x` is free; for `Copy` types it typically is, but for `Clone` types its cost depends on the type's implementation.

The keyword `copy` describes caller intent ("give the callee an independent value"). The mechanism is determined by which trait the type implements (`Copy` for bitwise copy, `Clone` for user-defined cloning).

### `move` Semantics

The `move` annotation transfers ownership to the function. After the call, the caller's binding is invalidated and may not be used. This applies uniformly to Copy and non-Copy types:

```with
let user = User { name: "Alice" }
store(move user)
print(user.name)  // ERROR — user has been moved

let n = 42
f(move n)
print(n)          // ERROR — n has been moved (even though i32 is Copy)
```

For Copy types, `move x` and `copy x` produce equivalent runtime behavior (both copy the value), but `move x` invalidates the source binding while `copy x` doesn't. The keyword reflects user intent: `move` declares ownership transfer; `copy` declares isolation while preserving the source.

### `Copy` vs Non-`Copy` Behavior at Call Sites

For `Copy` types, the default `f(x)` copies the value. Mutations inside the callee are local; the caller is unaffected.

```with
type Point: Copy { x: i32, y: i32 }  // explicitly opted into Copy

fn bump(p: Point):
    p.x += 1                    // local mutation; doesn't affect caller

let p = Point { x: 1, y: 2 }
bump(p)
print(p.x)  // still 1 — Copy types are passed by value
```

For non-`Copy` types, the default `f(x)` is share-place. Mutations affect the caller's place.

```with
type Buffer { data: Vec[u8] }  // non-Copy by default

fn append_byte(b: Buffer, value: u8):
    b.data.push(value)          // mutates caller's place

let buf = Buffer { data: Vec.new() }
append_byte(buf, 42)
print(buf.data.len())  // 1 — caller's buffer was modified
```

Users should understand:

- Copy types behave like primitives in C/Java/Python: pass-by-value semantics.
- Non-Copy types behave like Python objects (without GC): share-by-default with explicit `copy`/`move` for non-default semantics.

### Copy Is Opt-In for Aggregate Types

Primitives (i32, u8, bool, f64, char, etc.) are `Copy` by default — this matches every mainstream language's convention.

Aggregate types (structs, anonymous records, enums) are **non-Copy by default**, even if all their fields are Copy. The user opts in explicitly via `impl Copy for T` or equivalent declaration syntax.

```with
type Point { x: i32, y: i32 }              // non-Copy by default
type Pair: Copy { first: i32, second: i32 } // explicit Copy

let p = Point { x: 1, y: 2 }
bump(p)        // mutates p (share-place) — Point is non-Copy
print(p.x)     // shows the mutated value

let q = Pair { first: 1, second: 2 }
bump_pair(q)   // does NOT mutate q (copy) — Pair is Copy
print(q.first) // shows the original value
```

This rule prevents silent semantic changes from auto-derived Copy. If a user-defined struct's behavior at call sites should be "pass by value," the type must declare it.

Anonymous records (`{ x: i32, y: i32 }`) follow the same rule: non-Copy by default. If the user needs Copy semantics, they declare a named type with explicit Copy opt-in.

## Receiver Modes

Method declarations require an explicit receiver mode. There is no implicit default; every method must declare how it uses `self`. The receiver modes are:

- `fn len(self: &Self) -> usize` — read-only view. The method borrows `self` immutably; the caller's place is unchanged after the call.
- `fn push(mut self: Self, item: T)` — mutating-place. The method mutates `self`'s place; the place persists but contents may have changed.
- `fn into_bytes(move self: Self) -> Vec[u8]` — consuming. The method takes ownership; the caller's place is moved-from.

Methods are the type's API surface, and users read method signatures constantly. Requiring explicit receiver modes makes API contracts visible at a glance: a user reading `Vec` knows from the method signatures that `len` reads, `push` mutates, `into_bytes` consumes — without reading any bodies.

Plain `fn method(self: Self)` without a receiver-mode annotation is a compile error. Method authors must pick one of `&Self`, `mut Self`, or `move Self`.

This is the deliberate asymmetry between methods and free functions. Free functions don't require parameter mode annotations because they're not API-surface in the same sense; the borrow checker reports any actual misuse, and effect summaries are tooling-visible. Methods bear the extra ceremony because the documentation value justifies it.

### Receiver Modes vs Effect Summaries

Receiver modes classify the primary receiver access (read, write, or consume), but methods still receive full effect summaries for `self`, including `escape_view` origin tracking when a method returns or stores a view into the receiver.

```with
fn first(self: &Self) -> &T
    // Receiver mode: &Self (read-only)
    // Effect summary on self: {read, escape_view from {self}}

fn push_and_last(mut self: Self, item: T) -> &T
    // Receiver mode: mut Self (mutating)
    // Effect summary on self: {write, escape_view from {self}}
```

The receiver mode is a declared API contract on the receiver's primary use; the effect summary captures the complete relationship between the method and its receiver, including view returns. Both apply: receiver modes are the user-visible API surface; effect summaries are the full inferred behavior used by the borrow checker.

### Method Call-Site Behavior

The receiver mode determines how the method call interacts with the receiver binding:

```with
xs.len()         // &self method; treated as a read borrow on xs
                 // xs remains valid and unchanged

xs.push(item)    // mut self method; treated as a write borrow on xs
                 // xs is mutated; xs remains valid

xs.into_bytes()  // move self method; consumes xs
                 // xs is invalidated; cannot be used after this call
```

**No additional `move xs` annotation is needed at the call site for `move self` methods.** The method's receiver mode is part of its signature; invoking the method is sufficient to apply that mode to the receiver. Writing `move xs.into_bytes()` would be redundant.

This is consistent with the parameter-passing model: the call mode is determined by the function's API. For methods, the API is the receiver mode, visible in the signature. For free functions, the API is the effect summary, derived from the body.

```with
let xs = Vec.from([1, 2, 3])
let n = xs.len()           // OK — read borrow
xs.push(4)                 // OK — write borrow
let bytes = xs.into_bytes() // xs is now invalid
print(xs.len())            // ERROR — xs has been moved
```

## Effect Summaries

The compiler computes a per-function effect summary tracking how each parameter is used. Effects form a *set* per parameter — a function can have multiple effects on the same parameter. The effect categories are:

- **read** — the function observes the parameter's value.
- **write** — the function mutates the parameter's place through methods or place operations. Implies `read`.
- **consume** — the function takes ownership and uses the value internally (for example, moves it to another local binding for processing within the call). The value does not leave the call.
- **escape_value** — the function stores or returns the parameter as an owned value, beyond the call's lifetime.
- **escape_view** — the function returns or stores a reference into the parameter (origin tracking applies; see The Owned vs View Distinction below).

Effect strength forms a partial order: `read < write`. Other effects are independent of the read/write axis and of each other. A parameter's effect set might be `{read}`, `{write}`, `{write, escape_view}`, `{escape_value}`, `{write, consume}`, etc.

Effect summaries are derived from the function body during type-checking. They are not written by the user directly (with the exceptions of `&T` parameters and `@[effect(...)]` pins; see below).

Effect summaries are part of the function's compiled interface. They are exported alongside the type signature and used by the borrow checker at call sites in other modules.

### The Owned vs View Distinction

`escape_value` and `escape_view` are distinguished because they have different safety implications and different satisfaction rules at call sites.

**`escape_value`** is satisfied by `move`, `copy`, or default Copy passing:

```with
fn store_user(user: User):
    global_users.push(user)  // escape_value

store_user(move alice)   // OK — ownership provided
store_user(copy alice)   // OK — independent value provided
store_user(alice)        // ERROR — User is non-Copy; default share-place can't satisfy

fn store_int(n: i32):
    global_ints.push(n)  // escape_value

store_int(42)            // OK — i32 is Copy; default call provides ownership via copying
```

**`consume`** has the same satisfaction rules as `escape_value`: ownership must be provided. The distinction between consume and escape_value is semantic (whether the value's lifetime extends beyond the call), not about call-site mechanics:

```with
fn drop_it(x: User):
    let y = x          // consume; y goes out of scope at function end

drop_it(move alice)    // OK — alice transferred and dropped within drop_it
drop_it(copy alice)    // OK — copy transferred and dropped within drop_it
```

The distinction matters for some optimizations and for accurate error messages.

**`escape_view`** is governed by view-origin tracking and is **not** satisfied by `move`/`copy` for by-value parameters:

```with
fn first_user(xs: Vec[User]) -> &User:
    &xs[0]             // escape_view: returned reference originates from xs

let xs = Vec.from([alice, bob])
let first = first_user(xs)        // OK: view borrows from caller's xs
                                  // xs must remain valid as long as first is used

let first2 = first_user(move xs)  // ERROR: xs would die in callee;
                                  // returned view would dangle

let first3 = first_user(copy xs)  // ERROR: copy is a temporary that dies
                                  // when first_user returns; view would dangle
```

For `&T` parameters, view returns work normally because the parameter type itself preserves the source:

```with
fn first(xs: &Vec[User]) -> &User:
    &xs[0]

let users = Vec.from([alice, bob])
let first_user = first(&users)    // OK: view borrows from users via &T param
print(first_user.name)             // OK as long as users is valid
```

The rule: `escape_view` requires the source parameter to remain valid for the lifetime of the returned view. Default share-place (non-Copy) preserves the source. `&T` preserves the source. `move` invalidates it; `copy` produces a temporary that dies at function return — neither satisfies escape_view.

### View-Origin Tracking

When a function returns or stores a view derived from one or more parameters, the effect summary records which parameters the view may originate from. The returned view's lifetime is the intersection of the lifetimes of all possible origins.

```with
fn longest(a: String, b: String) -> &str:
    if a.len() > b.len():
        return a.as_str()
    else:
        return b.as_str()

// Effect on a: {read, escape_view from {a, b}}
// Effect on b: {read, escape_view from {a, b}}
```

At a call site:

```with
let s1 = String.from("hello")
let view: &str
{
    let s2 = String.from("world!")
    view = longest(s1, s2)   // returned view may originate from s1 or s2
}                            // s2 goes out of scope here
print(view)                  // ERROR: view may point into s2, which is dead
```

This is rejected because the view's lifetime is the intersection of `s1`'s and `s2`'s lifetimes, and `s2`'s lifetime ends before `view` is read.

Functions with single-origin views have correspondingly tighter summaries:

```with
fn first(a: String, b: String) -> &str:
    a.as_str()
// Effect on a: {read, escape_view from {a}}
// Effect on b: {read}  -- b is not an origin
```

Here `b` doesn't appear in the returned view's origin set, so its lifetime doesn't constrain the view.

Users do not write origin sets in source. The compiler infers them from the body. Tooling surfaces origin sets when relevant (in error messages, IDE hover, generated documentation).

### Combined Effects

A parameter can have multiple effects simultaneously. A common combination is `write` plus `escape_view`:

```with
fn push_and_last(xs: Vec[User], u: User) -> &User:
    xs.push(u)               // write effect on xs
    &xs[xs.len() - 1]        // escape_view effect on xs

// Effect on xs: {write, escape_view from {xs}}
// Effect on u: {escape_value}
```

The borrow checker treats combined effects with conservative ordering: existing live views into a parameter must not exist when a write effect occurs; a returned view becomes live after the function returns.

```with
let xs = Vec.from([alice])
let new_last = push_and_last(xs, bob)   // OK — no existing views
print(new_last.name)                     // OK — view from after the write
```

```with
let xs = Vec.from([alice])
let old_first = &xs[0]                   // existing view into xs
let new_last = push_and_last(xs, bob)    // ERROR — write conflicts with old_first
```

Functions with combined effects place stricter constraints on call sites; the borrow checker reports any conflicts.

### Effect Summary Changes as Interface Changes

Changing an exported function's effect summary is an interface change. Existing source-level callers may fail to compile if they relied on the previous effects. Existing compiled callers may require recompilation.

This is no different from changing a function's type signature: the interface changed, downstream code must adjust. With's effect summaries are part of the signature in this semantic sense, even though they're invisible in the source.

Tooling — IDE hover, generated documentation, error messages — surfaces effect summaries to users even though they don't appear in source. Users read effects through tools rather than through syntax.

### Borrow Checking via Effect Summaries

The borrow checker uses effect summaries to detect aliasing conflicts at call sites.

For non-Copy default calls, `f(x)` takes a borrow whose strength matches `f`'s effect on `x`:

- Read-only effect: shared (read) borrow.
- Write effect: exclusive (write) borrow.
- Consume or escape_value effect: requires `move x` or `copy x` (no default-call satisfaction for non-Copy).
- escape_view effect: shared borrow with lifetime tracking via the origin set.

For Copy default calls and explicit `copy x`, the callee receives an independent value, so no borrow of the caller's place persists after argument evaluation. Existing references to the caller's binding remain valid.

For `move x`, the caller's binding is invalidated; any existing references to it become invalid.

Multiple simultaneous shared borrows are permitted; multiple simultaneous exclusive borrows are not. Conflicts are caught statically:

```with
let first = &xs[0]
do_something(xs)
print(first)
```

If `do_something`'s effect summary includes a write to `xs`, this is rejected because the call would invalidate `first`. If `do_something` only reads `xs`, the code is accepted.

This is the borrow-checker discipline that gives With Rust-comparable safety without lifetime annotations: the user writes Python-shaped code, and the compiler infers and enforces the underlying safety properties.

## Effect Pinning

Functions can pin their effect summary explicitly via the `@[effect(...)]` attribute. This declares an authoritative contract that's exported as part of the function's interface.

> **Note on syntax:** The exact attribute syntax depends on With's general attribute system. The form shown here (`@[effect(name = effect_set, ...)]`) is illustrative; the actual syntax should match whatever the language adopts.

Effect pins serve API stability. Without pinning, a future change to a function body (adding mutation to a previously-read-only function, for example) silently changes the function's effect summary and breaks downstream callers. With pinning, the author can reserve effects from day one, even if the current body doesn't use them.

```with
@[effect(cache = write)]
pub fn update_cache(cache: Cache):
    print(cache.size)  // currently only reads, but pin reserves write
```

Future versions can add mutation without breaking callers:

```with
@[effect(cache = write)]
pub fn update_cache(cache: Cache):
    cache.size += 1    // OK; pin permits write
```

### Pin Semantics: Floor and Ceiling

An effect pin defines both a floor and a ceiling for the function's effects on the named parameter:

- **Floor**: the function's exported effect summary includes at least the pinned effects, even if the current body uses less. Callers must satisfy the pinned effects (or stronger).
- **Ceiling**: the function body cannot use effects stronger than (or orthogonal to) the pinned set. A pin of `write` permits `read` or `write` but rejects `consume`, `escape_value`, or `escape_view` in the body.

```with
@[effect(cache = write)]
pub fn update_cache(cache: Cache):
    global_cache_log.push(cache)  // ERROR: escape_value not permitted under write pin
```

To permit additional effects, the pin must declare them as a set:

```with
@[effect(cache = [write, escape_value])]
pub fn update_and_archive(cache: Cache):
    cache.size += 1
    archive.push(cache)   // OK — escape_value is in the pinned set
```

```with
@[effect(xs = [write, escape_view])]
pub fn push_and_last(xs: Vec[User], u: User) -> &User:
    xs.push(u)
    &xs[xs.len() - 1]
```

### Origin Sets and Pinning

Effect pins may pin the presence of `escape_view`, but origin sets are still inferred and remain part of the exported interface. The pin declares that the function returns a view; the compiler infers which parameters the view originates from based on the body.

```with
@[effect(result = escape_view)]
pub fn longest(a: String, b: String) -> &str:
    if a.len() > b.len():
        return a.as_str()
    else:
        return b.as_str()

// Pin: result has escape_view
// Inferred origin set: {a, b}
// Both are exported as part of the interface
```

Future spec versions may allow pinning origin sets explicitly (e.g., `@[effect(result = escape_view from {a})]`), but v1 keeps origin sets inferred to avoid additional syntax.

### Pin vs `&T`

`&T` and effect pins are complementary mechanisms with different roles:

- `&T` pins **read-only** with a no-write contract and a no-copy guarantee. The function is statically forbidden from writing to `&T` parameters. Used when an author wants the strongest read-only guarantee, including no-copy semantics.
- `@[effect(x = ...)]` pins arbitrary effect contracts: read-only, write, consume, escape, etc. Used when an author wants to reserve specific effects (most commonly `write`) for future API stability.

For pure read-only contracts, `&T` is the simpler tool. For reservable write or other effects, `@[effect(...)]` is the right mechanism.

### When to Pin

Pin effects when:

- The function is part of a public API and effect changes would break callers.
- The author plans to add an effect (typically `write`) in a future version and wants to reserve it now.
- The function's effect should be part of its documented contract regardless of body changes.

Don't pin effects for internal functions or rapid prototyping. Inferred effects are fine for most code; pinning is the deliberate ceremony for stable contracts.

## The `&T` Niche

The `&T` parameter type is preserved as an explicit contract: it pins both **no copy** and **no mutation through this parameter** in the function's signature. The function is statically forbidden from writing to `&T` parameters, regardless of the body.

`&T` is **not** the default for non-mutating parameters. Plain `T` is the default; the borrow checker derives the read-only effect from the body if the function doesn't actually mutate the parameter.

`&T` exists for three specific use cases:

1. **FFI** — C functions taking `const T*` map cleanly to `&T`. The C convention requires explicit pointer semantics with read-only intent.
2. **Library APIs with stable read-only contracts** — when the API author wants to publish "this function will never mutate this argument" as a stable contract that survives future implementation changes. Without `&T`, a future edit could add mutation to the body and silently change the function's effect summary; with `&T`, such an edit is rejected at the function's definition. `&T` is the right tool when the contract is specifically read-only; `@[effect(...)]` covers other contract shapes.
3. **Read-only views with no-copy guarantee** — when the caller needs the conjunction: no mutation AND no copy. `&T` provides both as a single contract.

For ordinary code, `&T` should not appear. Plain `T` parameters with effect-summary inference cover the common case. `&T` is the deliberate ceremony for the niche cases above.

## Closures

Closures capture environment variables according to the same calling-convention model:

- **For `Copy` types** (whether primitive or user-Copy aggregates), default capture copies the value. The closure has its own copy; mutations don't affect the original.
- **For non-`Copy` types**, default capture is share-place. The closure operates on the caller's place; mutations through the closure affect the original.
- **`move ||` closures** capture by ownership transfer regardless of Copy-ness. The closure owns its captures; the originals are invalidated.

Closure effect summaries are computed the same way as function effect summaries. The borrow checker treats closure invocation as a call against those effects.

```with
let xs = Vec.new()                     // non-Copy
let f = || xs.push(1)                  // captures xs by share-place
f()                                    // mutates xs

let n = 42                             // Copy
let g = || n + 1                       // captures n by copy
let m = g()                            // m is 43; n unchanged

let owned_xs = Vec.from([1, 2, 3])
let h = move || owned_xs.len()         // takes ownership
// owned_xs invalidated here
```

## Generic Functions

Generic functions infer effects from the body, just like non-generic functions. A function `fn id[T](x: T) -> T: x` has an `escape_value` effect on `x` because the body returns `x` as owned beyond the call.

Callers must satisfy effects with appropriate call modes:

```with
fn id[T](x: T) -> T:
    x

let user = User { name: "Alice" }     // User is non-Copy
let same = id(move user)               // OK — move provides ownership
let same = id(copy user)               // OK — copy provides ownership (requires User: Clone)
let same = id(user)                    // ERROR — id has escape_value; default share-place insufficient

let n = 42
let m = id(n)                          // OK — i32 is Copy; default call satisfies escape_value
```

Trait bounds are required only for operations the type parameter must support: `clone` requires `T: Clone`, comparison requires `T: Ord`, hashing requires `T: Hash`, storage with lifetime requirements may require `T: 'static`, etc. The basic call-mode mechanics (move, copy, default share-place) work without trait bounds.

```with
fn store_in_global[T](x: T):
    global_storage.add(x)  // escape_value

store_in_global(move user)  // OK
store_in_global(copy user)  // OK if User: Clone
store_in_global(user)       // ERROR if User is non-Copy — escape_value requires move or copy
                             // OK if User is Copy — default call provides ownership
```

The rule: generic functions inherit the same call-site discipline as concrete functions. The user doesn't need to learn special rules for generics.

## Summary Table

| Construct | Default | Annotation for non-default |
|---|---|---|
| Local declaration | (explicit choice) | `let` or `var` |
| `with` binding | Non-rebindable | (none — always non-rebindable) |
| Function parameter | Implicitly rebindable inside body | (none — always rebindable) |
| Argument passing, `Copy` type | Copy (provides ownership) | `move` (invalidates source) |
| Argument passing, non-`Copy` type | Ephemeral shared-place alias (read+write only) | `copy` (Copy/Clone required) or `move` |
| Method receiver | (no default; must be explicit) | `&Self`, `mut Self`, or `move Self` |
| Effect annotation in signature | None (inferred) | `&T` for read-only/no-copy, `@[effect(...)]` for general pinning |
| Aggregate type Copy-ness | Non-Copy by default | Explicit opt-in via `impl Copy` or `: Copy` |

The user-facing concepts: `let`/`var` for binding stability, `copy`/`move` at call sites for non-default argument semantics, `&Self`/`mut Self`/`move Self` for method receiver modes, `&T` for niche read-only contracts, `@[effect(...)]` for general effect pinning. The compiler does the rest internally via effect summaries with view-origin tracking.

## Rationale

### Why share-place by default

The default `f(x)` semantics matches what users usually want. Read-only function calls don't need annotation because reading is free under share-place. Mutating method calls don't need annotation because the mutation goes through the place naturally. Only ownership transfer (`move`) and explicit isolation (`copy`) need ceremony, and those are exactly the cases where the user is making a deliberate choice that deserves visibility.

This is more Python-shaped than Rust-shaped at the call site: a Python user who reads `f(xs)` understands that `f` may mutate `xs` (because Python lists are mutable) and can defensively copy with `f(xs.copy())` if they want isolation. With's `f(x)` and `f(copy x)` map to the same mental model, with the addition of `f(move x)` for ownership transfer (which Python doesn't have because it has GC).

The trade-off is signature-level documentation: in Rust, `fn f(x: &T)` tells you at a glance that `f` won't mutate `x`. In With, you have to read the body, the docs, or use tooling. This is a real ergonomic loss for library APIs, mitigated by tooling that surfaces effect summaries and by the optional `&T` annotation for authors who want explicit contracts.

### Why ephemeral non-escaping aliases

Without the ephemerality and non-escaping rules, "share-place" becomes an overloaded concept that hides several capabilities (consume, escape, return). The previous-language failure mode of `&mut` was exactly this conflation. Making the default explicitly *read+write but not consume/escape* gives the borrow checker a clean rule to enforce and gives users a precise mental model.

### Why function bodies are unrestricted

Unlike Rust, where the signature constrains what the body can do (a `&T` parameter cannot be mutated, regardless of body), With lets the body do anything. The effect summary is derived from the body; the call site must satisfy the effects.

This inversion has two benefits:

1. **No signature/body conflict.** The body never fights the signature. If the body needs to mutate a parameter, the inferred effect is `write`, and that's that. The author doesn't have to remember to update the signature.
2. **Caller-controlled isolation is explicit.** When the caller wants protection from mutation, they use `copy x`. The protection is visible at the call site, where the decision is being made, not at the function definition.

The cost is that signature-level documentation is reduced. Users reading a function signature can't tell at a glance whether the function mutates its argument; they need tooling or `&T` annotations.

### Why split owned-return from view-return

Owned return (`fn f(x: T) -> T: x`) and view return (`fn f(xs: Vec[T]) -> &T: &xs[0]`) have different safety implications. Owned return transfers a value; the caller provides ownership at the call site via `move` or `copy`. View return creates a reference relationship; the returned view's lifetime is tied to the source parameter, and `move`/`copy` doesn't make this safe — the source must remain valid as long as the view is used.

Conflating these would either over-restrict owned return (unnecessarily requiring lifetime tracking for value transfers) or under-protect view return (allowing returns of references to moved-from values). Splitting them produces precise rules for both cases.

### Why effect sets, not single effects

A function can write to a parameter and return a view into it (push_and_last). Single-effect summaries can't express this. Sets allow multiple orthogonal effects per parameter, with the borrow checker handling ordering conservatively.

### Why view-origin tracking instead of explicit lifetimes

Rust requires users to write lifetime annotations (`<'a>`) on functions that return views. With infers origin sets from the body and tracks lifetimes through the inferred sets. Users get the same safety guarantees without writing annotations.

The cost is that lifetime errors are reported by the borrow checker rather than the type checker, and may surface farther from the user's mental model. The mitigation is tooling: error messages and IDE hover surface origin sets when relevant.

### Why parameter rebinding is not a write effect

If rebinding counted as a write effect, every function that does `x = x + 1` internally would force callers to use `move` or `copy`, defeating the "parameters are implicitly rebindable" rule. Excluding rebinding from write effects keeps the rule consistent: parameters are local bindings inside the function; the body can rebind them freely; effects only track operations that touch the caller's place.

The RHS of a rebinding assignment still contributes effects normally — calling `transform(x)` and assigning the result to `x` propagates `transform`'s effects on `x` to the surrounding function's effect summary. Only the assignment operation itself is exempt; the expressions involved are subject to normal effect propagation.

### Why no parameter or with-binding mutability modifiers

Parameter rebinding inside a function body is rare-but-fine. Forcing `mut x: T` on every parameter that gets reassigned would be Rust-style ceremony tax for no real safety benefit — the borrow checker doesn't care about local rebinding because it doesn't affect callers.

`with` binding rebinding is almost always a mistake (it breaks the binding's connection to the source expression's place). Forbidding it eliminates a footgun without restricting useful patterns. Mutation through methods doesn't require rebinding, so the common case still works without ceremony.

### Why explicit receiver modes for methods

Methods are read more often than functions are. A user learning a type's API reads method signatures dozens of times: `Vec.push`, `Vec.len`, `Vec.iter`, `Vec.into_bytes`. Each method's receiver mode communicates important information about how the method uses `self`.

Requiring explicit modes (`&Self`, `mut Self`, `move Self`) makes this information visible at a glance. The cost is small ceremony at method declarations; the value is large for API consumers.

Free function parameters don't justify the same ceremony because they're not API-surface in the same way. The borrow checker catches misuse; effect summaries are tool-visible. For methods, the at-a-glance API readability is worth the explicit annotation.

### Why receiver modes don't replace effect summaries

A method like `fn first(self: &Self) -> &T` has receiver mode `&Self` (read-only contract on the receiver) but its effect summary on `self` includes `escape_view from {self}` because the return value borrows from `self`. The receiver mode declares the primary access; the effect summary captures the full picture.

Without this distinction, users might assume that a `&Self` method has no further effects on `self`, missing the borrow that the returned view creates. The two layers — declared receiver mode for API readability, full effect summary for borrow checking — work together.

### Why move on Copy invalidates the binding

`move x` is a deliberate annotation. The user wrote it because they meant "treat this as transferred." Honoring that uniformly across Copy and non-Copy types makes the keyword's meaning consistent: `move x` always invalidates `x`, regardless of type.

This also stabilizes refactoring: when a type changes from Copy to non-Copy or vice versa, call-site `move` annotations don't change behavior. The user can write `move x` everywhere they intend transfer, and the semantics are stable across type changes.

For Copy types, the runtime cost is identical to default passing (the value is copied either way), but the binding-invalidation gives the user explicit control over their own variable's validity.

### Why Copy is opt-in for aggregates

Auto-derived Copy for aggregates would silently change call-site semantics based on field composition. A struct with all-Copy fields would be Copy; adding a non-Copy field would silently change the struct to non-Copy and silently change every call site's semantics from copy to share-place. This is the kind of action-at-a-distance that breaks user mental models.

Opt-in Copy makes the choice deliberate and visible. The user declares Copy when they want pass-by-value semantics for an aggregate type. The default — non-Copy — matches the Python-shaped intuition for structs and produces stable semantics under refactoring.

Primitives are exempt from this rule because their Copy-ness is universal across languages and matches every user's intuition. Users coming from any language expect `f(5)` to copy the integer.

### Why Copy default calls satisfy escape_value

For Copy types, the default call already provides ownership through copying. Requiring `move` or `copy` annotations on every Copy argument that flows into a returning function would add ceremony for no safety benefit. The Copy semantics of "passing always provides an independent value" naturally satisfy ownership-providing effects.

### Why effect pinning

Inferred effects are good for the common case but create API instability: a body change can silently alter the exported effect summary. Effect pinning (`@[effect(...)]`) lets library authors lock in contracts for public APIs. The pin is both floor and ceiling: it declares the minimum effects callers must satisfy and the maximum effects the body may use. This gives stable contracts without forcing all functions into Rust-style explicit annotations — pinning is the deliberate ceremony for stable APIs, not a default.

### Why effect summaries instead of explicit annotations everywhere

Effect summaries inferred from the body trade signature-level documentation for source-level brevity. The user writes Python-shaped code; the compiler computes the underlying contracts; tooling surfaces them when needed. This is a different design point from Rust (where contracts are explicit in signatures) and from Python (where contracts are implicit and only checked at runtime). With sits between them: implicit at the source level, explicit at the tooling level, statically checked at compile time.

The cost is that signature changes can affect callers in non-obvious ways. The mitigation is that effect summary changes are interface changes — downstream callers fail to compile if they relied on previous effects. `&T` is available for authors who want to pin contracts explicitly and prevent silent effect changes from future body edits.
