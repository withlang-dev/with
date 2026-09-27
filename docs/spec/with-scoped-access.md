# 7. `with` — Scoped Access

`with` is the language's central construct. It means: **access this
value within this scope.** It appears in five forms, all expressing
the same idea — bounded, explicit interaction with data.

| Form | Meaning | Appears in |
|------|---------|------------|
| `with as name:` | Guarded access (lock, arena, file) | Concurrent/resource code |
| `with value as mut name:` | Scoped mutation (builder pattern) | Initialization, configuration |
| `with expr as name:` | Scoped binding (named temporary) | Pipelines, intermediate values |
| `with name(expr):` | Scoped implicit context | Allocators, devices, loggers, ambient config |
| `{ expr with field: val }` | Record update (functional copy) | Data transformation |

### 7.1 Form 1: Guarded Access

When data lives behind a lock, arena, or resource guard, `with`
provides scoped access. The compiler ensures the binding cannot
escape the block — the guard is released when the block exits.

```
with lock.read() as data:
    data.iter() |> filter(x => x.active) |> count()

with db.connection() as conn:
    conn.query("SELECT * FROM users WHERE id = ?", user_id)

with world.entities[player_id] as mut player:
    player.health -= damage
    player.last_hit = now()
```

`with` is built-in compiler semantics. The binding is scoped to
the block — it cannot escape. The `as mut` variant creates a
mutable binding; without `mut`, the binding is read-only.

```
with lock.read() as data: body
// data is scoped to block, read-only

with store.write() as mut data: body
// data is scoped to block, mutable
```

Multiple bindings are flat, nesting left-to-right:
```
with a.read() as textures,
     b.read() as meshes,
     c.write() as mut materials:
    body
```

### 7.2 Form 2: Scoped Mutation (Builder Pattern)

When constructing a complex value, `with` provides a mutable scope
for staged initialization. The value is owned and mutable inside the
block, then returned as the block's result.

```
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3
    c.verbose = true

let request = with HttpRequest.new("GET", "/api/users") as mut r:
    r.header("Authorization", token)
    r.header("Accept", "application/json")
    r.timeout(Duration.seconds(30))

let sprite = with Sprite.new() as mut s:
    s.position = Vec2.new(100.0, 200.0)
    s.scale = Vec2.one()
    s.color = Color.white()
    s.layer = 5
```

**Return rule:** `with expr as mut x:` **always returns `x`** (the
builder), regardless of the type of the body's last expression. One
construct, one meaning — the block's result never silently changes
because a setter gained or lost a return value.

```
// Builder: always returns c
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3

// Methods that return values are fine — their results are
// discarded, and the block still returns c:
let config = with Config.default() as mut c:
    c.headers.insert("Auth", tok)   // returns Option[V], discarded
    c.timeout = 30

// To extract a computed value, bind the builder, then compute:
let v = with Vec.new() as mut v:
    v.push(1)
    v.push(2)
let len = v.len()
```

For a scoped computation whose result is something other than the
binding, use Form 3 (`with expr as name:`, §7.3), whose result is
the body value.

The value is bound as a mutable local inside the block.

**Desugaring:**
```
let config = with Config.default() as mut c:
    c.timeout = 30
// → let config = { var c = Config.default(); c.timeout = 30; c }
```

This replaces the need for builder types, method chaining, or
mutable-then-freeze patterns. The mutation is visually contained
within the `with` block — nothing outside it can observe the
intermediate mutable state.

### 7.3 Form 3: Scoped Binding

When an intermediate computation needs a name for a small scope
without polluting the enclosing namespace, `with` provides a
scoped binding.

```
let damage = with calculate_armor_reduction(attacker, defender) as reduction:
    base_damage * (1.0 - reduction) + bonus_damage

let label = with user.display_name.unwrap_or(user.username) as name:
    "{name} ({user.role})"

let normalized = with vec.len() as len:
    if len > 1e-6: vec.scale(1.0 / len) else: Vec2.zero()
```

When `mut` is absent, the value is bound as an immutable local.

**Desugaring:**
```
with expr as name: body
// → { let name = expr; body }
```

This is lightweight. It is equivalent to a `let` binding inside an
anonymous block, but reads more naturally in expression chains and
avoids name leakage.

### 7.3a Form 3a: Implicit Context

`with name(expr):` introduces an **implicit context binding**. Any
function parameter declared with the `implicit` modifier may be
filled from the innermost matching implicit context in scope.

```
fn sin(x: &Array, ctx: implicit &Context) -> Array: ...

with context(default_device()):
    let y = sin(x)                // ctx resolved implicitly
    let z = a @ b                 // implicit context applies here too
    let w = sin(x, ctx: other)    // explicit argument overrides implicit
```

Implicit resolution is **lexical and type-based**:

- Positional arguments are matched first.
- Named arguments are matched second.
- Unfilled `implicit` parameters are searched from the innermost
  enclosing `with name(expr):` block outward.
- Remaining omitted parameters may then be filled from defaults.

Additional rules:

- Auto-ref applies during implicit lookup, so `Context` and `&Context`
  compose naturally with existing call ergonomics.
- A function may not declare two `implicit` parameters of the same
  type.
- An `implicit` parameter may not also have a default value.
- Inner implicit contexts shadow outer contexts of the same type.
- Closures capture the implicit contexts visible at their definition
  site, just like ordinary lexical bindings.

The identifier in `with name(expr):` is descriptive. Resolution is
driven by type, not by the identifier text.

`std.context` defines the standard context shape for common execution
services. `Context` is ephemeral and currently carries a temporary
arena, logger, cancellation token, and trace id. Library APIs that need
these cross-cutting services should accept an `implicit Context`
parameter instead of adding unrelated positional parameters.

```
use std.context

fn trace_id(ctx: implicit Context) -> i64:
    ctx.trace_id.value

with active(default_context()):
    let id = trace_id()
```

### 7.4 Form 4: Record Update

Functional immutable update of struct fields. Defined in §4.3 and
included here for completeness.

```
let moved = { entity with position: new_pos }
let damaged = { player with health: player.health - 10 }
let config = { defaults with verbose: true, retries: 5 }
```

For `Copy` types, all fields are copied. For non-`Copy` types,
non-overridden fields are moved from the source (the source is
consumed).

### 7.5 Dispatch Rule

Full `with` dispatch is syntax-first, type/protocol-driven, and
`mut`-refined.

1. The parser first distinguishes the syntactic shape:
   `with e`, `with e as x`, `with e as mut x`,
   `with name(expr):`, and record-update forms.
2. For forms that can be either guarded access or plain binding,
   the expression's type and protocols decide the path. If the
   expression implements a guarded-access protocol such as `Scoped[T]`
   or `ScopedMut[T]`, the form is guarded. Otherwise it is a plain
   scoped binding.
3. `mut` refines mutability within the selected path. It is not the
   global dispatcher.

```
// Plain binding path
with expr as name:                 →  { let name = expr; body }
with expr as mut name:             →  { var name = expr; body; name }
```

In the guarded path, the guard protocol supplies acquire/release
behavior and the payload type. `mut` requests mutable access to the
guarded value and must be supported by a mutable guard capability. For
example, `with lock.read() as mut data:` is invalid if `lock.read()`
produces only an immutable guard; the keyword does not select a
different protocol.

```
// Guarded access — lock.write() returns a guard
with lock.write() as data:
    data.x = 1                         // guard released at block exit

// Builder — plain scoped mutation
let config = with Config.default() as mut c:
    c.retries = 3

// Implicit context
with context(default_context()):
    log("started")
```

### 7.6 `with` as Expression

All forms of `with` are expressions. Their value is the value of
the body.

```
// Guarded access — result must be non-ephemeral
let count = with store.read() as textures:
    textures.iter() |> count()

// Builder — result is the configured value (implicit return)
let config = with Config.default() as mut c:
    c.timeout = 30

// Scoped binding — result is computed from the named value
let area = with shape.bounding_box() as bb:
    bb.width * bb.height
```

For guarded access (Form 1), the result must be non-ephemeral
(it cannot be a reference into the guarded data, since the guard
releases at block exit).

### 7.7 Control Flow Inside `with` Blocks

All `with` forms are **transparent for control flow** (analogous to
inline lambdas or non-escaping closures):

- **`return`** inside a `with` block returns from the **enclosing
  function**, not from the desugared closure.
- **`break`** and **`continue`** inside a `with` block within a loop
  affect the **enclosing loop**.
- Labeled `break 'label` and `continue 'label` inside a `with`
  block may target any visible label in the enclosing function;
  `with` does not create a label-scope boundary.
- **`goto 'label`** inside a `with` block may target a visible label
  in the enclosing function, subject to the normal goto restrictions
  (§13.5b).
- **`?`** propagates errors to the **enclosing function**.

```
fn find_value(lock: &Mutex[HashMap[str, i32]], key: &str) -> Option[i32]:
    with lock.lock() as map:
        match map.get(key):
            // v is &i32; the declared Option[i32] return context materializes
            // an independent Copy value under §3.8/D22.
            Some(v) => return Some(v)   // returns from find_value
            None    => ()
    None

fn process_all(lock: &Mutex[Vec[Item]]) -> Result[Unit, AppError]:
    with lock.lock() as items:
        for item in items:
            if item.is_invalid():
                continue                 // continues enclosing for loop
            validate(item)?              // propagates to process_all
    // implicit Ok(())

fn process_until_done(lock: &Mutex[Vec[Item]]):
    'outer for i in 0..10:
        with lock.lock() as items:
            if items[i].is_terminal():
                break 'outer             // exits the labeled outer loop
```

This is possible because `with` blocks are always non-escaping and
synchronous — the compiler can inline the control flow transformation.
This is NOT a general property of closures; it applies only to `with`
blocks and other compiler-known non-escaping constructs.

*§7.8 `with` Frequency moved to `docs/spec/guide/with-frequency.md`.*

*§7.9 `with` Idioms and Rules moved to `docs/spec/guide/with-idioms-and-rules.md`.*
