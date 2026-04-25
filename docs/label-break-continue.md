# Labeled break and continue

## Status

Proposal, v2. Targets a near-term With release. Driven by the
migrator's need to express multi-level control transfers cleanly
when porting the Beyond Relooper algorithm (Ramsey 2022) for
C-to-With goto lowering.

Independently useful for hand-written code with nested loops.

## Motivation

With currently has unlabeled `break` and `continue`. They always
target the innermost enclosing loop (`while`, `for`). There is no
way to break out of an outer loop from within an inner one without
using a flag variable, restructuring with a function and `return`,
or some similar workaround.

This is a problem for two distinct audiences.

The migrator needs to produce code shaped like the output of
structured control-flow algorithms (Beyond Relooper, Stackifier,
Relooper). These algorithms emit branches that target specific
named scopes — the WASM analogue is `br N`, "break out of N
scopes." Without labeled break, the migrator either synthesizes
flag-variable cascades (poor output) or falls back to state-machine
dispatch (defeats the purpose of using these algorithms in the
first place).

Hand-written code wants this for the obvious reasons. Searching a
2D grid, parsing nested structures, breaking out of polling loops
— any case where the control flow naturally spans more than one
loop level.

The feature is small, additive, and well-understood. Rust, Java,
JavaScript, Kotlin, and Swift all have variants. We adopt a syntax
close to Rust's because it is the closest language to With in style
and reads naturally next to the existing structured constructs.

## Syntax

### Labels

A label is an identifier prefixed with a single quote.

```
'outer
'search
'L0
```

Labels share the regular identifier namespace rules (alphanumeric
and underscore, starting with a letter or underscore) but are
syntactically distinct because of the leading quote. They cannot
collide with ordinary identifiers, types, or keywords.

### Uniform label-colon rule

A label always carries its colon. The form is:

```
LABEL ':' construct
```

The colon belongs to the label, not to whatever follows. This rule
is uniform regardless of which block style the construct uses.
There are no bare-label spellings.

### Labeled loops

The `while` and `for` loops may be prefixed with a label. Both block
styles are supported — colon-form and brace-form.

Brace form:

```
'outer: while cond {
    ...
}

'search: for x in xs {
    ...
}
```

Colon form:

```
'outer: while cond:
    ...

'search: for x in xs:
    ...
```

In the colon form, the first colon belongs to the label and the
second introduces the loop body. The two colons are at different
syntactic levels and unambiguous to the parser, even if visually
adjacent.

### Labeled blocks

A bare block may carry a label. This permits early exit from a
non-loop scope. Both block styles are supported.

Brace form:

```
'find: {
    if quick_check() { break 'find }
    ...
}
```

Colon form:

```
'find:
    if quick_check(): break 'find
    ...
```

Labeled blocks are not a new statement form. They are an existing
block with an attached label. `break 'label` exits the block;
`continue 'label` is a type error (you cannot continue a non-loop).

Labeled blocks are statement-position only in v1. They may not
appear where a value is expected.

### Labeled break and continue

The existing `break` and `continue` statements gain an optional
label operand.

```
break          // existing: innermost loop
break 'outer   // new: loop or block named 'outer

continue        // existing: innermost loop
continue 'outer // new: loop named 'outer
```

The unlabeled forms are unchanged in semantics. Labeled forms
target the named construct.

## Semantics

### Scoping

A label is in scope throughout the labeled construct's body,
including all nested constructs. The body begins at:

- The opening brace, for brace-form constructs.
- The loop-body colon, for colon-form `while` and `for` loops
  (not the label colon).
- The label colon itself, for colon-form labeled blocks (where
  the label colon is the body introducer).

A `break` or `continue` with a label is valid if and only if the
label is in scope at the point of use.

Labels do not shadow identifiers; they live in a separate namespace.
A variable named `outer` and a label `'outer` are unrelated.

### Function-local

Labels are function-local control-flow targets. A label is not
visible inside a nested `fn`, a closure, an `async:` block, or a
`gen fn` body. A `break 'label` or `continue 'label` may only
target a labeled construct in the same function body.

### with-block transparency

`with` blocks are transparent for label scoping. Labels declared
outside a `with` block remain visible inside it, and `break` or
`continue` may target outer labels from within a `with` body.

This is the correct rule because `with` blocks are compiler-known
control-flow constructs in With, not function boundaries. Closures
and nested functions are boundaries; `with` bodies are not.

```
'outer: while cond:
    with guard:
        if done: break 'outer    // valid; 'outer visible through with
```

### Label uniqueness

Two labeled constructs in the same lexical scope, where one nests
inside the other, must use distinct labels. The compiler rejects:

```
'l: while a:
    'l: while b:                // error: label 'l shadows enclosing 'l
        break 'l                // ambiguous: which 'l?
```

Labels in disjoint scopes may reuse names. This is fine:

```
fn f():
    'l: while a: ...
    'l: while b: ...            // ok: previous 'l is out of scope
```

### break with a label

`break 'l` transfers control to the statement immediately following
the construct labeled `'l`. It works for both loops and blocks.

For a labeled loop, this is the same as the unlabeled `break` would
do if `'l` were the innermost loop.

For a labeled block, this is exit from the block. There is no
implicit loop semantics — control does not return to the start of
the block.

### continue with a label

`continue 'l` transfers control to the next iteration of the loop
labeled `'l`. The exact target depends on the loop kind:

| Loop kind | Continue target                                  |
| --------- | ------------------------------------------------ |
| `while`   | The condition-check basic block.                 |
| `for`     | The iterator-advance / next-element basic block. |

`continue` with a label that names a non-loop construct (a labeled
block) is a type error.

### Cleanup on labeled break and continue

A labeled `break` or `continue` exits every intervening scope between
the statement and the target. For each such scope, in reverse order
of entry:

- Ordinary `defer` blocks run.
- `Drop` destructors for owned values run.
- `with` guards are released.

`errdefer` blocks do **not** run. `break` and `continue` are not
error returns; they are normal structured control transfers.

This is the same rule that already governs unlabeled `break` and
`continue`, applied across multiple scopes when a label requires it.

### Type and value

`break 'l` and `continue 'l` are statements. They have no value.

Labeled blocks are statement-position only in v1, so the question
of "what is the type of `let x = 'b: { ... break 'b ... }`?" does
not arise. Future block-as-expression work may extend labeled
break to carry values; the syntax `break 'l value` is syntactically
unambiguous and will compose cleanly when that work happens.

## Errors and diagnostics

The compiler produces specific errors for the following misuses.

**Undefined label.** `break 'foo` where no enclosing labeled
construct named `'foo` is in scope.

```
error: no enclosing loop or block labeled 'foo
  --> file.w:N:M
   |
   |     break 'foo
   |     ^^^^^^^^^^
help: in-scope labels are: 'outer, 'inner
```

**continue targeting a block.** `continue 'l` where `'l` labels
a block, not a loop.

```
error: cannot continue a labeled block; only loops support continue
  --> file.w:N:M
   |
   |     continue 'find
   |     ^^^^^^^^^^^^^^
note: 'find labels a block at file.w:K:L
help: use `break 'find` to exit the block, or label the enclosing loop
```

**Label collision.** A label nested directly inside another label
of the same name.

```
error: label 'l shadows enclosing label 'l
  --> file.w:N:M
   |
   |     'l: while ...
   |     ^^
note: enclosing 'l is at file.w:K:L
```

**Label without target.** A label declaration not immediately
followed by a `while`, `for`, or block.

```
error: label 'l must be followed by a loop or block
  --> file.w:N:M
   |
   |     'l: x = 1
   |     ^^^
```

**Label crossing function boundary.** A `break` or `continue` whose
label refers to a construct outside an enclosing nested function,
closure, `async:` block, or `gen fn`.

```
error: label 'outer is not visible inside this nested function
  --> file.w:N:M
   |
   |             break 'outer
   |             ^^^^^^^^^^^^
note: 'outer is declared in the enclosing function at file.w:K:L
note: labels do not cross function, closure, async, or gen boundaries
```

## Examples

### Multi-level break

```
fn find(grid: [[i32]], target: i32) -> bool:
    var found = false
    'rows: for row in grid:
        for cell in row:
            if cell == target:
                found = true
                break 'rows
    found
```

### Continue an outer loop

```
fn pairwise_skip(xs: [i32], ys: [i32]):
    'outer: for x in xs:
        for y in ys:
            if y > x: continue 'outer
            process(x, y)
```

### Labeled block for early exit

```
fn parse_header(input: bytes) -> Result[Header]:
    'parse:
        if input.len() < 4: break 'parse
        let magic = input[0..4]
        if magic != EXPECTED_MAGIC: break 'parse
        return Ok(read_header(input))
    Err("malformed header")
```

### Brace-form equivalents

The same examples in brace form, to make the duality concrete:

```
fn find(grid: [[i32]], target: i32) -> bool {
    var found = false
    'rows: for row in grid {
        for cell in row {
            if cell == target {
                found = true
                break 'rows
            }
        }
    }
    found
}

fn pairwise_skip(xs: [i32], ys: [i32]) {
    'outer: for x in xs {
        for y in ys {
            if y > x { continue 'outer }
            process(x, y)
        }
    }
}
```

### with-block transparency

A label declared outside a `with` block is visible inside it:

```
fn process(items: [Item]) -> Result[()]:
    'outer: for item in items:
        with lock = item.acquire():
            if item.is_terminal():
                break 'outer        // valid; 'outer crosses the with body
            do_work(item)
    Ok(())
```

### Migrator output (representative)

The kind of output the Beyond Relooper port will produce when
lowering a C function with non-trivial goto structure:

```
'L_function_body:
    'L_outer_loop: while true:
        if cond1: break 'L_outer_loop
        'L_inner_block:
            if cond2: break 'L_inner_block
            stmts_a
        stmts_b
        if cond3: continue 'L_outer_loop
        if cond4: break 'L_function_body
    cleanup
```

Compare to today's state-machine output for the same structure:

```
var __pc: i32 = 0
while true:
    match __pc:
        0 => { ...; __pc = 1; continue }
        1 => { ...; __pc = 2; continue }
        2 => { ...; if cond4 { __pc = 5; continue } else { __pc = 3 } }
        3 => { ...; break }
        _ => { break }
```

The labeled-break form is dramatically more readable, type-checks
naturally, and runs at native control-flow speed without dispatch
overhead.

## Implementation notes

### Frontend (lexer)

The lexer recognizes a label as a single token: apostrophe followed
immediately by an identifier. No whitespace between the apostrophe
and the identifier.

The token kind is `Label` with the identifier text (without the
leading apostrophe) as its value.

Single-quote-prefixed identifiers are reserved exclusively for
labels. Character literals, if introduced later, will use a
different syntax (e.g., `c'a'` or `char('a')`). This avoids the
lexer ambiguity that Rust inherited and matches the constraint
that we have no historical char-literal syntax to preserve.

### Frontend (parser)

The label prefix is uniform across constructs but interacts with
brace-form and colon-form bodies differently. The grammar makes
each case explicit:

```
label           := LABEL_TOKEN

while_stmt      := [label ':'] 'while' expr loop_body
for_stmt        := [label ':'] 'for' pat 'in' expr loop_body

loop_body       := brace_body | colon_body
brace_body      := '{' stmts '}'
colon_body      := ':' NEWLINE INDENT stmts DEDENT

labeled_block   := label ':' block_tail
block_tail      := brace_body | NEWLINE INDENT stmts DEDENT

break_stmt      := 'break' [label]
continue_stmt   := 'continue' [label]
```

Three notes on the grammar.

First, `loop_body` is the existing With construct — a `while` or
`for` loop body in either brace form or colon form. The label
prefix on `while_stmt` and `for_stmt` is independent of which
body style the loop uses.

Second, `labeled_block` is the new construct introduced by this
proposal. The label is required, never optional. There is no
unlabeled colon-form bare block in With — without a label there
would be nothing syntactically marking the start of the block.
Unlabeled brace blocks remain whatever they already are in With;
this proposal does not redefine them.

Third, in colon-form contexts, the label colon plays different
roles depending on what follows. For colon-form `while` and `for`
loops, the label colon and the loop-body colon are distinct — the
label colon ends the label, the loop-body colon (in `colon_body`)
introduces the body. For colon-form labeled blocks, there is only
one colon: the label colon is also the body introducer, because
there is no construct keyword between the label and the body.

The parser collapses the label prefix onto the target AST node
during construction. Existing AST nodes for `while`, `for`, and
brace blocks gain an optional `label: Option<LabelId>`. The
colon-form labeled block produces a new AST node
`LabeledBlock { label: LabelId, body: Stmts }` (the label is
required, hence non-optional). New fields on `BreakStmt` and
`ContinueStmt`: `target: Option<LabelId>`.

### Semantic analysis

A new `LabelEnvironment` tracks labels in scope during semantic
checking. It is a stack of frames, one per active labeled construct.
Each frame records:

- The label name.
- Whether it labels a loop (and which kind: `while` or `for`) or
  a block.
- The AST node it labels (for error reporting).

Entering a labeled construct pushes a frame; exiting pops it.
Crossing a function, closure, `async:` block, or `gen fn` boundary
pushes a sentinel that hides outer labels — labels above the sentinel
are not visible. `with` blocks do not push a sentinel; outer labels
remain visible.

Resolution of `break 'l` and `continue 'l`:

1. Walk the frame stack from innermost to outermost.
2. If a function-boundary sentinel is encountered before a match,
   error (label-crossing-function-boundary).
3. If a frame matches the label name, that is the target.
4. If `continue` and the matching frame is a block, error.
5. If no match, error (undefined label).

Label collision check: when pushing a frame, error if the label
name already appears in any enclosing frame within the current
function body. The check fires only on direct nested shadowing;
sibling labeled constructs reusing the same name are fine because
the first frame has been popped before the second is pushed.

### IR / lowering

The MIR (or intermediate IR) representation of a break or continue
includes the resolved target — typically a unique ID referring to
the labeled scope. Resolution happens during lowering from the AST,
not during codegen.

For unlabeled break/continue, the resolved target is the innermost
enclosing loop, exactly as today.

For labeled break/continue, the resolved target is the construct
named by the label.

After resolution, the IR no longer carries label names. It carries
scope IDs. Existing optimization passes that work with break and
continue need only minor changes — they need to handle break
targeting a scope that isn't the innermost.

### Codegen (LLVM backend)

LLVM has no labels at the IR level; it has basic blocks and
branches. A break or continue lowers to an unconditional branch
to the appropriate basic block:

- `break 'l` branches to the basic block immediately after the
  construct labeled `'l`.
- `continue 'l` branches to:
  - The condition-check block, if `'l` labels a `while` loop.
  - The iterator-advance / next-element block, if `'l` labels a
    `for` loop.

The lowering needs to know, at each break or continue, the basic
block ID for the target. This is straightforward when the construct
has already been laid out — we record per-construct the
"after-block" and (for loops) the appropriate "continue-block"
when generating the construct's own code.

Labeled blocks introduce one new piece of bookkeeping: a block that
has a label needs an "after-block" because something might break
to it. Unlabeled blocks don't need this — their code flows linearly
into whatever follows.

Cleanup code for `defer`, `Drop`, and `with` guards is emitted in
the same way as for unlabeled break and continue: the codegen
walks the scope chain from innermost outward, emitting cleanup for
each scope being exited, until it reaches the target. `errdefer`
blocks are skipped, because `break` and `continue` are not error
returns.

### Implementation phases

Phase 1: lexer and parser.
- Add Label token (apostrophe + identifier, no whitespace).
- Add label syntax to `while`, `for`, and block statements, in
  both brace-form and colon-form.
- Add optional label operand to `break` and `continue`.
- AST nodes carry label fields.

Phase 2: semantic analysis.
- LabelEnvironment with function/closure/async/gen boundary
  sentinels and `with`-transparent scoping.
- Resolution for labeled break and continue.
- Diagnostics for the five error cases.

Phase 3: IR lowering.
- Translate AST labels to scope IDs.
- Update IR for break and continue to carry scope ID.

Phase 4: Codegen.
- LLVM lowering recognizes scope IDs and branches to the correct
  basic block per loop kind.
- Labeled blocks gain an after-block.
- Cleanup walks emit `defer`, `Drop`, and `with` guard release;
  skip `errdefer`.

Phase 5: Tests.
- Selfhost regression tests for each form.
- Diagnostic tests for each error.
- End-to-end runtime tests verifying control flow.

Each phase ends with `make build`, `make fixpoint`, and `make test`
passing. Phases land as separate commits.

### Selfhost implications

The compiler is self-hosted. After Phase 1 adds the syntax, the
compiler can parse the new forms but does not yet understand them.
After Phase 4 lands, the compiler accepts and compiles labeled
break and continue.

The compiler itself does not need to use the new feature for its
own implementation. Existing With code in the compiler continues
to use unlabeled break and continue. The migrator's generated
output will use labeled forms.

If we want the bootstrap chain to test labeled break and continue
at each stage, we can introduce one or two uses in the compiler
source after Phase 4. This is good practice but not required.

### Migration of existing code

No migration needed. The feature is additive. All existing With
code continues to work without changes.

## Acceptance criteria

The feature is considered complete when:

1. Each of the five error diagnostics fires correctly with the
   specified message structure.
2. The selfhost regression suite includes at least one test per
   syntactic form, in both colon-form and brace-form:
   - Labeled `while`
   - Labeled `for`
   - Labeled block
   - `break` with label (loop target)
   - `break` with label (block target)
   - `continue` with label (loop target)
   - `with`-transparency: a labeled outer loop, broken from inside
     a `with` body
   - Function-boundary opacity: a `break` or `continue` inside a
     nested function or closure that fails to find an outer label
3. `make build`, `make fixpoint`, and `make test` all pass at each
   phase boundary.
4. The compiler emits correct LLVM IR for nested labeled loops,
   verified against hand-written equivalents and with cleanup
   ordering for `defer`, `Drop`, and `with` guards (and
   `errdefer` correctly skipped).
5. The migrator port can use the feature to lower goto-containing
   C functions.

## References

- Rust reference, "Loop labels":
  https://doc.rust-lang.org/reference/expressions/loop-expr.html#loop-labels
- Java Language Specification, sections on labeled statements,
  break, and continue.
- Norman Ramsey, "Beyond Relooper: recursive translation of
  unstructured control flow to structured control flow." ICFP 2022.
  (Establishes the algorithmic context for why the migrator needs
  this feature.)