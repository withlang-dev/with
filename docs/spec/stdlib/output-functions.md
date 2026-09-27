# 15.7 Output Functions

Four output functions. `print` and `eprint` append a newline.
`write` and `ewrite` do not.

| Function | Target | Newline |
|----------|--------|---------|
| `print(s)` | stdout | Always |
| `eprint(s)` | stderr | Always |
| `write(s)` | stdout | Never |
| `ewrite(s)` | stderr | Never |

```
print("hello")               // stdout: hello\n
print(f"count: {n}")         // stdout: count: 42\n
eprint("warning: not found") // stderr: warning: not found\n
write("loading...")           // stdout: loading... (no newline)
write(f"\r{pct}%")           // overwrite current line
ewrite("progress: ")          // stderr, no newline
```

All four take a single `str` argument. Formatting is done via
f-strings, not via the output function itself. There are no format
arguments, no varargs, no separator or end parameters.

```
let name = "alice"
let score = 42
print(f"{name}: {score}")    // alice: 42\n

// Multiple values: use f-strings, not multiple arguments
print(f"{x} {y} {z}")       // not print(x, y, z)
```

**`println` and `eprintln` do not exist.** `print` and `eprint`
always append a newline. Use `write` when raw output without a
newline is needed.

**Design rationale:**
- The overwhelmingly common case is line-terminated output
- Forgetting a newline produces garbled terminal output; forgetting
  to suppress one is harmless
- The `ln` suffix is visual noise on nearly every print call
- F-strings handle all formatting — no need for `sep`/`end` parameters
- `write`/`ewrite` are the explicit opt-in for no-newline output
  (progress bars, prompts, terminal control)
