# 18. Modules and Packages

### 18.1 Modules

```
module math.vector

use std.collections.HashMap
```

The `module` header is optional; a file without one is addressed by
its path. One file is one module; directories group modules into
hierarchical paths. `use` resolution searches, in order: the embedded
standard library, paths relative to the importing module's directory,
the project's `lib/` roots, and the project root.

### 18.2 Imports

Names are imported with `use`. Variant constructors, functions, and
types can all be imported:

```
use std.collections.{HashMap, HashSet}
use Shape.{Circle, Rectangle, Triangle}
use math.vector.{Vec3, dot, cross}
```

**Prelude:** The following are automatically imported into every module:
- `Option.{Some, None}`
- `Result.{Ok, Err}`
- `Bool.{true, false}`
- Primitive types (`i32`, `i64`, `f64`, `bool`, `Int`, `UInt`, etc.)
- `Unit`
- `Vec[T]`, `String` / `str`
- Traits: `Eq`, `Ord`, `Hash`, `Debug`, `Display`, `Default`, `Drop`
- `print`, `eprint` — `print[T: Display](v: &T)`: any `Display` value
  prints; `&str` is one instance. A `match` whose arms do not share a
  `Display` type yields nothing joinable, and the diagnostic's fix-it is the
  f-string (`print(f"{x}")`), never an implicit boxing join.
- `assert`, `assert_eq`, `assert_ne`, `require`, `check`, `panic`, `unreachable`, `todo`
- `drop[T](val: T)` — explicitly drop a value to trigger cleanup

The enumerated prelude list is closed. Its role is (a) the set of
non-imported names permitted bare in `impl` and `extend` headers, and
(b) the `--no-std` core surface. It does not grow to track the standard
library.

**Implicit standard-library availability.** Every public declaration of
the standard library is available by its unqualified name as the
lowest-priority resolution tier. Fallback declarations retain canonical
module identity — this tier is a lookup fallback, never injection into
the module's declaration table.

**Name precedence is deterministic**, highest to lowest:

1. Lexical bindings and generic parameters
2. Current-module declarations
3. Explicit imports and aliases
4. The prelude
5. Unique standard-library fallback

**Within explicit imports, the last one wins.** When two explicit imports
provide the same name, the import written last in the module shadows the
others; this is never an ambiguity error. A `use c_import(...)` is an
import and takes its place in that order.

**Every import is also a namespace**, so a shadowed name stays reachable:

- `use std.math` makes `math`, the last segment of its path, a namespace:
  `math.PI` names std.math's `PI` whatever else is imported. The full
  path, `std.math.PI`, names it as well.
- `use c_import("raylib.h")` makes `raylib`, the header's file name
  without `.h`, a namespace: `raylib.PI`. A header in a directory takes its
  file name (`<SDL3/SDL.h>` is `SDL`). A `c_import` of inline C text has
  no file name and so no default namespace.
- `use m as n` names the namespace `n` instead. It is needed only when two
  imports would otherwise share a namespace name.

```
use c_import("raylib.h")
use std.math

fn main:
    print(f"{PI}")          // std.math's PI: the later import
    print(f"{raylib.PI}")   // raylib's PI, through its namespace
    print(f"{math.TAU}")
```

A user-controlled declaration is never shadowed, merged, or
impl-captured by the fallback tier. If you define `print` — or `Regex` —
in a module, uses in that module resolve to your definition.

**Fallback matching is exact** — no fuzzy matching, ever. Two or more
standard-library candidates for one name is a hard ambiguity error, with
each candidate offered as an insertable-import fix-it; candidate ranking
may order the suggestions but never resolves.

**`impl` and `extend` headers.** A non-prelude standard-library name may
not resolve through fallback alone in an `impl` or `extend` header — an
explicit import or qualified path is required.

**Compatibility invariant.** A standard-library addition may turn a
unique fallback resolution into an ambiguity, but may never rebind an
existing resolution.

**Engine packages** are ordinary explicit dependencies and are never
ambient; a public re-export from the standard library is deliberate
promotion into the ambient vocabulary.

`drop` is a built-in identity function that takes any value by
move and does nothing — the value is destroyed when the argument
goes out of scope:

```
fn drop[T](val: T): ()
```

This is used to trigger resource cleanup at a specific point:

```
let (tx, rx) = chan[i32](10)
// ... send items ...
drop(tx)                 // close the send half, receivers see None
for item in rx:          // drains remaining items
    process(item)
```

### 18.3 Visibility

`pub` exports names. No `pub` = module-private. Cross-module access
to a non-`pub` symbol is a compile error; this applies uniformly to
functions, types, constants, and globals.

### 18.4 Packages

Directory with `with.toml`. Single-file programs need no manifest.
Dependencies hash-pinned in lockfile.

*§18.5 Toolchain moved to `docs/spec/toolchain/toolchain.md`.*

*§18.5a Project Builds moved to `docs/spec/toolchain/project-builds.md`.*

*§18.5b CLI One-Liners moved to `docs/spec/toolchain/cli-one-liners.md`.*

#### 18.5b.1 Generated Environment

All one-liner modes implicitly import common modules, including I/O,
string helpers, regex support, math, collections, and builtins. The
exact generated helper names are implementation-defined; the following
bindings are user-visible:

| Binding | Modes | Type / Meaning |
|---------|-------|----------------|
| `args` | all | `Vec[str]` containing arguments after `--` |
| `line` | `-n`, `-p` | current stdin line, without trailing newline or CRLF `\r` |
| `nr` | `-n`, `-p` | 1-based line number, `i64` |

Arguments after `--` are passed to `args` and are not parsed as With CLI
options:

```
with -e 'for a in args: print(a)' -- foo bar
```

#### 18.5b.2 `-e`

`-e CODE` emits `CODE` as top-level executable statements after the
implicit imports and `args` binding:

```
with -e 'print("hello")'
```

is equivalent, modulo implementation-defined helper names, to an entry
file containing:

```
use std.io
use std.str
use std.regex
use std.math
use std.collections
use std.builtins

let args: Vec[str] = ...
print("hello")
```

#### 18.5b.3 `-n`

`-n CODE` emits a top-level loop over `stdin.lines()`. For each input
line, `line` is bound to the current line and `nr` is incremented before
the user code runs:

```
cat access.log | with -n 'if line =~ /404/: print(f"{nr}: {line}")'
```

is equivalent to:

```
var nr: i64 = 0
for line in stdin.lines():
    nr = nr + 1
    if line =~ /404/: print(f"{nr}: {line}")
```

`stdin.lines()` used by one-liners removes the trailing newline. For
CRLF input, the trailing `\r` is also removed.

#### 18.5b.4 `-p`

`-p CODE` is like `-n`, but prints `line` after `CODE` runs. `line` is a
mutable per-line binding in `-p`, so assignments affect the printed
value:

```
cat names.txt | with -p 'line = line.upper()'
```

is equivalent to:

```
var nr: i64 = 0
for __line in stdin.lines():
    nr = nr + 1
    var line = __line
    line = line.upper()
    print(line)
```

For filtering, use `-n`; `-p` always prints once per input line.

#### 18.5b.5 Semicolons

Shell one-liners often need multiple statements. Within `-e`, `-n`, and
`-p` code strings, semicolons act as line separators:

```
with -e 'var x = 0; x = x + 1; print(x)'
```

The semicolon pass is lexical. It must not split semicolons inside
string literals, regex literals, character literals, or balanced
delimiter groups. Braced blocks may still contain ordinary semicolon
separators:

```
with -e 'if true { print("yes"); print("also yes") }'
```

#### 18.5b.6 Regex One-Liners

Regex one-liners use the normal With regex syntax — this is §15.8
applied to generated entry sources, not a one-liner-only feature:

| Feature | Syntax |
|---------|--------|
| literal | `/pattern/flags` |
| positive match | `text =~ /pattern/` |
| negative match | `text !~ /pattern/` |
| numbered captures | `$0`, `$1`, `$2`, ... |
| named captures | `$name` |

Capture bindings are created only for direct positive regex conditions
whose right side is a regex literal:

```
cat log.txt | with -n 'if line =~ /status=(\d+)/: print($1)'
cat log.txt | with -n 'if line =~ /^\[(?<level>ERROR|WARN)\]\s+(?<msg>.*)$/: print(f"{nr}: {$level} {$msg}")'
```

Named captures include the `$` prefix. A regex capture named `level`
is referenced as `$level`, including inside f-string holes:

```
print(f"{$level}: {$msg}")
```

`!~` is valid for boolean matching but does not create capture
bindings:

```
cat log.txt | with -n 'if line !~ /debug/: print(line)'
```

Compound boolean expressions do not create capture bindings for their
subexpressions. To combine capture use with other conditions, nest the
logic:

```
cat log.txt | with -n 'if line =~ /error (\d+)/ { if line.len() > 0: print($1) }'
```

Regex literals are ordinary `Regex` values in one-liners:

```
with -e 'let r = /hello/i; print(r.is_match("HELLO"))'
```

#### 18.5b.7 Diagnostics

Compiler errors from one-liner user code must point at the user's CLI
argument, not at generated imports, helper bindings, temporary files, or
wrapper code. Diagnostic source names identify the originating argument:

```
with -e 'let x = '
```

reports against `<cli -e #1>`. Multiple same-mode code arguments use
`#1`, `#2`, and so on. Failed one-liner compilation should emit the
normal compiler diagnostic and exit non-zero; it must not add vague
wrapper errors such as "one-liner compilation failed".

#### 18.5b.8 Non-Goals

One-liners do not add shell execution, `s///` substitution syntax, a
REPL execution model, or a separate data-processing mini-language.
Replacement, splitting, and more advanced regex operations use the
normal `std.regex` API.

*§18.5c Bundles and interfaces moved to `docs/spec/toolchain/bundles-and-interfaces.md`.*

*§18.5d Acceptance scenarios moved to `docs/spec/toolchain/acceptance-scenarios.md`.*

*§18.6 Standard Library Design moved to `docs/spec/stdlib/standard-library-design.md`.*

### 18.7 Freestanding Mode (`no_std`)

For embedded, kernel, bootloader, and bare-metal targets, the
standard library can be skipped entirely. Set `std = false` in
`with.toml`:

```toml
[package]
name = "my-firmware"
std = false
```

Or pass `--no-std` to the compiler:

```
with build --no-std --target thumbv7em-none-eabi
```

**What you keep (`core`):**

The `core` library is always available. It contains everything
that doesn't need a heap allocator or OS:

| Category | What's included |
|----------|----------------|
| Primitives | `i8`–`i64`, `u8`–`u64`, `f32`, `f64`, `bool`, `usize` |
| Traits | `Copy`, `Clone`, `Drop`, `Default`, `Debug`, `Eq`, `Ord`, `Hash` |
| Option/Result | `Option[T]`, `Result[T, E]` and all methods |
| Slices | `&[T]` — borrowed views into arrays |
| Fixed arrays | `[T; N]` — stack-allocated |
| Tuples | `(A, B, ...)` |
| Ranges | `0..10`, `0..=10` |
| Math | Integer and float arithmetic, `min`, `max`, `abs` |
| Bitwise | All bit operations on integer types |
| Pointers | `*T`, `*mut T`, safe raw address arithmetic/comparison, unsafe raw memory access/conversion (§16.11) |
| Comptime | All compile-time evaluation (§17) |
| `c_import` | Full C interop — this is how you talk to hardware |
| Ownership | Generational ownership, move semantics, drop (§2.5) — statically optimized to zero cost on single-owner paths, one predicted branch where ownership is dynamic; no GC, no runtime |
| `@[panic_handler]` | Custom panic behavior (see below) |
| `Never` type | For diverging functions |
| `unsafe` blocks | Full unsafe capabilities |
| `comptime if` | Conditional compilation |

**What you lose (`std` only):**

| Category | Requires `std` | Why |
|----------|---------------|-----|
| `str`, `String` | Yes | Heap-allocated |
| `Vec[T]` | Yes | Heap-allocated |
| `HashMap`, `HashSet` | Yes | Heap-allocated |
| `Box[T]` | Yes | Heap-allocated |
| `print`, `eprint`, `write`, `ewrite` | Yes | Needs stdout/stderr |
| `std.io`, `std.fs` | Yes | Needs OS |
| `std.net` | Yes | Needs OS |
| `async fn`, `.await` | Yes | Needs fiber runtime |
| `std.sync` (channels) | Yes | Needs OS threads |

**String literals in `no_std`:** Bare `"hello"` is `&str` (static
reference) in `no_std` mode — there is no allocator to create
an owned `str`. This is the one context where the default type of
a string literal changes. If you need owned strings in `no_std`,
bring your own allocator and use `FixedString[N]` or a similar
stack-allocated string type.

**Panic handler:** In `no_std` mode, you must provide a panic
handler. Without one, the compiler errors:

```
@[panic_handler]
fn on_panic(info: &PanicInfo) -> Never:
    // Option 1: spin forever
    loop {}

    // Option 2: reset the chip
    // cortex_m.SCB.system_reset()
```

**Entry point:** There is no `fn main` in `no_std` unless you
define it yourself. Use `@[entry]` to mark your entry point,
or `@[no_main]` to handle startup entirely through C interop
or linker scripts:

```
@[no_main]
@[entry]
fn start -> Never:
    // Initialize hardware
    let peripherals = c_import("stm32f4xx.h")
    // ...
    loop
        // main loop
```

**Allocator opt-in:** You can get `Vec`, `str`, `Box`, and
other heap types back without pulling in the full `std` by
providing a global allocator:

```toml
[package]
name = "my-firmware"
std = false
alloc = true       # enables core + alloc (heap types, no OS)
```

```
@[global_allocator]
global ALLOC: BumpAllocator = BumpAllocator.new(
    start: 0x2000_0000,
    size: 64 * 1024,    // 64KB SRAM
)
```

With `alloc = true`, you get `Vec[T]`, `Box[T]`, `str`,
`String`, `HashMap`, and `HashSet` — but still no I/O, no
filesystem, no async runtime, no OS-dependent features.

**Three tiers:**

| Tier | `with.toml` | What you get |
|------|-------------|--------------|
| Full | `std = true` (default) | Everything |
| Alloc | `std = false`, `alloc = true` | `core` + heap types |
| Freestanding | `std = false` | `core` only — no heap |

**Embedded hello world:**

```
// with.toml: std = false, target = "thumbv7em-none-eabi"

use c_import("stm32f4xx_hal.h", link: "hal")

@[panic_handler]
fn on_panic(info: &PanicInfo) -> Never:
    loop {}

@[entry]
fn start -> Never:
    let led = gpio_init(GPIOA, PIN_5, .Output)
    loop
        gpio_toggle(led)
        delay_ms(500)
```

Everything With gives you — ownership, borrow checking, `c_import`,
`match`, `comptime`, type inference — works in freestanding mode.
You're just writing With without a heap or an OS.

*§18.8 Package Management moved to `docs/spec/toolchain/package-management.md`.*
