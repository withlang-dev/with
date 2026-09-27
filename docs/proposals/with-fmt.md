# `with fmt` — Specification

> **Status (2026-09-19): design recovered, not implemented, not reviewed against
> the current language.** Written 2026-04-12 and never committed; this is the
> text as written, unchanged below this note. `src/Fmt.w` today does layout only
> and implements none of the idiom rewrites in §2.
>
> Known to need a review pass before implementation — the language moved since:
>
> - **§2.12 `if-to-then`** targets `if COND then STMT`, which is not With
>   today. The inline form is `if COND: STMT`.
> - **§2.4 `unit-return`, §2.5 `obvious-return-type`** follow §9.1 for public
>   and private functions alike. The parser's former public-return annotation
>   requirement had no basis in the specification. D43 now defines exactly
>   when an unannotated function has a type (it inherits its
>   tail; a missing arm means `Unit`; mixed written arms do not infer), so
>   §2.5 can be wider than "a single literal" but must follow D43, and must
>   leave entry points and tests alone.
> - **§2.14 `chain-to-pipeline`** must respect D21's place-threading rule for
>   `mut fn` receivers.
> - **Rewrites the project rules now call for, which this design predates:**
>   the legacy index and cast idioms (`v.get(i as i64)` → `v[i]`,
>   `s.byte_at(i)` → `s[i]`, `x as i64` where the target already widens —
>   CLAUDE.md "Unnecessary casts and `unsafe` are defects"), a redundant
>   call-site `move` into a consuming parameter (§3.8, D5), and a `let _ =`
>   that discards a value whose discard has no effect.
> - Ownership-era semantics in general (D22, D27, D32, D44, D45): a rewrite
>   must never turn a view into an owner or the reverse; §2.6 `implicit-it`
>   and §2.10 `concat-to-fstring` want checking against them.
>
> Decisions this design would need from Eric before it is normative: whether
> idiom rewrites are always on (§Overview says yes, no flag), and whether
> `with migrate` pipes through them by default (§4).


## Overview

`with fmt` is a source-to-source tool that takes syntactically valid With code and rewrites it to be idiomatic. It performs two categories of transformation:

1. **Layout** — whitespace, indentation, line breaks, alignment
2. **Idiom rewrites** — semantic AST transformations that simplify code without changing behavior

Both categories are always applied together. There is no flag to separate them. The output of `with fmt` is always a fixpoint: running it twice produces the same result as running it once.

`with fmt` never changes program semantics. Every rewrite preserves observable behavior. If a rewrite would change semantics (e.g., removing a side effect), it is not applied.

---

## 1. Layout Rules

### 1.1 Indentation

4 spaces per level. No tabs. Continuation lines are indented one additional level beyond the opening construct.

### 1.2 Trailing whitespace

Stripped from all lines.

### 1.3 Final newline

Every file ends with exactly one newline.

### 1.4 Blank lines

- Maximum two consecutive blank lines anywhere → collapse to two.
- Exactly one blank line between top-level declarations (fn, type, enum, trait, impl, extend, let, const, use).
- No blank line after `:` that opens a block.
- No blank line before the first statement in a block.
- No trailing blank lines before a block-closing dedent.

### 1.5 Line length

Soft limit: 100 columns. `with fmt` does not break lines that are already under 100. It does not join lines that are already broken. It breaks lines that exceed 100 at natural break points (after `,`, before `|>`, before binary operators, after `(`).

### 1.6 Spaces around operators

- Binary operators: one space each side (`a + b`, `x = 3`, `a and b`).
- Unary prefix operators: no space (`-x`, `not valid`, `&mut v`).
- Commas: no space before, one space after.
- Colons in type annotations: no space before, one space after (`x: i32`).
- Colons opening blocks: one space before when inline (`fn f: expr`), newline after when starting indented block.
- `=>` in match arms: one space each side.
- `|>` pipeline: one space each side, or at start of continuation line.

### 1.7 Parentheses

No spaces inside parentheses: `f(x, y)` not `f( x, y )`.
No spaces inside brackets: `a[i]` not `a[ i ]`.

### 1.8 One-liner vs block

If a body is a single expression and the whole construct fits within the line length limit, keep it on one line:

```
fn double(x: i32) -> i32: x * 2
if not valid then return Err(.Invalid)
trait Neg[Output]: fn neg(self: Self) -> Output
```

If it doesn't fit, break into an indented block.

### 1.9 Trailing commas

Add trailing commas to multi-line struct literals, function arguments, and array literals. Remove trailing commas from single-line forms.

### 1.10 Comment alignment

Comments are not reformatted. Their indentation is adjusted to match the block they belong to.

---

## 2. Idiom Rewrites

Each rewrite is identified by a short name (for diagnostics and `// fmt:skip` overrides). Rewrites are listed in order of application.

### 2.1 `bool-wrap` — Remove C-style boolean wrapping

**Pattern:** `(if EXPR: 1 else: 0) != 0`
**Rewrite:** `EXPR`

Also handles:
- `(if EXPR: 1 else: 0) == 0` → `not EXPR`
- `(if EXPR: 1 else: 0)` in boolean context → `EXPR`
- Nested: `(if (if EXPR: 1 else: 0) != 0: 1 else: 0) != 0` → `EXPR`

This is the single highest-impact rewrite for migrated code.

### 2.2 `redundant-parens` — Remove unnecessary parentheses

**Pattern:** `(EXPR)` where the parentheses don't affect precedence or meaning.
**Rewrite:** `EXPR`

Preserve parentheses when:
- They disambiguate precedence in a way the reader would find helpful.
- They surround a tuple or function call argument list.
- Removing them would change the parse (e.g., `(a + b) * c`).

### 2.3 `empty-parens` — Drop `()` on no-arg function declarations

**Pattern:** `fn name():`
**Rewrite:** `fn name:`

**Pattern:** `fn name() -> T:`
**Rewrite:** `fn name -> T:`

Does not apply to function *calls* — `f()` stays `f()`.

### 2.4 `unit-return` — Drop `-> Unit` return type

**Pattern:** `fn name(...) -> Unit:`
**Rewrite:** `fn name(...):`

### 2.5 `obvious-return-type` — Drop return type when body makes it clear

**Pattern:** Function body is a single struct literal, enum variant, or literal, and the return type matches.
**Rewrite:** Drop the `-> T` annotation.

Only applied when the body is a single expression and the type is immediately obvious from that expression (struct literal with type name, `.Variant`, numeric/string literal matching the annotated type).

### 2.6 `implicit-it` — Convert single-param lambda to `it`

**Pattern:** `param => EXPR` where `param` appears in `EXPR` only in simple member access, comparison, arithmetic, or method call positions.
**Rewrite:** Replace `param` with `it`, drop `param =>`.

```
// Before
items.filter(x => x.active)
items.map(item => item.name)
items.filter(n => n > 0)

// After
items.filter(it.active)
items.map(it.name)
items.filter(it > 0)
```

Does not apply when:
- The parameter is used more than once in a way that would be unclear.
- The closure has multiple parameters.
- The body is complex (nested closures, multi-statement).

### 2.7 `enum-shorthand` — Shorten enum variant paths

**Pattern:** `TypeName.Variant` where the type is known from context (match scrutinee type, function parameter type, return type, let binding with annotation).
**Rewrite:** `.Variant`

### 2.8 `field-shorthand` — Use struct field punning

**Pattern:** `{ field: field }` in struct literal where field name matches variable name.
**Rewrite:** `{ field }`

### 2.9 `eq-true` — Remove comparison to `true`/`false`

**Pattern:** `EXPR == true`
**Rewrite:** `EXPR`

**Pattern:** `EXPR == false`
**Rewrite:** `not EXPR`

**Pattern:** `EXPR != true`
**Rewrite:** `not EXPR`

**Pattern:** `EXPR != false`
**Rewrite:** `EXPR`

### 2.10 `concat-to-fstring` — Convert concatenation to f-string

**Pattern:** `"lit" ++ expr ++ "lit"` and similar chains mixing string literals and expressions.
**Rewrite:** `f"lit{expr}lit"`

Only applied when:
- The chain has at least one interpolated expression (pure `"a" ++ "b"` is collapsed to `"ab"` instead).
- No element in the chain requires explicit `.to_str()` calls that wouldn't work in f-string interpolation.

### 2.11 `nullstmt` — Remove bare `0` statements

**Pattern:** A statement that is just the literal `0` with no side effects (NullStmt residue from C migration).
**Rewrite:** Remove the statement entirely.

### 2.12 `if-to-then` — Convert single-expression if blocks to inline `then`

**Pattern:**
```
if COND:
    return EXPR
```
**Rewrite:** `if COND then return EXPR`

Only when the body is a single `return`, `break`, `continue`, or short expression. Does not apply when the body has side effects beyond the single statement or when the line would exceed the length limit.

### 2.13 `goto-varname` — Strip goto suffixes from variable names

**Pattern:** `name__goto_NNNN_NN` where the unsuffixed `name` has no collision in scope.
**Rewrite:** `name`

Only applied when no other variable named `name` exists in the same scope. If there is a collision, keep the suffix.

### 2.14 `chain-to-pipeline` — Convert nested calls to pipeline

**Pattern:** `f(g(h(x)))` where each function takes one argument.
**Rewrite:** `x |> h |> g |> f`

Only applied when:
- Three or more nesting levels.
- Each function takes exactly one argument (the inner result).
- The result reads more clearly as a pipeline.

### 2.15 `redundant-let-type` — Remove type annotation when RHS makes type obvious

**Pattern:** `let x: SomeType = SomeType { ... }` or `let x: i32 = 42`
**Rewrite:** `let x = SomeType { ... }` or `let x = 42`

Only when the RHS unambiguously determines the type (struct literal, enum variant with type prefix, obvious literal).

### 2.16 `for-range` — Convert C-style while loop to for-range

**Pattern:**
```
var i = 0
while i < N:
    BODY
    i = i + 1
```
**Rewrite:**
```
for i in 0..N:
    BODY
```

Only when:
- `i` starts at an integer literal or variable.
- The increment is exactly `i = i + 1` (or `i += 1`) and appears as the last statement.
- `i` is not modified anywhere else in the body.

---

## 3. Skipping

### 3.1 Line skip

A `// fmt:skip` comment on the line immediately before a construct prevents all rewrites on that construct.

```
// fmt:skip
let x: i32 = (if flag: 1 else: 0) != 0  // left as-is
```

### 3.2 Block skip

```
// fmt:off
... code left untouched ...
// fmt:on
```

Layout is still normalized (indentation, trailing whitespace) even inside `fmt:off` blocks. Idiom rewrites are suppressed.

### 3.3 Named skip

`// fmt:skip(bool-wrap)` suppresses only the named rewrite on the next construct.

---

## 4. Interaction with `with migrate`

`with migrate` should pipe its output through the idiom rewrite pass before writing `.w` files. This means migrated code is idiomatic by default. The `bool-wrap`, `nullstmt`, `redundant-parens`, and `goto-varname` rewrites are the critical ones for migration output quality.

A `--raw` flag on `with migrate` skips the cleanup pass for debugging.

---

## 5. Non-goals

`with fmt` does **not**:

- Rename user-chosen identifiers (beyond `goto-varname` suffix stripping).
- Reorder declarations or imports.
- Add or remove `use` statements.
- Change `var` to `let` or vice versa.
- Insert `defer` or `errdefer`.
- Convert imperative code to functional style beyond the specific rewrites listed.
- Warn about anything — it only rewrites. Warnings belong in `with check` or a future linter.

---

## 6. CLI

```
with fmt [files...]          # format in place
with fmt --check [files...]  # exit 1 if any file would change (for CI)
with fmt --diff [files...]   # print unified diff of changes
with fmt -                   # read stdin, write stdout
```

When invoked with no arguments, formats all `.w` files in the current directory recursively (respecting `.withignore` if present).

---

## 7. Ordering and Fixpoint

Rewrites are applied bottom-up on the AST (innermost expressions first), then iterated until no rewrite produces a change. The `bool-wrap` rewrite in particular requires iteration because removing one layer of wrapping may expose another.

The implementation must guarantee convergence. Every rewrite strictly reduces AST node count or token count. No rewrite can increase either metric. This ensures termination in at most O(depth) iterations, where depth is the maximum nesting of rewritable patterns.
