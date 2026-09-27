# 13. Iteration and Collection Operations

### 13.1 Iterators Over Borrowed Data Are Ephemeral

Iterators holding references to collections are ephemeral. They can be
used in pipelines within scope but not stored, returned, or captured by
escaping closures.

**What this means in practice:** You cannot return an *opaque* lazy
iterator that borrows from its inputs (e.g., `-> dyn Iter[StrView]`
or `-> dyn Iter[StrView]`). However, you CAN return a *concrete
ephemeral struct* that implements `Iter`:

```
// IMPOSSIBLE: opaque return type hides the ephemerality
fn find_matches(text: &str, pat: &str) -> dyn Iter[StrView]

// POSSIBLE: concrete ephemeral struct — caller inherits restriction
type MatchIter = ephemeral { text: StrView, pat: StrView, pos: usize }
impl Iter[StrView] for MatchIter: ...

fn find_matches(text: &str, pat: &str) -> MatchIter:
    MatchIter { text: text.as_view(), pat: pat.as_view(), pos: 0 }
// Caller's binding is ephemeral — cannot store, must use in this scope
```

The concrete ephemeral struct approach works because the caller can
see the type is ephemeral and inherits the restriction (Rule 8,
§22.1). The opaque approach fails because trait objects erase the
ephemerality, preventing the caller from knowing the restriction.

**Additional workarounds (when concrete ephemeral structs are too verbose):**

```
// 1. Collect into owned container (small allocation cost)
fn find_matches(text: &String, pat: &str) -> Vec[String]:
    text.split(pat) |> map(s => s.to_string()) |> collect()

// 2. Generator (lazy, zero-copy, no allocation; the caller's `for`
//    body sees each view while the generator runs, §13.4)
gen fn find_matches(text: &String, pat: &str) -> StrView:
    for segment in text.split(pat):
        yield segment

// 3. Process inline (no function boundary)
let results = text.split(pat)
    |> filter(s => s.len() > 0)
    |> map(s => s.to_string())
    |> collect[Vec]()
```

This trade-off is fundamental to With's design. Rust allows returning
borrowing iterators at the cost of lifetime annotations on every struct
and function in the chain. With eliminates those annotations at the
cost of occasional allocation or ownership transfer at function
boundaries. For most code, the ergonomic difference is small. For
zero-copy parsing pipelines, it is real.

### 13.2 The Iterator Trait

```
trait Iter[T]:
    fn next(mut self: Self) -> Option[T]
```

**One-implementation rule:** A type may implement `Iter[T]` for
**at most one `T`**. This ensures that `for x in expr:` always has
unambiguous type inference — the compiler knows exactly what type
`x` is without annotation:

```
// OK: Vec[i32]'s iterator yields &i32
for x in my_vec:
    print(x)           // x: &i32, unambiguous

// ERROR: conflicting Iter implementations
impl Iter[u8] for MyBuffer: ...
impl Iter[String] for MyBuffer: ...   // REJECTED: MyBuffer already implements Iter[u8]
```

This restriction replaces the need for associated types on `Iter`
in v1.0. A type that genuinely needs to yield different element
types should provide named methods returning different iterator
types (e.g., `.bytes() -> ByteIter`, `.lines() -> LineIter`).

**Iterators just work — for every library, not just the stdlib.**
The mechanism is the `@[iter_of_self]` attribute on an
iterator-returning method: it declares that the returned iterator
borrows the *receiver* (the underlying collection), not the iterator
struct itself. The registered borrow on the receiver is shared, lives
as long as the iterator, and is the origin of any references the
iterator's `next()` yields. The stdlib applies it to `Vec.iter()`,
`HashMap.iter()`, and the other collection iterators; any library may
apply it to its own iterator constructors (tensor views, ECS queries,
dataset readers). Future versions may infer this property from the
constructor body; the semantics are normative either way. This means
normal iteration patterns work naturally:

```
let iter = names.iter()
let a = iter.next()   // borrows from names, not iter
let b = iter.next()   // OK — iter is not locked by a
process(a, b)         // both references live simultaneously
```

`for` loops, `.zip()`, `.peekable()`, `.windows()` — all work as
you'd expect. A custom iterator constructor without `@[iter_of_self]`
falls back to conservative borrowing (the iterator value itself is
treated as holding the borrow), which is safe but may reject patterns
the attribute would allow.

*§13.3 Collection Operations (Standard Library) moved to `docs/spec/stdlib/collection-operations.md`.*

### 13.4 Generators (`yield`)

A generator produces a sequence by calling `yield` once per element. It
is an ordinary function whose consumer decides what happens to each
element: a `for` loop over a generator runs its body at each `yield`,
inside the generator's call.

```
gen fn fibonacci -> i64:
    var a = 0
    var b = 1
    loop:
        yield a
        let next = a + b
        a = b
        b = next

let first_10 = fibonacci() |> take(10) |> collect[Vec]()

gen fn upto(count: i32) -> i32:
    for i in 0..count:
        yield i * 10

for v in upto(4):
    print(v)                 // 0, 10, 20, 30
```

**Declaration and call.** `gen fn f(params) -> T` declares a generator
whose elements have type `T`; the `-> T` names the element type, as
`async fn f -> T` names the task's result. Calling `f(args)` runs
nothing: it evaluates the arguments and returns a **generator value**
that holds them, of a compiler-generated type whose name is not
denotable. The body runs when the value is consumed. A generator value
is consumed once.

**`Gen[T]`.** Every generator value implements:

```
trait Gen[T]:
    move fn each(body: fn(T) -> bool)
```

`each` calls `body` once per element, in order, and stops as soon as
`body` returns `false`. `for x in g:` consumes `g` through `each`. The
pipeline stages of §13.3 that visit elements in order (`map`, `filter`,
`take`, `collect`, and the like) accept a `Gen[T]`; a stage that steps a
sequence itself (`zip`, `peekable`, a bare `next()`) takes an `Iter[T]`
(see **Pulling** below). Application code never writes
`each`; implementing `Gen[T]` by hand is library-maintainer work.

**`yield`.** `yield e` hands `e` to the consumer and continues after
the consumer's body has run. When the consumer has stopped — `break`,
`return`, `?`, a labeled `break`, or a stage such as `take` that has
what it needs — `yield` does not return: the generator leaves at that
`yield` as if by `return`, releasing its scopes in reverse order before
control reaches the consumer's continuation. A generator cannot observe
or ignore a stop. `yield` appears only directly in a `gen fn` body, not
in a `fn` or closure nested in it. `return` in a generator ends the
sequence and takes no value.

**The consumer's control flow.** In the body of `for x in g:`,
`break`, `continue`, `return`, `?`, labeled `break` and `continue`, and
`.await` mean what they mean in any `for` body. They belong to the
consumer; the compiler carries them across the generator's call.

**Views.** A generator may yield a view of its own locals or of what
its arguments view. The consumer's body runs while the generator's
frame is live, so the view is valid for that run of the body and is not
retained past it (§21.1); keeping an element is spelled `.clone()`.

```
gen fn nonempty(lines: &Vec[str]) -> &str:
    for line in lines:
        if line.len() > 0:
            yield line                    // a view into the argument

gen fn labels(count: i32) -> &str:
    var buf = ""
    for i in 0..count:
        buf = f"item-{i}"
        yield &buf                        // a view of the generator's own local
```

**Resources.** A generator's resources live in its scopes. Its owned
locals, `with` scopes, and `defer`s are released when it returns, runs
off its end, or leaves at a stopped `yield` — including when the
consumer breaks early. A generator value dropped without being consumed
never ran; it releases only its arguments.

**Pulling.** Code that must step a sequence itself — `zip`, a parser
asking a lexer for one token, a partly consumed sequence kept in a
struct — spells `g.pull()`, which returns an owned `Iter[T]` that runs
the generator on its own fiber (§14.18) and resumes it at each
`next()`. Dropping the pulled iterator before the end stops the
generator exactly as a consumer's `break` does. `pull()` is spelled
because it allocates a fiber stack; it is unavailable in `no_runtime`
builds. A generator that yields views of its own locals, or whose body
may suspend (§14.3), cannot be pulled, because `next()` returns an
element its caller keeps; such a `pull()` is a compile error naming the
`yield` or the suspension point.

**Storing and sending.** A generator value holds only its arguments.
It is ephemeral when an argument is a view (§5.5), and otherwise it can
be stored, returned, and sent to another thread when its arguments are
`Send`.

**Compilation model.** A generator compiles to an ordinary function
that takes the consumer's body as a function argument; each `yield` is
a call to it. There is no state struct, no scheduler, and no
allocation, and generators work in `no_runtime` builds. The body of a
generator is ordinary code: a `.await` in it suspends the consumer's
fiber, and the generator's may-suspend effect is the consuming loop's
(§14.3).

### 13.5 For-In Loops

```
for item in collection:
    process(item)

for (i, item) in collection.enumerate():
    print(f"{i}: {item}")
```

The binding position is a full pattern, not just an identifier:

```
for (key, value) in map:
    print(f"{key} = {value}")

for { name, age, .. } in users:
    print(f"{name}: {age}")

for Some(item) in optional_items:
    process(item)
```

**Implicit iteration:** When the expression after `in` implements
`Iter[T]` directly (e.g., ranges, iterators), it is used as-is.
When it does not implement `Iter[T]` but has an `.iter()` method
that returns an `Iter[T]`, the compiler inserts `.iter()`
automatically:

```
// These are equivalent:
for item in my_vec:           // compiler inserts .iter()
for item in my_vec.iter():    // explicit (also valid)

// For place-based or consuming iteration, be explicit:
for item in my_vec.iter_place():  // yields VecSlot handles for in-place mutation
for item in my_vec.iter_ref():    // yields &T references (zero-copy)
for item in my_vec.into_iter():   // consuming (moves elements)
```

`for pattern in expr: body` desugars to calling `next()` in a loop.
The implicit `.iter()` insertion means `for x in collection:`
borrows the collection immutably — the collection remains valid
after the loop.

For a keyed map, `for (k, v) in map:` is `for (k, v) in map.iter():`, so
`k: &K` and `v: &V`. `for (k, v) in map.into_iter():` consumes the map and
binds `k: K`, `v: V`.

Pattern matching uses the same pattern language as `let` and `match`.
Irrefutable patterns bind every element. Refutable patterns are
allowed; elements that do not match are skipped and iteration
continues. Reference-pattern ergonomics (§9.7) apply here too, so
patterns over `.iter()` output usually bind references without
explicit `&`.

### 13.5a Labels, Labeled Break, and Continue


**A trailing labeled statement yields its tail value.** When a `'label:` statement is the last element of a block and its body ends in a value expression, that expression is the block's value (§29.13 composes with labels). A labeled block does not otherwise carry a value (there is no `break 'label value`); the value comes only from fall-through of its tail. (#640.)

Labels provide named control-flow targets within a function. A label
declaration is an identifier prefixed with a single quote:

```
'outer
'search
'L0
```

A label appears as the first token of a statement. It may precede any
statement: a block, a loop, a `let` or `var` binding, a `return`, an
expression statement, or another label. The label and the statement
it precedes are syntactically a single statement; the label does not
declare a new scope. A label may appear alone on a line and label the
next statement:

```
'top
if done:
    goto 'finish

'outer for row in grid:
    ...

'parse:
    ...

'finish return
```

A label has no trailing colon of its own. Labeled `while` and `for`
loops may use either colon-form or brace-form bodies; the body
introducer is the same `:` or `{ }` the loop would use without a
label. A labeled block uses a body directly after the label: `:` for
colon form or `{` for brace form.

Every label name must be unique within its function. The label
namespace is shared by `goto`, `break`, and `continue`, but is
separate from ordinary identifiers, types, and keywords. A variable
named `outer` and a label named `'outer` do not collide.

Labels are function-local control-flow targets. They are not visible
inside a nested `fn`, closure, `async:` block, or `gen fn` body.
`with` blocks are transparent for label scoping: a label declared
outside a `with` block remains visible inside the `with` body.

```
'outer for item in items:
    with item.acquire() as guard:
        if guard.is_done():
            break 'outer       // valid: with is label-transparent
```

The existing unlabeled forms are unchanged:

```
break       // exits the innermost enclosing loop
continue    // continues the innermost enclosing loop
```

`break` and `continue` also accept an optional label operand:

```
break 'outer       // exits the loop or block labeled 'outer
continue 'outer    // continues the loop labeled 'outer
```

Labeled `break` and `continue` are statements and have no value.
`break value` and `break 'label value` are valid when the targeted
construct is a `loop` (§13.5d), where they supply the loop's result
value. For `while`, `for`, `do`-`while`, and labeled blocks,
value-carrying break remains reserved for a future design and is
invalid in this version (those constructs can complete without
`break`, so they have no value to guarantee).

`break 'label` transfers control to the statement immediately after
the construct labeled `'label`. The target label must be declared on
a labeled `while`, labeled `for`, or labeled block that lexically
encloses the `break`.

`continue 'label` transfers control to the next iteration of the
loop labeled `'label`. For a `while` loop, this means the condition
check. For a `for` loop, this means the iterator-advance or
next-element step. For a `do`-`while` loop, this means the trailing
condition check (§13.5c). The target label must be declared on a
labeled `while`, `for`, or `do` that lexically encloses the
`continue`.

Labels on other statement forms are valid `goto` targets (§13.5b),
but they are not valid targets for `break` or `continue`.

Labeled blocks are statement-position only. They are not expressions,
and they do not produce a value. This is valid:

```
fn parse_header(input: bytes) -> Result[Header, Error]:
    'parse:
        if input.len() < 4: break 'parse
        let magic = input[0..4]
        if magic != EXPECTED_MAGIC: break 'parse
        return Ok(read_header(input))
    Err("malformed header")
```

This is not valid:

```
let result = 'parse:          // ERROR: labeled block is not an expression
    ...
```

A label token that is not the first token of a statement is a syntax
error:

```
if cond: 'outer while true:    // ERROR: label must start a statement
    tick()
```

A labeled `break` or `continue` exits every intervening scope between
the statement and the target. Cleanup is the same as for ordinary
structured control flow, repeated across each exited scope in reverse
entry order:

- `defer` blocks run.
- `Drop` destructors for owned values run.
- `with` guards are released.

`errdefer` blocks do not run for labeled `break` or `continue`,
because these are normal control transfers, not error returns.

The compiler must diagnose at least these errors:

- Duplicate label name in the same function.
- Undefined label.
- `break` targeting a label that is not on an enclosing loop or block.
- `continue` targeting a label that is not on an enclosing loop.
- Label token not at the start of a statement.
- Label use across a nested function, closure, `async:`, or `gen fn`
  boundary.

A label that is not targeted by `goto`, `break`, or `continue`
produces an `unused-label` warning. Labels exist to name control-flow
targets; code that wants to name a construct purely for readability
should use a comment.

### 13.5b Goto Statement

`goto` transfers control unconditionally to a labeled statement
within the same function:

```
goto 'label
```

Conditional gotos are written by composition with `if`:

```
if cond: goto 'label
```

Example:

```
fn example:
    var i = 0
    'top
    if i >= 10:
        goto 'done
    process(i)
    i = i + 1
    goto 'top
    'done
    print("finished")
```

The compiler rejects any `goto` that violates these static
restrictions:

**Function-local.** The target label must be declared in the same
function as the `goto` statement. `goto` cannot cross function,
closure, `async:`, or `gen fn` boundaries.

**No entry into a block from outside.** The target label's enclosing
scope chain must be a prefix of the goto site's enclosing scope
chain. Equivalently, a `goto` may exit scopes, but it may not enter a
scope that is not already active at the goto site.

This forbids jumping from outside a loop into the loop body, jumping
from one branch of an `if` into the other branch, and jumping from
outside a `match` into one of its arms.

**No skipping of variable initialization.** A `goto` must not jump
over a binding declaration when that binding would be in scope at the
target. Otherwise the target scope could observe, drop, or assign over
a value that was never initialized.

When a `goto` exits one or more scopes, cleanup is identical to
falling out of those scopes normally or to an equivalent labeled
`break`:

- `defer` blocks run.
- `Drop` destructors for owned values run.
- `with` guards are released.

`errdefer` blocks do not run for `goto`, because `goto` is a normal
control transfer, not an error return.

A backward `goto` to a point before a local binding's declaration ends
that binding's current lifetime before the jump. Its cleanup runs
before control transfers, and the binding is initialized again if
execution later reaches its declaration.

The compiler must diagnose at least these errors:

- Undefined target label.
- Target label declared outside the current function.
- `goto` across a nested function, closure, `async:`, or `gen fn`
  boundary.
- `goto` that would enter a block from outside.
- `goto` that would skip variable initialization.

`with migrate` may emit `goto` when C source contains control flow
that cannot be expressed with structured constructs, such as an
irreducible control-flow graph. For reducible C, the migrator should
prefer structured With using `while`, `do`-`while` (§13.5c), `if`,
labeled `break`, and labeled `continue`. In particular, C
`do { ... } while (cond)` loops should be translated directly to
With `do: ... while cond`, preserving `continue`-to-condition
semantics. For irreducible C, each basic block may become a
labeled statement at function scope, and each control-flow edge may
become a `goto` or conditional `goto`.

Computed goto (`goto *ptr`) and non-local jumps such as
`setjmp`/`longjmp` are not supported. If `with migrate` encounters a
function that requires one of those patterns, it must emit a
diagnostic naming the function and source location, produce no
misleading placeholder translation, and exit non-zero.

### 13.5c `do`-`while` Loop

A `do`-`while` loop executes its body at least once, then repeats
while the trailing condition is true.

```
do_loop := 'do' body 'while' condition
```

The body uses the standard three forms:

```
// Indented colon
do:
    stmt1
    stmt2
while condition

// Braced
do {
    stmt1
    stmt2
} while condition

// Inline colon (single statement)
do: stmt
while condition
```

The `while` keyword following the body introduces the loop
condition. It is not a separate `while` loop — the parser
recognizes `while` at the same nesting level as `do` as the
loop's trailing condition, not as a new statement.

No colon or brace follows the trailing `while` — the condition
is a single expression terminated by a newline or the end of the
enclosing block.

**Semantics:**

1. The body executes unconditionally on the first iteration.
2. After each iteration, the condition is evaluated.
3. If the condition is true, the body executes again.
4. If the condition is false, the loop exits.

`break` exits the loop immediately.

`continue` jumps to the **condition check**, not to the top of
the body. This matches C semantics: any side-effects in the
condition expression are executed on every `continue`.

```
// Equivalent to C: do { ... continue; ... } while (*(++p))
var p = start
do:
    if should_skip:
        continue        // jumps to the while condition below
    process(p)
while { p = p + 1; unsafe *p != 0 }
```

**Labeled form:**

`do` loops may be labeled for use with `break` and `continue`:

```
'outer do:
    'inner do:
        if done: break 'outer
        if skip: continue 'inner
        process()
    while inner_condition
while outer_condition
```

**Type:**

A `do`-`while` loop is a statement. It does not produce a value.
Unlike `loop` (which can produce a value via `break expr`), a
`do`-`while` loop always evaluates to `Unit`.

**Condition with side-effects:**

The trailing condition may contain side-effects. When the
condition is a block expression (braced), all statements in the
block execute before the truthiness of the final expression
determines whether to continue looping:

```
do:
    process(current)
while { current = current.next; current != null }
```

This is the direct translation of C's:

```c
do {
    process(current);
} while ((current = current->next) != NULL);
```

When the condition is a simple expression, it is evaluated
normally:

```
do:
    attempt()
while retry_count > 0
```

**Desugaring:**

The compiler treats `do`-`while` as a primitive loop form, not
as syntactic sugar over `loop`. This ensures `continue` has the
correct target (the condition check, not the body top).

Conceptually, the semantics are equivalent to:

```
loop:
    body
    if not condition: break
```

except that `continue` anywhere in `body` jumps to the condition
evaluation, not to the top of `loop`. This distinction only
matters when the body contains `continue` statements.

**Interaction with `defer` and `errdefer`:**

`defer` statements inside the body execute at scope exit as
usual — either when the loop exits via `break`, when the
enclosing function returns, or at the end of a braced body on
each iteration.

`errdefer` follows the same scoping rules as in other loop
bodies.

**Examples:**

Retry loop:

```
var attempts = 0
do:
    attempts = attempts + 1
    let result = try_connect(host)
    if result.is_ok():
        return result
while attempts < max_retries
return Err(.MaxRetriesExceeded)
```

Processing a non-empty list:

```
var node = list.head
do:
    process(node.value)
    node = node.next
while node != null
```

Iterator with lookahead:

```
var p = start
do:
    let ch = unsafe *p
    if ch == delimiter: break
    buffer.push(ch)
while { p = p + 1; p < end }
```

C migration — PCRE2 list iteration:

C source:
```c
do {
    if (*list < new_start) {
        if (*list + 1 == new_start) { new_start--; continue; }
    } else if (*list > new_end) {
        if (*list - 1 == new_end) { new_end++; continue; }
    } else {
        continue;
    }
    result += 2;
    if (buffer != NULL) {
        buffer[0] = *list;
        buffer[1] = *list;
        buffer += 2;
    }
} while (*(++list) != NOTACHAR);
```

With translation:
```
do:
    if (unsafe *list) < new_start:
        if (unsafe *list) + 1 == new_start:
            new_start = new_start - 1
            continue
    else if (unsafe *list) > new_end:
        if (unsafe *list) - 1 == new_end:
            new_end = new_end + 1
            continue
    else:
        continue
    result = result + 2
    if buffer != null:
        unsafe buffer[0] = unsafe *list
        unsafe buffer[1] = unsafe *list
        buffer = buffer + 2
while { list = list + 1; (unsafe *list) != NOTACHAR }
```

No `goto` required. `continue` correctly jumps to the `while`
condition, which increments `list` and checks the terminator.

### 13.5d The `loop` Construct

`loop` is the infinite loop. It supports the three standard body
forms (§29.13) and may be labeled (§13.5a):

```
loop:
    tick()
    if done(): break

'outer loop { poll(); if quit(): break 'outer }
```

**`loop` is an expression.** `break expr` supplies its value; plain
`break` supplies `Unit`. The loop's type is the unified type of its
`break` values. A `loop` with no reachable `break` has type `Never`
and may appear anywhere a diverging expression is valid:

```
let session = loop:
    let attempt = try_connect(host)
    if attempt.is_ok():
        break attempt.unwrap()      // loop evaluates to Connection
    sleep(backoff()).await

fn serve -> Never:
    loop:
        accept_and_handle()         // no break: type is Never
```

`break 'label expr` targets a labeled `loop` the same way. All
`break` values within one loop must unify to a single type (plain
`break` contributes `Unit`); mixing valued and plain breaks where the
type is not `Unit` is a compile error. `continue` behaves as in other
loops. `while`, `for`, and `do`-`while` loops are statements and do
not produce values (§13.5a, §13.5c).

### 13.6 Collection Comprehensions

Comprehensions build collections from iteration with filtering.
There is **one comprehension family, polymorphic over its target
collection** (the Scala lesson: don't invent a syntax per container).
The element form builds sequences and sets; the `key: value` form
builds maps. The target is selected by expected type — the same
inference rule as enum variant shorthand (§4.4) and numeric literals
(§4.2.1) — with `Vec` and `HashMap` as the defaults:

```
let squares = [x * x for x in 0..10]
// Vec[i32]: [0, 1, 4, 9, 16, 25, 36, 49, 64, 81]

let evens = [x for x in 0..100 if x % 2 == 0]
// Vec[i32]: [0, 2, 4, ..., 98]

let coords = [(x, y) for x in 0..3 for y in 0..3 if x != y]
// Vec[(i32, i32)]: [(0,1), (0,2), (1,0), (1,2), (2,0), (2,1)]

// Expected type selects the target collection:
let words: HashSet[str] = [w.clone() for w in tokens]
let ordered: BTreeSet[i32] = [x for x in xs if x > 0]

// Map form: key-colon-value builds a map (HashMap by default)
let index = [w.clone(): i for (i, w) in vocab.enumerate()]
let sorted_index: BTreeMap[str, i32] = [w.clone(): i for (i, w) in vocab.enumerate()]
```

An element, key or value expression is an owned-value demand (§3.8,
D22): a view of a Copy type materializes; a view of any other type is
cloned explicitly (D45).

**Desugaring:**

```
[expr for x in iter if cond]
// →
iter |> filter(x => cond) |> map(x => expr) |> collect[C]()
// where C is the expected collection type, defaulting to Vec

[k_expr: v_expr for x in iter if cond]
// →
iter |> filter(x => cond) |> map(x => (k_expr, v_expr)) |> collect[M]()
// where M is the expected map type, defaulting to HashMap
```

Yes, this allocates. It's obvious from the syntax — you're building
a collection. This is the same philosophy as string interpolation:
the allocation is inherent to what you're asking for, and the syntax
makes it clear.

Comprehensions are pure sugar over the pipeline operations of §13.3
and `collect[C]` — the same machinery, three altitudes: literals
(§4.3c) for known elements, comprehensions for shaped iteration,
pipelines for everything else. For lazy evaluation, use pipeline
syntax with iterators directly.

For duplicate keys in a map comprehension, later elements win
(last-write semantics, matching repeated `insert`).

**Disambiguation with `in` operator:** In comprehensions, `for x in`
is always the iteration form (`Iter` trait). The `in` membership
operator (§9.9) may appear in the `if` filter clause:

```
[x for x in 0..100 if x in primes]  // for-in loop + membership test in filter
```

The parser resolves this structurally — `for PATTERN in EXPR` is
always iteration, `EXPR in EXPR` in the filter is always membership.

### 13.6a Option and Result For-Comprehensions

`for` can also express short-circuiting chains over `Option` and
`Result`. Clauses are separated by `;`. Each binding clause unwraps
one successful value and binds it for the following clauses.

```
let name: Option[str] =
    for user in get_user(id);
        profile in get_profile(user):
    yield profile.display_name

let data: Result[Response, Error] =
    for conn in connect(host);
        auth in conn.authenticate(token);
        resp in auth.fetch(path):
    yield resp
```

The first clause determines the carrier family:

- `Option[T]` comprehensions unwrap `Some(...)` and short-circuit on
  `None`.
- `Result[T, E]` comprehensions unwrap `Ok(...)` and short-circuit on
  `Err(...)`.

The expression form ends with `yield expr`, which re-wraps the final
value in `Some(...)` or `Ok(...)`. The statement form omits `yield`
and runs its body only when every clause succeeds:

```
for user in get_user(id); profile in get_profile(user):
    update_profile(profile)
```

This is equivalent to nested `match` expressions over the relevant
success and failure constructors.

Option comprehensions also support boolean guard clauses:

```
let active_name =
    for user in get_user(id);
        if user.is_active();
        profile in get_profile(user):
    yield profile.name
```

If the guard is false, the comprehension produces `None`. `Result`
comprehensions do not have an implicit guard-failure error value; use
an explicit `if`/`match` inside the comprehension body when guard
failure must choose an `Err`.

---
