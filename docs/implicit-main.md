# With Language Spec: Implicit Main

**Status:** Draft
**Author:** Eric Hartford
**Date:** 2026-04-15

## Summary

When the build entry file contains top-level executable statements and does not define `fn main`, the compiler synthesizes an implicit `fn main` whose body consists of all top-level statements and bindings in source order. This reduces the minimal With program from three lines to one:

```
print("Hello, World!")
```

## Motivation

Every new user's first interaction with a language is the hello-world program. Removing the `fn main:` boilerplate from scripts and small programs makes With's first impression competitive with Python while preserving the explicit-main option for structured programs.

This feature also establishes the semantic foundation for With's REPL and notebook modes, which share the same "top-level code executes sequentially" model.

## Definitions

### Top-level items

Every top-level construct in a With source file is classified as exactly one of:

**Declaration** — defines a name at module scope:

| Kind | Example |
|------|---------|
| `fn` | `fn greet(name: str): ...` |
| `type` | `type Point { x: i32, y: i32 }` |
| `trait` | `trait Printable: ...` |
| `impl` | `impl Printable for Point: ...` |
| `use` | `use std.fs` |
| `const` | `const MAX = 1024` |
| `extern` | `extern fn malloc(size: i64) -> *mut i8` |
| `pub` (modifier) | `pub fn foo(): ...` |

**Statement** — produces a runtime effect or introduces a local binding:

| Kind | Example |
|------|---------|
| Expression statement | `print("hello")` |
| Assignment | `x = 42` |
| Control flow | `if`, `while`, `for`, `match` |
| Bare function call | `greet("World")` |
| `let` / `var` binding | `let name = "world"` |

Note: `let` and `var` at top level are **statements**, not declarations. They introduce bindings that are local to the implicit main when script mode is active. This ensures top-to-bottom execution order with no surprises.

### Script mode

A build entry file is in **script mode** when both conditions hold:

1. The file contains at least one top-level statement.
2. The file does not define `fn main`.

The compiler sets an internal flag during the top-level classification pass:

```
has_top_level_stmt = false

for each top-level node:
    if node is a statement (including let/var):
        has_top_level_stmt = true
```

Script mode is enabled when `has_top_level_stmt == true` and no `fn main` declaration exists.

## Transformation

When script mode is active, the compiler synthesizes an implicit main function as follows:

1. **Declarations remain at module scope.** Functions, types, traits, impls, imports, externs, and consts are hoisted and resolved as module-level items, identical to their behavior in a file with explicit `fn main`.

2. **All statements — including `let`/`var` — are collected in source order** into the body of a synthesized `fn main`. Bindings introduced by `let`/`var` become local variables inside main.

3. The synthesized main has the signature `fn main` (returns `void`, exit code 0). Programs that need a non-zero exit code must use an explicit `fn main -> i32`.

### Design principle: scripts execute top-to-bottom

The defining property of script mode is that **every statement executes in source order**. There is no distinction between "init time" and "main time." The user sees:

```
let db = connect()
print("connected")
query(db)
```

and the execution order is exactly: `connect()`, then `print`, then `query`. No statement runs before any statement that precedes it in the source.

This is the reason `let`/`var` must be wrapped into main rather than hoisted as module-level declarations. If `let db = connect()` were hoisted to module scope, it would execute before `print("connected")`, violating the top-to-bottom guarantee that makes scripts intuitive.

### Example transformation

Source:

```
use std.fs

const MAX_SIZE = 1024

fn process(data: str) -> str:
    return data.to_upper()

let args = get_args()
if args.len() < 2:
    print("usage: tool <file>")
else:
    let contents = fs.read(args[1])
    print(process(contents))
```

Synthesized equivalent:

```
use std.fs

const MAX_SIZE = 1024

fn process(data: str) -> str:
    return data.to_upper()

fn main:
    let args = get_args()
    if args.len() < 2:
        print("usage: tool <file>")
    else:
        let contents = fs.read(args[1])
        print(process(contents))
```

### Interleaved declarations and statements

When declarations and statements are interleaved in the source, declarations are hoisted and statements are collected in order:

```
let x = 42

fn double(n: i32) -> i32:
    return n * 2

print(double(x))
```

Synthesized equivalent:

```
fn double(n: i32) -> i32:
    return n * 2

fn main:
    let x = 42
    print(double(x))
```

The relative order of statements is preserved exactly. The relative order of declarations is also preserved, though declaration order is not significant in With (forward references are allowed).

### Forward references

Executable statements in the implicit main body may reference any declaration in the same file, regardless of source order. This is consistent with existing With semantics where module-level declarations are visible throughout the module.

```
greet("World")

fn greet(name: str):
    print(f"Hello, {name}!")
```

This works because `fn greet` is hoisted to module scope during the declaration pass, before the implicit main body executes.

## `const` vs `let` / `var`

In script mode:

| Keyword | Scope | Timing |
|---------|-------|--------|
| `const` | Module | Compile-time |
| `let` | Local to implicit main | Runtime, in source order |
| `var` | Local to implicit main | Runtime, in source order |

`const` remains at module scope because it is a compile-time constant — it has no runtime initialization and therefore no execution-ordering concerns. `let` and `var` become locals inside the synthesized main.

In non-script mode (explicit `fn main` or library file), `let` and `var` at top level remain module-level bindings as today. This is not a contradiction — files with explicit `fn main` have opted into module semantics, and library files are never in script mode.

## Scope restrictions

### Entry file only

Implicit main synthesis applies **only** to the build entry file — the file passed directly to `with build` or `with run`. Files imported via `use` are never eligible for implicit main, even if they contain top-level statements. Imported files with top-level statements are a compile error (existing behavior).

### Does not apply to `with check`

`with check` validates syntax and types but does not require a main function. Implicit main synthesis is not needed and does not run during `with check`.

### Does not apply to `with test`

Test files use `#[test]` attributes or a test harness, not `fn main`. Implicit main does not interact with the test runner.

## Error cases

### E1: Explicit main alongside top-level statements

```
fn main:
    print("explicit")

print("also top-level")
```

**Error:**

```
error: file has both `fn main` and top-level executable statements
  --> script.w:4:1
   |
1  | fn main:
   | -------- `fn main` defined here
   |
4  | print("also top-level")
   | ^^^^^^^^^^^^^^^^^^^^^^^ top-level statement here
   |
   = help: move the statement inside `fn main`, or remove
           `fn main` to use implicit main mode
```

### E2: Explicit main with return type alongside top-level statements

Same error as E1. The presence of any `fn main` (regardless of return type) conflicts with top-level statements.

### E3: Top-level statements in a non-entry file

```
// lib.w (imported by another file)
print("side effect on import")
```

**Error:**

```
error: top-level executable statements are not allowed in library files
  --> lib.w:1:1
   |
1  | print("side effect on import")
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = help: wrap this in a function, or make this file the build entry
```

## Implementation

The transformation is performed during parsing, after the top-level item classification pass and before semantic analysis.

### Algorithm

```
fn maybe_synthesize_implicit_main(entry_file: &mut Module):
    let has_main = entry_file.declarations.any(|d| d.is_fn_main())
    let stmts = entry_file.top_level_items.filter(|i| i.is_statement())
    // Note: let/var are classified as statements, not declarations

    if stmts.is_empty():
        return  // nothing to do — pure declaration file

    if has_main:
        emit_error(E1, main_decl.span, stmts[0].span)
        return

    // Synthesize: remove stmts from top-level, wrap in fn main
    let main_body = Block { stmts: stmts.collect_in_order() }
    let main_fn = FnDecl {
        name: "main",
        params: [],
        return_type: void,
        body: main_body,
        span: stmts[0].span,  // for error reporting
        is_implicit: true,     // for diagnostics
    }
    entry_file.declarations.push(main_fn)
```

The `is_implicit` flag on the synthesized `fn main` is used only for diagnostics. It has no semantic effect — the implicit main behaves identically to an explicit one in all subsequent compiler phases.

### Ordering guarantee

The synthesized main body preserves the source order of statements exactly. Declarations are hoisted but their relative order is also preserved. The interleaving of declarations and statements in the source is separated into two ordered sequences:

```
// Source order:      D1  S1  D2  S2  D3  S3
// Declaration order: D1  D2  D3
// Statement order:   S1  S2  S3
// Result:            D1  D2  D3  fn main: S1; S2; S3
```

## REPL and notebook mode

With's REPL and notebook modes share the same semantic model as implicit main: top-level code executes sequentially, declarations are hoisted, `let`/`var` introduce local bindings.

Each REPL input or notebook cell behaves as if its contents were appended to the implicit main body. Declarations entered in earlier cells are visible in later ones (hoisted to a shared module scope). Bindings introduced by `let`/`var` persist across cells within a session.

```
// Cell 1
let x = 42

// Cell 2
print(x)         // works — x is still in scope

// Cell 3
fn double(n: i32) -> i32:
    return n * 2

// Cell 4
print(double(x)) // works — double is hoisted, x persists
```

The precise semantics of REPL and notebook modes are defined in their own specs. The relevant guarantee here is that implicit main establishes the execution model that REPL and notebook build on: **top-level code is sequential, declarations are hoisted, bindings are local.**

## Future considerations

### `global` keyword

If users need module-level runtime state in script-mode files (for example, a database connection shared across hoisted functions), a `global` keyword could serve as an explicit escape hatch:

```
global db = connect()

fn query(sql: str):
    db.execute(sql)

query("SELECT 1")
```

Here `global db` would be initialized at module scope before implicit main runs, while `query("SELECT 1")` executes inside main.

This is deferred until there is demonstrated need. The current design covers the intended use cases (one-liner scripts, quick utilities, REPL cells). Programs complex enough to need module-level state should use explicit `fn main`.

### Implicit main with return type

A future extension could allow:

```
return 1
```

as a top-level statement, causing the synthesized main to have return type `i32`. This is not part of the initial implementation. For now, programs that need a non-zero exit code must write explicit `fn main -> i32`.

### `--no-implicit-main` flag

A compiler flag to disable implicit main synthesis may be useful for tooling or style enforcement. Not required for the initial implementation.