# `with migrate` — Implementation Plan

> Historical note: sections that discuss `__pc` state-machine goto
> lowering describe the old plan. Current goto lowering builds a
> migrator CFG and emits labeled blocks/loops through
> `std.cfg.stackify`.

**Spec:** `docs/with-migrate-spec.md`
**Reference:** `.reference/translate-c/` (Zig's translate-c, 10,469 LOC)
**Goal:** Guaranteed-correct C-to-With translation.

---

## Zig translate-c — Patterns to Follow

Zig's translate-c (`Translator.zig`, 4,449 lines) is the north
star. Key architectural decisions to adopt:

### 1. Intermediate AST, not string concatenation

Zig builds a **typed Zig AST** (`ast.zig`, 3,114 lines) and then
renders it to source text. With's CImport.w concatenates strings
directly. This works but is fragile.

**Decision:** Keep string concatenation for v1. The existing
CImport.w translator is already 4,627 lines of working string
concat. Introducing an intermediate AST would be a rewrite.
Adopt the AST approach in v2 if the string approach hits walls.

### 2. Scope as a struct hierarchy, not pipe-delimited strings

Zig uses `Scope.zig` (441 lines) with a proper scope struct:
`Scope.Block` with `variables: AliasList`, `mangle_count: u32`,
`label: ?[]const u8`, and a `parent` pointer chain. Variables
are looked up by walking the parent chain (`getAlias`). Name
mangling increments `mangle_count` per block.

CImport.w uses pipe-delimited strings (`"|name|"` or
`"|name=mangled|"`). This works but limits what we can express.

**Decision:** Keep pipe-delimited strings for v1. Refactor to
proper Scope struct in v2. The current approach handles shadowing
and mangling correctly.

### 3. Switch fallthrough via statement duplication

Zig's `transSwitch` (lines 1942–2025) handles fallthrough by
**duplicating statements into each case prong**. When case 1
falls through to case 2, case 1's prong contains both case 1's
body AND case 2's body. The `transSwitchProngStmtInline` function
(lines 2088–2130) walks the remaining switch body collecting
all statements until a `break` or `return`.

This is cleaner than a state variable for switch fallthrough.

**Decision:** Adopt Zig's duplication approach for switch.

### 4. Goto is TODO in Zig

Zig's translate-c does NOT support goto (lines 1705–1706):
```zig
.goto_stmt, .computed_goto_stmt, .labeled_stmt => {
    return t.fail(error.UnsupportedTranslation, stmt.tok(t.tree), "TODO goto", .{});
},
```

**This is where we go beyond Zig.** Our state-variable transform
will handle what Zig cannot. This is a competitive advantage.

### 5. Error handling via error union returns

Zig returns `TransError` (union of `TypeError`,
`UnsupportedTranslation`, `SelfReferential`). When a construct
can't be translated, it returns an error and the caller decides
how to handle it (skip, emit comment, emit opaque type, etc.).

CImport.w returns empty string `""` on failure, or emits
`comptime_error(...)`.

**Decision:** Keep CImport.w's approach. Return `""` on failure,
caller emits fallback. For migrate mode, never silently skip —
emit `comptime_error` with explanation.

### 6. Bool coercion is type-aware

Zig's `transBoolExpr` checks the C type and inserts appropriate
conversions (int→bool via `!= 0`, pointer→bool via `!= null`).

CImport.w has `ci_trans_bool_expr` that does the same thing.
Already aligned.

### 7. Wrapping arithmetic for unsigned types

Zig emits `+%` (add_wrap), `-%` (sub_wrap), `*%` (mul_wrap) for
unsigned integer operations. CImport.w does the same via
`ci_bo_to_str_typed`.

Already aligned.

### 8. Switch wrapped in while(true)

Zig wraps every switch in `while (true) { switch (expr) { ... } break; }`
to allow break statements to exit the switch (since Zig's switch
is an expression). This pattern converts a C switch-statement
into something that works with Zig's expression-based switch.

With's `match` is a statement, not an expression, and `break`
inside match arms works differently. We don't need this wrapper.

**Decision:** Don't wrap in while(true). Use `match` for
non-fallthrough switches and the duplication approach for
fallthrough.

---

## What Already Exists (CImport.w, 4,627 lines)

All of the following are implemented and working:

- **libclang integration:** parse session, cursor API (`with_ci_*`)
- **Type translation:** C→With types, 18 implicit cast kinds,
  pointer/array/function types
- **Declarations:** structs (packed, aligned, anonymous nested),
  enums, typedefs, globals, function signatures, calling conventions,
  variadic functions
- **Expressions:** all binary/unary ops, wrapping arithmetic for
  unsigned, pointer arithmetic (`ptr+idx`, `ptr-ptr`), array
  subscript, member access (`.` and `->`), function calls,
  ternary, sizeof, compound literals, initializer lists,
  designated initializers, comma expressions, pre/post inc/dec,
  statement expressions, `_Generic`
- **Statements:** compound blocks, return, if/else, while, for,
  do-while, break, continue, switch (no fallthrough), local decls
- **Scope:** variable shadowing via name mangling, scope propagation
  via `SCOPE:` prefix protocol
- **Bool coercion:** type-aware (int→`!=0`, ptr→`!=null`, float→`!=0.0`)
- **Names:** reserved word escaping, two-pass collision resolution
  (strong/weak), member function detection
- **Macros:** integer/float/string/char constants, simple
  function-like macros, expression evaluation

---

## Implementation Steps

### Step 1: File-level driver

**Creates:** `pub fn migrate_c_file(...)` inside CImport.w
**Est:** ~150 LOC

Add migrate mode to CImport.w. The key difference from
`process_c_import`: translate ALL function bodies, not just
`static inline`.

**1a.** Add a module-level flag or parameter:

```
pub fn migrate_c_file(input_path: str, output_path: str,
                       include_paths: Vec[str]) -> i32:
    ci_set_include_paths(include_paths)
    // Read file, pass as #include to libclang
    let session = with_cimport_parse("#include \"" ++ input_path ++ "\"")
    if session == 0: return 1
    ...
```

**1b.** Fork `ci_translate_function` for migrate mode:

The existing function (line 577) has this guard at line 614:
```
if storage == CX_SC_STATIC and is_inline == 0:
    return ""  // skip non-inline static functions
```

In migrate mode: **remove this guard.** Translate every function.

Also change the fallback behavior: when `ci_try_translate_fn_body`
returns `""` (translation failed), the current code silently
demotes to `extern fn`. In migrate mode: emit the function with
`comptime_error("body translation failed")` as the body.

**1c.** For non-static functions, prepend `@[c_export("name")]`.
Detection: `with_cimport_fn_storage_class(session, idx) != CX_SC_STATIC`

**1d.** Emit header:
```
// Generated by: with migrate <filename>
c_import("<stdlib.h>")
c_import("<string.h>")
```

**Done when:** `with migrate hello.c` translates a trivial C
file with function bodies. Every function has a body (no extern
stubs).

---

### Step 2: Switch fallthrough — Zig's duplication approach

**Modifies:** `ci_trans_switch_body` in CImport.w
**Est:** ~100 LOC
**Reference:** Zig `transSwitch` (lines 1942–2025),
`transSwitchProngStmtInline` (lines 2088–2130)

Replace the current fallthrough handling (if/else chain) with
Zig's statement duplication approach.

**Algorithm (following Zig exactly):**

For each case in the switch body:
1. Call `ci_trans_case_items` — collect the case value(s),
   chasing nested case/default chains
2. Call `ci_trans_switch_prong` — starting from this case's
   first real statement, walk FORWARD through the remaining
   switch body, translating each statement until hitting
   a `break`, `return`, `goto`, or `continue`
3. If during the forward walk we encounter another `case` or
   `default`, chase through its labels to its body and continue
   translating (this is the duplication — we include the next
   case's statements in the current prong)

**Example:**
```c
switch (x) {
    case 1: a(); // falls through
    case 2: b(); break;
    case 3: c(); break;
}
```

Produces:
```
match x:
    1 ->
        a()
        b()    // duplicated from case 2
    2 -> b()
    3 -> c()
```

For cases without fallthrough (the common case, detected by
`ci_stmt_ends_with_break`), emit a clean single-body match arm.

**Done when:** Switch with fallthrough, including cascading
fallthrough across 3+ cases, produces correct output. Test with
Duff's device.

---

### Step 3: Goto detection and label collection

**Adds to:** CImport.w
**Est:** ~60 LOC

```
fn ci_function_has_goto(session: i64, cursor: i32) -> bool:
    // Recursive walk. Return true if any child is kind 232 (GotoStmt).

fn ci_collect_labels(session: i64, cursor: i32) -> str:
    // Recursive walk. For every LabelStmt (kind 233), collect:
    //   "|labelname=stateN|" where N is sequential from 1.
    // Entry block is always state 0.
    // Return pipe-delimited label→state map.

fn ci_goto_target(session: i64, cursor: i32) -> str:
    // For a GotoStmt cursor, return the target label name.
    // libclang: with_ci_cursor_spelling on GotoStmt = target label.
```

**Done when:** Can identify goto-containing functions and map
every label to a state ID.

---

### Step 4: Variable hoisting for goto functions

**Adds to:** CImport.w
**Est:** ~80 LOC

```
fn ci_collect_all_var_decls(session: i64, cursor: i32,
                             names: &mut str, types: &mut str):
    // Recursive walk of function body.
    // For every VarDecl (kind 9, inside DeclStmt kind 231):
    //   Append "|name|" to names, "|type|" to types.
    // Skip duplicates (same name already collected).
```

In the state-machine emitter (Step 5), before the dispatch loop,
emit one `var name: type = default` for each collected variable.
Use `ci_default_for_type` for zero initialization.

At the original declaration site inside the state machine, emit
only the assignment (`name = init_expr`), not a new `var`.

**Done when:** A function with variables declared inside goto-
targeted blocks compiles after hoisting.

---

### Step 5: State-variable transform

**Adds to:** CImport.w
**Est:** ~300 LOC

This is the core new feature — what Zig's translate-c cannot do.

```
fn ci_trans_goto_function(session: i64, fn_cursor: i32,
                           decl_idx: i32) -> str:
```

**Algorithm:**

1. Find the CompoundStmt body (same as `ci_try_translate_fn_body`)
2. Build scope from parameters (same approach)
3. Collect all labels → state map (Step 3)
4. Collect all var decls → hoisted vars (Step 4)
5. Emit function header + hoisted vars
6. Emit `var __pc: i32 = 0`
7. Emit dispatch loop + match

**The dispatch loop:**

```
var __pc: i32 = 0
while true:
    match __pc:
        0 ->
            // entry block statements
        1 ->    // label_a:
            // label_a's statements
        2 ->    // label_b:
            // label_b's statements
        ...
        _ -> break
```

**Walking the body to build blocks:**

Walk the CompoundStmt's children linearly. Maintain a
`current_state: i32` starting at 0.

For each child:
- **LabelStmt (kind 233):** Close current match arm with
  `__pc = next_state; continue`. Start new arm with the
  label's state ID. Recurse into the label's body child.
- **GotoStmt (kind 232):** Emit `__pc = target_state; continue`
  where target_state is looked up from the label map.
- **ReturnStmt:** Emit `return expr` (exits the function).
- **All other statements:** Translate with `ci_trans_stmt`
  normally.
- **End of block (before next label or end of function):**
  Emit `__pc = next_state; continue` (fallthrough).

**Handling goto inside nested control flow:**

When a goto appears inside an `if` or `while` within a labeled
block, the existing `ci_trans_stmt` emits
`comptime_error("goto not supported")`. We need a variant.

Add `ci_trans_stmt_goto_mode(session, cursor, indent, scope, label_map) -> str`:
- Same as `ci_trans_stmt` but replaces kind 232 (GotoStmt) with
  `__pc = target_state; break` instead of `comptime_error`.
- For LabelStmt inside nested code: emit the body normally (rare
  case — labels inside if/while are unusual).

The `break` exits the innermost loop/if. After each `while` or
`for` loop inside a match arm, insert:
```
if __pc != current_state:
    continue    // a goto inside the loop changed __pc; re-dispatch
```

This ensures that a goto from inside a nested loop correctly
re-enters the dispatch loop.

**Test cases (from spec):**

```c
// Forward goto (cleanup pattern)
int test1() {
    int *p = malloc(sizeof(int));
    if (!p) goto fail;
    *p = 42;
    int result = *p;
    goto done;
fail:
    result = -1;
done:
    free(p);
    return result;
}

// Backward goto (loop)
int test2() {
    int i = 0;
again:
    if (i >= 10) goto end;
    i++;
    goto again;
end:
    return i;
}

// Goto inside if
int test3(int x) {
    if (x > 0) goto positive;
    return -1;
positive:
    return x * 2;
}

// Mutual gotos (state machine)
int test4(const char *s) {
    int state = 0;
state_a:
    if (*s == 0) return state;
    if (*s == 'x') { state = 1; goto state_b; }
    s++;
    goto state_a;
state_b:
    if (*s == 0) return state;
    if (*s == 'y') { state = 0; goto state_a; }
    s++;
    goto state_b;
}
```

**Done when:** All four test functions translate to compilable
With and produce identical output to the C versions.

---

### Step 6: Type topological ordering

**Adds to:** CImport.w
**Est:** ~60 LOC

Currently `process_c_import` emits types in declaration order.
For self-contained translation, types must be in dependency order.

```
fn ci_topological_sort_types(session: i64, count: i32) -> Vec[i32]:
    // 1. For each struct, check field types.
    //    If field type is another struct BY VALUE (not pointer):
    //    add edge A → B (A depends on B).
    // 2. Kahn's algorithm: BFS with in-degree tracking.
    // 3. Return sorted declaration indices.
    // 4. Cycles (mutual by-value reference): break with opaque forward decl.
```

**Done when:** Structs that reference each other by value are
emitted in correct dependency order.

---

### Step 7: Multi-file and directory mode

**Adds to:** CImport.w
**Est:** ~100 LOC

```
pub fn migrate_c_directory(input_dir: str, output_dir: str,
                            include_paths: Vec[str]) -> i32:
    // 1. Use with_system("find <dir> -name '*.c' -not -name '.*'")
    //    to enumerate .c files.
    // 2. Parse output, iterate each file.
    // 3. Track emitted names across files via
    //    with_cimport_is_name_emitted / mark_name_emitted.
    // 4. First file gets type definitions (c_void, c_int, etc.).
    //    Subsequent files reuse via dedup.
    // 5. Emit shared types in _types.w if >1 file shares them.
    // 6. Call migrate_c_file for each .c file.
```

**Done when:** `with migrate dir/ -o out/` produces a coherent
set of `.w` files that compile together.

---

### Step 8: CLI integration

**Modifies:** `src/main.w` (line 318), `src/Migrate.w`
**Est:** ~100 LOC

Replace the stub at main.w:318:
```
if cli_command(argc) == "migrate":
    return run_migrate_command(argc)
```

Implement `run_migrate_command`:
- Parse positional arg (file or directory path)
- Parse `-o`, `-I`, `-D`, `--check`, `--diff`, `--stats`
- Detect language: if path ends in `.c` or directory contains
  `.c` files → C migration. Otherwise check for explicit `rust`,
  `zig`, `swift`, `go` arg (for future migrate specs).
- Call `migrate_c_file` or `migrate_c_directory`
- Print summary stats

**Modes:**
- **write** (default): translate and write .w files
- **check**: translate to string, compare, exit 1 if different
- **diff**: translate to string, print diff to stdout
- **stats**: count gotos, unsafe blocks, print summary

**Done when:** `with migrate foo.c` and `with migrate src/ -o out/`
work from the command line with all modes.

---

### Step 9: Polish and edge cases

**Est:** ~100 LOC

- **Computed goto** (`goto *ptr`): emit `comptime_error("computed goto")`.
  PCRE2 doesn't use these. Very rare.
- **`setjmp`/`longjmp`**: emit as extern fn calls via c_import.
  They just work — they're C library functions.
- **Volatile access**: emit `unsafe { volatile_read(ptr) }` /
  `unsafe { volatile_write(ptr, val) }`.
- **Bit-fields**: keep existing behavior (demote struct to opaque).
- **Inline assembly**: emit `comptime_error("inline asm")`.
- **Complex macros not handled by macro translator**: already
  expanded by libclang at call sites — the AST contains expanded
  code. Drop the macro definition, emit a comment.
- **`--stats` output**: count gotos, unsafe blocks, translated
  lines, skipped constructs.

**Done when:** No known C construct causes a crash or silent
mis-translation.

---

### Step 10: PCRE2 validation

Not implementation work — validation and bug fixing.

1. Clone PCRE2 to `.reference/pcre2/`
2. Run `with migrate .reference/pcre2/src/ -o lib/std/pcre2/ --prefer-brace --stats`
3. Exclude `pcre2_jit_compile.c` (inline asm, code gen — skip)
4. Build migrated code with `with build`
5. Fix translation bugs found by compilation failures
6. Build migrated `pcre2test` against the migrated With PCRE2 modules
7. Run PCRE2's test suite
8. Fix any remaining bugs
9. Iterate until all tests pass

**Done when:** migrated `pcre2test` passes against With-compiled PCRE2.

---

## Dependency Graph

```
Step 1 (driver) ─────→ Step 3 (goto detect) ──→ Step 4 (var hoist) ──→ Step 5 (state machine)
      │
      └─→ Step 2 (switch fallthrough) — independent of goto work
          Step 6 (type ordering) — independent
          Step 8 (CLI) — depends on Step 1

Step 7 (multi-file) — depends on Steps 1, 6, 8
Step 9 (polish) — depends on Steps 1–5
Step 10 (PCRE2) — depends on all
```

Steps 2, 6 can proceed in parallel with Steps 3–5.

---

## Size Estimates

| Step | Est. LOC | Notes |
|---|---|---|
| 1. File driver + export mode | 150 | Fork of process_c_import |
| 2. Switch fallthrough (Zig-style dup) | 100 | Replace ci_trans_switch_body |
| 3. Goto detection + label map | 60 | Recursive AST walks |
| 4. Variable hoisting | 80 | Recursive var collection |
| 5. State-variable transform | 300 | Core new feature |
| 6. Type ordering | 60 | Kahn's algorithm |
| 7. Multi-file | 100 | Directory walk + dedup |
| 8. CLI | 100 | Arg parsing + modes |
| 9. Polish + edge cases | 100 | Computed goto, volatile, etc. |
| **Total new code** | **~1,050** | Plus test harness |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Goto inside nested while/for | High | High | `ci_trans_stmt_goto_mode` + post-loop `__pc` check |
| `break` targets inner loop not dispatch | High | High | Use `break` + post-loop re-dispatch check |
| Variable shadowing across goto blocks | Medium | Medium | Hoisting + existing scope mangling |
| Recursive type cycles | Low | Low | Break with opaque forward decl |
| libclang doesn't expose goto target | Verified OK | — | `with_ci_cursor_spelling` returns target label |
| PCRE2 uses computed goto | Low | Medium | `comptime_error` — PCRE2 doesn't use them |
| Switch with goto inside case | Medium | Medium | Goto-mode switch translation |

---

## Verification

After each step:
```
make build          # compiler compiles
make fixpoint       # stage2 == stage3
make test           # no regressions
```

After Step 5:
```
# Write C test files with goto patterns, migrate, compile, run:
echo '<test.c content>' > /tmp/test_goto.c
with migrate /tmp/test_goto.c -o /tmp/test_goto.w
with build /tmp/test_goto.w
./test_goto    # verify identical output to C version
```

After Step 10:
```
with migrate .reference/pcre2/src/ -o lib/std/pcre2/ --prefer-brace --stats
with build lib/std/pcre2/
cc -o pcre2test pcre2/src/pcre2test.c -L out/lib -lpcre2
./pcre2test pcre2/testdata/testinput1
# All tests must pass
```
