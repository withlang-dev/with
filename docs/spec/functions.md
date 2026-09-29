# 9. Functions and Expressions

### 9.1 Functions

```
fn add(a: i32, b: i32) -> i32: a + b

fn clamp(x: i32, lo: i32, hi: i32) -> i32:
    if x < lo: lo
    else if x > hi: hi
    else: x
```

**Syntax:**

```
fn NAME(PARAMS) -> TYPE: BODY    // parameters + declared return type
fn NAME(PARAMS): BODY            // parameters, return type inferred
fn NAME -> TYPE: BODY            // no parameters, declared return type
fn NAME: BODY                    // no parameters, return type inferred
```

When `-> TYPE` is omitted, the return type is inferred from the body's
tail. A body whose tail is a statement or a `Unit`-typed expression
returns `Unit`. An assignment in tail position is a statement. `main`,
`@[entry]` functions and `test_*` functions do not infer: their return
contract is fixed and their tail is statement position.

**Inferred returns through a branching tail.** When the tail is an `if`,
`if let` or `match`:

1. If an arm is missing — no final `else`, a partial `match`, or an arm
   that holds no expression (`else: {}`, `_ => {}`) — the tail is a
   statement and the function returns `Unit`. (An `if` without `else` and
   a partial `match` are never values: see "`else` is required in
   expression position" below and §9.7.)
2. Otherwise the reaching arms must have one type, which is the return
   type. `Never`-typed arms join with anything. The join follows §3.8.
3. If the reaching arms do not have one type, the return type cannot be
   inferred and the program is rejected: the programmer writes `->`. The
   compiler never chooses `Unit`, an arm's type, or a default for them.

A single-statement body and a block body ending in the same tail are the
same case. Every `return e` in the body must agree with the inferred
type; a value on one path and fall-off on another is a missing return
(§4.10). A closure with no expected function type infers its result the
same way.

An assignment `place = value` is an expression; its value is a read of
`place` after the store (C's rule, C11 §6.5.16, under With's view semantics:
a read of a place yields a view of it, §3.8, D22). In statement position the
value is discarded. In any other position — nested (`a = b = e`), an operand
(`while (n = next()) != 0:`), a binding (`let t = (s = e)`), or the tail of
a body whose declared return type is not `Unit` (D60) — the assignment yields
that view under the ordinary rules: a `Copy` demand copies, an owned demand
on a non-`Copy` view is refused with the clone or move fix-it. The value
stored is never duplicated (D73).

Function bodies support three interchangeable forms (§29.13):

```
fn NAME(PARAMS) -> TYPE: BODY    // inline or indented colon
fn NAME(PARAMS) -> TYPE { BODY } // braced
```

Parentheses are required when a function takes parameters. When a
function takes no parameters, parentheses may be included or
omitted — `fn greet:` and `fn greet():` are both legal. The
idiomatic style omits them. The body is introduced by
`:` (colon form) or `{ }` (brace form) — see §29.13 for the full
rules.

```
fn greet: print("hello")               // colon inline
fn greet { print("hello") }            // brace inline
fn greet(): print("hello")             // also legal, parens optional
fn get_pi -> f64: 3.14159              // no args, returns f64
fn double(x: i32) -> i32: x * 2       // args + return type
fn double(x: i32) -> i32 { x * 2 }    // same, brace form
fn log(msg: str): print(msg)           // args, returns Unit
```

**Conditional syntax:**

`if` supports the three normal body forms. `else if` is a two-token keyword pair
that continues the chain; `else` without `if` ends it:

```
// Inline colon — body introducer is ':'
if x < 0: handle_negative()
else if x == 0: handle_zero()
else: handle_positive()

// Inline colon expression arms
let y = if x > 0: x else if x == 0: 0 else: -x
let clamped = if x < lo: lo else if x > hi: hi else: x

// Indented colon
if x < 0:
    handle_negative()
else if x == 0:
    handle_zero()
else:
    handle_positive()

// Braced
if x < 0 { handle_negative() } else if x == 0 { handle_zero() } else { handle_positive() }
```

Every `if`, `else if`, and `else` arm uses a normal body introducer:
inline colon, indented colon, or braces. There is no `then` body form,
and a naked `else expr` is not valid; write `else: expr` or `else { expr }`.

```
let clamped =
    if x < lo:
        lo
    else if x > hi:
        hi
    else: x
```

`else if` is always parsed as a chain continuation — the parser
consumes `else`, sees `if`, and continues the same chain rather than
nesting an `if` inside the else body. The forms may be mixed freely
within a single chain. `else` is required in expression position
unless the if-branch is `Never`-typed.

### 9.1a Named Arguments, Default Parameters, and Implicit Parameters

Function parameters may be passed positionally or by name. Parameters
may declare a default value with `= expr`, and may declare an
`implicit` modifier to request resolution from an enclosing
`with name(expr):` scope (§7.3a).

```
fn connect(host: str, port: u16, timeout: i32 = 30) -> Connection
fn sin(x: &Array, ctx: implicit &Context) -> Array

connect("localhost", 8080, 60)
connect("localhost", port: 8080)
connect(timeout: 60, host: "localhost", port: 8080)

with context(default_device()):
    sin(x)
    sin(x, ctx: fallback_device)
```

**Rules:**

- Positional arguments must come before named arguments.
- Parameter names of `pub` functions are part of the API surface:
  renaming a `pub` parameter is a breaking change for named call
  sites.
- A parameter may not be specified more than once.
- Named arguments must match parameter names exactly.
- Named arguments may appear in any order relative to one another.
- Default parameters may be omitted positionally only from the end of
  the parameter list, or skipped arbitrarily when the caller uses
  named arguments.
- Default expressions are evaluated at the call site on every call
  where the argument is omitted.
- Call resolution order is: positional arguments, named arguments,
  implicit parameters, then defaults.
- `extern fn` values, closure values, and placeholder-based partial
  application calls do not support named arguments.
- A function may not declare two `implicit` parameters of the same
  type, and an `implicit` parameter may not also have a default.

```
fn greet(name: str, greeting: str = "Hello"):
    print(f"{greeting}, {name}!")

greet("Alice")                  // greeting defaults to "Hello"
greet("Bob", "Hey")             // explicit positional override
greet(name: "Cara")             // named + default
greet(greeting: "Hi", name: "Dae")
```

### 9.1b `const` Declarations

Compile-time constants are declared with `const`:

```
const MAX_SIZE = 1024
const PI = 3.14159
const HEADER: str = "X-Custom"
```

**Syntax:** `const NAME [: TYPE] = EXPR`

The type annotation may be omitted when the initializer determines an
unambiguous type. If omitted, ordinary expression inference and default
literal rules choose the type. The annotation is required when the
initializer cannot determine a concrete type, and public exported constants
must include an explicit type so the API surface is stable.

`const NAME: TYPE = EXPR` remains the spelling for API clarity and
disambiguation. Use it whenever the default literal type would be
surprising.

The expression must be evaluable at compile time — integer literals,
arithmetic (`+`, `-`, `*`, `/`, `%`), unary negate, logical `not`, and
references to other `const` values.

```
const WIDTH = 80
const HEIGHT = 24
const AREA = WIDTH * HEIGHT    // computed at compile time

pub const PROTOCOL_VERSION: u16 = 3
```

`const` values are inlined at every use site. They have no runtime address and
cannot be mutated. They may appear at module scope or inside function bodies.

**Difference from `let`:** `let` bindings are runtime values (even if initialized
from a constant). `const` values are guaranteed to be compile-time constants and
are always inlined.

### 9.1c Global Declarations

Module-level runtime state is declared with `global`:

```
global cache = Cache.new()        // stable binding: cannot be rebound
global var current: Option[User] = None   // rebindable binding
```

`global` is the module-level analog of `let`; `global var` is the
analog of `var`. A stable `global` cannot be reassigned, but its
value may still mutate through `mut self` methods, field assignment,
or `IndexPlace` writes if the type supports them. A `global var` may
additionally be reassigned to a new value of the same type.

A global always holds a value: it is observed, mutated in place, or
reassigned, never moved out of; an owned copy is spelled `.clone()`. A
`const` is a value, not a place — each use materializes it.

**Initialization.** Global initializers are ordinary expressions.
They run before `main`, on the initial thread, in declaration order
within a module. Because concurrency in With can only be created by
program code (§14, Invariant 3), initialization is race-free by
construction.

**Safety rule (data races).** Globals are places; §21.1's access
rules apply. Cross-thread safety is usage-based — the compiler
proves what it can, and asks for `unsafe` only past the proof:

1. **Never-mutated globals are always safe.** If the program never
   mutates a global after initialization (no reassignment, no
   `mut self` call, no field or index write, no mutable borrow),
   every read is race-free and requires nothing.
2. **Synchronized globals are always safe.** Globals of `Sync`
   synchronization types — `Atomic[T]`, `Mutex[T]`, `RwLock[T]`, and
   other types whose mutation flows through their own thread-safe
   APIs — are safe in all programs. This is the idiom for shared
   mutable state (§12.3 of the mutability model: scoped
   synchronization via `with`).
3. **Bare mutation is safe iff the program is provably
   single-threaded.** Mutating any other global (rebinding or
   interior mutation), and reading a global that is mutated anywhere,
   is safe when the compiler proves the program never gains
   concurrency. The proof obligations are enumerable, because With
   has exactly one concurrency source (§14, Invariant 3): the program
   uses no `async` construct, never calls `thread.spawn_os`, exports
   no `@[c_export]` symbols, and coerces no With function to an
   `extern "C"` callback. When the proof fails, each such access
   requires an `unsafe` context — the programmer is asserting the
   absence of a data race the compiler cannot prove, exactly as with
   raw pointers (§16.11).

The diagnostic for a failed proof must name the construct that
introduced concurrency and offer the remedies (wrap in `Atomic` /
`Mutex`, or `unsafe`):

```
error[E0921]: mutation of global `counter` may race
  --> src/serve.w:40:5
   |
40 |     counter += 1
   |     ^^^^^^^^^^^^ global mutated here
   |
  ::: src/serve.w:12:9
   |
12 |     let task = handle(conn)     // program creates fibers here
   |
   = help: use Atomic[i32], wrap in Mutex, or assert with `unsafe`
```

The proof is a whole-program analysis and may be conservative; a
conservative implementation may treat the proof as failed whenever it
cannot establish all obligations. Improving its precision is compiler
quality work (§22.3), never a semantic change: strengthening the
proof only makes more programs safe.

Migrated C globals (`with migrate`) translate to `global` /
`global var` and land under these same rules — single-threaded C
programs translate without ceremony; concurrent ones surface their
shared state loudly, which is the raw-stays-explicit contract
(§16.1).

### 9.2 Tail Call Optimization

Tail calls may be optimized even without annotations. `@[tailrec]`
turns that optimization into a guarantee: if the compiler cannot
eliminate stack growth for the annotated recursive calls, it rejects
the program.

```
@[tailrec]
fn factorial(n: Int, acc: Int) -> Int:
    match n { 0 => acc, _ => factorial(n - 1, n * acc) }
```

Tail position means:

- The final expression of a function body
- The final expression of a block already in tail position
- Both branches of an `if`/`else` already in tail position
- Every arm of a `match` already in tail position
- `return f(...)` only when the call result can be returned directly
  with no post-call coercion, wrapping, storage, cleanup, or ABI
  reshaping

The following are **not** tail position:

- Any call followed by additional work (`1 + recur(...)`, field access,
  method call, etc.)
- Loop bodies
- Calls with an active `defer` or `errdefer`
- Calls that leave a `Drop`-implementing local live across the call

```
@[tailrec]
fn bad(n: Int) -> Int:
    if n <= 0: 0
    else: 1 + bad(n - 1)        // compile error: not tail position
```

Self-recursive `@[tailrec]` functions must compile to a loop or
equivalent frame-reusing form. Mutual tail recursion is permitted
only when every function in the cycle is annotated `@[tailrec]` and
the compiler can verify the cycle without stack growth; otherwise the
program is ill-formed.

In the currently guaranteed mutual-recursion subset, every recursive
edge in the SCC must be in verified tail position, every member of the
SCC must have a compatible signature and calling convention, and no
active `defer` or `errdefer` cleanup may remain across the recursive
edge. When those conditions are not met, the compiler must reject the
program rather than falling back to ordinary stack-growing calls.

The full `@[tailrec]` contract, diagnostics, ABI constraints, and
current guaranteed lowering subset are specified in
`docs/tco-spec.md`.

### 9.3 Closures

```
x => x + 1
(x, y) => x * y
() => print("hello")
```

The `=>` token means "produces this value" and is used in both closures
and match arms. The `->` token is reserved exclusively for return type
annotations (e.g., `fn foo() -> i32`).

Implicit `it` parameter (see §9.3.1):
```
items |> filter(it.age > 21) |> map(it.name)
```

#### 9.3.1 Implicit `it` Parameter

When a function expects a single-parameter closure, the expression can
use `it` to refer to the implicit parameter instead of declaring an
explicit closure with `x => expr` syntax:

```
items |> filter(it.age > 21)     // equivalent to x => x.age > 21
items |> map(it.name)            // equivalent to x => x.name
items |> filter(it % 2 == 0)    // equivalent to n => n % 2 == 0
items |> sort_by(it.score)       // equivalent to x => x.score
```

`it` is a reserved keyword. It may only appear in expression positions
where the surrounding call site expects a single-parameter function type.
The compiler infers `it`'s type from the expected function parameter type.

**Nested `it` is forbidden:** If an `it`-expression appears inside
another `it`-expression, the inner closure must use explicit `param => expr`
syntax. This prevents ambiguity about which closure level `it` refers to.

```
// OK: outer uses it, inner uses explicit parameter
items |> map(it.children |> filter(c => c.active))

// ERROR: nested it is ambiguous
items |> map(it.children |> filter(it.active))
```

**`_` is not a closure placeholder.** `_` means discard (in patterns)
or placeholder (in partial application). For closure shorthand, `it` is
the one way.

**Error codes:**
- E0951: nested implicit `it` is ambiguous — use explicit `param => expr` for inner closure
- E0952: `it` used in context expecting N != 1 parameters
- E0953: `it` is a reserved keyword and cannot be used as an identifier

### 9.4 Partial Application

Functions can be partially applied with `_` placeholders inside a call
argument list:

```
fn add(a: i32, b: i32) -> i32: a + b
let add5 = add(5, _)        // fn(i32) -> i32
add5(3)                      // 8

let pair = make_pair(_, 10, _)   // fn(T0, T2) -> Pair
pair("x", true)

values |> map(clamp(0, 255, _))
```

Currying is not automatic. Partial application via `_` is the explicit,
controlled equivalent.

**Rules:**

- `_` is a placeholder only inside a call argument list.
- A placeholder call with `N` placeholders produces a closure taking
  `N` arguments in left-to-right placeholder order.
- Non-placeholder arguments are captured into the generated closure.
- `_` in callee position is an error.
- `add(5)` is an ordinary wrong-argument-count error, not partial
  application.
- Placeholder calls use positional arguments only; named arguments are
  not permitted in the same call.

### 9.5 Extension Blocks

```
extend Vec[T]:
    fn is_empty() -> bool: self.len() == 0
```

**Receiver mode is a keyword on the declaration; `self` is never written (D7).**
A method's receiver is expressed by a prefix keyword on `fn`. The receiver value
`self` is an implicit binding in the body, and its type — always the enclosing
type — is never spelled. Writing `self` (or its type) as a parameter is an
unnecessary character and is being retired.

Whether a function is an instance method or an associated function is decided by
**location**, with no keyword: a `fn` declared **inside** an `impl`/`extend`/`type`
is an instance method (receiver synthesised); a `fn` at **top level** — including
the dotted `fn Type.name` — is associated / free (no receiver).

| Declaration | Receiver semantics | Call syntax | Implicit receiver |
|-------------|--------------------|-------------|-------------------|
| `fn m()` inside `impl`/`extend`/`type` | borrows the receiver immutably | `x.m()` | `self: &Self` |
| `mut fn m()` inside a type | mutates the receiver in place (by-place mutable borrow) | `x.m()` | `mut self: Self` |
| `move fn m()` inside a type | moves (consumes) the receiver | `x.m()` | `move self: Self` |
| `fn Type.m()` at top level | none (associated) | `Type.m()` | — |
| `mut`/`move fn` at top level | *error* — mode with no receiver | — | — |

**A `mut fn` may not duplicate the receiver's ownership into its return
(D21).** The caller retains the receiver place across a `mut fn` call, so a
non-`Copy` owned return may not be the receiver itself or another owner of
storage that the receiver still owns. Receiver-returning fluency is a
consuming contract and is spelled `move fn`.

This rule forbids duplicated ownership, not useful results. A `mut fn` may
return a `Copy` value, a view governed by returned-origin tracking, a fresh
independent owned value, or ownership moved out of a receiver projection when
reset-on-move blanks that source projection (§2.5.1, D17). In the last case the
caller retains the changed receiver place and the return is the sole owner of
the moved-out value. The compiler rejects only a non-`Copy` owned return whose
ownership is still retained by the receiver.

```
impl Counter:
    fn get() -> i32: self.n            # read borrow — no `self` parameter
    mut fn bump(): self.n = self.n + 1  # mutable borrow
    move fn into_n() -> i32: self.n     # consuming

fn Counter.zero() -> Counter: Counter { n: 0 }   # top level: associated
```

*Transition:* the explicit receiver-parameter forms (`self: &Self`,
`mut self: Self`, `move self: Self`) remain accepted while the compiler and
stdlib migrate to the keyword form; the parser desugars the keyword form to
them. See `docs/proposals/eliminate-self.md` for the phased plan.

**Any owner type may be extended, primitives and `str` included — the
receiver mode decides by-place behavior, not the owner's type (D12).** A `mut fn`
mutates the caller's place for every owner, whether the owner is an
aggregate, a scalar primitive, or `str`:

```
extend i32:
    mut fn bump(): self += 1

var x = 5
x.bump()        # x == 6 — mutation reaches the caller
let y = 5
y.bump()        # error: cannot mutate immutable binding `y`
```

A scalar primitive is `Copy`, yet `mut fn` still borrows it in place: the
receiver **mode** wins over the owner's Copy-ness, exactly as it does for a
`Copy` struct. Passing the same value to a by-value parameter (`f(x)`)
copies it; calling a `mut fn` on it (`x.bump()`) borrows the caller's place
(by-place receiver mode, D12). `move fn` on a primitive still consumes.

The idiomatic use is a domain verb on a distinct/newtype, where the method
names an operation the bare operator cannot:

```
distinct type Health = i32
extend Health:
    mut fn damage(n: i32): self = Health(self.value - n)
    mut fn heal(n: i32):   self = Health(self.value + n)

var hp = Health(100)
hp.damage(30)   # reads as the domain verb, not `hp = Health(hp.value - 30)`
```

On a bare primitive with no domain meaning, prefer the operator (`x += 1`)
over `x.bump()`. `mut fn` on a `str` owner reassigns the caller's slice
(`self = self.slice(1, self.len())`), subject to the ephemeral/view-origin
rules of §22.

**Consuming `self` enables consuming method chains:**

```
type Builder { host: str, port: u16 }

extend Builder:
    move fn host(h: str) -> Builder: { self with host: h }
    move fn port(p: u16) -> Builder: { self with port: p }
    move fn build() -> Result[Server, ConfigError]: ...

// Dot-notation chains naturally — each call moves the builder
let server = Builder.new()
    .host("localhost")
    .port(8080)
    .build()?
```

This eliminates the need for pipeline placeholder syntax in builder
patterns. The pipeline operator `|>` remains available for free
functions and partial application.

**When to use which builder pattern:**

| Pattern | Best for | Example |
|---------|----------|---------|
| `with ... as mut` (§7.2) | Configuring fields on an existing struct with defaults | `with Config.default() as mut c: c.timeout = 30` |
| Method chains (§9.5) | Progressive construction with type-state, validation, or multiple steps | `Builder.new().host("x").build()?` |

Use `with ... as mut` when you have a struct with default values and
just need to set some fields. Use method chains when each step
transforms or validates the builder, especially when `.build()`
can fail. Both are idiomatic — they solve different problems.

### 9.6 Pipeline and Composition Operators

**Pipeline (forward application):**
```
data |> parse |> validate? |> transform |> summarize
```

Pipelines are left-associative. Ordinarily, `x |> f(a)` desugars to
`f(x, a)`, and the next stage receives that call's result. There is one
place-preserving case for in-place mutation (D21):

Stage lookup uses the piped value as a receiver when an applicable instance or
extension method named `f` exists, so `x |> f(a)` resolves as `x.f(a)`; that
method takes precedence over a same-named free function. If no applicable
method exists, the stage uses the ordinary free-function form `f(x, a)`.

**A stage that resolves to a `mut fn` whose resolved concrete return type is
`Unit` performs the ordinary mutating call and continues with the same receiver
place.** Resolution includes return-type inference, overload resolution, and
generic substitution. A `mut fn` stage with any other return type continues
with its returned value under the ordinary pipeline rule.

```
var v: Vec[i32] = Vec.new()

v
|> push(1)       // push mutates v and returns Unit; the pipeline still carries v
|> clear()       // clear mutates v and returns Unit; the pipeline still carries v
|> push(3)

assert(v.len() == 1)
```

This is definitionally the corresponding statement sequence:

```
v.push(1)
v.clear()
v.push(3)
```

Argument evaluation, receiver exclusivity, view liveness, alias checking, and
mutation ordering are exactly those of those ordinary calls (§3.2, §21.1). A
pipeline does not create a second or weaker place-mutation regime. For example,
`v |> push(f(v))` is governed exactly like `v.push(f(v))`: it is allowed when
`f(v)` finishes before the mutation and produces an independent value, and is
rejected when the argument retains access to `v`.

**A non-`Unit` result changes what the pipeline carries.** The named receiver
remains alive and mutated in its enclosing scope, while the next stage receives
the returned value:

```
var v: Vec[i32] = Vec.new()

let popped = v
    |> push(1)    // Unit: still carrying v
    |> pop()      // Option[i32]: now carrying the Option
    |> unwrap()

assert(popped == 1)
assert(v.is_empty())
```

The decision is static but not restricted to a literal `-> Unit` annotation.
An inferred Unit return threads the place. A generic stage threads the place
when its resolved return type is Unit after substitution, and carries the
returned value in instantiations where the substituted return type is not Unit:

```
v |> apply(clear_it) |> push(1)  // apply's resolved R is Unit: still carrying v
let ok = v |> apply(check_it)    // apply's resolved R is bool: carries the bool
```

**Rvalue receivers become statement temporaries.** The ordinary move and
temporary-drop rules (§2.2, §2.4) then apply without pipeline-specific
ownership behavior:

```
Vec.new() |> push(1)
// The hidden Vec place is dropped at statement end.

let v: Vec[i32] = Vec.new() |> push(1)
// The hidden Vec remains the final pipeline value and assignment moves it to v.

let item: Option[i32] = Vec.new() |> push(1) |> pop()
// pop changes the pipeline value to Option; item receives the Option and the
// now-empty hidden Vec is dropped at statement end.
```

A stage resolving to `Never` is not Unit: it diverges, there is no pipeline
value or continuation, and subsequent stages are unreachable under the
ordinary `Never` and unreachable-code rules (§20b.5).

**Backward application:**
```
print <| f"{key}: {value}"
```

`f <| x` desugars to `f(x)`. Right-associative. Useful for avoiding
parentheses in nested calls:

```
// These are equivalent:
assert(is_valid(parse(input)))
assert <| is_valid <| parse(input)
```

**Bitwise shift operators:**

`<<` (left shift) and `>>` (right shift) are binary operators at
precedence level 9, between bitwise operators and additive operators.

```
let flags = 1 << 4          // 16
let high = value >> 8        // extract high byte
let mask = 0xFF << (n * 8)   // position-dependent mask
```

Right shift is arithmetic (sign-extending) for signed types and
logical (zero-filling) for unsigned types.

**Function composition** uses the pipeline operator or explicit
closures:

```
let normalize = x => strip_accents(lowercase(trim(x)))
names |> map(normalize) |> collect[Vec]()
```

### 9.7 Pattern Matching

Pattern matching is the primary control flow for algebraic data types.
It is expression-oriented, exhaustive, and supports deep structural
matching. `match` has two forms:

- **Block match** uses `:` after the subject and separates arms with
  newlines.
- **Inline match** uses `{}` around arms and separates arms with
  commas.

Semicolons are not valid match arm separators.

**Patterns and `Drop`.** A struct or enum pattern applied to a value whose
type implements `Drop` is a compile-time error — in `let`, in a `match` arm
and in `if let` alike — with fix-its to keep the value whole (`let t = r`)
or read a field (`r.field`); a binding, `_` or a wildcard arm keeps the
value whole and its destructor runs as usual. Inside that type's own
`move fn` methods (`drop` included) such a pattern is the visible disarm
(§2.5.1) and must be total: every field is bound by name or explicitly
`_`; a partial pattern (`R { fd, .. }`) is an error naming the fields left
unstated.

**Block form:**
```
match shape:
    Circle(r)         => pi * r * r
    Rectangle(w, h)   => w * h
    Triangle(a, b, c) => herons_formula(a, b, c)
```

The colon is required in block form. Omitting it is a syntax error.
Block arms are separated by newlines; commas and leading `|` arm
separators are not used.

**Inline form:**
```
match n { 0 => 1, _ => n * factorial(n - 1) }
let x = match result { Ok(v) => v, Err(_) => default }
```

Inline match is an expression form. Arms are written as
`pattern => expr`; guards use `pattern if cond => expr`. Arms are
comma-separated, and a trailing comma is allowed under §29.2. The
semicolon-separated form used in earlier examples is invalid.

**Pattern projection preserves exact types (D22).** Pattern matching is
structural projection, not an owned-value demand. A pattern binding receives
the exact type of the projected subvalue. Projecting through a shared
reference produces shared-reference subviews; it does not contextually copy
`Copy` fields.

Therefore `Some(v)` matched against `Option[&V]` binds `v: &V` for every `V`
and every generic instantiation. A nested pattern such as `Some((a, b))`
matched against `Option[&(A, B)]` binds `a: &A` and `b: &B`. Contextual Copy
materialization may occur later when one of those bindings is used in an
independently established owned-value context. No `ref` pattern syntax or
type annotation is required merely to preserve the reference.

**Guards:**
```
match value:
    x if x > 0 => "positive"
    x if x < 0 => "negative"
    _           => "zero"
```

**Nested / deep patterns:**
```
match expr:
    Add(Lit(a), Lit(b))                 => Lit(a + b)
    Add(Lit(0), rhs)                    => rhs
    Mul(Lit(0), _) | Mul(_, Lit(0))     => Lit(0)
    other                               => other
```

**Or-patterns** share a body:
```
match day:
    Monday | Tuesday | Wednesday | Thursday | Friday => "weekday"
    Saturday | Sunday => "weekend"
```

**`@` binding:**
```
match event:
    click @ MouseClick { button: Left, pos } =>
        log("click at {pos}")
        handle(click)
```

**Literal and range patterns:**
```
match status_code:
    200         => "ok"
    301 | 302   => "redirect"
    400..=499   => "client error"
    _           => "unknown"
```

**`in` patterns:**

An `in` pattern matches when the scrutinee is contained in the given
expression. It works with any `Contains` type — arrays, ranges, sets,
or user types:

```
match method:
    in ["map", "filter", "take", "skip"] => handle_lazy()
    in ["collect", "fold", "sum", "count"] => handle_eager()
    _ => handle_other()
```

This is syntactic sugar for a guard:

```
match method:
    m if m in ["map", "filter", "take", "skip"] => handle_lazy()
    m if m in ["collect", "fold", "sum", "count"] => handle_eager()
    _ => handle_other()
```

The `in` pattern does not introduce a binding. Use `@` if you need
one:

```
match status_code:
    code @ in 200..=299 => log("success: {code}")
    code @ in 400..=499 => log("client error: {code}")
    code @ in 500..=599 => log("server error: {code}")
    other               => log("unexpected: {other}")
```

`in` patterns compose naturally with other match features:

```
fn categorize(token: TokenKind) -> Category:
    match token:
        in [Plus, Minus, Star, Slash]  => .Operator
        in [LParen, RParen, LBrace, RBrace] => .Delimiter
        in [If, Else, While, For, Match]    => .Keyword
        Ident(_)                             => .Identifier
        IntLit(_) | FloatLit(_)              => .Literal
        _                                    => .Other
```

**Struct patterns with `..` rest:**
```
match user:
    { name, age } if age >= 18 => grant_access(name)
    { name, .. }               => deny_access(name)
```

Positional struct patterns match fields in declaration order:

```
match point:
    Point(x, y) => plot(x, y)
```

**Tuple patterns:**
```
match (x, y):
    (0, 0) => "origin"
    (x, 0) => "x-axis at {x}"
    _      => "elsewhere"
```

Parentheses around a single pattern are grouping: `(p)` is the same
pattern as `p`. A one-element tuple pattern requires a comma: `(p,)`.
`()` matches the empty tuple.

**Slice patterns:**
```
match items:
    []              => "empty"
    [only]          => "single"
    [first, ..rest] => "head: {first}, {rest.len()} more"
```

For fixed-size arrays, the compiler performs compile-time length matching:
- `[a, b, c]` matches exactly 3 elements
- `[first, ..rest]` matches any array with 1+ elements, `rest` is bound to the remaining count
- `[first, ..mid, last]` matches 2+ elements, extracting both ends
- `[]` matches empty arrays (`[0]T`)

**`let` destructuring:**

All pattern forms are available in `let`/`var` bindings:

```
// Tuple destructuring
let (x, y, z) = compute_position()
let (first, _) = split_first(text)       // _ ignores a field
let (head, ..tail) = get_items()          // ..rest captures remaining

// Struct destructuring
let { name, age, .. } = get_user()        // .. ignores remaining fields
let { x, y } = point                      // field shorthand in patterns too

// Slice destructuring
let [first, second, ..rest] = items

// Nested destructuring
let (Ok({ name, email, .. }), status) = (parse_user(data), 200)
```

**`let ... else` (refutable patterns):**

When a pattern might not match, `let ... else` provides the
fallback. The `else` branch must diverge (`return`, `break`,
`continue`, `panic`). It is either a body in any of the three forms
of §29.13, or a single diverging expression written directly after
`else` on the same line:

```
let Some(user) = find_user(id) else return Err(.NotFound)
let Ok(value) = try_parse(input) else return Err(.ParseError)
let [first, ..rest] = items else return Err(.Empty)

let Some(user) = find_user(id) else:
    log(f"no user {id}")
    return Err(.NotFound)
```

**`if let`:**
```
if let Some(user) = find_user(id):
    print(f"found: {user.name}")
```

**Chained `if let`:** Multiple conditional bindings in a single `if`,
separated by commas. All bindings must succeed for the body to
execute. This eliminates the pyramid of doom:

```
// Before: nested if let
if let Some(b) = b_store.get(entity):
    if let Some(c) = c_store.get(entity):
        yield (entity, a, b, c)

// After: chained if let
if let Some(b) = b_store.get(entity),
   let Some(c) = c_store.get(entity):
    yield (entity, a, b, c)
```

Chains can mix `let` bindings with boolean conditions:

```
if let Some(user) = find_user(id),
   user.is_active(),
   let Some(email) = user.email:
    send_welcome(email)
```

Each binding in the chain is in scope for subsequent bindings and
the body. If any binding fails, the entire `if` is skipped (or the
`else` branch runs).

**`let ... else` with enum shorthand:**

`let ... else` works especially well with enum variant shorthand
for asserting expectations:

```
let .TString(key) = self.expect_token("object key")? else:
    return Err(.UnexpectedChar(self.pos))

let .Colon = self.expect_token("':'")? else:
    return Err(.UnexpectedChar(self.pos))

// Cleaner than the match equivalent
```

**Pattern matching in function parameters:**
```
fn distance({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point) -> f64:
    let dx = x2 - x1
    let dy = y2 - y1
    (dx * dx + dy * dy).sqrt()

fn origin: Point { x: 0.0, y: 0.0 }

fn head([first, ..]: &[T]) -> Option[&T]: Some(first)
fn head([]: &[T]) -> Option[&T]: None
```

Parameter patterns desugar to a match on the parameter at the
function entry. They are sugar, not a separate mechanism. Irrefutable
patterns (structs, tuples) need no special handling. Refutable
patterns (like slice patterns) require multiple function clauses or
an `else`.

**`match` in pipelines:**
```
let result = input |> parse |> match:
    Ok(ast)  => transform(ast)
    Err(e)   => default_ast()
```

**Destructuring in `for` loops:**
```
for (id, entity) in world.entities():
    process(id, entity)

for { name, age, .. } in users:
    print(f"{name}: {age}")
```

Exhaustiveness depends on position:

- **Expression-position match** (value is used/returned): must be exhaustive.
- **Statement-position match** (value ignored): may be partial; unmatched
  variants are a no-op.
- **`@[must_use]` types** (e.g. `Task`): match must always be
  exhaustive or include an explicit `_ => ...` catch-all arm, regardless
  of position. Partial match on a `@[must_use]` type is a compile error.
  `Result` is **not** `@[must_use]`: discarding or partially matching a
  `Result` carries no obligation (§10.1) — a statement-position match
  on `Result` follows the ordinary partial-match rule. (An opt-in lint
  may flag partial statement matches for projects that want
  exhaustiveness everywhere: `[lint] partial_statement_match = true` in
  `with.toml`.)

Examples:

```
// expression-position: exhaustive required
let label = match status:
    Ok(v) => "ok"
    Err(e) => "err"

// statement-position: partial allowed (non-must_use enum)
match event:
    Click(pos) => handle_click(pos)
    KeyDown(k) => handle_key(k)
// other variants are ignored

// statement-position on Result: partial match is allowed (§10.1)
match result:
    Ok(v) => process(v)
// unmatched Err arms are a no-op — no catch-all required
```

**Reference pattern ergonomics:** When a pattern is matched against
a reference type `&T`, the pattern automatically binds variables as
references to the inner fields. No explicit `&` is needed in the
pattern:

```
let items: Vec[(str, i32)] = [("alice", 1), ("bob", 2)]

// .iter() yields &(str, i32)
// Destructuring binds key: &str, val: &i32 automatically
for (key, val) in items:
    print(f"{key}: {val}")

// Equivalent explicit form (also valid but unnecessary):
for &(key, val) in items:
    print(f"{key}: {val}")

// Works with match on borrowed enums:
fn describe(opt: &Option[String]) -> &str:
    match opt:
        Some(s) => s       // s: &String, not String
        None    => "none"
```

This rule applies transitively: matching `&(A, &B)` against a
pattern `(a, b)` gives `a: &A` and `b: &&B`. The compiler inserts
reference bindings to match the actual type. This is critical for
ergonomic iteration, since `for` loops with implicit `.iter()`
always yield references.

**Trait-object downcast patterns.** In a match whose subject has type
`&dyn T`, the pattern `name: C` tests whether the object has concrete type
`C`. `C` must be visible and implement `T`. On a successful match, `name`
has type `&C` and observes the same object; it preserves the subject's
view origin and does not copy or take ownership of the object. This pattern
is rejected for a subject whose type is not `&dyn T`.

If `T` is `@[sealed]`, its closed set of implementors is the domain for
exhaustiveness. An exhaustive match covers every implementor with an
unguarded typed binding pattern or a wildcard. A non-sealed trait requires
a wildcard arm to establish exhaustiveness because its implementor set is
open. A guarded arm alone does not establish coverage. The ordinary rules
above determine when a non-exhaustive match is an error or a warning.

The binding remains an observing view when the trait-object place is
mutable. Mutation uses the trait's `mut fn` methods under the ordinary
receiver rules; the downcast pattern does not grant write access through
`&C`. With has no `&mut T` spelling (§15.1). Owned by-value trait-object
matching is not defined.

### 9.8 Pipeline DSL Patterns

The `|>` operator plus extension blocks plus closures is sufficient
to build fluent domain-specific APIs that read like language features.
No macros or special syntax required.

**Query DSL:**
```
let results = world
    |> query[Position, Velocity]()
    |> where((pos, _) => pos.x > 0.0)
    |> order_by((_, vel) => vel.magnitude())
    |> limit(100)
    |> collect[Vec]()
```

**HTTP request builder:**
```
let response = HttpClient.new()
    |> base_url("https://api.example.com")
    |> header("Authorization", "Bearer {token}")
    |> get("/users")
    |> query_param("page", "1")
    |> send()
    |> await?
```

**Shader pipeline:**
```
let shader = ShaderBuilder.new()
    |> vertex_input(VertexLayout.pos_normal_uv())
    |> uniform("camera", CameraUniforms)
    |> stage(ShaderStage.Vertex, vertex_main)
    |> stage(ShaderStage.Fragment, fragment_main)
    |> build()
```

These patterns require no language support beyond `|>`, extension
blocks, and closures. The gap between "library code" and "language
feature" is intentionally small in With — the pipeline operator makes
well-designed libraries feel like built-in syntax.

### 9.9 The `in` Operator

`in` is a boolean operator that tests membership. It works on any
type that implements the `Contains` trait. The compiler optimizes
literal cases to zero-allocation comparisons.

```
if method in ["map", "and_then", "filter", "map_err", "ok", "err"]:
    handle_combinator(method)
```

**Expression forms:**

```
expr in expr       → bool
expr not in expr   → bool
```

`in` is a binary operator at the same precedence level as equality
operators (`==`, `!=`). It is non-associative — `a in b in c` is a
compile error. Ordered comparisons (`<`, `<=`, `>`, `>=`) may chain;
see §4.2.7.

**Operator precedence** (low to high):

| Level | Operators | Associativity |
|-------|-----------|---------------|
| 1 | `or` | Left |
| 2 | `and` | Left |
| 3 | `==`, `!=`, `in`, `not in`, `=~`, `!~` | Non-associative |
| 4 | `<`, `>`, `<=`, `>=` | Chained |
| 5 | `\|>` (pipeline) | Left |
| 6 | `\|` | Left |
| 7 | `^` | Left |
| 8 | `&` | Left |
| 9 | `<<`, `>>` | Left |
| 10 | `+`, `-`, `++`, `??` | Left |
| 11 | `*`, `/`, `%`, `@` | Left |
| 12 | Unary prefix (`not`, `-`, `~`, `&`, `&raw mut`) | — |
| 13 | Postfix (`.await`, `?`, `.field`, `[i]`, `()`) | Left |

This means:

```
x in list and y in list       // (x in list) and (y in list)
x + 1 in values               // (x + 1) in values
not x in list                  // not (x in list) — but prefer `x not in list`
```

`not in` is a single two-keyword operator, not `not (x in y)`.
This matches Python's `not in` and reads naturally:

```
if x in [1, 2, 3]:               // membership test
if x not in [1, 2, 3]:           // negated membership
if name in names:                 // variable collection
if ch in 'a'..='z':              // range membership
if key in map:                    // key existence
if "hello" in text:               // substring search
```

**Desugaring:** `x in collection` desugars to
`collection.contains(&x)`. `x not in collection` desugars to
`not collection.contains(&x)`. The `Contains` trait is defined in
§11.7.

**`not in` vs `not` + `in`:**

`not in` is parsed as a single operator, not as `not (expr in expr)`.
Both `x not in list` and `not x in list` produce the same result.
The `not in` form is idiomatic. The linter suggests `x not in y`
when it sees `not (x in y)`.

**Type checking:**

1. Left operand type `T`
2. Right operand type `C` where `C: Contains[T]`
3. Result type is `bool`

If `C` does not implement `Contains[T]`, the compiler emits:

```
error[E0277]: cannot test membership of `Foo` in `Bar`
  --> src/main.w:12:15
   |
12 |     if x in bar:
   |           ^^ `Bar` does not implement `Contains[Foo]`
   |
   = help: implement `Contains[Foo] for Bar`
```

**Type inference:** The right-hand side provides type context for the
left-hand side, just as with `==`:

```
if 42 in values:    // 42 inferred as element type of values
if .Red in colors:  // .Red inferred as enum variant matching element type
```

Literal arrays on the right infer element type from the left:

```
let x: u8 = 5
if x in [1, 2, 3]:  // array inferred as [u8; 3], elements as u8
```

**Compiler optimizations:**

*Literal array elimination.* When the right-hand side of `in` is an
array literal where all elements are compile-time constants, the
compiler eliminates the array entirely and emits a chain of
comparisons:

```
// Source:
if method in ["map", "and_then", "filter"]:

// Compiles to (no allocation, no array):
if method == "map" or method == "and_then" or method == "filter":
```

This applies to any array literal of constants: integers, floats,
strings, enum variants, bool. For small arrays (≤8 elements), this
is always done. For larger literal arrays, the compiler may emit a
switch/jump table or sorted binary search. The threshold is
implementation-defined.

*Range optimization.* Ranges are always optimized to two comparisons:

```
// Source:
if x in 1..=100:

// Compiles to:
if x >= 1 and x <= 100:
```

No `Contains` trait call, no range object allocation.

*HashSet / HashMap.* These go through the actual `.contains()` method,
which is O(1). No special compiler treatment needed.

**Interaction with `for` loops:**

`in` already appears in `for` loops (`for x in collection:`). The
`for` loop uses the `Iter` trait. The `in` operator uses the
`Contains` trait. The parser distinguishes them structurally:
`for PATTERN in EXPR:` is a loop, `EXPR in EXPR` is a membership
test. No ambiguity.

**Interaction with comprehensions:**

`in` in comprehensions is the `for` loop form, not the membership
test. The membership test appears in filter expressions:

```
[x * x for x in 0..10]              // for-in loop
[x for x in 0..100 if x in primes]  // for-in loop + membership test in filter
```

**Interaction with pipelines:**

`in` works naturally inside pipeline closures:

```
let valid = tokens
    |> filter(t => t.kind in [Ident, Number, String])
    |> collect[Vec]()
```

**Interaction with match patterns:**

`in` patterns are described in §9.7. Range patterns (`400..=499`)
remain valid in match. There is no ambiguity because `in` patterns
always start with the `in` keyword.

**Examples:**

```
// Basic membership
let vowels = ['a', 'e', 'i', 'o', 'u']
if ch in vowels:
    print("vowel")

// String search
if "error" in log_line:
    alert(log_line)

if '@' in email:
    validate_email(email)

// Enum variant sets
enum Color { Red | Green | Blue | Yellow | Cyan | Magenta }

fn is_primary(c: Color) -> bool:
    c in [.Red, .Green, .Blue]

// Map key existence
if key in cache:
    cache[key]
else:
    let val = compute(key)
    cache[key] = val
    val

// Range checks
fn is_ascii_letter(c: char) -> bool:
    c in 'a'..='z' or c in 'A'..='Z'

fn is_valid_port(port: u16) -> bool:
    port in 1..=65535

// Filtering
let dangerous_ops = ["rm", "format", "drop", "truncate"]
let safe_commands = commands
    |> filter(cmd => cmd.op not in dangerous_ops)
    |> collect[Vec]()

// Compound conditions
if user.role in ["admin", "moderator"] and action in allowed_actions:
    execute(action)
```

**Grammar:**

```
// Expression
in_expr     = expr "in" expr
            | expr "not" "in" expr

// Pattern (in match arms)
in_pattern  = "in" expr

// With @ binding
in_pattern  = IDENT "@" "in" expr
```

The `in` keyword is already reserved (used by `for`). `not` is
already a keyword. No new keywords needed.

---
