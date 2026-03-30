# Print Semantics — Specification & Implementation Notes

*Replacing `print`/`println` with a single newline-terminated `print`.*

---

## 1. Specification

### 1.1 `print`

`print` outputs a string to stdout followed by a newline.

```
print("hello")          // outputs: hello\n
print(f"count: {n}")    // outputs: count: 42\n
print("")               // outputs: \n (blank line)
```

`print` takes a single `str` argument. Formatting is done via f-strings, not via print itself. There are no format arguments, no varargs, no separator or end parameters.

```
// Format before printing
let name = "alice"
let score = 42
print(f"{name}: {score}")    // alice: 42\n

// Multiple values: use f-strings
print(f"{x} {y} {z}")       // not print(x, y, z)
```

### 1.2 `eprint`

`eprint` outputs a string to stderr followed by a newline. Same semantics as `print` but targets stderr.

```
eprint("warning: file not found")    // stderr: warning: file not found\n
eprint(f"error at line {line}")      // stderr: error at line 42\n
```

### 1.3 Removed: `println`, `eprintln`

`println` and `eprintln` no longer exist. `print` and `eprint` always append a newline. There is no function that prints without a newline.

```
// Old (removed):
println("hello")      // error: undefined variable 'println'
eprintln("error")     // error: undefined variable 'eprintln'

// New:
print("hello")        // hello\n
eprint("error")       // error\n
```

### 1.4 `write` and `ewrite`

`write` outputs a string to stdout with NO newline. `ewrite` does the same to stderr. These are the explicit opt-in for raw output.

```
write("loading...")           // stdout, no newline
write(f"\r{percent}%")        // carriage return, no newline
write("Enter name: ")         // prompt without trailing newline
ewrite("progress: ")          // stderr, no newline
```

Use cases: progress bars, prompts, terminal control, building output character by character.

### 1.5 Design Rationale

**Why always newline:**
- The overwhelmingly common case is line-terminated output
- Python's `print()` adds a newline by default — this is proven good design
- Forgetting a newline produces garbled terminal output; forgetting to suppress one is harmless
- The `ln` suffix is visual noise that appears on nearly every print call

**Why not `sep`/`end` parameters like Python:**
- With has f-strings for all formatting — `print(f"{a} {b}")` replaces `print(a, b, sep=" ")`
- Extra parameters add complexity for marginal utility
- One argument, one behavior, no surprises

**Why `eprint` not `eprint_ln` or `eprintln`:**
- Same reasoning as `print` — always newline, no suffix
- Shorter name for a common operation (error/debug output)

---

## 2. Implementation Notes

### 2.1 Current State

The compiler currently has four output functions:

| Function | Defined in | Behavior |
|----------|-----------|----------|
| `print(s: str)` | `runtime/helpers.c` as `with_print` | Outputs `s` with NO newline |
| `println(s: str)` | `runtime/helpers.c` as `with_println` | Outputs `s` with newline |
| `with_eprintln(s: str)` | `runtime/helpers.c` | Outputs `s` to stderr with newline |
| `eprintln(s: str)` | prelude alias | Alias for `with_eprintln` |

The compiler source itself uses:
- `with_eprintln(...)` — for error/debug output (hundreds of call sites)
- `print(...)` — in user-facing code, test harnesses

### 2.2 Runtime Changes

**`runtime/helpers.c`:**

Change `with_print` to append a newline:

```c
// Before:
void with_print(with_str s) {
    if (s.ptr && s.len > 0)
        fwrite(s.ptr, 1, (size_t)s.len, stdout);
}

// After:
void with_print(with_str s) {
    if (s.ptr && s.len > 0)
        fwrite(s.ptr, 1, (size_t)s.len, stdout);
    fputc('\n', stdout);
}
```

Remove `with_println` (or make it an alias for `with_print`):

```c
// Remove entirely — or keep as deprecated alias:
void with_println(with_str s) {
    with_print(s);  // with_print now adds newline
}
```

Add `with_eprint`:

```c
void with_eprint(with_str s) {
    if (s.ptr && s.len > 0)
        fwrite(s.ptr, 1, (size_t)s.len, stderr);
    fputc('\n', stderr);
}
```

Add `with_write` and `with_ewrite` (raw output, no newline):

```c
void with_write(with_str s) {
    if (s.ptr && s.len > 0)
        fwrite(s.ptr, 1, (size_t)s.len, stdout);
}

void with_ewrite(with_str s) {
    if (s.ptr && s.len > 0)
        fwrite(s.ptr, 1, (size_t)s.len, stderr);
}
```

### 2.3 Prelude Changes

**`lib/std/prelude.w`** (or wherever builtins are declared):

```
// Before:
extern fn print(s: str)
extern fn println(s: str)
extern fn eprintln(s: str)

// After:
extern fn print(s: str)       // stdout + newline
extern fn eprint(s: str)      // stderr + newline
extern fn write(s: str)       // stdout, no newline
extern fn ewrite(s: str)      // stderr, no newline
// println removed
// eprintln renamed to eprint
```

### 2.4 Compiler Source Migration

The compiler source uses `with_eprintln(...)` extensively for debug/error output. Migration:

| Old | New | Sites |
|-----|-----|-------|
| `println(...)` | `print(...)` | ~20 in tests |
| `eprintln(...)` | `eprint(...)` | ~5 in user code |
| `with_eprintln(...)` | `with_eprint(...)` | ~300 in compiler source |
| `print(...)` (no newline) | Add `\n` to the f-string or use `write()` | ~10 |

The `with_eprintln` → `with_eprint` rename is mechanical. A sed script handles it:

```bash
find src/ -name '*.w' -exec sed -i '' 's/with_eprintln/with_eprint/g' {} +
find test/ -name '*.w' -exec sed -i '' 's/println/print/g' {} +
```

### 2.5 Sites That Currently Rely on No-Newline `print`

Search for `print(` calls that intentionally omit newlines. These are the sites that need attention:

```bash
# Find print calls where the string doesn't end with \n
# These are the ones that rely on no-newline behavior
grep -rn 'print(' src/ test/ --include='*.w' | grep -v 'println\|eprintln\|with_eprintln'
```

Common patterns:
- **Progress output:** `print(f"\r{pct}%")` — needs `write()` eventually
- **Table row building:** `print(cell)` then `print(cell)` — should be `print(f"{cell}{cell}")`
- **Prompt:** `print("Enter name: ")` — needs `write()` eventually

For launch: convert all no-newline print calls to either:
1. A single `print(f"...")` with the full line composed via f-string
2. String building (`var line = ...; print(line)`)

### 2.6 Test Impact

Test files that use `println` need updating:

```bash
grep -rn 'println(' test/ --include='*.w' | wc -l
```

Each `println(x)` becomes `print(x)`. The output is identical since `println` already added a newline and `print` now does too.

Tests that use `print(x)` without newline and rely on concatenated output on one line need to be rewritten to compose the full line first:

```
// Before (two prints on one line):
print("a=")
print(int_to_string(x))
println("")

// After (one print with f-string):
print(f"a={x}")
```

### 2.7 Bootstrap

**Single-step bootstrap.** The compiler source uses `with_eprintln` (a C extern), not `println`. Changing the runtime's `with_print` to add a newline and renaming `with_eprintln` to `with_eprint` doesn't affect what the seed compiler can compile — the extern function names are just strings.

Steps:
1. Change `runtime/helpers.c`: modify `with_print`, add `with_eprint`, keep `with_eprintln` as alias
2. Rename `with_eprintln` → `with_eprint` across all `.w` source files
3. Remove `println` from prelude, add `eprint`
4. Build, fixpoint
5. Remove `with_eprintln` alias and `with_println` from runtime (cleanup)

### 2.8 Error Messages

When someone uses the old names, the compiler should give helpful errors:

```
println("hello")
// error: undefined variable 'println'
//   = help: use 'print' instead — print always adds a newline

eprintln("error")
// error: undefined variable 'eprintln'
//   = help: use 'eprint' instead — eprint always adds a newline
```

These hints can be added to Sema's undefined variable handler by checking if the name matches a known removed function.

---

## 3. Summary

| Function | Target | Newline | Status |
|----------|--------|---------|--------|
| `print(s)` | stdout | Always | **Changed** (was no-newline) |
| `eprint(s)` | stderr | Always | **New** (replaces `eprintln`) |
| `write(s)` | stdout | Never | **New** (raw output) |
| `ewrite(s)` | stderr | Never | **New** (raw stderr output) |
| `println(s)` | stdout | Always | **Removed** (use `print`) |
| `eprintln(s)` | stderr | Always | **Removed** (use `eprint`) |

Two line-printing functions (`print`, `eprint`) and two raw-output functions (`write`, `ewrite`). No suffixes to remember. No parameters to configure. Format with f-strings.

---

*Print semantics — v1.0*