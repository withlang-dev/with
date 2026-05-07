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
5 minutes. Before running `make build`, state what specific
question you're answering and what each possible outcome tells
you. If you can answer the question with `grep`, `nm`, `otool`,
`lldb`, or reading code — do that instead.

**Use the debugger.** The project has debug symbols. `lldb` with
a single breakpoint answers in seconds what print-and-rebuild
answers in minutes. Stop adding debug prints and rebuilding.

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
it. `git stash && make test && git stash pop` answers this
question in under a minute.

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
When a runtime function is needed, implement it in `rt_core.w`
with `@[c_export("symbol_name")]`. Never add new code to
`helpers.c`.

---

## Build System

```
make stage1      # seed → stage1
make stage2      # stage1 → stage2
make build       # stage1 + stage2 + runtime objects
make stage3      # stage2 → stage3
make fixpoint    # verify stage2 == stage3 (byte-identical)
make test        # run test suite
make smoke       # quick smoke test
```

Stage chain: `seed → stage1 → stage2 → stage3`

Fixpoint invariant: `stage2 == stage3`. If fixpoint fails,
code generation is nondeterministic. Stop and fix.

**If the build breaks, fixing the build is the top priority.**

---

## Seed Compiler

Resolution order: `WITH=<path>` → `with` on PATH → `src/main`

`src/main` is not checked into git. It's a GitHub release asset.
Run `make seed` to fetch. After `make build`, `make fixpoint`,
and `make test` all pass, update the installed user compiler:
`make install-user`.

If the seed, installed compiler, and release binaries are all
broken, the compiler cannot be recovered.

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

### String formatting

Use f-strings when they make code shorter and simpler. Use `++`
concatenation when it makes code shorter and simpler. Do not
mechanically prefer one form over the other.

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
make build          # must pass
make fixpoint       # must pass
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
rt/               runtime interface + platform backends (.w, .s)
runtime/          legacy C runtime (helpers.c — being migrated out)
test/             test suite
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
- **Using `make build` as a debugging tool.** It takes 5 minutes.
  Use `grep`, `nm`, `lldb`, or `with check` for diagnosis.
- **Iterating unordered maps** or using pointer-address ordering.
  These break fixpoint determinism.

---

## Success Checklist

A change is acceptable only if:

```
make build      # compiles
make fixpoint   # stage2 == stage3
make test       # no regressions
```

If any step fails, continue debugging until it passes.

After all three steps pass, deploy the verified compiler to
`~/.local/bin/with` with `make install-user`. Do not deploy a
compiler that has not passed the full checklist.

---

## Bootstrap Rules

### The seed compiler is frozen
The installed compiler at ~/.local/bin/with has its own Link.w, its own
embedded runtime objects, and its own codegen logic baked into the binary.
You cannot change its behavior by editing source files. If the seed's
Link.w expects helpers.o, no amount of editing Link.w on disk changes that.
The seed will always look for helpers.o until you install a new seed.

### Never run `make install` with uncommitted changes
`make install` updates the seed. A broken seed breaks all future builds.
Only run `make install` after `make fixpoint` passes on committed code.

### Never change Link.w and runtime files in the same commit
Commit 1: Add new exports to rt_core.w (old link path still works)
Commit 2: Change Link.w + strip helpers.c (new link path activates)
Each commit must independently pass `make fixpoint`.

### Bootstrap order for runtime migration
1. git checkout all runtime/link files to last green state
2. make build && make fixpoint (verify green baseline)
3. Apply rt_core.w changes ONLY (new exports, ABI fixes)
4. make build && make fixpoint (old link path, new symbols available)
5. Apply Link.w + helpers.c + compat_runtime.w changes
6. Build stage1 with old seed (old link path)
7. Stage1 has new Link.w — it builds stage2 with new link path
8. make fixpoint (stage2 == stage3, new link path converges)
9. make install (seed is now updated)

### If bootstrap is broken, don't guess
Run `make doctor` to see what state the seed, stage binaries, and
runtime objects are in.
