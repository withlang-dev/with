# With Language Additions
# Unified Specification & Implementation Notes

Fourteen language features organized by compiler phase. Each
feature includes specification, surface syntax, grammar changes,
implementation notes, and scope estimate.

**Design priorities:**
1. Ergonomic — familiar to developers from Python, Scala, and
   Rust backgrounds
2. Efficient — zero hidden cost, no runtime overhead beyond the
   operation itself

**Design constraint:** Function-first. All canonical APIs are free
functions. Methods via `impl` are convenience aliases.

---

# Phase A: Parser-Only Changes

These features are pure parser sugar. They desugar into existing
AST constructs. Sema, MIR, and codegen are unaware of them.

---

## F1. Tuple Destructuring in For Loops

### Specification

For loops accept patterns in binding position, not just identifiers:

```
for (key, value) in map:
    println(f"{key} = {value}")

for (i, item) in items.enumerate():
    println(f"[{i}] {item}")

for (a, (b, c)) in nested_pairs:
    println(f"{a} {b} {c}")

for (_, value) in map:
    process(value)

for Some(item) in optional_items:
    process(item)
```

### Grammar

```
// Current:
for_stmt = 'for' IDENT 'in' expr ':' block

// New:
for_stmt = 'for' pattern 'in' expr ':' block
```

The `pattern` production already exists for `match` and `let`
destructuring. Reuse it.

### Implementation

**Parser:** In `parse_for`, after `for`, check if the next token
is `(` or a variant constructor. If so, parse a pattern instead
of a single identifier.

**Sema:** Check the pattern against the iterator element type.
Reuse `check_pattern` from match arm checking.

**MIR:** In `lower_for`, after evaluating `.next()`, if the binding
is a pattern, lower with `lower_pattern` instead of direct binding.

### Scope

Parser: ~20 lines. Sema: ~30 lines. MIR: ~30 lines. Total: ~80 lines.

---

## F2. Chained Comparisons

### Specification

Chains of comparison operators desugar into conjunctions of
pairwise comparisons:

```
let valid = 0.0 < x < 1.0      // (0.0 < x) & (x < 1.0)
let in_range = lo <= x <= hi    // (lo <= x) & (x <= hi)
let sorted = a < b < c < d     // (a < b) & (b < c) & (c < d)
```

Interior operands are evaluated once. Non-trivial expressions
get a compiler-introduced temporary:

```
a < f(x) < c
→ let __tmp = f(x); (a < __tmp) & (__tmp < c)
```

### Grammar

```
// Current:
comparison = additive ( comp_op additive )?

// New:
comparison = additive ( comp_op additive )*
```

### Desugaring

If more than one comparison is parsed:

```
a < b < c
→ NK_AND(NK_LT(a, b), NK_LT(b, c))
```

The `&` is elementwise AND for types that implement it (e.g.,
boolean arrays) and logical AND for scalar bools.

### Implementation

Parser only. Sema sees standard comparison and AND nodes.

### Scope

Parser: ~30 lines.

---

## F3. For-Comprehensions over Option/Result

### Specification

`for`/`in` with `yield` chains operations that return `Option` or
`Result`, short-circuiting on `None` or `Err`:

```
let name: ?str = for user in get_user(id);
                     profile in get_profile(user);
                     settings in profile.settings():
    yield settings.display_name
```

Equivalent to nested `match`:

```
match get_user(id):
    Some(user) => match get_profile(user):
        Some(profile) => match profile.settings():
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
```

**With guards:**

```
let result = for user in get_user(id);
                 if user.is_active();
                 profile in get_profile(user):
    yield profile.name
```

Guard failure returns `None` (for Option) or `Err` (for Result).

**Without yield — imperative chaining:**

```
for user in get_user(id); profile in get_profile(user):
    update_profile(profile)
```

### Syntax

```
for BINDING in EXPR; BINDING in EXPR; ...:
    yield RESULT_EXPR
```

`;`-separated bindings. `yield` marks a comprehension (not a loop).

### Desugaring

Desugar in the parser to nested `match`:

```
for x in a(); y in b(x): yield f(x, y)
→
match a():
    Some(x) => match b(x):
        Some(y) => Some(f(x, y))
        None => None
    None => None
```

For `Result`:

```
match a():
    Ok(x) => match b(x):
        Ok(y) => Ok(f(x, y))
        Err(e) => Err(e)
    Err(e) => Err(e)
```

Guards desugar to conditional `None`/`Err`:

```
for x in a(); if pred(x); y in b(x): yield f(x, y)
→
match a():
    Some(x) =>
        if pred(x):
            match b(x):
                Some(y) => Some(f(x, y))
                None => None
        else: None
    None => None
```

Whether to desugar as Option or Result is determined by the type
of the first binding's expression, resolved during sema. The parser
emits a generic desugared form; sema rewrites `Some`/`None` to
`Ok`/`Err` if the first expression returns `Result`.

### Implementation

Parser: multi-binding `for` detection, `yield` keyword, nested
match generation. Sema: Option vs Result dispatch on first binding
type. MIR/codegen: unaware.

### Scope

Parser: ~180 lines. Sema: ~70 lines. Total: ~250 lines.

---

# Phase B: Parser + Sema Changes

These features require both grammar extensions and semantic
analysis work but do not change MIR or codegen.

---

## F4. Named Arguments and Default Values

### Specification

Function arguments can be passed by name. Parameters can declare
default values:

```
fn connect(host: str, port: u16, timeout: i32 = 30) -> Connection

// Positional:
connect("localhost", 8080, 60)

// Named:
connect(host: "localhost", port: 8080, timeout: 60)

// Mixed — positional first, then named:
connect("localhost", port: 8080)

// Named in any order:
connect(timeout: 60, host: "localhost", port: 8080)

// Defaults skipped:
connect(host: "localhost", port: 8080)  // timeout = 30
```

### Rules

1. Named args must come after all positional args.
2. A parameter cannot be specified both positionally and by name.
3. Names must match parameter names exactly.
4. Named args can appear in any order relative to each other.
5. Default parameters can be skipped when using named args.
6. Default expressions are evaluated at the call site on each
   call where the argument is omitted.
7. Named args do NOT work with: extern functions, closures,
   or partial application placeholders.

### Grammar

Call arguments:

```
arg = expr | IDENT ':' expr
```

Function parameters:

```
param = IDENT ':' type ( '=' expr )?
```

### Parser

When parsing call arguments: if the parser sees `IDENT ':'` followed
by an expression (and the identifier is not a type name), treat it
as a named argument. Store the name symbol alongside the argument
node.

When parsing function parameters: if `=` follows the type
annotation, parse the default value expression.

Disambiguation from struct literals: inside `fn_name(...)` it's
a named argument; inside `TypeName { ... }` it's a field init.
The parser already knows which context it's in.

### Sema

**Call resolution:**
1. Match positional arguments left-to-right.
2. Match named arguments by name (order-independent).
3. Verify no parameter assigned twice.
4. Fill unmentioned parameters from defaults.
5. Fill implicit parameters from scope (see F6).
6. Any unmatched non-default, non-implicit parameter → error.
7. Reorder argument list to match parameter order.
8. Type-check each argument against its resolved parameter.

After sema, the call has arguments in parameter order. MIR sees
a normal call.

### Scope

Parser: ~60 lines. Sema: ~140 lines. Total: ~200 lines.

---

## F5. Multidimensional Indexing

### Specification

Extend `[]` to support comma-separated dimension specs, slice
notation, ellipsis, and newaxis — dispatched through a `MultiIndex`
trait:

```
let x = a[2, 3]                // two-dim scalar index
let y = a[2:5, :]              // slice rows, all columns
let w = a[::2, 1:4]            // stride + slice
let v = a[::-1]                // reversed
let e = a[..., 0]              // ellipsis
let g = a[newaxis, :]          // insert dimension
let p = a[mask]                // boolean mask
let s = a[idx, 2:5]            // integer index + slice
a[2:5, :] = 0.0                // indexed assignment
a[-1]                          // negative indexing
a[-3:]                         // negative slice start
```

### Grammar

```
postfix_expr = primary ( '[' index_list ']' | '(' args ')' | '.' ident )*

index_list = index_spec ( ',' index_spec )*

index_spec =
    | '...'                              // ellipsis
    | 'newaxis'                          // insert dimension
    | slice_spec                         // range with optional step
    | expr                               // scalar or expression

slice_spec =
    | ':'                                // all elements
    | expr ':'                           // start to end
    | ':' expr                           // begin to stop
    | expr ':' expr                      // start to stop
    | expr ':' expr ':' expr             // start:stop:step
    | '::' expr                          // begin to end with step
```

### Detection rule

After parsing the first expression inside `[]`, if the next token
is `,` or if the first token was `:` or `...`, switch to
multi-index mode. Otherwise produce legacy `NK_INDEX`.

### AST

```
NK_MULTI_INDEX:
    data0 = base expression
    data1 = specs list start (extra data pool)
    data2 = specs count

NK_INDEX_SPEC:
    kind: INDEX_SCALAR | INDEX_SLICE | INDEX_ELLIPSIS | INDEX_NEWAXIS
    data0 = start expr (0 = absent)
    data1 = stop expr (0 = absent)
    data2 = step expr (0 = absent)
```

### Slice parsing

```
parse_slice_spec():
    if peek() == ':':
        eat(':')
        start = absent
    else:
        start = parse_expr()
        if peek() != ':': return INDEX_SCALAR(start)
        eat(':')

    if peek() == ':':
        eat(':')
        step = parse_expr()
        return INDEX_SLICE(absent, absent, step)
    else if peek() != ',' and peek() != ']':
        stop = parse_expr()
        if peek() == ':':
            eat(':')
            step = parse_expr()
            return INDEX_SLICE(start, stop, step)
        return INDEX_SLICE(start, stop, absent)
    return INDEX_SLICE(start, absent, absent)
```

### Trait

```
trait MultiIndex:
    fn multi_index(self: &Self, specs: &[IndexSpec]) -> Self
    fn multi_index_set(self: &mut Self, specs: &[IndexSpec], value: Self)

type IndexSpec = {
    kind: i32,           // 0=scalar, 1=slice, 2=ellipsis, 3=newaxis
    start: i64,
    stop: i64,
    step: i64,
    has_start: bool,
    has_stop: bool,
    has_step: bool,
    expr_value: *mut void,
}
```

The language provides syntax, AST, trait, and `IndexSpec`. What
the trait impl does (views, copies, gather, scatter, COW) is the
implementor's decision.

### Sema

1. Check base type for `MultiIndex` impl.
2. Type-check each spec (slices must be integer, at most one
   ellipsis).
3. Validate spec count vs rank if statically known.

### MIR lowering

```
_specs = stack_alloc IndexSpec[N]
// populate each spec
_result = call multi_index(_base, _specs, N)
```

Assignment: `call multi_index_set(_base, _specs, N, _value)`.
Specs are stack-allocated. No heap allocation for indexing.

### Scope

Parser: ~150 lines. AST: ~30 lines. Sema: ~100 lines.
MIR: ~50 lines. Total: ~330 lines.

---

## F6. Implicit Parameters via `with` Blocks

### Specification

A scoped implicit parameter mechanism. A `with` block introduces
a typed binding automatically passed to functions declaring an
`implicit` parameter of the matching type:

```
with context(default_device()):
    let y = sin(x)                // ctx resolved implicitly
    let z = a @ b                 // ctx resolved implicitly
    let w = sin(x, ctx: other)    // explicit overrides implicit
```

### Function declaration

```
fn sin(x: &Array, ctx: implicit &Context) -> Array
```

### Mechanism

1. `with context(expr):` evaluates `expr`, binds with implicit
   marker, enters body.
2. At call sites, for each `implicit` parameter not provided,
   sema searches enclosing scopes (innermost first) for a `with`
   binding of matching type.
3. If found, inserts argument. If not, compile error.
4. By MIR, all implicits are explicit. MIR/codegen unaware.

### Grammar

```
with_stmt = 'with' IDENT '(' expr ')' ':' block
```

Produces `NK_WITH_IMPLICIT`. Function parameters gain a 1-bit
`is_implicit` flag.

### Call resolution order

1. Positional arguments left-to-right.
2. Named arguments by name.
3. Implicit arguments from scope (type-matched, innermost first).
4. Defaults.
5. Remaining unmatched → error.

### Constraints

- A function may not declare two `implicit` parameters of the
  same type.
- Exact type match. No subtyping. Auto-ref applies.
- Closures capture the implicit binding from lexical scope.

### Nesting

Inner `with` shadows outer. Same rules as `let`.

### Scope

Parser: ~40 lines. Sema: ~120 lines. Total: ~160 lines.

---

## F7. `@` Infix Operator

### Specification

`@` as a binary infix operator at multiplicative precedence:

```
let y = a @ b                  // matmul
let z = a @ b + c              // matmul then add
let w = (a @ b) @ c            // chained
```

### Grammar

```
multiplicative = unary ( ('*' | '/' | '%' | '@') unary )*
```

`a @ b` produces `NK_MATMUL(data0=a, data1=b)`.

### Trait

```
trait MatMul:
    fn matmul(self: &Self, rhs: &Self) -> Self
```

### Disambiguation from annotations

`@[` is annotation. `@` in expression position is matmul. The
parser knows context — annotations appear before declarations.

### Scope

Parser: ~5 lines. Sema: ~20 lines. MIR: ~10 lines. Total: ~35 lines.

---

# Phase C: Sema Changes

These features require semantic analysis changes but no grammar
extensions.

---

## F8. Multi-Parameter Operator Dispatch

### Specification

Extend trait resolution so binary operators dispatch on both
operand types, not just the left:

```
// Currently works:
array + 1.0          // Add lookup on Array, f64 argument

// Currently fails, should work:
1.0 + array          // Add lookup on f64, Array argument → not found
```

### Mechanism

When resolving `a OP b`:

1. Look up operator trait on `typeof(a)` with `typeof(b)`. If
   found, use it. (Existing behavior.)
2. If not found, look up on `typeof(b)` with `typeof(a)` using
   reversed-operand semantics. If found, use it. (New.)

The trait implementor handles non-commutativity:

```
impl Sub for (f64, Array):
    fn sub(self: f64, rhs: &Array) -> Array:
        // self - rhs, NOT rhs - self
```

### Comparison operators

Follow the same two-step lookup. Return type is unconstrained by
the language — an impl may return any type (enabling boolean arrays
from comparisons).

### Scope

Sema: ~80 lines.

---

## F9. `@[tailrec]` Enforcement

### Specification

The `@[tailrec]` annotation guarantees the compiler MUST optimize
the tail call, or emit a compile error if it can't:

```
@[tailrec]
fn sum_to(n: i32, acc: i32) -> i32:
    if n <= 0: acc
    else: sum_to(n - 1, acc + n)    // guaranteed: no stack growth

@[tailrec]
fn bad(n: i32) -> i32:
    if n <= 0: 0
    else: 1 + bad(n - 1)            // ERROR: not in tail position
```

Without `@[tailrec]`, the compiler optimizes tail calls silently
when detected. The annotation is for when the programmer NEEDS
the guarantee.

**Tail position means:**
- The return expression of a function body
- The last expression in a block that is itself in tail position
- Both branches of `if`/`else` in tail position
- Every arm of a `match` in tail position
- Loop bodies are NOT tail position
- `defer` blocks are NOT tail position

**Mutual tail calls** require both functions to be `@[tailrec]`:

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

### Enforcement

When a function has `@[tailrec]`:
1. Find all recursive calls (to self or other `@[tailrec]` fns)
2. Verify each is in tail position
3. If any is not, error:

```
error: recursive call is not in tail position
src/foo.w:5:10
5 |     1 + sum_to(n - 1, acc)
  |         ^^^^^^^^^^^^^^^^^^
  = note: function is annotated @[tailrec]
  = help: ensure the recursive call is the last operation
```

### Scope

Sema/SemaCheck: ~60 lines.

---

# Phase D: MIR Changes

These features require MIR transformations or new MIR lowering
patterns.

---

## F10. Tail Call Optimization (self-recursion)

### Specification

A function call in tail position reuses the current stack frame.
This turns recursion into iteration:

```
fn factorial_acc(n: i32, acc: i32) -> i32:
    if n <= 1: acc
    else: factorial_acc(n - 1, n * acc)  // tail position → loop
```

### Detection (MIR level)

After lowering a function body, scan `TK_CALL` terminators.
A call is in tail position if:
1. Result place is `_0` (return place)
2. Next block is just `TK_RETURN`
3. No `defer`/`errdefer` active
4. No Drop-implementing locals live across the call

### Transform

Replace tail self-call with argument reassignment + jump to entry:

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

### Scope

MirLower: ~150 lines.

---

## F11. Tail Call Optimization (mutual recursion)

### Specification

Two or more `@[tailrec]` functions calling each other in tail
position. Implemented via trampoline — merge into single function
with dispatch tag:

```
fn _even_odd_trampoline(tag: i32, n: i32) -> bool:
    loop:
        if tag == 0:     // even
            if n == 0: return true
            tag = 1; n = n - 1
        else:            // odd
            if n == 0: return false
            tag = 0; n = n - 1
```

Alternative: LLVM `musttail call` for compatible signatures.

### Scope

MirLower + Codegen: ~400 lines. **Defer post-launch.**

---

## F12. Partial Application

### Specification

A function call with `_` placeholders produces a closure:

```
fn add(a: i32, b: i32) -> i32: a + b

let add5 = add(5, _)           // fn(i32) -> i32
let result = add5(3)           // 8

let clamp_byte = clamp(0, 255, _)
let clamped = clamp_byte(300)  // 255
```

**Multiple placeholders:**

```
let f = foo(1, _, 3, _)        // fn(T2, T4) -> R
f(20, 40)                      // foo(1, 20, 3, 40)
```

### Rules

- `_` only valid inside call argument lists
- `_` in callee position is an error
- `_` in non-call contexts retains existing meaning (wildcard)
- This is NOT auto-currying. `add(5)` is wrong-argument-count
  error, not partial application.

### Parser

When parsing call args, if any argument is `_`, the entire call
becomes `NK_PARTIAL_CALL`.

### Sema

1. Resolve callee type, get parameter types
2. For each `_`, record parameter type at that position
3. Synthesize closure type: `fn(placeholder_types...) -> R`
4. Type-check non-placeholder args

### MIR lowering

Desugar to closure construction:

```
// add(5, _) →
let closure_env = alloc { a: 5 }
let closure = make_closure(closure_fn, closure_env)
// where closure_fn(env, x) = add(env.a, x)
```

### Scope

Parser: ~40 lines. Sema: ~120 lines. MIR: ~140 lines.
Total: ~300 lines.

---

# Phase E: Verification Items

These features should work with existing language machinery. Each
needs a test confirming correct behavior.

---

## F13. Tuple Destructuring from Returns

```
let (u, s, vt) = svd(a)
let (_, s, _) = svd(a)            // _ discards, Drop called
let (x, y) = fn_with_implicit()   // implicit context resolved
```

Verify tuples compose with implicit parameters and defaults.

---

## F14. Range Types as Function Arguments

```
let r = 0..100           // Range[i32]
some_function(r)          // Range is a normal value
```

If ranges are currently loop-only, generalize to expressions.
**Scope if needed:** Parser ~30 lines, Sema ~20 lines.

---

# Implementation Order

```
Step  Feature                    Phase  Effort   Depends on
───── ──────────────────────────── ───── ──────── ──────────
  1   Tuple destructure in for   A      ~80 ln   —
  2   Chained comparisons        A      ~30 ln   —
  3   Named args + defaults      B      ~200 ln  —
  4   Implicit parameters        B      ~160 ln  F4 (call resolution)
  5   Multi-param dispatch       C      ~80 ln   —
  6   @ operator                 B      ~35 ln   F8 (trait resolution)
  7   @[tailrec] enforcement     C      ~60 ln   —
  8   Tail call (self)           D      ~150 ln  F9 (detection)
  9   Multi-dim indexing         B      ~330 ln  F6 (implicit ctx)
 10   Partial application        D      ~300 ln  —
 11   For-comprehensions         A      ~250 ln  —
 12   Verify: tuple returns      E      ~0 ln    F6
 13   Verify: range values       E      ~-50    —
 14   Tail call (mutual)         D      ~400 ln  F10, defer
```

### Dependency graph

```
F4 (named args)
 ├→ F6 (implicit params) → F5 (multi-dim indexing)
 └→ F7 (@ operator)

F8 (multi-param dispatch)
 └→ F7 (@ operator)

F9 (@[tailrec] enforcement)
 └→ F10 (self-TCO) → F14 (mutual TCO, deferred)

F1 (tuple in for)      — independent
F2 (chained compare)   — independent
F12 (partial apply)    — independent
F3 (for-comprehend)    — independent
```

### Recommended sequence

**Week 1:** F1, F2, F4, F3 — parser-heavy, independent, buildable
in parallel. ~560 lines.

**Week 2:** F6, F8, F7, F9 — sema-heavy, F6 depends on F4.
~335 lines.

**Week 3:** F10, F5 — MIR transform for TCO, largest parser change
for multi-dim indexing. ~480 lines.

**Week 4:** F12, F13, F14 — partial application, verification.
~350 lines.

**Post-launch:** F11 (mutual TCO trampoline). ~400 lines.

Total compiler changes (excluding mutual TCO): ~1,725 lines.

---

# Risk Assessment

**Multi-dim indexing parser complexity.** The slice grammar has
many edge cases (`:`, `::`, `3:`, `:3`, `3:7:2`, negative starts,
absent components). Exhaustive parser tests for every `slice_spec`
production before integrating with sema.

**Implicit parameter scope and closures.** Closures defined inside
`with` blocks capture the implicit binding. A closure escaping the
block must carry the captured reference. Test explicitly.

**Multi-param operator dispatch.** Reversed-operand lookup is a
real trait resolution change. If too invasive for v1: left-operand
dispatch only (`array + 1.0` works, `1.0 + array` doesn't).
Acceptable but not premium.

**`@` disambiguation.** `@[` is annotation, `@` in expression
position is matmul. No conflict expected but test error recovery.

**Partial application + closures.** The synthesized closure must
correctly capture non-placeholder arguments. Interaction with
auto-referencing (captured `&T` vs `T`) needs careful testing.

**For-comprehension type dispatch.** The parser emits generic
desugared `match`. Sema must determine Option vs Result from the
first binding's type. If the first expression returns neither
Option nor Result: error.

**Self-TCO and Drop.** Must verify no Drop-implementing locals
are live across the tail call. A live local with Drop prevents
TCO — the destructor must run before the call, meaning the call
isn't truly in tail position.

---

# Scope Summary

| # | Feature | Parser | Sema | MIR | Total |
|---|---------|--------|------|-----|-------|
| F1 | Tuple in for | 20 | 30 | 30 | 80 |
| F2 | Chained comparisons | 30 | — | — | 30 |
| F3 | For-comprehensions | 180 | 70 | — | 250 |
| F4 | Named args + defaults | 60 | 140 | — | 200 |
| F5 | Multi-dim indexing | 150 | 100 | 80 | 330 |
| F6 | Implicit parameters | 40 | 120 | — | 160 |
| F7 | @ operator | 5 | 20 | 10 | 35 |
| F8 | Multi-param dispatch | — | 80 | — | 80 |
| F9 | @[tailrec] enforce | — | 60 | — | 60 |
| F10 | Self-TCO | — | — | 150 | 150 |
| F11 | Mutual TCO (deferred) | — | — | 400 | 400 |
| F12 | Partial application | 40 | 120 | 140 | 300 |
| F13 | Verify: tuple returns | — | — | — | 0 |
| F14 | Verify: range values | 30 | 20 | — | 50 |
| | **Total (excl F11)** | **555** | **760** | **410** | **1,725** |