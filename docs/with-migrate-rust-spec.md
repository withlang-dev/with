# `with migrate rust` — Rust-to-With Source Translator

**Best-effort migration from Rust to With.**

The output is a starting point, not a finished product. It handles
syntax, common patterns, and structural differences automatically.
It flags what it can't translate. The programmer finishes the job.

---

## Design Goals

1. **Get 80% of the way there.** Syntax, types, traits, error
   handling, closures, control flow — translate mechanically.
   The output reads like With, not like Rust with find-and-replace.

2. **Flag the hard parts.** Lifetimes, stored references, `Pin`,
   `Arc`/`Rc`, `unsafe` blocks, proc macros — mark them with
   `// @migrate:` comments explaining what needs to change and why.

3. **Never silently break semantics.** If a translation might
   change behavior, flag it rather than guess. Prefer a compile
   error the user can see over a subtle runtime difference.

4. **One command.** `with migrate rust src/` translates a Rust
   crate directory.

---

## Usage

```
with migrate rust src/lib.rs              # single file
with migrate rust src/                    # directory (all .rs files)
with migrate rust src/ -o lib/            # explicit output
with migrate rust src/ --check            # dry run
with migrate rust src/ --diff             # unified diff
with migrate rust src/ --stats            # summary
```

---

## Translation Rules

### Tier 1: Mechanical Syntax (100% automated)

These are always correct. No flags needed.

#### Braces → indentation

```rust
// Rust
fn process(x: i32) -> i32 {
    if x > 0 {
        x * 2
    } else {
        -x
    }
}

// With
fn process(x: i32) -> i32:
    if x > 0:
        x * 2
    else:
        -x
```

Strip `{` `}` `;` from control flow. Convert to indent-based
blocks. The existing `bracesToIndent` in Migrate.zig does this.

#### Bindings

```rust
let x = 5;            →  let x = 5
let mut x = 5;        →  var x = 5
const X: i32 = 5;     →  const X: i32 = 5
static X: i32 = 5;    →  let X: i32 = 5    // @migrate: was static
static mut X: i32 = 5; → var X: i32 = 5    // @migrate: was static mut
```

#### Generic syntax

```rust
Vec<T>                 →  Vec[T]
HashMap<K, V>          →  HashMap[K, V]
Result<T, E>           →  Result[T, E]
impl<T: Clone>         →  impl[T: Clone]
fn foo<T>(x: T)        →  fn foo[T](x: T)
where T: Display       →  where T: Display
```

Replace `<` `>` with `[` `]` in generic positions. Must be
context-aware: `a < b` (comparison) vs `Vec<T>` (generic). Use
the same disambiguation as Rust's parser — after a type name or
keyword (`impl`, `fn`, `struct`, `enum`, `trait`), `<` is generic.

#### Path separator

```rust
std::collections::HashMap  →  std.collections.HashMap
crate::module::Type        →  module.Type
self::foo                  →  foo
super::bar                 →  // @migrate: super not supported, use explicit path
```

`::` → `.` everywhere.

#### Attributes

```rust
#[derive(Clone, Debug)]    →  @[derive(Clone, Debug)]
#[inline]                  →  @[inline]
#[cfg(test)]               →  @[cfg(test)]
#[allow(unused)]           →  @[allow(unused)]
#[test]                    →  @[test]
```

`#[` → `@[`. Inner attributes `#![` → `// @migrate: crate-level attribute`.

#### String formatting

```rust
format!("{}", x)           →  f"{x}"
format!("{:?}", x)         →  f"{x:?}"
println!("{}", x)          →  print(f"{x}")
println!("{x}")            →  print(f"{x}")
eprintln!("{}", x)         →  eprint(f"{x}")
write!(f, "{}", x)         →  f.write(f"{x}")
panic!("msg")              →  panic("msg")
todo!()                    →  panic("todo")
unimplemented!()           →  panic("unimplemented")
unreachable!()             →  unreachable()
assert!(cond)              →  assert(cond)
assert_eq!(a, b)           →  assert(a == b)
assert_ne!(a, b)           →  assert(a != b)
debug_assert!(cond)        →  assert(cond)   // @migrate: was debug_assert
```

Pattern-match macro invocations. Handle positional (`{}`) and
named (`{name}`) format args. Convert to With f-strings.

#### Closures

```rust
|x| x + 1                 →  x => x + 1
|x, y| x + y              →  (x, y) => x + y
|x: i32| -> i32 { x + 1 } →  (x: i32) -> i32 => x + 1
move |x| x + 1            →  x => x + 1   // @migrate: was move closure
|| { body }               →  () => body
```

`|args| expr` → `args => expr`. Typed closures preserve types.
`move` keyword is flagged (With determines capture mode
automatically).

#### Control flow

```rust
if let Some(x) = opt { body }        →  if let Some(x) = opt: body
while let Some(x) = iter.next() {}   →  while let Some(x) = iter.next(): ...
for x in iter { body }               →  for x in iter: body
loop { body }                        →  while true: body
match x { arms }                     →  match x: arms
```

Rust `loop` → `while true`. Match arms: `pat => expr,` →
`pat -> expr`.

```rust
// Rust match arm
Some(x) => x * 2,
None => 0,

// With match arm
Some(x) -> x * 2
None -> 0
```

#### Semicolons

Strip trailing `;` from statements. Expression-position
semicolons (Rust's "discard value" semantics) are handled:
`expr;` at end of block → `expr` (ignore result) or
`let _ = expr` if the value might have side effects via `Drop`.

#### Return type syntax

```rust
fn foo() { ... }           →  fn foo: ...
fn foo() -> i32 { ... }   →  fn foo -> i32: ...
fn foo(&self) -> i32       →  fn foo(self: &Self) -> i32
fn foo(&mut self)          →  fn foo(self: &mut Self)
fn foo(self)               →  fn foo(self: Self)   // @migrate: by-value self
```

#### Visibility

```rust
pub fn foo()               →  pub fn foo
pub(crate) fn foo()        →  fn foo   // @migrate: was pub(crate)
pub(super) fn foo()        →  fn foo   // @migrate: was pub(super)
```

`pub` stays. `pub(crate)` and `pub(super)` → private with flag.

#### Type aliases

```rust
type Alias = Vec<i32>;     →  type Alias = Vec[i32]
```

#### Struct / Enum

```rust
struct Point {
    x: f64,
    y: f64,
}

// With
type Point = {
    x: f64,
    y: f64,
}
```

```rust
enum Shape {
    Circle(f64),
    Rect { w: f64, h: f64 },
}

// With
type Shape =
    | Circle(f64)
    | Rect { w: f64, h: f64 }
```

Struct → `type Name = { fields }`. Enum → `type Name = | Variant | ...`.

---

### Tier 2: Semantic Translations (automated with caveats)

These change structure but are correct for common patterns.
Flagged with `// @migrate:` when the translation might need
manual verification.

#### Lifetimes → removal

```rust
fn first<'a>(s: &'a str) -> &'a str { &s[..1] }

// With
fn first(s: &str) -> &str: s.slice(0, 1)
// @migrate: lifetime 'a removed — With infers borrow provenance
```

Strip all lifetime parameters (`<'a, 'b>`), lifetime annotations
on references (`&'a T` → `&T`), and lifetime bounds
(`T: 'a` → `T`). With's borrow checker infers provenance from
parameter position.

For `'static`: `&'static str` → `str` (With's `str` is already
a static string type).

#### `Box<T>` → `T`

```rust
fn make() -> Box<dyn Error> { ... }
let x: Box<i32> = Box::new(5);

// With
fn make() -> dyn Error: ...   // @migrate: Box removed, verify return works
let x: i32 = 5
```

In most cases, `Box<T>` is used for heap allocation that With
handles automatically (all values are stack or heap as needed).
`Box<dyn Trait>` → `dyn Trait`. Flag for review.

#### `Rc<T>` / `Arc<T>` → flag

```rust
let shared: Arc<Mutex<Data>> = Arc::new(Mutex::new(data));

// With
let shared = Mutex.new(data)
// @migrate: Arc removed. With uses `with` blocks for shared access:
//   with shared.lock() as data: ...
// If this value is shared across threads, use a different pattern.
```

There's no 1:1 equivalent. Flag with an explanation of the
With alternatives:
- Thread-local: just own it
- Shared read: `with lock.read() as data:`
- Shared write: `with lock.write() as mut data:`
- Entity systems: `SlotMap[T]` + `Handle[T]`

#### `String` / `&str`

```rust
fn greet(name: &str) -> String {
    format!("hello {name}")
}

// With
fn greet(name: &str) -> str:
    f"hello {name}"
```

`String` → `str` (With's `str` is owned). `&str` stays as `&str`
in parameter position or becomes `str` in return position.
`.to_string()`, `.to_owned()`, `.into()` for strings → remove.

#### `Option` / `Result` methods

```rust
opt.unwrap_or(default)     →  opt ?? default
opt.unwrap_or_else(|| f()) →  opt ?? f()
opt.and_then(|x| f(x))    →  // keep as-is, With has and_then
opt.map(|x| x + 1)        →  opt.map(x => x + 1)
opt.ok_or(err)             →  // keep as-is
opt.is_some()              →  opt.is_some()
opt.is_none()              →  opt.is_none()
```

`unwrap_or` → `??`. Other combinators have the same names.

#### `impl Trait` return type

```rust
fn items() -> impl Iterator<Item = i32> { ... }

// With
fn items() -> impl Iter[i32]: ...
// @migrate: With uses Iter[T] trait, not Iterator<Item = T>
```

`Iterator<Item = T>` → `Iter[T]`.

#### `impl` blocks

```rust
impl Point {
    fn new(x: f64, y: f64) -> Self { Point { x, y } }
    fn distance(&self, other: &Point) -> f64 { ... }
}

// With
impl Point:
    fn new(x: f64, y: f64) -> Self: Point { x, y }
    fn distance(self: &Self, other: &Point) -> f64: ...
```

or equivalently with `extend`:

```
extend Point:
    fn new(x: f64, y: f64) -> Point: Point { x, y }
    fn distance(self: &Point, other: &Point) -> f64: ...
```

`&self` → `self: &Self`. `&mut self` → `self: &mut Self`.
`self` (by value) → `self: Self` with flag.

#### Trait impl

```rust
impl Display for Point {
    fn fmt(&self, f: &mut Formatter) -> fmt::Result { ... }
}

// With
impl Display for Point:
    fn fmt(self: &Self, f: &mut Formatter) -> fmt.Result: ...
```

Direct translation. `fmt::Result` → `fmt.Result`.

#### `async` / `.await`

```rust
async fn fetch(url: &str) -> Result<Response, Error> {
    let resp = client.get(url).await?;
    Ok(resp)
}

// With
async fn fetch(url: &str) -> Result[Response, Error]:
    let resp = client.get(url).await?
    resp   // implicit Ok wrapping
```

`expr.await` → `expr.await` (already postfix in With).
`async fn` → `async fn`. Remove explicit `Ok()` wrapping at
end of Result-returning functions.

#### `vec![]` and other macros

```rust
vec![1, 2, 3]              →  [1, 2, 3]   // @migrate: verify Vec literal syntax
vec![]                      →  Vec.new()
HashMap::new()              →  HashMap.new()
```

#### Range syntax

```rust
0..10                      →  0..10
0..=10                     →  0..=10
..10                       →  ..10
```

Direct translation (same syntax in With).

---

### Tier 3: Structural Flags (cannot auto-translate)

These produce `// @migrate:` annotations. The tool does NOT
attempt to translate these — it preserves the Rust code as a
comment and explains what needs to change.

#### Stored references in structs

```rust
struct Parser<'a> {
    source: &'a str,
    pos: usize,
}

// With
type Parser = {
    // @migrate: STORED REFERENCE — With does not allow references in structs.
    // Options:
    //   1. Make this an ephemeral type: type Parser = ephemeral { source: StrView, pos: usize }
    //   2. Own the data: type Parser = { source: str, pos: usize }
    //   3. Use offset-based: type Parser = { source_len: usize, pos: usize }
    source: str,    // changed from &'a str — verify ownership
    pos: usize,
}
```

Detect `'a` on struct → flag every reference field.

#### `Rc<T>` / `Arc<T>` / `Weak<T>`

```rust
let node: Rc<RefCell<Node>> = ...

// With
// @migrate: Rc<RefCell<Node>> — no direct equivalent.
// With alternatives:
//   - If single-threaded ownership graph: use Handle[Node] + SlotMap
//   - If shared read: with lock.read() as node: ...
//   - If tree structure: own children, borrow parent via &
let node = ...  // TODO: choose pattern
```

#### `Pin<T>`

```rust
// @migrate: Pin<T> not needed in With.
// With uses stackful fibers, not pinned state machines.
// Self-referential types: use offset-based pattern or arena.
```

#### `unsafe` blocks

```rust
unsafe {
    ptr::write(dst, src);
}

// With
unsafe:
    // @migrate: review unsafe block — raw pointer write
    ptr_write(dst, src)
```

Translate the syntax (`unsafe { }` → `unsafe:`). Flag for review.
With has `unsafe` with the same semantics.

#### Proc macros / derive macros

```rust
#[derive(Serialize, Deserialize)]

// With
// @migrate: Serialize/Deserialize — no proc macro equivalent.
// Implement manually or use With's @[derive] for supported traits.
@[derive(Clone, Debug)]
```

Known derives that map: `Clone`, `Debug`, `Default`, `PartialEq`,
`Eq`, `Hash`. Everything else → flag.

#### Trait associated types

```rust
trait Collection {
    type Item;
    fn get(&self, idx: usize) -> Option<&Self::Item>;
}

// With
trait Collection:
    // @migrate: associated type Item — With uses generic trait params instead
    // trait Collection[T]: fn get(self: &Self, idx: usize) -> Option[&T]
    type Item
    fn get(self: &Self, idx: usize) -> Option[&Self.Item]
```

With supports basic associated types but the idiomatic pattern
is generic trait parameters (`Iter[T]` not `Iterator<Item=T>`).
Flag and suggest the generic form.

#### `dyn Trait + Send + Sync`

```rust
Box<dyn Error + Send + Sync>

// With
// @migrate: Send + Sync bounds removed.
// With's concurrency model uses fiber-safe types by default.
dyn Error
```

`Send`/`Sync` don't exist in With. Strip them. Flag if the code
relies on thread-safety guarantees.

#### Macro definitions

```rust
macro_rules! my_macro { ... }

// With
// @migrate: macro_rules! not supported.
// Convert to a function or generic function.
// Original macro preserved below as comment:
// macro_rules! my_macro { ($x:expr) => { $x + 1 } }
fn my_macro(x: i32) -> i32: x + 1  // best-guess translation
```

For simple expression macros: convert to generic function.
For complex macros: comment out and flag.

#### Feature flags / conditional compilation

```rust
#[cfg(feature = "serde")]
impl Serialize for Foo { ... }

// With
// @migrate: cfg(feature) — With uses comptime if for conditional compilation
// comptime if cfg.feature_serde:
//     impl Serialize for Foo: ...
```

#### Turbofish

```rust
let x = iter.collect::<Vec<_>>();

// With
let x: Vec[_] = iter.collect()
// @migrate: turbofish ::<> converted to type annotation
```

Convert turbofish to a type annotation on the binding.

---

## Translation Quality Levels

The tool reports a quality level per file:

| Level | Meaning | Typical result |
|---|---|---|
| **A** | Pure syntax changes. Compiles immediately. | Utility functions, simple structs, error types |
| **B** | Minor semantic changes. Compiles with small edits. | Functions with `Box<T>`, string conversions |
| **C** | Structural changes needed. Significant manual work. | Structs with lifetimes, `Arc`/`Rc`, proc macros |
| **D** | Mostly untranslatable. Flagged throughout. | Macro-heavy code, `Pin`, custom allocators |

```
with migrate rust src/ --stats

src/lib.rs     → lib.w       Grade A   0 flags
src/parser.rs  → parser.w    Grade B   3 flags (Box removal)
src/ast.rs     → ast.w       Grade C   7 flags (stored refs, lifetimes)
src/macros.rs  → macros.w    Grade D  12 flags (proc macros, macro_rules)
```

---

## Multi-File / Crate Translation

### Module structure

```rust
// Rust: src/lib.rs, src/parser.rs, src/parser/lexer.rs
// With: lib.w, parser.w, parser/lexer.w
```

`mod parser;` → `use parser` (if in same directory).
`mod parser { ... }` (inline module) → separate file `parser.w`.

### `use` statements

```rust
use std::collections::HashMap;
use crate::parser::Parser;
use super::utils;

// With
use std.collections.HashMap
use parser.Parser
// @migrate: super::utils — use explicit module path
```

`std::` → `std.`. `crate::` → strip (top-level). `super::` → flag.

### Cargo.toml → with.toml

```toml
# Cargo.toml
[dependencies]
serde = { version = "1.0", features = ["derive"] }
tokio = "1"

# with.toml (suggested, not auto-generated)
# @migrate: external dependencies need With equivalents:
#   serde → With's built-in serialization or manual impl
#   tokio → With's built-in async runtime (no external runtime needed)
```

The tool does NOT generate `with.toml`. It emits a comment
listing Cargo dependencies and suggesting With alternatives.

---

## What We Don't Translate

| Rust feature | Why | What happens |
|---|---|---|
| Proc macros | No equivalent | Commented out, flagged |
| `macro_rules!` (complex) | No equivalent | Commented out, flagged |
| Custom allocators | Different model | Flagged |
| Inline assembly | Different syntax | Flagged |
| `Pin`/`Unpin` | Not needed (fibers) | Removed, flagged |
| Raw pointer FFI | Different syntax | Translated to With `unsafe`, flagged |
| `#![no_std]` | Different tier system | Flagged |
| Build scripts (`build.rs`) | Different build model | Not translated |
| Benchmarks | Different framework | Not translated |

---

## Implementation Plan

### Step 1: Syntax transformer (extend Migrate.zig port)

The existing `transformRust` in Migrate.zig handles basic
syntax rewrites. Port to With (in `src/MigrateRust.w`) and
extend with:

- Generic `<>` → `[]` (context-aware)
- Closure `||` → `=>`
- Match arms `=>` → `->`
- `impl` block restructuring
- Visibility modifiers
- Struct/enum syntax

**Done when:** Pure-syntax Rust files produce readable With.

### Step 2: Type rewriter

- `Box<T>` → `T`
- `String` → `str`
- `&'a str` → `&str` (strip lifetime)
- `Vec<T>` → `Vec[T]`
- `Option<T>` → `Option[T]`
- `Result<T, E>` → `Result[T, E]`
- `Arc<Mutex<T>>` → `Mutex[T]` (with flag)
- `impl Iterator<Item = T>` → `impl Iter[T]`

**Done when:** Common Rust types produce correct With types.

### Step 3: Macro expansion

- `format!` → f-string
- `println!`/`eprintln!` → `print`/`eprint`
- `vec![]` → array literal or `Vec.new()`
- `assert!`/`assert_eq!`/`assert_ne!` → `assert`
- `panic!`/`todo!`/`unreachable!` → `panic`/`unreachable`

**Done when:** Standard library macros produce correct With.

### Step 4: Lifetime stripper

- Remove `<'a, 'b, ...>` from function signatures
- Remove `'a` annotations from references
- Remove `T: 'a` bounds
- `&'static str` → `str`
- Flag structs with lifetime parameters

**Done when:** No lifetime syntax remains in output.

### Step 5: Flag generator

Walk the AST (or the translated text) and emit `// @migrate:`
comments for:
- Stored references in structs
- `Rc`/`Arc`/`Weak` usage
- `Pin` usage
- `unsafe` blocks
- Proc macro derives
- `macro_rules!` definitions
- `Send`/`Sync` bounds
- Feature flags
- Associated types in traits

**Done when:** Every untranslatable construct has a flag with
an explanation of the With alternative.

### Step 6: Quality grading

Count flags per file. Assign grade A–D. Print summary.

### Step 7: Multi-file and module rewriting

Handle `mod` declarations, `use` paths, `crate::`/`super::`,
file tree structure.

**Done when:** `with migrate rust src/` translates a full crate.

---

## Philosophy

This tool is a **recruitment aid**, not a compiler. It says:

> "Here's your Rust code in With. 80% of it compiles already.
> The flagged parts are where With does things differently —
> and in most cases, simpler. No lifetimes, no `Pin`, no
> `Arc<Mutex<T>>`. Just `with lock.read() as data:`."

The flags are not apologies. They're invitations to learn
With's idioms. Each flag explains the With way of doing things,
which is the real migration: not syntax, but mindset.
