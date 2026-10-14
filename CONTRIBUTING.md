# Contributing to With

The rules agents and maintainers work by are in [CLAUDE.md](CLAUDE.md)
(identical to AGENTS.md); this page is the process. The mission is
[docs/mission.md](docs/mission.md); the specification,
[docs/spec/README.md](docs/spec/README.md), leads the implementation.

---

## Building

### Prerequisites

- macOS arm64 is the release host; Linux x86-64 and Windows x86-64 build the
  same way.
- No system LLVM. The toolchain builds its own static LLVM/Clang/lld SDK
  (`tools/build-static-llvm.sh`, under `.deps/`); the release binary embeds it.
- A `with` compiler. The repo is 100% With: every tool and script is a `.w`
  file (`with run tools/x.w`).

### The seed

`src/main` is the seed: the compiler pinned in `seed.lock`, fetched from the
release asset by `with build :seed`. It drives every validation build, exactly
as CI would; the installed `with` drives only the iterate tier.

```sh
with build :seed                 # once per seed.lock bump
export WITH=$PWD/src/main
src/main build                   # seed -> stage1 -> stage2 -> release
```

The release compiler is `out/release/bin/with`; the stages are
`out/bootstrap/bin/with-stage1` and `out/stage/bin/with-stage2`.

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
`--dump-mir`, `--dump-drop-state`, `--dump-async-mir`.

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

rt/
    rt_core.w           core runtime (With source)
    llvm_bridge.w       LLVM-C API bridge
    clang_bridge.w      libclang bridge
    fiber_core_darwin.w fiber runtime
    ...

runtime/
    fiber_asm_aarch64.s stack switching (ARM64 assembly)

test/
    behavior/           behavior tests
    compile_errors/     negative compilation tests
    codegen/            code generation tests
    spec/               specification conformance tests
```

### Key Concepts

**Self-hosting.** The With compiler is written in With. Stage 2
(`out/stage/bin/with-stage2`) compiles itself into Stage 3. They're
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

### Validation is scoped to its tier (D131)

Each tier runs only what it must prove.

| Tier | Must prove | Run |
|---|---|---|
| A fix | it does what it says and breaks nothing nearby | `with check src/main.w`, `with build :dev`, the tests for what you touched |
| A PR | main stays correct and buildable | `with run tools/battery.w` (the battery), once per stack |
| A seed cut or a release | the toolchain reproduces itself; the migrator and the corpora agree | `src/main build :release-checks` |

**A fix.** Write the test first and watch it fail, then fix the root cause
(the exact line, found with the route in
[docs/spec/toolchain/deep-debugging-tools.md](docs/spec/toolchain/deep-debugging-tools.md)).
Iterate with `with check` and `with build :dev` (stage1) and run the tests you
wrote or touched with `out/bootstrap/bin/with-stage1 test <files>`. New code in
`src/` also runs `with run tools/ceremony_census.w --diff HEAD`. Before calling
a layer done, run `src/main build :gate`.

**A PR.** Work landing together goes on one `gh stack`; one battery blesses
the whole stack on its top commit:

```sh
with run tools/battery.w
```

It refuses a dirty tree and runs one graph: the gate, the acceptance scenarios
(`uat/*.uat`) and the survey (the language suites, the drop and move audits,
every PR test target, the green evidence), scheduled by readiness on every
core. A red is written to `out/battery/status.txt` as it lands. Fix every red
on the stack, then run the battery once more. A green battery publishes the
green for those sources (D49): after the squash-merge, main needs no second
battery. A docs-only PR needs only `spec-inventory-check`.

No migration runs for a fix or a PR. The C migrator and the migrated corpora
(`lib/std/re`, `zl`, `c_algorithms`, `tommyds`) change only when a human runs
them: `src/main build :c-migrator-tests` or a corpus lane after a migrator or
corpus change, and `:release-checks` before every seed cut and release.

**A seed cut or a release.** `src/main build :release-checks` runs what the
battery does not: the fixpoint (stage2 compiles the compiler into stage3, and
the two are byte-identical), the Sema regression rebuilds (issue61, the
invariance perturbations), the C migrator tests, every corpus migrated afresh
and tested, and wo-drift. A seed is cut, and a release made, only from a tree
whose `:release-checks` is green; `release-uat` depends on it. Then follow
[docs/spec/toolchain/with-release-runbook.md](docs/spec/toolchain/with-release-runbook.md).
A newer seed lands as its own PR: bump `seed.lock`, `with run
tools/bump_seed_pins.w`, `with build :seed`.

### Pull requests

- Every change reaches `main` through a PR; dependent PRs are a `gh stack`
  (`gh stack link --base main <bottom> ... <top>`), never hand-chained bases.
- A PR is a draft until its battery is green and posted on it.
- Merge the stack in order: `gh stack merge <top-pr> --yes --squash`.
- Every PR must build from the pinned seed. A change that needs a newer seed
  cuts and pins one first.
- One logical change per commit, authored by the human who drove the work
  (Eric: `Eric Hartford <eric@quixi.ai>`); no AI author or co-author lines.
- Never `git stash`; use `git worktree`.

### Decisions and the spec

Only Eric writes or blesses normative spec text. A question that needs a
ruling goes to him as a brief: what the reference languages do, what the spec
says, the mission fit, and a committed prediction (CLAUDE.md, "Do the thing").
A reversible question outside C interop, ownership and safety with a
prediction of 75% or more is delegated (D98): implement it, spec words
included, and record it in [docs/meetings/README.md](docs/meetings/README.md).
Every non-obvious decision is recorded there with its reasoning.

### Filing bugs

A bug found on the way that is outside the change is filed with its spec
reference, a minimal repro, expected and actual output, and any workaround.

### What Gets Tested

The test runner reads directives from test files:

```
//! expect-stdout: Hello, World!
fn main:
    println("Hello, World!")
```

Supported directives:

- `//! expect-stdout: <line>` — one line of the program's stdout. The
  `expect-stdout` lines, in order, are the whole stdout: every printed line is
  listed, exactly, as many times as it prints (`drop 1` does not match
  `drop 10`). An empty line is `//! expect-stdout:`.
- `//! expect-stdout-contains: <text>` — the text appears somewhere in stdout.
  Only for output no run repeats (timings, addresses), with a comment saying
  why; never beside `expect-stdout`.
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
    println("{x}")' > test/behavior/my_feature.w
```

For a bug fix, add a regression test that reproduces the bug:

```bash
# Name it after the issue or the symptom
echo '//! expect-stdout: ok
fn main:
    // This used to crash in the resolver
    let x = some_edge_case()
    println("ok")' > test/behavior/issue_123_resolver_crash.w
```

---

## Debugging

Debugging must identify the exact failing line or allocator event. Avoid
edit/compile/trace loops: trace output and `--dump-*` files are useful for
narrowing a hypothesis, but root cause needs `lldb`, the native debug
allocator, or another direct observation tool.

### Reproduce First

Before reaching for any tool, get a minimal reproducing command
and narrow it to a compiler phase:

```bash
time ./out/stage/bin/with-stage2 check your_file.w

# Narrow by phase
./out/stage/bin/with-stage2 check your_file.w --dump-tokens    # lexer
./out/stage/bin/with-stage2 check your_file.w --dump-ast       # parser
./out/stage/bin/with-stage2 check your_file.w --dump-resolved  # resolver
./out/stage/bin/with-stage2 check your_file.w --dump-typed     # sema
./out/stage/bin/with-stage2 check your_file.w --dump-mir       # MIR lowering
./out/stage/bin/with-stage2 check your_file.w --dump-drop-state # MIR ownership state
./out/stage/bin/with-stage2 check your_file.w --dump-drop-plan  # MIR cleanup plan
./out/stage/bin/with-stage2 build your_file.w                  # full pipeline
```

If `--dump-tokens` works but `--dump-ast` crashes, the bug is in
the parser. If `--dump-resolved` works but `--dump-typed` crashes,
it's in sema. Narrow it down before diving deeper.

When a repro is larger than the failure needs, reduce it before editing:

```bash
./out/stage/bin/with-stage2 reduce your_file.w \
    --contains "diagnostic text" \
    -- ./out/stage/bin/with-stage2 check {file}
```

### MIR And Fixpoint Debugging

For MIR lowering, ownership, and codegen bugs, use the targeted MIR tools before
adding trace prints:

```bash
./out/stage/bin/with-stage2 check your_file.w --trace-place main:_1
./out/stage/bin/with-stage2 check your_file.w --explain-mir-origin main:_1
./out/stage/bin/with-stage2 check your_file.w --trace-ownership main:_1
./out/stage/bin/with-stage2 check your_file.w --dump-drop-plan
./out/stage/bin/with-stage2 check your_file.w --dump-place-map
./out/stage/bin/with-stage2 check your_file.w --trace-cleanup-edge 'main:bb0->bb1'
./out/stage/bin/with-stage2 check your_file.w --dump-drop-flags
./out/stage/bin/with-stage2 check your_file.w --validate-all
./out/stage/bin/with-stage2 check your_file.w --validate-ownership
```

For fixpoint failures, generate the byte-level diff report:

```bash
with build :fixpoint-diff
cat out/fixpoint-diff/report.txt
```

See [docs/spec/toolchain/deep-debugging-tools.md](docs/spec/toolchain/deep-debugging-tools.md) for the exact
command syntax and limits.

### Crashes: LLDB

```bash
lldb -- ./out/stage/bin/with-stage2 check your_file.w
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

### Drop, Lifetime, And With-Allocator Bugs

For double-free, use-after-free, leak, or suspicious drop behavior, start with
the native debug allocator. The With runtime uses its own slab allocator, so
libc malloc tools do not see most With allocations.

```bash
./out/stage/bin/with-stage2 run --debug-alloc repro.w
./out/stage/bin/with-stage2 run --debug-alloc --debug-alloc-filter=non-root repro.w
./out/stage/bin/with-stage2 check repro.w --dump-drop-state
./out/stage/bin/with-stage2 check repro.w --trace-ownership main:_1
./out/stage/bin/with-stage2 check repro.w --dump-drop-plan
WITH_DEBUG_ALLOC=1 ./path/to/already-built-repro
with build :debug-alloc-tests
```

The report prints allocator verdicts such as `DOUBLE FREE`, `LEAK`, and
`origin=List/channel/fiber/with_alloc`. Compiler-emitted drops also report
`first_drop=` and `second_drop=` tags when a double-free is observed. To
resolve source sites for a flagged address:

```bash
./out/release/bin/with build tools/debug_drop.w -o out/debug-alloc-tests/debug_drop
out/debug-alloc-tests/debug_drop run ./out/release/bin/with repro.w
lldb --batch -s tools/debug_drop_sites.lldb \
    -o "run run repro.w" -o "quit" -- ./out/release/bin/with
```

Use `tools/debug_drop_fields.lldb` when the allocator verdict points at a
drop/codegen bug and you need to observe which codegen drop path fired. See
[docs/spec/toolchain/debug-allocator.md](docs/spec/toolchain/debug-allocator.md) and
[test/debug_alloc/README.md](test/debug_alloc/README.md).

### Host Heap Corruption

```bash
MallocScribble=1 MallocGuardEdges=1 \
    ./out/stage/bin/with-stage2 check your_file.w
```

- **MallocScribble** fills freed memory with `0x55` and new
  allocations with `0xAA`. Use-after-free becomes immediately
  visible instead of a silent stale read.
- **MallocGuardEdges** adds guard pages around allocations.
  Buffer overflows crash immediately on the guard page.

To see where a corrupted allocation was created:

```bash
MallocScribble=1 MallocGuardEdges=1 MallocStackLogging=1 \
    ./out/stage/bin/with-stage2 check your_file.w
```

### Memory Leaks

```bash
leaks --atExit -- ./out/stage/bin/with-stage2 check your_file.w
```

Use this for host/libc-level leaks. For With runtime allocations, prefer
`--debug-alloc`, because `leaks` cannot classify logical allocations inside the
runtime slab.

### Deep Memory Analysis: Instruments

```bash
xcrun xctrace record \
    --template "Leaks" \
    --output /tmp/with-leaks.trace \
    --launch -- ./out/stage/bin/with-stage2 check your_file.w

open /tmp/with-leaks.trace
```

Other useful templates: **Allocations** (track every allocation),
**Time Profiler** (find performance bottlenecks).

### Performance Profiling

```bash
# Quick timing
time ./out/stage/bin/with-stage2 check src/main.w

# Instruments
xcrun xctrace record \
    --template "Time Profiler" \
    --output /tmp/with-profile.trace \
    --launch -- ./out/stage/bin/with-stage2 check src/main.w

open /tmp/with-profile.trace
```

For a quick command-line sample without Instruments:

```bash
./out/stage/bin/with-stage2 check src/main.w &
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
    ./out/stage/bin/with-stage2
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
| Large repro | `with reduce` | Predicate cost |
| MIR ownership/codegen bug | `--trace-place`, `--explain-mir-origin`, `--trace-ownership`, `--dump-place-map`, `--validate-all`, `--validate-ownership` | Check-only |
| Fixpoint nondeterminism | `with build :fixpoint-diff` | Stage-object build |
| With double-free / leak / drop bug | `--debug-alloc`, `--dump-drop-state`, `--dump-drop-plan`, `--trace-cleanup-edge`, `tools/debug_drop.w`, `tools/debug_drop*.lldb` | Runtime-gated |
| Host use-after-free / overflow | `MallocScribble` + `MallocGuardEdges` | ~1.2x |
| Host memory leaks | `leaks --atExit` | ~1.5x |
| Allocation tracking | `MallocStackLogging` | ~3x |
| Deep memory analysis | Instruments (Leaks / Allocations) | ~2x |
| Performance bottleneck | Instruments (Time Profiler) or `sample` | ~1.5x |

---

## Filing a Bug

Include:

1. The minimal `.w` file that reproduces it, preferably reduced with `with reduce`.
2. Which `--dump-*` flag or targeted MIR tool narrows it to a phase; include `--dump-drop-state`, `--trace-ownership`, or `--dump-drop-plan` for ownership/drop bugs.
3. The LLDB backtrace if it crashes.
4. The `--debug-alloc` verdict for drop/lifetime/double-free/leak bugs.
