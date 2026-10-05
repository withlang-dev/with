# The With Programming Language

[![linux x86_64](https://github.com/withlang-dev/with/actions/workflows/selfhost-linux.yml/badge.svg?branch=main)](https://github.com/withlang-dev/with/actions/workflows/selfhost-linux.yml)
[![linux aarch64](https://github.com/withlang-dev/with/actions/workflows/selfhost-linux-aarch64.yml/badge.svg?branch=main)](https://github.com/withlang-dev/with/actions/workflows/selfhost-linux-aarch64.yml)
[![macOS arm64](https://github.com/withlang-dev/with/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/withlang-dev/with/actions/workflows/ci.yml)
[![windows x86_64](https://github.com/withlang-dev/with/actions/workflows/selfhost-windows.yml/badge.svg?branch=main)](https://github.com/withlang-dev/with/actions/workflows/selfhost-windows.yml)
[![windows aarch64](https://github.com/withlang-dev/with/actions/workflows/selfhost-windows-aarch64.yml/badge.svg?branch=main)](https://github.com/withlang-dev/with/actions/workflows/selfhost-windows-aarch64.yml)

With is a systems language that compiles to native code. It has no garbage
collector and no lifetime annotations, it is designed to be at least as
safe as Rust, and it treats C as a first-class citizen.

One rule drives the design: **if the program has already determined
something, you should not have to write it.** When only one meaning is
possible, With infers it, imports it, fetches it, links it or proves it.
When two meanings are possible, you spell the choice, and that spelling is
the guardrail.

[Specification](docs/spec/README.md) · [Mission](docs/mission.md) · [Decision log](docs/meetings/README.md) · [Contributing](CONTRIBUTING.md) · [Devlog](https://github.com/withlang-dev/with/discussions/185)

## Use a C library in three commands

```sh
with init .
with get c.raylib
with run
```

That is the whole setup for a raylib program, from an empty directory. You
do not edit a build file, write bindings, install a C compiler, or write
`unsafe`. The program calls raylib directly:

```
use c_import("raylib.h")

fn draw_spiral(cx: f64, cy: f64, t: f64):
    for i in 0..180:
        let p = (i as f64) / 180.0
        let angle = p * 18.8495559215 + t * 0.8
        let radius = 28.0 + p * 250.0 + sin(t * 1.4 + p * 6.0) * 18.0
        let x = cx + cos(angle) * radius
        let y = cy + sin(angle) * radius
        let hue = (p * 360.0 + t * 50.0) as f32
        let col = ColorFromHSV(hue, 0.86 as f32, 1.0 as f32)
        DrawCircle(x as i32, y as i32, (4.0 + p * 4.0) as f32, col)
```

These lines are from [`uat/fixtures/raylib_spiral_main.w`](uat/fixtures/raylib_spiral_main.w).
The scenario [`uat/raylib_spiral.uat`](uat/raylib_spiral.uat) runs exactly
the three commands above in a new directory, then reads the rendered frame
back and checks its pixels. `with uat` runs every scenario in [`uat/`](uat).

What happens behind those commands:

- **`c_import`** reads the real header with the Clang that is linked into
  the compiler. Functions, structs, enums and macros such as `LIGHTGRAY`
  become With names. There is no binding generator to run and no generated
  file to keep.
- **`with get c.<name>`** resolves the package from
  [Conan Center](https://conan.io/center). It uses a prebuilt binary when
  one fits the target. Otherwise it builds the package from source through
  the package's own CMake build, with the Clang, CMake and Ninja that the
  compiler carries. With evaluates the Conan recipe itself, so neither
  Conan nor Python is installed.
- **Linking** uses the lld inside the compiler, against a sysroot the
  compiler carries.

Acceptance scenarios cover raylib, SQLite, zlib, bzip2, libcurl and SDL.

## Built with With

[![WIPE: SURVIVAL gameplay: the ship at the center of a warped blue grid, two kill bursts and floating scores](https://raw.githubusercontent.com/withlang-dev/wipe/main/docs/screenshot.png)](https://github.com/withlang-dev/wipe)

[WIPE: SURVIVAL](https://github.com/withlang-dev/wipe) is a twin-stick
survivor game written in With over raylib: about 12,000 lines in 56 source
files. It has a lattice that warps around the ship, two-tier Gaussian
bloom, eight weapons, bosses, nine ships, and a save written atomically
with a backup. It is a whole program, not a feature demo.

## C handles become owned values

A raw C API hands you pointers and asks you to remember who frees them. A
`c facade` states that contract once (who owns what, what closes what, what
borrows from what), and the compiler enforces it from then on. This program
has no `unsafe` and no raw pointer. The statement is finalized and the
database is closed by their scopes, on every path:

```
use facades.sqlite3
use c_import("sqlite3.h")

fn main:
    let Ok(db) = Database.open(":memory:") else:
        print("sqlite3 open failed")
        return 1
    if db.exec("CREATE TABLE t(value INTEGER); INSERT INTO t(value) VALUES (42);", None, None) != SQLITE_OK:
        print("sqlite3 exec failed")
        return 1
    let Ok(stmt) = db.prepare("SELECT value FROM t") else:
        print("sqlite3 prepare failed")
        return 1
    if stmt.step() != SQLITE_ROW:
        print("sqlite3 step failed")
        return 1
    print(stmt.column_int(0))
```

Today the facade is a file in your project
([`lib/facades/sqlite3.w`](lib/facades/sqlite3.w) is the one used here).
The rules are in [spec §16.2b](docs/spec/ffi.md).

## Translate C into With

```sh
with migrate tiny.c -o tiny.w
with run tiny.w
```

`with migrate` turns C source into With source that you check in and
maintain. Parts of the standard library are its output: the regex engine
behind `=~` is PCRE2 (35 modules), and `std.zlib` is zlib (22 modules), both
migrated from the upstream C and kept in step with it by a drift check in
the build. The translation is literal: migrated code keeps C's pointer
operations inside `unsafe`, and you tighten it from there.

## Ownership without the ceremony

The signature says whether a function borrows or takes ownership. The call
site says nothing:

```
fn total(xs: &Vec[i32]): xs.iter() |> sum()                      // &T borrows

fn archive(xs: Vec[i32]): print(f"archived {xs.len()} values")   // T takes ownership

fn main:
    let xs: Vec = [1, 2, 3]
    print(total(xs))                   // no & at the call
    archive(xs)                        // no move at the call
    print(total(xs))                   // error: use of moved value
```

```
error: use of moved value
 --> main.w:12:17
12 |     print(total(xs))
   |                 ^^
```

Functions return views into their arguments with no lifetime parameters.
The compiler tracks where each view comes from:

```
fn longest(a: &str, b: &str) -> &str:
    if a.len() >= b.len(): a else: b

fn first(xs: &Vec[i32]) -> &i32: xs[0]
```

and it refuses a view that would outlive what it points into:

```
fn first_of_local() -> &i32:
    let xs: Vec = [1, 2, 3]
    xs[0]        // error: returned view may outlive its origin 'xs'
```

## A resource lives in its scope

The language is named for the `with` scope. A value is released when the
scope that owns it ends, and memory is released the same way as any other
resource:

```
type Config { timeout: i32 = 10, retries: i32 = 1, name: str = "svc" }

type Conn { id: i32 }
impl Drop for Conn:
    move fn drop(): print(f"closed {self.id}")

fn main:
    let config = with Config {} as mut c:      // mutable inside, a finished value outside
        c.timeout = 30
        c.retries = 3
    print(f"{config.name} {config.timeout} {config.retries}")

    with Conn { id: 7 } as conn:
        print(f"using {conn.id}")
    print("after")
```

```
svc 30 3
using 7
closed 7
after
```

Here With sets a stricter bar than Rust. Rust classifies a leak as safe.
With's specification classifies it as a defect: a program that does nothing
special does not leak ([spec §2](docs/spec/ownership.md)). The compiler has
a debug allocator built in to check it:

```sh
with run --debug-alloc main.w      # debug-alloc: leak count=0 allocations=9
```

## The happy path is just the value

No `Ok(...)` wrapper on success, no `return` at the end, no type the
compiler can already see:

```
use std.collections.HashMap

error ConfigError =
    Missing(key: str)
    Empty(key: str)

fn setting(settings: &HashMap[str, str], key: &str) -> Result[&str, ConfigError]:
    let value = settings.get(key) ?? return .Err(.Missing(key.clone()))
    if value.len() == 0: return .Err(.Empty(key.clone()))
    value

fn endpoint(settings: &HashMap[str, str]) -> Result[str, ConfigError]:
    let host = setting(settings, "host")?
    let port = setting(settings, "port")?
    f"{host}:{port}"

fn main:
    var settings: HashMap[str, str] = ["host": "localhost", "port": "8080"]
    match endpoint(settings):
        .Ok(e) => print(e)                               // localhost:8080
        .Err(.Missing(key)) => print(f"missing '{key}'")
        .Err(e) => print(f"error: {e}")
```

Enums with payloads, traits, generics, pipelines and comprehensions:

```
enum Shape:
    Circle(radius: f64)
    Rect(width: f64, height: f64)
    Unit

trait Area:
    fn area(self: &Self) -> f64

impl Area for Shape:
    fn area(self: &Self):
        match self:
            .Circle(r) => 3.14159 * r * r
            .Rect(w, h) => w * h
            .Unit => 0.0

fn largest[T: Area](items: &Vec[T]):
    let biggest = items.iter() |> map(it.area()) |> max()
    biggest ?? 0.0                       // an empty list has no largest

fn main:
    let shapes: Vec[Shape] = [.Circle(1.0), .Rect(2.0, 3.0), .Unit]
    print(largest(shapes))                                                   // 6
    let big = shapes.iter() |> filter(it.area() > 1.0) |> map(it.area()) |> collect[Vec]()
    let squares = [x * x for x in 1..6 if x % 2 == 1]                        // 1, 9, 25
```

## A scripting language too

A file needs no `main`; top-level statements are the program, and
`with run tool.w a b` compiles and runs it with arguments. The compiler
also runs one-liners, which makes With a replacement for `grep`, `sed`,
`awk` and `jq`:

```sh
with -e 'print("Hello, World!")'

# grep: lines that start with "a"
cat people.txt | with -n 'if line.starts_with("a"): print(line)'

# sed: swap two columns with a regex and backreferences
cat people.txt | with -p 'line = /(\w+) (\d+)/.replace(line, "$2 $1")'

# awk: line numbers and captures
cat access.log | with -n 'if line =~ /(\d+)$/: if $1 == "500": print(f"{nr}: {line}")'

# jq: a field of a JSON document
echo '{"a":{"b":3}}' | with -e 'use std.json; print(JsonDocument.parse(read_all()).root().field("a").field("b").raw())'
```

Regular expressions are part of the language: `/pattern/flags` literals,
`=~`, and `$1` / `$name` captures in the branch a match guards.

## Concurrency, generators, compile-time code

Calling an `async fn` starts it on a fiber with a real stack and returns a
`Task`; `.await` waits for it. References live across `.await` like any
other local, and there is no `Pin`, `Future` or `Poll`. `async scope`
guarantees that every task it tracks has finished before the scope exits:

```
use std.channel

async fn main:
    let (job_tx, job_rx) = chan[i32](1)
    let (result_tx, result_rx) = chan[i32](1)
    async scope s =>
        s.track(async:
            for n in 1..5: job_tx.send(n)
        )
        s.track(async:
            for _ in 1..5: result_tx.send(job_rx.recv().unwrap() * 10)
        )
        var total = 0
        for _ in 1..5: total += result_rx.recv().unwrap()
        print(total)        // 100
```

A generator is an ordinary function that calls the consumer's loop body at
each `yield`. It can yield views of its own locals, and a `break` in the
consumer releases its scopes:

```
gen fn fibonacci -> i64:
    var a = 0
    var b = 1
    loop:
        yield a
        let next = a + b
        a = b
        b = next

gen fn words(text: &str) -> &str:
    for word in text.split(" "): yield word

fn main:
    for n in fibonacci():
        if n > 50: break
        print(n)
```

`comptime` runs With code during compilation, and `@[derive(...)]`
generates implementations from a type's structure:

```
use std.json

comptime fn squares(n: i32) -> Vec[i32]:
    var table = Vec[i32].new()
    for i in 0..n: table.push(i * i)
    table

const SQUARES: Vec[i32] = comptime squares(8)       // built by the compiler

@[derive(Serialize, Deserialize)]
type User { name: str, age: i32 }

fn main:
    let doc = JsonDocument.parse("{\"name\":\"Ada\",\"age\":36}")
    let user = User.deserialize(doc.root())
    print(f"{user:?}")                                   // User { name: "Ada", age: 36 }
    print(user.serialize(JsonWriter.new()).finish())     // {"name":"Ada","age":36}
```

## One binary, nothing else to install

The `with` executable contains its LLVM, Clang and lld, statically linked,
along with the standard library, the runtime, and the C headers and link
stubs for its target. Building a With program does not use a compiler,
linker or SDK from the host: no Xcode or Command Line Tools, no Visual
Studio or Windows SDK, no system GCC. A gate in the build
(`with build :no-host-toolchain`) fails if any compile or link step reads a
path outside the repository and With's own SDK.

A built program depends at run time only on what the operating system
ships: `libSystem` on macOS, the kernel and glibc 2.28 or later on Linux,
and the DLLs Windows 10 and later carry in-box.

The same binary is the whole toolchain:

| Command | What it does |
|---|---|
| `with run`, `build`, `check` | compile and run, build, type-check |
| `with test` | run every `fn test_*` in a file |
| `with get`, `remove`, `update` | manage C package dependencies |
| `with migrate` | translate C source to With |
| `with fmt`, `with lsp` | formatter and language server |
| `with uat` | run a project's acceptance scenarios |
| `with run --debug-alloc` | find double frees and leaks |
| `with reduce` | shrink a failing program to a minimal reproduction |
| `with analyze` | query and audit the compiler's own semantic, ownership and ABI facts |

## The compiler is written in With

The compiler, the runtime and the build system are written in With (about
233,000 lines in `src/`), plus a few assembly files for fiber context
switches. It compiles itself,
and `with build :fixpoint` checks that the compiler built by itself and the
compiler built by that one are byte-identical. The test suite has more
than 1,600 behavior programs, 1,600 programs that must fail with a specific
diagnostic, and 210 programs tied to sections of the specification.

## Status

With is young, and one person has written most of it. Read this before you
depend on it.

- **The specification leads the implementation.** Where they disagree the
  spec is right, and the spec's changelog marks rules the compiler does not
  yet implement as NON-COMPLIANT. The safety model above is the design; the
  compiler still has bugs against it, and they are tracked in the open
  ([issues](https://github.com/withlang-dev/with/issues)).
- **Releases lag `main`.** Everything on this page was run on a compiler
  built from `main` (v0.15.3.0). The installer below fetches the latest
  release, which may be older.
- **Platforms.** Release binaries are published for macOS arm64, Linux
  x86_64 and arm64, and Windows x86_64 and arm64. macOS is the most
  exercised. Cross-compiling with `--target` is not implemented yet.
- **`with get`** builds from source only for packages whose recipe uses
  CMake. A package that needs Autotools, Meson, MSBuild or a Perl-driven
  configure script works only where Conan Center has a prebuilt binary.
- **Facades** for C libraries are copied into a project by hand today.

## Install

macOS or Linux:

```sh
curl -fsSL https://withlang.org/installer/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://withlang.org/installer/install.ps1 | iex
```

The installer writes one file, `with`, to `~/.local/bin` (set
`WITH_INSTALL_DIR` to choose another directory). To read a script before
running it, drop the pipe. Binaries, checksums and provenance are on the
[releases page](https://github.com/withlang-dev/with/releases). With Nix:
`nix run github:withlang-dev/with# -- -e 'print("hello!")'`.

```sh
with -e 'print("Hello, World!")'
```

## Build from source

The only requirement is `git` and a released `with` binary to start from.
The build fetches its pinned LLVM SDK itself.

```sh
git clone https://github.com/withlang-dev/with.git
cd with
with build :seed          # fetch the compiler pinned in seed.lock
with build                # seed -> stage1 -> stage2
with build :fixpoint      # stage2 and stage3 are byte-identical
with build :test
with build :install-user  # install to ~/.local/bin/with
```

Architecture, testing and debugging are in [CONTRIBUTING.md](CONTRIBUTING.md);
editor setup for VS Code, Neovim, Vim, Emacs, Zed and Helix is in
[docs/proposals/editor-support.md](docs/proposals/editor-support.md).

## License

[MIT](LICENSE).
