# Spec Addition: Implicit Closure Parameter `it`

## Summary

When a closure has exactly one parameter, the identifier `it` is
implicitly bound to that parameter. The closure argument list may
be omitted entirely.

```
items |> filter(it % 2 == 0)
```

is equivalent to:

```
items |> filter(|n| n % 2 == 0)
```

---

## Syntax

Any expression passed in a closure position that references `it`
and has no explicit parameter list is treated as an implicit
single-parameter closure.

```
// Grammar addition:
//
// closure_expr = '|' param_list '|' expr        // explicit (existing)
//              | expr_containing_it              // implicit (new)
//
// The compiler detects the implicit form when:
//   1. An expression appears in a position expecting fn(T) -> U
//   2. The expression references the identifier `it`
//   3. No explicit parameter list is present
```

---

## Semantics

### Type Inference

`it` receives its type from the expected parameter type at the call
site, exactly as explicit closure parameters do today.

```
// filter expects fn(i32) -> bool
// therefore it: i32
items |> filter(it % 2 == 0)

// map expects fn(User) -> str
// therefore it: User
users |> map(it.name)
```

### Scope

`it` is scoped to the implicit closure expression. It does not leak
into surrounding scope. Nested implicit closures are not permitted —
the inner closure must use explicit parameters to avoid ambiguity.

```
// OK — single level
items |> map(it * 2)

// OK — explicit inner, implicit outer
items |> map(it.children |> filter(|c| c.active))

// ERROR — nested implicit closures, ambiguous it
items |> map(it.children |> filter(it.active))
//                                 ^^ error: nested implicit closure
//                                    use explicit parameter: |c| c.active
```

### Where `it` Is Available

`it` is available anywhere a single-parameter closure is expected:

```
// Pipeline functions
items |> filter(it > 0)
items |> map(it.name)
items |> any(it.active)
items |> all(it > threshold)
items |> find(it.id == target_id)
items |> count(it.is_valid())
items |> reduce(0, |acc, x| acc + x)   // multi-param: explicit

// Method calls
items.filter(it > 0)
items.map(it.name)
items.sort_by(it.age)

// Standalone closures assigned to variables
let is_even = (it % 2 == 0)           // type inferred from usage
let double = (it * 2)

// Function arguments
let result = retry(3, it + 1)          // ERROR if fn expects 2+ params
```

### Where `it` Is NOT Available

- **Multi-parameter closures.** If the expected function type has more
  than one parameter, `it` is not available. Use explicit parameters.

  ```
  // reduce expects fn(Acc, T) -> Acc — two params, must be explicit
  items |> reduce(0, |acc, x| acc + x)

  // zip_with expects fn(A, B) -> C — two params, must be explicit
  zip_with(xs, ys, |a, b| a + b)
  ```

- **Ambiguous closure position.** If the compiler cannot determine
  that the expression is in a closure position (e.g., it's a bare
  expression not passed to a function), `it` is a normal identifier
  lookup and follows standard resolution.

- **Nested implicit closures.** As described above, the inner closure
  must use explicit parameters.

### `it` Is A Reserved Keyword

`it` is a keyword, the same as `if`, `for`, `match`, `fn`. It cannot
be used as a variable name, function name, parameter name, field name,
or any other identifier.

```
let it = 42            // ERROR: `it` is a reserved keyword
fn it():               // ERROR: `it` is a reserved keyword
|it| it + 1            // ERROR: `it` is a reserved keyword, use a different name

// The ONLY valid use of `it`:
items |> filter(it > 0)    // implicit closure parameter
```

This eliminates all shadowing ambiguity. `it` always means exactly
one thing: the implicit single-parameter closure reference.

### Interaction With `_`

`_` remains the discard/wildcard symbol. `it` is the implicit parameter.
They do not overlap.

```
// _ discards a value
let _ = expensive_call()

// it is the implicit parameter
items |> filter(it > 0)

// In match arms, _ is wildcard, it is not special
match value
    Some(x) -> x
    _ -> 0
```

---

## Desugaring

The compiler desugars implicit closures early, during parsing or
immediately after. The transformation is:

```
// Source
items |> filter(it % 2 == 0)

// Desugared
items |> filter(|__it| __it % 2 == 0)
```

The desugared parameter name is internal. The user always writes `it`.

### Detection Algorithm

When the compiler encounters an expression in a closure-expected
position:

1. Walk the expression tree.
2. If `it` appears anywhere in the expression:
   a. Verify the expected type is `fn(T) -> U` (single parameter).
   b. If yes: wrap the expression as a closure with one parameter
      bound to `it`.
   c. If the expected type has 0 or 2+ parameters: error.
3. If `it` does not appear, treat the expression normally
   (not a closure).

Since `it` is a reserved keyword, it can never appear as a local
variable or other binding. Any occurrence of `it` in an expression
unambiguously signals an implicit closure.

---

## Method Access Shorthand

A common pattern is accessing a field or calling a method:

```
users |> map(it.name)
users |> filter(it.is_active())
users |> sort_by(it.age)
```

These desugar to:

```
users |> map(|__it| __it.name)
users |> filter(|__it| __it.is_active())
users |> sort_by(|__it| __it.age)
```

---

## Chaining

`it` works naturally in chained expressions:

```
users
    |> filter(it.age >= 18)
    |> map(it.name |> uppercase)
    |> filter(it |> starts_with("A"))
```

Each `it` in each pipeline step refers to that step's closure
parameter. There is no ambiguity because each step is a separate
closure position.

---

## Comparison With Explicit Closures

| Pattern | Explicit | Implicit |
|---|---|---|
| Simple predicate | `\|n\| n > 0` | `it > 0` |
| Field access | `\|u\| u.name` | `it.name` |
| Method call | `\|u\| u.is_active()` | `it.is_active()` |
| Arithmetic | `\|n\| n * 2 + 1` | `it * 2 + 1` |
| Two params | `\|a, b\| a + b` | not available |
| Nested closure | `\|u\| u.items.filter(\|i\| i.ok)` | `it.items.filter(\|i\| i.ok)` |

---

## Examples

### Idiomatic With with `it`

```
// Filter and sum
let total = items |> filter(it > 0) |> sum

// Extract field
let names = users |> map(it.name) |> collect[Vec]

// Chain predicates
let results = entries
    |> filter(it.active)
    |> filter(it.score > threshold)
    |> map(it.name)

// Sort
let sorted = users |> sort_by(it.age)

// Find
let admin = users |> find(it.role == .Admin)

// Any / All
let has_errors = results |> any(it.is_err())
let all_valid = inputs |> all(it.len() > 0)

// String processing
let cleaned = lines
    |> map(it |> trim)
    |> filter(it.len() > 0)
    |> filter(it |> starts_with("#") |> not)

// Nested — inner must be explicit
let active_children = groups
    |> map(it.members |> filter(|m| m.active) |> count)
```

### The Landing Page Example

```
fn main:
    let sum = read_file("nums.txt")?
        |> lines |> map(parse[i32]) |> filter(it % 2 == 0) |> sum
    println("Sum of evens: {sum}")
```

---

## Error Messages

### Nested implicit closure

```
error[E0901]: nested implicit closure is ambiguous
  --> src/main.w:12:42
   |
12 |     groups |> map(it.items |> filter(it.active))
   |                                      ^^ which `it`?
   |
   = help: use an explicit parameter for the inner closure
   = suggestion: groups |> map(it.items |> filter(|x| x.active))
```

### Wrong arity

```
error[E0902]: `it` used in context expecting 2 parameters
  --> src/main.w:8:30
   |
 8 |     pairs |> reduce(0, it + 1)
   |                        ^^ `reduce` expects fn(Acc, T) -> Acc
   |
   = help: use explicit parameters: |acc, x| acc + x
```

### `it` used as identifier

```
error[E0903]: `it` is a reserved keyword
  --> src/main.w:3:9
   |
 3 |     let it = 42
   |         ^^ cannot use `it` as a variable name
   |
   = note: `it` is the implicit closure parameter keyword
   = help: choose a different name
```