# Mutability Without `&mut` — Revision 8

**Status:** Draft proposal, revised
**Target:** With language specification, pre-v1 source cleanup
**Scope:** Remove user-facing `&mut` from safe With and replace it with a With-native mutation model
**Supersedes:** Mutability Without `&mut` (Revision 7)

---

## Summary

This proposal removes `&mut T` from the safe surface of With and establishes a complete model for mutation built around three principles:

> **Arguments are inputs.**
> **Mutation targets are lexically visible.**
> **Sharp tools live at the unsafe edge.**

Revision 1 captured the design philosophy. Revisions 2–6 added formal definitions, resolved tensions, and tightened semantics. Revision 7 fixed a self-contradiction between §13.5 and §19.5, formally added function parameters to the place-root table, and tightened "view" terminology. Revision 8 corrects an overclaim in §11.4 and §19.5: for-loop variables *are* places (per §2.1), but they are not place projections into the iterator's source collection. The actual reason mutation through `for x in xs.iter()` fails when the iterator yields `&T` is the existing read-only-view rule (§3), not a new for-loop-specific rule. Diagnostics, tests, and migration text are corrected accordingly.

---

## Goals

* Remove `&mut T` from ordinary safe With code.
* Preserve mutation ergonomics for local values, containers, parsers, builders, and scoped access.
* Make caller-visible mutation visually local and obvious.
* Avoid Rust-style lifetime annotations and borrow-region mental models.
* Keep function arguments simple: by-value inputs or read-only views.
* Keep C-style out-parameters available through raw pointers and `unsafe`.
* Avoid relying on unsound `noalias` assumptions for mutable parameters.
* Preserve existing memory-safety guarantees for `&T` views.

## Non-goals

* Removing all mutation.
* Making `let` mean deep immutability.
* Making With purely functional.
* Replacing raw pointers or FFI out-parameters.
* Building a Rust-like borrow checker with lifetime annotations.
* Inferring uniqueness for `noalias` optimization in v1.
* Supporting first-class function references to mutating receiver methods in v1.
* Supporting iterators that yield places into their source collection in v1 (see §19.5).

---

## 1. Core Principle

With separates **binding mutability** from **value mutability**.

A binding controls whether the name can be rebound. It does not freeze the object bound to that name.

```with
let xs = Vec.new()
xs.push(1)       // OK: mutates the Vec value
xs.pop()         // OK
xs = Vec.new()   // ERROR: `xs` is a non-rebindable binding

var ys = Vec.new()
ys.push(1)       // OK
ys = Vec.new()   // OK: `var` allows rebinding
```

A `let` binding is stable. It is not deeply immutable. Types decide which operations mutate their internal state. If a type exposes a mutating method, that method may be called on a *place* visible in the current lexical scope.

Read-only views (`&T`) do not allow mutation through the view.

---

## 2. Places (Formal Definition)

The mutation model is built on the concept of a **place**. This section is normative.

A **place** is a storage location that can be named or reached from a named storage root. Place identity is determined syntactically; it is not a runtime property.

Some places are **read-only**: they can be read from but not written to. Field projections from read-only places are read-only. Mutating operations (assignment, mutating receiver calls, `&raw mut`) are rejected on read-only places.

### 2.1 Roots

The following expressions are place roots:

| Root                                      | Example                              | Mutability |
| ----------------------------------------- | ------------------------------------ | ---------- |
| Local binding                             | `xs`                                 | Mutable    |
| Function parameter (owned)                | `xs` (in `fn f(xs: Vec[T])`)         | Mutable    |
| Function parameter (reference)            | `r` (in `fn f(r: &T)`); see §2.3 for `*r` | Binding is local; dereferenced target `*r` is read-only (§2.3) |
| Global or module-level binding            | `cache`                              | Mutable    |
| Captured lexical binding                  | `xs` (inside non-escaping closure)   | Mutable    |
| `with`-bound scoped binding (write guard) | `data` (in `with lock.write() as data`) | Mutable |
| `with`-bound scoped binding (read guard)  | `data` (in `with lock.read() as data`)  | Read-only |
| Compiler-created temporary place          | `__iter` (from `for` desugaring)     | Mutable    |
| `for`-loop variable                       | `x` (in `for x in iter:`)            | Mutability of yielded item; see §11.4 |
| Dereferenced safe reference               | `*r` for `r: &T`                     | Read-only  |
| Dereferenced const raw pointer (unsafe)   | `*p` for `p: *const T`               | Read-only (unsafe) |
| Dereferenced mut raw pointer (unsafe)     | `*p` for `p: *mut T`                 | Mutable (unsafe) |

The mutability of a root determines the mutability of the place. For example, `*r` for `r: &User` is a read-only place; the projection `(*r).name` is also read-only; assignment to `(*r).name` is rejected.

#### Function parameters

Function parameters are local bindings within the function body. An ordinary owned parameter (e.g., `xs: Vec[T]`) produces a mutable place — the function may call mutating receiver methods on it, assign to its fields, or take `&raw mut` of it. A reference parameter (e.g., `r: &T`) is itself a local binding holding the reference value; the dereferenced target `*r` is a read-only place per §2.3.

The receiver-place mode `mut self: Self` (§5.1) is a special case that operates on the caller's place rather than producing a new owned local; it is not an ordinary owned parameter.

### 2.2 Projections

Given a place P, the following projections produce places:

| Projection                          | Example                          | Condition                  |
| ----------------------------------- | -------------------------------- | -------------------------- |
| Field of struct                     | `P.field`                        | Always                     |
| Field of tuple                      | `P.0`, `P.1`                     | Always                     |
| Indexed access                      | `P[i]`                           | Type implements `IndexPlace` (§2.4) |
| Raw pointer projection (unsafe)     | `(*p).field`, `p[i]` inside `unsafe` | Always inside `unsafe`, with mutability inherited from `p` |

Projections inherit the mutability of the base place. A projection from a read-only place is read-only; a projection from a mutable place is mutable.

### 2.3 Dereferenced safe references

For a safe reference `r: &T`, the expression `*r` is a read-only place expression. Field projections through `*r` are read-only places (assignment to them is rejected), and mutating receiver methods cannot be called through `*r`.

```with
fn print_age(u: &User):
    let age = (*u).age               // OK: reads field through dereferenced reference
    print(age)

fn bad(u: &User):
    (*u).age = 31                    // ERROR: cannot assign through dereferenced &T
    (*u).rename("Bob")               // ERROR if `rename` is a mutating receiver method
```

Note: in expressions where the deref applies to the whole reference, parentheses are required because `*` has lower precedence than `.`. Writing `*u.age` parses as `*(u.age)` — dereferencing the field — which is a type error since `u.age` is not a reference. Use `(*u).age` to dereference `u` and then access the `age` field.

#### Auto-deref sugar

Where With's existing rules permit auto-dereference, `u.age` is sugar for `(*u).age`. The place semantics are identical: both produce a read-only place projection from the dereferenced reference. The explicit form `(*u).age` is always available; the sugared form is available wherever the language permits auto-deref.

```with
fn print_age(u: &User):
    let a1 = (*u).age                // explicit
    let a2 = u.age                   // auto-deref sugar (if permitted by With's rules)
    // a1 and a2 produce the same read-only place
```

This rule allows `&raw const *r` (taking a raw const pointer to a referenced value, §13.2) to work without ambiguity, and it makes the semantics of reading through a reference uniform with the rest of the place model.

### 2.4 Indexed projections require `IndexPlace`

`P[i]` is a place projection only when the type of P implements `IndexPlace`. Types that only support value-returning indexing (`IndexGet`) do not produce a place from `P[i]`; assignment or mutating receiver calls through such expressions are rejected.

#### `IndexPlace` is a syntax trait

`IndexPlace` is a **syntax trait**: it grants the compiler permission to treat `P[i]` as a place projection into `P`. Its implementation provides compiler-recognized operations for reading, writing, and scoped access to the indexed element without requiring value-copy semantics. The exact lowering is implementation-defined, but it must preserve normal ownership and `Drop` rules.

In particular, nested place mutation through `P[i]` — including field assignment (`xs[i].field = value`), mutating receiver calls (`xs[i].method()`), and compound assignment (`xs[i].field += 1`) — must be performed without copying the indexed element out and back. The compiler operates on the underlying storage directly, the same way it would for a struct field projection.

#### Reasoning

If `P[i]` were lowered as `P.get(i)` returning a value followed by `P.set(i, modified)`, several problems arise:

* For non-`Copy` element types, the get-by-value step would move the value out of the container, leaving the container in an invalid state during the expression.
* For types with `Drop`, the read-modify-write pattern would invoke `Drop` on intermediate values unnecessarily.
* For types with identity (pinned, self-referential, intrusive list nodes), the address change would break invariants.

Treating `P[i]` as a place projection avoids all of these issues.

#### Trait shape

```with
trait IndexGet[I, V]:
    fn get(self: &Self, index: I) -> V
    // Value-returning indexing. P[i] is not a place.

trait IndexPlace[I, V]:
    // Compiler-recognized place projection contract.
    // Implementations grant the compiler permission to treat P[i] as a place
    // projection of P. The compiler generates lowering for read, write, and
    // scoped access to the indexed element directly on underlying storage.
    //
    // Implementations must provide the operational contract recognized by the
    // compiler. The exact form of this contract is implementation-defined and
    // may evolve; user types typically obtain IndexPlace through a standard
    // pattern provided by stdlib (e.g., for Vec-shaped containers) rather than
    // implementing it from scratch.
```

`Vec[T]`, `Array[N, T]`, and similar dense collections implement `IndexPlace` via stdlib-provided support. Read-only views and value-shaped indexers (e.g., a function-like `f(x)` table) implement only `IndexGet`.

For simple assignment `xs[i] = value` and value reads `let v = xs[i]`, the conceptual lowering is "write through the place" and "read through the place" respectively. The compiler may optimize these to direct memory operations or to method calls on the implementing type, as long as ownership and `Drop` are preserved.

User-defined containers requiring `IndexPlace` should follow the standard pattern (to be specified in the stdlib documentation) rather than attempting to implement the syntax trait directly. v1 may restrict `IndexPlace` to stdlib-provided container types.

### 2.5 What is *not* a place

The following are explicitly **not** places, even when their value type would allow place operations:

* **Function call results.** `get_vec()` is a value, not a place.
* **Method call results that return by value.** `parser.peek()` is a value.
* **Arithmetic and other expression results.** `a + b`, `f(x).clone()`.
* **Index access through a function call result.** `get_vec()[0]` is not a place because `get_vec()` is not a place.
* **Field access through a function call result.** `get_user().name` is not a place.
* **Index access on a type that implements only `IndexGet`.** Result is the indexed value, not a place.

### 2.6 Place expressions are syntactic

Whether an expression is a place is determined by its syntactic form (and, for indexing, by the type's trait implementation), not by runtime behavior. This means:

```with
let xs = get_vec()    // OK: `xs` is now a place (Vec implements IndexPlace)
xs.push(1)            // OK
xs[0] = 5             // OK: place projection through IndexPlace

get_vec().push(1)     // ERROR: temporary is not a place
```

This rule is intentional. Allowing function results to be places would require dataflow analysis to determine which calls return references to existing storage. With v1 avoids that complexity by making the rule purely syntactic.

### 2.7 Mutating receiver requires a mutable place

Mutating receiver methods (`mut self: Self`) require their receiver to be a mutable place. Calling a mutating method on a non-place, on a read-only place (`*r` for `r: &T`, or a projection therefrom), or on a `*const T` dereference, is rejected at compile time:

```with
get_vec().push(1)
// ERROR: mutating receiver `push` requires a place
// help: bind to a local first: `let xs = get_vec(); xs.push(1)`

fn bad(r: &Vec[i32]):
    (*r).push(1)
// ERROR: cannot call mutating method through dereferenced read-only reference

fn bad_const_ptr(p: *const Vec[i32]):
    unsafe { (*p).push(1) }
// ERROR: cannot call mutating method through *const dereference
```

Read-only receiver methods (`self: &Self`) and consuming receiver methods (`self: Self`) work on any expression of the appropriate type, place or not.

---

## 3. Reference Types

Safe With has one reference type:

```with
&T       // read-only ephemeral view
```

`&mut T` is removed from the source language entirely. It does not appear in:

* Function parameters
* Return types
* Let bindings
* Type annotations
* Method receivers (use `mut self: Self` instead)
* Trait method signatures

A reference is an ephemeral read-only view. It may be passed to functions, bound locally, and returned subject to existing ephemeral rules. It may not be used to mutate the referenced value.

```with
fn print_user(u: &User):
    print(u.name)              // auto-deref sugar; equivalent to print((*u).name)

fn bad(u: &User):
    u.name = "Bob"             // ERROR: cannot mutate through read-only view
    u.rename("Bob")            // ERROR if rename is a mutating receiver method
```

This rule applies wherever an `&T` value appears, including loop variables bound from iterators that yield `&T` (see §11.4).

Auto-reference creates `&T` views only:

```with
fn print_user(u: &User): print(u.name)

let user = User { name: "Alice" }
print_user(user)          // compiler inserts read-only view
```

There is no auto-reference to `&mut T`, because `&mut T` no longer exists.

---

## 4. Function Arguments

Function arguments are inputs. A function parameter is either:

1. an owned value, or
2. a read-only view.

A function cannot mutate a caller's local value by receiving a mutable reference to it.

```with
fn use_user(u: &User):
    print(u.name)              // read-only

fn normalize(xs: Vec[i32]) -> Vec[i32]:
    xs.sort()                  // mutates the function's owned local
    xs                         // caller receives the transformed value
```

Calling a function with an owned value moves the value into the function unless the type is `Copy`. Any mutation performed by the function is mutation of the callee's owned value. The caller does not observe that mutation unless the value is returned.

```with
fn push_one(xs: Vec[i32]) -> Vec[i32]:
    xs.push(1)
    xs

let xs = Vec.new()
let xs2 = push_one(xs)         // xs moved; xs2 receives the modified Vec
```

This replaces out-parameters with return values. For multiple outputs, return a tuple or named record.

---

## 5. Mutating Receiver Methods

Mutation is primarily expressed through mutating receiver methods, declared with `mut self`:

```with
extend Vec[T]:
    fn push(mut self: Self, value: T): Unit
    fn pop(mut self: Self) -> Option[T]
    fn clear(mut self: Self): Unit
    fn len(self: &Self) -> usize
```

### 5.1 Receiver-place mode

`mut self: Self` is a **receiver-place mode**, not a normal by-value parameter. Specifically:

* The receiver must be a mutable place at the call site (§2).
* The method has scoped in-place access to that place for the duration of the call.
* The receiver is not moved by the call; the place remains valid afterward.
* This mode exists only in receiver position. It cannot be expressed as an ordinary free-function parameter.

The type annotation `Self` indicates the receiver's type. The `mut` modifier indicates the receiver-place mode. Together they form a distinct construct from any by-value or by-reference parameter form.

```with
let xs = Vec.new()
xs.push(1)              // OK: mutating receiver on a mutable place
let n = xs.len()        // OK: read-only receiver
xs.push(2)              // OK: xs is still a valid place after the previous push
```

A mutating receiver method cannot be called through a read-only view, through a dereferenced read-only reference, or through a `*const T` dereference:

```with
fn bad(xs: &Vec[i32]):
    xs.push(1)           // ERROR: cannot call mutating method through &Vec[i32]
    (*xs).push(1)        // ERROR: *xs is a read-only place

fn bad_const(p: *const Vec[i32]):
    unsafe { (*p).push(1) }   // ERROR: *p is a read-only unsafe place
```

### 5.2 Receiver Modes

| Receiver         | Semantic                                  | Requires mutable place |
| ---------------- | ----------------------------------------- | ---------------------- |
| `self: &Self`    | Read-only view                            | No                     |
| `mut self: Self` | Receiver-place mode (in-place mutation)   | Yes                    |
| `self: Self`     | Consuming receiver (moves the value)      | No                     |

The `mut` keyword in `mut self` is a binding-mutability modifier at the receiver position, consistent with the `let`/`var` distinction for local bindings. It is not a type modifier; the receiver type remains `Self`.

`&mut self` is not valid syntax in With.

### 5.3 Mutating methods are not first-class in v1

In v1, mutating receiver methods cannot be referenced as first-class function values directly:

```with
let f = Vec.push       // ERROR in v1: cannot reference mutating method as a value
```

The reason is type-system: the type of such a reference would need to be a place-based function type (e.g., `Place[Vec[T]] -> T -> Unit`), which v1 does not provide.

To pass a mutating method as a callback, wrap it in a closure that operates on a place:

```with
let f = (xs, value) => xs.push(value)
```

This restriction may be revisited in a future revision if a place-based function type is added.

### 5.4 Nested mutating calls and evaluation order

When multiple mutating receiver calls appear in a single expression involving the same place, they execute in left-to-right argument evaluation order, with each call's mutation visible to subsequent calls.

```with
xs.push(xs.len())
// 1. xs.len() evaluates first, returns the current length as a value
// 2. xs.push(length_value) executes, mutating xs

xs.push(xs.pop().unwrap())
// 1. xs.pop() executes first, mutating xs and returning Option[T]
// 2. .unwrap() runs on the Option (no mutation)
// 3. xs.push(unwrapped_value) executes, mutating the now-popped xs
```

This is well-defined because place access is sequential within an expression. The compiler must guarantee that each mutating call completes before the next argument is evaluated.

### 5.5 Argument independence in mutating receiver calls

The interaction between §5.4 (nested mutating calls work via sequencing) and §8.3 (conflicting accesses in the same call are rejected) is resolved by the **argument independence** rule.

For a mutating receiver call, argument expressions are evaluated left-to-right before the receiver mutation begins. Reads or mutations that complete before the receiver call and produce **independent values** are permitted. Conflicts arise only when an argument retains access to the same place, moves the same place, or creates another live access that overlaps the receiver mutation.

#### Independent values

An independent value is a value type whose contents do not include a view of, iterator over, guard for, or owned move of the place being mutated. The same definition as in §9 closure captures applies:

* **Independent values:** primitive copies (`xs.len()`, `xs.is_empty()`), cloned values (`xs[0].clone()`), computed values (`xs.len() * 2`), values returned from completed mutating calls (`xs.pop().unwrap()`).
* **Non-independent (retain access):** read-only views (`&xs`, `&xs[0]`), iterators (`xs.iter()`, `xs.entries()`), guards (`xs.lock()`), owned moves of the place itself.

#### Examples

```with
xs.push(xs.len())
// OK: xs.len() returns an independent usize value before push begins.

xs.push(xs.pop().unwrap())
// OK: xs.pop() completes (mutating xs) before xs.push() begins.
//     The returned T is an independent value.

xs.push(xs.iter())
// ERROR: iterator retains access to xs; would conflict with push's mutation.

xs.push(&xs[0])
// ERROR: read-only view of xs[0] would be invalidated by push (potential reallocation).

xs.update(xs[0].clone())
// OK: clone produces an independent value.

xs.update(xs[0])
// ERROR if T is not Copy: would move xs[0] while xs is being mutated.
```

This rule resolves the apparent tension between §5.4 and §8.3: §8.3 rejects truly conflicting accesses; §5.4 enables nested mutating calls because their results are independent values.

---

## 6. Field, Index, and Compound Assignment

### 6.1 Field assignment

Field assignment desugars to a place mutation:

```with
user.age = 31
```

This requires `user.age` to be a mutable place (which requires `user` to be a mutable place, since field projection from a place yields a place of the same mutability). Field assignment cannot be performed through a read-only view or a dereferenced read-only reference.

```with
fn bad(u: &User):
    u.age = 31             // ERROR: cannot assign to field through read-only view
    (*u).age = 31          // ERROR: cannot assign through dereferenced &T

fn ok(user: User) -> User:
    user.age = 31          // OK: owned parameter is a mutable place (§2.1)
    user                   // return modified value
```

### 6.2 Index assignment and nested mutation

Index assignment is supported by any type implementing `IndexPlace` (§2.4). Because `IndexPlace` is a syntax trait granting compiler-recognized place projection, the desugaring is not a simple `get`/`set` macro expansion — it is performed by the compiler with full place semantics.

#### Direct assignment

```with
xs[i] = value
```

For types implementing `IndexPlace`, this writes `value` to the indexed slot directly. The index expression `i` is evaluated once. The lowering is implementation-defined but preserves ownership and `Drop` rules: any value previously in the slot is dropped according to its `Drop` impl, and `value` is moved (or copied if `Copy`) into the slot.

#### Nested assignment and method calls

```with
xs[i].field = value
xs[i].method()                // mutating receiver call
```

These forms work because `IndexPlace` exposes `P[i]` as a place projection. The compiler operates on the indexed slot directly without copying the element out and back. For non-`Copy` element types, this is the only correct lowering — a get-then-set sequence would move the element out of the container mid-expression.

#### Types implementing only `IndexGet`

Types implementing `IndexGet` but not `IndexPlace` do not support index assignment or nested place operations through `P[i]`:

```with
let view = ReadOnlyTable.new()
view[0]                       // OK: returns the value at index 0
view[0] = 5                   // ERROR: ReadOnlyTable does not implement IndexPlace
view[0].method()              // ERROR if `method` is mutating; OK if read-only
```

### 6.3 Compound assignment

Compound assignment operators (`+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`) read the target place once, compute the new value, and write back to the same place. The base place expression and any projection expressions are evaluated **exactly once** in source order.

For a simple binding:

```with
counter += 1
// Evaluates as: read counter, compute counter + 1, write to counter
```

For a field projection:

```with
user.age += 1
// Evaluates as: read user.age, compute user.age + 1, write to user.age
// (user is evaluated once)
```

For an indexed projection:

```with
xs[f()] += g()
```

is evaluated conceptually as:

```with
let __idx = f()                        // f() evaluated once
let __new = (read xs at __idx) + g()   // g() evaluated once, value read once
(write xs at __idx, __new)             // value written once
```

For `IndexPlace` types, the read and write happen as place operations on the same projection, not as a `get`/`set` pair that materializes the element by value.

For compound projections (e.g., `xs[i].field += 1`), the rule recurses: each step of the projection chain is evaluated once, and the read/write occurs at the final place. The element at `xs[i]` is not copied out; the field is mutated in place through the chain.

The single-evaluation rule is required for soundness: side-effecting index expressions or side-effecting argument expressions must not be duplicated.

---

## 7. Lexical Mutation

Caller-visible mutation should be lexical. The mutation target should appear directly in the scope where the mutation happens:

```with
var xs = Vec.new()
items |> for_each(xs.push(it.value))
```

or:

```with
let xs = Vec.new()
for item in items:
    xs.push(item.value)
```

This is the With replacement for passing mutable out-parameters.

```with
// Not With style:
fn collect_values(items: Items, out: &mut Vec[i32]):
    for item in items:
        out.push(item.value)

// With style:
fn values(items: Items) -> Vec[i32]:
    let xs = Vec.new()
    items |> for_each(xs.push(it.value))
    xs
```

---

## 8. Access Conflicts

When two place accesses target related memory, the language must determine whether the accesses conflict. This section establishes the access conflict rules for v1.

### 8.1 Disjoint paths

Two place expressions are **statically disjoint** if their paths from a common root differ at any point by a different field name or different statically-known tuple index.

```with
pair.0.push(1)
pair.1.push(2)         // OK: tuple fields .0 and .1 are statically disjoint

config.database.host = "x"
config.cache.host = "y"   // OK: fields `database` and `cache` are disjoint
```

### 8.2 Indexed paths

Two place expressions that share an indexed projection from the same base are **considered overlapping** in v1, even if the indices are statically different:

```with
xs[0].update()
xs[1].update()           // OK individually, but conflict in same call:

xs[0].update(xs[1])      // ERROR: two accesses through indexed base `xs`
```

The conservative rule avoids requiring runtime checks or dataflow analysis. It rejects programs that may be safe but would require non-trivial proof.

Workarounds for legitimate disjoint indexed access:

```with
// Clone the second value:
let other = xs[1].clone()
xs[0].update(other)

// Use a disjoint-access API exposed by the container:
with xs.get_disjoint(0, 1) as (a, b):
    a.update(b)
```

Container types may provide disjoint-access methods (`get2`, `split_at`, `get_disjoint`, etc.) that prove disjointness through their API contract.

### 8.3 Conflict at call sites

Within a single function call, if two arguments evaluate accesses that conflict, the call is rejected:

```with
xs[0].update(xs[1])         // ERROR: conflicting indexed accesses
update(xs[0], xs[1])        // ERROR: same conflict, free function form
```

If the conflicting access is read-only on one side and mutating on the other, the conflict still applies. Two read-only accesses to the same place do not conflict.

This rule is moderated by §5.5 for mutating receiver calls, where argument independence determines whether a conflict actually exists.

### 8.4 Read-only views and mutation

A live `&T` view of a place creates an obligation: no mutation may occur to that place (or any overlapping projection) while the view is live. Violating this rule may invalidate the view (e.g., by reallocating a Vec's buffer, leaving a reference dangling).

#### Rule

A mutating access to a place P conflicts with any live read-only view of P or of any place containing P or contained by P. The view is live from its creation until its last use within the enclosing scope (non-lexical liveness).

```with
let xs = Vec.new()
xs.push(0)
let first = &xs[0]      // read-only view, live from here...
xs.push(1)              // ERROR: mutating xs while `first` is live
print(first)            // ...until last use here
xs.push(2)              // OK: `first` is no longer live
```

```with
let user = User { name: "Alice", age: 30 }
let name_view = &user.name
user.age = 31           // OK: `user.age` does not overlap `user.name`
print(name_view)
```

```with
let user = User { name: "Alice", age: 30 }
let name_view = &user.name
user.name = "Bob"       // ERROR: mutating `user.name` while view is live
print(name_view)
```

#### Liveness semantics

The view is live until its last use. After the last use, mutation of the underlying place becomes legal again. This is non-lexical liveness, equivalent to Rust's NLL semantics.

This rule is the only borrow-checker-shaped analysis in v1. It does not require lifetime variables, region inference, or annotations. The compiler tracks per-place view liveness through scopes.

#### Why this rule is required

Without it, removing `&mut` would *weaken* memory safety relative to languages with Rust-style borrow checking, because read-only views could be invalidated by mutations of the underlying place. The rule preserves the safety guarantee that views remain valid for their lifetime.

---

## 9. Closure Capture Conflict

Mutating closures capture places from their parent scope. The interaction between mutating capture and other call arguments requires precise rules.

### 9.1 Mutating closure

A closure that calls a mutating receiver method on, or assigns to, a captured place is a **mutating closure**.

### 9.2 Capture conflict rule

When a function call passes a mutating closure, each place mutably captured by that closure is **reserved** for the duration of the call. Other arguments to the same call may not pass anything that retains access to the reserved place.

#### Independent values vs retained access

An argument expression may be evaluated before a mutating closure is created if the result is an **independent value** that does not retain access to the reserved place. The result must be a value type whose contents do not include a view of, iterator over, guard for, or owned move of the reserved place.

The following retain access and therefore conflict:

* **Read-only views** of the reserved place: `&xs`, `&xs[0]`, `&xs.field`
* **Iterators** over the reserved place: `xs.iter()`, `xs.entries()`
* **Guards** scoping access to the reserved place: `xs.lock()`
* **Owned moves** of the reserved place: passing `xs` itself (which moves it before the closure can capture it)

The following are independent values and do not conflict:

* Primitive copies: `xs.len()`, `xs.is_empty()`
* Cloned values: `xs[0].clone()`
* Computed values: `xs.len() * 2`

### 9.3 Examples

```with
let xs = Vec.new()
items |> for_each(xs.push(it.value))
// OK: only one argument captures xs; nothing else accesses xs in this call.
```

```with
let xs = Vec.new()
some_function(xs, item => xs.push(item.value))
// ERROR: `xs` is moved as the first argument and mutably captured by the closure.
```

```with
let xs = Vec.new()
some_function(&xs, item => xs.push(item.value))
// ERROR: `xs` is passed as a read-only view and also mutably captured.
```

```with
let xs = Vec.new()
some_function(xs.iter(), item => xs.push(item.value))
// ERROR: iterator over xs retains access; closure mutably captures xs.
```

```with
let xs = Vec.new()
some_function(xs.len(), item => xs.push(item.value))
// OK: xs.len() returns a primitive value; no access to xs is retained.
```

```with
let xs = Vec.new()
let snapshot = xs[0].clone()
some_function(snapshot, item => xs.push(item.value))
// OK: snapshot is an independent owned value; xs itself is not retained.
```

### 9.4 Escape rule

A mutating closure may not escape the scope containing the captured place:

```with
fn bad() -> fn(Item):
    let xs = Vec.new()
    return item => xs.push(item.value)
    // ERROR: closure that mutates captured place `xs` cannot escape its defining scope
```

If long-lived mutable state is required, move owned state into a named type with mutating receiver methods.

---

## 10. Scoped Mutable Access via `with`

For types that contain internal state needing scoped mutable access (Vec slots, HashMap entries, lock-protected data), the language idiom is `with`-based scoped access.

### 10.1 Pattern

```with
with map.entry(key) as slot:
    slot.value = slot.value + 1
```

The container exposes a method that produces a scoped binding. Inside the `with` body, the binding is a place. Mutations to it affect the underlying container. When the body exits, the scope ends.

### 10.2 Idiomatic API names

Container types should expose scoped-access methods using names that match the new model:

| Method               | Returns                       | Used for                          |
| -------------------- | ----------------------------- | --------------------------------- |
| `entry(key)`         | Scoped entry binding          | Map-like access by key            |
| `slot(i)`            | Scoped element binding        | Indexed access (single element)   |
| `get_disjoint(...)`  | Tuple of scoped bindings      | Indexed access (multiple, disjoint) |
| `read()` / `write()` | Scoped read / write binding   | Lock-protected access             |

API names like `get_mut` should not appear on new With APIs. They should appear only in migration documentation as "this is what you used to write."

### 10.3 Common patterns

```with
// Increment a counter in a HashMap:
with map.entry(key) as slot:
    slot.value += 1

// Mutate a specific slot in a Vec:
with xs.slot(i) as elem:
    elem.field = new_value

// Access lock-protected state:
with lock.write() as data:
    data.push(item)

// Disjoint multi-slot access:
with xs.get_disjoint(0, 1) as (a, b):
    a.update(b)
```

### 10.4 Read vs write guards

Guard types decide whether the scoped binding is read-only or mutable. The distinction comes from the guard, not from `&mut` syntax:

```with
with lock.read() as data:
    print(data.len())
    data.push(1)              // ERROR: read guard exposes a read-only place

with lock.write() as data:
    data.push(1)              // OK: write guard exposes a mutable place
```

### 10.5 Stdlib types should expose this idiom

Container types in stdlib should expose `with`-friendly scoped access methods. This is the With idiom for "give me scoped mutable access to internal state" and replaces Rust's `&mut`-returning methods.

---

## 11. Iterators and `for`

The `for` loop requires a hidden iterator place to support mutating iterators.

### 11.1 Iterator trait

```with
trait Iter[T]:
    fn next(mut self: Self) -> Option[T]
```

The iterator value mutates itself via its `next` method. Calling `next` requires the iterator to be a mutable place.

### 11.2 `for` desugaring

A `for` loop creates a hidden compiler-generated place for the iterator:

```with
for x in make_iter():
    body
```

desugars conceptually to:

```with
let __iter = make_iter()       // __iter is a mutable place (compiler-created)
loop:
    match __iter.next():
        Some(x) => body
        None => break
```

The hidden iterator place exists for the lifetime of the loop body. This allows `for x in some_function()` to work even though `some_function()` returns a non-place.

### 11.3 No user-facing iterator places required

Users do not typically write iterator place declarations explicitly; the `for` desugaring handles it. Users who need fine-grained iterator control can name the iterator:

```with
let it = make_iter()
match it.next():
    Some(first) =>
        for x in it:           // continues from second element
            process(x)
    None => return
```

Here `it` is a place declared by the user, and subsequent operations work on that place.

### 11.4 `for` does not yield source places

In v1, `for x in iter:` binds `x` as an ordinary local binding for each yielded item. `x` is itself a place (per §2.1, all local bindings are places), but it is **not** a place projection into the iterator's source collection. Mutations to `x` follow the rules of whatever value the iterator yields — not the rules of "place into the source."

The behavior breaks down by what the iterator yields:

#### Iterator yields owned values

If the iterator yields owned `T` (consuming iterator, or iterator over a `Copy` element type), `x` is a mutable local place holding the owned value. Field assignment, mutating receiver calls, and other place operations work on `x` — but they affect only the local copy, not the source collection.

```with
fn double_in_place(xs: Vec[i32]) -> Vec[i32]:
    let result = Vec.new()
    for x in xs:                   // consuming iterator; yields owned i32
        let doubled = x * 2
        result.push(doubled)
    result
```

```with
fn process(items: Vec[Item]) -> Vec[Item]:
    let result = Vec.new()
    for item in items:             // yields owned Item (consumes `items`)
        item.field = transform(item.field)   // OK: mutates local place `item`
        result.push(item)
    result
```

In both cases, mutation of the loop variable is legal. The mutation does not propagate back to a "source collection" — there is no live source collection during the loop, because the iterator has consumed it (or is producing fresh values).

#### Iterator yields read-only views (`&T`)

If the iterator yields `&T` (e.g., `xs.iter()`), `x` is a local binding holding a read-only view. Mutation through `x` is rejected by §3 — the existing rule that mutation through `&T` is not permitted. This is not a new for-loop-specific rule.

```with
fn bad(xs: Vec[User]):
    for u in xs.iter():            // u: &User
        u.age += 1                 // ERROR: cannot mutate through read-only view (§3)
```

The error here is the same as `fn bad(u: &User): u.age += 1` outside any loop. The `for` loop merely binds `u` from each yielded view; the read-only-ness comes from `&User`, not from being a loop variable.

#### In-place mutation of a source collection

For in-place mutation that *does* affect the source collection, use index-based iteration on a place that implements `IndexPlace`:

```with
for i in 0..xs.len():
    xs[i].field += 1               // OK: place-projection through IndexPlace (§6.2)
```

Here `xs[i]` is a place projection into the source collection. Mutations affect `xs` directly because §2.4 specifies `IndexPlace` as compiler-recognized place projection.

#### Future work

Place-yielding iteration — a `for` form where the loop variable *is* a place projection into the iterator's source — is the open question tracked in §19.5. v1 does not provide it; index-based iteration is the v1 substitute.

---

## 12. Globals and Shared State

A function may mutate global or module-level state when that state is visible by name and the state itself permits mutation.

### 12.1 Global binding mutability

Global bindings are declared at module level (not inside function bodies) and follow the same binding-mutability convention as local bindings:

```with
global cache = Cache.new()       // module-level: stable binding; value may mutate through methods
global var current = None        // module-level: rebindable binding
```

`global name = expr` declares a stable global binding. The name cannot be rebound after initialization. The value may be mutated through mutating receiver methods or field assignment if the type supports it.

`global var name = expr` declares a rebindable global binding. The name may be reassigned to a new value of the same type. Value mutation works the same as for stable bindings.

This mirrors `let`/`var` for local bindings: `global` is the global equivalent of `let`; `global var` is the global equivalent of `var`.

### 12.2 Examples

```with
// At module level:
global cache = Cache.new()

fn remember(key: str, value: Value):
    cache.insert(key, value)         // OK: mutating receiver on stable global

fn replace_cache():
    cache = Cache.new()              // ERROR: cannot rebind `global` cache

// At module level:
global var current_user: Option[User] = None

fn login(user: User):
    current_user = Some(user)        // OK: rebinding a `global var`

fn logout():
    current_user = None              // OK
```

### 12.3 Concurrency

Globals are places. The same access conflict rules apply to globals as to local places. Concurrent shared state should use scoped synchronization:

```with
with global_cache.write() as cache:
    cache.insert(key, value)
```

---

## 13. Raw Pointers and the Unsafe Edge

C-style mutation through an out-parameter belongs at the unsafe edge.

### 13.1 Raw pointer types

Raw pointers remain available:

```with
*const T       // raw const pointer
*mut T         // raw mutable pointer
```

These are distinct from `&T` (a read-only safe view). Raw pointers do not carry the read-only-view safety guarantees from §8.4.

The kind of pointer determines the mutability of the place produced by dereference (§2.1):

* `*const T` dereferenced inside `unsafe` is a **read-only unsafe place**.
* `*mut T` dereferenced inside `unsafe` is a **mutable unsafe place**.

This mirrors the safe-reference rule that `*r` for `r: &T` is a read-only place.

### 13.2 Raw address-of

Taking the raw address of a place uses explicit raw-address-of syntax:

```with
&raw const P       // produces *const T from place P; safe to form
&raw mut P         // produces *mut T from place P; requires P to be a mutable place
```

The forms `&raw const P` and `&raw mut P` are distinct from `&P`. They produce raw pointers, not safe views. Forming a raw pointer does not require an `unsafe` block, but **dereferencing or writing through** the resulting pointer does.

#### What "mutable place" means

`&raw mut P` requires P to be a mutable place. This means:

* P is rooted in `let`, `var`, `global`, `global var`, an owned function parameter, a captured non-view binding, a `with`-bound write guard, a compiler-created temporary place, or a `*mut T` dereference inside `unsafe`.
* P is *not* rooted in a dereferenced safe reference (`*r` for `r: &T`), a `*const T` dereference, or any projection therefrom.

Binding mutability (`let` vs `var`, `global` vs `global var`) is **independent** of place mutability. Both `let xs = Vec.new()` and `var xs = Vec.new()` produce mutable places; the difference is only whether `xs = ...` is allowed for rebinding. Therefore `&raw mut xs` is valid for both.

#### Forming raw const pointers from references

A read-only reference `r: &T` may be used as the basis for a raw const pointer via `&raw const *r`. This forms `*const T` pointing at the same memory the reference points to. It does not create a mutable pointer and does not permit mutation. The dereferenced reference `*r` is a read-only place (§2.3); only `&raw const` is valid on it, not `&raw mut`.

```with
fn read_value(value: &i32) -> i32:
    let p: *const i32 = &raw const *value      // OK: const pointer to referenced i32
    unsafe *p                                  // dereference requires unsafe

fn bad(value: &i32):
    let p: *mut i32 = &raw mut *value          // ERROR: *value is a read-only place
```

### 13.3 Unsafe pointer operations

Writing through a raw pointer requires unsafe permission *and* a mutable raw pointer:

```with
let p: *mut i32 = &raw mut some_var
unsafe *p = 1                  // OK: *mut T dereference is a mutable unsafe place

let q: *const i32 = &raw const some_value
unsafe *q = 1                  // ERROR: *const T dereference is read-only

unsafe out[i] = value          // OK if `out: *mut T`, ERROR if `out: *const T`
```

or:

```with
unsafe:
    *out = value                // OK if `out: *mut T`
```

Inside `unsafe`, raw pointer dereferences are places with mutability determined by the pointer type (§13.1).

### 13.4 C interop

C interop and migrated C code may continue to use raw pointers for out-parameters:

```with
extern "C" {
    fn sqlite3_open(path: *const c_char, out_db: *mut *mut sqlite3) -> c_int
}
```

With wrappers should expose safe, return-value-oriented APIs, using `&raw mut` for the address-of:

```with
fn open_database(path: str) -> Result[Database, DbError]:
    var raw: *mut sqlite3 = null
    let rc = unsafe { sqlite3_open(path.to_cstring().ptr, &raw mut raw) }
    if rc != SQLITE_OK:
        return Err(.OpenFailed(rc))
    Database.from_raw(raw)
```

### 13.5 Mutable slices

Mutable borrowed slices are removed from safe With along with `&mut T`. The forms `[]mut T` and `&mut [T]` are not part of the source language.

In-place slice mutation is expressed through:

* **Visible containers and index-based loops** for whole-container mutation.
* **Scoped `with` access combined with index-based iteration** for sub-range mutation that should remain in-place.
* **Raw pointers** for low-level fill/copy at the unsafe edge.

Note: place-yielding iteration (e.g., `for slot in slice:` where `slot` is a place into the source) is not part of v1 (§19.5). The examples below use index-based iteration, which is supported by `IndexPlace` (§2.4).

#### Examples

```with
// In-place transform on a visible container:
fn normalize(xs: Vec[f32]) -> Vec[f32]:
    let n = xs.len()
    for i in 0..n:
        xs[i] = xs[i] / n
    xs

// Sub-range mutation through a scoped binding plus index-based iteration:
with xs.range(0..n) as slice:
    for i in 0..slice.len():
        slice[i].field += 1

// Low-level fill via raw pointer (e.g., for FFI):
fn fill(out: *mut u8, len: usize):
    unsafe:
        for i in 0..len:
            out[i] = 0

// Safe wrapper at the boundary:
fn fill_buffer(buf: Vec[u8]) -> Vec[u8]:
    let n = buf.len()
    if n > 0:
        unsafe { fill(&raw mut buf[0], n) }
    buf
```

Read-only slices (`&[T]`, however the spec spells them) remain available because they are built on `&T`, which still exists.

---

## 14. Optimization and `noalias` (Non-goal for v1)

This section is normative.

### 14.1 v1 does not infer `noalias`

Removing `&mut` from With is a source-language design change. It is **not** a `noalias` optimization feature. With v1 does not apply LLVM `noalias` to:

* Mutating receiver parameters (`mut self`)
* Owned by-value parameters
* Places identified by the access conflict rules
* Any other source-level construct

### 14.2 Why this is explicit

Applying `noalias` requires a *uniqueness proof*. Without a uniqueness analysis (a borrow checker, restricted alias analysis, or other mechanism), `noalias` is unsound — the compiler tells LLVM "these pointers don't alias" without verifying the claim, and LLVM optimizes based on the false premise.

With v1 has no uniqueness analysis. Therefore `noalias` cannot be soundly applied.

### 14.3 What is allowed

The following safe optimizations remain available without uniqueness proof:

* `&T` references are never `noalias`. Multiple `&T` to the same data is legal (subject to the read-only view conflict rule, §8.4).
* Raw pointers are never `noalias` by default. Future explicit unsafe contracts may add `restrict`-style annotations.
* Internal compiler temporaries may be optimized if their uniqueness is a lowering invariant of the compiler itself, not of source-level constructs.
* LLVM optimization levels (-O1, -O2, -O3) apply normally; the absence of `noalias` does not disable other optimizations.

### 14.4 Future work

`noalias` may be revisited when With has a mechanism that proves uniqueness — for example, a borrow checker for mutable receivers, or a richer access-conflict analysis. Any future addition must include a soundness argument, not just a performance benchmark.

---

## 15. Diagnostics

### 15.1 `&mut` in source

```with
fn fill(out: &mut Vec[i32]): ...
```

```text
error: `&mut T` is not part of safe With
help: use a return value, a mutating receiver method, scoped `with` access, or `*mut T` inside `unsafe`
```

### 15.2 Mutating through read-only view

```with
fn f(xs: &Vec[i32]):
    xs.push(1)
```

```text
error: cannot call mutating method `push` through read-only view `&Vec[i32]`
help: mutate an owned value, use a mutating receiver on a place, or return the modified value
```

### 15.3 Mutating receiver on non-place

```with
get_vec().push(1)
```

```text
error: mutating method `push` requires a place as receiver
help: bind the value first:
        let xs = get_vec()
        xs.push(1)
```

### 15.4 First-class mutating method reference

```with
let f = Vec.push
```

```text
error: cannot reference mutating receiver method `Vec.push` as a first-class function value
help: wrap in a closure that operates on a place:
        let f = (xs, value) => xs.push(value)
```

### 15.5 Indexed access conflict

```with
xs[0].update(xs[1])
```

```text
error: conflicting accesses through indexed base `xs` in the same call
help: clone or use a disjoint-access API:
        let other = xs[1].clone()
        xs[0].update(other)
help: or use a method that proves disjointness:
        with xs.get_disjoint(0, 1) as (a, b):
            a.update(b)
```

### 15.6 Mutation while view is live

```with
let xs = Vec.new()
xs.push(0)
let first = &xs[0]
xs.push(1)
print(first)
```

```text
error: cannot mutate `xs` while read-only view `first` is live
  --> example.w:4:5
   |
3  |     let first = &xs[0]
   |                 ------ view created here
4  |     xs.push(1)
   |     ^^^^^^^^^^ mutation conflicts with live view
5  |     print(first)
   |           ----- view used here
help: use the view before mutating, or clone the value if you need both
```

### 15.7 Closure capture conflict

```with
some_function(xs, item => xs.push(item.value))
```

```text
error: place `xs` is both passed as an argument and mutably captured by a closure
help: the call argument and the mutating closure cannot both access `xs`
help: pass an independent value instead:
        some_function(xs.len(), item => xs.push(item.value))
```

### 15.8 Closure capture conflict via iterator

```with
some_function(xs.iter(), item => xs.push(item.value))
```

```text
error: iterator over `xs` retains access; cannot also mutably capture `xs`
help: collect the iterator first, or restructure the call to avoid simultaneous access
```

### 15.9 Escaping mutating capture

```with
fn bad() -> fn(Item):
    let xs = Vec.new()
    return item => xs.push(item.value)
```

```text
error: closure that mutates captured place `xs` cannot escape its defining scope
help: return the accumulated value, or move owned state into a named type with mutating methods
```

### 15.10 Field assignment through read-only view

```with
fn bad(u: &User):
    u.age = 31
```

```text
error: cannot assign to field through read-only view `&User`
help: take an owned `User` and return the modified value, or use a mutating receiver method
note: `u.age` here is sugar for `(*u).age`; both refer to a read-only place
```

### 15.11 Index assignment on type without IndexPlace

```with
let view = ReadOnlyTable.new()
view[0] = 5
```

```text
error: type `ReadOnlyTable` does not support index assignment
help: `view[i] = ...` requires `IndexPlace`; this type only implements `IndexGet`
```

### 15.12 Rebinding a stable global

```with
global cache = Cache.new()

fn replace_cache():
    cache = Cache.new()
```

```text
error: cannot rebind global `cache`; declared as `global` (stable)
help: use `global var cache = ...` to allow rebinding, or mutate the existing cache value
```

### 15.13 Raw mut address of non-place

```with
let p: *mut i32 = &raw mut get_value()
```

```text
error: `&raw mut` requires a place; `get_value()` is not a place
help: bind the value first:
        var v = get_value()
        let p: *mut i32 = &raw mut v
```

### 15.14 Raw mut address of read-only place

```with
fn bad(value: &i32):
    let p: *mut i32 = &raw mut *value
```

```text
error: `&raw mut` requires a mutable place; `*value` is read-only (dereferenced &T)
help: use `&raw const *value` for a const pointer, or take an owned value
note: read-only places include `*r` for `r: &T` and `*p` for `p: *const T`
```

### 15.15 Write through *const T

```with
let p: *const i32 = &raw const some_value
unsafe *p = 1
```

```text
error: cannot write through `*const T` dereference; `*p` is a read-only unsafe place
help: use `*mut T` if you need to write through a raw pointer:
        let q: *mut i32 = &raw mut some_var
        unsafe *q = 1
```

### 15.16 Deref-precedence error

```with
fn bad(u: &User):
    let age = *u.age
```

```text
error: cannot dereference `i32` (the type of `u.age`)
note: `*u.age` parses as `*(u.age)`; the unary `*` has lower precedence than `.`
help: to dereference `u` and then access `age`, write `(*u).age`:
        let age = (*u).age
help: or rely on auto-deref:
        let age = u.age
```

### 15.17 Mutation through for-loop variable bound to a view

When the iterator yields `&T` and the loop body attempts to mutate through the loop variable, the diagnostic should point at the read-only-view rule directly:

```with
for u in users.iter():
    u.age += 1
```

```text
error: cannot assign through read-only view `u`
note: `users.iter()` yields `&User`; `u` is a local binding holding that view
help: use index-based iteration if the source supports `IndexPlace`:
        for i in 0..users.len():
            users[i].age += 1
help: or consume the iterator and rebuild:
        let updated = users.into_iter().map(|u| { let new = u; new.age + 1; new }).collect()
```

For iterators where the yielded type is unclear or not a view, a more general diagnostic applies:

```with
for elem in some_iter():
    elem.field += 1                  // some_iter yields a non-place type
```

```text
error: cannot mutate `elem` to affect the iterator's source collection
note: `for x in iter:` binds each yielded item as a local value, not as a place
      projection into the source. Mutating `elem` here mutates only the local binding.
help: use index-based iteration if the source supports `IndexPlace`:
        for i in 0..xs.len():
            xs[i].field += 1
note: place-yielding iteration is tracked as future work (§19.5)
```

Note: if the iterator yields owned values and the user *intends* local-only mutation, no error is produced. The diagnostic fires only when the surrounding code makes clear the user expected source-collection mutation (e.g., the source is still in scope and the mutation pattern matches typical "modify through iter" patterns).

---

## 16. Migration Guide

### 16.1 Function out-parameters

Before:

```with
fn collect_values(items: Items, out: &mut Vec[i32]):
    items |> for_each(out.push(it.value))
```

After:

```with
fn values(items: Items) -> Vec[i32]:
    let out = Vec.new()
    items |> for_each(out.push(it.value))
    out
```

### 16.2 Mutating helper function

Before:

```with
fn advance(p: &mut Parser):
    p.pos += 1

advance(&mut parser)
```

After:

```with
extend Parser:
    fn advance(mut self: Self):
        self.pos += 1

parser.advance()
```

### 16.3 In-place transform

Before:

```with
fn normalize(xs: &mut Vec[f32]):
    let n = xs.len()
    for i in 0..n:
        xs[i] = xs[i] / n
```

After, as mutating receiver:

```with
extend Vec[f32]:
    fn normalize(mut self: Self):
        let n = self.len()
        for i in 0..n:
            self[i] = self[i] / n

xs.normalize()
```

### 16.4 `&mut`-returning accessor methods

Before:

```with
let slot = map.get_mut(key)     // returned &mut V in old API
slot.value += 1
```

After:

```with
with map.entry(key) as slot:
    slot.value += 1
```

### 16.5 Mutable slices

Before:

```with
fn fill(out: &mut [u8]):
    for i in 0..out.len():
        out[i] = 0
```

After, as mutating receiver on a container type:

```with
extend Vec[u8]:
    fn fill_zero(mut self: Self):
        for i in 0..self.len():
            self[i] = 0

xs.fill_zero()
```

Or as a low-level raw-pointer version with a safe wrapper:

```with
fn fill_unsafe(out: *mut u8, len: usize):
    unsafe:
        for i in 0..len:
            out[i] = 0

fn fill_buffer(buf: Vec[u8]) -> Vec[u8]:
    let n = buf.len()
    if n > 0:
        unsafe { fill_unsafe(&raw mut buf[0], n) }
    buf
```

### 16.6 C out-parameters

C functions migrated via `with migrate` keep their C-shaped signatures using `*mut T`:

```with
fn c_style(out: *mut i32):
    unsafe *out = 42
```

Safe wrappers should be added at the boundary, using `&raw mut` for the address:

```with
fn make_value() -> i32:
    var result: i32 = 0
    unsafe { c_style(&raw mut result) }
    result
```

### 16.7 `iter_mut`-style patterns

Before:

```with
for elem in xs.iter_mut():
    elem.field += 1
```

After (index-based, requires `xs` to implement `IndexPlace`):

```with
for i in 0..xs.len():
    xs[i].field += 1
```

This is sufficient for v1. Place-yielding iteration is future work (§19.5).

### 16.8 Existing With codebase

Spec sections currently containing `&mut`:

* §3 Reference Types — remove `&mut T`
* Method receiver tables — remove `&mut Self` row
* `IndexMut` and `MultiIndexMut` — replace with `IndexPlace` (compiler-recognized syntax trait)
* `ScopedMut` — remove or fold into guard capability model
* `SlotMap`, `Iter`, `for_each_mut`, `get_mut` — revise per this proposal
* `[]mut T` slice form — remove; use containers, scoped access, or raw pointers
* All examples throughout — convert to mutating receivers, return values, or `with` access

Stdlib types currently using `&mut self` in method signatures need conversion to `mut self: Self`. This is mechanical but extensive. See §20 for the recommended order.

---

## 17. Required Spec Changes

### Remove

* `&mut T` as a type form
* `&mut self` as a receiver mode
* `[]mut T`, `&mut [T]`, or any mutable borrowed slice form
* `IndexMut`, `MultiIndexMut`, `ScopedMut` traits as currently defined
* All `&mut` examples throughout the spec
* `&` (read-only) used to satisfy `*mut T` arguments — replace with `&raw mut`

### Add

* §2 Places (formal definition with roots, projections, mutability rules, and place expression rules)
* §2.1 Place root mutability column distinguishing read-only from mutable roots; explicit entry for function parameters and for-loop variables
* §2.3 Dereferenced safe references as read-only places, with deref-precedence note and auto-deref equivalence
* §2.4 `IndexPlace` as a compiler-recognized syntax trait, distinct from `IndexGet`
* §5 Mutating receiver syntax (`mut self: Self`) as a receiver-place mode
* §5.3 Restriction on first-class mutating method references in v1
* §5.4 Nested mutating call evaluation order
* §5.5 Argument independence rule for mutating receiver calls
* §6 Field, index, and compound assignment desugaring (with single-evaluation rule)
* §6.2 Index assignment via `IndexPlace` with nested place semantics
* §7 Lexical mutation principle
* §8 Access conflict rules (disjoint paths, indexed conflict, call-site conflict)
* §8.4 Read-only view vs mutation conflict rule
* §9 Closure capture conflict rules with independent-value clarification
* §10 Scoped mutable access via `with` as a primary idiom
* §11 `for` desugaring with hidden iterator place
* §11.4 `for` does not yield source places; behavior depends on what the iterator yields
* §12 Global binding mutability: `global` (stable) vs `global var` (rebindable), declared at module level
* §13 Raw pointers and the unsafe edge:
  * §13.1 `*const T` deref produces read-only unsafe place; `*mut T` deref produces mutable unsafe place
  * §13.2 `&raw const` and `&raw mut` address-of forms with explicit place-mutability rules
  * §13.3 Writes require both unsafe and a `*mut T` source
  * §13.5 Mutable slice replacement story using index-based iteration
* §14 `noalias` non-goal with explicit reasoning

### Revise

* `Iter` trait: `next(mut self: Self) -> Option[T]`
* `IndexMut` / `IndexSet` → `IndexPlace` as compiler-recognized syntax trait
* Method resolution rules: incorporate place requirement for `mut self` receivers
* Auto-reference rules: only `&T`, never `&mut T`
* Trait method receiver tables: three modes (`&Self`, `mut Self`, `Self`)
* FFI examples: use `&raw mut` for raw mutable address-of; safe `&` cannot satisfy `*mut T`

---

## 18. Tests

### Accepted

```with
fn local_vec:
    let xs = Vec.new()
    xs.push(1)
    xs.push(2)
    assert_eq(xs.len(), 2)
```

```with
fn collect(items: Vec[Item]) -> Vec[i32]:
    let xs = Vec.new()
    items |> for_each(xs.push(it.value))
    xs
```

```with
extend Parser:
    fn advance(mut self: Self):
        self.pos += 1

fn use_parser:
    let p = Parser.new()
    p.advance()
```

```with
fn owned_transform(xs: Vec[i32]) -> Vec[i32]:
    xs.push(1)                 // OK: owned parameter is a mutable place (§2.1)
    xs
```

```with
fn raw_out(out: *mut i32):
    unsafe *out = 42
```

```with
fn raw_addr_of:
    var x = 5
    let p: *mut i32 = &raw mut x
    unsafe *p = 10
    assert_eq(x, 10)
```

```with
fn raw_const_addr_through_ref(value: &i32):
    let p: *const i32 = &raw const *value
    let x = unsafe *p
    assert_eq(x, *value)
```

```with
fn safe_wrapper_for_c() -> i32:
    var result: i32 = 0
    unsafe { c_set_value(&raw mut result) }
    result
```

```with
fn explicit_deref_read(u: &User):
    let age = (*u).age              // explicit deref-then-field
    let name = u.name               // auto-deref sugar (same place)
    print(age)
    print(name)
```

```with
fn disjoint_tuple_fields:
    let pair = (Vec.new(), Vec.new())
    pair.0.push(1)
    pair.1.push(2)
```

```with
fn scoped_entry_access:
    var map = HashMap.new()
    map.insert("a", 0)
    with map.entry("a") as slot:
        slot.value = slot.value + 1
```

```with
fn for_loop_with_value_iter:
    for x in 0..10:
        print(x)
```

```with
fn for_loop_owned_mutable:
    fn process(items: Vec[Item]) -> Vec[Item]:
        let result = Vec.new()
        for item in items:           // consumes items; yields owned Item
            item.field = transform(item.field)   // OK: mutates local place `item`
            result.push(item)
        result
```

```with
fn closure_with_value_arg:
    let xs = Vec.new()
    some_function(xs.len(), item => xs.push(item.value))
```

```with
fn nested_mutating_calls:
    let xs = Vec.new()
    xs.push(0)
    xs.push(xs.len())          // OK: §5.5 — len() is independent value
    assert_eq(xs.len(), 2)
```

```with
fn nested_mutate_then_push:
    let xs = Vec.new()
    xs.push(1)
    xs.push(2)
    xs.push(xs.pop().unwrap())  // OK: pop() completes before push() begins
    assert_eq(xs.len(), 2)
```

```with
fn view_then_mutate:
    let xs = Vec.new()
    xs.push(0)
    let first = &xs[0]
    print(first)               // last use of `first`
    xs.push(1)                 // OK: `first` no longer live
```

```with
fn compound_assign_indexed:
    let xs = Vec.new()
    xs.push(10)
    xs[0] += 5                 // place-projection through IndexPlace
    assert_eq(xs[0], 15)
```

```with
fn nested_field_through_index:
    let users = Vec.new()
    users.push(User { name: "Alice", age: 30 })
    users[0].age += 1          // place-projection enables nested field mutation
                               // without copying User out of the Vec
    assert_eq(users[0].age, 31)
```

```with
fn nested_method_through_index:
    let parsers = Vec.new()
    parsers.push(Parser.new())
    parsers[0].advance()       // mutating receiver call through IndexPlace projection
```

```with
fn index_based_in_place_mutation:
    let xs = Vec.new()
    for i in 0..3:
        xs.push(User { name: "user", age: 0 })
    for i in 0..xs.len():
        xs[i].age = i.to_i32()  // OK: index-based iteration with IndexPlace
    assert_eq(xs[2].age, 2)
```

```with
fn write_through_mut_ptr:
    var x: i32 = 0
    let p: *mut i32 = &raw mut x
    unsafe *p = 42
    assert_eq(x, 42)
```

```with
fn read_through_const_ptr:
    let value: i32 = 42
    let p: *const i32 = &raw const value
    let v = unsafe *p
    assert_eq(v, 42)
```

```with
// At module level:
global counter = Counter.new()

fn use_stable_global:
    counter.increment()        // OK: mutating receiver on stable global
```

```with
// At module level:
global var current = 0

fn use_rebindable_global:
    current = 5                // OK: `global var` allows rebinding
    current = 10               // OK
```

### Rejected

```with
fn bad(out: &mut Vec[i32]):
    out.push(1)
```

```with
fn bad(xs: &Vec[i32]):
    xs.push(1)
```

```with
fn bad_through_deref(xs: &Vec[i32]):
    (*xs).push(1)              // ERROR: *xs is a read-only place
```

```with
fn bad() -> fn(Item):
    let xs = Vec.new()
    return item => xs.push(item.value)
```

```with
fn bad(xs: &Vec[i32]):
    xs[0] = 1
```

```with
fn bad_field_through_deref(u: &User):
    (*u).age = 31              // ERROR: cannot assign through dereferenced &T
```

```with
fn bad_temp:
    Vec.new().push(1)         // mutating receiver on non-place
```

```with
fn bad_indexed_conflict:
    let xs = Vec.new()
    xs[0].update(xs[1])       // conflicting indexed accesses
```

```with
fn bad_capture_with_arg:
    let xs = Vec.new()
    some_function(xs, item => xs.push(item.value))
```

```with
fn bad_capture_with_view:
    let xs = Vec.new()
    some_function(&xs, item => xs.push(item.value))
```

```with
fn bad_capture_with_iter:
    let xs = Vec.new()
    some_function(xs.iter(), item => xs.push(item.value))
```

```with
fn bad_mutate_while_view_live:
    let xs = Vec.new()
    xs.push(0)
    let first = &xs[0]
    xs.push(1)                 // ERROR: `first` still live
    print(first)
```

```with
fn bad_first_class_mutating_method:
    let f = Vec.push           // ERROR: not first-class in v1
```

```with
fn bad_push_with_view:
    let xs = Vec.new()
    xs.push(0)
    xs.push(&xs[0])            // ERROR: §5.5 — view retains access
```

```with
fn bad_push_with_iter:
    let xs = Vec.new()
    xs.push(xs.iter())         // ERROR: §5.5 — iterator retains access
```

```with
fn bad_index_assign_no_indexplace:
    let view = ReadOnlyTable.new()
    view[0] = 5                // ERROR: type does not implement IndexPlace
```

```with
// At module level:
global cache = Cache.new()

fn bad_global_rebind:
    cache = Cache.new()        // ERROR: `global` is not rebindable
```

```with
fn bad_raw_mut_non_place:
    let p: *mut i32 = &raw mut get_value()  // ERROR: get_value() is not a place
```

```with
fn bad_raw_mut_through_ref(value: &i32):
    let p: *mut i32 = &raw mut *value       // ERROR: *value is a read-only place
```

```with
fn bad_safe_ref_for_c_out:
    var result: i32 = 0
    unsafe { c_style(&result) }  // ERROR: &result is &i32, not *mut i32
```

```with
fn bad_write_through_const_ptr:
    let value: i32 = 42
    let p: *const i32 = &raw const value
    unsafe *p = 1                // ERROR: *const T deref is a read-only place
```

```with
fn bad_method_through_const_ptr(p: *const Vec[i32]):
    unsafe { (*p).push(1) }      // ERROR: *p is a read-only unsafe place
```

```with
fn bad_deref_precedence(u: &User):
    let age = *u.age             // ERROR: *u.age parses as *(u.age); type error
```

```with
fn bad_mutate_through_iter_view:
    let xs = Vec.new()
    xs.push(User { name: "Alice", age: 30 })
    for u in xs.iter():
        u.age += 1               // ERROR: cannot mutate through read-only view (§3)
                                 //        u: &User; the iterator yields views, not places
```

---

## 19. Open Questions

### 19.1 Disjoint indexed access APIs

Container types should expose APIs that prove disjointness. Standard names to consider:

* `get_disjoint(i, j)` returning a tuple of scoped bindings
* `split_at(i)` returning a prefix and suffix as scoped bindings
* `slot(i)` for single-element scoped access

The naming and exact API shape is a follow-up stdlib design question.

### 19.2 Deep immutability

This proposal does not provide deep immutability. If users need a frozen value, possible future designs include:

```with
readonly T
Frozen[T]
```

or type-specific APIs that don't expose mutating methods. Not included in v1.

### 19.3 Guard capability model

`Scoped`/`ScopedMut` should be redesigned around read vs write guard capabilities without exposing `&mut`. Belongs in a follow-up stdlib/syntax-trait proposal.

### 19.4 First-class place-based functions

§5.3 restricts mutating receiver methods from being first-class function values in v1. A future revision may add a place-based function type:

```with
fn(Place[T], U) -> V
```

This would allow `let f = Vec.push` to have a meaningful type. Not in v1; the closure-wrapping workaround is sufficient for current needs.

### 19.5 Iterators that yield places into source collections

Rust's `iter_mut` yields `&mut T` items, which are place projections into the source collection. Mutating an `iter_mut` item mutates the source.

In v1, With's iterators yield values (owned `T`) or read-only views (`&T`). Neither is a place projection into the source. A `for x in iter:` loop binds `x` as an ordinary local; mutations to `x` follow the rules of whatever it holds, not source-place rules (§11.4).

For in-place mutation that affects the source collection, v1 uses index-based iteration on a place that implements `IndexPlace`:

```with
for i in 0..xs.len():
    xs[i].field += 1         // place-projection through IndexPlace
```

Possible post-v1 designs for true place-yielding iteration:

```with
// Scoped iteration with a closure receiving each slot as a place:
xs.each_slot(|slot|:
    slot.field += 1
)

// A new for-syntax explicitly requesting place-yielding iteration:
for_place slot in xs:
    slot.field += 1

// A new iterator trait that yields scoped place bindings:
trait IterPlace[T]:
    fn next_slot(mut self: Self) -> Option[ScopedSlot[T]]
```

The shape, syntax, and trait design for place-yielding iteration are open. v1 ships with index-based iteration as the primary mechanism; this section will be revisited in a follow-up proposal.

### 19.6 Raw address-of syntax bikeshed

The chosen syntax is `&raw const P` and `&raw mut P`. Alternative spellings considered:

* `addr_of(P)` / `addr_of_mut(P)` — function-shaped, less syntactic.
* `&P` with type ascription `as *const T` — overloads `&` ambiguously.
* `unsafe &mut P` (only inside unsafe) — reuses old syntax inside unsafe.

`&raw const` / `&raw mut` is preferred because it is syntactically distinct from `&P` (no overloading), it is visible at the expression site (no need to look at type ascription), and it uses the keyword `raw` to mark the unsafe-adjacent nature without requiring an `unsafe` block at the address-of point itself.

### 19.7 `IndexPlace` user-defined implementations

§2.4 specifies `IndexPlace` as a compiler-recognized syntax trait. v1 may restrict implementations to stdlib-provided container types (Vec, Array, etc.) rather than allowing arbitrary user implementations. The full contract for user-defined `IndexPlace` types — what operations the user must provide, how the compiler lowers nested place access — is a follow-up design question.

If user-defined `IndexPlace` is permitted in v1, the interface might require methods like `slot(i) -> ScopedSlot[T]` (a `with`-friendly scoped accessor), with the compiler generating place-projection lowering that calls into these methods. The exact shape is open.

---

## 20. Implementation Plan

This proposal is a substantial change touching parser, sema, stdlib, migrator, codegen, and tests. Implementation order:

### 20.0 API Inventory (prerequisite)

Before any code changes, audit all public APIs in stdlib and the compiler that currently use `&mut`. Classify each as one of:

| Old pattern              | New pattern                             |
| ------------------------ | --------------------------------------- |
| `&mut self` method       | `mut self: Self` mutating receiver      |
| `fn(&mut T, ...)` free fn | Mutating receiver method on T          |
| `&mut T` return value    | `with` scoped access via container method |
| `&mut T` parameter for output | Return value from function         |
| `&mut T` for FFI         | `*mut T` with `unsafe` writes           |
| `&mut [T]` slice         | Container method, scoped access, or raw pointer at unsafe edge |
| `IndexMut` impl          | `IndexPlace` impl (stdlib-supported)    |
| `iter_mut` / `for_each_mut` | Index-based iteration with IndexPlace, or scoped-access closure |

This avoids mechanical rewrites that pick the wrong idiom. Examples requiring care:

* `Vec.iter_mut` → index-based iteration in v1 (§19.5 deferred)
* `HashMap.get_mut` → `with map.entry(key) as slot:`
* `SlotMap.get_mut` → `with slotmap.slot(id) as elem:`
* `Iter.next(&mut self)` → `Iter.next(mut self: Self)`
* `for_each_mut(xs, f)` → `xs.each_slot(|slot| ...)` or restructure caller

Output of this step is a written inventory document listing every affected API and its target shape.

### 20.1 Spec finalization

Resolve open questions (§19), get one final review pass, publish as canonical. The `IndexPlace` user-implementation question (§19.7) should be resolved before sema work begins, since it determines whether the compiler needs to support arbitrary user types or only stdlib containers.

### 20.2 Parser changes

Reject `&mut T` syntax with clear error messages pointing to migration guide. Accept `mut self: Self` receivers. Accept `&raw const` and `&raw mut` address-of forms. Accept `global var` declarations at module level. Reject first-class references to mutating methods. Provide deref-precedence diagnostic (§15.16) when `*x.field` appears with a reference-typed `x`.

### 20.3 Sema changes

Implement places analysis (§2), including the `IndexPlace`/`IndexGet` distinction, dereferenced-reference place semantics, `*const T`/`*mut T` dereference mutability tracking, and explicit treatment of function parameters and for-loop variables as place roots. Implement access conflict checking (§8) including the read-only view vs mutation rule (§8.4). Implement closure capture conflict checking (§9). Implement argument independence rule for mutating receiver calls (§5.5). Enforce global binding mutability (§12).

For `for` loops, no special "loop variable is not a place" rule is needed — the loop variable is an ordinary local binding (§2.1) and existing rules govern what mutations are legal. Iterators yielding `&T` produce loop variables holding views; mutations through them are caught by §3 (the existing read-only-view rule). Iterators yielding owned values produce mutable local places, where mutations are legal but local. The diagnostic for §15.17 should detect the common "user expected source-collection mutation" pattern and offer the index-based fix.

The `IndexPlace` lowering is the most subtle piece: nested place projection through `P[i]` must operate on storage directly, not via get/set value copies. The compiler's place-projection machinery must be extended to handle indexed projections in addition to field projections. For v1 with stdlib-only `IndexPlace` impls, this can be hardcoded for Vec, Array, and similar; for user-defined impls (if §19.7 allows them), a more general mechanism is needed.

This is the largest implementation step. Estimated 2000-4000 lines of sema code, depending on how much shared infrastructure exists and on the §19.7 resolution.

### 20.4 Stdlib migration

Apply the API inventory from §20.0. Convert `&mut self` methods to `mut self: Self`. Replace `IndexMut`/`MultiIndexMut`/`ScopedMut` with `IndexPlace` and the new guard model. Audit and update Vec, HashMap, SlotMap, Iter, and similar types. Update mutable-slice APIs to use containers, scoped access, or raw pointers per §13.5. Replace `iter_mut` callers with index-based iteration.

### 20.5 Migrator updates

Emit raw pointer + unsafe patterns for C out-parameters, using `&raw mut` for safe-side address-of. Emit `mut self: Self` for mutating methods on migrated structs. Update PCRE2 and other migrated stdlib modules.

### 20.6 `for` desugaring update

Update to create hidden iterator places (§11.2). No special handling of loop variables is required; existing rules govern their use. Diagnostic §15.17 should trigger when source-collection mutation is the apparent intent.

### 20.7 Codegen audit

Confirm no `noalias` is being applied to source-level constructs (matches §14 non-goal). Add tests that verify miscompilation does not occur for previously-vulnerable patterns. Verify that `IndexPlace` lowering correctly preserves `Drop` semantics — specifically, that nested place mutation through `xs[i].field` does not invoke `Drop` on the element unnecessarily. Verify that writes through `*const T` are rejected, not silently emitted.

### 20.8 Test suite updates

Add accepted/rejected cases from §18. Update existing tests that used `&mut` patterns. Add specific regression tests for §5.5 argument independence, §8.4 view vs mutation, §9 closure capture, §6.3 compound assignment evaluation order, §13.1 `*const T` vs `*mut T` deref mutability, §13.2 raw address-of (including const-from-ref form), §12 global binding mutability, §2.3 dereferenced-reference place semantics, §6.2 nested place mutation through `IndexPlace`, §11.4 for-loop semantics (both accepted owned-mutation case and rejected view-mutation case). Add deref-precedence error test (§15.16).

### 20.9 Documentation

Update tutorials, examples, the spec website. Migration guide for users with existing With code. Update Claude/agent prompts that reference With syntax. Sweep all spec examples for `*x.field` patterns that should be `(*x).field` and convert them. Sweep for `_view` variable names that hold values rather than references and rename to plain `x` or similar.

### Estimated scope

Smaller than PCRE2 migration in line count, but touches more parts of the system simultaneously. Worth doing as a single coordinated change rather than incrementally — partial states would leave the language inconsistent. Work order matters: §20.0 inventory and §20.1 spec finalization (including §19.7 resolution) must complete before any code changes.

---

## 21. Rationale

`&mut` feels wrong in With because it encodes Rust's central mutation abstraction: temporary exclusive borrows passed through function boundaries. That abstraction brings the entire Rust mental model with it — uniqueness proofs, lifetime regions, borrow choreography — which users must understand even when the syntax tries to hide them.

With's design points elsewhere:

* Python-shaped 90% case
* Minimal annotations
* Function arguments as obvious inputs
* Mutation visible where it happens
* Scoped access through `with`
* Sharp tools at unsafe/FFI boundaries

Removing `&mut` makes the language internally consistent. It also avoids building a Rust-style borrow checker to support an abstraction With shouldn't be encouraging in the first place. The one borrow-checker-shaped rule that remains — read-only view liveness (§8.4) — exists only to preserve the safety guarantees of `&T`, which are present in any language that has references at all.

The resulting model:

> **Arguments are inputs.**
> **Return values are outputs.**
> **Mutation targets are lexically visible.**
> **Read-only views remain valid for their lifetime.**
> **Indexed places are real places (no copy-out-and-back).**
> **Read-only places (dereferenced `&T`, dereferenced `*const T`) cannot be written to.**
> **For-loop variables are local places; their mutability follows what the iterator yields.**
> **Iteration in v1 is value-based or index-based; place-yielding iteration into source collections is future work.**
> **Raw pointers are for unsafe/C-style mutation, with `&raw mut` as the explicit address-of form.**

---

## Changelog

**Revision 8 (this document):**

* §2.1 Added `for`-loop variable as a place root, with mutability inherited from the yielded item type.
* §3 Added clarification that `&T` mutation rules apply wherever `&T` values appear, including loop variables.
* §11.4 Rewrote completely. Previous wording overclaimed that loop variables are "not places"; corrected to specify that loop variables *are* local places, but they are not place projections into the source collection. Behavior depends on what the iterator yields: owned values produce mutable local places (mutation legal but local-only); `&T` views produce read-only bindings (mutation rejected by §3). Index-based iteration via `IndexPlace` is the v1 mechanism for source-collection mutation.
* §15.17 Rewrote diagnostic. Two-form diagnostic: when iterator clearly yields `&T`, point at the read-only-view rule directly with concrete owned/index alternatives. For ambiguous cases, the more general "loop variable is not a source-place projection" diagnostic applies.
* §18 Added accepted test for owned-mutation in for-loop. Renamed and rewrote rejected test to use clear `&T` iterator example, with comment correctly identifying the error as a read-only-view violation rather than a for-loop-specific rule.
* §19.5 Rewrote to clarify the precise issue: With's iterators yield values or views, not source-place projections. Renamed section to "Iterators that yield places into source collections" for precision.
* §20.3 Removed "reject mutating operations on for loop variables" overspecified task. Replaced with note that no special for-loop rule is needed; existing place and view rules cover the cases.
* §20.6 Removed the "add diagnostic for loop variable mutation attempts" task; folded into §15.17 with smarter detection.
* §20.8 Updated test description to cover both accepted and rejected for-loop cases.
* §21 Added "For-loop variables are local places" line to model summary.
* Updated non-goals: clarified that v1 does not support iterators yielding *places into source collections*, not just "iterators yielding places."

**Revision 7:**

* §2.1 Added function parameters to place-root table.
* §2.3 Renamed `age_view` to `age`; reserved "view" terminology for `&T` values.
* §11.4 New subsection: `for` does not yield places in v1.
* §13.5 Rewrote sub-range mutation example to use index-based iteration.
* §15.17 New diagnostic for mutation through for-loop variable.
* §16.7 New migration entry for `iter_mut` patterns.
* §18 Updated tests.
* §19.5 Rewrote v1 stance.
* §20 Updated implementation tasks.
* §21 Added iteration line to model summary.

**Revision 6:**

* §2.1 Added mutability column; distinguished `*const T` deref from `*mut T` deref.
* §2.3 Fixed deref-precedence syntax errors.
* §13.1 Added `*const T` vs `*mut T` deref mutability rule.
* §15.15/15.16 New diagnostics.
* §18 New tests.
* §21 Added read-only-place rule to model summary.

**Revision 5:**

* §2.1 Added dereferenced safe reference as a place root.
* §2.3 New section specifying read-only place semantics.
* §2.4 Reframed `IndexPlace` as a compiler-recognized syntax trait.
* §6.2 Updated index assignment lowering.
* §12 Restructured global examples.
* §13.2 Added mutable-place definition.
* §15.14 New diagnostic.
* §18 Updated tests.
* §19.7 New open question.
* §20 Updated implementation plan.
* §21 Updated rationale model.

**Revision 4:**

* §2.2 Distinguished `IndexPlace` from `IndexGet`.
* §5.5 Added Argument Independence rule.
* §6.2 Updated index assignment desugaring.
* §12 Distinguished `global` from `global var`.
* §13.2 Added `&raw const` and `&raw mut`.
* §13.5 Mutable slice replacement story.
* §15 New diagnostics.
* §16 Migration entries for mutable slices and FFI.
* §18 New tests.
* §19.6 Open question for raw address-of syntax.
* §20.0 Updated API inventory.
* §21 Updated rationale.

**Revision 3:**

* §5.1 Defined `mut self: Self` as a receiver-place mode.
* §5.3 Restriction on first-class mutating method references.
* §5.4 Evaluation order for nested mutating calls.
* §6.2/§6.3 Single-evaluation rule for compound assignment.
* §8.4 Read-only view vs mutation conflict rule.
* §9.2 Independent-value semantics for closure capture.
* §10.2 Idiomatic API name table.
* §15 New diagnostics.
* §18 Regression tests.
* §19.5 Open question for iterators yielding places.
* §20.0 API inventory step.
* §21 Updated rationale.

**Revision 2:**

* §2 Places as a formal normative section.
* §6 Assignment desugaring rules.
* §8 Access Conflicts.
* §9 Closure Capture Conflict.
* §10 Scoped Mutable Access via `with`.
* §11 `for` desugaring.
* §14 `noalias` non-goal.
* §5 Receiver mode table tightened.
* §15 Expanded Diagnostics.
* §16 Expanded Migration Guide.
* §20 Implementation Plan.

**Revision 1:**

* Initial proposal: removed `&mut T` from safe With surface, established mutating receiver methods, lexical mutation principle, and unsafe escape hatch.