# Blocks in With: One Shape, Two Spellings

With has a small syntactic trick that pays off everywhere:

> A block is a block, whether it belongs to a function, a type, an enum,
> a match, a loop, a trait, or a scoped `with`.

Most languages make these feel like separate constructs. Structs have one
shape, enums another, functions another, match arms another. With tries to
make the surface area smaller. Once you understand how a block starts and
ends, the rule carries through the language.

There are two spellings:

```with
fn greet:
    print("hello")
```

and:

```with
fn greet {
    print("hello")
}
```

The first is colon form. The second is brace form. They mean the same thing.

---

## The Colon Form

Colon form is the style you normally write by hand.

For a single short body, put it on the same line:

```with
fn double(x: i32) -> i32: x * 2
fn is_empty(xs: &Vec[i32]) -> bool: xs.len() == 0
```

For more than one statement, put the body on the next line and indent it:

```with
fn describe(score: i32) -> str:
    if score >= 90:
        "excellent"
    else if score >= 70:
        "solid"
    else:
        "needs work"
```

That rule is intentionally boring:

- Same line after `:` means one inline body.
- Newline after `:` means an indented body.
- Mixing same-line content and an indented continuation is an error.
- A colon with no body is an error.

No hidden terminators. No "sometimes braces, sometimes not." Just a header
and a body.

---

## The Brace Form

Brace form is the same block with explicit delimiters:

```with
fn describe(score: i32) -> str {
    if score >= 90 {
        "excellent"
    } else if score >= 70 {
        "solid"
    } else {
        "needs work"
    }
}
```

Inside braces, whitespace does not define the block boundary. Newlines and
semicolons both separate statements:

```with
fn main { let x = 1; let y = 2; print(x + y) }
```

That makes brace form useful for generated code, formatter output tests,
and compiler-produced code where indentation sensitivity is more burden
than benefit.

The formatter understands both spellings:

- `with fmt` preserves the spelling already used.
- `with fmt --prefer-colon` rewrites brace bodies to colon bodies where it
  can do so cleanly.
- `with fmt --prefer-brace` rewrites colon bodies to brace bodies.

The conversion is meant to be lossless because the two forms are the same
block model.

---

## Declaration Blocks

The same block rule starts declarations.

Types can use colon form:

```with
type Request:
    method: str
    path: str
    body: Vec[u8]
```

or brace form:

```with
type Request { method: str, path: str, body: Vec[u8] }
```

Enums can also use either spelling:

```with
enum Route:
    Home
    User(id: UserId)
    NotFound
```

```with
enum Route { Home | User(id: UserId) | NotFound }
```

Block enum variants are separated by newlines. Inline enum variants use
`|`, because the whole enum is being written as a compact algebraic data
type. A leading `|` is also allowed in block form when that reads better:

```with
enum Route:
    | Home
    | User(id: UserId)
    | NotFound
```

Discriminant enums show why the parser keeps the idea precise:

```with
enum Status: i32:
    Ok = 0
    Missing = 404
    Failed = 500
```

The first colon belongs to the enum representation type, `i32`. The second
colon starts the block. It looks compact, but the roles are different.

Traits and implementation blocks follow the same shape:

```with
trait Drawable:
    fn draw(self: &Self)

impl Drawable for Sprite:
    fn draw(self: &Sprite):
        renderer.draw_sprite(self)

extend Sprite:
    fn is_visible(self: &Sprite) -> bool:
        self.alpha > 0.0
```

These are not special islands of syntax. They are declarations with block
bodies.

---

## Control-Flow Blocks

Conditionals and loops use the same spelling:

```with
if user.active:
    send_email(user)
else:
    archive(user)

for item in items:
    process(item)

while queue.has_items():
    drain_one(queue)
```

The brace versions are equivalent:

```with
if user.active { send_email(user) } else { archive(user) }
for item in items { process(item) }
while queue.has_items() { drain_one(queue) }
```

Inline `if` is the one separate expression form:

```with
let label = if user.active then "active" else "archived"
```

That uses `then`, not a colon. It exists for short expressions. Once an
`if` has a real body, it goes back to the normal block rule.

---

## Match Blocks

`match` is where the two spellings matter most for readability.

Block form uses a colon after the subject and newlines between arms:

```with
fn area(shape: Shape) -> f64:
    match shape:
        .Circle(r) => pi * r * r
        .Rectangle(w, h) => w * h
        .Triangle(a, b, c) => herons_formula(a, b, c)
```

Inline form uses braces and commas:

```with
let name = match status { .Ok => "ok", .Missing => "missing", _ => "failed" }
```

Semicolons are not match arm separators. In block form, arms are separated
by newlines. In inline form, arms are separated by commas.

That distinction keeps dense expression matches readable without making
large structural matches look like a comma-management exercise.

---

## Scoped Blocks

Some blocks do more than group statements. They introduce a scope with
meaning.

`with` gives a value a scoped name, mutable builder slot, guard, or implicit
context:

```with
let config = with Config.default() as mut c:
    c.host = "localhost"
    c.port = 8080
```

The body is still just a block. The special part is what happens at the
boundary: the temporary name exists only inside, and guarded resources are
released when the block exits.

`comptime` and `async:` blocks use the same visual shape:

```with
comptime:
    generate_accessors(User)

let task = async:
    fetch_profile(id).await
```

The block syntax does not carry the whole meaning. `async:` starts a fiber.
`comptime:` runs during compilation. `with` chooses a scoped access form
from the type. But the way the body is written stays consistent.

---

## Braces Are Not Always Block Bodies

Curly braces also appear in data syntax:

```with
let p = Point { x: 1.0, y: 2.0 }
let moved = { entity with position: new_pos }
```

Those are not ordinary block bodies. The first is a struct literal. The
second is record update syntax. They use braces because they are constructing
values, not because they are choosing the brace spelling of a control-flow
body.

There is a named block literal form for structs:

```with
let p = Point:
    x: 1.0
    y: 2.0
```

But that is still a struct literal, not a free-standing statement block. The
fields are the body.

The useful rule is:

> If a keyword or declaration header introduces a body, colon and braces are
> two spellings of the same block. If braces are constructing data, they are
> part of that data syntax.

---

## Why This Matters

With leans hard on blocks:

- `type` blocks define data.
- `enum` blocks define choices.
- `match` blocks consume those choices.
- `with` blocks bind access to resources and temporaries.
- `comptime` blocks move work to compilation.
- `async:` blocks start concurrent work.

Keeping all of those visually aligned makes the language easier to scan.
The important word is the introducer: `type`, `enum`, `match`, `with`,
`comptime`, `async`. The punctuation only answers one question:

> Is this body delimited by indentation or by braces?

For hand-written code, indentation keeps the page quiet:

```with
fn route(req: Request) -> Response:
    match parse_route(req.path):
        .Home => render_home()
        .User(id) => render_user(id)
        .NotFound => Response.not_found()
```

For generated code, braces make the output robust:

```with
fn route(req: Request) -> Response {
    match parse_route(req.path) {
        .Home => render_home(),
        .User(id) => render_user(id),
        .NotFound => Response.not_found(),
    }
}
```

Same blocks. Same program. Different spelling.
