# `with -e` / `-n` / `-p` — CLI One-Liners

Run small With programs directly from the command line.

This spec covers the first one-liner milestone only:

- `with -e CODE`
- `with -n CODE`
- `with -p CODE`
- regex one-liners using `/.../`, `=~`, `!~`, and `$0` / `$1` / `$name`

---

## 1. Goals

### 1.1 Fast shell ergonomics

Common one-liners should not require a source file:

```bash
with -e 'print("hello")'
seq 5 | with -n 'print(f"line {nr}: {line}")'
cat log.txt | with -n 'if line =~ /error (\d+)/: print($1)'
cat names.txt | with -p 'line = line.upper()'
```

### 1.2 Full With semantics

One-liners are compiled With programs.

There is no interpreter, bytecode VM, or separate execution model. The CLI constructs a synthetic With entry source file, compiles it through the normal build/run path, runs the resulting binary, and returns that binary's exit code.

### 1.3 Reuse implicit main

The generated source uses top-level executable statements and relies on the existing implicit-main feature to synthesize `fn main`. The CLI does not generate an explicit `fn main` wrapper.

This keeps one-liners equivalent to short script entry files and avoids a second entry-point mechanism.

### 1.4 Minimal language magic

The CLI wrapper provides:

- implicit imports
- implicit-main entry-source generation
- stdin line loop generation for `-n` / `-p`
- built-in variables: `line`, `nr`, `args`

It does not introduce a separate mini-language.

---

## 2. Non-Goals

This milestone does not include:

- data-document processing modes beyond normal With code
- dynamic `.field` access on untyped data values
- `s///` substitution syntax
- shell command execution
- REPL behavior
- interpretation without compilation

---

## 3. Prerequisites

This feature depends on the following existing or planned library/language surface.

### 3.1 Required for `-e`, `-n`, and `-p`

- `std.io`
  - `stdin.lines()`
  - `print`
  - `print`
- `std.str`
  - basic string methods
  - string interpolation support, if examples use `f"..."`
- `std.math`
  - basic math functions, if included in implicit imports
- CLI/runtime support for argv after `--`

### 3.2 Required for regex one-liners

- `std.regex`
  - high-level user-facing regex facade
  - `Regex`
  - `Regex.is_match`
  - `Regex.captures`
  - `Regex.replace_all`
  - `Regex.split`
- regex literals: `/.../flags`
- regex match operators: `=~`, `!~`
- scoped capture bindings from direct positive regex conditions:
  - `$0`
  - `$1`, `$2`, ...
  - `$name`

---

## 4. Modes

Exactly one of `-e`, `-n`, or `-p` may be used in a single invocation.

### 4.1 Generated entry files

All modes generate a synthetic build/run entry file. The generated file contains imports, `args`, and top-level executable statements. Existing implicit-main support turns those top-level statements into the program entry point.

The CLI must not generate an explicit `fn main` unless this spec is revised, because explicit `fn main` changes how top-level `let` / `var` are classified and can conflict with top-level executable statements.

---

## 5. `-e CODE`

Compile and run `CODE` as top-level executable statements in a synthetic entry file. The normal implicit-main feature synthesizes `fn main`.

```bash
with -e 'print("hello")'
```

Desugars to:

```with
use std.io
use std.str
use std.regex
use std.math

let args = __cli_args_after_double_dash()
print("hello")
```

The exact argv helper name is implementation-defined. The user-visible binding is `args`.

### 5.1 Multiple `-e` flags

Multiple `-e` flags concatenate as separate top-level executable lines after the implicit imports and `args` binding.

```bash
with -e 'var total = 0' -e 'total = total + 1' -e 'print(total)'
```

Desugars to:

```with
use std.io
use std.str
use std.regex
use std.math

let args = __cli_args_after_double_dash()
var total = 0
total = total + 1
print(total)
```

---

## 6. `-n CODE`

Line-processing mode.

The CLI emits a top-level loop over stdin. Each input line is bound to `line`. The line number is bound to `nr`, starting at 1. The normal implicit-main feature turns this top-level loop into the program entry point.

```bash
cat access.log | with -n 'if line =~ /404/: print(f"{nr}: {line}")'
```

Desugars to:

```with
use std.io
use std.str
use std.regex
use std.math

let args = __cli_args_after_double_dash()
var nr: i64 = 0
for line in stdin.lines():
    nr = nr + 1
    if line =~ /404/: print(f"{nr}: {line}")
```

### 6.1 Line endings

`stdin.lines()` yields lines with the trailing newline removed.

If the input uses Windows line endings, the trailing `\r` should also be removed before assigning `line`.

### 6.2 Multiple `-n` flags

Multiple `-n` flags concatenate as separate loop-body lines inside the generated top-level stdin loop.

```bash
cat data.csv | with -n 'let f = line.split(",")' -n 'print(f[0])'
```

Desugars to:

```with
let args = __cli_args_after_double_dash()
var nr: i64 = 0
for line in stdin.lines():
    nr = nr + 1
    let f = line.split(",")
    print(f[0])
```

---

## 7. `-p CODE`

Auto-print mode.

`-p` is like `-n`, but prints `line` after `CODE` executes.

If `CODE` assigns to `line`, the modified value is printed.

```bash
cat names.txt | with -p 'line = line.upper()'
```

Desugars to:

```with
use std.io
use std.str
use std.regex
use std.math

let args = __cli_args_after_double_dash()
var nr: i64 = 0
for __line in stdin.lines():
    nr = nr + 1
    var line = __line
    line = line.upper()
    print(line)
```

The internal `__line` binding avoids shadowing ambiguity. The user-visible binding is mutable `line`.

### 7.1 Filtering

`-p` always prints `line` after `CODE`.

For filtering, use `-n`:

```bash
cat access.log | with -n 'if line =~ /500/: print(line)'
```

### 7.2 Multiple `-p` flags

Multiple `-p` flags concatenate as separate loop-body lines before the final generated `print(line)`.

```bash
cat names.txt | with -p 'line = line.trim()' -p 'line = line.upper()'
```

Desugars to:

```with
let args = __cli_args_after_double_dash()
var nr: i64 = 0
for __line in stdin.lines():
    nr = nr + 1
    var line = __line
    line = line.trim()
    line = line.upper()
    print(line)
```

---

## 8. Built-In Variables

### 8.1 In all modes

| Variable | Type | Description |
|---|---:|---|
| `args` | `Vec[str]` | Command-line arguments after `--` |

Example:

```bash
with -e 'for a in args: print(a)' -- foo bar baz
```

### 8.2 In `-n` and `-p`

| Variable | Type | Description |
|---|---:|---|
| `line` | `str` | Current input line with newline stripped |
| `nr` | `i64` | Current line number, 1-indexed |

Example:

```bash
cat file.txt | with -n 'print(f"{nr}: {line}")'
```

### 8.3 Reserved internal names

The generated source may use internal names beginning with `__cli_` or `__line`.

User code should not rely on or shadow these names. If needed, the compiler may reject user declarations beginning with reserved CLI-generated prefixes inside one-liner generated code.

---

## 9. Implicit Imports

All one-liner modes implicitly import:

| Import | Provides |
|---|---|
| `std.io` | `stdin`, `stdout`, `stderr`, `print`, `print` |
| `std.str` | String utilities and string methods |
| `std.regex` | Regex type, regex literals, `=~`, `!~`, regex helpers |
| `std.math` | Common math functions and constants |

These imports are equivalent to writing them at the top of a normal With source file.

The compiler should not give these modules special runtime behavior. The imports are syntactic sugar in the generated source.

---

## 10. Semicolons in CLI Code

Shell one-liners often need multiple statements. Within `-e`, `-n`, and `-p` code strings, semicolons act as line separators.

```bash
with -e 'var x = 0; x = x + 1; print(x)'
```

is equivalent to the generated entry-file body:

```with
var x = 0
x = x + 1
print(x)
```

### 10.1 No block inference

Semicolons do **not** infer nested indentation.

This:

```bash
with -e 'if true: print("yes"); print("also yes")'
```

desugars as top-level entry code:

```with
if true: print("yes")
print("also yes")
```

The second `print` is not inside the `if`.

### 10.2 Multi-statement nested bodies

Use braces for multi-statement nested bodies:

```bash
with -e 'if true { print("yes"); print("also yes") }'
```

desugars as a single top-level statement containing a braced block:

```with
if true {
    print("yes")
    print("also yes")
}
```

The CLI semicolon pass is intentionally simple. It must not implement a parser for With block structure.

---

## 11. Regex One-Liners

Regex one-liners use the normal With regex syntax:

- regex literals: `/.../flags`
- positive match: `=~`
- negative match: `!~`
- scoped captures: `$0`, `$1`, `$2`, `$name`

### 11.1 Grep-style filtering

```bash
cat log.txt | with -n 'if line =~ /error/: print(line)'
```

### 11.2 Capture extraction

```bash
cat log.txt | with -n 'if line =~ /error (\d+)/: print($1)'
```

### 11.3 Named captures

```bash
cat users.txt | with -n 'if line =~ /name: (?<name>.+)/: print($name)'
```

### 11.4 Negative match

`!~` is valid for boolean matching but never creates capture bindings.

```bash
cat log.txt | with -n 'if line !~ /debug/: print(line)'
```

This is invalid:

```bash
cat log.txt | with -n 'if line !~ /error (\d+)/: print($1)'
```

### 11.5 Compound boolean expressions

Compound boolean expressions do not create magic capture bindings.

Valid boolean code:

```bash
cat log.txt | with -n 'if line.len() > 0 and line =~ /error (\d+)/: print(line)'
```

Invalid capture usage:

```bash
cat log.txt | with -n 'if line.len() > 0 and line =~ /error (\d+)/: print($1)'
```

To use captures with additional conditions, nest the logic:

```bash
cat log.txt | with -n 'if line =~ /error (\d+)/ { if line.len() > 0: print($1) }'
```

### 11.6 Regex literals as values

Regex literals are ordinary `Regex` values.

```bash
with -e 'let r = /hello/i; print(r.is_match("HELLO"))'
```

### 11.7 Replacement

This spec does not add Perl `s///` substitution syntax.

Regex replacement uses the `Regex` API:

```bash
cat data.txt | with -p 'line = /old/.replace_all(line, "new")'
```

or, if the stdlib exposes a free function:

```bash
cat data.txt | with -p 'line = Regex.replace_all(/old/, line, "new")'
```

The exact API spelling should follow `std.regex`.

A future `std.str` convenience method may make the common one-liner form more natural:

```bash
cat data.txt | with -p 'line = line.replace(/old/, "new")'
```

That would be an API-layer convenience over regex replacement. It does not require CLI-specific syntax and does not imply adding `s///`.

### 11.8 Splitting

Regex splitting uses the `Regex` API:

```bash
cat data.tsv | with -n 'let f = /\t/.split(line); print(f[2])'
```

If `str.split` supports plain string separators, that remains separate:

```bash
cat data.csv | with -n 'let f = line.split(","); print(f[0])'
```

---

## 12. Flag Interactions

| Flags | Behavior |
|---|---|
| `-e` + `-n` | Error: mutually exclusive |
| `-e` + `-p` | Error: mutually exclusive |
| `-n` + `-p` | Error: mutually exclusive |
| `-e` + source file | Error: cannot combine one-liner code with a source file |
| `-n` + source file | Error: cannot combine one-liner code with a source file |
| `-p` + source file | Error: cannot combine one-liner code with a source file |
| `-e` repeated | Concatenate as top-level body lines |
| `-n` repeated | Concatenate as loop-body lines |
| `-p` repeated | Concatenate as loop-body lines before implicit print |
| `--` | Remaining args are exposed as `args` |
| `-O0`, `-O1`, `-O2` | Applies to generated program compilation |

---

## 13. Compilation Strategy

The CLI implementation constructs a synthetic entry-file source string, compiles it through the normal build/run path with implicit-main behavior enabled, runs the compiled binary, and cleans up temporary files.

Pseudocode:

```with
fn handle_cli_code(code_parts: Vec[str], mode: CliCodeMode):
    let source = build_synthetic_entry_source(code_parts, mode)
    let tmp_src = tmp_path(".w")
    let tmp_bin = tmp_path("")
    write_file(tmp_src, source)
    compile(tmp_src, tmp_bin, opt_level)
    let code = exec(tmp_bin, args)
    remove(tmp_src)
    remove(tmp_bin)
    exit(code)
```

### 13.1 Optimization level

Default to `-O0` for compile latency.

Users may override with normal optimization flags:

```bash
cat huge.csv | with -O2 -n 'let f = line.split(","); print(f[3])'
```

The spec does not promise a specific startup latency number.

### 13.2 Exit code

The process exit code is the exit code of the compiled program.

If compilation fails, exit code is `1` and diagnostics are written to stderr.

### 13.3 Temporary files

Temporary source and binary files should be removed after execution when possible.

If compilation or execution crashes, best-effort cleanup is acceptable.

---

## 14. Diagnostics and Source Mapping

Compiler errors should point at the user's CLI code, not at the generated source boilerplate.

For example:

```bash
with -e 'let x = '
```

should report an error against something like:

```text
<cli -e #1>:1:9
```

not against the generated temp file's wrapper line.

### 14.1 Multiple code arguments

For multiple `-e`, `-n`, or `-p` arguments, diagnostics should identify which argument failed:

```text
<cli -e #2>:1:5
<cli -n #1>:1:12
<cli -p #3>:1:1
```

Implementation may use line directives, source-map entries, fixed generated-source-offset correction, or a compiler diagnostic remapping table.

The implementation mechanism is not user-visible. The user-facing requirement is that diagnostics identify the CLI argument and location inside that argument rather than exposing generated source boilerplate or temporary-file offsets.

---

## 15. Examples

### 15.1 Hello world

```bash
with -e 'print("hello")'
```

### 15.2 Quick math

```bash
with -e 'print(sin(PI / 4))'
```

### 15.3 Loop

```bash
with -e 'for i in 1..=5: print(i)'
```

### 15.4 Multiple statements

```bash
with -e 'var total = 0; for i in 1..=10 { total = total + i }; print(total)'
```

### 15.5 Number stdin lines

```bash
cat file.txt | with -n 'print(f"{nr}: {line}")'
```

### 15.6 Grep equivalent

```bash
cat server.log | with -n 'if line =~ /FATAL/: print(line)'
```

### 15.7 Grep with capture

```bash
cat server.log | with -n 'if line =~ /status=(\d+)/: print($1)'
```

### 15.8 Named capture

```bash
cat users.txt | with -n 'if line =~ /email=(?<email>\S+)/: print($email)'
```

### 15.9 Transform each line

```bash
cat names.txt | with -p 'line = line.upper()'
```

### 15.10 Regex replace

```bash
cat config.txt | with -p 'line = /localhost/.replace_all(line, "0.0.0.0")'
```

### 15.11 Process CSV

```bash
cat sales.csv | with -n 'let f = line.split(","); print(f"{f[0]}\t{f[3]}")'
```

### 15.12 Process TSV with regex split

```bash
cat data.tsv | with -n 'let f = /\t/.split(line); print(f[2])'
```

### 15.13 Use command-line args

```bash
with -e 'for a in args: print(a)' -- foo bar baz
```

---

## 16. What This Is Not

### Not a REPL

There is no interactive session. Each invocation compiles and runs one complete program.

### Not an interpreter

The generated source is compiled using the normal With compiler pipeline.

### Not a shell

`with -e` is for quick With programs, not for process orchestration or shell replacement.

---

## 17. Design Decisions

| Decision | Rationale |
|---|---|
| `-e` emits top-level statements | Reuses implicit main instead of generating a special wrapper function |
| `-n` loops over stdin lines | Proven Perl/AWK-style filtering workflow |
| `-p` auto-prints modified line | Proven Perl-style transformation workflow |
| `line` instead of `$_` | With avoids sigil variables for ordinary values |
| `nr` instead of `$.` | Readable and obvious |
| `args` after `--` | Conventional CLI argument separation |
| Regex uses `=~` and `$1` | Matches the planned With regex language feature |
| No implicit `m` binding | Avoids a second capture model |
| No capture magic in compound booleans | Keeps capture scope predictable |
| No `s///` in v1 | Avoids adding another regex-specific mini-syntax |
| Semicolons become newlines only | Keeps CLI preprocessing simple |
| Braces for multi-statement blocks | Uses existing With block syntax |
| Reuse implicit main | Avoids a CLI-only `fn main` wrapper and keeps one-liners equivalent to script entry files |
| Full compilation | Maintains one execution model |
| `-O0` default | Optimizes for compile latency |

---

## 18. Follow-Up Specs

Future documents may cover:

### 18.1 CLI caching

Possible filename:

```text
with-cli-cache.md
```

Scope:

- caching generated one-liner binaries
- cache keys
- invalidation
- stdlib/compiler versioning
- temp file lifecycle

### 18.2 Shell integration

Possible filename:

```text
with-shell-integration.md
```

Scope:

- editor integration
- completions
- richer diagnostics
- command wrappers
- install-time shell helpers
