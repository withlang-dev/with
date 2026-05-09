# Contributing to With

---

## Building

### Prerequisites

- macOS ARM64 (primary development platform)
- LLVM installed at `/usr/local/llvm` (override with `LLVM_PREFIX` env var)
- Zig (optional, for cross-compilation via `--emit-c`)

### Clone and Build

```bash
git clone https://github.com/QuixiAI/with.git
cd with
make
```

If you don't have `with` on PATH, first download the seed:

```bash
make seed
```

Then `make` builds Stage 2. The output is `out/bin/with-stage2`.

### Verify It Works

```bash
echo 'fn main: println("Hello, World!")' > /tmp/hello.w
./out/bin/with-stage2 build /tmp/hello.w
/tmp/hello
```

If you see `Hello, World!`, you're ready.

### Run the Test Suite

```bash
./scripts/run_tests.sh
```

All tests should pass. If any fail on a clean checkout, open an
issue — that's a bug in main, not in your setup.

---

## Architecture

### The Compiler Pipeline

```
source.w
    → Lexer (src/Lexer.w)         tokens
    → Parser (src/Parser.w)       AST
    → Resolve (src/Resolve.w)     import graph, name resolution
    → Sema (src/Sema.w)           type checking, trait resolution
    → MIR (src/MirLower.w)        desugared control flow graph
    → Async MIR (src/AsyncMir.w)  async/await lowering
    → Codegen (src/Codegen.w)     LLVM IR via llvm_bridge.c
    → Link (src/compiler/Link.w)  binary
```

Each phase has a `--dump-*` flag that prints its output and stops:
`--dump-tokens`, `--dump-ast`, `--dump-resolved`, `--dump-typed`,
`--dump-mir`.

### Directory Map

```
src/
    main.w              CLI entry point
    Lexer.w             tokenizer
    Token.w             token types
    Parser.w            AST construction
    Ast.w               AST node types and pool
    Resolve.w           name resolution and import graph
    Sema.w              type checking
    MirLower.w          typed IR → MIR lowering
    Mir.w               MIR data structures
    AsyncMir.w          async/await MIR transformation
    Codegen.w           MIR → LLVM IR
    CCodegen.w          MIR → C (--emit-c backend)
    compiler/
        Compilation.w   orchestration root
        Zcu.w           canonical compilation state
        Frontend.w      lex/parse/import/prelude injection
        Backend.w       backend dispatch
        Link.w          linker invocation and runtime policy
        Config.w        build configuration

lib/
    std/                standard library (With source)
        prelude.w       implicitly imported into every module
        iter.w          iterator functions
        string.w        string operations
        ...

runtime/
    fiber.c             fiber runtime (C)
    fiber_asm_aarch64.s stack switching (ARM64 assembly)
    llvm_bridge.c       LLVM-C API bridge (statically linked into compiler)
    helpers.c           runtime helpers

test/
    wave1/ .. wave8/    per-wave test suites
    cases/              individual test cases

scripts/
    run_tests.sh        unified test runner
    run_cli_selfhost_tests.sh
                        self-hosted CLI and migrator regression tests
```

### Key Concepts

**Self-hosting.** The With compiler is written in With. Stage 2
(`out/bin/with-stage2`) compiles itself into Stage 3. They're
byte-identical — that's the fixpoint. When you change the
compiler, you're changing the program that compiles itself.

**SoA and handles.** The compiler uses Struct-of-Arrays layout
with `i32` handles instead of pointers. `Ast.w` stores nodes as
parallel arrays indexed by node ID. This is cache-friendly and
avoids reference management. You'll see patterns like
`node_kinds[id]`, `node_spans[id]` everywhere.

**MIR is the fork point.** Both the LLVM backend and the C
backend consume MIR. All syntactic sugar is gone by MIR — no
`|>`, no `?.`, no `with` blocks, no implicit returns. Just
basic blocks, assignments, branches, calls, and drops.

**The prelude.** Every module implicitly imports `lib/std/prelude.w`.
Functions like `println`, `map`, `filter` are normal With functions
made ambient by the prelude, not compiler builtins.

---

## Making Changes

### Workflow

1. Make your change.
2. Rebuild: `make build`
3. Run tests: `./scripts/run_tests.sh`
4. If you changed the compiler, verify fixpoint (see below).
5. Open a PR.

### Verifying Fixpoint

If your change touches the compiler itself (anything in `src/`),
verify the compiler still reproduces itself:

```bash
make fixpoint
```

This builds stage3 from stage2 and checks they are byte-identical.

If fixpoint breaks, your change introduced nondeterminism. Common
causes: hash map iteration order, pointer values in output,
timestamps, or uninitialized memory read as data.

### What Gets Tested

The test runner (`scripts/run_tests.sh`) reads directives from
test files:

```
//! expect-stdout: Hello, World!
fn main:
    println("Hello, World!")
```

Supported directives:

- `//! expect-stdout: <text>` — program output must match
- `//! expect-check-fail` — `check` must fail (negative test)
- `//! expect-build-fail` — `build` must fail
- `//! check-only` — only type-check, don't build

### Adding Tests

For a new language feature, add a test file in the appropriate
directory:

```bash
# Feature test
echo '//! expect-stdout: 42
fn main:
    let x = 42
    println("{x}")' > test/cases/my_feature.w
```

For a bug fix, add a regression test that reproduces the bug:

```bash
# Name it after the issue or the symptom
echo '//! expect-stdout: ok
fn main:
    // This used to crash in the resolver
    let x = some_edge_case()
    println("ok")' > test/cases/issue_123_resolver_crash.w
```

### Compiler Changes vs Library Changes

**Compiler changes** (anything in `src/`): require fixpoint
verification. The compiler compiles itself, so a bug in your
change can prevent the compiler from building.

**Library changes** (`lib/std/`): don't require fixpoint. They're
compiled by the compiler, not part of it. Just run the test suite.

**Runtime changes** (`runtime/`): require a full rebuild and all
tests. The runtime is linked into every binary the compiler
produces.

---

## Debugging

### Reproduce First

Before reaching for any tool, get a minimal reproducing command
and narrow it to a compiler phase:

```bash
time ./out/bin/with-stage2 check your_file.w

# Narrow by phase
./out/bin/with-stage2 check your_file.w --dump-tokens    # lexer
./out/bin/with-stage2 check your_file.w --dump-ast       # parser
./out/bin/with-stage2 check your_file.w --dump-resolved  # resolver
./out/bin/with-stage2 check your_file.w --dump-typed     # sema
./out/bin/with-stage2 check your_file.w --dump-mir       # MIR lowering
./out/bin/with-stage2 build your_file.w                  # full pipeline
```

If `--dump-tokens` works but `--dump-ast` crashes, the bug is in
the parser. If `--dump-resolved` works but `--dump-typed` crashes,
it's in sema. Narrow it down before diving deeper.

### Crashes: LLDB

```bash
lldb -- ./out/bin/with-stage2 check your_file.w
```

Inside LLDB:

```
(lldb) run
(lldb) bt                    # backtrace of current thread
(lldb) bt all                # all threads
(lldb) frame variable        # local variables
(lldb) up / down             # navigate call stack
```

Set breakpoints for targeted debugging:

```
(lldb) breakpoint set -n resolve_module
(lldb) run
(lldb) step / next / continue
```

### Heap Corruption

```bash
MallocScribble=1 MallocGuardEdges=1 \
    ./out/bin/with-stage2 check your_file.w
```

- **MallocScribble** fills freed memory with `0x55` and new
  allocations with `0xAA`. Use-after-free becomes immediately
  visible instead of a silent stale read.
- **MallocGuardEdges** adds guard pages around allocations.
  Buffer overflows crash immediately on the guard page.

To see where a corrupted allocation was created:

```bash
MallocScribble=1 MallocGuardEdges=1 MallocStackLogging=1 \
    ./out/bin/with-stage2 check your_file.w
```

### Memory Leaks

```bash
leaks --atExit -- ./out/bin/with-stage2 check your_file.w
```

Arena allocations freed at process exit show up as leaks but aren't
bugs. Focus on leaks that grow proportionally to input size — those
indicate missing cleanup in a loop or phase transition.

### Deep Memory Analysis: Instruments

```bash
xcrun xctrace record \
    --template "Leaks" \
    --output /tmp/with-leaks.trace \
    --launch -- ./out/bin/with-stage2 check your_file.w

open /tmp/with-leaks.trace
```

Other useful templates: **Allocations** (track every allocation),
**Time Profiler** (find performance bottlenecks).

### Performance Profiling

```bash
# Quick timing
time ./out/bin/with-stage2 check src/main.w

# Instruments
xcrun xctrace record \
    --template "Time Profiler" \
    --output /tmp/with-profile.trace \
    --launch -- ./out/bin/with-stage2 check src/main.w

open /tmp/with-profile.trace
```

For a quick command-line sample without Instruments:

```bash
./out/bin/with-stage2 check src/main.w &
sample $(pgrep -n with-stage2) 5 -file /tmp/with-sample.txt
cat /tmp/with-sample.txt
```

### Debugger Permissions

If you see `not debuggable` or `Unable to acquire required task port`:

```bash
cat > /tmp/debug.entitlements <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.get-task-allow</key>
    <true/>
</dict>
</plist>
EOF

codesign -s - --entitlements /tmp/debug.entitlements --force \
    ./out/bin/with-stage2
```

Re-sign after every rebuild. One-time machine setup:

```bash
sudo DevToolsSecurity -enable
sudo dseditgroup -o edit -a "$USER" -t user _developer
```

### Tool Summary

| Problem | Tool | Overhead |
|---|---|---|
| Crash / segfault | `lldb` | None |
| Use-after-free / overflow | `MallocScribble` + `MallocGuardEdges` | ~1.2x |
| Memory leaks | `leaks --atExit` | ~1.5x |
| Allocation tracking | `MallocStackLogging` | ~3x |
| Deep memory analysis | Instruments (Leaks / Allocations) | ~2x |
| Performance bottleneck | Instruments (Time Profiler) or `sample` | ~1.5x |

---

## Filing a Bug

Include:

1. The minimal `.w` file that reproduces it.
2. Which `--dump-*` flag narrows it to a phase.
3. The LLDB backtrace if it crashes.
