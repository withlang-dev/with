# Plan: Implement Three Block Body Forms (docs/three-block-types.md)

## Context

`docs/three-block-types.md` specifies that every construct in With that introduces a
statement or expression body must support exactly three interchangeable body forms:

1. **Inline colon** — `if cond: expr` (single item, same line, newline-terminated)
2. **Indented colon** — `:` at end of line, indented block follows
3. **Braced** — `{ body }` directly after the construct's header, whitespace-insensitive

The spec also requires:
- After a construct's header, if neither `:` nor `{` follows → parse error
- Remove `=` as a body-introducing token for function/method bodies
- Remove `then` as a body-introducing token for if/else bodies
- All three forms produce identical AST; lowering and codegen are unchanged

---

## Gap Analysis

| Construct | Inline `:` | Indented `:` | Braced `{}` | Bad forms to remove |
|-----------|:----------:|:------------:|:-----------:|:--------------------|
| `fn` | ✓ | ✓ | ✓ | `= expr` (5 parser sites) |
| `if / else` | ✓ | ✓ | ✓ | `then expr` (86 usages, 2 parser sites) |
| `while` | ✓ | ✓ | ✓ | colon optional (needs enforcement) |
| `for` | ✓ | ✓ | ✓ | colon optional (needs enforcement) |
| `loop` | ✓ | ✓ | ✓ | colon optional (needs enforcement) |
| `unsafe` | ✓ | ✓ | ✓ | colon optional (needs enforcement) |
| `with expr as x` | ✓ | ✓ | ✓ | colon optional (needs enforcement) |
| `defer` | ✗ | ✗ | ✗ | — |
| `errdefer` | ✗ | ✗ | ✗ | — |
| `comptime` | ✗ | ✗ | ✗ | — |
| match arms (indented) | ✓ | ✓ | ✗ | — |

---

## Implementation Phases

### Phase 1 — Fix missing three-form dispatch

**1a. `parse_defer` and `parse_errdefer`** (`Parser.w` lines 4121–4131)

Both currently call `parse_expr()` with no colon/brace dispatch. Change to the
standard pattern (matching `parse_unsafe` lines 4133–4144):

```
fn Parser.parse_defer(self: Parser) -> NodeId:
    let start = self.current_start()
    self.advance()
    var body: NodeId = 0 as NodeId
    if self.peek() == TokenKind.TK_L_BRACE:
        self.advance()
        body = self.parse_braced_body()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
        body = self.parse_block_or_expr()
    else:
        self.emit_error("expected ':' or '{' after 'defer'")
        body = self.parse_block_or_expr()  // error recovery
    self.pool.add_node(NodeKind.NK_DEFER, start, self.prev_end(), body, 0, 0)
```

Apply identically to `parse_errdefer`.

**Lowering:** `lower_defer` (MirLower.w:5053) pushes `d0` onto `defer_nodes` and
later re-lowers it with `lower_expr`. `lower_expr` already handles `NK_BLOCK`,
so a block body works without any lowering changes.

**1b. `parse_comptime_expr`** (`Parser.w` line 4265)

Currently calls `parse_expr()` only. Apply the same three-form dispatch.

**Lowering:** `try_eval_const` (MirLower.w:1340) calls `try_eval_const(d0)`.
For `NK_BLOCK` inner nodes it returns the "not constant" sentinel — correct and
safe. Normal lowering proceeds via the runtime lowering path (MirLower.w:5451).

**1c. Match arms braced form** (`Parser.w` line 4815)

`parse_match_arms` (indented match form) currently calls `parse_block_or_expr()`
directly after `=>`. Add braced check before:

```
var body: NodeId = 0 as NodeId
if self.peek() == TokenKind.TK_L_BRACE:
    self.advance()
    body = self.parse_braced_body()
else:
    // preserve leading newline for indentation detection
    body = self.parse_block_or_expr()
```

The inline match arm form (`parse_inline_match_arms` line 4837) already supports
both braced and inline — no change needed there.

---

### Phase 2 — Extract unified `parse_body()` with error enforcement

The spec states: "The parser routes all such constructs through a single
body-parsing path; consistency is structural, not enforced per-construct."

Currently the dispatch pattern is duplicated across ~10 constructs. Extract a
shared helper in `Parser.w`:

```
fn Parser.parse_body(self: Parser) -> NodeId:
    if self.peek() == TokenKind.TK_L_BRACE:
        self.advance()
        return self.parse_braced_body()
    else if self.peek() == TokenKind.TK_COLON:
        self.advance()
        return self.parse_block_or_expr()
    else:
        self.emit_error("expected ':' or '{' to introduce body")
        return self.parse_block_or_expr()  // error recovery: attempt to continue
```

Replace duplicated body dispatch in these functions with `self.parse_body()`:

| Function | Lines (approx) |
|----------|----------------|
| `parse_while` | 4392–4398 |
| `parse_loop` | 4434–4440 |
| `parse_for` (main body) | 4473–4479 |
| `parse_for` (else body) | 4496–4500 |
| `parse_unsafe` | 4137–4143 |
| `parse_labeled_block` | 4673–4678 |
| `parse_defer` | (Phase 1 result) |
| `parse_errdefer` | (Phase 1 result) |
| `parse_comptime_expr` | (Phase 1 result) |
| `parse_with_expr` (3 variants) | 5410–5486 |

Note: `parse_if_expr` is NOT replaced with `parse_body()` because it is also
losing the `then` form (Phase 4) and handles `if_chain_form` tracking. It gets
its own targeted fix.

Note: `parse_fn_decl` and method-body parsing sites (Phase 3) are handled
separately because they also remove the `=` form.

---

### Phase 3 — Remove `=` body form from function/method declarations

The spec's inline form is `:`, not `=`. No usages of `fn f() = expr` were found
in the codebase (grep confirmed 0 matches), so this is a parser-only change.

**Parser sites to update** (remove `or self.peek() == TokenKind.TK_EQ` from
each condition and update error messages):

| Line | Context |
|------|---------|
| 726 | Top-level function body |
| 1943 | Method body in impl block |
| 2029 | Method body in impl block (alternate path) |
| 2187 | Method body in trait |
| 2258 | Method body in trait (alternate path) |

Before (example, line 726):
```
if self.peek() == TokenKind.TK_EQ or self.peek() == TokenKind.TK_COLON:
    self.advance()
    body = self.parse_block_or_expr()
else if self.peek() == TokenKind.TK_L_BRACE:
    self.advance()
    body = self.parse_braced_body()
else:
    self.emit_error("expected '=', ':' or '{'")
```

After (using `parse_body()` from Phase 2):
```
body = self.parse_body()
```

After Phase 3, the `TK_EQ` token no longer has any role as a body introducer.

---

### Phase 4 — Remove `then` form from if/else

**Scope:** 86 usages of `then` across `src/`, `lib/`, `test/`, `examples/`.

**Bootstrap constraint:** The compiler is self-hosting. `src/` and `lib/` are
compiled by the seed compiler (which still supports `then`). Removal must happen
in two commits:

**Commit A — Migrate all `then` usages to `:` form**

This commit removes every usage of `then` while the parser still accepts it.
The seed compiler can compile both old and new forms.

Files to migrate (non-exhaustive list from grep):
- `src/render.w:429` — render.w emits `then` when pretty-printing if expressions.
  Change emitted string from `" then "` to `": "`. This affects debug output.
- `src/main.w:1362` — keyword list in help text: remove `then` from the list
- `src/bootstrap_main.w:219` — same keyword list
- `src/main_emit_temp.w:712` — same keyword list
- `lib/test/runner.w:33` — `if passed == total then 0 else 1`
- `lib/std/math.w:31,35,39,43,47,51,55,56` — 8 usages of `then`
- `lib/std/alloc.w:20,31,37` — 3 usages
- `lib/std/process.w:45` — 1 usage
- `test/**/*.w` — ~45 test files with `then` usages
- `examples/**/*.w` — ~28 example files with `then` usages

Migration rule: `if X then Y` → `if X: Y` and `if X then Y else Z` → `if X: Y else: Z`

After Commit A: `make build && make fixpoint` must pass. `then` is unused but
the parser still accepts it.

**Commit B — Remove `then` from the parser**

Remove `TK_KW_THEN` handling from `parse_if_expr` (two sites: lines 3944, 4036).
Also remove the `if_chain_form` tracking variable and its associated mixing-error
logic — after removing `then`, the only forms are `:` and `{`, both of which are
freely mixable per the spec. The `if` construct's body dispatch becomes:

```
if self.peek() == TokenKind.TK_L_BRACE:
    self.advance()
    then_body = self.parse_braced_body()
else if self.peek() == TokenKind.TK_COLON:
    self.advance()
    then_body = self.parse_block_or_expr()
else:
    self.emit_error("expected ':' or '{' after if condition")
    then_body = self.parse_block_or_expr()  // error recovery
```

Apply the same pattern to the `else if` and `else` arm parsing.

After Commit B: `make build && make fixpoint` must pass.

---

### Phase 5 — Save plan and add tests

**Save plan to repo:**
Create `docs/plans/` directory and write
`docs/plans/three-block-types-impl.md` with this plan content.

**New test files:**

`test/parser/ast_three_body_forms_defer.w`
- `defer: expr` (inline)
- `defer:\n    expr` (indented)
- `defer { expr }` (braced)
- Same three forms for `errdefer`

`test/parser/ast_three_body_forms_comptime.w`
- `comptime: expr`, `comptime:\n  expr`, `comptime { expr }`

`test/parser/ast_three_body_forms_match.w`
- `pat => { body }` in indented match (braced form)
- Verify produces same AST as `pat => body`

`test/behavior/behav_defer_block.w`
- Defer with multi-statement indented body — verify all statements execute at scope exit in LIFO order

`test/behavior/behav_comptime_block.w`
- `comptime { expr }` and `comptime:\n  expr` parse and lower without error

`test/compile_errors/err_body_missing_colon_brace.w`
- Verify that `while cond\n  body` (no `:` or `{`) now produces a parse error
- Similar for `for`, `loop`, `unsafe`

---

## Files to Modify

| File | Phase | Change summary |
|------|-------|----------------|
| `src/Parser.w` | 1–4 | ~80 lines changed; add `parse_body()` helper, fix 3 constructs, remove `=` and `then` |
| `src/render.w` | 4A | Change `" then "` to `": "` in if expression rendering |
| `src/main.w` | 4A | Remove `then` from keyword list |
| `src/bootstrap_main.w` | 4A | Remove `then` from keyword list |
| `src/main_emit_temp.w` | 4A | Remove `then` from keyword list |
| `lib/test/runner.w` | 4A | 1 usage |
| `lib/std/math.w` | 4A | 8 usages |
| `lib/std/alloc.w` | 4A | 3 usages |
| `lib/std/process.w` | 4A | 1 usage |
| `test/**/*.w` | 4A | ~45 files with `then` usages |
| `examples/**/*.w` | 4A | ~28 files with `then` usages |
| `docs/plans/three-block-types-impl.md` | 5 | New file |
| `test/parser/ast_three_body_forms_*.w` | 5 | New test files |
| `test/behavior/behav_defer_block.w` | 5 | New test file |
| `test/compile_errors/err_body_missing_colon_brace.w` | 5 | New test file |

No changes to `MirLower.w`, `Codegen.w`, `SemaCheck.w`, or `Ast.w`.

---

## Commit Ordering

```
Commit 1: Phases 1+2+3 — defer/errdefer/comptime three-form support,
          unified parse_body(), = removal, match arm braced form
          → make build && make fixpoint && make test

Commit 2: Phase 4A — migrate all then usages in src/lib/test/examples
          → make build && make fixpoint && make test
          (then still accepted by parser, but no usages remain)

Commit 3: Phase 4B — remove then from parser
          → make build && make fixpoint && make test

Commit 4: Phase 5 — save plan, add new tests
          → make build && make fixpoint && make test
```

---

## Verification Gates

After each commit:
```
make build      # must pass (seed → stage1 → stage2)
make fixpoint   # stage2 == stage3 (byte-identical)
make test       # no regressions; new tests pass
```

Manual spot-checks:
```
./out/bin/with-stage2 check test/parser/ast_three_body_forms_defer.w
./out/bin/with-stage2 check test/behavior/behav_defer_block.w
./out/bin/with-stage2 check test/compile_errors/err_body_missing_colon_brace.w
```
