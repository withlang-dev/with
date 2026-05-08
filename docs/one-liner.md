# `with -e` — CLI One-Liners

**Run With code directly from the command line.**

```
with -e 'println("hello")'
echo '{"users":[{"name":"Alice","age":31}]}' | with -e 'let d = json.parse(stdin.read()); println(from d | .users | where .age > 30 | .name)'
cat log.txt | with -n 'if line.match(/error/): println(line)'
cat data.json | with -j 'from . | .users | where .active | .email'
```

---

## Flags

### `-e CODE`

Compile and run CODE as the body of `fn main:`.

```
with -e 'let x = 42; println(f"x={x}")'
```

Becomes:

```
use std.str
use std.io
use std.re
use std.math
use std.json
use std.yaml
use std.toml

fn main:
    let x = 42; println(f"x={x}")
```

Multiple `-e` flags concatenate as separate lines:

```
with -e 'var total = 0' -e 'total = total + 1' -e 'println(total)'
```

### `-n CODE`

Line-processing mode. Wraps CODE in a loop over stdin. Each
line is bound to `line` with the trailing newline stripped.

```
cat access.log | with -n 'if line.match(/404/): println(line)'
```

Becomes:

```
use std.str
use std.io
use std.re
use std.math
use std.json
use std.yaml
use std.toml

fn main:
    for line in stdin.lines():
        if line.match(/404/): println(line)
```

### `-p CODE`

Auto-print mode. Like `-n`, but prints `line` after CODE
executes. If CODE assigns to `line`, the modified value
is printed.

```
cat names.txt | with -p 'line = line.upper()'
```

Becomes:

```
use std.str
use std.io
use std.re
use std.math
use std.json
use std.yaml
use std.toml

fn main:
    for line in stdin.lines():
        var line = line
        line = line.upper()
        println(line)
```

The `var line = line` rebinding makes `line` mutable so the
user can modify it. The `println(line)` at the end prints
whatever `line` is after the user's code runs.

### `-j QUERY`

JSON query mode. Reads all of stdin as JSON, binds it to `.`,
and runs a `from` expression on it. Prints the result as JSON.

```
curl api.example.com/users | with -j 'from . | .users | where .age > 30 | .name'
```

Becomes:

```
use std.str
use std.io
use std.re
use std.math
use std.json
use std.yaml
use std.toml

fn main:
    let _input = json.parse(stdin.read())
    let _result = from _input | .users | where .age > 30 | .name
    println(json.to_string_pretty(_result))
```

This is the jq replacement. The query after `-j` is a `from`
pipeline expression where `.` refers to the parsed stdin.

#### `-j` with JSONL (newline-delimited JSON)

When stdin is JSONL (one JSON object per line), use `-jn` to
process each line independently:

```
cat events.jsonl | with -jn 'from . | where .level == "error" | .message'
```

Becomes:

```
fn main:
    for _line in stdin.lines():
        let _input = json.parse(_line)
        let _result = from _input | where .level == "error" | .message
        if not _result.is_null():
            println(json.to_string(_result))
```

#### `-j` with YAML input

```
cat config.yaml | with -jy 'from . | .database.host'
```

Parses stdin as YAML instead of JSON. Result prints as JSON.

#### `-j` with TOML input

```
cat config.toml | with -jt 'from . | .database.host'
```

Parses stdin as TOML instead of JSON. Result prints as JSON.

---

## Implicit Imports

All modes (`-e`, `-n`, `-p`, `-j`) implicitly import:

| Import | Provides |
|---|---|
| `std.str` | String methods |
| `std.io` | `stdin`, `stdout`, `stderr`, `println`, `print` |
| `std.re` | Regex literals, `match`, `replace`, `split` |
| `std.math` | Basic math functions |
| `std.json` | `json.parse`, `json.to_string`, `Json` type |
| `std.yaml` | `yaml.parse` |
| `std.toml` | `toml.parse` |

These are the same modules you'd use in a script. No special
runtime, no hidden magic — the implicit imports are syntactic
sugar only.

---

## Semicolons as Line Separators

Within `-e` / `-n` / `-p` strings, semicolons act as line
breaks. This lets you write multi-statement one-liners:

```
with -e 'var x = 0; x = x + 1; println(x)'
```

Is equivalent to:

```
fn main:
    var x = 0
    x = x + 1
    println(x)
```

Indentation after `:` is inferred — a semicolon after
`if cond:` or `for x in y:` starts an indented body:

```
with -e 'for i in 0..5: println(i)'
with -e 'if true: println("yes"); println("also yes")'
```

---

## Built-in Variables

### In `-n` and `-p` modes

| Variable | Type | Description |
|---|---|---|
| `line` | `str` | Current line (newline stripped) |
| `nr` | `i64` | Line number (1-indexed) |

```
cat file.txt | with -n 'println(f"{nr}: {line}")'
```

### In all modes

| Variable | Type | Description |
|---|---|---|
| `args` | `Vec[str]` | Command-line arguments after `--` |

```
with -e 'for a in args: println(a)' -- foo bar baz
```

---

## `from` in One-Liners

The `from` query expression is the primary reason `-j` mode
exists. It replaces jq for JSON processing and works with
YAML and TOML too.

### Replacing jq

```bash
# jq
cat data.json | jq '.users[] | select(.age > 30) | .name'

# with
cat data.json | with -j 'from . | .users | where .age > 30 | .name'
```

```bash
# jq — construct new objects
cat data.json | jq '.users[] | {name: .name, email: .email}'

# with
cat data.json | with -j 'from . | .users | { name: .name, email: .email }'
```

```bash
# jq — nested access
cat data.json | jq '.config.database.host'

# with
cat data.json | with -j 'from . | .config.database.host'
```

```bash
# jq — sort and limit
cat data.json | jq '[.users[] | select(.active)] | sort_by(.age) | .[:5]'

# with
cat data.json | with -j 'from . | .users | where .active | sort_by(.age) | limit(5)'
```

### With variables in queries

In `-e` mode, you can capture With variables in `from`
expressions:

```
with -e 'let min = 30; let d = json.parse(stdin.read()); let r = from d | .users | where .age > min | .name; println(r)'
```

### Chaining data formats

```bash
# Read YAML, query it, output JSON
cat config.yaml | with -jy 'from . | .services | where .enabled | .name'

# Read TOML, query it
cat Cargo.toml | with -jt 'from . | .dependencies | keys'
```

### Aggregations

```bash
# Count items
cat data.json | with -j 'from . | .users | where .active | length'

# Sum values
cat sales.json | with -j 'from . | .transactions | .amount | sum'

# Statistics
cat data.json | with -j 'from . | .scores | { mean: mean, max: max, min: min }'
```

### JSONL processing

```bash
# Filter log lines
cat app.log.jsonl | with -jn 'from . | where .level == "error"'

# Extract fields from each line
cat events.jsonl | with -jn 'from . | { ts: .timestamp, msg: .message }'

# Count errors (accumulate across lines — use -e instead)
cat app.log.jsonl | with -e 'var n = 0; for r in json.stream_lines(stdin): if (from r | .level).string_or("") == "error": n = n + 1; println(n)'
```

---

## Regex Integration

Regex literals and match results work naturally in one-liners:

```
# grep equivalent
cat log.txt | with -n 'if line.match(/error (\d+)/): println(m[1])'

# sed equivalent
cat data.txt | with -p 'line = line.replace(/old/, "new")'

# awk-like field splitting
cat data.tsv | with -n 'let f = line.split(/\t/); println(f[2])'
```

When `line.match(regex)` is used as a condition, the match
result is implicitly bound to `m` in the body:

```
with -n 'if line.match(/name: (.+)/): println(m[1])'
```

This is the same implicit-match-binding that With uses in
regular code — not a one-liner-specific feature.

---

## Implementation

### Compilation

`-e` / `-n` / `-p` / `-j` construct a synthetic source string,
write it to a temp file, compile with `with build`, run the
binary, then delete both temp files. No interpreter, no REPL —
full compiled code every time.

```
// Pseudocode for the implementation:
fn handle_cli_code(code: str, mode: Mode):
    let source = build_source(code, mode)
    let tmp_src = tmp_path(".w")
    let tmp_bin = tmp_path("")
    write_file(tmp_src, source)
    compile(tmp_src, tmp_bin, opt_level: 0)
    exec(tmp_bin, args)
    remove(tmp_src)
    remove(tmp_bin)
```

### Optimization level

Default to `-O0` for minimum compile latency. The user can
override with `-O1` or `-O2` if they want optimized code
(e.g. for a CPU-bound one-liner processing a large file).

```
cat huge.csv | with -O2 -n 'let f = line.split(/,/); ...'
```

### Exit code

The process exit code is the exit code of the compiled program.
If compilation fails, exit code is 1 and errors go to stderr.

### Error messages

Compiler errors reference line numbers in the user's code, not
the synthetic wrapper. Line 1 is the first `-e` argument.

---

## Interaction with Other Flags

| Flags | Behavior |
|---|---|
| `-e` + `-n` | Error: mutually exclusive |
| `-e` + `-p` | Error: mutually exclusive |
| `-e` + `-j` | Error: mutually exclusive |
| `-n` + `-p` | Error: mutually exclusive |
| `-j` + `-jn` | `-jn` is a combined flag (JSON + line mode) |
| `-j` + `-jy` | `-jy` is a combined flag (YAML input) |
| `-j` + `-jt` | `-jt` is a combined flag (TOML input) |
| `-e` + `-O2` | Compile one-liner at -O2 |
| `-e` + file.w | Error: can't combine -e with a source file |

---

## Examples

### jq replacement — the common case

```bash
# Pretty-print JSON
cat data.json | with -j 'from .'

# Extract nested field
cat config.json | with -j 'from . | .database.host'

# Filter array
cat users.json | with -j 'from . | .users | where .active and .age >= 18'

# Reshape objects
cat api.json | with -j 'from . | .results | { id: .id, title: .title }'

# Sort and take top N
cat scores.json | with -j 'from . | .scores | sort_by(.value) | reverse | limit(3)'

# Aggregate
cat sales.json | with -j 'from . | .orders | .total | sum'
```

### Grep for pattern, print line numbers

```
cat server.log | with -n 'if line.match(/FATAL/): println(f"{nr}: {line}")'
```

### Sum numbers from stdin

```
seq 100 | with -e 'var sum = 0; for line in stdin.lines(): sum = sum + parse_int(line); println(sum)'
```

### In-place-style text replacement

```
cat config.txt | with -p 'line = line.replace(/localhost/, "0.0.0.0")'
```

### Quick math

```
with -e 'println(sin(PI / 4))'
with -e 'for i in 1..=20: println(f"{i}: {fib(i)}")'
```

### Process CSV, print specific columns

```
cat sales.csv | with -n 'let f = line.split(/,/); println(f"{f[0]}\t{f[3]}")'
```

### YAML config extraction

```
cat docker-compose.yaml | with -jy 'from . | .services | keys'
```

### JSONL log analysis

```bash
# Show all errors
cat app.log.jsonl | with -jn 'from . | where .level == "error"'

# Extract timestamps of slow requests
cat access.log.jsonl | with -jn 'from . | where .duration_ms > 1000 | .timestamp'
```

### Combine regex and JSON

```
# Parse semi-structured log, extract JSON payload, query it
cat app.log | with -n 'if line.match(/payload=({.+})/): let d = json.parse(m[1]); println(from d | .user.email)'
```

---

## What This Is NOT

**Not a REPL.** There is no interactive mode. Every invocation
compiles and runs a complete program.

**Not an interpreter.** The code is compiled to native machine
code via LLVM, then executed. There is no bytecode, no VM.

**Not a shell.** `with -e` doesn't replace bash. It's for
data processing and quick computations, not for running
system commands or managing processes.

**Not just jq.** `-j` mode uses `from` query expressions
which are a general-purpose data query language backed by
the migrated jq engine. But `-e` / `-n` / `-p` give you the
full With language for everything else.
