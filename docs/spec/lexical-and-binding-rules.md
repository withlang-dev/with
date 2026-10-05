# 29. Additional Lexical and Binding Rules (Wave Language Rules)

### 29.1 Numeric separators

Numeric literals permit `_` separators for readability:

- Decimal: `1_000_000`
- Hex: `0xFF_AA_22`
- Binary: `0b1111_0000`
- Float: `3.141_592_653`

Separators are ignored for numeric value parsing.

Type suffixes, when present, begin after the numeric portion of the
literal ends. The suffix itself does not contain separators:

- Valid: `1_000u64`, `0xFF_FFu32`, `3.25f32`
- Invalid: `1_000_u64`, `0xFF_FF_u32`

The suffix is matched greedily from the closed set of numeric suffixes
defined in §4.2.1.

### 29.2 Trailing commas

Trailing commas are **permitted but never required** in list-like grammar positions, including:

- Function parameter lists and argument lists
- Type parameter and type argument lists
- Record/struct field lists
- Tuple/array literal element lists
- Match arms and import/use lists

Inside matched `()`, `[]`, and `{}`, list-like grammar positions treat optional
newlines like separator whitespace. This means multiline parameter lists,
argument lists, tuple literals, array literals, struct literals, indexing, and
type/generic lists are legal as long as the delimiters are balanced.

This rule applies to the delimited list itself, not to nested block bodies.
Newlines that start a block after `:` or `=>` retain their normal significance.

### 29.3 Raw string literals

Raw string forms are supported:

- `r"..."`  
- `r#"..."#`  
- `r##"..."##` (and higher `#` counts)

Raw strings disable escape and interpolation parsing in the lexer/parser path; delimiter matching uses the same `#` count.

### 29.4 Triple-quoted multiline strings

`"""..."""` literals:

- May start with an optional newline immediately after the opening delimiter.
- May end with a trailing newline immediately before the closing delimiter.
- Are dedented by common leading indentation across non-empty lines.

### 29.5 Byte literals

`b'X'` and escaped forms (for example `b'\x41'`) are accepted.

Bootstrap lowering treats character and byte literals as integer literal values during AST construction; type-checking follows normal integer coercion rules.

### 29.5a Labels

A `LABEL` token is a single quote followed immediately by an identifier,
with no whitespace between the quote and the identifier:

```
'outer
'search
'L0
```

The identifier part follows the ordinary identifier spelling rules:
it starts with a letter or underscore and may contain letters,
digits, and underscores. Labels are syntactically distinct from
ordinary identifiers because of the leading quote and live in a
separate namespace. That namespace is shared by label declarations
and the target operands of `goto`, `break`, and `continue`.

Single-quoted character literals are also valid syntax. A character
literal is a single quote, followed by one character or escape
sequence, followed by a closing single quote:

```
'a'
'@'
'\n'
```

Lexer priority for apostrophe-related tokens is:

1. Byte literals such as `b'X'` or `b'\n'`.
2. Closed character literals such as `'a'`, `'@'`, or `'\n'`.
3. Labels such as `'outer`, `'L0`, or `'scan`.

A label has no closing quote. A character literal must have a closing
quote. Inside string literals, apostrophe is ordinary string content
and never starts a label or character literal.

### 29.6 Unused bindings

`_` is an explicit discard binding. It is legal in binding positions (for example `let _ = expr`, parameter bindings, pattern bindings) and does not introduce a usable name.

`_` binds nothing, so a value bound to it is dropped where it is bound. A `let _ = x` that names a non-`Copy` value moves it, as naming one does everywhere, and drops it at that statement: a later use of `x` is a use of a moved value. `let _ = x` is the visible way to say "drop this now".

### 29.7 String escape parity

String processing supports:

- Standard escapes: `\\`, `\"`, `\n`, `\r`, `\t`
- Null byte: `\0`
- Hex byte: `\xNN` (two hexadecimal digits)

These rules apply consistently to standard and C-string literal processing.

### 29.8 No-shadowing

Shadowing is disallowed for local bindings. Rebinding an existing visible name emits a diagnostic (for example, `shadowing is not allowed for 'x'`).

**Consuming-rebind exception:** a new binding may reuse a visible
local name when its initializer consumes that binding — i.e. the old
binding's last use is inside the initializer expression:

```
let x = read_input()
let x = parse(x)?        // OK: old x is consumed by the initializer
```

This removes the naming ceremony of pure narrowing chains (`s`,
`s2`, `trimmed`) without permitting shadowing at a distance: if the
old binding would still be live after the new declaration, the rebind
is still an error.

### 29.9 Pipeline-first guidance

Because rebinding/shadowing is disallowed, stepwise transformations should use pipelines (`|>`) and scoped `with` bindings instead of repeated `let name = ...` rebinding.

### 29.10 `todo` and `unreachable`

`todo()` and `unreachable()` are divergence-oriented builtins with type `Never`.

- They accept zero arguments or one `str`-compatible message argument.
- Their type is `Never`, which is compatible in value position with any expected type.
- They are treated as diverging control-flow points for typing and reachability analysis.

### 29.11 Reserved Keywords

The following keywords are reserved and cannot be used as
identifiers. This list is normative and matches the implementation's
lexer keyword table:

```
and       as        asm       async     await     break
c_import  comptime  const     continue  copy      defer
do        dyn       else      enum      ephemeral errdefer
error     extend    extern    false     fn        for
gen       global    goto      if        impl      in
it        let       loop      match     module    move
mut       no_suspend not      null      opaque    or
pub       return    select    spawn     trait     true
type      union     unsafe    use       var       where
while     with      yield
```

Notes:

- `then` is not a reserved keyword and is not an `if` body
  introducer.
- `newaxis` and `implicit` are **contextual**: they have special
  meaning only in index lists (§11.7) and parameter declarations
  (§9.1a) respectively, and remain usable as ordinary identifiers
  elsewhere.
- `else if` is a two-token keyword pair (§9.1), not a single
  keyword.
- `spawn` is reserved; it currently has no construct in §14 and its
  surface is under review.

### 29.12 Error Codes

| Code | Description |
|------|-------------|
| E0901 | Non-local control flow (`return`, `break`, `continue`, `goto`, `?`) inside `defer`/`errdefer` |
| E0951 | Nested implicit `it` is ambiguous — use explicit `param => expr` for inner closure |
| E0952 | `it` used in context expecting N != 1 parameters |
| E0953 | `it` is a reserved keyword and cannot be used as an identifier |
| E1101 | Orphan rule violation: impl requires a local trait or local type |
| E1102 | Duplicate implementation of trait for type |
| E1201 | Overlapping trait implementations |

### 29.13 Block Body Syntax

Most constructs that introduce a statement or expression body support
three interchangeable body forms. The choice is purely stylistic; all
three produce identical AST and compiled output. The three-form rule
applies to `fn`, `while`, `for`, `loop`, `with`, `defer`, `errdefer`,
`comptime`, labeled blocks, match arms, and any future block-introducing
construct unless that construct states a narrower syntax.

`unsafe` is the deliberate exception: `unsafe:` is always a newline
block, `unsafe { ... }` is the inline block expression form, and
`unsafe *p` / `unsafe p[i]` is the narrow raw-access prefix form.

`if`/`else if`/`else` support all three forms. They do not support a
separate `then` expression shorthand; see §9.1 for the full `if` syntax.

**Form 1 — Inline colon.** A colon immediately followed by content
on the same line.

```
fn add(a: i32, b: i32) -> i32: a + b
if ready: launch()
for x in xs: total = total + x
defer: f.close()
```

The body is a single block item. The inline body ends at the first
top-level newline. Newlines inside balanced delimiters (parentheses,
brackets, braces) do not terminate the inline body.

**Form 2 — Indented colon.** The colon ends the line; the body is
the indented block on subsequent lines.

```
fn main:
    let x = 5
    print(x)

while running:
    tick()
    render()
```

The body ends when indentation returns to or below the introducing
construct's level. A colon at end of line with nothing following
(no indented block) is a syntax error.

**Form 3 — Braced.** Curly braces follow the construct's header
directly, with no intervening colon.

```
fn add(a: i32, b: i32) -> i32 { a + b }
fn main {
    let x = 5
    print(x)
}
while running { tick(); render() }
```

Whitespace inside braces is insignificant. Statements are separated
by newlines or semicolons. Empty brace body `{}` is legal (returns
`Unit`).

**After a construct's header, a body introducer is required.** For all
constructs, including `if`, `else if`, and `else`, the introducer must be
`:` or `{`; omitting it is a parse error. The one exception is the `else`
of `let ... else` (§9.7), which may instead take a single diverging
expression on the same line. `then` is not a body introducer.

**Illegal combinations:**

- Colon-then-brace: `fn f: { body }` — the `{ }` is parsed as an
  inline body expression (e.g. a record literal), not a braced body.
  This is valid only if `{ body }` is a meaningful expression.
- No introducer: `while cond\n    body` — parse error; `:` or `{`
  is required after the condition.

**Labeled bodies:**

Labels are statement prefixes (§13.5a). A label may prefix any
statement, either on the same line or on its own line immediately
before the statement it labels. A label has no trailing colon of its
own; when the labeled statement is a block, loop, or other body form,
that construct still supplies its normal body introducer:

```
'outer while running:
    tick()

'outer while running { tick() }

'scan for item in list:
    process(item)

'scan for item in list { process(item) }

'early:
    maybe_exit()

'early { maybe_exit() }

'done return
```

For labeled `while` and `for`, the loop still has its own body
introducer. For colon-form labeled blocks, the colon after the label
is the block-body introducer. Labels on non-body statements, such as
`'done return`, do not introduce a block.

**Applies uniformly to all block-introducers:**

```
// Functions
fn greet: print("hello")
fn greet { print("hello") }

// Conditionals
if x > 0:
    handle_positive()
if x > 0 { handle_positive() }

// Loops
while running:
    tick()
while running { tick() }

for item in list:
    process(item)
for item in list { process(item) }

// Match (block form)
match shape:
    Circle(r) => pi * r * r
    _ => 0.0
match shape {
    Circle(r) => pi * r * r,
    _ => 0.0,
}

// Type definitions
type Point { x: f64, y: f64 }

// Trait definitions
trait Drawable:
    fn draw(self: &Self)
trait Drawable {
    fn draw(self: &Self)
}
```

**Semicolons as statement separators:**

The semicolon (`;`) is a statement separator, not a terminator.
It may be used anywhere a newline separates statements:

```
let x = 1; let y = 2; print(x + y)
fn add(a: i32, b: i32) -> i32 { a + b; }   // trailing ; is legal (ignored)
```

Consecutive semicolons and mixed semicolons/newlines collapse to a
single separator, just as consecutive newlines do:

```
let x = 1;; let y = 2      // same as: let x = 1; let y = 2
let a = 1;
let b = 2                   // semicolon + newline = one separator
```

`with fmt` normalizes semicolons to newlines — semicolons never
appear in formatted output.

Semicolons inside `[…]` retain their existing meaning (array fill
and for-comprehension monadic chaining) and are not affected by
this rule.

**Style guidance:** Hand-written code typically uses colon form.
Generated code (code generators, derive macros, comptime expansions)
should use brace form to avoid indentation-sensitivity issues.

**Formatter behavior:**

- `with fmt` (default): preserves the author's chosen form.
- `with fmt --prefer-brace`: converts inline colon to inline brace.
  `fn f: expr` becomes `fn f { expr }`. Multi-line colon becomes
  multi-line brace. Lossless.
- `with fmt --prefer-colon`: converts inline brace to inline colon
  when the body is a single expression. Multi-statement braced
  bodies convert to multi-line colon form. Lossless.

### 29.14 Attribute Index

All `@[...]` attributes, with their owning sections. This list is
normative for the *user-facing* set; an attribute not listed here and
not marked internal is invalid.

| Attribute | Section | Purpose |
|-----------|---------|---------|
| `@[derive(...)]` | §11.8 | Generate trait implementations |
| `@[must_use]` | §9.7, §14.7 | Match-exhaustiveness obligation |
| `@[tailrec]` | §9.2 | Guaranteed tail-call elimination |
| `@[inline]` / `@[noinline]` | §9.2 | Inlining hints |
| `@[sealed]` | §11.6 | Closed trait implementor set |
| `@[flags]` | §4.4a | Power-of-two enum auto-increment |
| `@[specified]` | §4.4a | Require explicit discriminants |
| `@[bitpacked]` | §4.3b | Bit-level struct packing |
| `@[repr(C)]` / `@[repr(packed)]` | §16.4 | Layout control |
| `@[align(N)]` | §16.4 | Custom alignment |
| `@[c_export("name")]` | §16.5 | Export a C ABI symbol |
| `@[link_name("symbol")]` | §16.3 | Foreign symbol name for an extern function |
| `@[effect(...)]` | §16.3d | Declared effect contracts (bodiless decls) |
| `@[no_await_guard]` | §7.9 | Guard must not live across suspension |
| `@[no_alloc]` | §20 | Reject hidden/ambient allocation in the function body |
| `@[iter_of_self]` | §13.2 | Iterator borrows the receiver |
| `@[ffi_stack]` | §14.19 | Reserved: OS-stack execution (roadmap) |
| `@[panic_handler]` / `@[entry]` / `@[no_main]` / `@[global_allocator]` | §18.7 | Freestanding-mode hooks |
| `@[target("arch")]` | §16.13 | Architecture-guarded items |
| `@[import_module("ns")]` | §16.3 | WebAssembly import namespace of an extern function (wasm32 only) |

**Implementation-internal (unstable):** `@[bench]`, `@[test]`,
`@[before]`, `@[after]`, `@[stack_size]`, `@[callconv]`,
`@[compiler_hook]`, `@[packed]`, `@[weak]`. These exist for compiler,
test harness, migrator/runtime, and stdlib development, may change or
vanish without notice, and are not part of the language. The
type-position operator `@TypeOf(expr)` (compile-time type of an
expression) is likewise implementation-internal and unstable.

---
