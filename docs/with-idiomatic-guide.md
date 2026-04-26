# Idiomatic With

The principle: **if the compiler already knows it, don't type it.**

Every rule in this guide follows from that. With is designed so
that the shortest, cleanest version of the code is also the
correct version.

---

## Use Prelude Names Directly

The prelude is always in scope. Prefer unqualified names for common
types and traits:

```
let users: Vec[User] = Vec.new()
let name: String = "alice"

fn render[T](value: T):
    println(f"{value}")
```

No `use` is needed for `Vec`, `String`, `Option`, `Result`,
`Debug`/`Display`/`Default`, `Iter`/`IntoIter`, `Eq`/`Hash`/`Ord`,
or core print/assert helpers.

---

## Functions

**Drop the parens.** If a function takes no arguments, don't
write empty parentheses.

```
// ✗ verbose
fn greet():
    println("hello")

// ✓ idiomatic
fn greet:
    println("hello")
```

**Drop the return type when it's Unit.** If a function doesn't
return anything, don't annotate it.

```
// ✗ verbose
fn greet() -> Unit:
    println("hello")

// ✓ idiomatic
fn greet:
    println("hello")
```

**Drop the return type when the body makes it obvious.** The
compiler infers return types. If the body is a single expression
whose type is clear, the annotation is redundant.

```
// ✗ redundant — the struct literal already says Vec2
fn zero -> Vec2: Vec2 { x: 0.0, y: 0.0 }

// ✓ idiomatic
fn zero: Vec2 { x: 0.0, y: 0.0 }

// ✗ redundant — .North is clearly a Direction
fn default_dir -> Direction: .North

// ✓ idiomatic
fn default_dir: .North
```

**Do annotate when it helps the reader.** If the return type
isn't obvious from the body, keep the annotation.

```
// ✓ annotation helps — what does this compute?
fn solve(input: str) -> Solution:
    input |> parse |> optimize |> evaluate

// ✓ annotation helps — numeric expressions don't reveal the type
fn area(r: f64) -> f64: 3.14159 * r * r
```

**`fn main:` not `fn main -> i32:`.** A program that succeeds
shouldn't need to say so.

```
// ✗ C-brain
fn main -> i32:
    println("Hello, World!")
    0

// ✓ idiomatic
fn main:
    println("Hello, World!")
```

---

## Generic Bounds

**Omit bounds when the body already says what it needs.** Unbounded
generics are checked when they are instantiated with concrete types.
For local helpers and obvious one-liners, the shorter form is usually
the better one.

```
// ✓ idiomatic helper
fn double[T](x: T): x + x
```

When an unbounded generic is called with a type that doesn't support
the required operation, the compiler error names the concrete type
and the instantiation — so the caller can immediately see what went wrong.

**Keep bounds when the signature should carry the contract.** Public
APIs, library entry points, and longer generic functions often read
better when the requirement is explicit. Bounded generics produce
errors at the call site (before monomorphization), which is earlier
and more targeted.

```
// ✓ explicit contract
fn max[T: Ord](a: T, b: T):
    if a > b then a else b
```

**Use `where` when it improves readability, not because the language
requires it.** Inline bounds and `where` clauses are both optional.

```
fn compare[T](a: T, b: T) where T: Eq + Ord:
    if a == b then 0
    else if a < b then -1
    else 1
```

---

## Let the Compiler Infer Types

**Don't annotate what's obvious.** The compiler has
bidirectional type inference. Use it.

```
// ✗ over-annotated
let x: i32 = 42
let name: str = "Alice"
let items: Vec[i32] = Vec.new()
let found: bool = list.contains(x)

// ✓ idiomatic
let x = 42
let name = "Alice"
let items = Vec.new[i32]()
let found = list.contains(x)
```

**Do annotate when it helps the reader.** If the type isn't
obvious from the right-hand side, annotate it.

```
// ✓ annotation helps here — what does parse return?
let config: ServerConfig = parse(args)
```

---

## Use `const` for Compile-Time Constants

**Don't use `let` for values known at compile time.**

```
// ✗ runtime binding for a fixed value
let MAX_RETRIES = 3

// ✓ compile-time constant, inlined at every use
const MAX_RETRIES: i32 = 3
```

`const` requires a type annotation and a compile-time evaluable
expression. Use it for configuration values, sizes, sentinel values,
and any named value that never changes.

```
const BUFFER_SIZE: i32 = 4096
const DEFAULT_TIMEOUT: i64 = 30000
const VERSION: str = "1.0.0"
```

---

## Use `pub` for Published API Contracts

With names are reachable by default. `pub` is not access control; it is a
published-API marker. Use it when you want to promise that downstream With
code can depend on a declaration staying compatible.

```with
// ✓ published With-level API
pub fn parse(source: str) -> Ast:
    source |> tokenize |> build_ast

// ✓ reachable, but not a stability promise
fn parse_expr(tokens: Tokens) -> Expr:
    ...
```

Use `@[c_export]` for ABI/linkage contracts. That is a separate boundary:

```with
@[c_export("with_parse")]
fn parse_c(ptr: *u8, len: i64) -> i32:
    ...
```

The model:

- ordinary declarations are reachable but may be implementation details
- `pub` marks the supported With-level API
- `@[c_export]` exports an ABI symbol

---

## Mutability Belongs to the Binding

Do not write Rust-shaped `&mut` parameters or `&mut` call sites. If a value is
bound with `var`, functions may mutate it. If you want to protect the original,
pass a copy.

```with
var graph = Graph.new()
add_block(graph, "entry")      // may mutate graph

let snapshot = graph.copy()
add_block(snapshot, "other")   // mutate the copy
```

Function signatures describe values, not borrow modes:

```with
// ✗ Rust-brain
fn add_block(g: &mut Graph, name: str):
    ...
add_block(&mut graph, "entry")

// ✓ idiomatic With
fn add_block(g: Graph, name: str):
    ...
add_block(graph, "entry")
```

---

## Use `Option` / `Result`, Not Sentinel Values

Don't encode absence or failure as magic values like an empty string or `-1`
when the type can say what is happening.

```with
// ✗ sentinel string
fn validate(config: Config):
    if config.port <= 0 then return "bad port"
    ""

// ✓ explicit absence/presence
fn validate(config: Config):
    if config.port <= 0 then return Some("bad port")
    None
```

Use `Result` when the caller should propagate or handle an error:

```with
fn load_config(path: str) -> Result[Config, ConfigError]:
    let text = read_file(path)?
    parse_config(text)
```

---

## Don't Return What's Implied

**Don't write trailing `0`.** If a function returns a type
that implements `Default` and the last expression is a
statement, the compiler returns `T.default()`.

```
// ✗ boilerplate
fn setup_logging -> i32:
    init_logger()
    set_level("debug")
    0

// ✓ idiomatic — i32.default() is 0
fn setup_logging -> i32:
    init_logger()
    set_level("debug")
```

**Don't write `Ok(())`.** If a function returns `Result[Unit, E]`
and the body ends with a statement, the compiler wraps it.

```
// ✗ ceremony
fn save_all(items: &Vec[Item]) -> Result[Unit, DbError]:
    for item in items:
        db.insert(item)?
    Ok(())

// ✓ idiomatic — implicit Ok(())
fn save_all(items: &Vec[Item]) -> Result[Unit, DbError]:
    for item in items:
        db.insert(item)?
```

**Don't write `Ok(value)`.** The happy path just returns the
value. The compiler wraps it.

```
// ✗ wrapping manually
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    Ok(User.from_row(row))

// ✓ idiomatic — auto-wrapped in Ok
fn get_user(id: i32) -> Result[User, DbError]:
    let row = db.query("SELECT ...", id)?
    User.from_row(row)
```

**The rule:** `?` handles the sad path. The happy path just
returns the value.

**Don't add defensive tail returns just to satisfy control-flow.**
If some branches `return` and a fallthrough path is not provably
returning the declared type, the compiler inserts an implicit
`unreachable` panic at function exit (with file/line). Write
`unreachable()` explicitly only when it improves readability.

---

## Use Enum Variant Shorthand

When the type is known from context, use `.Variant` instead
of the full `TypeName.Variant`.

```
// ✗ verbose
fn color_name(c: Color) -> str:
    match c
        Color.Red   => "red"
        Color.Green => "green"
        Color.Blue  => "blue"

// ✓ idiomatic
fn color_name(c: Color) -> str:
    match c
        .Red   => "red"
        .Green => "green"
        .Blue  => "blue"
```

Works everywhere the compiler can infer the enum type: match
arms, return positions, function arguments, let bindings with
type annotations.

```
// ✓ in return position
fn default_dir -> Direction: .North

// ✓ in function arguments
move_player(.North, 10.0)

// ✓ in error returns
if age < 0 then return Err(.InvalidAge)
```

**Use discriminant enums for protocol/wire values.** When enum values
must map to specific integers (protocol codes, file formats, FFI):

```
// ✓ discriminant enum — explicit integer mapping
enum HttpMethod:
    Get = 1
    Post = 2
    Put = 3
    Delete = 4

// ✓ @[flags] for bitfield enums
@[flags]
enum Perms:
    Read         // 1
    Write        // 2
    Execute      // 4

let rw = Perms.Read as i32 | Perms.Write as i32
```

---

## Use Field Shorthand

When variable names match field names, don't repeat yourself.

```
// ✗ repetitive
let user = User { name: name, email: email, active: active }

// ✓ idiomatic
let user = User { name, email, active }
```

Works in struct literals, patterns, and destructuring.

---

## Use Default Fields

Struct fields with defaults can be omitted at construction.

```
type ServerConfig:
    host: str = "localhost"
    port: i32 = 8080
    max_connections: i32 = 100

// ✗ specifying defaults
let config = ServerConfig {
    host: "localhost",
    port: 8080,
    max_connections: 200,
}

// ✓ idiomatic — only specify what differs
let config = ServerConfig { max_connections: 200 }
```

---

## Use `then` for Guards

Single-expression conditionals use `then` for inline guards.
Don't inflate them into blocks.

```
// ✗ heavy
if not valid:
    return Err(.Invalid)

// ✓ idiomatic
if not valid then return Err(.Invalid)
```

This reads like English: "if not valid, then return error."

---

## Use `?` and `??`, Not Manual Matching

**`?` for propagation.** Don't manually match on Option/Result
when you just want to propagate the error.

```
// ✗ manual propagation
let user = match db.find_user(id)
    Ok(u)  => u
    Err(e) => return Err(e)

// ✓ idiomatic
let user = db.find_user(id)?
```

**`??` for defaults.** Don't match when you just want a
fallback.

```
// ✗ manual default
let name = match user.nickname
    Some(n) => n
    None    => "anonymous"

// ✓ idiomatic
let name = user.nickname ?? "anonymous"
```

**`?.` for optional chaining.** Navigate nested Options
without unwrapping each layer.

```
// ✗ nested matching
let city = match user.address
    Some(addr) => match addr.city
        Some(c) => Some(c)
        None    => None
    None => None

// ✓ idiomatic
let city = user.address?.city
```

---

## Use `let ... else` for Early Exit

When you need to unwrap or bail, `let ... else` reads cleanly.

```
// ✗ nested
match parse_config(path)
    Ok(config) =>
        // rest of function indented
    Err(e) =>
        return Err(e)

// ✓ idiomatic — flat
let Ok(config) = parse_config(path) else return Err(.ParseError)
// rest of function at top level
```

Works with enum patterns:

```
let .Connected(socket) = state else return Err(.NotConnected)
let Some(user) = find_user(id) else return Err(.NotFound)
```

---

## Use Pipelines for Data Transformation

When data flows through a sequence of steps, use `|>` instead
of nested calls.

```
// ✗ nested — read inside-out
let result = summarize(transform(validate(parse(data))))

// ✓ idiomatic — read left-to-right
let result = data |> parse |> validate |> transform |> summarize
```

Pipelines compose with `?`:

```
let result = data
    |> parse?
    |> validate?
    |> transform
    |> summarize
```

**Use method chains for objects, pipelines for free functions.**

```
// ✓ methods — the value is the subject
let names = users.iter()
    .filter(u => u.active)
    .map(u => u.name)
    .collect[Vec]()

// ✓ pipeline — data flows through transformations
let report = raw_data
    |> parse_csv
    |> normalize
    |> aggregate_by_month
    |> render_chart
```

Collection pipelines support implicit `.iter()`: `Vec`, arrays, slices,
`HashMap`, and `HashSet` can flow directly into `map`/`filter`/`count`
without calling `.iter()` explicitly.

---

## Use `with` for Scoped Operations

### Builders

Don't write mutable-then-freeze manually. Use `with ... as mut`.

```
// ✗ manual builder pattern
var config = Config.default()
config.timeout = 30
config.retries = 3
config.verbose = true
let config = config   // freeze

// ✓ idiomatic — mutation is scoped
let config = with Config.default() as mut c:
    c.timeout = 30
    c.retries = 3
    c.verbose = true
```

### Guarded access

Don't manually lock and unlock. `with` scopes it.

```
// ✗ manual lock management
let guard = lock.read()
let count = guard.data.len()
drop(guard)

// ✓ idiomatic — the type tells the compiler it's a guard
with lock.read() as data:
    data.len()
```

### Record update

Don't clone and mutate. Use `{ expr with field: val }`.

```
// ✗ clone and mutate
var new_config = config.clone()
new_config.timeout = 60

// ✓ idiomatic — functional update
let new_config = { config with timeout: 60 }
```

---

## Use `defer` for Cleanup

Don't write cleanup at every exit point. `defer` runs at scope
exit regardless of how you leave.

```
// ✗ fragile — cleanup at every return
fn process(path: str) -> Result[Unit, IoError]:
    let f = File.open(path)?
    if not f.is_valid():
        f.close()
        return Err(.Invalid)
    let data = f.read_all()?
    f.close()

// ✓ idiomatic — one defer, always runs
fn process(path: str) -> Result[Unit, IoError]:
    let f = File.open(path)?
    defer f.close()
    if not f.is_valid() then return Err(.Invalid)
    let data = f.read_all()?
```

**Use `errdefer` for error-only cleanup.** When you need cleanup that
should only run on error (not on success), use `errdefer`:

```
fn connect(url: str) -> Result[Connection, Error]:
    let conn = open_socket(url)?
    errdefer conn.close()         // only runs if a later ? fails
    let auth = authenticate(conn)?
    Connection { conn, auth }     // success: errdefer skipped
```

---

## Pattern Matching

**Use `match`, not chains of `if/else if`.** For value-producing
matches, keep arms exhaustive. For statement-only dispatch,
partial matches are valid when ignored variants should no-op.

```
// ✗ if-chains on enums
if status == .Ok:
    handle_success()
else if status == .NotFound:
    handle_404()
else if status == .ServerError:
    handle_500()

// ✓ idiomatic — expression-position match is exhaustive
match status
    .Ok          => handle_success()
    .NotFound    => handle_404()
    .ServerError => handle_500()

// ✓ statement-position partial match
match event
    .Click(pos) => on_click(pos)
    .KeyDown(k) => on_key(k)
```

**Destructure in the pattern.** Don't match then access.

```
// ✗ match then access
match result
    Ok(val) => println(f"{val.name}: {val.score}")
    Err(e)  => println(f"error: {e}")

// ✓ idiomatic — destructure deeper if it helps
match result
    Ok({ name, score }) => println(f"{name}: {score}")
    Err(e)              => println(f"error: {e}")
```

---

## String Interpolation

Don't concatenate. Interpolate.

```
// ✗ concatenation
let msg = "Hello, " ++ name ++ "! You have " ++ count.to_str() ++ " items."

// ✓ idiomatic — f-strings interpolate {expressions}
let msg = f"Hello, {name}! You have {count} items."
```

---

## Ranges and Loops

**Use ranges.** Don't write C-style index manipulation.

```
// ✗ C-style
var i = 0
while i < 10:
    process(i)
    i += 1

// ✓ idiomatic
for i in 0..10:
    process(i)
```

**Use iterators.** Don't index when you can iterate.

```
// ✗ indexing
for i in 0..items.len():
    process(items[i])

// ✓ idiomatic
for item in items:
    process(item)
```

**Use comprehensions for transforms.**

```
// ✗ manual accumulation
var result = Vec.new[i32]()
for x in 0..10:
    result.push(x * x)

// ✓ idiomatic
let result = [x * x for x in 0..10]
```

---

## Closures

**Minimize syntax.** Closures are already short. Keep them that
way.

```
// ✗ over-specified
items.filter((item: &Item) => item.active == true)

// ✓ idiomatic — types inferred, expression body
items.filter(item => item.active)

// ✓ best — use `it` for single-parameter closures
items.filter(it.active)
items.map(it.name)
items.filter(it > 0)
```

**Use `it` for simple closures.** When a function expects a
single-parameter closure, `it` refers to the implicit parameter.
Reserve explicit `param => body` for multi-parameter closures or when
the body is complex:

```
// ✓ use it for short, clear expressions
numbers |> filter(it > 0) |> map(it * 2)

// ✓ use explicit params for multi-param or clarity
pairs.sort_by((a, b) => a.score - b.score)
```

---

## The Colon Rule

`:` introduces a block everywhere in With — `fn`, `if`, `for`,
`while`, `match`, `trait`, `impl`, `extend`. One rule:

- **One expression/statement after the colon = one line.**
- **Multiple = indent block.**

No special cases.

```
// ✓ one-line bodies
fn double(x: i32) -> i32: x * 2
if not valid then return Err(.Invalid)

// ✓ one-line traits and impls
trait Add[Rhs, Output]: fn add(self: Self, rhs: Rhs) -> Output
trait Sub[Rhs, Output]: fn sub(self: Self, rhs: Rhs) -> Output
impl Show for Point: fn show(self: &Point) -> String: f"({self.x}, {self.y})"

// ✓ multi-line when it doesn't fit
trait DataSource:
    async fn fetch(self: &Self, id: i32) -> Result[Data, Error]
    async fn batch(self: &Self, ids: &Vec[i32]) -> Result[Vec[Data], Error]

extend Vec[T]:
    fn is_empty(self: &Vec[T]) -> bool: self.len() == 0
    fn first(self: &Vec[T]) -> Option[&T]: if self.is_empty() then None else Some(&self[0])
```

```
// ✗ artificially multi-line
trait Neg[Output]:
    fn neg(self: Self) -> Output

// ✓ fits on one line — keep it there
trait Neg[Output]: fn neg(self: Self) -> Output
```

### Choose One Block Style Per Codebase

With supports both colon blocks and brace blocks on block-bearing constructs.
Prefer one house style within a codebase — usually colon blocks for multi-line
code.

```with
// ✓ default multi-line style
type Point:
    x: i32
    y: i32

fn render(point: Point):
    println(f"{point.x}, {point.y}")
```

Use braces when they improve locality, especially for short one-liners or
expression-level literals:

```with
type Point { x: i32, y: i32 }
let origin = Point { x: 0, y: 0 }
```

Avoid mixing colon and brace declaration styles for similar neighboring
constructs unless there is a concrete ergonomic reason.

---

## Use Handles, Not Pointers

For data-oriented relationships, use `Handle[T]` with `SlotMap`
instead of pointers or reference-counted objects. Handles are
`Copy`, type-safe, and detect use-after-remove via generation
mismatch.

```
// ✗ pointer-based — fragile, cache-unfriendly
type Entity:
    parent: *Entity
    children: Vec[*Entity]

// ✓ idiomatic — handle-based, data-oriented
type Entity = Handle[EntityRow]

type World:
    entities: SlotMap[EntityRow]
    transforms: DenseStorage[Transform]
    sprites: DenseStorage[Sprite]

// Handles are Copy — store them freely
let player = world.spawn("player")
let enemies = vec![world.spawn("e1"), world.spawn("e2")]

// Safe access — None if entity was despawned
if let Some(tf) = world.transforms.get(player):
    println(f"pos: {tf.position}")
```

Handles compose naturally with the ECS pattern:

```
// Query all entities with both Transform and Sprite
for (entity, tf, sprite) in query2(&world.transforms, &world.sprites):
    draw(tf.position, sprite.texture)
```

---

## Use `traverse` for Bulk Fallible Operations

When applying a fallible function to a collection, use
`traverse` instead of a manual loop with error handling.
Use `sequence` when you already have `Vec[Result[T, E]]`.

```
// ✗ manual loop with error handling
var results = Vec.new[i32]()
for s in strings:
    match s.parse_int()
        Ok(n)  => results.push(n)
        Err(e) => return Err(e)

// ✓ idiomatic — traverse = map + collect-or-fail
let results = strings.traverse(s => s.parse_int())?
```

`sequence` converts `Vec[Result[T, E]]` to `Result[Vec[T], E]`:

```
// ✗ manual unwrapping
var users = Vec.new[User]()
for result in fetch_results:
    users.push(result?)

// ✓ idiomatic — sequence
let users = fetch_results.sequence()?
```

Both short-circuit on the first error.

---

## Use `async scope` for Concurrency

Structured concurrency with `async scope` guarantees all
spawned tasks complete before the scope exits. No lifetime
annotations needed — the compiler knows borrows can't outlive
the scope.

```
// ✗ manual task management — tasks can leak
let t1 = spawn(fetch_user(1))
let t2 = spawn(fetch_user(2))
let r1 = t1.await
let r2 = t2.await

// ✓ idiomatic — structured concurrency
async scope s =>
    let t1 = s.track(fetch_user(1))
    let t2 = s.track(fetch_user(2))
    let (r1, r2) = (t1.await, t2.await)
// All tasks guaranteed complete here.
```

Scatter-gather pattern:

```
// Fire off N parallel fetches, collect results
let profiles = async scope s =>
    ids |> map(id => s.track(get_profile(id)))
        |> collect[Vec]()
        |> map(task => task.await)
        |> collect[Vec]()
```

Scoped borrows — tasks can borrow local data without lifetimes:

```
async fn process_all(data: &mut Vec[i32]):
    async scope s =>
        s.track(transform(&data[0..100]))
        s.track(transform(&data[100..200]))
    // Borrows released, data is accessible again.
```

## Concurrent Await

Use tuple `.await` for a small fixed set of independent async
operations. Avoid serial `.await` chains when there is no dependency.

```
// ✗ sequential
let user = fetch_user(id).await
let posts = fetch_posts(id).await

// ✓ concurrent
let (user, posts) = (fetch_user(id), fetch_posts(id)).await
```

Use collection combinators for larger homogeneous sets:

```
let users = ids |> map(fetch_user) |> await_all
```

Use `spawn` for detached fire-and-forget work; never `let _ =` on
an async call result because dropping a `Task` cancels it.

```
// ✓ detached
spawn send_analytics(event)
```

Prefer `async scope` when you need tracked cancellation behavior or
dynamic task sets. For simple fixed arity fan-out/fan-in, tuple
`.await` is usually the clearest form.

---

## Use `in` for Membership Tests

The `in` operator tests containment on any collection or
literal array. Don't write chains of `==` or verbose `match`
for set membership.

```
// ✗ verbose equality chain
if kind == .Plus or kind == .Minus or kind == .Star or kind == .Slash:
    handle_operator()

// ✓ idiomatic
if kind in [.Plus, .Minus, .Star, .Slash]:
    handle_operator()
```

Works in match arms:

```
match token
    in [.Red, .Green, .Blue] => "color"
    in [.Bold, .Italic]      => "style"
    _                         => "other"
```

`not in` reads naturally:

```
if user.role not in [.Admin, .Moderator] then
    return Err(.Forbidden)
```

---

## Use Chained `if let` to Avoid Nesting

Multiple `if let` bindings can be chained with commas.
All patterns must match for the body to execute.

```
// ✗ pyramid of doom
if let Some(a) = store_a.get(entity):
    if let Some(b) = store_b.get(entity):
        if let Some(c) = store_c.get(entity):
            yield (entity, a, b, c)

// ✓ idiomatic — flat
if let Some(a) = store_a.get(entity),
   let Some(b) = store_b.get(entity),
   let Some(c) = store_c.get(entity):
    yield (entity, a, b, c)
```

Especially useful for extracting nested optional data:

```
if let Some(user) = find_user(id),
   let Some(addr) = user.address,
   let Some(city) = addr.city:
    println(f"User lives in {city}")
else:
    println("Address unknown")
```

---

## Use `let ... else` to Test Expected Variants

When you expect a specific variant and want to bail otherwise,
`let ... else` is cleaner than a full `match`.

```
// ✗ verbose match for a single expected variant
let value = match token
    .TString(s) => s
    _ => return Err(.UnexpectedToken)

// ✓ idiomatic — assert the pattern, bail in else
let .TString(value) = token else return Err(.UnexpectedToken)
```

Pairs well with `?` for multi-step unwrapping:

```
let Some(user) = find_user(id) else return Err(.NotFound)
let Ok(config) = parse_config(path) else return Err(.ParseError)
let [first, ..rest] = items else return Err(.Empty)
```

Inside `select` branches:

```
select await
    opt = rx.recv() =>
        let Some(item) = opt else break
        items.push(item)
    _ = timeout(Duration.from_secs(5)) =>
        break
```

---

## Use `comptime if` for Metaprogramming

`comptime if` selects code at compile time. Dead branches
are erased entirely — no runtime cost, no dead code warnings.

```
// ✓ specialize based on type capabilities
fn serialize[T](val: &T, out: &mut Writer):
    comptime if T.is_copy():
        out.write_bytes(val as *const u8, T.size())
    else if T.implements(Serialize):
        val.serialize(out)
```

Platform-specific code:

```
comptime if cfg.target_os == "linux":
    use c_import("fcntl.h", link: "c")
comptime else if cfg.target_os == "windows":
    use c_import("windows.h")
```

Debug-only instrumentation:

```
fn process(x: i32) -> i32:
    comptime if cfg.is_debug:
        println(f"debug: processing {x}")
    x * x + 1
```

---

## Use `c_import` for C Interop

`c_import` reads a C header at compile time and makes all
declarations available as With symbols. No manual `extern fn`
declarations needed.

```
// ✗ manual FFI declarations
extern "C":
    fn sqlite3_open(filename: *const u8, db: *mut *mut sqlite3) -> i32
    fn sqlite3_close(db: *mut sqlite3) -> i32
    fn sqlite3_exec(db: *mut sqlite3, sql: *const u8, ...) -> i32

// ✓ idiomatic — import the header, link the library
use c_import("sqlite3.h", link: "sqlite3")
```

Use `c"..."` string literals for NUL-terminated C strings:

```
// c"hello" is a &CStr — static, NUL-terminated
printf(c"hello %d\n".ptr, 42)
```

Wrap C resources with `impl Drop` for safe cleanup:

```
type Database = { handle: *mut sqlite3, path: str }

impl Drop for Database:
    fn drop(self: Self):
        if self.handle != null:
            unsafe { sqlite3_close(self.handle) }

extend Database:
    fn open(path: str) -> Result[Database, SqliteError]:
        var handle: *mut sqlite3 = null
        let rc = unsafe { sqlite3_open(path.as_ptr(), &mut handle) }
        if rc != SQLITE_OK then
            return Err(.OpenFailed(path, code: rc))
        Database { handle, path }
```

---

## Implement Prelude Traits

Prelude traits (`Eq`, `Ord`, `Debug`, `Display`, `Default`, `Drop`) are
always in scope — no `use` needed to implement them:

```
type Point { x: i32, y: i32 }

impl Eq for Point:
    fn eq(self: Point, other: Point):
        self.x == other.x and self.y == other.y

impl Default for Point:
    fn default: Point { x: 0, y: 0 }
```

Primitive types have prelude-provided impls for `Eq` and `Default`:

```
let a: i32 = 42
assert(a.eq(42))           // instance method
let zero = i32.default()   // static method
```

---

## Naming

With follows Rust's naming conventions:

| Kind | Convention | Example |
|------|-----------|---------|
| Functions, methods, variables | `snake_case` | `get_user`, `is_valid` |
| Types, traits, enums | `PascalCase` | `ServerConfig`, `Display` |
| Enum variants | `PascalCase` | `Option.Some`, `Color.Red` |
| Constants | `SCREAMING_SNAKE` | `MAX_RETRIES` |
| Modules, files | `snake_case` | `string_map.w` |

`with fmt` enforces these.

---

## Additional Language Rules

### Prefer Contextual Inference Over Numeric Suffixes

The compiler infers literal types from context (bindings, parameters,
binary peers, return types). Use suffixes only when context is absent:

```
// ✓ idiomatic — type inferred from binding
let x: u32 = 0xFF

// ✓ idiomatic — type inferred from parameter
fn process(val: u8):
    ()
process(42)

// ✓ suffix needed — no context to infer from
let raw = 0xFFu32

// ✗ over-specified — context already says u8
let b: u8 = 0x00u8
```

Available suffixes: `u8`, `u16`, `u32`, `u64`, `i32`, `i64`, `f32`, `f64`.

### Use Numeric Separators for Readability

Prefer grouped numeric literals:

```
let users = 1_000_000
let color = 0xFF_AA_22
let mask = 0b1111_0000
let pi = 3.141_592_653
```

### Use Trailing Commas in Multi-line Lists

Trailing commas are optional, but preferred in multi-line forms because they reduce diff noise:

```
let cfg = ServerConfig {
    host: "localhost",
    port: 8080,
    max_connections: 200,
}
```

### Choose the Right String Form

- Use normal strings for escaped/interpolated text.
- Use raw strings for regex/path/JSON fragments where escapes should stay literal.
- Use triple-quoted strings for readable multi-line literals.

```
let path = r"C:\Users\eric\logs"
let json = r#"{"name":"with","ok":true}"#
let sql = """
    SELECT id, name
    FROM users
    WHERE active = true
    """
```

### Use `b'X'` for Byte-oriented Code

Use byte literals when working with protocol/data bytes:

```
let esc = b'\x1B'
let newline = b'\n'
```

### Use `_` for Unused Bindings, Not Ignored Calls

If a binding or pattern slot is intentionally unused, write `_`:

```
let (_, value) = pair
```

Do not write `let _ =` just to call a function for its side effects. A call
statement may ignore its result naturally:

```
// ✗ defensive noise
let _ = cache.delete(key)

// ✓ idiomatic
cache.delete(key)
```

### No Shadowing: Prefer Pipelines

Do not rebind the same name for sequential transforms.

```
// ✗ shadowing style
let input = read_file(path)?
let input = input.trim()
let input = parse_json(input)?

// ✓ pipeline style
let input = read_file(path)? |> trim |> parse_json?
```

### `todo` and `unreachable`

Use `todo()` for intentional not-yet-implemented branches and `unreachable()` for logically impossible branches. Keep them short-lived and remove them before release code.

### `assert` vs `require` vs `check`

With has three assertion builtins. Each communicates a different
intent about **who is at fault** when the condition fails:

- **`assert(cond)`** — for tests and debugging. "This must be
  true; if not, something is deeply wrong." Panics unconditionally.
- **`require(cond)`** — for validating caller input. "The caller
  violated this function's contract." Raises
  `IllegalArgumentError`.
- **`check(cond)`** — for internal invariants. "My own state is
  wrong — I have a bug." Raises `IllegalStateError`.

```
fn withdraw(account: &mut Account, amount: i64):
    // require: caller must satisfy the contract
    require(amount > 0)
    require(amount <= account.balance)

    // check: internal invariant — balance should never go negative
    account.balance -= amount
    check(account.balance >= 0)

fn test_withdraw:
    var acct = Account { balance: 100 }
    withdraw(&mut acct, 50)

    // assert: test expectation
    assert(acct.balance == 50)
```

**When to use which:**

| Situation | Use |
|-----------|-----|
| Test assertions ("did I get the right answer?") | `assert` |
| Preconditions on public API arguments | `require` |
| Postconditions / class invariants | `check` |
| Should-never-happen branches | `unreachable` |

All three accept an `Option[str]` message as a second argument
when one is available (e.g. `require(x > 0, "x must be positive")`).

---

## Summary: The Idiomatic Checklist

Before submitting code, check:

1. **No unnecessary parens** — `fn greet:` not `fn greet():`
2. **No unnecessary return types** — `fn zero: Vec2 { x: 0.0, y: 0.0 }` not `fn zero -> Vec2: ...`
3. **No unnecessary type annotations** — `let x = 42` not `let x: i32 = 42`
4. **No `Ok(value)`** — just return the value
5. **No `Ok(())`** — just end the function
6. **No trailing `0`** — implicit default return handles it
7. **No manual unwrap chains** — use `?`, `??`, `?.`
8. **No verbose enum paths** — `.Variant` not `Type.Variant` when inferrable
9. **No field repetition** — `User { name, email }` not `User { name: name, email: email }`
10. **No mutable-then-freeze** — use `with ... as mut`
11. **No nested function calls** — use `|>` for pipelines
12. **No manual lock/guard management** — use `with`
13. **No string concatenation** — use f-string interpolation `f"hello {name}"`
14. **No C-style loops** — use ranges and iterators
15. **No `if/else if` chains on enums** — use `match`
16. **No manual cleanup at every exit** — use `defer`
17. **No `== true` or `== false`** — just `if active` or `if not active`
18. **No artificial newlines** — if a trait/impl/fn fits on one line, keep it there
19. **No pointer-based relationships** — use `Handle[T]` with `SlotMap`
20. **No manual error-collecting loops** — use `traverse` / `sequence`
21. **No unstructured task spawning** — use `async scope` with `s.track()`
22. **No equality chains for membership** — use `in` / `not in`
23. **No nested `if let` pyramids** — chain with commas
24. **No full `match` for single variant tests** — use `let ... else`
25. **No runtime checks for compile-time facts** — use `comptime if`
26. **No manual `extern fn` declarations** — use `c_import` with `c"..."` strings
27. **No generic `assert` for contract violations** — use `require` for caller errors, `check` for internal invariants
