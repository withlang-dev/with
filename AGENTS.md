# AGENTS.md — With Compiler

Rules for AI agents working in this repository.

The With compiler is **self-hosting**. Small mistakes corrupt the
stage chain. Strict discipline is required.

---

## Mission

(Canonical copy: `docs/mission.md`.)

With is an ergonomics-first systems language: close to the
machine, native by default, exactly as safe as Rust, and built
to remove the suffering.

Every unnecessary character is a compiler failure. If With can
infer it, import it, fetch it, bind it, prove it, generate it,
link it, migrate it, wrap it, or make it safe, the programmer
should not have to spell it out.

C interop is first-class, not an escape hatch. With should
understand C headers, ABIs, native libraries, linkers, package
managers, and existing C code well enough to import, integrate,
and migrate them without making the programmer become the build
system.

With pays compiler complexity to remove ceremony without
removing guardrails. Raw C stays explicit; modeled C becomes
humane. The goal is native control, Rust-level safety, and
C-level reach — with the suffering automated away.

---

## Core Principles

**We own every bug.** There is no such thing as "pre-existing."
If a bug exists, we fix it. Never defer. Never work around.

**Root cause, always.** Perform a 5 Whys analysis. Trace the
failure chain to the deepest credible cause. Fix that. Never
fix symptoms.

**Build is verification, not experimentation.** A build takes
5 minutes. Before running `with build`, state what specific
question you're answering and what each possible outcome tells
you. If you can answer the question with `grep`, `nm`, `otool`,
`lldb`, or reading code — do that instead.

**Use the debugger.** The project has debug symbols. `lldb` with
a single breakpoint answers in seconds what print-and-rebuild
answers in minutes. Stop adding debug prints and rebuilding.

---

## Language Design Philosophy

**Don't make the user write anything the compiler already knows,
could figure out, or that doesn't matter.** This is the single
principle behind With's surface syntax, and it must be applied
*pervasively and consistently*. It is why:

- a function returning `i32` doesn't need a trailing `0`
- you don't write `Ok(())` or `Ok(value)` — `?` handles the sad
  path, the happy path just returns the value
- return types are inferred when the body makes them obvious
- `fn main:` not `fn main -> i32:`
- enum variants use `.Variant` when the type is known

**Never force the user to write ceremony for something that does
not matter.** The clearest violation is requiring `let _ = expr`
to discard a value whose discard has no effect. A dropped `Result`
does nothing, so a "must-use Result" diagnostic that forces
`let _ =` is **forbidden** — it makes the user annotate a fact the
compiler already knows and that changes nothing. (Contrast: a
dropped `Task` *cancels* it, so requiring an explicit choice there
is acceptable — the discard actually matters.)

Before adding any rule, error, or required annotation, ask: *does
this make the user state something the compiler already knows, can
infer, or that has no consequence?* If yes, don't add it. A
diagnostic earns its place only by catching a real mistake the
compiler cannot otherwise resolve — not by enforcing ritual.

---

## No Silent Fallbacks

When code cannot be correctly generated, the only acceptable
behavior is to fail loudly with a diagnostic and exit non-zero.
The following are **forbidden** regardless of what tests or
downstream compilation say:

- Emitting a placeholder function body (`-> Never`,
  `comptime_error(...)`, `panic("TODO")`, `return 0`, etc.)
  when translation fails
- Emitting an `extern fn` declaration to paper over a
  function the translator couldn't handle
- Silently dropping a clause, arm, or statement that the
  translator can't lower
- "Simplifying" a construct into something that compiles but
  behaves differently from the source
- Adding a `TODO` comment to emitted output and continuing

**A migrator that produces 30/30 files with silent stubs is
worse than one that produces 0/30 with a loud error.** The
first lies about completeness. The second tells the truth.

If you find yourself reaching for any of these patterns, stop.
The correct action is: emit a diagnostic naming the function
and source location, return non-zero from the tool, and leave
the work visible for a human to prioritize.

If you cannot produce correct output and you cannot fail
loudly (e.g., you're deep in a helper without error-return
plumbing), wire the plumbing. Do not invent a placeholder.

---

## "Done" Is a Claim That Requires Evidence

A task is not done because:

- Tests pass
- The build succeeds
- No compiler errors remain
- The commit was accepted
- Output files exist in the expected directory

A task is done when:

- The output is correct — meaning it does what a human
  familiar with the source would expect, not just what
  happens to compile
- The edge cases you noticed have tests or comments
  explaining why they're not covered
- Anything you couldn't solve is filed as an issue or
  surfaced as a loud failure, not hidden as a passing stub

Before claiming done, do the gut check: *did I make the
success condition true by doing the work, or by redefining
the success condition?* If the answer isn't obviously the
first, it's the second.

This applies especially to translation, migration, and
code-generation tasks where the output volume is large and
correctness is hard to eyeball. In those tasks, "the build
is green" means almost nothing about whether the tool works.

---

## Verify by Running, Not by Reasoning

The compiler's subtle, half-implemented corners — mutable aliasing,
slice mutability, coercions, which types are even spellable — are
exactly where reasoning from layout, signatures, or spec text goes
wrong. Three rules, each learned by shipping a wrong verdict:

**Spell it and run it.** Before concluding a type, mechanism, or API
"works" or "is the surface," write the smallest program that uses it
and compile it. A type that looks usable from its layout may be
unspellable as a parameter (`VecRange`); a `mut` parameter may *move*
rather than borrow; `&raw place` may need an explicit `const`/`mut`
qualifier. You will not find these by reading — only by compiling. "I
read the signature and assumed it" is how wrong conclusions ship.

**Exhaust small answer-spaces in one pass.** When a question has a
small, enumerable set of answers ("how many ways can a mutable buffer
cross a function call?"), test all of them at once and write the
matrix — don't conclude from the first one or two and patch later. A
verdict from partial evidence flips every time the next case is
tested; a verdict from the whole matrix is stable. If you catch
yourself concluding-and-patching the same question twice, stop and
enumerate.

**Code is proof of intent, not just mechanics.** The spec says what
*should* be true; it is not proof of what the design *is* when code
contradicts it. When a spec promise and an implementation fact
disagree (a documented coercion with no producer; a "returns X" the
impl returns as Y), that contradiction is the load-bearing fact:
reconcile it from code before committing to a fix shape, and surface
it for the maintainer rather than assuming which side is canonical.
Test the inconvenient premise first — the fact that fights your
conclusion is the one most worth running.

---

## Anti-Patterns

These patterns are how a task looks successful while actually
being broken. Each one is easy to fall into when the pressure
to complete is high.

**Weakening the check.** If a check fails, the fix is to
make the code pass the check, or to confirm with a human
that the check is wrong. It is never to downgrade the check
to a warning, add an exemption, or route around it.

**"Pre-existing" without evidence.** A failure is only
pre-existing if you've verified it existed on the previous
commit. Otherwise it's your failure and you've just renamed it.
Never use `git stash` to answer this question; use `git worktree`
or a separate clone.

**Silent fallbacks in generated output.** See "No Silent
Fallbacks" above. Placeholder bodies, TODO comments in
emitted code, and "untranslatable" stubs that compile are
all forms of this.

**"Good enough for now."** This is the migrator's biggest
trap. A 90%-working translator that silently mishandles the
other 10% is not 90% done; it's 0% done with a confusing
reporting problem. The bar is correctness, not coverage.

---

## Runtime Architecture

```
rt_core.o    (With)  = the future. All new runtime functions go here.
helpers.o    (C)     = legacy. Functions migrate OUT, never in.
```

Two link paths:
- **cc (Apple ld64):** user programs
- **lld (LLVM ld64):** compiler build

Linking rules:
- Pure With programs (no c_import): `rt_core.o` only
- User programs with c_import: `rt_core.o` first, then
  `helpers.a` as archive (linker pulls only missing symbols)
- Compiler build: `helpers.o` + `support_runtime.o` (no rt_core.o)

**Direction is always: With replaces C. Never duplicate in C.**
When compiler-owned runtime behavior is needed, implement it as ordinary
With code behind normal module/private-function boundaries. Never add new
code to `helpers.c`.

### `@[c_export]` is foreign ABI only

`@[c_export]` means: **this With function is intentionally exported as a
C ABI surface for non-With callers** (C, Rust, Zig, Python FFI, etc.).
It is not a With-to-With linkage tool.

- With-to-With libraries use With modules and `pub` APIs, not `@[c_export]`.
- The With compiler and compiler-owned runtime use normal modules/private
  functions, not `@[c_export]`.
- With libraries should use `@[c_export]` only when they explicitly want to
  expose a foreign-language ABI surface.

Any actual `@[c_export]` attribute on a With declaration compiled into the
compiler executable is a bug. During #335, remove the existing occurrences;
after #335, any compiler-codebase `@[c_export]` occurrence is a regression,
not precedent. Do not copy or rename them into another internal export
mechanism.

### `with_*` is compiler-internal — user programs never call it

Two surfaces. Never conflate them:

- **User programs** use exactly two things: the **language syntax**
  (wired into the stdlib) and the **`std.*` stdlib APIs** (e.g.
  `std.regex`, in `lib/std/`). That is the entire user-facing surface.
- **`with_*` symbols and everything in `rt/*.w` are the compiler's own
  internal runtime/ABI.** User *source* never names a `with_*` symbol —
  the compiler emits those calls. `rt/regex_runtime.w` (`with_regex_*`)
  is the **compiler's** regex; it is compiler code, not a user-facing
  runtime. It is compiled as part of the compiler, not a foreign object
  to embed and hand out.

So never reason as if a user program must *link* or *resolve* the internal
runtime on its own behalf. If you catch yourself asking "how does a user
program get the `with_regex_*` symbols?", **stop** — the question is
malformed. Users reach regex through `std.regex`, never through
`with_regex_*`. `rt/*.w` is part of the compiler; treat it that way.

---

## Self-Contained Toolchain (we build our own LLVM)

**After bootstrap the seed depends on nothing external from LLVM.**
This is a hard invariant, not an aspiration.

*We* build the entire static LLVM/Clang/lld SDK from source via
`tools/build-static-llvm.sh` (`cmake --build --target install` into
`.deps/llvm-<ver>-<host>` = `LLVM_PREFIX`). CMake and its generator backend are
also With-owned SDK tools: build Ninja from source with `tools/build-ninja.*`,
then build CMake from source with `tools/build-cmake.*`, installing both into
the same SDK prefix before the LLVM build. That SDK produces every static
resource the compiler needs:

- `lib/libclang.a`, `lib/libLLVM*.a`, `lib/liblld*.a` — the archives.
- `lib/clang/<v>/include/` — clang's **builtin headers** (`stddef.h`,
  `stdarg.h`, `stdint.h`, …) that `c_import` needs to parse any C header.
- `bin/clang` and `bin/clang++` — the With-owned C/C++ drivers used by
  emitted-C bootstrap. Bootstrap must not fall back to GCC or MSVC `cl.exe`.
- `bin/cmake` — the With-owned CMake used for repeat SDK production.
- `bin/ninja` — the With-owned CMake generator backend used for repeat SDK
  production.
- `bin/lld` plus driver symlinks, `bin/llvm-ml`/`bin/llvm-ml64`,
  `bin/llvm-nm`, and `bin/llvm-strip` — linker, assembler, symbol, and
  release packaging tools.

The release binary **embeds** these, the same way it already embeds the
stdlib (`build/runtime.w` → `EmbeddedStdlibData.w`, served via the
`<embedded-std>/` virtual FS) and the runtime objects (`.EmbedObjectFiles`
→ `with_embedded_*` incbin'd into the binary). libclang is statically
linked; the final binary loads **no** `libclang`/`libLLVM` dylib (the
bootstrap runbook's Failure Policy enforces this). `LLVM_PREFIX` and
`WITH_LIBCLANG` are **build-time link inputs only** — never a runtime
dependency. The static SDK they point at is published per-platform per
release and fetched with `with build :deps` (#313); LLVM is
built from source (`tools/build-static-llvm.sh`) only when bringing up a new
platform or bumping `COMPILER_LLVM_VERSION`. Never rebuild it or point at a
system LLVM during a normal build.

**Never trust a system-installed LLVM.** We didn't build it, so we don't
trust it — and a system LLVM almost never ships the static `.a` we need
anyway. Do **not** resolve any LLVM/Clang resource (archive *or* header)
from an external path at runtime. If `c_import` can't find a builtin
header (`'stddef.h' file not found`), the bug is that the resource is
missing *from the binary* — fix the embedding. **Do not** "fix" it by
pointing `WITH_CLANG_RESOURCE_DIR` / `LLVM_PREFIX` / `llvm-config` at a
system or `.deps` LLVM; that re-introduces the external dependency this
invariant exists to forbid, and a clean release host won't have it.

> Clang's builtin headers ARE now embedded (#312): the build bakes
> `lib/clang/<v>/include` into the binary
> (`out/gen/compiler/EmbeddedClangResourceData.w`), and at first `c_import`
> the compiler materializes them to `~/.cache/with/clang-resource/<v>/` and
> points `-resource-dir` there. `get_clang_resource_dir()` no longer probes
> `LLVM_PREFIX` / `llvm-config` / `/usr/local/llvm`; `WITH_CLANG_RESOURCE_DIR`
> remains an explicit override-only escape hatch. Remaining #312 items are
> about the *host's own* libc, not LLVM-we-built: `get_sdk_path()` shells to
> `xcrun` for the macOS sysroot, and macro extraction shells to `cc`.

### Clang is the only C compiler for bootstrap/release C

All platform bootstrap and release flows that compile C use **Clang**:
macOS, Linux, and Windows. Do not use GCC on Linux, and do not use MSVC
`cl.exe` on Windows. This applies to emitted-C bootstrap compilers,
emit-C fixpoint binaries, C smoke tests, generated bridge C, and release
packaging checks that compile C.

Reason: the emitted-C bootstrap is a compiler artifact, not a portable
"try any C compiler" sample. It must be validated through one C frontend
and one diagnostic/ABI model across all hosts. Mixing GCC, MSVC, and Clang
turns compiler bootstrap failures into host-compiler dialect differences
and hides real With codegen bugs.

Allowed platform C drivers:

- macOS: `clang` with the Apple SDK/sysroot and LLVM/lld inputs required by
  the runbook.
- Linux: `clang` with the With-owned static LLVM/lld SDK and host glibc CRT
  inputs. If only `gcc` is installed, install/provision Clang; do not switch
  the bootstrap to GCC.
- Windows: `clang -target x86_64-pc-windows-msvc` plus `lld-link`; Visual
  Studio Build Tools/Windows SDK may provide headers, libraries, and CRT
  import/static libraries, but `cl.exe` is not the compiler.

The static LLVM SDK itself must also be built with Clang:

- Linux/macOS SDK CMake cache must name `clang` and `clang++`.
- Windows SDK CMake cache must name `clang-cl`, not MSVC `cl.exe`.
- Windows x64 SDK CMake cache must name SDK `llvm-ml64`, not external MSVC
  `ml64`, for MASM assembly.
- Linux/macOS SDK builds must link with lld (`-fuse-ld=lld`) where CMake drives
  a linker.

The first SDK build for a new platform may use an externally installed Clang as
the bootstrap compiler, but that compiler is only used to build the pinned
With-owned SDK from the exact LLVM source tag. Every later compiler/bootstrap/
release artifact must use the Clang, lld, libclang, and LLVM archives from that
SDK. Packaging scripts must reject SDKs whose CMake cache names GCC,
`/usr/bin/cc`, `/usr/bin/c++`, MSVC `cl.exe`, or external MSVC `ml64`.

The first SDK build may use external Python and an external CMake only to build
the SDK's own `bin/ninja` and `bin/cmake`, because these tools bootstrap the SDK
build system. After that point, repeat LLVM SDK production uses
`LLVM_PREFIX/bin/cmake` and `LLVM_PREFIX/bin/ninja`; SDK packaging must reject
archives that do not include both tools. Do not depend on a host Ninja, Make,
MSBuild, or Visual Studio generator for repeat SDK production.

Release binary size parity is a toolchain-parity check. Large `.text`
differences between platforms are not harmless until explained; first verify
the SDK compiler, linker folding/GC policy, and strip policy.

---

## Build System

```
with build              # full build (seed → stage1 → stage2 → final)
with build :stage1      # seed → stage1
with build :stage2      # stage1 → stage2
with build :stage3      # stage2 → stage3
with build :fixpoint    # verify stage2 == stage3 (byte-identical)
with build :test        # run test suite
with build :test-green  # verify/record current test evidence
with build :prune       # report stale build artifacts
```

Stage chain: `seed → stage1 → stage2 → stage3`

Fixpoint invariant: `stage2 == stage3`. If fixpoint fails,
code generation is nondeterministic. Stop and fix.

**If the build breaks, fixing the build is the top priority.**

---

## Seed Compiler

Resolution order: `WITH=<path>` → `with` on PATH → `src/main`

`src/main` is not checked into git. It is the local seed path fetched
from the `with-darwin-aarch64` GitHub release asset. Run `with build :seed`
to fetch it. After `with build`, `with build :fixpoint`, and
`with build :test` all pass, run `with build :test-green` and
`with build :last-green`, then update the local bootstrap seed with
`with build :update-seed` and the installed user compiler with
`with build :install-user`. `with build :test-green` records evidence from a
completed test run; it is not a substitute for running `with build :test`.

If the seed, installed compiler, and release binaries are all
broken, the compiler cannot be recovered.

---

## Releases

For release tasks, follow `docs/with-release-runbook.md`. It is the canonical
release runbook.

Release work is packaging and verification by default. Do not make compiler,
runtime, stdlib, migrator, build-system, or test changes during a release
unless the maintainer explicitly approves expanding the release scope.

If release prep exposes an unrelated bug, file an issue with the repro and
stop there unless the maintainer says it blocks the release.

Publish the Darwin arm64 binary as `with-darwin-aarch64`. Do not publish a
release binary asset named `main`; `src/main` is only the local seed path.

---

## Filing Bugs

If the spec (`docs/with-specification.md`) says something should
work and the compiler disagrees, that is a **compiler bug**. Do
not silently work around it. File an issue with:

- Spec reference (e.g., "§9.7 Pattern Matching")
- Minimal reproduction
- Expected vs actual behavior
- Workaround used (so the fix can remove it)

---

## Editing Protocol

### Before editing

Read relevant source files. Confirm AST layouts. Verify naming
conventions. When you can't find something, grep `examples/`,
`src/`, and `docs/with-specification.md` before assuming it
doesn't exist. Never rely on memory.

Read `out/project-state.md` immediately after this file if it exists.
This file is ignored local agent scratch, not repository documentation.
Do not create it from scratch as routine agent bookkeeping; only create
it if the maintainer explicitly asks. If it exists, keep it current
when phase status, blockers, or the next work queue changes, and follow
its retention policy: it is a short-lived checkpoint, not a history log.
Prune stale completed entries while updating it, prefer GitHub issues
for follow-ups and real docs/specs for durable design facts, and keep
it concise.

### One logical change at a time

Don't batch unrelated changes. Small changes make debugging
possible.

### Commit authorship

Eric Hartford <eric@quixi.ai> is the sole author of this repository.
Never add an AI assistant, model, tool, or vendor as a commit author,
co-author, trailer, or credit line. Do not use `Co-Authored-By` for AI
assistance.

### String formatting

Use f-strings when they make code shorter and simpler. Use `++`
concatenation when it makes code shorter and simpler. Do not
mechanically prefer one form over the other.

### Write nice With code

With source should be pleasant to read and worth keeping as an example
of the language. Passing tests is not enough. Do not mechanically extend
bad shapes such as giant condition chains, fixture dumps in unrelated
modules, copy-pasted validation blocks, or awkward APIs that make the next
change harder. If surrounding code is ugly, improve the shape locally as
part of the change instead of preserving the ugliness. Prefer small named
helpers, clear predicates, typed data, and readable control flow.

Use the language ergonomics. Closed sets are enums, not integer constants
or nullary functions. Enum variant names live under the enum namespace, so
do not repeat the enum name in every variant (`CcCalleeHint.NONE`, not
`CcCalleeHint.CC_CALLEE_HINT_NONE`). Omit redundant type annotations when
the initializer already determines the type, especially `: i32` on integer
values.

Give tag enums an integer backing type (`enum Thing: i32:`). The backing
type is load-bearing, not decoration: a backing-less `enum Thing:` is a
non-Copy tagged ADT, while `enum Thing: i32:` is a Copy integer tag. Any
enum that is passed by value, stored in a `Vec`/`HashMap`, compared, or used
as a lightweight tag (like `TypeKind`, `NodeKind`, `MirIntrinsic`,
`CcBuiltin`) must be `: i32`-backed, or the move-checker will reject ordinary
by-value use. Only omit the backing type for true sum types whose variants
carry payloads and are meant to be moved.

Use semantic types at semantic boundaries. If a value represents a
`MirIntrinsic`, `TypeKind`, `NodeKind`, `BinaryOp`, or local enum such as
`CcBuiltin`, helper parameters and return types should use that enum type,
not `i32`. Raw integers are acceptable only at real storage, wire-format,
FFI, table-index, or bitfield boundaries. Convert at the boundary and keep
the rest of the code typed.

When cleaning a bad local pattern, clean the whole touched slice. Do not
make the maintainer point out each leftover instance one by one. If you
replace function-shaped constants with an enum, update the helper
signatures, sentinel checks, variant names, and nearby callers in the same
logical change. If you cannot complete that cleanup safely, stop and explain
the exact boundary instead of leaving a half-modernized hybrid.

Write With like With. Prefer `enum Thing: A B C` plus `Thing.A` over
C-style prefixes, prefer `let x = value` over redundant annotations, and
prefer small typed helpers over long chains of stringly or integerly
conditionals. Existing bad style is context to improve, not precedent to
copy.

### Shell commands

Compiler, migrator, runtime, and stdlib code must not assemble shell
command strings to perform process or filesystem work. Prefer calling
the internal functions directly; use fibers for concurrency inside the
compiler instead of spawning compiler subprocesses. Shell command strings
are acceptable only in Makefiles, scripts, and test harness glue where
shell semantics such as redirection, globbing, or pipelines are the
point.

### Rebuild and verify

After each change:
```
with build              # must pass
with build :fixpoint    # must pass
```

If either fails, stop adding changes. Debug the failure.

### Re-read before editing

After 10+ messages in a conversation, re-read any file before
editing it. Context compaction may have silently destroyed your
knowledge of file contents. Edit tool fails silently when the
old_string doesn't match due to stale context.

---

## Stage Debugging

### Quick repro
```
time ./out/stage/bin/with-stage2 check src/main.w
```

### LLDB (preferred)
```
lldb -- ./out/stage/bin/with-stage2 check src/main.w
(lldb) run
(lldb) bt all
```

### Heap corruption
```
MallocScribble=1 MallocGuardEdges=1 \
./out/stage/bin/with-stage2 check src/main.w
```

### Leak detection
```
leaks --atExit -- ./out/stage/bin/with-stage2 check src/main.w
```

If stacks are nonsense, suspect seed corruption. Replace the
seed with a known-good binary.

---

## Repository Layout

```
src/              compiler source (.w)
lib/std/          standard library (.w)
rt/               runtime interface + platform backends (.w, .s)
runtime/          legacy C runtime (helpers.c — being migrated out)
test/             test suite
out/bootstrap/bin/ bootstrap stage binaries (build artifacts)
out/stage/bin/   intermediate stage binaries (build artifacts)
out/release/bin/ release compiler binary (build artifact)
out/lib/          compiled runtime objects (build artifacts)
docs/             specifications
```

Source directories must never contain build artifacts.

---

## AST Node Layouts

```
NK_LET_DECL (4)       d0=name  d1=value  d2=flags (bit0=mut, bit1=pub)
NK_LET_BINDING (33)   d0=name  d1=value  d2=flags (bit0=mut)
NK_IF_EXPR (31)       d0=cond  d1=then   d2=else
NK_FOR (37)           d0=binding d1=iterable d2=body  (body is d2, not d1)
NK_WHILE (35)         d0=cond  d1=body   d2=label
NK_MATCH (40)         d0=subject d1=extra_start d2=arm_count
NK_MATCH_ARM (110)    d0=pattern d1=body  d2=guard
NK_BLOCK (30)         d0=extra_start d1=stmt_count d2=tail
NK_RETURN (32)        d0=value
NK_STRUCT_LIT (43)    d0=name  d1=extra_start d2=field_count
```

There is **no `NK_VAR_DECL`**. Mutable variables use the mut
flag on `NK_LET_DECL`.

---

## Common Mistakes

- **Misreading AST layouts.** Always confirm field meanings.
- **Guessing APIs.** Read the source.
- **Working around compiler bugs.** Fix the root cause.
- **Writing C when With works.** The runtime is being migrated
  to With. Compiler-owned With code must use modules/private functions,
  not `@[c_export]`, for internal boundaries.
- **Guessing linker flags.** Understand which link path you're
  on (cc vs lld) before changing anything.
- **Using `with build` as a debugging tool.** It takes 5 minutes.
  Use `grep`, `nm`, `lldb`, or `with check` for diagnosis.
- **Iterating unordered maps** or using pointer-address ordering.
  These break fixpoint determinism.
- **Never use `git stash`.** It has destroyed uncommitted work
  multiple times. There is no valid use case in this repo.
  If you need to test something against a clean state, use
  `git worktree` or a separate clone. `git stash`, `git stash pop`,
  and `git stash drop` are all forbidden.

---

## Success Checklist

A change is acceptable only if:

```
with build              # compiles
with build :fixpoint    # stage2 == stage3
with build :test        # no regressions
with build :test-green  # current test evidence recorded
```

If any step fails, continue debugging until it passes.

After these steps pass, deploy the verified compiler to
`~/.local/bin/with` with `with build :install-user`. Do not deploy a
compiler that has not passed the full checklist.

---

## Bootstrap Rules

### The seed compiler is frozen
The installed compiler at ~/.local/bin/with has its own Link.w, its own
embedded runtime objects, and its own codegen logic baked into the binary.
You cannot change its behavior by editing source files. If the seed's
Link.w expects helpers.o, no amount of editing Link.w on disk changes that.
The seed will always look for helpers.o until you install a new seed.

### Never run seed/install targets with uncommitted changes
`with build :update-seed` updates `src/main`; `with build :install-user`
updates `~/.local/bin/with`. A broken seed breaks future builds. Only run
these targets after `with build :fixpoint` passes on committed code.

### Never change Link.w and runtime files in the same commit
Commit 1: Add new exports to rt_core.w (old link path still works)
Commit 2: Change Link.w + strip helpers.c (new link path activates)
Each commit must independently pass `with build :fixpoint`.

### Bootstrap order for runtime migration
1. git checkout all runtime/link files to last green state
2. with build && with build :fixpoint (verify green baseline)
3. Apply rt_core.w changes ONLY (new exports, ABI fixes)
4. with build && with build :fixpoint (old link path, new symbols available)
5. Apply Link.w + helpers.c + compat_runtime.w changes
6. Build stage1 with old seed (old link path)
7. Stage1 has new Link.w — it builds stage2 with new link path
8. with build :fixpoint (stage2 == stage3, new link path converges)
9. with build :update-seed (local bootstrap seed is now updated)

### If bootstrap is broken, don't guess
Inspect `WITH`, `src/main`, `out/release/bin/with`, the stage binaries, and
runtime objects directly before making changes.
