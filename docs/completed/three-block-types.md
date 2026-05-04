## Block Body Forms

Every construct in With that introduces a statement or expression body supports three interchangeable body forms. The user selects the form that fits the situation. The language imposes no preference and warns on no choice.

### The Invariant

A colon introduces either an inline body or an indented body. A brace directly after a construct's header introduces a braced body. There is no colon-plus-brace body form; if `{ ... }` appears after `:`, it is parsed as the single inline body expression according to normal expression grammar.

### The Three Forms

**Inline colon.** A colon followed by a single block item on the same line.

```
fn double(x: i32) -> i32: x * 2
if ready: launch()
for x in xs: total += x
unsafe: *p = 42
```

The inline body is a block containing exactly one block item. Multiple statements separated by `;` on the same line are not permitted in inline form; use the braced form for multi-statement one-liners.

The inline body is terminated by the first top-level newline. Newlines inside balanced delimiters (parentheses, brackets, braces) do not terminate the inline body, so multi-line expressions inside delimiters work as expected:

```
if cond: call({
    x: 1,
    y: 2,
})
```

The body here is the single call expression; the call's argument is a multi-line record literal whose internal newlines are inside `{ }` and do not end the inline body.

Comments are treated as whitespace. The body ends at the actual newline after any trailing comment.

Use when the body is short enough to read on one line.

**Indented colon.** The colon ends the line; the body is the indented block that follows. Indentation is structural — the body ends when indentation returns to or below the introducing construct's level.

```
fn process(items: Vec[Item]) -> Result:
    var total = 0
    for item in items:
        total = total + item.value
    .Ok(total)
```

Use when the body spans multiple statements. The Python-shaped default for non-trivial bodies.

**Braced.** Curly braces follow the construct's header directly, without an intervening colon. Brace blocks are whitespace-insensitive: the parser treats whitespace inside braces as separator only, not as structure.

```
fn process(items: Vec[Item]) -> Result {
    var total = 0
    for item in items { total = total + item.value }
    .Ok(total)
}

fn main { var x = 0; for i in 0..10 { x = x + i }; print(x) }
```

Inside braces, statements are separated by semicolons or newlines. Multiple statements on the same physical line require semicolons. The block ends at the matching `}` regardless of whitespace.

Use when whitespace independence matters — generated code, minified code, single-line lambdas inside expressions, or contexts where indentation cannot serve as structure.

### Why Three Forms

Each form serves a distinct property:

- **Inline colon** serves visual brevity. A trivial body shouldn't need three lines.
- **Indented colon** serves structural readability. Python-shaped indentation makes multi-line structure visible at a glance.
- **Braces** serve whitespace independence. Code generators, minifiers, and embedded-expression contexts cannot rely on indentation or newlines.

The three properties don't overlap. The three forms are the minimal set covering them.

**Exception — `if` expression shorthand:** `if` additionally supports `then` as a body introducer for pure expression chains: `if cond then expr else expr`. The `then` form is not a general block form — it accepts only a single expression, not a block, and the `else` arm also takes a bare expression. It serves a fourth property: reading like a mathematical conditional without any punctuation overhead. Because it is expression-only and `if`-specific, it does not generalize to other constructs.

### Universal Application

The three-form rule applies to every construct that introduces a statement or expression body. There are no exceptions among such constructs.

The constructs subject to the rule are:

- **Functions:** `fn name(params) -> T: body`
- **Conditionals:** `if cond: body`, `else: body`, `else if cond: body`, and the expression shorthand `if cond then expr else expr`
- **Loops:** `for x in xs: body`, `while cond: body`, `loop: body`
- **Scoped access:** `with expr as x: body`, `with expr as mut x: body`, `with expr as (a, b): body`
- **Unsafe regions:** `unsafe: body`
- **Defer statements:** `defer: body`
- **Comptime blocks:** `comptime: body`
- **Async constructs:** any `async:`, `spawn:`, or similar that introduces a body
- **Labeled blocks:** `'label: body`

For labeled blocks, all three forms apply:

```
'label: cleanup()

'label:
    cleanup()
    break 'label

'label {
    cleanup()
    break 'label
}
```

Constructs added to the language in the future that introduce a statement or expression body automatically inherit the three-form rule. The parser routes all such constructs through a single body-parsing path; consistency is structural, not enforced per-construct.

### Match Arms

Match arms use `=>` rather than `:` to introduce the arm body. Match arms support the same three forms, with `=>` taking the role of `:`:

- **Inline:** `pattern => expression` — a single expression on the same line as `=>`.
- **Indented:** `pattern =>` ending the line, with an indented block on subsequent lines. The body ends when indentation returns to or below the arm level (typically when the next pattern appears).
- **Braced:** `pattern => { body }` — explicit braces directly after `=>`.

```
match x:
    0 => "zero"
    1 =>
        log("one")
        "one"
    _ => { log("other"); "other" }
```

All three are legal. Style: hand-written match arms are typically inline; indented arms appear when the body has multiple statements; braced arms appear in generated code or when explicit delimiters fit better.

### Constructs Outside the Rule

The three-form rule applies to *blocks* — sequences of statements or a single body expression. It does not apply to constructs that introduce *declarations*:

- **Type bodies** (`type T { fields }`, `enum E { variants }`) declare fields or variants.
- **Trait bodies** (`trait T = ...`) declare trait methods.
- **Impl blocks** (`impl T:`, `impl Trait for T:`) declare methods.
- **Module bodies** declare top-level items.

These are inherently multi-item structural definitions, not statement blocks. They use their own grammar (braces or colon-introduced declaration lists) and do not have an inline form. The distinction is semantic: a *block* contains statements or yields a value; a *declaration body* contains definitions.

`impl T:` opens an indented declaration body containing methods, not a statement block. The methods inside are themselves `fn` constructs that follow the three-form rule for their own bodies.

### Disambiguation

After parsing a block-introducing construct's header, the parser dispatches based on the next non-whitespace token:

1. **`{` next** (with optional whitespace, no intervening colon): braced form. The body is delimited by the matching `}`.
2. **`:` next, then non-whitespace content on the same line:** inline form. The body is a single block item terminated by the first top-level newline.
3. **`:` next, then end-of-line:** indented form. The body is the indented block on subsequent lines.
4. **`then` next** (`if` only): expression shorthand form. The body is a single expression; `else` introduces the else expression directly, without a body introducer.
5. **Anything else:** parse error.

A line ending with `:` and no indented body following is a parse error. A construct with no recognized body introducer is a parse error.

If `{ ... }` appears after `:`, it is parsed as a single inline body expression (typically an anonymous record literal or a block expression), not as a braced body. This is what allows constructs like `fn make_user: { name: "Alice", age: 30 }` to parse correctly once anonymous record literals are in the language.

### Whitespace Rules

Whitespace handling differs across the three forms:

- **Inline colon** is line-structured. The body ends at the first top-level newline. Newlines inside balanced delimiters do not count.
- **Indented colon** is indentation-structured. The body ends when indentation returns to or below the introducing construct's level.
- **Braced** is whitespace-insensitive. The body ends at the matching `}` regardless of newlines or indentation.

These rules compose cleanly across nesting. An inline colon body can contain braced sub-blocks; a braced block can contain colon-introduced sub-blocks; an indented block can contain anything.

### Nesting and Dangling `else`

Inline forms compose. The inner construct's body parses according to the same rules.

```
fn classify(n: i32) -> Category: if n < 0: .Negative else if n == 0: .Zero else: .Positive
fn clamp(x: i32, lo: i32, hi: i32) -> i32: if x < lo then lo else if x > hi then hi else x
```

For the dangling `else` case: an `else` on the same line as an inline `if` binds to the nearest unmatched inline `if` on that line. An `else` on a following line participates in the outer indentation structure and binds according to indentation, not inline-line proximity.

```
if a: if b: c else: d
```

Both `else: d` and `if b: c` are on the same line. The `else` binds to `if b`. The outer `if a` has no else.

```
if a: if b: c
else: d
```

Here `else: d` is on the following line. It participates in the outer structure and binds to `if a`. The inner `if b` has no else.

### Body Type Rules

The three body forms (and the `then` expression shorthand) produce the same body AST and are type-checked by the existing rules for that construct.

If a construct has an expected body type, the body must type-check against that expected type regardless of source form. If the construct participates in inference, such as function return type inference, the existing inference rules apply unchanged. This proposal does not define or alter those rules.

For ordinary expression blocks, the body type is the type of the tail expression, or `Unit` if there is no tail expression. Inline bodies are one-item blocks; indented and braced bodies are ordinary multi-item blocks.

Body forms do not affect type checking, return type inference, or control-flow semantics. After parsing, inline, indented, and braced bodies are normalized to the same body AST shape. Existing rules for function return inference, block tail expressions, `return`, `break`, `continue`, `with` implicit return, and unit typing apply unchanged.

### Equivalence

The three forms are syntactically interchangeable and produce identical compiled output. The following three definitions compile to identical AST, identical MIR, and identical machine code:

```
fn add(a: i32, b: i32) -> i32: a + b

fn add(a: i32, b: i32) -> i32:
    a + b

fn add(a: i32, b: i32) -> i32 { a + b }
```

For `if` expressions, the `then` form is also equivalent:

```
fn clamp(x: i32, lo: i32, hi: i32) -> i32: if x < lo then lo else if x > hi then hi else x
fn clamp(x: i32, lo: i32, hi: i32) -> i32: if x < lo: lo else if x > hi: hi else: x
```

Tools that parse and re-emit With source (formatters, refactoring tools, the `with migrate` C-import path) may convert between forms; the conversion is purely syntactic.

### Style Guidance

The language enforces no style. The following is guidance.

**Use inline colon when:**
- The body is a single short expression or statement.
- The construct's purpose is clear at a glance.
- Adding indentation would obscure rather than clarify.

**Use indented colon when:**
- The body has multiple statements.
- The body's structure benefits from vertical visual layout.
- This is the common case for hand-written production code.

**Use braces when:**
- Whitespace independence matters: code generation, minification, single-line lambdas.
- The surrounding context already uses braces and consistency aids readability.
- Indentation would be impractical or ambiguous for the situation.

The compiler does not warn on form choice. Linters may; project conventions may; code review may. The language gives the tools and trusts the user to pick the right one.

### Rationale

With aims to be a Python-shaped systems language. Python's indented blocks work well for most code. But:

- Trivial bodies don't need indentation; forcing it adds visual noise.
- Some contexts — lambdas inside expressions, code generators, minified output — cannot use indentation as structure. They need explicit delimiters.
- One-size-fits-all enforcement (`gofmt`-style) buys consistency at the cost of fighting the formatter when the enforced shape doesn't fit.

Three forms covering three properties lets the user write what reads best for the situation. The cost is style debates within a codebase; the benefit is that a natural-looking shape is always one form away.

The "every construct, no exceptions" rule eliminates a class of papercut: users never need to remember which constructs allow which forms. If it introduces a statement or expression body, all three forms work. The rule is structural, not per-construct. The single exception is the `then` shorthand, which is `if`-specific because it is expression-only and would not generalize cleanly to block-introducing constructs.

The "trust the user" principle is a real design choice. The language could enforce a single form per construct, or warn when users mix forms within a function. With does neither. The language gives three tools that each serve a distinct property; the user decides which tool fits the situation.