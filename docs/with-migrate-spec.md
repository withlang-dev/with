# `with migrate` — C-to-With Source Translator

**Guaranteed-correct translation of C source files to With.**

The output compiles, links, and produces identical behavior to the
original C. No human review required for correctness. The migrated
code can be incrementally cleaned up later.

---

## Design Goals

1. **100% success on valid C.** Every compilable C file produces a
   compilable With file with identical runtime behavior. No
   `comptime_error` stubs. No "manual fixup needed."

2. **Preserve the test suite.** If the C project's tests pass
   before migration, they pass after migration. The user migrates
   the source, not the tests.

3. **Ugly but correct first.** The output is mechanically
   translated, not idiomatic. It uses `unsafe` liberally. Cleanup
   is a separate, optional pass.

4. **One command.** `with migrate pcre2/src/ -o lib/std/regex/`
   translates an entire directory.

---

## Usage

```
with migrate foo.c                    # writes foo.w
with migrate foo.c -o bar.w           # explicit output path
with migrate src/ -o out/             # directory mode
with migrate src/ --check             # dry run: exit 1 if changes needed
with migrate src/ --diff              # show unified diff
with migrate src/ --stats             # print translation statistics
```

**Modes:**
- `write` (default) — write `.w` files
- `check` — report what would change, exit nonzero if any
- `diff` — print unified diff to stdout

**Options:**
- `-o <path>` — output path (file or directory)
- `-I <dir>` — add C include path (passed to libclang)
- `-D <name>=<value>` — define C preprocessor macro
- `--config <path>` — read `with.toml` for c_import settings
- `--no-cleanup` — skip the optional cleanup pass
- `--stats` — print per-file statistics (gotos, unsafe blocks, etc.)

---

## Architecture

```
C source file(s)
    ↓ libclang
Clang AST (cursors)
    ↓ Phase 1: Declaration scan
Name table, type table, forward decl ordering
    ↓ Phase 2: Translate declarations
Structs, enums, typedefs, globals, function signatures
    ↓ Phase 3: Translate function bodies
    ├─ Functions without goto → structured translation (existing)
    └─ Functions with goto → CFG → goto elimination → structured code
    ↓ Phase 4: Emit
.w source text with imports, types, functions
    ↓ Phase 5: Optional cleanup
Remove redundant casts, simplify trivial unsafe blocks
```

### What already exists (in CImport.w)

The following are **already implemented** and working:

- libclang integration (parse session, cursor traversal)
- Type translation (C types → With types, 18 cast kinds)
- Declaration translation (structs, enums, typedefs, globals,
  function signatures, calling conventions, variadic)
- Expression translation (all binary/unary operators,
  pointer arithmetic, array subscript, member access, casts,
  function calls, ternary, sizeof, compound literals,
  initializer lists, designated initializers, comma expressions,
  pre/post increment/decrement, statement expressions)
- Statement translation (compound blocks, return, if/else,
  while, for, do-while, break, continue, switch, local decls)
- Scope tracking with variable shadowing (name mangling)
- Bool coercion (type-aware: int→`!=0`, ptr→`!=null`, float→`!=0.0`)
- Reserved word escaping
- Name collision resolution (two-pass, strong/weak)
- Member function detection (CamelCase prefix → methods)
- Macro translation (integer, float, string, char constants;
  simple function-like macros)

### What needs to be built

| Component | Status | Effort |
|---|---|---|
| File-level driver | New | 1 day |
| Translate ALL function bodies (not just `static inline`) | Wire existing code | 0.5 day |
| Goto elimination via state-variable transform | New | 3–4 days |
| Switch fallthrough (correct semantics) | Fix existing | 1 day |
| Topological ordering of type definitions | New | 0.5 day |
| Module header emission (imports, c_import for linking) | New | 0.5 day |
| Multi-file coordination (shared types across files) | New | 1 day |
| Optional cleanup pass | New | 1–2 days |
| CLI + modes (write/check/diff/stats) | Port from Migrate.zig | 0.5 day |
| **Total** | | **~10 days** |

---

## Phase 3: Goto Elimination (the hard part)

### Strategy: State-variable transform

Every C function body is analyzed for goto usage. Functions
without goto use the existing structured translator unchanged.
Functions with goto use the state-variable transform.

### Algorithm

**Input:** libclang function cursor with CompoundStmt body.

**Step 1: Identify labels and gotos.**

Walk the function AST. Collect:
- Every label name and its cursor
- Every goto and its target label
- Whether any goto exists in the function

If no gotos: use existing `ci_trans_stmt` directly. Done.

**Step 2: Build basic blocks.**

Partition the function body into basic blocks. A new block starts:
- At the function entry
- At every label
- After every goto
- After every conditional branch
- After every return

Each block has:
- An ID (integer, used as state value)
- A list of statements
- A terminator (goto, conditional branch, return, or fallthrough
  to next block)

```
type BasicBlock = {
    id: i32,
    label: str,          // "" if unlabeled
    stmts: Vec[Cursor],  // statement cursors in this block
    terminator: Terminator,
}

type Terminator =
    | Goto(target_label: str)
    | CondGoto(cond: Cursor, true_label: str, false_label: str)
    | Return(value: Option[Cursor])
    | Fallthrough(next_id: i32)
    | Break
    | Continue
    | Switch(cond: Cursor, cases: Vec[(i64, str)])
```

**Step 3: Assign state IDs.**

Each basic block gets a sequential integer ID. The function entry
block is ID 0.

**Step 4: Emit state machine.**

```
fn translated_function(...):
    // local declarations hoisted here (all vars from all blocks)
    var __pc: i32 = 0
    while true:
        match __pc:
            0 ->
                // block 0 statements
                __pc = 3; continue  // goto label_x
            1 ->
                // block 1 statements
                if cond:
                    __pc = 2; continue
                __pc = 4; continue
            2 ->
                // block 2 statements
                return value
            // ...
            _ -> break
```

**Step 5: Variable hoisting.**

C allows declaring variables inside blocks that are jumped over
by goto. In With, all locals in a goto-containing function must
be hoisted to the function's top scope and zero-initialized.

Walk all DeclStmt nodes in the function, collect their names and
types, emit `var name: type = default` at the top before the
`while true` loop.

### Handling nested control flow inside goto functions

When a function uses goto, the state-variable transform replaces
the entire function body. This means if/else, while, for, etc.
inside the function are also converted to basic blocks.

This is intentional. The state machine correctly handles:
- Goto into a loop body
- Goto out of a loop body
- Goto into an if branch
- Goto between switch cases
- Mutual gotos (state machines)

For functions **without** goto, the existing structured translator
produces natural if/while/for/match code — no state machine needed.

### Optimization: structured subregions

Most C functions with goto use it only for error cleanup. The
function might be 200 lines with 3 gotos all jumping to a cleanup
block at the end. Converting the entire function to a state
machine is overkill.

**Optimization:** Identify the smallest subregion of the function
that contains all gotos and their targets. Only that subregion
gets the state-variable treatment. Surrounding structured code
translates normally.

This is a nice-to-have optimization. The correct baseline is:
if any goto exists, state-machine the whole function. Optimize
later.

---

## Switch Fallthrough

C switch statements have implicit fallthrough. The current
translator (`ci_trans_switch_body`) loses fallthrough semantics.

### Fix

Detect whether any case in the switch relies on fallthrough
(case body does not end with break/return/goto/continue).

**No fallthrough:** Emit `match` expression (current behavior, correct).

**With fallthrough:** Emit a state-machine within the switch:

```
// C:
switch (x) {
    case 1: a(); // fallthrough
    case 2: b(); break;
    case 3: c(); break;
}

// With:
var __sw: i32 = -1
if x == 1: __sw = 0
else if x == 2: __sw = 1
else if x == 3: __sw = 2

if __sw <= 0:
    a()
if __sw <= 1:
    b()
if __sw == 2:
    c()
```

For simple cascading fallthrough (the common case), cascading
`if __sw <= N` produces correct behavior. For complex fallthrough
patterns (case falls through to non-adjacent case), use the
full state-variable approach.

---

## Variable Hoisting for Goto Functions

C allows:
```c
goto skip;
int x = 10;
skip:
printf("%d", x);  // undefined in C, but compilers allow it
```

In the state-machine transform, all local variables must be
hoisted to the top of the function and zero-initialized:

```
fn f():
    var x: i32 = 0    // hoisted, zero-init
    var __pc: i32 = 0
    while true:
        match __pc:
            0 ->
                __pc = 1; continue   // goto skip
                x = 10               // unreachable but harmless
            1 ->   // skip
                print(f"{x}")
                return
            _ -> break
```

### Collecting declarations

Walk the entire function AST recursively. For every VarDecl:
1. Record name, type, and whether it has an initializer
2. In the state machine, split the declaration: `var name: type = default`
   at the top, and the initializer assignment `name = init_expr` at the
   original location

---

## Type Ordering

C allows forward references between types (via pointers). With
requires types to be defined before use (except through pointers).

### Algorithm

1. Collect all struct/union/enum/typedef declarations
2. Build a dependency graph: type A depends on type B if A has a
   field of type B (not pointer to B — pointers are always OK)
3. Topological sort
4. Emit declarations in dependency order
5. For cycles (mutual struct references via value, rare but legal
   in C via pointers): break the cycle by emitting an opaque
   forward declaration

---

## Multi-File Translation

A C project has multiple `.c` files that share headers.

### Strategy

1. Parse each `.c` file independently with libclang (libclang
   resolves includes automatically)
2. Each `.c` file becomes one `.w` file
3. Shared declarations (from headers) are emitted in a common
   module (`_types.w` or similar) and imported by each file
4. Deduplication: track which names have been emitted across files
   (the `with_cimport_is_name_emitted` / `mark_name_emitted`
   mechanism already exists)

### Linking

The migrated With code still needs to link against any C
libraries the original code used. Emit a `c_import` block at
the top of each file for the external dependencies:

```
// Auto-generated: external C dependencies
c_import("<stdlib.h>")
c_import("<string.h>")
```

Or, for a self-contained translation (no external C deps),
the migrated code is pure With and links normally.

---

## Macro Translation

### Object-like macros (constants)

Already handled: `#define FOO 42` → `let FOO: i32 = 42`.

### Simple function-like macros

Already handled: `#define MAX(a,b) ((a)>(b)?(a):(b))` →
generic function.

### Complex macros

For macros that can't be translated (variadic, token paste,
stringification, multi-statement):

**Strategy:** Expand the macro at every call site. libclang's
preprocessor does this — the AST already contains the expanded
code. The macro definition itself is dropped, and every use
site sees the expanded inline code.

This changes the source structure but preserves behavior
exactly. The original macro name can be emitted as a comment:

```
// was: PCRE2_SPTR16 (macro expanded inline)
let ptr: *const u16 = ...
```

---

## Unsafe Wrapping

All pointer dereferences, raw pointer indexing, and raw memory
access operations are wrapped in `unsafe`:

```c
// C
*ptr = 42;
ptr[i] = x;
ptr++;
```

```
// With
unsafe { *ptr = 42 }
unsafe { ptr[i] = x }
ptr = ptr + 1
```

The `unsafe` blocks are intentionally granular (one per
operation) to make later cleanup easy: a human can review
each `unsafe` and decide whether to replace it with safe
code (slice indexing, references, etc.).

---

## PCRE2-Specific Considerations

PCRE2 is the target use case. ~70K lines of C.

### What works out of the box

- Struct definitions (pcre2_real_code, pcre2_real_match_data, etc.)
- Function signatures (all 200+ API functions)
- Integer/string constants (#define PCRE2_*)
- The compile phase (pcre2_compile.c) — heavy switch/if logic,
  minimal goto
- Unicode tables (pcre2_tables.c) — large constant arrays
- Utility functions (pcre2_string_utils.c, etc.)

### What needs the state-variable transform

- **pcre2_match.c** (~3K lines) — the interpretive match engine.
  Uses goto for backtracking. The state-variable transform
  handles this mechanically. The result will be a large `while
  true: match __pc:` loop — ugly but correct and optimizable
  (LLVM turns dense match on i32 into a jump table).

- **pcre2_dfa_match.c** (~3.5K lines) — the DFA match engine.
  Also uses goto for state transitions. Same treatment.

### What to skip

- **pcre2_jit_compile.c** — the sljit JIT compiler. This
  generates machine code at runtime. It should be excluded from
  migration and linked as a C object, or dropped entirely (the
  interpreter is sufficient).

- **pcre2test.c** — the test harness. This stays as C and tests
  the migrated library through its C-compatible API.

### Memory allocator

PCRE2 uses `pcre2_compile_context` to pass custom allocators.
By default it calls `malloc`/`free`. The migrated code preserves
this — `malloc`/`free` are available via `c_import("<stdlib.h>")`.

Post-migration, the allocator can be swapped to With's allocator
by changing the context setup.

### API preservation

PCRE2's public API is all `pcre2_*` functions with C calling
convention. After migration, these functions exist as With
functions. To maintain C ABI compatibility (so existing C code
can call the migrated library), decorate them with
`@[c_export("pcre2_compile")]`.

This means: migrate PCRE2 source → build as With → existing C
callers (including pcre2test) link against it unchanged.

---

## Correctness Guarantee

### How we ensure the output is correct

1. **Semantic preservation by construction.** Every C construct
   maps to a With construct with identical runtime behavior.
   Pointer arithmetic stays as pointer arithmetic in safe code.
   Raw pointer access stays visibly wrapped in `unsafe`. Integer
   overflow stays as wrapping arithmetic (`+%`). Casts stay as
   explicit `as` casts.

2. **No behavior changes.** The translator does not "improve"
   the code. It does not replace `malloc` with safe allocation.
   It does not replace pointer arithmetic with slice indexing.
   It does not add bounds checks. The migrated code does exactly
   what the C code did, bit for bit.

3. **State-variable transform is provably correct.** The
   transform is a standard compiler technique (used by
   Emscripten, Cheerp, and every C-to-WASM compiler). It
   preserves the control flow graph exactly. The state variable
   encodes the program counter. The `while true: match __pc:`
   loop executes the same basic blocks in the same order as the
   original gotos.

4. **Test with the original test suite.** The migrated code
   exposes the same C ABI (via `@[c_export]`). The original
   test harness links against it and runs unchanged. If the
   tests pass, the migration is correct.

### What could go wrong

| Risk | Mitigation |
|---|---|
| libclang parse failure (invalid C) | Reject with error. Only valid C is translated. |
| Undefined behavior in C source | Preserved identically — UB in C stays UB in With. |
| Platform-specific types (sizeof long) | Use same platform types as the C compiler (already handled by c_type aliases). |
| Inline assembly | Emit as `comptime_error("inline asm")`. The JIT files are excluded anyway. |
| Computed goto (`goto *ptr`) | Emit as state-variable with indirect dispatch. Very rare outside interpreters. |
| `setjmp`/`longjmp` | Emit as `c_import` extern calls. They still work — they're just C library functions. |
| Volatile access | Emit as `unsafe` volatile read/write intrinsics. |
| Bit-fields | Existing handling: demote struct to opaque. Access via C helper functions. |

---

## Output Format

### Single file (`foo.c` → `foo.w`)

```
// Generated by: with migrate foo.c
// Source: foo.c (1234 lines, 5 gotos eliminated, 42 unsafe blocks)

c_import("<stdlib.h>")
c_import("<string.h>")

// ── Types ──────────────────────────────────────────────

type FooContext = {
    buffer: *mut u8,
    length: i32,
    flags: u32,
}

// ── Functions ──────────────────────────────────────────

@[c_export("foo_create")]
fn foo_create(size: i32) -> *mut FooContext:
    let ctx = unsafe { malloc(sizeof[FooContext]()) as *mut FooContext }
    if ctx == null:
        return null
    unsafe { (*ctx).buffer = malloc(size as u64) as *mut u8 }
    unsafe { (*ctx).length = size }
    unsafe { (*ctx).flags = 0 }
    ctx

@[c_export("foo_process")]
fn foo_process(ctx: *mut FooContext, data: *const u8, len: i32) -> i32:
    // [state-machine translation — original used goto for error cleanup]
    var result: i32 = 0
    var __pc: i32 = 0
    while true:
        match __pc:
            0 ->
                if ctx == null:
                    __pc = 2; continue   // goto error
                // ... normal processing ...
                result = 1
                __pc = 3; continue       // goto done
            2 ->   // error
                result = -1
                __pc = 3; continue
            3 ->   // done
                return result
            _ -> break
    result
```

### Statistics output (`--stats`)

```
with migrate pcre2/src/ --stats

pcre2_compile.c   → pcre2_compile.w   2847 lines  0 gotos  123 unsafe
pcre2_match.c     → pcre2_match.w     3012 lines  47 gotos  456 unsafe
pcre2_dfa_match.c → pcre2_dfa_match.w 3521 lines  31 gotos  389 unsafe
pcre2_tables.c    → pcre2_tables.w     892 lines  0 gotos    0 unsafe
...
total: 23 files, 31847 lines, 78 gotos eliminated, 2341 unsafe blocks
```

---

## Implementation Plan

### Step 1: File-level driver

Create `src/MigrateC.w`. Read a `.c` file, pass to libclang,
iterate all declarations, call existing translators.

**Key difference from CImport.w:** CImport skips non-inline
function bodies and emits `extern fn`. MigrateC translates
every function body.

Reuse: `ci_translate_struct`, `ci_translate_enum`,
`ci_translate_typedef`, `ci_translate_var`,
`ci_trans_expr`, `ci_trans_stmt`, `ci_trans_bool_expr`,
`ci_try_translate_fn_body`, scope tracking, name collision
resolution — all from CImport.w.

**Done when:** `with migrate hello.c` produces a compilable
`hello.w` for a trivial C program.

### Step 2: Goto detection and basic block construction

Add `ci_function_has_goto(session, cursor) -> bool` — walk AST,
return true if any GotoStmt (kind 232) is found.

Add `ci_build_basic_blocks(session, cursor) -> Vec[BasicBlock]`:
- Walk the CompoundStmt
- Split at labels and gotos
- Record terminators

**Done when:** Can identify which functions need the state-variable
transform and build their block graph.

### Step 3: State-variable transform

Add `ci_trans_goto_function(session, cursor, indent, scope) -> str`:
- Build basic blocks
- Hoist all variable declarations
- Emit `var __pc: i32 = 0`
- Emit `while true: match __pc:`
- For each block: translate statements, emit terminator

**Done when:** A function with gotos translates to a compilable
state machine. Test with a C function that has forward goto,
backward goto, cleanup goto, and mutual gotos.

### Step 4: Switch fallthrough fix

Replace `ci_trans_switch_body` for fallthrough cases. Use the
cascading `if __sw <= N` approach for simple fallthrough, full
state variable for complex fallthrough.

**Done when:** `switch` with fallthrough produces correct output.
Test with Duff's device.

### Step 5: Variable hoisting

For goto-containing functions, walk all VarDecl nodes, collect
to top of function, emit zero-initialized `var` declarations
before the state machine loop.

**Done when:** Functions with goto that declare variables in
inner blocks compile correctly.

### Step 6: Type ordering

Topological sort of struct/typedef definitions. Break cycles
with opaque forward declarations.

**Done when:** Structs with mutual pointer references emit in
correct order.

### Step 7: Multi-file and directory mode

Walk directory, process each `.c` file independently. Track
emitted names across files for deduplication. Emit shared
types in a common file.

**Done when:** `with migrate pcre2/src/ -o lib/std/regex/`
processes all files.

### Step 8: `@[c_export]` for API functions

Detect which functions are "public" (non-static, declared in a
header). Add `@[c_export("original_name")]` so the migrated
library maintains C ABI compatibility.

**Done when:** C test programs can link against the migrated With
library without changes.

### Step 9: CLI polish

Three modes (write/check/diff), `-o` flag, `-I`/`-D` flags,
`--stats`, `--config`.

**Done when:** CLI matches the usage section of this spec.

### Step 10: PCRE2 migration

The proof of the pudding.

1. Clone PCRE2 to `.reference/pcre2/`
2. `with migrate .reference/pcre2/src/ -o lib/std/pcre2/`
3. Build: `with build` (the migrated files must compile)
4. Link pcre2test against the migrated library
5. Run PCRE2's test suite
6. Fix any translation bugs found
7. Iterate until all tests pass

**Done when:** `pcre2test` passes against the With-compiled PCRE2.
