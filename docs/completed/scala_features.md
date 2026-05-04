# Scala-Inspired Features — Specification & Implementation Notes

*Tail call optimization, currying, named arguments, for-comprehensions,
tuple destructuring in for loops.*

---

## 1. Tail Call Optimization

### 1.1 Specification

A function call in tail position reuses the current stack frame instead
of allocating a new one. This turns recursion into iteration with zero
stack growth.

**Tail position** means the call is the last operation before returning —
no further computation on the result:

```
// Tail call — result of factorial_acc is returned directly
fn factorial_acc(n: i32, acc: i32) -> i32:
    if n <= 1: acc
    else: factorial_acc(n - 1, n * acc)    // tail position

// NOT tail call — multiplication happens after the recursive call
fn factorial(n: i32) -> i32:
    if n <= 1: 1
    else: n * factorial(n - 1)             // not tail position
```

**`@[tailrec]` annotation:** Opt-in guarantee that the compiler MUST
optimize the tail call, or emit a compile error if it can't:

```
@[tailrec]
fn sum_to(n: i32, acc: i32) -> i32:
    if n <= 0: acc
    else: sum_to(n - 1, acc + n)           // guaranteed: no stack growth

@[tailrec]
fn bad(n: i32) -> i32:
    if n <= 0: 0
    else: 1 + bad(n - 1)                   // ERROR: call not in tail position
```

Without the annotation, the compiler optimizes tail calls silently when
it detects them. The annotation is for when the programmer NEEDS the
guarantee (infinite recursion by design, like event loops or state
machine drivers).

**What counts as tail position:**

- The return expression of a function body
- The last expression in a block that is itself in tail position
- Both branches of an `if`/`else` in tail position
- Every arm of a `match` in tail position
- The body of a `for`/`while`/`loop` is NOT tail position (the loop continues)
- Calls inside `defer` blocks are NOT tail position

**Mutual tail calls:** Two functions calling each other in tail position:

```
@[tailrec]
fn even(n: i32) -> bool:
    if n == 0: true
    else: odd(n - 1)

@[tailrec]
fn odd(n: i32) -> bool:
    if n == 0: false
    else: even(n - 1)
```

Mutual tail calls require both functions to be marked `@[tailrec]`.
The compiler may implement these via a trampoline or by merging the
functions into a single loop with a dispatch tag.

### 1.2 Implementation Notes

**Detection (MIR level):**

In MirLower.w, after lowering a function body, scan all `TermKind.TK_CALL`
terminators. A call is in tail position if:

1. The call's result place is the function's return place (`_0`)
2. The terminator's next block contains only a `TK_RETURN`
3. No `defer` or `errdefer` is active in the current scope
4. No destructors need to run after the call (no Drop-implementing locals live across the call)

**Lowering (self-tail calls):**

For direct self-recursion (the common case), replace the tail call with:

1. Copy arguments to the function's parameter locals
2. Jump to the function's entry block

This is a simple MIR → MIR transformation:

```
// Before:
bb5:
    _0 = call factorial_acc(_3, _4)
    goto bb6
bb6:
    return

// After:
bb5:
    _1 = copy _3        // reassign param 'n'
    _2 = copy _4        // reassign param 'acc'
    goto bb0             // jump to entry
```

**Lowering (mutual tail calls):**

For mutual recursion, use a trampoline. Merge both functions into one
with a discriminant:

```
// Conceptual transform:
fn _even_odd_trampoline(tag: i32, n: i32) -> bool:
    loop:
        if tag == 0:     // even
            if n == 0: return true
            tag = 1; n = n - 1
        else:            // odd
            if n == 0: return false
            tag = 0; n = n - 1
```

This is more complex and can be deferred to post-launch. Self-tail calls
cover 95% of the use cases.

**LLVM `musttail`:** LLVM supports `musttail call` which guarantees
tail call optimization at the IR level. Use this when:
- Caller and callee have the same signature (self-recursion)
- The call is the last instruction before `ret`

For self-recursion, the MIR-to-loop transform is simpler and doesn't
depend on LLVM's tail call support. Use `musttail` only for mutual
tail calls where the trampoline isn't viable.

**`@[tailrec]` enforcement:**

In Sema or MirLower, when a function has the `tailrec` attribute:

1. Find all recursive calls (calls to self or to other `@[tailrec]` functions)
2. Check that each is in tail position (using the criteria above)
3. If any recursive call is NOT in tail position, emit a compile error:

```
error: recursive call is not in tail position
src/foo.w:5:10
5 |     1 + sum_to(n - 1, acc)
  |         ^^^^^^^^^^^^^^^^^^
  = note: function is annotated @[tailrec]
  = help: ensure the recursive call is the last operation before returning
```

**Files:**

| File | Change |
|------|--------|
| `src/Ast.w` | Add attribute recognition for `tailrec` |
| `src/MirLower.w` | Tail call detection + self-call → loop transform |
| `src/Sema.w` or `src/SemaCheck.w` | `@[tailrec]` enforcement |
| `src/Codegen.w` | Emit `musttail` for mutual calls (optional) |

**Estimated scope:** ~200 lines for self-tail calls. ~400 more for mutual.

---

## 2. Currying / Partial Application

### 2.1 Specification

A function call with `_` placeholders produces a closure that captures
the provided arguments and takes the remaining ones as parameters:

```
fn add(a: i32, b: i32) -> i32: a + b

let add5 = add(5, _)           // fn(i32) -> i32
let result = add5(3)           // 8

fn clamp(lo: i32, hi: i32, val: i32) -> i32:
    if val < lo: lo
    else if val > hi: hi
    else: val

let clamp_byte = clamp(0, 255, _)    // fn(i32) -> i32
let clamped = clamp_byte(300)        // 255
```

**Multiple placeholders** produce multi-argument closures. Arguments
are filled left-to-right in placeholder order:

```
let swap_sub = sub(_, _)       // fn(i32, i32) -> i32 — identity
let f = foo(1, _, 3, _)        // fn(T2, T4) -> R
f(20, 40)                      // foo(1, 20, 3, 40)
```

**Method partial application** works the same way:

```
let items: Vec[i32] = Vec.from([1, 2, 3, 4, 5])
let big = items.filter(clamp(3, 5, _) == _)
// or more commonly:
let squares = items.map(mul(_, _))
```

**Partial application is NOT currying.** Haskell-style automatic
currying (`add 5` without `_`) is not supported. Every partial
application requires explicit `_` placeholders. This keeps the call
syntax unambiguous — you always know whether a function is being called
or partially applied by looking at the call site.

**Type inference:** The closure's parameter types are inferred from the
function signature. The closure's return type matches the original
function's return type. No annotation needed.

**Restrictions:**

- `_` is only valid inside function call argument lists
- `_` cannot appear in the callee position: `_(1, 2)` is an error
- `_` in non-call positions (let bindings, patterns) retains its
  existing meaning (discard / wildcard)
- Variadic extern functions cannot be partially applied

### 2.2 Implementation Notes

**Parser:**

In `parse_call_args`, when the parser sees `TK_UNDERSCORE` in argument
position, record it as a placeholder node (`NK_PARTIAL_ARG` or reuse
`NK_WILDCARD`). Count the number of placeholders.

If any argument is a placeholder, the entire call expression becomes
`NK_PARTIAL_CALL` instead of `NK_CALL`.

**Sema:**

When checking an `NK_PARTIAL_CALL`:

1. Resolve the callee type and get its parameter types
2. For each `_` placeholder, record the parameter type at that position
3. Synthesize a closure type: `fn(placeholder_types...) -> return_type`
4. Type-check the non-placeholder arguments against their parameter types
5. The expression's type is the synthesized closure type

**MIR lowering:**

Desugar `NK_PARTIAL_CALL` into a closure construction:

```
// add(5, _) desugars to:
// (captured_a) => { |x| add(captured_a, x) }

// Concretely in MIR:
let closure_env = alloc { a: 5 }
let closure = make_closure(closure_fn, closure_env)
// where closure_fn(env, x) = add(env.a, x)
```

The closure function is a synthetic function generated during MIR lowering.
It loads captured values from the environment struct and calls the original
function with all arguments filled in.

**Files:**

| File | Change |
|------|--------|
| `src/Parser.w` | Detect `_` in call args, emit `NK_PARTIAL_CALL` |
| `src/Ast.w` | Add `NK_PARTIAL_CALL` node kind (or flag on `NK_CALL`) |
| `src/SemaCheck.w` | Type-check partial calls, synthesize closure type |
| `src/MirLower.w` | Desugar to closure construction + synthetic function |

**Estimated scope:** ~300 lines across parser, sema, and MIR lowering.

---

## 3. Named Arguments at Call Sites

### 3.1 Specification

Function arguments can be passed by name instead of by position:

```
fn connect(host: str, port: u16, timeout: i32 = 30) -> Connection:
    ...

// Positional (existing):
connect("localhost", 8080, 60)

// Named:
connect(host: "localhost", port: 8080, timeout: 60)

// Mixed — positional first, then named:
connect("localhost", port: 8080, timeout: 60)

// Named arguments can be in any order:
connect(timeout: 60, host: "localhost", port: 8080)
```

**Rules:**

1. Named arguments must come after all positional arguments
2. A parameter cannot be specified both positionally and by name
3. The names must match the function's parameter names exactly
4. Named arguments can be in any order relative to each other
5. Default parameters can be skipped when using named arguments:
   `connect(host: "localhost", port: 8080)` — timeout gets its default

**Named arguments work with methods:**

```
let conn = server.connect(port: 8080, timeout: 10)
```

**Named arguments do NOT work with:**
- Extern functions (C doesn't have named params, and names may not match)
- Closures (closure parameters don't have externally meaningful names)
- Partial application placeholders (use positional `_` instead)

### 3.2 Implementation Notes

**Parser:**

In `parse_call_args`, when the parser sees `TK_IDENT TK_COLON` followed
by an expression (and the ident is not a type name), treat it as a
named argument. Store the name symbol alongside the argument node.

This reuses the same `name: expr` pattern as struct literals. The
disambiguation: inside `fn_name(...)` it's a named argument; inside
`TypeName { ... }` it's a field initializer. The parser already knows
which context it's in.

**AST representation:**

Add a sidecar for call nodes that have named arguments:

```
// In AstPool:
call_named_arg_syms: Vec[i32]    // name symbols for named args
call_named_arg_starts: Vec[i32]  // per-call start into syms vec
call_named_arg_counts: Vec[i32]  // per-call count
```

Or simpler: store a flag on the call node that says "has named args,"
and store the names in the extra pool interleaved with the argument nodes.

**Sema:**

When checking a call with named arguments:

1. Split arguments into positional (no name) and named (with name)
2. Verify positional arguments come first
3. For each named argument, find the matching parameter by name
4. Check that no parameter is assigned twice
5. Fill in defaults for unmentioned parameters with defaults
6. Reorder the argument list to match parameter order
7. Type-check each argument against its resolved parameter type

**MIR lowering:**

By the time MIR sees the call, sema has already reordered the arguments
to match parameter order. MIR lowering doesn't need to know about named
arguments at all — it sees a normal call with arguments in the right order.

**Files:**

| File | Change |
|------|--------|
| `src/Parser.w` | Detect `ident: expr` in call args |
| `src/Ast.w` | Sidecar storage for named arg symbols |
| `src/SemaCheck.w` | Reorder + validate named arguments |

**Estimated scope:** ~200 lines. No MIR or codegen changes needed.

---

## 4. For-Comprehensions over Option/Result

### 4.1 Specification

`for`/`in` with `yield` chains operations that return `Option` or
`Result`, short-circuiting on `None` or `Err`:

```
// Option chaining:
let name: ?str = for user in get_user(id);
                     profile in get_profile(user);
                     settings in profile.settings():
    yield settings.display_name

// Equivalent to:
let name: ?str = match get_user(id)
    Some(user) => match get_profile(user)
        Some(profile) => match profile.settings()
            Some(settings) => Some(settings.display_name)
            None => None
        None => None
    None => None
```

**Result chaining:**

```
let data: Result[Response, Error] =
    for conn in connect(host);
        auth in conn.authenticate(token);
        resp in auth.fetch(path):
    yield resp

// Short-circuits on the first Err, propagating it
```

**With guards:**

```
let result = for user in get_user(id);
                 if user.is_active();
                 profile in get_profile(user):
    yield profile.name

// Guard failure returns None (for Option) or Err (for Result)
```

**Syntax:**

```
for BINDING in EXPR; BINDING in EXPR; ...:
    yield RESULT_EXPR
```

Each `;`-separated binding unwraps the previous expression. If any
step returns `None` or `Err`, the entire comprehension short-circuits
with that failure value.

The `yield` keyword indicates this is a comprehension (producing a
wrapped value), not a loop. The result type is `Option[T]` or
`Result[T, E]` matching the type of the chained expressions.

**Without yield — imperative chaining:**

```
for user in get_user(id); profile in get_profile(user):
    update_profile(profile)
// Returns Option[void] — None if any step failed
```

### 4.2 Implementation Notes

**Parser:**

Extend `parse_for` to recognize `;`-separated bindings before the `:`
body. When multiple bindings are present and the body starts with
`yield`, this is a comprehension, not a loop.

Alternatively, parse it as sugar and desugar immediately in the parser
to nested `match` expressions. This avoids adding a new AST node.

**Desugaring (recommended approach):**

Transform in the parser or in a dedicated desugar pass:

```
// Input:
for x in a(); y in b(x): yield f(x, y)

// Desugared to:
match a()
    Some(x) => match b(x)
        Some(y) => Some(f(x, y))
        None => None
    None => None
```

For `Result`:

```
// Input:
for x in a(); y in b(x): yield f(x, y)

// Desugared to:
match a()
    Ok(x) => match b(x)
        Ok(y) => Ok(f(x, y))
        Err(e) => Err(e)
    Err(e) => Err(e)
```

The desugaring choice (Option vs Result) is determined by the type of
the first binding's expression, resolved during sema.

**Guards desugar to conditional None/Err:**

```
// Input:
for x in a(); if pred(x); y in b(x): yield f(x, y)

// Desugared to:
match a()
    Some(x) =>
        if pred(x):
            match b(x)
                Some(y) => Some(f(x, y))
                None => None
        else:
            None
    None => None
```

**Files:**

| File | Change |
|------|--------|
| `src/Parser.w` | Multi-binding `for` + `yield` detection |
| `src/Parser.w` or `src/Desugar.w` | Nested match desugaring |
| `src/SemaCheck.w` | Determine Option vs Result from first binding type |

**Estimated scope:** ~250 lines. Desugaring in the parser keeps sema
and MIR completely unaware of comprehensions.

---

## 5. Tuple Destructuring in For Loops

### 5.1 Specification

For loops can destructure tuples and pairs directly in the binding:

```
let pairs = [(1, "one"), (2, "two"), (3, "three")]

for (num, name) in pairs:
    print(f"{num}: {name}")

// HashMap iteration:
for (key, value) in map:
    print(f"{key} = {value}")

// With index:
for (i, item) in items.enumerate():
    print(f"[{i}] {item}")

// Nested destructuring:
for (a, (b, c)) in nested_pairs:
    print(f"{a} {b} {c}")
```

**Underscore for ignored elements:**

```
for (_, value) in map:
    process(value)

for (key, _) in map:
    print(key)
```

**Pattern matching in for bindings:**

```
// Only iterate over Some values:
for Some(item) in optional_items:
    process(item)

// Destructure enum payloads:
for Ok(value) in results:
    accumulate(value)
```

### 5.2 Implementation Notes

**Parser:**

In `parse_for`, after parsing `for`, check if the next token is
`TK_L_PAREN`. If so, parse a tuple pattern instead of a single
binding identifier:

```
// Current:
for IDENT in EXPR:

// Extended:
for PATTERN in EXPR:
```

The pattern parsing reuses `parse_pattern` which already handles
tuple patterns, nested patterns, wildcards, and variant patterns.

**Sema:**

When checking a for loop with a pattern binding:

1. Resolve the iterator element type
2. Check the pattern against the element type (reuse match pattern checking)
3. Bind the pattern variables into the loop body's scope

This is the same logic as `let (a, b) = expr` destructuring, which
already works in With. The for loop just needs to use the same path.

**MIR lowering:**

In `lower_for`, after evaluating the iterator's `.next()` call:

1. If the binding is a simple identifier, bind directly (existing path)
2. If the binding is a pattern, lower as pattern match against the
   element value (reuse `lower_pattern`)

**Files:**

| File | Change |
|------|--------|
| `src/Parser.w` | Accept patterns in for binding position |
| `src/SemaCheck.w` | Check pattern against iterator element type |
| `src/MirLower.w` | Pattern destructuring in for loop body |

**Estimated scope:** ~80 lines. Most of the machinery already exists
for `match` and `let` destructuring.

---

## 6. Summary

| Feature | Parser | Sema | MIR | Codegen | Est. Lines |
|---------|--------|------|-----|---------|-----------|
| Tail call optimization | Attribute | Enforcement | Detection + transform | `musttail` (optional) | ~200-600 |
| Partial application | `_` in calls | Closure synthesis | Desugar to closure | None | ~300 |
| Named arguments | `name: expr` | Reorder + validate | None | None | ~200 |
| For-comprehensions | Multi-bind + yield | Option/Result dispatch | None (desugared) | None | ~250 |
| Tuple destructuring in for | Pattern in binding | Pattern check | Pattern lower | None | ~80 |
| **Total** | | | | | **~1,030-1,430** |

## 7. Implementation Order

```
1. Tuple destructuring in for     — smallest, reuses existing pattern infra
2. Named arguments                — parser + sema only, no MIR/codegen
3. Partial application (currying) — requires closure synthesis
4. Tail call optimization (self)  — MIR transform, most impactful
5. For-comprehensions             — parser desugaring, depends on Option/Result types
6. Tail call optimization (mutual)— trampoline, defer post-launch
```

Start with the features that touch fewer compiler phases. Tuple
destructuring and named arguments are parser+sema changes that don't
affect MIR or codegen at all. Partial application and TCO require MIR
work but build on existing closure and control flow infrastructure.
For-comprehensions are pure sugar that desugars in the parser.

---

*Scala-inspired features — v1.0*