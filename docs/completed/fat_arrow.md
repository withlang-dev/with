# Spec Addition: `=>` Produces Operator

## Summary

`=>` is the universal "produces" operator. It replaces `|param|`
pipe syntax for closures and `->` for match arms. `->` is now
used exclusively for return type annotations.

```
// Closures — single parameter, use it
items |> filter(it > 0)

// Closures — single parameter, named
items |> filter(x => x > 0)

// Closures — multi parameter
items |> reduce(0, (acc, x) => acc + x)

// Closures — no parameters
spawn(() => println("done"))

// Match arms
match x
    .Some(v) => handle(v)
    .None => default()
```

| Symbol | Meaning |
|---|---|
| `=>` | "Produces this value" — closures and match arms |
| `->` | "Returns this type" — function signatures only |

---

## §8.X Closure Expressions

### Spec Language

A closure expression creates an anonymous function value. There are
three forms:

**Implicit parameter (`it`):**

```
items |> filter(it > 0)
items |> map(it.name)
```

When an expression in a closure-expected position references the
keyword `it`, it is treated as a single-parameter closure. See
§8.Y Implicit Closure Parameter.

**Single parameter (no parentheses):**

```
items |> filter(x => x > 0)
items |> map(user => user.name |> uppercase)
```

A single identifier followed by `=>` introduces a one-parameter
closure. The identifier is the parameter name. The expression
after `=>` is the body. No parentheses needed.

**Multiple parameters (parenthesized):**

```
items |> reduce(0, (acc, x) => acc + x)
pairs |> map((a, b) => a + b)
grid |> each((x, y, val) => draw(x, y, val))
```

A parenthesized parameter list followed by `=>` introduces a
multi-parameter closure. Parameters are comma-separated inside
the parentheses.

**Zero parameters:**

```
let f = () => 42
spawn(() => println("fire and forget"))
```

Empty parentheses followed by `=>` introduces a zero-parameter
closure.

**Typed parameters:**

Parameters may optionally include type annotations:

```
(x: i32, y: i32) => x + y
(name: str) => name |> uppercase
```

Typed parameters require parentheses even for a single parameter:

```
// Untyped single param — no parens
x => x + 1

// Typed single param — parens required
(x: i32) => x + 1
```

**Return type annotation:**

A closure may optionally specify its return type after the
parameter list and before `=>`:

```
(x: i32) -> i32 => x + 1
(a: str, b: str) -> str => a ++ " " ++ b
```

This is rarely needed — the compiler infers the return type from
the body expression in almost all cases. Use it when inference
is ambiguous.

### Grammar

```
closure_expr =
    | 'it' expr                                    // implicit single param
    | IDENT '=>' expr                              // single param, untyped
    | '(' ')' '=>' expr                            // zero params
    | '(' param_list ')' '=>' expr                 // multi param
    | '(' param_list ')' '->' type '=>' expr       // multi param + return type

param_list = param (',' param)*
param = IDENT [':' type]
```

### Type Inference

Closure parameter types are inferred from the call site's expected
function type, exactly as before. The syntax change does not affect
type inference:

```
// filter expects fn(i32) -> bool
// therefore x: i32, inferred
items |> filter(x => x > 0)

// reduce expects fn(i32, i32) -> i32
// therefore acc: i32 and x: i32, inferred
items |> reduce(0, (acc, x) => acc + x)
```

### Multi-line closures

For closures with multiple statements, use a block after `=>`:

```
items |> map(x =>
    let doubled = x * 2
    let adjusted = doubled + offset
    adjusted
)

spawn(() =>
    let data = fetch(url).await
    process(data)
    println("done")
)
```

The indentation rules for closure bodies follow the same rules as
all other blocks in With. The last expression in the block is the
return value.

---

## Disambiguation

### `=>` vs `->`

| Symbol | Meaning |
|---|---|
| `=>` | "Produces this value" — closures and match arms |
| `->` | "Returns this type" — function and closure signatures only |

`=>` means "given this input, produce this output" everywhere:

```
// Match arm: given this pattern, produce this value
match x
    .Some(v) => handle(v)
    .None => default()

// Closure: given this parameter, produce this value
items |> filter(x => x > 0)
```

`->` means "returns this type" and nothing else:

```
fn foo(x: i32) -> i32: x + 1
(x: i32) -> i32 => x + 1
```

These are never ambiguous. `=>` appears after match patterns and
closure parameters. `->` appears only in type signatures.

### `=>` vs `>=`

`=>` and `>=` are both two-character tokens. `=>` starts with `=`,
`>=` starts with `>`. They begin with different characters. The
lexer reads left-to-right. No ambiguity.

---

## §6.X Match Arm Syntax

### Spec Language

Match arms use `=>` to separate the pattern from the body.
This replaces the previous `->` syntax.

```
match status
    .Active(user) => handle_active(user)
    .Suspended(reason) => handle_suspended(reason)
    .Deleted => handle_deleted()
```

**Single-line arms:**

```
match x
    .Some(v) => v
    .None => default_value
```

**Multi-line arms:**

```
match command
    .Quit =>
        save_state()
        exit(0)
    .Run(args) =>
        let result = execute(args)?
        println("done: {result}")
        result
```

**Guards:**

```
match score
    n if n >= 90 => "A"
    n if n >= 80 => "B"
    n if n >= 70 => "C"
    _ => "F"
```

**Destructuring:**

```
match response
    Ok({ users: [first, ..rest], total }) if total > 100 =>
        process(first, rest)
    Ok({ users: [], .. }) =>
        handle_empty()
    Err(.Timeout(duration)) if duration > 30.secs() =>
        retry()
```

**Grammar update:**

```
match_expr = 'match' expr indent match_arm+ dedent
match_arm = pattern ['if' expr] '=>' expr
```

The `->` token is removed from match arm syntax. It remains
valid only in return type annotations.

### Migration: Match Arms

All match arms change from `->` to `=>`.

| Old syntax | New syntax |
|---|---|
| `.Some(v) -> handle(v)` | `.Some(v) => handle(v)` |
| `.None -> default()` | `.None => default()` |
| `Ok(v) -> v` | `Ok(v) => v` |
| `Err(e) -> return Err(e)` | `Err(e) => return Err(e)` |
| `n if n > 0 -> n` | `n if n > 0 => n` |
| `_ -> fallback` | `_ => fallback` |

---

## Interaction With `it`

`it` and `=>` are complementary. `it` is syntactic sugar for the
most common case (single parameter, short body). `=>` is the
general form.

| Pattern | Preferred syntax |
|---|---|
| Single param, short | `it > 0` |
| Single param, named | `user => user.active` |
| Single param, typed | `(x: i32) => x + 1` |
| Multi param | `(acc, x) => acc + x` |
| Zero param | `() => println("hi")` |

`it` is never used with `=>`. Writing `it => it + 1` is
redundant — the compiler emits a style warning suggesting
either `it + 1` or `x => x + 1`.

---

## Migration From Pipe and Arrow Syntax

The `|param|` pipe closure syntax and the `->` match arm syntax
are both removed. All "produces" contexts use `=>`.

### Closures

| Old syntax | New syntax |
|---|---|
| `\|x\| x + 1` | `x => x + 1` |
| `\|x\| x > 0` | `it > 0` |
| `\|a, b\| a + b` | `(a, b) => a + b` |
| `\|x: i32\| x * 2` | `(x: i32) => x * 2` |
| `\|\| println("hi")` | `() => println("hi")` |
| `\|user\| user.name` | `it.name` |

### Match arms

| Old syntax | New syntax |
|---|---|
| `.Some(v) -> v` | `.Some(v) => v` |
| `.None -> default()` | `.None => default()` |
| `_ -> fallback` | `_ => fallback` |
| `n if n > 0 -> n` | `n if n > 0 => n` |

The `|` character is no longer used for closure parameters. It
remains available as the bitwise OR operator and in enum type
declarations (`type X = A \| B`).

The `->` token is no longer used for match arms. It remains
valid only in return type annotations (`fn foo -> i32`).

---

## Examples

### Pipelines

```
// Simple transforms
let names = users |> filter(it.active) |> map(it.name)

// With named param for clarity
let seniors = users |> filter(u => u.age >= 65 and u.active)

// Multi-param reduction
let total = items |> reduce(0, (sum, x) => sum + x.price)

// Chained with method calls
let result = data
    |> filter(it.valid)
    |> map(it.value)
    |> sort_by(x => x.timestamp)
    |> take(10)
```

### Callbacks

```
// Event handler
button.on_click(() => refresh_ui())

// Retry with backoff
retry(3, (attempt) => fetch(url).timeout(attempt * 100))

// Async spawn
spawn(() =>
    let data = fetch(url).await
    cache.set(key, data).await
)
```

### Collection operations

```
// Sort
users |> sort_by(it.name)

// Find
let admin = users |> find(it.role == .Admin)

// Group
let by_dept = employees |> group_by(it.department)

// Zip and combine
zip(xs, ys) |> map((a, b) => a + b)
```

### Stored closures

```
let predicate = x => x > threshold
let transform = (a: i32, b: i32) => a * b + offset

items |> filter(predicate) |> map(it * 2)
```

### Match expressions

```
// Simple enum matching
match option
    .Some(v) => v
    .None => default_value

// Pattern matching with guards
let grade = match score
    n if n >= 90 => "A"
    n if n >= 80 => "B"
    n if n >= 70 => "C"
    _ => "F"

// Nested destructuring
match response
    Ok({ status: 200, body }) => parse(body)
    Ok({ status }) => Err(.HttpError(status))
    Err(e) => Err(.NetworkError(e))

// Exhaustive enum matching
match command
    .Start => initialize()
    .Stop =>
        cleanup()
        exit(0)
    .Pause(duration) => sleep(duration)
    .Resume => continue_work()
```

---

## Implementation Note: Lexer Changes

### Note

Add `TK_FAT_ARROW` token for `=>`.

In the lexer, when `=` is encountered:
- If next char is `>`: emit `TK_FAT_ARROW`, advance 2.
- If next char is `=`: emit `TK_EQ_EQ`, advance 2.
- Otherwise: emit `TK_EQ`, advance 1.

No ambiguity with `>=` because `>=` starts with `>`, not `=`.

Remove `TK_PIPE` from closure parameter contexts. `|` remains
only as the bitwise OR operator and in type declarations.

---

## Implementation Note: Parser Changes

### Note

In `parse_expr` or equivalent, when the parser sees an expression
that could be a closure:

**Detection rules:**

1. `IDENT TK_FAT_ARROW` → single untyped parameter closure.
   Parse IDENT as param name, consume `=>`, parse body expr.

2. `TK_LPAREN ... TK_RPAREN TK_FAT_ARROW` → multi/zero/typed
   parameter closure. Parse param list (possibly empty, possibly
   typed), consume `=>`, parse body expr.

3. `TK_LPAREN ... TK_RPAREN TK_ARROW type TK_FAT_ARROW` →
   typed-return closure. Parse params, consume `->`, parse
   return type, consume `=>`, parse body.

4. Expression containing `it` in closure-expected position →
   implicit single-parameter closure (already spec'd).

**Disambiguation of `IDENT TK_FAT_ARROW` vs assignment:**

In expression position, `x => expr` is always a closure because
`=` alone is the assignment operator and `=>` is never valid in
an assignment context. The parser knows from context whether it's
parsing an expression (closure) or a statement (assignment).

**AST representation:**

Closures produce the same `NK_CLOSURE` AST node regardless of
syntax. The node stores: parameter list, body expression, optional
return type. The parser normalizes all three forms (it, single
`=>`, multi `=>`) into the same AST shape.

---

## Implementation Note: Match Arm Parser Changes

### Note

In `parse_match_arm` or equivalent, replace `TK_ARROW` (`->`)
with `TK_FAT_ARROW` (`=>`).

The match arm grammar changes from:

```
match_arm = pattern ['if' expr] '->' expr
```

to:

```
match_arm = pattern ['if' expr] '=>' expr
```

This is a one-line change in the parser: wherever the match arm
parser consumes `TK_ARROW`, change it to consume `TK_FAT_ARROW`.

`TK_ARROW` (`->`) remains in the grammar only for return type
annotations in function and closure signatures.

---

## Implementation Note: Remove Pipe Closure Syntax

### Note

Remove the `|param| body` and `|param, param| body` closure
parsing paths from the parser. The `|` token in expression
context should no longer trigger closure parsing.

Specifically:
- Remove the path where `TK_PIPE` is followed by identifiers
  and another `TK_PIPE` to form a closure parameter list.
- Keep `TK_PIPE` as the bitwise OR binary operator.
- Keep `|` in type declarations (`type X = A | B`).

**Self-host source migration:** Before removing old syntax from
the parser, update all source to use the new syntax. Verify
fixpoint after each migration step.

Order:
1. Add `=>` closure parsing and `=>` match arm parsing (new syntax works alongside old).
2. Migrate all `src/*.w` closures from `|x|` to `=>` or `it`.
3. Migrate all `src/*.w` match arms from `->` to `=>`.
4. Verify fixpoint.
5. Remove `|x|` closure parsing.
6. Remove `->` match arm parsing.
7. Verify fixpoint again.

This ensures the compiler can always compile itself at every step.

---

## Implementation Note: Migration Script

### Note

A mechanical find-and-replace can handle most cases:

Closures:
- `|x|` where x is a single identifier → `x =>`
  (or `it` if body is `x.field` or `x op value`)
- `|x, y|` → `(x, y) =>`
- `|x: Type|` → `(x: Type) =>`
- `||` at start of closure → `() =>`

Match arms:
- `pattern -> body` → `pattern => body`
  (inside `match` blocks only)

Review each replacement manually — `|` as bitwise OR and `->` in
return type annotations must not be caught by the migration.

---

## Reserved Syntax

`=>` is now a reserved token. Its meaning is "produces this value."
It appears in exactly two contexts: closure bodies and match arms.
No other meaning may be assigned to `=>`.

`->` is restricted to return type annotations only. It no longer
appears in match arms.