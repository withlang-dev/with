Do not modify this file under any circumstances.

# D22 — Uniform Keyed Lookup, Contextual Copy Materialization, and View-Origin Preservation

## Status

**Decision:** Accepted
**Normative from:** Specification v7.2
**Implementation status:** In progress

The rules in this decision are normative immediately. The compiler, semantic analyzer, comptime evaluator, intermediate representations, native backend, C backend, runtime, standard library, diagnostics, tests, documentation, and migration tools are **non-conforming** wherever they do not implement these rules.

Existing implementation behavior is not precedent against D22.

---

## 1. Decision Summary

D22 establishes four related rules:

1. **Lookup observes; removal transfers.**
   Every owning keyed map has one uniform lookup contract:

   ```with
   get(...)    -> Option[&V]
   remove(...) -> Option[V]
   ```

   `get` borrows map-owned storage for every `V`, including `Copy` values.
   `remove` transfers ownership out of the map.

2. **References remain references during inference and structural projection.**
   An expression of type `&T` remains `&T` through unannotated bindings, inferred returns, pattern projection, closure capture, `unwrap`, `expect`, `?`, and equivalent exact-payload eliminators.

3. **A `Copy` pointee may satisfy an independently established owned-value demand.**
   When an existing context requires an owned value and `T: Copy`, an expression of type `&T` may satisfy that demand by copying the pointee.

4. **Views retain their origins through transparent carriers.**
   Wrapping, projecting, eliminating, forwarding, or joining a view through `Option`, `Result`, tuples, patterns, or compiler-generated temporaries does not erase its origin. An origin ends only when an operation actually produces an independent owned value.

These are one coherent rule set. They must not be implemented as conditional map signatures, conditional `unwrap` signatures, or ad hoc container-specific exceptions.

---

## 2. Scope

### 2.1 Keyed maps covered by D22

D22 applies to every **owning keyed map** in the standard library, including at least:

* `HashMap[K, V]`
* `BTreeMap[K, V]`

A library type presented as an owning keyed map should follow the same contract unless its API explicitly represents a different ownership operation.

`SlotMap[T]` already follows the same principle:

```with
get(handle)    -> Option[&T]
remove(handle) -> Option[T]
```

D22 confirms that contract but does not otherwise change `SlotMap`.

### 2.2 APIs not restandardized by D22

D22 does not change the declared signatures of:

* `Vec` indexing or lookup;
* fixed-array indexing or lookup;
* slice indexing or lookup;
* string indexing or lookup;
* iterator element APIs;
* arbitrary user-defined `get` methods.

The general contextual-materialization, exact-projection, join, and origin-propagation rules in this decision apply to those APIs according to their existing signatures.

Any future change to their signatures is a separate decision, provisionally identified as **D23**.

### 2.3 Key parameter mode

D22 does not change how a map accepts its key argument. The key parameter continues to use the mode specified by that container’s API.

---

## 3. Terminology

### 3.1 Exact type

The **exact type** of an expression is its type before contextual Copy materialization or ordinary value coercion.

Examples:

```with
let view = counts.get("api").unwrap()
```

If `counts: HashMap[str, i32]`, the exact type of `view` is `&i32`.

```with
match counts.get("api"):
    Some(value) => ...
```

The exact type of `value` is `&i32`.

### 3.2 Owned-value demand

An **owned-value demand** is an independently established requirement that an expression produce an owned value of a resolved type.

Inference alone is not an owned-value demand.

### 3.3 Contextual Copy materialization

**Contextual Copy materialization** is the operation by which an expression of type `&T`, where `T: Copy`, satisfies an independently established owned-value demand by copying the pointee.

The resulting value is independent of the reference and carries no view origin.

### 3.4 Transparent carrier

A **transparent carrier** is a value whose structure may contain or forward another value without making that value independent.

Transparent carriers include at least:

* `Option[T]`
* `Result[T, E]`
* tuples;
* structs or enums containing ephemeral values;
* pattern projections;
* compiler-generated temporaries;
* control-flow joins;
* non-owning combinators that return or forward a carried view.

Transparency is semantic. It does not depend on source spelling or lowering strategy.

### 3.5 View origin

A **view origin** identifies the storage or value from which an ephemeral reference or view is derived.

A view may have more than one possible origin after control-flow joins.

---

## 4. Uniform Owning-Map Contract

### 4.1 Required signatures

Every owning keyed map must provide the following ownership contract:

| Operation | Signature                               | Ownership                 |
| --------- | --------------------------------------- | ------------------------- |
| `get`     | `(self: &Self, key: K) -> Option[&V]`   | Borrows map-owned storage |
| `remove`  | `(mut self: Self, key: K) -> Option[V]` | Transfers ownership out   |

The exact key parameter mode may vary according to the map’s declared API. The result contracts above do not.

### 4.2 `get`

`get` returns `Option[&V]` for every `V`.

Its return type must not vary according to whether `V` implements `Copy`, `Clone`, `Drop`, or any other trait.

```with
let a: Option[&i32] = counts.get("api")
let b: Option[&Vec[Job]] = queues.get("ready")
```

Both calls have the same structural return shape.

The returned reference originates in the map receiver. It does not originate in the transient key argument.

The returned reference remains valid only while:

* the map remains alive;
* the relevant map storage remains unmutated;
* the reference has not passed its final use.

Normal non-lexical view-liveness rules apply.

### 4.3 `remove`

`remove` returns `Option[V]`.

A successful removal transfers ownership of the stored value out of the map. The returned value is independent of subsequent mutation or destruction of the map.

```with
let owned = queues.remove("ready")?
queues.clear()
use(owned)                    // valid
```

`remove` is the standard operation for taking ownership from a map.

### 4.4 Copying and cloning conveniences

A separately named convenience may produce an owned value from `get`, including:

```with
map.get(key).copied()     // requires V: Copy
map.get(key).cloned()     // requires V: Clone
```

Such conveniences are ownership boundaries.

They do not change the contract of `get`.

---

## 5. Exact-Type Preservation

### 5.1 General rule

A shared reference `&T` remains `&T` during inference and exact-type propagation.

`Copy` does not silently erase reference identity.

Exact-type preservation applies to at least:

* unannotated bindings;
* inferred function returns;
* pattern bindings;
* tuple and field projection;
* closure capture;
* `Option.unwrap`;
* `Option.expect`;
* `Result.unwrap`;
* `Result.expect`;
* `?` successful payload extraction;
* `Some(value)` and `Ok(value)` pattern bindings;
* `if let`;
* `let ... else`;
* refutable `for` patterns;
* equivalent structural eliminators.

Examples:

```with
let count = counts.get("api").unwrap()
// count: &i32
```

```with
fn find[K, V](map: &HashMap[K, V], key: &K):
    map.get(key)
// inferred return: Option[&V]
```

```with
match map.get(key):
    Some(value) => use(value)  // value: &V
    None => ()
```

### 5.2 Inference is not a demand

The following do not independently demand an owned value:

```with
let x = view
```

```with
fn inferred():
    view
```

```with
match value:
    Some(x) => ...
```

```with
let closure = () => view
```

These forms preserve the exact reference type and its origins.

### 5.3 Explicit reference preservation

No special `ref` pattern syntax is required merely to preserve a reference.

Because inference already preserves the exact reference type, both forms below preserve `&i32`:

```with
let a = counts.get("api").unwrap()
let b: &i32 = counts.get("api").unwrap()
```

The annotation may document or verify intent but is not required for reference preservation.

---

## 6. Contextual Copy Materialization

### 6.1 Core rule

When `T: Copy`, an expression of type `&T` may satisfy an independently established owned-value demand.

The compiler:

1. reads and copies the pointee;
2. produces an independent owned `T`;
3. applies any ordinary value coercions required by the destination.

Example:

```with
let view: &i32 = counts.get("api").unwrap()

let a: i32 = view
let b: i64 = view
```

The first use copies the pointee as `i32`.

The second use copies the pointee as `i32`, then applies the ordinary lossless widening conversion to `i64`.

The reference itself remains borrowed if it is used again:

```with
let view = counts.get("api").unwrap()
let snapshot: i32 = view
print_ref(view)                 // still valid
```

### 6.2 Contexts that establish owned-value demand

An owned-value demand is established independently by one of the following:

1. **A declared destination type**

   * typed binding;
   * assignment target;
   * cast target;
   * declared function return type;
   * known struct-field type;
   * known tuple-component type;
   * known array or collection element type.

2. **A resolved by-value callable position**

   * by-value function parameter;
   * by-value constructor component;
   * already-selected by-value method receiver;
   * another resolved callable component whose type is owned.

3. **A resolved operator position**

   * operand type selected by operator resolution;
   * result type established by the operator contract.

4. **A multi-expression join**

   * as specified in Section 8.

### 6.3 Examples

Typed binding:

```with
let snapshot: i32 = counts.get("api").unwrap()
```

Assignment:

```with
var snapshot: i32 = 0
snapshot = counts.get("api").unwrap()
```

Declared return:

```with
fn current_count(counts: &HashMap[str, i32]) -> i32:
    counts.get("api").unwrap()
```

Constructor component:

```with
fn wrapped(counts: &HashMap[str, i32]) -> Option[i32]:
    match counts.get("api"):
        Some(value) => Some(value)
        None => None
```

`value` remains `&i32` in the pattern. `Some` expects an owned `i32`, so its constructor component establishes the owned demand.

Operator operand:

```with
let next = counts.get("api").unwrap() + 1
```

Comparison:

```with
if counts.get("api").unwrap() == 42:
    ...
```

### 6.4 Non-Copy values

A reference to a non-`Copy` value cannot satisfy an owned-value demand through contextual materialization.

```with
let jobs: Vec[Job] = queues.get("ready").unwrap()
// error: Vec[Job] is not Copy
```

An independent non-`Copy` value requires an explicit ownership-producing operation, such as:

* `clone`;
* `cloned`;
* `remove`;
* a consuming conversion;
* construction of a new owned value.

### 6.5 No hidden cloning

Contextual Copy materialization performs only the operation authorized by `Copy`.

It must never:

* call `Clone`;
* allocate;
* transfer ownership;
* retain the reference as hidden storage;
* duplicate a `Drop` value;
* produce an owned non-`Copy` value.

### 6.6 Resolution order

Method lookup, overload resolution, trait selection, and ABI selection occur while preserving the expression’s exact reference type.

Ordinary auto-dereferencing may participate in resolution.

Contextual Copy materialization may satisfy an already-selected by-value receiver or parameter, but it must not:

* select a different method;
* select a different overload;
* change dynamic dispatch;
* change a function’s ABI;
* change the declared signature of the producer.

---

## 7. Pattern Projection

### 7.1 Structural projection is not an owned-value demand

Pattern matching is structural projection.

A pattern binding receives the exact type of the projected subvalue.

Pattern projection does not contextually copy `Copy` values.

### 7.2 `Option` and `Result`

Matching `Option[&V]` binds `&V` for every `V`:

```with
match map.get(key):
    Some(value) => ...  // value: &V
    None => ...
```

This is uniform across all generic instantiations.

Matching `Result[&T, E]` similarly binds the successful payload as `&T`.

### 7.3 Nested projection

Projection through a shared reference produces shared-reference subviews.

```with
let pair: Option[&(A, B)] = ...

match pair:
    Some((a, b)) =>
        // a: &A
        // b: &B
```

Projection is recursive and exact.

If the projected field is itself a reference, the resulting binding preserves that additional reference layer.

```with
// subject payload: &(A, &B)
// bindings:
a: &A
b: &&B
```

### 7.4 Later materialization

A projected reference may later satisfy an independently established owned-value demand when its pointee is `Copy`.

```with
match counts.get("api"):
    Some(value) =>
        let snapshot: i32 = value
    None => ()
```

The pattern preserves `value: &i32`.

The typed binding materializes the independent `i32`.

### 7.5 Closures

A closure captures the exact projected reference unless an owned value is materialized before capture.

```with
let value = counts.get("api").unwrap()
let f = () => use_ref(value)
```

The closure captures the reference and its origin.

```with
let value: i32 = counts.get("api").unwrap()
let f = () => use_value(value)
```

The closure captures an independent `i32`.

---

## 8. Multi-Expression Join Rule

### 8.1 Covered forms

The contextual join rule applies to:

* `if` expressions;
* `match` expressions;
* `??`;
* `unwrap_or`;
* `unwrap_or_else`;
* array and collection literals;
* equivalent control-flow or multi-expression joins.

### 8.2 Join algorithm

For all reaching expressions in the join:

1. **Exact equality**

   If all reaching expressions have the same exact type, that type is preserved.

2. **Determine an owned candidate without borrowing reference arms**

   The compiler determines whether an owned result type `J` is independently established by:

   * an enclosing expected type; or
   * one or more non-reference reaching expressions, using the ordinary join and coercion rules.

   Reference arms do not themselves establish `J`.

3. **Materialize compatible reference arms**

   If an owned result type `J` is established, an expression of type `&T` may satisfy that arm when:

   * `T: Copy`; and
   * an owned `T` can ordinarily coerce to `J`.

   The compiler copies the pointee and applies the ordinary coercion to `J`.

4. **Reference-only join**

   If no owned `J` is established and all reaching expressions are compatible shared references, the result remains a shared reference.

   Its origin set is the union of the origins of all reaching paths.

5. **No implicit borrowing of owned temporaries**

   An owned temporary must not be implicitly borrowed merely to force a reference result.

6. **Non-Copy mismatch**

   A reference to non-`Copy` `T` cannot satisfy an owned result type `J` without an explicit ownership-producing operation.

7. **Order independence**

   Arm order must not affect the result type.

### 8.3 Examples

Same reference type:

```with
let selected = if use_primary:
    primary.get(key).unwrap()
else:
    fallback.get(key).unwrap()
// selected: &V
// origins: union(primary, fallback)
```

Owned default anchors `??`:

```with
let port = counts.get("port") ?? 8080
// left payload: &i32
// right expression: i32
// result: i32
```

Owned function result anchors a multi-arm match:

```with
let selected = match source:
    .Api      => counts.get("api").unwrap()
    .Worker   => counts.get("worker").unwrap()
    .Queue    => counts.get("queue").unwrap()
    .Fallback => counts.get("fallback").unwrap()
    .Computed => compute_count()
// compute_count(): i32 establishes J = i32
// all &i32 arms materialize
// selected: i32
```

Explicit expected type pins the result:

```with
let selected: i32 = match source:
    .Api      => counts.get("api").unwrap()
    .Worker   => counts.get("worker").unwrap()
    .Queue    => counts.get("queue").unwrap()
    .Fallback => counts.get("fallback").unwrap()
    .Computed => compute_count()
```

Non-Copy mismatch:

```with
let jobs = queues.get("ready") ?? Vec.new()
// error: left branch is &Vec[Job]; Vec[Job] is not Copy
```

Borrowed default:

```with
let empty = Vec.new()
let jobs = queues.get("ready") ?? &empty
// jobs: &Vec[Job]
// origins: union(queues, empty)
```

Explicit clone:

```with
let jobs = queues.get("ready").cloned() ?? Vec.new()
// jobs: Vec[Job]
```

### 8.4 Inferred-type changes after editing arms

Removing or changing the last expression that independently establishes an owned result may change an inferred join from an owned type to a reference type.

Example:

```with
let selected = match source:
    .Api      => counts.get("api").unwrap()
    .Worker   => counts.get("worker").unwrap()
    .Computed => compute_count()
```

`selected` is `i32`.

Changing `.Computed` to return another `&i32` makes every arm reference-shaped, so the inferred type becomes `&i32`.

This is an ordinary inferred-type change, but it changes view-origin obligations.

Code that requires a stable owned result should declare it:

```with
let selected: i32 = match source:
    ...
```

### 8.5 Join diagnostics

Clean builds do not emit coercion notes.

When a later diagnostic depends on whether a join preserved references or materialized owned values, the diagnostic must identify:

* the expression or enclosing expected type that established the owned join;
* each relevant reference arm that was materialized;
* or, for a reference result, the reaching arms that contributed origins.

---

## 9. `Option` and `Result` Elimination

### 9.1 Exact-payload eliminators

The following preserve the exact payload type:

* `unwrap`;
* `expect`;
* `?`;
* `Some(value)` patterns;
* `Ok(value)` patterns;
* `if let`;
* `let ... else`;
* ordinary `match` projection.

Therefore:

```with
let x = option_ref.unwrap()
```

If `option_ref: Option[&T]`, then `x: &T`.

`unwrap` must not return `T` when `T: Copy` and `&T` otherwise.

### 9.2 Join-based eliminators

The following use the contextual join rule:

* `??`;
* `unwrap_or`;
* `unwrap_or_else`;
* equivalent methods that choose among multiple expressions.

Normative signatures:

```with
Option[T].unwrap_or[U](default: U) -> Join[T, U]
Option[T].unwrap_or_else[U](default: fn() -> U) -> Join[T, U]

Result[T, E].unwrap_or[U](default: U) -> Join[T, U]
Result[T, E].unwrap_or_else[U](default: fn(E) -> U) -> Join[T, U]
```

`Join[T, U]` is specification metavocabulary. It is not user-facing type syntax. It means the contextual join defined in Section 8.

### 9.3 `??`

```with
expr ?? fallback
```

evaluates `expr` once.

The fallback is lazy.

Its successful and fallback expressions are joined under Section 8.

Conceptually:

```with
match expr:
    Some(value) => value
    None => fallback
```

The conceptual pattern preserves the exact payload type. The surrounding join determines whether contextual Copy materialization occurs.

Consequences:

```with
Option[&T] ?? &T
```

produces `&T` and unions origins.

```with
Option[&T] ?? T
```

produces `T` when `T: Copy`.

```with
Option[&T] ?? T
```

is an error when `T` is not `Copy`, unless the successful path explicitly produces an owned value.

### 9.4 Early-exit forms

The early-exit forms:

```with
value ?? return ...
value ?? break
value ?? continue
```

preserve the exact successful payload type.

The diverging fallback contributes no result type.

### 9.5 `copied` and `cloned`

`Option` must provide:

| Method     | Availability                    | Result      |
| ---------- | ------------------------------- | ----------- |
| `copied()` | `Self = Option[&T]`, `T: Copy`  | `Option[T]` |
| `cloned()` | `Self = Option[&T]`, `T: Clone` | `Option[T]` |

Both operations end the successful payload’s view origin.

---

## 10. Transparent-Carrier Origin Propagation

### 10.1 General rule

Constructing, carrying, projecting, eliminating, forwarding, or joining a value that contains a view preserves the origin set of every view that can flow into the result.

This applies whether the carrier is written explicitly by the programmer or introduced by the compiler.

### 10.2 Required carriers and eliminators

Origin propagation applies through at least:

* `Option`;
* `Result`;
* tuples;
* ephemeral structs and enums;
* `Some` and `Ok` construction;
* pattern bindings;
* `match`;
* `if let`;
* `let ... else`;
* `?`;
* `??`;
* `unwrap`;
* `expect`;
* `unwrap_or`;
* `unwrap_or_else`;
* optional chaining;
* non-owning combinators;
* compiler-generated temporaries;
* lowering-generated enum payload operations.

### 10.3 Origin union

A control-flow join carries the union of the origins from all reaching view-producing paths.

```with
let selected = if choose_a:
    map_a.get(key).unwrap()
else:
    map_b.get(key).unwrap()
```

`selected` may originate in either `map_a` or `map_b`.

Mutation invalidating either possible origin is forbidden while `selected` remains live.

### 10.4 Operations that end an origin

Origin propagation ends only when an operation actually produces an independent owned value.

Such operations include:

* contextual Copy materialization;
* `copied`;
* explicit `clone`;
* `cloned`;
* construction of a new owned value;
* ownership transfer from `remove`;
* another consuming operation explicitly specified to return ownership.

Merely wrapping a view in an enum, tuple, temporary, intrinsic result, or backend-specific representation does not end its origin.

### 10.5 Semantic rule

Origin tracking follows semantic values, not wrapper spellings.

A view does not become independent merely because it passed through:

* an enum;
* a tuple;
* a local temporary;
* an intrinsic;
* an inlined function;
* an intermediate representation;
* a compiler-generated lowering;
* a backend ABI representation.

### 10.6 Non-owning combinators

A combinator that returns or forwards a view derived from its input must propagate that view’s origin.

A combinator that produces an unrelated independent owned value does not propagate the input view origin into that value.

The determination follows ordinary origin inference and declared effects, not the combinator’s name.

---

## 11. Required Diagnostics

### 11.1 Mutation while a view remains live

When mutation is rejected because an unannotated binding retained a reference to a `Copy` value, the diagnostic must explain the view and show how to request an independent copy.

Required shape:

```text
error: cannot mutate `counts` while `count` is a live view into it
  --> source.w:12:5
   |
10 | let count = counts.get("api").unwrap()
   |     ----- `count` views a value stored in `counts`
11 | counts.clear()
   | ^^^^^^^^^^^^^ mutation would invalidate that view
12 | print(count)
   |       ----- view is used here after the mutation
   |
help: take an independent Copy value:
   |
10 | let count: i32 = counts.get("api").unwrap()
   |          +++++
```

The fix must be machine-applicable when the owned type is known and source rewriting is unambiguous.

### 11.2 Non-Copy owned join

When `??`, `unwrap_or`, `unwrap_or_else`, or another join would require copying a non-`Copy` value, the diagnostic must describe the ownership mismatch rather than presenting a bare unification error.

Required shape:

```text
error: `??` cannot produce an owned `Vec[Job]`
  --> source.w:8:39
   |
8  | let jobs = queues.get("ready") ?? Vec.new()
   |            -------------------    ^^^^^^^^^ owned fallback
   |            |
   |            successful value has type `&Vec[Job]`
   |
note: `Vec[Job]` is not `Copy`; a borrowed value cannot become owned implicitly
help: clone the found value:
   |
8  | let jobs = queues.get("ready").cloned() ?? Vec.new()
   |                                      +++++++++
help: or borrow the fallback as well:
   |
7  | let empty = Vec.new()
8  | let jobs = queues.get("ready") ?? &empty
```

A clone suggestion may be emitted only when the type implements an applicable owning operation.

The diagnostic must not imply that a type annotation can copy a non-`Copy` value.

### 11.3 Materialized join explanations

When a diagnostic depends on a mixed join that materialized one or more reference arms, it must identify:

* the expected type or owned expression that established the owned result;
* the arms materialized to meet that result;
* the type copied from each reference arm.

### 11.4 Origin through carriers

When a view passed through `Option`, `Result`, a pattern, or another carrier, diagnostics should identify the original storage owner rather than blaming only the final eliminator.

For example, a view obtained through:

```with
let value = map.get(key).unwrap()
```

should be described as viewing storage in `map`, not as viewing storage in the temporary `Option`.

---

## 12. Generic Semantics

### 12.1 Uniform forwarding

Generic code observes one uniform map contract:

```with
fn find[K, V](map: &HashMap[K, V], key: &K) -> Option[&V]:
    map.get(key)
```

This signature is valid for both `Copy` and non-`Copy` `V`.

The return type must not change by instantiation.

### 12.2 Exact generic pattern bindings

```with
fn inspect[K, V](map: &HashMap[K, V], key: &K):
    match map.get(key):
        Some(value) => use_ref(value)
        None => ()
```

`value` is `&V` for every instantiation.

Whether a later use may materialize an owned value depends on whether the concrete `V` implements `Copy` and whether that use independently demands an owned value.

### 12.3 Honest owned generic functions

A function that returns an owned `V` from a shared map must state the required ownership information.

Copy form:

```with
fn get_or_default[K, V: Copy](
    map: &HashMap[K, V],
    key: &K,
    default: V,
) -> V:
    map.get(key) ?? default
```

Clone form:

```with
fn get_or_clone[K, V: Clone](
    map: &HashMap[K, V],
    key: &K,
    default: V,
) -> V:
    map.get(key).cloned() ?? default
```

Borrowed form:

```with
fn get_or_ref[K, V](
    map: &HashMap[K, V],
    key: &K,
    default: &V,
) -> &V:
    map.get(key) ?? default
```

The `Copy` or `Clone` bound and the borrowed default are ownership information, not optional ceremony.

---

## 13. Explicitly Non-Conforming Interpretations

The following implementations violate D22.

### 13.1 Conditional map lookup

It is non-conforming for `get` to have either of these conditional contracts:

```with
get -> Option[V]   when V: Copy
get -> Option[&V]  otherwise
```

or any equivalent hidden `Read[V]` return rule.

`get` must return `Option[&V]` uniformly.

### 13.2 Conditional `unwrap`

It is non-conforming for:

```with
Option[&T].unwrap()
```

to return `T` when `T: Copy` and `&T` otherwise.

It always returns the exact payload type, `&T`.

The same prohibition applies to:

* `expect`;
* `?`;
* `Some` and `Ok` patterns;
* `if let`;
* `let ... else`;
* equivalent exact-payload eliminators.

### 13.3 Eager inferred-binding copies

It is non-conforming for an unannotated binding to materialize a `Copy` pointee merely because the pointee is `Copy`.

```with
let count = counts.get("api").unwrap()
```

must infer `&i32`, not `i32`.

### 13.4 Conditional pattern types

It is non-conforming for:

```with
Some(value)
```

matched against `Option[&V]` to bind `V` for `Copy` instantiations and `&V` for non-`Copy` instantiations.

It binds `&V` uniformly.

### 13.5 Origin laundering

It is non-conforming to erase a view origin merely because the view passes through:

* `Option`;
* `Result`;
* a tuple;
* a pattern;
* an intrinsic;
* a temporary;
* an intermediate representation;
* backend lowering.

### 13.6 Implicit non-Copy ownership

It is non-conforming to satisfy an owned demand from `&T` when `T` is not `Copy`, unless the source expression explicitly performs an owning operation.

### 13.7 Container-specific elimination hacks

It is non-conforming to special-case `Option.unwrap`, `??`, patterns, or other general eliminators based on whether their value originated from `HashMap.get`.

The rules must be implemented as general exact-type, contextual-materialization, join, and origin-propagation semantics.

---

## 14. Required Conformance Matrix

A conforming implementation must test the following behaviors through semantic analysis, comptime, every code-generation backend, and runtime execution where applicable.

### 14.1 Uniform types

```with
let x = counts.get("api")
// x: Option[&i32]
```

```with
let x = queues.get("ready")
// x: Option[&Vec[Job]]
```

```with
let x = counts.get("api").unwrap()
// x: &i32
```

```with
match counts.get("api"):
    Some(x) => ...  // x: &i32
    None => ()
```

### 14.2 Contextual Copy materialization

```with
let x: i32 = counts.get("api").unwrap()
```

must compile.

```with
fn f(counts: &HashMap[str, i32]) -> i32:
    counts.get("api").unwrap()
```

must compile.

```with
let x = counts.get("api").unwrap() + 1
```

must compile.

```with
let x = counts.get("api").unwrap() == 1
```

must compile.

### 14.3 No inferred eager copy

```with
let x = counts.get("api").unwrap()
```

must infer `&i32`.

### 14.4 Non-Copy ownership rejection

```with
let x: Vec[Job] = queues.get("ready").unwrap()
```

must fail.

```with
let x = queues.get("ready") ?? Vec.new()
```

must fail unless the successful path explicitly clones or otherwise produces ownership.

### 14.5 Origin preservation

Each of the following must retain the map origin:

```with
let x = map.get(key).unwrap()
```

```with
let x = try map.get(key)
```

```with
let x = map.get(key) ?? &fallback
```

```with
match map.get(key):
    Some(x) => ...
```

```with
if let Some(x) = map.get(key):
    ...
```

```with
let Some(x) = map.get(key) else return
```

```with
let x = map.get(key).unwrap_or(&fallback)
```

```with
let x = map.get(key).unwrap_or_else(() => &fallback)
```

Mutation invalidating the origin before the view’s final use must be rejected.

### 14.6 Origins end at ownership boundaries

These must be accepted:

```with
let copied: i32 = counts.get(key).unwrap()
counts.clear()
use(copied)
```

```with
let cloned = queues.get(key).cloned().unwrap()
queues.clear()
use(cloned)
```

```with
let removed = queues.remove(key).unwrap()
queues.clear()
use(removed)
```

### 14.7 Origin unions

```with
let x = if cond:
    a.get(key).unwrap()
else:
    b.get(key).unwrap()
```

must retain possible origins from both `a` and `b`.

Mutation of either map before `x`’s final use must be rejected.

### 14.8 NLL precision

After the final use of a view, mutation must be accepted:

```with
let x = map.get(key).unwrap()
use(x)                 // final use
map.clear()            // valid
```

A conservative implementation that rejects this case is non-conforming precision debt.

### 14.9 Generic stability

The following must retain one signature for all `V`:

```with
fn find[K, V](map: &HashMap[K, V], key: &K) -> Option[&V]:
    map.get(key)
```

Pattern bindings within generic bodies must remain `&V` for every instantiation.

---

## 15. Supersession

D22 supersedes the former call-site-only restriction on reading a `Copy` pointee through `&T`.

The old restriction that allowed materialization only for by-value function arguments is retired.

Any compile-fail fixture asserting that an `&i32` cannot satisfy a declared `i32` return, typed binding, assignment, operator operand, or owned join is no longer a language requirement.

Such fixtures must be converted into must-compile tests where D22 permits materialization.

D22 also supersedes every active document, example, test, or implementation rule stating or implying that:

```with
HashMap[K, V].get -> Option[V]
```

for all values, or conditionally when `V: Copy`.

Historical documents may be retained for provenance but must carry a conspicuous supersession notice.

No rationale should be invented for the retired call-site-only restriction where no recorded rationale exists.

---

## 16. Implementation Doctrine

The implementation must follow this order of authority:

1. D22 normative semantics;
2. the current reference specification;
3. conformance tests;
4. implementation code.

Existing implementation behavior must not be used to reinterpret the ruling.

The implementation should be structured around general mechanisms:

* exact-type propagation;
* contextual Copy materialization;
* ordinary type-demand resolution;
* contextual joins;
* semantic view-origin propagation.

It must not be structured around isolated patches such as:

* “HashMap `get` copies integers”;
* “`unwrap` copies Copy payloads”;
* “`??` has a special map rule”;
* “the LLVM backend fixes the type after semantic analysis”;
* “the C backend uses a different lookup contract.”

All semantic layers and all backends must agree on the same source-level type and ownership behavior.

---

## 17. Normative Principle

The ruling may be summarized as:

> **Lookup observes; removal transfers. References preserve identity until an owned context spends that identity by making an authorized Copy. Wrappers never launder a view.**

Or, in operational form:

> A shared reference remains a shared reference through inference, forwarding, and structural projection. When an independently established context requires an owned value, the compiler may copy the pointee only when the pointee is `Copy`. Until such an owned value is actually produced, every transparent carrier preserves the reference’s origin.
