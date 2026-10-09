# 15. Strings

### 15.1 String Types

**There are two string types you need to know:**

| Type | What it is | When to use |
|------|-----------|-------------|
| `str` | Owned, heap-allocated, UTF-8 string | Storing strings, struct fields, return values |
| `&str` | Borrowed view into a string | Function parameters, read-only access |

That's it. `str` for owning, `&str` for borrowing. Everything else
is an implementation detail or FFI-specific.

```
type User { name: str, email: str }    // owned strings in structs
fn greet(name: &str): print(f"Hello, {name}")  // borrowed for reading
fn get_name -> str: "Alice"            // return owned string
```

**String literals** (`"hello"`) are `str` by default (owned). The
compiler is smart about this — when it can prove the string is only
read (never stored, never returned, never mutated), it may optimize
away the allocation and use a static reference internally.
You don't think about this. You write strings, the compiler does the
right thing:

```
let greeting = "hello"       // str — just a string
let user = User { name: "Alice", email: "a@b.com" }  // str fields
```

**When you explicitly want a borrowed view** (e.g., for performance
in a tight loop over slices), annotate it:

```
let view: &str = "hello"     // &str — static reference, no allocation
fn greet(name: &str): ...   // parameter context: callers can pass &str
```

**Advanced types** (you rarely need these directly):

| Type | What it is |
|------|-----------|
| `String` | Same as `str` — `str` is an alias for `String` |
| `StrView` | Same as `&str` — `&str` is an alias for `StrView` |
| `CStr` | NUL-terminated C string view (FFI only) |
| `CString` | Owned NUL-terminated C string (FFI only) |

*§15.2 Conversions moved to `docs/spec/stdlib/string-conversions.md`.*

### 15.3 String Literals

String literals like `"hello"` default to owned `str`. You never
need a type annotation to use a string:

```
// These all just work — no annotations needed
let name = "Alice"
let config = ServerConfig { host: "localhost", port: 8080 }
fn get_name -> str: "Alice"

fn register(name: str): ...
register("Alice")                                          // just works

// Passing to fn(&str) auto-borrows (no allocation):
fn greet(name: &str): print(f"hello {name}")
greet("world")                               // OK: str auto-borrows to &str

// Explicit &str for zero-cost static reference:
let view: &str = "hello"                     // no allocation, static memory
```

**How it works:** Type context decides the storage class
deterministically.

- In `&str` context, the literal is a zero-cost static reference.
  This guarantee is unconditional.
- In owned `str` context, the literal produces an owned `str` and may
  allocate. The compiler may elide the allocation when the owned value
  is observably equivalent to a static immutable string, but elision
  is an optimization, never a guarantee — code that requires zero
  allocation must use `&str` context.

Performance-sensitive code that requires zero allocation should use an
explicit `&str` annotation or pass to an `&str` parameter for guaranteed
zero-cost static storage.

When the type context is `&str` (function parameter, explicit
annotation), the literal is a zero-cost static reference with no
allocation. This guarantee is unconditional — it does not depend
on optimizer analysis.

```
let s = "hello"        // s: str (owned — the default)
let s: &str = "hello"  // s: &str (static reference, no allocation)
```

**F-string literals** (`f"user {id}"`) always produce `str`
(owned) because they must allocate to build the result. Plain
string literals (`"hello"`) do not support interpolation.

**C-string literals:** `c"hello"` produces a `&CStr` — a compile-
time reference to a NUL-terminated string in static memory. The NUL
byte is appended automatically by the compiler; the user does not
write `\0`:

```
// c"hello" is &CStr pointing to static "hello\0"
puts(c"hello".ptr)     // .ptr gives *const u8

// For dynamic C strings, use CString:
let name = CString.new("Alice")   // heap-allocates with NUL
puts(name.as_cstr().ptr)
```

`c"..."` does not support string interpolation. For dynamic C
strings, construct a `CString` from an owned `str`.

`CStr` makes no UTF-8 claim. Its conversions to With text are explicit:
`to_str()` validates and returns an error on invalid UTF-8, `to_str_lossy()`
repairs, and `to_owned()` allocates an owned copy. No `CStr` becomes a `str`
silently.

### 15.4 Formatted String Interpolation (F-Strings)

F-strings are the sole formatting mechanism in With. There is no
`printf`, no `format()` function, no format-string varargs. `print`
takes `str`. `f"..."` returns `str`. One way to format.

```
let s = f"elapsed: {secs:.3}s"
print(s)
print(f"count: {n}, flag: {flag}")
```

An f-string is a string literal prefixed with `f` containing
interpolation holes delimited by `{}`. Each hole contains an
expression and an optional format specification separated by `:`.
An f-string evaluates to `str`.

```
f"literal {expr} literal {expr:spec} literal"
```

The expression may be any With expression: variable, field access,
method call, arithmetic, index, function call. The format spec
controls how the value is rendered as text.

Literal `{` and `}` characters are written as `{{` and `}}`:

```
f"set = {{{val}}}"    // "set = {42}"
```

Plain string literals (`"hello"`) do not support interpolation.
F-strings may not be nested.

**Semantics:**

- Each `{expr}` is type-checked at compile time.
- Non-`str` expressions are converted to `str` via built-in
  formatting functions (no trait dispatch).
- `++` concatenates sequences (§15.4.9); it does not format. Use
  f-strings to format values into strings.
- F-strings always produce owned `str` (they allocate).

#### 15.4.1 Format Specification Grammar

```
spec := [[fill]align][sign]['#']['0'][width]['.' precision][mode]
```

All fields are optional. Omitting the entire spec (`{expr}` with
no colon) uses the type's default display.

| Field | Syntax | Description |
|-------|--------|-------------|
| fill | any single byte except `{` `}` | Padding character (default: space) |
| align | `<` left, `>` right, `^` center | Alignment within width |
| sign | `+` always show sign, `-` negative only (default) | Sign display for numbers |
| `#` | literal `#` | Alternate form: `0x`/`0b`/`0o` prefix |
| `0` | literal `0` | Zero-pad shorthand (equivalent to `0>` fill+align) |
| width | positive integer | Minimum field width |
| precision | `.` followed by non-negative integer | Decimal places (floats) or max chars (strings) |
| mode | single letter | Rendering mode (see below) |

The fill character is only recognized when followed immediately by
an align character (`<`, `>`, `^`). Otherwise the character is
parsed as a later field. This matches Python's rule.

#### 15.4.2 Modes

| Mode | Valid types | Meaning | Example |
|------|------------|---------|---------|
| `d` | integers | Decimal (default for integers) | `42` |
| `x` | integers | Lowercase hexadecimal | `2a` |
| `X` | integers | Uppercase hexadecimal | `2A` |
| `b` | integers | Binary | `101010` |
| `o` | integers | Octal | `52` |
| `f` | floats | Fixed-point | `3.140000` |
| `e` | floats | Scientific notation | `3.14e+00` |
| `g` | floats | C general format, six significant digits by default | `3.14` |
| `s` | strings | String (default for strings) | `hello` |
| `?` | any type | Debug representation | `Point { x: 1, y: 2 }` |

#### 15.4.3 Integer Formatting

Default (no spec): decimal with no padding.

```
f"{42}"          // "42"
f"{-7}"          // "-7"
```

Hex, binary, octal:

```
f"{255:x}"       // "ff"
f"{255:X}"       // "FF"
f"{255:#x}"      // "0xff"
f"{7:b}"         // "111"
f"{7:#b}"        // "0b111"
f"{63:o}"        // "77"
```

Width and zero-padding:

```
f"{42:8}"        // "      42"  (right-aligned by default)
f"{42:08}"       // "00000042"  (zero-pad)
f"{42:<8}"       // "42      "  (left-aligned)
f"{42:^8}"       // "   42   "  (centered)
f"{42:_>8}"      // "______42"  (custom fill)
```

Sign:

```
f"{42:+}"        // "+42"
f"{-42:+}"       // "-42"
```

Precision on integers is a compile-time error.

#### 15.4.4 Float Formatting

Default (no spec): C `printf("%g")` general format, with six significant
digits. Round to the requested significant precision first. If the rounded
scientific exponent is at least -4 and less than the precision, use fixed
notation; otherwise use scientific notation. Remove trailing fractional
zeros and an unnecessary decimal point. Default display is not a round-trip
serialization format. With uses a decimal point independent of locale.

For explicit `g`, precision specifies significant digits; omitted precision
is six and zero precision means one, as in C. When precision is specified
without a mode letter, the mode defaults to `f` (fixed-point).

```
f"{3.14}"          // "3.14"
f"{3.14159:.2}"    // "3.14"       (precision → fixed-point)
f"{3.14159:.2f}"   // "3.14"       (explicit fixed)
f"{3.14159:.2e}"   // "3.14e+00"   (scientific)
f"{3.14:+.2}"      // "+3.14"
```

Integer modes on floats are compile-time errors.

#### 15.4.5 String Formatting

Default (no spec): the string itself, unmodified.

```
let s = "hello"
let t = "hi"
let w = "hello world"
f"{s}"        // "hello"
f"{t:>10}"    // "        hi"  (right-align)
f"{t:<10}"    // "hi        "  (left-align, default)
f"{w:.5}"     // "hello"       (truncation)
```

Numeric modes on strings are compile-time errors.

#### 15.4.6 Boolean Formatting

Default: `true` or `false`. Only `?` mode and width/alignment
are valid. All other modes are compile-time errors.

#### 15.4.7 Debug Mode `:?`

Available for every type in the table below, every type composed of them,
and every type with an `impl Debug`. A value with no Debug form — a function
value, a closure, `dyn Trait`, a range, a `va_list` — is a compile error
under `:?` naming its type; it is never printed as a placeholder. Prints a
structural representation:

| Type | Debug output |
|------|-------------|
| integer | Same as default: `42` |
| float | Same as default: `3.14` |
| str | Quoted and escaped: `"a\"b"`, `"café"` |
| bool | `true` / `false` |
| struct | `TypeName { field: value, field: value }` |
| enum | `Variant`, or `Variant(payload, payload)` |
| `Option[T]` / `Result[T, E]` | `Some(value)` / `None`, `Ok(value)` / `Err(error)` |
| `Vec[T]`, array, slice | `[elem, elem]` |
| `HashMap[K, V]` | `{key: value, key: value}`, entries ordered by the Debug text of their keys |
| `BTreeMap[K, V]` | `{key: value, key: value}`, in key order |
| `HashSet[T]` | `{elem, elem}`, elements ordered by their Debug text |
| `Box[T]`, `Rc[T]`, `Arc[T]` | The value they hold, formatted with `:?`: `Box.new(5)` is `5` |
| raw pointer (`*const T`, `*mut T`) | Its address in hexadecimal: `0x16f3a2b40` |

```
f"{42:?}"        // "42"
f"{name:?}"      // "\"hi\""   (name = "hi")
f"{point:?}"     // "Point { x: 1, y: 2 }"
```

Debug is recursive: every struct field, enum payload, and collection
element is formatted with `:?`, so a value formats the same at every
depth. A type with an explicit `impl Debug` is formatted by its
`debug_str` at every depth; every other type uses the compiler-generated
form. `:?` needs no derive: `@[derive(Debug)]` provides the `Debug` trait,
for code that names it as a bound. A `str` is quoted and escaped: `"` as
`\"`, `\` as `\\`, and the control characters U+0000–U+001F and U+007F as
`\n`, `\t`, `\r`, `\0`, or `\xHH`; every other character, including
printable non-ASCII, appears as itself.

#### 15.4.8 Compile-Time Validation

All invalid type/mode combinations produce clear compile-time
errors:

| | `d` | `x/X/b/o` | `f/e/g` | `s` | `?` |
|---|---|---|---|---|---|
| **integer** | ✓ | ✓ | error | error | ✓ |
| **float** | error | error | ✓ | error | ✓ |
| **str** | error | error | error | ✓ | ✓ |
| **bool** | error | error | error | error | ✓ |
| **struct** | error | error | error | error | ✓ |

Using `{some_struct}` without `:?` is a compile-time error:

```
f"{player}"      // error: struct type Player has no default
                 //   display; use :? for debug
```

#### 15.4.9 Concatenation (`++`, `++=`)

`a ++ b` concatenates two sequences into a new value: two `str` give a
`str`; any two of a `Vec`, a slice, a fixed array or a list literal, with
the same element type, give a `Vec[T]` (a `[T; N+M]` where one is
demanded). Both operands are observed and left untouched; at an operand's
last use the compiler reuses its buffer, so `xs = xs ++ more` costs only
the append. Elements that are not `Copy` are moved, so such an operand
must be at its last use or spelled `move`; otherwise write `.clone()`.

`a ++= b` extends `a` in place, and `v ++= [x]` appends one element.
`push` remains the method for a single element.

```
let greeting = "hello" ++ " " ++ "world"  // "hello world"
let msg = f"count: {n}" ++ "!"            // f-string ++ str
let all = defaults ++ extras              // defaults, extras still usable
args ++= ["-v"]                           // extend in place
```

To include non-string values in a string, use f-strings:

```
// Correct:
let s = f"value: {x}"

// Error:
let s = "value: " ++ x    // error if x is not str
```

*§15.7 Output Functions moved to `docs/spec/stdlib/output-functions.md`.*

*§15.8 Regular Expressions moved to `docs/spec/stdlib/regular-expressions.md`.*
