# AGENTS.md — With Compiler

Rules for AI agents working in this repository.

The With compiler is **self-hosting**. Small mistakes corrupt the
stage chain. Strict discipline is required.

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
commit. Otherwise it's your failure and you've just renamed
it. Never use `git stash` to answer this question; use `git worktree`
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
rt_core.o    (With)  = core runtime. All runtime functions live here.
```

Two link paths:
- **cc (Apple ld64):** user programs
- **lld (LLVM ld64):** compiler build

Linking rules:
- Pure With programs (no c_import): `rt_core.o` only
- User programs with c_import: `rt_core.o` first, then
  `cimport_stubs.o` as archive (linker pulls only missing symbols)

When a runtime function is needed, implement it in `rt_core.w`
with `@[c_export("symbol_name")]`.

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

**After bootstrap the seed depends on nothing external from LLVM.** A
hard invariant.

*We* build the static LLVM/Clang/lld SDK from source via
`tools/build-static-llvm.sh` into `.deps/llvm-<ver>-<host>`
(`LLVM_PREFIX`). That build produces the archives (`libclang.a`,
`libLLVM*.a`, `liblld*.a`) **and** clang's builtin headers
(`lib/clang/<v>/include/`: `stddef.h`, `stdarg.h`, …) that `c_import`
needs to parse C headers. The release binary **embeds** these — like it
already embeds the stdlib and runtime objects — and links libclang
statically; the final binary loads no LLVM/Clang dylib. `LLVM_PREFIX` /
`WITH_LIBCLANG` are **build-time link inputs only**, never runtime deps.

**Never trust a system-installed LLVM** — we didn't build it, and it
won't have the static `.a` we need. Do not resolve any LLVM/Clang
resource (archive *or* header) from an external path at runtime. If
`c_import` reports `'stddef.h' file not found`, the resource is missing
*from the binary* — fix the embedding. **Never** point
`WITH_CLANG_RESOURCE_DIR` / `LLVM_PREFIX` / `llvm-config` at a system or
`.deps` LLVM to make it pass; that re-introduces the dependency this
invariant forbids, and a clean release host won't have it. (Clang's builtin
headers are now embedded in the binary and materialized to a cache at first
`c_import` (#312); `get_clang_resource_dir()` no longer probes external LLVM,
and `WITH_CLANG_RESOURCE_DIR` is an override-only escape hatch.)

---

## Build System

```
with build              # full build (seed → stage1 → stage2 → final)
with build :stage1      # seed → stage1
with build :stage2      # stage1 → stage2
with build :fixpoint    # verify stage2 == stage3 (byte-identical)
with build :test        # run test suite
with build :clean       # remove build artifacts
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
`with build :test` pass, run `with build :last-green`, then update
`src/main` with `with build :update-seed` and the installed compiler with
`with build :install-user`.

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

### One logical change at a time

Don't batch unrelated changes. Small changes make debugging
possible.

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
time ./out/bin/with-stage2 check src/main.w
```

### LLDB (preferred)
```
lldb -- ./out/bin/with-stage2 check src/main.w
(lldb) run
(lldb) bt all
```

### Heap corruption
```
MallocScribble=1 MallocGuardEdges=1 \
./out/bin/with-stage2 check src/main.w
```

### Leak detection
```
leaks --atExit -- ./out/bin/with-stage2 check src/main.w
```

If stacks are nonsense, suspect seed corruption. Replace the
seed with a known-good binary.

---

## Repository Layout

```
src/              compiler source (.w)
lib/std/          standard library (.w)
rt/               runtime source + platform backends (.w, .s)
runtime/          platform assembly (fiber_asm_*.s)
test/             test suite
build.w           build system (with build entry point)
out/bin/          compiler binaries (build artifacts)
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
  to With. Use `@[c_export]` for exported symbols.
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
```

If any step fails, continue debugging until it passes.

---

## Bootstrap Rules

### The seed compiler is frozen
The installed compiler at ~/.local/bin/with has its own Link.w, its own
embedded runtime objects, and its own codegen logic baked into the binary.
You cannot change its behavior by editing source files. The seed will
keep using its baked-in behavior until you install a new seed.

### Never run `with build :install` with uncommitted changes
`with build :install` updates the seed. A broken seed breaks all future
builds. Only run install after `with build :fixpoint` passes on committed
code.

### Never change Link.w and runtime files in the same commit
Commit 1: Add new exports to rt_core.w (old link path still works)
Commit 2: Change Link.w (new link path activates)
Each commit must independently pass `with build :fixpoint`.

### Bootstrap order for runtime migration
1. git checkout all runtime/link files to last green state
2. with build && with build :fixpoint (verify green baseline)
3. Apply rt_core.w changes ONLY (new exports, ABI fixes)
4. with build && with build :fixpoint (old link path, new symbols available)
5. Apply Link.w changes
6. Build stage1 with old seed (old link path)
7. Stage1 has new Link.w — it builds stage2 with new link path
8. with build :fixpoint (stage2 == stage3, new link path converges)
9. with build :install (seed is now updated)
