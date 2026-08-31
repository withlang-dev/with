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

The language is named for the `with` scope: a resource lives in its
scope and is released when the scope ends. Memory is the first
resource, not an exception. Every allocation is owned from the moment
it is made, and its owner's scope releases it — the compiler proves
this the same way it proves safety. Here With is stricter than Rust:
Rust calls leaking safe; With calls it a defect. Leaking memory must
take deliberate, visible effort. If the creators of the language can
leak by accident, the design is wrong, not the programmer.

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

**"Root cause" means the exact line.** A root cause is complete only
when you can name the exact function, branch, and condition producing
the wrong state, observed in `lldb` or the debug allocator. Output
tables, run counts, raw `--dump-mir`/`--dump-drop-state` greps, and
added trace prints are hypotheses, not proof. Do not propose a fix or
deferral from a characterization alone. Deferring a bug is valid only
after locating it at the instruction level and showing the fix needs
foundation work you can point to.

**Self-check trip-wire.** If your last three actions were editing,
compiling, and reading trace output, and you still cannot name the exact
wrong line, stop the loop and switch tools. Use a breakpoint, an
allocator verdict, `with reduce`, `--trace-place`,
`--explain-mir-origin`, `--trace-ownership`, `--dump-drop-plan`,
`--trace-cleanup-edge`, `--validate-all`, `nm`/`otool`, or a smaller checked
repro before the next edit.

**Workflow default for deep compiler bugs.** If the repro is not already
minimal, run `with reduce` with the failing command as the predicate. For
MIR lowering, ownership, and codegen bugs, use `with check --trace-place`,
`with check --explain-mir-origin`, `with check --trace-ownership`,
`with check --dump-drop-plan`, `with check --dump-place-map`,
`with check --trace-cleanup-edge`, and `with check --validate-all` before
adding temporary trace prints. For fixpoint failures, run
`with build :fixpoint-diff` before inspecting generated objects by hand.

**Workflow default for memory bugs.** Any drop/lifetime/double-free/
use-after-free/leak bug starts with the native debug allocator:
`--debug-alloc` or `WITH_DEBUG_ALLOC=1`; see `docs/debug-allocator.md`.
Use `tools/debug_drop.w` and `tools/debug_drop*.lldb` to turn the
allocator verdict into allocation/free sites, inspect `--dump-drop-state`,
`--trace-ownership`, and `--dump-drop-plan` for MIR ownership state, then use
`lldb` on the compiler branch that emitted the bad drop. The allocator says
which memory was mishandled; the dumps say which places the compiler thinks are
live and scheduled for cleanup; the debugger says why codegen emitted it.

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

**Vale, not Rust, is the closest reference for the ownership model.**
We take the best parts of Vale (single ownership, consuming
destructors / Higher RAII, generational references, regions) and
ditch the worst parts. The mission's "exactly as safe as Rust" is a
safety *bar*, not a design compass — we are allergic to Rust's
tiresome syntax and the burden it puts on the dev-user. When a Rust
idiom is adopted because we absolutely must, it is confined to the
library-maintainer tier ("only library maintainers will ever have to
do this, never app developers"). When weighing ownership/drop/
lifetime semantics, check `.reference/Vale` first; reach for Rust
only when Vale's answer cannot meet the safety bar.

**The signature states parameter ownership mode — this is load-bearing.**
For free functions, `&T` borrows and plain `T` consumes. Auto-referencing
removes call-site ceremony: `peek(x)` is the ordinary spelling when `peek`
takes `&T`; `take(x)` is the ordinary spelling when `take` takes `T`. The
signature is authoritative, so a body edit never silently changes ownership,
destructor timing, or the public calling convention. `move x`, `copy x`, and
`&x` remain explicit spellings of intent, but a consuming signature never
requires a redundant call-site `move` acknowledgment. See specification §3.8
and the supersession record in `docs/decisions.md` D5.

Do not infer a borrow merely because a plain-`T` parameter is currently
read-only. That would make the contract and destructor timing depend on the
body. A function that observes a value takes `&T`; a function that retains a
borrowed input must make the lifetime valid, and a function that needs an
independent retained value clones explicitly. During source migrations the
compiler may diagnose a legacy read-only `T` and offer an exact `&T` fix-it,
but canonical mode never silently reinterprets the declared type.

**Receiver modes are separate.** `fn`/`&self` reads, `mut fn`/`mut self`
mutates the receiver place in place, and `move fn`/`move self` consumes it.
Retiring free-parameter SHARE-PLACE does not change `mut fn` receiver
semantics or D21's place-threading pipeline rule.

**D22 has one canonical and complete source: `docs/d22-Eric-Ruling.md`.** It is
Eric's ruling, not a draft or a summary. Every other document, comment, test,
TODO, plan, or implementation behavior that conflicts with it is false and
non-conforming. Do not edit, reinterpret, narrow, or broaden the ruling. The
specification and decision log must conform to it; `docs/d22-implementation-plan.md`
is a derivative execution plan and cannot amend it.

**D22 map-view and contextual-Copy implementation is still in progress.**
`HashMap[K, V].get` and `BTreeMap[K, V].get` uniformly
return `Option[&V]`; `remove` is the ownership-transfer operation and returns
`Option[V]`. Copy-ness never changes a lookup signature. A `&T` remains a
reference during inference and pattern projection, including when `T: Copy`.
It materializes an independent `T` only when an owned-value demand has already
been established. `Option`, `Result`, patterns, `?`, `??`, and eliminators are
transparent to view origins; they do not erase a borrow. Read the canonical
ruling first; specification §§3.4, 3.8, 9.7, 10, 13.3, 21.1 and
`docs/decisions.md` D22 are conforming projections of it.

The current compiler is deliberately NON-COMPLIANT while D22 is being
implemented. Do not restore conditional `get` returns, teach new code that
lookup owns/copies, or treat a lost origin through `unwrap` as precedent. Do
not implement D22 from isolated TODOs: follow
`docs/d22-implementation-plan.md` and the full NON-COMPLIANT acceptance matrix
so every equivalent spelling shares one semantic rule.

**D27 (decisions.md) extends the doctrine to positional collections: element
access observes; `remove` transfers.** `xs[i]` denotes the element place;
`xs.get(i)` returns `&T` (read-only, panics out-of-range — `Option` is for
keyed maps, where absence is normal); a binding names what's there, an
annotation demands what it says. The element-view campaign is done; see
`docs/d27-implementation-plan.md`. The interim #715 element gate and the
deliberately over-broad #730 unannotated-let field gate are retired.
Serialize/Deserialize
signatures are ruled correct as declared (`JsonView` is a Copy view token);
do not "fix" the threaded sink into a borrow.

**`FnAbi` is the single ABI source of truth — never re-derive call ABI
per-path.** Every function signature has ONE ABI descriptor (`FnAbi`
with a per-parameter `PassMode` — `Direct`/`Indirect`/`IndirectPlace`/
`Fat`/`Ignore`), computed ONCE by `compute_fn_abi(sig)` and read by BOTH
the callee prologue (`declare_function`) and every call site
(`push_call_arg`). This is what Rust (`FnAbi`/`PassMode`), Go
(`ABIParamResultInfo`), Zig (`fn_info`), and Clang/LLVM
(`CGFunctionInfo`/`ABIArgInfo`) all do; it makes caller/callee/path
divergence impossible. When adding a call-lowering path, a receiver
shape, or a parameter kind, extend `compute_fn_abi`/`PassMode` in ONE
place and read it — **never** write a fresh per-path "value vs address
vs byval" decision. A per-path ABI derivation is the exact bug that
produced the transparent `T*`/`T**` divergence; re-introducing one is a
regression. `PassMode::IndirectPlace` is a physical mode for compiler-modeled
borrowed places such as in-place receivers; an explicit `&T` is itself a
reference value with the ABI of that reference type. A plain consuming `T` is
owned even when its physical ABI is indirect. See `docs/decisions.md` D6 and
`docs/fn_abi_descriptor_design.md`.

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

**Code settles facts; intent is the maintainer's call.** The spec says
what *should* be true; running the code shows what *is* — what
compiles, what's spellable, whether a feature even has a producer.
When a spec promise and an implementation fact disagree (a documented
coercion with no producer; a "returns X" the impl returns as Y), the
*facts* come from running code, but *which side is canonical* is a
design decision — not derivable from the code or the spec. Settle the
facts by running; then surface the contradiction for the maintainer
rather than assuming which side wins. Test the inconvenient premise
first — the fact that fights your conclusion is the one most worth
running.

**And otherwise, keep moving.** These rules are about *verifying*, not
*pausing* — they cure over-autonomy (acting past a real fork), not the
opposite failure of hovering at every seam. The discriminator is narrow:
stop only when there is a decision that is genuinely the maintainer's —
intent, scope, or a go/no-go on real risk you cannot resolve yourself.
When the path is clear and self-scoped — you already know what to do and
can verify it by running — proceed and report as you go; do not ask
permission to continue. Owning a decision to defer ("I'm picking this up
fresh because X") is fine; voicing it as a permission request is the
hover. Restraint that catches a real fork is discipline; restraint
applied to a clear path is just the under-autonomy failure wearing
discipline's clothes.

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

**TRANSITIONAL — D30 (docs/decisions.md) retires this object-boundary
design.** Destination: the runtime compiles in-unit like the embedded
stdlib; rt objects survive only as a (compiler-version, target)-keyed
cache whose hits are byte-identical to the in-unit result. A runtime
object built by a different compiler generation must never be linked —
that mixed-world link is #761's corruption class. The layout below is
the current tree until the retirement lands.

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

When compiler-owned runtime behavior is needed, implement it as ordinary
With code behind normal module/private-function boundaries.

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

**DEPRECATED TIER — D30 (2026-08-09) retires the internal runtime ABI.**
The `with_*` seam is a C-bootstrap fossil, not a semantic necessity: the
runtime will compile in-unit like the embedded stdlib, codegen will lower
to ordinary module functions, and pre-compiled rt objects survive only as
a (compiler-version, target)-keyed cache — never as a boundary with its
own contracts (#761 is what such a boundary does). Until the retirement
lands (sequenced after the 747-flip merge/reseed), the guidance below
remains operative for the current tree; do not build NEW machinery on
this seam, and see §16.3e for the boundary-type rule that governs the
surfaces that remain after it.

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

**Not a single line of non-With code in this repo. We are 1000%
self-hosted.** Inline/platform assembly (`.s`) is the only exception.
No C, no C++, no glue files — external native libraries (libclang,
LLVM) are reached through `extern fn` declarations in With, never
through a shim written in another language. If a capability seems to
require a C/C++ source file, the answer is a With-side implementation
over the C API (or asm), or the capability waits.

**This includes ALL tooling — even temporary, one-off, throwaway scripts.**
Migrators, source rewriters, log/output scanners, ad-hoc analysis: write them in
With, never in Python, bash, perl, or awk. A Python/bash scratch script in this
repo is the same violation as C in the compiler — delete it and rewrite it in
With. With IS a scripting language; there is no "just a quick script" exception.

- **One-liners** (perl/python `-e` style):
  - `with -e 'print_i32(6 * 7)'` — eval a snippet (implicit main)
  - `... | with -n 'if line.starts_with("a"): print(line)'` — run the code per
    stdin line with `line` bound (grep-like)
  - `... | with -p 'line = line ++ "!"'` — per-line transform, auto-printed
    (sed-like)
- **Never `sed`/`awk`/`cut`/`perl` for text transforms — use a `with` one-liner.**
  If a transform is genuinely impossible as a one-liner, that is a BUG to file, not
  a reason to reach for sed.
  - `sed 's/old/new/'`  →  `... | with -p 'line = line.replace("old", "new")'`
  - `grep pat`          →  `... | with -n 'if line.contains("pat"): print(line)'`
    (also `.starts_with`/`.ends_with`)
  - `cut -f2`           →  `... | with -n 'print(line.split("\t").get(1))'`
  - complex regex       →  `use std.regex` in a `with run tool.w` script
    (`Regex.replace(text, repl)`); prefer str `slice`/`split`/`replace` first.
- **Implicit main** — a `.w` file needs no `fn main`; top-level statements ARE
  the program, and may sit alongside helper `fn` definitions:
  ```
  use std.process
  fn shout(s: str): s ++ "!"        // return type inferred
  let argv = args()                      // std.process
  for i in 1..argv.len() as i32: print(shout(argv.get(i as i64)))
  ```
- **Run without a build step**: `with run tool.w a b` compiles-and-runs and
  forwards `a b` as the program's argv. Reuse the compiler's own modules
  (`use Lexer`, `use Token`) for token-accurate source tooling — regex/text
  hacks are not acceptable for self-host-critical rewrites. See
  `tools/migrate_receivers.w`.
- File I/O via `extern fn with_fs_read_file(path: str) -> str` /
  `with_fs_write_file(path: str, data: str) -> i32`. (Transitional
  spelling: these decls are the D30-deprecated internal seam and die with
  it — post-retirement, tools reach fs through `std.fs`, and `str` in an
  extern signature is a §16.3e error.)

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
with build :dev         # dev tier: seed → stage1 only (D14 iterate loop)
with build :stage1      # seed → stage1
with build :stage2      # stage1 → stage2
with build :fixpoint    # verify stage2 == stage3 (byte-identical)
with build :test        # run test suite
with build :test-green  # verify/record current test evidence
with build :clean       # remove build artifacts
```

Stage chain: `seed → stage1 → stage2 → stage3`

Fixpoint invariant: `stage2 == stage3`. If fixpoint fails,
code generation is nondeterministic. Stop and fix.

**If the build breaks, fixing the build is the top priority.**

### Optimization level: ALWAYS `-O1`, NEVER `-O0`

The compiler is built at **`-O1`** everywhere — **all** stages (stage1, stage2,
stage3), the fixpoint stages, every runtime/bootstrap object, and the release
binary. There is **no `-O0` anywhere** in `build.w` / `build/*.w`. The build files
encode this; **it is an invariant, not a preference.** (The first build after a
fresh seed is slow because the `-O0` seed builds the `-O1` stage1; once the `-O1`
compiler is installed as the seed, subsequent builds are fast. That one-time cost
is not a reason to drop to `-O0`.)

- **Never switch the build to `-O0`.** `-O0` produces pathologically slow,
  unoptimized output (e.g. it turned a 26k-line module's object build into 31+
  minutes; `-O1` does it in seconds). The build/test step timeouts assume an
  `-O1` compiler.
- **`-O1` is fully deterministic** (fixed pass pipeline, no RNG, no
  address-dependent choices). If fixpoint (`stage2 == stage3`) breaks under `-O1`,
  that is a **real nondeterminism bug in our codegen** — find it with
  `with build :fixpoint-diff` and **fix it**. Dropping to `-O0` to make fixpoint
  pass is forbidden; it hides the bug.
- **A bug that only appears at `-O1` is a real bug** — latent undefined behavior
  the optimizer exposed, or a genuine miscompile. Root-cause and fix it. `-O0` is
  **not** a workaround; "it works at `-O0`" means "we have a UB/codegen bug we are
  hiding."
- **Switching to `-O0` to make a red build/test/fixpoint go green is the single
  most forbidden shortcut here.** It has been done repeatedly by agents dodging
  real, fixable bugs. Do not do it. If you catch yourself reaching for `-O0`,
  stop — the task is to fix the bug `-O1` revealed.
- The *only* allowed `-O0` use is a deliberate, explicitly-approved, temporary
  local diagnostic. It must be reverted before any commit. **Never commit an
  `-O0` build setting.** If you see `-O0` anywhere in `build.w` / `build/*.w`,
  that is a regression — restore `-O1`.

---

## Seed Compiler

Resolution order: `WITH=<path>` → `with` on PATH → `src/main`

`src/main` is not checked into git. It is the local seed path fetched
from the `with-darwin-aarch64` GitHub release asset. Run `with build :seed`
to fetch it. After `with build`, `with build :fixpoint`, and
`with build :test` pass, run `with build :test-green` and
`with build :last-green`, then update `src/main` with
`with build :update-seed` and the installed compiler with
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

## The Specification Leads

`docs/with-specification.md` is the bible. For D22,
`docs/d22-Eric-Ruling.md` is the complete controlling ruling: if the spec,
requirements, decision summary, plan, tests, comments, or code omit or conflict
with it, those sources are non-conforming and must be repaired to match it.
Two rules are otherwise absolute:

**The spec leads the implementation.** A spec change is a ruling that the
product is now NON-COMPLIANT until the implementation catches up. There is
no "implement first, spec after," no "hold the spec text until the code
lands," and no reverting spec text to match what the code happens to do.
Compliance work chases the spec — never the reverse. When the spec and the
implementation disagree, the implementation is wrong, or the disagreement
is surfaced to Eric for a ruling; it is never resolved by quietly editing
the spec.

**Spec changes are solemn.** Only Eric authors or blesses normative spec
text — the exact words, not just the direction (D16's precedent: "the
uniform spec sentence landing as the ruling itself"). An agent may draft
and propose language, but a general directive, a mission statement, or an
agreed design direction is NOT approval of specific spec wording. Nothing
lands in the spec without Eric's explicit blessing of the words
themselves.

### "Do the thing" — the decision procedure

Every spec change, and most decisions surfaced to Eric, go through this
procedure. Present all four parts in one brief, then wait for the ruling:

1. **What the others do.** Compare the reference projects (`.reference/`:
   go, mojo, rust, swift, Vale, zig — plus any that fit) — verified in
   their trees, not from memory. Name the mechanism each uses and where it
   diverges from the others.
2. **What the spec currently says.** Quote the exact text. Check whether
   the current spec already rules the question (it often does — the
   implementation may simply be non-compliant), and whether the proposal
   duplicates an existing rule (one rule, one normative home).
3. **Mission fit.** Relate the choice to `docs/mission.md` and the
   decision record (`docs/decisions.md`). Say which option is most
   with-y, not just which is safest.
4. **Predict what Eric would say.** A committed BDFL prediction with
   confidence, derived from his decision record — not a menu of options
   with no stake. The prediction is falsifiable; being wrong and told why
   improves the record.

Then Eric rules. For spec changes, the blessed wording lands immediately
as the ruling itself, and the implementation is non-compliant until it
conforms (see above).

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

## Decision Log

`docs/decisions.md` records non-obvious design/architecture decisions and
**why** we made them (context, alternatives weighed, reasoning, and what would
reopen the call). When you make or reverse a judgment call that a future
maintainer or agent might re-litigate — an ownership/safety semantics ruling, a
deviation from the reference implementations, a spec amendment that reverses an
earlier one — append an entry (newest first) and cross-link superseded ones.
Consult it before reopening a settled question. Keep it terse; it is reasoning,
not a changelog.

---

## Editing Protocol

### Before editing

Read relevant source files. Confirm AST layouts. Verify naming
conventions. When you can't find something, grep `examples/`,
`src/`, and `docs/with-specification.md` before assuming it
doesn't exist. Never rely on memory.

### Code style — write the least ceremony

Match the surrounding code, and follow the mission at the character level:

- **Don't spell types the compiler can infer.** Omit a return type when the body
  makes it obvious (`fn shout(s: str): s ++ "!"`, not `-> str`); omit a
  local's type when the initializer gives it. Annotate only where inference
  genuinely needs it (e.g. `var xs: Vec[i32] = Vec.new()`).
- **Inline the colon when the body is very small.** `fn millis(ms: i32): ms`
  and `fn get(): self.n` on one line — do NOT break a one-token/one-expression
  body onto its own indented line. Use a block body only when the body is
  actually multi-statement or long.
- **Boy-scout the style: any time you touch an existing function, fix its style
  too** — drop inferable types, inline tiny bodies. Leave the whole function
  least-ceremony, not just the lines you came to change.

### One logical change at a time

Don't batch unrelated changes. Small changes make debugging
possible.

### Commit authorship

Eric Hartford <eric@quixi.ai> is the sole author of this repository.
Never add an AI assistant, model, tool, or vendor as a commit author,
co-author, trailer, or credit line. Do not use `Co-Authored-By` for AI
assistance.

### Rebuild and verify (tiered — see decisions.md D14, D19)

**Iterate tier — the only per-change requirement.** `with check src/main.w`
and/or `with build :dev` (seed → stage1, one self-compile), plus the
targeted tests for what you touched. Never run the full battery per edit.

**Batch tier — the default.** Accumulate related commits; ONE battery
blesses the whole batch:
```
with build              # must pass
with build :fixpoint    # must pass
```
plus `audit:all`, `:test`, `:test-green`, `:last-green` (`audit:all` and
`:test` may run concurrently — they share no outputs), then reseed once.
Batteries are expensive; batching them is the discipline, not a shortcut.

**Isolation rule — blast radius, not ritual.** A change to ownership/drop
scheduling, codegen determinism, or ABI must be ALONE in its batch (and
adds `:move-audit`/`:drop-audit`), so a red battery indicts one change.
Docs, build-layer, and tooling changes batch freely and skip the drop
audits.

If a batch's battery fails: bisect within the batch using iterate-tier
evidence. Do not add changes to a red batch.

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

### Deep compiler tools
Use these before edit/compile/trace loops on MIR, ownership, codegen, or
fixpoint bugs:
```
./out/stage/bin/with-stage2 reduce repro.w --contains "diagnostic" -- ./out/stage/bin/with-stage2 check {file}
./out/stage/bin/with-stage2 check repro.w --trace-place main:_1
./out/stage/bin/with-stage2 check repro.w --explain-mir-origin main:_1
./out/stage/bin/with-stage2 check repro.w --trace-ownership main:_1
./out/stage/bin/with-stage2 check repro.w --dump-drop-plan
./out/stage/bin/with-stage2 check repro.w --dump-place-map
./out/stage/bin/with-stage2 check repro.w --dump-abi
./out/stage/bin/with-stage2 check repro.w --trace-cleanup-edge 'main:bb0->bb1'
./out/stage/bin/with-stage2 check repro.w --dump-drop-flags
./out/stage/bin/with-stage2 check repro.w --validate-all
./out/stage/bin/with-stage2 check repro.w --validate-ownership
with build :fixpoint-diff
```

### Integrated compiler analysis (`with analyze`)

Use this **before** standalone source scanners, debug prints, or a rebuild when a
problem crosses AST/Sema/MIR/ABI/codegen. It runs one compilation and joins facts
from the compiler's live `Sema`, `MirBody`, diagnostics, and real LLVM codegen
branches. It also audits its own marshalling coverage, so an uninstrumented
ordinary call path is a failure rather than a blind spot.

```sh
./out/stage/bin/with-stage2 analyze repro.w audit:all
./out/stage/bin/with-stage2 analyze repro.w audit:storage
./out/stage/bin/with-stage2 analyze repro.w summary
./out/stage/bin/with-stage2 analyze repro.w 'matrix:name~function_name'
./out/stage/bin/with-stage2 analyze repro.w 'select:stage=sema,kind=parameter,name~function_name'
./out/stage/bin/with-stage2 analyze repro.w 'explain:call:function_name'
./out/stage/bin/with-stage2 analyze repro.w move-sites
./out/stage/bin/with-stage2 analyze repro.w 'explain:effect:Type.method:self'
./out/stage/bin/with-stage2 analyze repro.w 'path:call:caller:callee'
./out/stage/bin/with-stage2 analyze repro.w 'closure:call:root_function'
./out/stage/bin/with-stage2 analyze repro.w 'lldb:kind=call,name~function_name'
```

Requests:

- `facts` / `snapshot`: stable TSV facts suitable for checked-in fixtures or a
  normal text diff. Facts cover all AST function declarations (including generic
  and uninstantiated methods), finalized signatures/effects/receiver modes,
  specializations, MIR bodies/locals/places/calls, diagnostic provenance, LLVM
  parameter shapes, caller marshalling, and callee binding. Source-bearing facts
  include compiler source-file identity, exact byte `start`/`end`, and resolved
  declaration owner. MIR call-argument facts join lowered operands back to Sema's
  canonical AST argument nodes, including the implicit method receiver offset.
- `select:<query>`, `summary[:<query>]`, `matrix:<query>`: query the same fact
  database. Queries are comma-separated `field=value`, `field!=value`, or
  `field~substring` predicates; run `with analyze file.w help` for fields.
- `audit:calls|effects|storage|methods|mir|returns|receivers|receiver-surface|phase|codegen|trait-tables|all`: hard invariants. `all`
  includes typed/ownership MIR validators, receiver declarations/contracts,
  fixed-point effects, freeze/eager-cache/specialization checks, frozen-phase
  mutable-Sema re-entry, LLVM declaration ABI, caller marshalling, callee aliasing,
  instrumentation coverage, AST-indexed storage bounds/key-capacity checks, and
  codegen trait-table/vtable agreement with canonical AST method records.
  `audit:storage` permanently checks the resolved-call table/key class that once
  overflowed when AST node IDs crossed 32767/65535.
- `path:call` / `closure:call`: operate on the live MIR call graph; use these in
  place of source-text call-graph reconstruction whenever the program compiles.
- `lldb:<query>`: emits breakpoints from actual matching facts and refuses to
  invent one when nothing matches.

The analysis command is also a reducer predicate:

```sh
./out/stage/bin/with-stage2 reduce repro.w --exit-code nonzero -- \
  ./out/stage/bin/with-stage2 analyze {file} audit:all
```

Do not start a full build to test an ABI/ownership hypothesis. First require the
focused repro's `audit:all` to pass and inspect its cross-layer `matrix`. A build
is the final verification that the already-proven invariant holds repository-wide.
There are no source-scanner semantic fallbacks. If analysis cannot reach the
needed phase, reduce the repro or attach LLDB to the compiler branch that stopped
it. Source rewrite tools may use the Lexer to apply byte edits, but selection and
contracts must come from `compiler_analyze_file` facts:

- `tools/annotate_receivers.w`: finalized Sema receiver requirements.
- `tools/migrate_receivers.w`: Sema declaration scope/mode plus lexical splices.
- `tools/relocate_methods.w`: Sema top-level method/owner/mode plus reindentation.
- `tools/migrate_method_arg_moves.w`: structured compiler diagnostics and spans.

The removed receiver/frozen/closure/diagnostic-map tools must not be recreated.
Use `select`, `matrix`, `path`, `closure`, `explain:node`, and the audits instead.

See `docs/deep-debugging-tools.md`.

`--dump-abi` prints, per function signature, each parameter's ownership/ABI
classification — effect flags, `value_ref_abi`, and the current physical
passing verdict. It is the direct answer to "is this declared borrow or owned
parameter lowered consistently at caller and callee?" — do NOT infer that from
MIR or reasoning; dump it. Any legacy `SHARE-PLACE` label in this diagnostic is
implementation terminology for `IndirectPlace`, not permission to reinterpret
a plain consuming `T` as a borrow.

For drop-exactly-once correctness across (value shape × control flow × ownership
op × receiver mode), run `with build :drop-audit` (tools/drop_audit.w —
candidate = the fresh release binary, baseline = the verified seed) before and
after ANY change to drop scheduling, ownership, or receiver lowering. One bad
cell means the whole region is untested — audit it, don't spot-fix. The auditor
classifies every cell against the baseline compiler so regressions self-identify
(a cell is red only when the verdicts DIFFER; known-shipped findings like #693's
enum cells and the #608 POD-leak pins read as `same`).

### LLDB (preferred)
```
lldb -- ./out/stage/bin/with-stage2 check src/main.w
(lldb) run
(lldb) bt all
```

### Native Debug Allocator
Use this before any edit/compile/trace loop for drop, lifetime,
double-free, use-after-free, and leak bugs:
```
./out/stage/bin/with-stage2 run --debug-alloc repro.w
./out/stage/bin/with-stage2 run --debug-alloc --debug-alloc-filter=non-root repro.w
./out/stage/bin/with-stage2 check repro.w --dump-drop-state
./out/stage/bin/with-stage2 check repro.w --dump-drop-plan
./out/stage/bin/with-stage2 check repro.w --trace-ownership main:_1
with build :debug-alloc-tests
./out/release/bin/with build tools/debug_drop.w -o out/debug-alloc-tests/debug_drop
out/debug-alloc-tests/debug_drop run ./out/release/bin/with repro.w
lldb --batch -s tools/debug_drop_sites.lldb \
  -o "run run repro.w" -o "quit" -- ./out/release/bin/with
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

---

## Bootstrap Rules

### Every PR must be bootstrappable
Each PR must be green and buildable from a tagged seed release that already
exists in the repo before it merges — if a change needs a newer seed, tag a
release to be that seed first.

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
