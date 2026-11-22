# Runtime architecture and the self-contained toolchain

Moved verbatim from AGENTS.md (#2374). Nothing here was reworded.

## Runtime Architecture

**D30 landed (steps 1–4, 2026-10-20;
`docs/meetings/2026-08-09-D30-retire-the-internal-runtime-abi-remaining-boundaries-speak-c.md`).**
The runtime is a bundle: `rt/*.with` compiled as one unit per (compiler
generation, target) at compiler build time into `rt.{o,wi,manifest}`
(`build/rt_bundle.with`), embedded in the compiler's `rt` slot (the host's) and
`rt@<tag>` slots (wasm32, the cross tags), and found beside a runtime root
(`out/bootstrap/lib`, `out/lib`, `<compiler_dir>/../lib`) when the slot is
empty (a `:dev` stage1). Every unit with a prelude parses the runtime's
*interface* (`rt.wi`) — the standard library imports it (`use rt.rt_core`,
`rt.platform`, `rt.fiber_core`) — and every link whose undefined symbols
reach the runtime joins the bundle's object, `fiber_asm.o` with it off wasm,
and the on-demand `cimport_stubs.o` archive when the unit reaches libc or
c_import symbols. A runtime that is not the linking compiler's own generation
(the bundle's `generation` line, or bytes equal to the embedded slot, D132)
is never linked: that mixed-world link is #761's corruption class. The
`.w`-derived runtime objects (`rt_core.o`, the platform object, panic,
compat, fiber stubs, channel, fiber runtime, fiber core) no longer exist;
`WITH_RT_IN_UNIT` is gone (the lane is the only path). The seed-built
`out/bootstrap-lib` objects remain until a post-flip seed is cut: the pinned
seed links stage1 in the object world.

Two link paths: **cc (Apple ld64)** for user programs, **lld (LLVM ld64)** for
the compiler build. Compiler-owned runtime behavior is ordinary With code
behind normal module/private-function boundaries.

### `@[c_export]` is foreign ABI only

`@[c_export]` means: this With function is intentionally exported as a C ABI
surface for non-With callers. With-to-With libraries use modules and `pub`;
the compiler and runtime use normal modules/private functions. Any
`@[c_export]` on a declaration compiled into the compiler executable is a bug
(during #335 remove existing ones; after, any occurrence is a regression). Do
not rename them into another internal export mechanism.

### `with_*` is compiler-internal — user programs never call it

Two surfaces, never conflated: user programs use exactly the language
syntax and the `std.*` APIs (`lib/std/`); `with_*` symbols and everything in
`rt/*.with` are the compiler's own runtime — user source never names one; the
compiler emits those calls (`std.regex` is a facade over the pcre2 `.wo`
bundle, `std.engines.pcre2`, D38/D39). If you catch yourself asking "how does a user
program get the `with_*` symbols?", the question is malformed. The standard
library reaches the runtime as a module, never an extern: `use rt.rt_core`,
and by role `use rt.platform` / `use rt.fiber_core` (the active target's
modules; on wasm `rt.fiber_runtime` and `rt.channel_runtime` resolve to the
fiber stubs). The runtime is internal to the standard library and the
compiler: `use rt.*` from a program is refused ("a program reaches it
through std"). A new `extern fn with_*` in `lib/std` is a regression. A
runtime function is safe by its declaration: an `unsafe` block whose only
content is a call of one is vacuous and refused (R4c). The compiler's own
`src/` modules reach the runtime the same way (`use rt.rt_core`, and by
role `use rt.platform`) and libc through `std.libc`; a new `extern fn` in
`src/` is a regression unless it names a C symbol of our own bridge objects
(the `wl_*`/`clang_*` LLVM and Clang bridges, the tool `main`s), never a
runtime or libc function: an agreeing duplicate is a second declaration of
one fact, and the one that disagreed (`exit` typed as returning) hid dead
code (2026-10-25 sweep). A runtime fact crosses the seam typed:
`with_system_info() -> SysInfo`, never a byte pointer with a layout comment.
One constraint shapes the order of such changes: `src/` is compiled by the
pinned seed against the seed's runtime interface and linked with the seed's
runtime, so a new runtime API reaches `src/` only after a seed carrying it is
pinned (a byte-form stand-in stays, marked seed-bound, until then and is
deleted in the pin's own stack: `with_sysinfo` lived from #2621 to the
2026-10-25 seed); `lib/std` is compiled by the tree's compiler and uses it
at once.


## Whose action is it? The user may use system tools; the toolchain is bootstrapped (D171)

Before deciding whether something may run Perl, `sh`, `make`, a host C
compiler or any other system tool, ask **whose action it is**:

- **The user's.** `with get` building a user's C package, a user's own
  project and build, a release UAT scenario (it plays a user). These **may**
  use the host's system tools. A missing tool is named, and installing it is
  the user's step (package-management.md).
- **The toolchain's.** The compiler, its runtime, its build system
  (`build.with`, `build/*.with`), the SDK and the migrated corpora. These may
  **not**: everything they need is bootstrapped from our own sources and SDK
  (D81, and the next section).

The two never meet. Our compiler and our build never call `with get`; the
migrated corpora (pcre2, zlib, …) serve the standard library and the
compiler, never `with get`. So a user's C dependency is never ported,
migrated or substituted to spare `with get` a host tool, and the
toolchain's rule is never applied to a user's action.

The release UAT selects only scenarios the toolchain can do: a scenario uses
only dependencies `with get` provides cleanly on that platform (a Conan
Center binary, or a CMake source build through the compiler's own `cmake`,
`ninja` and `with cc`). A dependency chain that needs a host tool on a
platform (openssl's Perl, libiconv's autotools) takes that platform off the
scenario's `platforms:` line; it never starts a port or a migration
(`uat/README.md`).

Eric has had to explain this distinction three times (2026-10-28). Read it
before proposing anything about a package's dependencies or the UAT.


## Self-Contained Toolchain (we build our own LLVM)

**Not a single line of non-With code in this repo. 1000% self-hosted.**
Inline/platform assembly (`.s`) is the only exception. External native
libraries (libclang, LLVM) are reached through `extern fn` declarations in
With, never a shim in another language. **This includes ALL tooling — even
one-off scripts.** Migrators, rewriters, log scanners, ad-hoc analysis: With,
never Python, bash, perl or awk. With IS a scripting language.

- **One-liners:** `with -e 'print_i32(6 * 7)'` (implicit main);
  `... | with -n 'if line.starts_with("a"): print(line)'` (per line, grep-like);
  `... | with -p 'line = line ++ "!"'` (per-line transform, auto-printed).
- **Never `sed`/`awk`/`cut`/`perl` for text transforms.** A transform
  impossible as a one-liner is a BUG to file. Parity:
  - `sed 's/old/new/g'` → `with -p 'line = line.replace("old", "new")'`
  - `sed -E 's/(a)(b)/\2\1/'` → `with -p 'line = /(a)(b)/.replace(line, "$2$1")'`
  - `sed -n 'A,Bp' file` → `with -n 'if nr >= A and nr <= B: print(line)' < file`
    (`nr` is the 1-based line number, §18.5b)
  - `sed '/pat/d'` → `with -n 'if not line.contains("pat"): print(line)'`
  - `grep pat` → `with -n 'if line.contains("pat"): print(line)'`
    (`.starts_with`/`.ends_with`; `grep -i` is `line =~ /pat/i`)
  - `cut -f2` → `with -n 'print(line.split("\t")[1])'`
  - `awk '{print $2}'` → `with -n 'print(line.fields()[1])'` (runs of blanks
    separate fields; `NF` is `line.fields().len()`; a short line panics (D71),
    check `.len()` first)
  - `wc -l` → `with -n '' -e 'print(nr)'`; `tail -n 1` →
    `with -n 'if last: print(line)'`; state across lines is declared in `-e`
    before the first `-n` and read in `-e` after the last (D217):
    `with -e 'var m = ""' -n 'if line.len() > m.len(): m = line' -e 'print(m)'`
  - `jq -r .a.b` → `with -e 'use std.json` ⏎ `print(JsonDocument.parse(read_all()).root().field("a").field("b").raw())'`
  - `sed -i 's/a/b/' f` → `with -p -i 'line = line.replace("a", "b")' f`;
    `awk '…' f1 f2` → `with -n '…' f1 f2`, with `filename` and `fnr` bound
    (FILENAME, FNR) beside `nr` (D222)
  - Full matrix and open gaps: `docs/spec/toolchain/improve_oneliners.md`.
- **Implicit main** — a `.w` file needs no `fn main`; top-level statements are
  the program, beside helper `fn`s:
  ```
  use std.process
  fn shout(s: str): s ++ "!"
  let argv = args()
  for i in 1..argv.len() as i32: print(shout(argv[i]))
  ```
- **Run without a build step**: `with run tool.with a b` forwards `a b` as argv.
  Reuse the compiler's modules (`use Lexer`, `use Token`) for token-accurate
  source tooling — regex hacks are not acceptable for self-host-critical
  rewrites (see `tools/migrate_receivers.with`).
- File I/O via `use std.fs` (`read_file`, `write_file`, `list_files_text`,
  newline-separated). Never declare the `with_fs_*` externs in a tool or user
  program: that seam SEGFAULTS in user programs (#901) and dies with #761.
  Until #909 lands, `read_file` returns `""` for a missing path.

**After bootstrap the seed depends on nothing external from LLVM.** We build
the static LLVM/Clang/lld SDK from source via `tools/build-static-llvm.sh` into
`.deps/llvm-<ver>-<host>` (`LLVM_PREFIX`): the archives (`libclang.a`,
`libLLVM*.a`, `liblld*.a`) and clang's builtin headers (`lib/clang/<v>/include/`)
that `c_import` needs. The release binary **embeds** these and links libclang
statically; it loads no LLVM/Clang dylib. `LLVM_PREFIX` / `WITH_LIBCLANG` are
build-time link inputs only. **Never trust a system-installed LLVM**, and never
resolve any LLVM/Clang resource from an external path at runtime. If
`c_import` reports `'stddef.h' file not found`, the resource is missing *from
the binary* — fix the embedding; never point `WITH_CLANG_RESOURCE_DIR` /
`LLVM_PREFIX` / `llvm-config` at a system or `.deps` LLVM (clang's builtin
headers are embedded and materialized to a cache at first `c_import`, #312;
`WITH_CLANG_RESOURCE_DIR` is an override-only escape hatch).
