# AGENTS.md — With Compiler

Rules for AI agents in this repo. The With compiler is **self-hosting**:
small mistakes corrupt the stage chain, so strict discipline is required.

---

## Mission

(Summary; canonical: `docs/mission.md`.)

With is an ergonomics-first systems language: close to the machine, native by
default, exactly as safe as Rust, built to remove the suffering. Every
unnecessary character is a compiler failure — if With can infer, import, fetch,
bind, prove, generate, link, migrate, wrap, or make it safe, the programmer
shouldn't spell it out. C interop is first-class, not an escape hatch: raw C
stays explicit, modeled C becomes humane, and the programmer never has to become
the build system.

Named for the `with` scope: a resource lives in its scope and is released when
the scope ends. Memory is the first resource — owned from creation, released by
its owner's scope, proven the same way safety is. Stricter than Rust: Rust calls
leaking safe, With calls it a defect. Leaking must take deliberate, visible
effort.

---

## Core Principles

**We own every bug.** Nothing is "pre-existing." If a bug exists, we fix it —
never defer, never work around.

**Root cause, always.** Run a 5 Whys: trace the failure to its deepest credible
cause and fix that, not the symptom.

**Build is verification, not experimentation.** A build takes 5 minutes. Before
`with build`, state the question you're answering and what each outcome tells
you. If `grep`, `nm`, `otool`, `lldb`, or reading code can answer it, do that.

**Use the debugger.** The project has debug symbols. One `lldb` breakpoint
answers in seconds what print-and-rebuild takes minutes to.

**"Root cause" means the exact line** — the exact function, branch, and
condition producing the wrong state, observed in `lldb` or the debug allocator.
Output tables, run counts, raw `--dump-mir`/`--dump-drop-state` greps, and trace
prints are hypotheses, not proof; don't propose a fix or deferral from a
characterization alone. Deferring is valid only after locating the bug at the
instruction level and showing the fix needs foundation work you can point to.

**Self-check trip-wire.** If your last three actions were edit, compile, read
trace output, and you still can't name the exact wrong line, stop and switch
tools: a breakpoint, an allocator verdict, `with reduce`, `--trace-place`,
`--explain-mir-origin`, `--trace-ownership`, `--dump-drop-plan`,
`--trace-cleanup-edge`, `--validate-all`, `nm`/`otool`, or a smaller checked
repro.

**Deep compiler bugs.** If the repro isn't minimal, run `with reduce` with the
failing command as the predicate. For MIR lowering, ownership, and codegen bugs,
reach for the `with check` trace/dump flags (see Stage Debugging) before adding
trace prints. For fixpoint failures, run `with build :fixpoint-diff` first.

**Memory bugs.** Any drop/lifetime/double-free/use-after-free/leak bug starts
with the native debug allocator: `--debug-alloc` or `WITH_DEBUG_ALLOC=1` (see
`docs/debug-allocator.md`), then `tools/debug_drop.w`/`tools/debug_drop*.lldb` to
turn its verdict into alloc/free sites, the `--dump-drop-state`/`--trace-ownership`/`--dump-drop-plan`
dumps for MIR ownership state, then `lldb` on the branch that emitted the bad
drop. Allocator = which memory was mishandled; dumps = which places the compiler
thinks are live and scheduled for cleanup; debugger = why codegen emitted it.

---

## Language Design Philosophy

**Don't make the user write anything the compiler already knows, could figure
out, or that doesn't matter.** The single principle behind With's surface syntax;
apply it *pervasively*. It is why:

- a function returning `i32` doesn't need a trailing `0`
- you don't write `Ok(())` or `Ok(value)` — `?` handles the sad path, the happy
  path just returns the value
- return types are inferred when the body makes them obvious
- `fn main:` not `fn main -> i32:`
- enum variants use `.Variant` when the type is known

**Never force ceremony for something that doesn't matter.** The clearest
violation: requiring `let _ = expr` to discard a value whose discard has no
effect. A dropped `Result` does nothing, so a "must-use Result" diagnostic
forcing `let _ =` is **forbidden**. (Contrast: a dropped `Task` *cancels* it, so
an explicit choice there is acceptable — the discard matters.) Before adding any
rule, error, or required annotation, ask: *does this make the user state
something the compiler already knows, can infer, or that has no consequence?* If
yes, don't add it. A diagnostic earns its place only by catching a real mistake
the compiler can't otherwise resolve — not by enforcing ritual.

**Vale, not Rust, is the closest reference for the ownership model.** We take the
best of Vale (single ownership, consuming destructors / Higher RAII, generational
references, regions) and ditch the worst. "Exactly as safe as Rust" is a safety
*bar*, not a design compass — we are allergic to Rust's tiresome syntax. A Rust
idiom we must adopt is confined to the library-maintainer tier ("only library
maintainers will ever do this, never app developers"). When weighing
ownership/drop/lifetime semantics, check `.reference/Vale` first; reach for Rust
only when Vale can't meet the bar.

**The signature states parameter ownership mode — load-bearing.** For free
functions, `&T` borrows and plain `T` consumes. Auto-referencing removes
call-site ceremony: `peek(x)` when `peek` takes `&T`; `take(x)` when `take` takes
`T`. The signature is authoritative, so a body edit never silently changes
ownership, destructor timing, or the public calling convention. `move x`,
`copy x`, `&x` remain explicit spellings of intent, but a consuming signature
never requires a redundant call-site `move`. Don't infer a borrow merely because
a plain-`T` parameter is currently read-only — that makes the contract depend on
the body. A function that observes takes `&T`; one that retains a borrowed input
must make the lifetime valid; one that needs an independent retained value clones
explicitly. During migrations the compiler may diagnose a legacy read-only `T`
and offer an exact `&T` fix-it, but canonical mode never silently reinterprets
the declared type. See specification §3.8 and `docs/decisions.md` D5.

**Receiver modes are separate.** `fn`/`&self` reads, `mut fn`/`mut self` mutates
the receiver place in place, `move fn`/`move self` consumes it. Retiring
free-parameter SHARE-PLACE doesn't change `mut fn` receiver semantics or D21's
place-threading pipeline rule.

**D22 has one canonical, complete source: `docs/d22-Eric-Ruling.md`** — Eric's
ruling, not a draft or summary. Any document, comment, test, TODO, plan, or
behavior that conflicts with it is false and non-conforming. Don't edit,
reinterpret, narrow, or broaden it. The specification and decision log must
conform to it; `docs/d22-implementation-plan.md` is a derivative execution plan
and can't amend it.

**D22 map-view and contextual-Copy is still in progress.** `HashMap[K, V].get`
and `BTreeMap[K, V].get` uniformly return `Option[&V]`; `remove` is the
ownership-transfer op and returns `Option[V]`. Copy-ness never changes a lookup
signature. A `&T` stays a reference during inference and pattern projection,
including when `T: Copy`; it materializes an independent `T` only once an
owned-value demand is established. `Option`, `Result`, patterns, `?`, `??`, and
eliminators are transparent to view origins — they don't erase a borrow. Read the
ruling first; specification §§3.4, 3.8, 9.7, 10, 13.3, 21.1 and `docs/decisions.md`
D22 are conforming projections of it. The current compiler is deliberately
NON-COMPLIANT while D22 is implemented: don't restore conditional `get` returns,
teach new code that lookup owns/copies, or treat a lost origin through `unwrap`
as precedent. Follow `docs/d22-implementation-plan.md` and the full NON-COMPLIANT
acceptance matrix, not isolated TODOs, so every equivalent spelling shares one
semantic rule.

**D27 (decisions.md) extends the doctrine to positional collections: element
access observes; `remove` transfers.** `xs[i]` denotes the element place;
`xs.get(i)` returns `&T` (read-only, panics out-of-range — `Option` is for keyed
maps, where absence is normal); a binding names what's there, an annotation
demands what it says. The element-view campaign is done; see
`docs/d27-implementation-plan.md`. The interim #715 element gate and the
over-broad #730 unannotated-let field gate are retired. Serialize/Deserialize
signatures are correct as declared (`JsonView` is a Copy view token); don't "fix"
the threaded sink into a borrow.

**`FnAbi` is the single ABI source of truth — never re-derive call ABI
per-path.** Every function signature has ONE ABI descriptor (`FnAbi` with a
per-parameter `PassMode`: `Direct`/`Indirect`/`IndirectPlace`/`Fat`/`Ignore`),
computed ONCE by `compute_fn_abi(sig)` and read by BOTH the callee prologue
(`declare_function`) and every call site (`push_call_arg`) — this makes
caller/callee/path divergence impossible (Rust, Go, Zig, and Clang/LLVM all do
the same). When adding a call-lowering path, receiver shape, or parameter kind,
extend `compute_fn_abi`/`PassMode` in ONE place and read it — **never** write a
fresh per-path "value vs address vs byval" decision. A per-path derivation is the
exact bug that produced the transparent `T*`/`T**` divergence; reintroducing one
is a regression. `PassMode::IndirectPlace` is a physical mode for compiler-modeled
borrowed places such as in-place receivers; an explicit `&T` is a reference value
with the ABI of that reference type; a plain consuming `T` is owned even when its
physical ABI is indirect. See `docs/decisions.md` D6 and
`docs/fn_abi_descriptor_design.md`.

---

## No Silent Fallbacks

When code can't be correctly generated, the only acceptable behavior is to fail
loudly with a diagnostic and exit non-zero. These are **forbidden** regardless
of what tests or downstream compilation say:

- Emitting a placeholder body (`-> Never`, `comptime_error(...)`,
  `panic("TODO")`, `return 0`, etc.) when translation fails
- Emitting an `extern fn` declaration to paper over a function the translator
  couldn't handle
- Silently dropping a clause, arm, or statement the translator can't lower
- "Simplifying" a construct into something that compiles but behaves
  differently from the source
- Adding a `TODO` comment to emitted output and continuing

**A migrator that produces 30/30 files with silent stubs is worse than one that
produces 0/30 with a loud error** — the first lies about completeness. Instead:
emit a diagnostic naming the function and source location, return non-zero, and
leave the work visible for a human. If you can't produce correct output and can't
fail loudly (deep in a helper with no error-return plumbing), wire the plumbing.
Never invent a placeholder.

---

## "Done" Is a Claim That Requires Evidence

Not done because tests pass, the build succeeds, no errors remain, the commit
was accepted, or output files exist. Done when:

- The output is correct — it does what a human familiar with the source would
  expect, not just what happens to compile
- The edge cases you noticed have tests or comments explaining why they're
  uncovered
- Anything you couldn't solve is filed as an issue or surfaced as a loud
  failure, not hidden as a passing stub

Gut check: *did I make the success condition true by doing the work, or by
redefining the success condition?* If it isn't obviously the first, it's the
second. This applies especially to translation, migration, and codegen tasks
with large output where correctness is hard to eyeball — there, "the build is
green" says almost nothing about whether the tool works.

---

## Verify by Running, Not by Reasoning

The compiler's subtle, half-implemented corners — mutable aliasing, slice
mutability, coercions, which types are even spellable — are exactly where
reasoning from layout, signatures, or spec text goes wrong. Three rules:

**Spell it and run it.** Before concluding a type, mechanism, or API "works" or
"is the surface," write the smallest program that uses it and compile it. A type
usable-looking from its layout may be unspellable as a parameter (`VecRange`); a
`mut` parameter may *move* rather than borrow; `&raw place` may need an explicit
`const`/`mut` qualifier. You find these only by compiling.

**Exhaust small answer-spaces in one pass.** When a question has a small,
enumerable set of answers ("how many ways can a mutable buffer cross a call?"),
test all at once and write the matrix — a verdict from partial evidence flips
every time the next case is tested; from the whole matrix it's stable. If you
catch yourself concluding-and-patching the same question twice, stop and
enumerate.

**Code settles facts; intent is the maintainer's call.** The spec says what
*should* be true; running the code shows what *is*. When a spec promise and an
implementation fact disagree (a documented coercion with no producer; a "returns
X" the impl returns as Y), settle the facts by running, then surface the
contradiction rather than assuming which side is canonical. Test the inconvenient
premise first — the fact that fights your conclusion is the one most worth
running.

**And otherwise, keep moving.** These rules verify, they don't *pause*. Stop
only for a decision genuinely the maintainer's — intent, scope, or a go/no-go on
real risk you can't resolve yourself. When the path is clear and self-scoped,
proceed and report as you go; don't ask permission to continue. Restraint that
catches a real fork is discipline; restraint on a clear path is under-autonomy
wearing discipline's clothes.

---

## Anti-Patterns

How a task looks successful while actually being broken. Each is easy to fall
into under pressure to complete.

**Weakening the check.** If a check fails, make the code pass it, or confirm
with a human that the check is wrong. Never downgrade it to a warning, add an
exemption, or route around it.

**"Pre-existing" without evidence.** A failure is pre-existing only if you've
verified it on the previous commit. Otherwise it's your failure, renamed. Never
use `git stash` to answer this; use `git worktree` or a separate clone.

**Silent fallbacks in generated output.** See "No Silent Fallbacks."

**"Good enough for now."** The migrator's biggest trap. A 90%-working translator
that silently mishandles the other 10% is not 90% done; it's 0% done with a
confusing reporting problem. The bar is correctness, not coverage.

---

## Runtime Architecture

**TRANSITIONAL — D30 (docs/decisions.md) retires this object-boundary design.**
Destination: the runtime compiles in-unit like the embedded stdlib; rt objects
survive only as a (compiler-version, target)-keyed cache whose hits are
byte-identical to the in-unit result. A runtime object built by a different
compiler generation must never be linked — that mixed-world link is #761's
corruption class. The layout below is the current tree until retirement lands.

```
rt_core.o    (With)  = core runtime. All runtime functions live here.
```

Two link paths:
- **cc (Apple ld64):** user programs
- **lld (LLVM ld64):** compiler build

Linking rules:
- Pure With programs (no c_import): `rt_core.o` only
- User programs with c_import: `rt_core.o` first, then `cimport_stubs.o` as
  archive (linker pulls only missing symbols)

When compiler-owned runtime behavior is needed, implement it as ordinary With
code behind normal module/private-function boundaries.

### `@[c_export]` is foreign ABI only

`@[c_export]` means: **this With function is intentionally exported as a C ABI
surface for non-With callers** (C, Rust, Zig, Python FFI, etc.). It is not a
With-to-With linkage tool.

- With-to-With libraries use With modules and `pub` APIs, not `@[c_export]`.
- The compiler and compiler-owned runtime use normal modules/private functions,
  not `@[c_export]`.
- With libraries use `@[c_export]` only to expose a foreign-language ABI surface.

Any `@[c_export]` on a With declaration compiled into the compiler executable is
a bug. During #335, remove existing occurrences; after #335, any
compiler-codebase occurrence is a regression, not precedent. Do not copy or
rename them into another internal export mechanism.

### `with_*` is compiler-internal — user programs never call it

**DEPRECATED TIER — D30 (2026-08-09) retires the internal runtime ABI.** The
`with_*` seam is a C-bootstrap fossil; it retires the same way (§Runtime
Architecture: in-unit compilation, ordinary module functions, rt objects only as
a version/target cache). Until retirement lands (sequenced after the 747-flip
merge/reseed), the guidance below stays operative; do not build NEW machinery on
this seam, and see §16.3e for the boundary-type rule governing the surfaces that
remain after it.

Two surfaces, never conflated:

- **User programs** use exactly two things: the **language syntax** (wired into
  the stdlib) and the **`std.*` stdlib APIs** (e.g. `std.regex`, in `lib/std/`).
  That is the entire user-facing surface.
- **`with_*` symbols and everything in `rt/*.w` are the compiler's own internal
  runtime/ABI.** User *source* never names a `with_*` symbol — the compiler emits
  those calls. `rt/regex_runtime.w` (`with_regex_*`) is the **compiler's** regex,
  compiled as part of the compiler, not a foreign object to embed and hand out.

Never reason as if a user program must *link* or *resolve* the internal runtime.
If you catch yourself asking "how does a user program get the `with_regex_*`
symbols?", **stop** — the question is malformed. Users reach regex through
`std.regex`. `rt/*.w` is part of the compiler; treat it that way.

---

## Self-Contained Toolchain (we build our own LLVM)

**Not a single line of non-With code in this repo. We are 1000% self-hosted.**
Inline/platform assembly (`.s`) is the only exception. No C, no C++, no glue
files — external native libraries (libclang, LLVM) are reached through
`extern fn` declarations in With, never a shim in another language. If a
capability seems to need a C/C++ source file, the answer is a With-side
implementation over the C API (or asm), or the capability waits.

**This includes ALL tooling — even temporary, one-off, throwaway scripts.**
Migrators, source rewriters, log/output scanners, ad-hoc analysis: write them in
With, never Python, bash, perl, or awk. A Python/bash scratch script here is the
same violation as C in the compiler. With IS a scripting language; there is no
"just a quick script" exception.

- **One-liners** (perl/python `-e` style):
  - `with -e 'print_i32(6 * 7)'` — eval a snippet (implicit main)
  - `... | with -n 'if line.starts_with("a"): print(line)'` — run per stdin
    line with `line` bound (grep-like)
  - `... | with -p 'line = line ++ "!"'` — per-line transform, auto-printed
    (sed-like)
- **Never `sed`/`awk`/`cut`/`perl` for text transforms — use a `with` one-liner.**
  A transform genuinely impossible as a one-liner is a BUG to file, not a reason
  to reach for sed.
  - `sed 's/old/new/g'` →  `... | with -p 'line = line.replace("old", "new")'`
  - `sed -E 's/(a)(b)/\2\1/'` → `... | with -p 'line = /(a)(b)/.replace(line, "$2$1")'`
    (a regex literal's `.replace` takes `$N` backreferences; no script needed)
  - `sed -n 'A,Bp' file` → `with -n 'if nr >= A and nr <= B: print(line)' < file`
    (`nr` is the 1-based line number, §18.5b; never `sed -n` to read a range)
  - `sed '/pat/d'`      →  `... | with -n 'if not line.contains("pat"): print(line)'`
  - `grep pat`          →  `... | with -n 'if line.contains("pat"): print(line)'`
    (also `.starts_with`/`.ends_with`; `grep -i` is `line =~ /pat/i`)
  - `cut -f2`           →  `... | with -n 'print(line.split("\t").get(1))'`
  - `awk '{print $2}'`  →  `... | with -n 'print(line.split(" ").get(1))'` — exact
    separator only until `str.fields()` lands (#959)
  - `wc -l`, `tail`, sums → `with -e` with a loop over `stdin.lines()` (the
    whole input, so END-style work is a print after the loop); `-n` gains
    persistent state and `last` with #957
  - `jq -r .a.b`        →  `with -e 'use std.json` ⏎ `print(JsonDocument.parse(read_all()).root().field("a").field("b").raw())'`
  - `sed -i`, `awk … file` → not yet (#958): `< file` and `with run` until then
  - The full sed/awk/jq parity matrix and every open gap: `docs/improve_oneliners.md`.
- **Implicit main** — a `.w` file needs no `fn main`; top-level statements ARE
  the program, and may sit alongside helper `fn` definitions:
  ```
  use std.process
  fn shout(s: str): s ++ "!"        // return type inferred
  let argv = args()                      // std.process
  for i in 1..argv.len() as i32: print(shout(argv.get(i as i64)))
  ```
- **Run without a build step**: `with run tool.w a b` compiles-and-runs and
  forwards `a b` as argv. Reuse the compiler's own modules (`use Lexer`,
  `use Token`) for token-accurate source tooling — regex/text hacks are not
  acceptable for self-host-critical rewrites. See `tools/migrate_receivers.w`.
- File I/O via `use std.fs` (`read_file(path)`, `write_file(path, data)`,
  `list_files(path)`). Never declare the `with_fs_*` externs in a tool or
  user program: that D30-deprecated internal seam SEGFAULTS in user
  programs (#901) and dies with the D30 retirement (#761). Caveat until
  #909 lands: `read_file` returns `""` for a missing/unreadable path —
  check existence when the distinction matters.

**After bootstrap the seed depends on nothing external from LLVM.** A hard
invariant.

*We* build the static LLVM/Clang/lld SDK from source via
`tools/build-static-llvm.sh` into `.deps/llvm-<ver>-<host>` (`LLVM_PREFIX`). That
build produces the archives (`libclang.a`, `libLLVM*.a`, `liblld*.a`) **and**
clang's builtin headers (`lib/clang/<v>/include/`: `stddef.h`, `stdarg.h`, …)
that `c_import` needs to parse C headers. The release binary **embeds** these —
as it already embeds the stdlib and runtime objects — and links libclang
statically; the final binary loads no LLVM/Clang dylib. `LLVM_PREFIX` /
`WITH_LIBCLANG` are **build-time link inputs only**, never runtime deps.

**Never trust a system-installed LLVM** — we didn't build it, and it won't have
the static `.a` we need. Do not resolve any LLVM/Clang resource (archive *or*
header) from an external path at runtime. If `c_import` reports `'stddef.h' file
not found`, the resource is missing *from the binary* — fix the embedding.
**Never** point `WITH_CLANG_RESOURCE_DIR` / `LLVM_PREFIX` / `llvm-config` at a
system or `.deps` LLVM to make it pass; that re-introduces the forbidden
dependency, and a clean release host won't have it. (Clang's builtin headers are
embedded and materialized to a cache at first `c_import` (#312);
`get_clang_resource_dir()` no longer probes external LLVM, and
`WITH_CLANG_RESOURCE_DIR` is an override-only escape hatch.)

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

Fixpoint invariant: `stage2 == stage3`. If fixpoint fails, code generation is
nondeterministic. Stop and fix.

**If the build breaks, fixing the build is the top priority.**

### Optimization level: ALWAYS `-O1`, NEVER `-O0`

The compiler is built at **`-O1`** everywhere — all stages (1, 2, 3), the
fixpoint stages, every runtime/bootstrap object, and the release binary. There
is **no `-O0` anywhere** in `build.w` / `build/*.w`; the build files encode this
as an **invariant, not a preference**. (The first build after a fresh seed is
slow because the `-O0` seed builds the `-O1` stage1; once `-O1` is the seed,
builds are fast.)

- **`-O0` is pathologically slow** (a 26k-line module's object build: 31+ min at
  `-O0`, seconds at `-O1`). The build/test timeouts assume `-O1`.
- **`-O1` is fully deterministic** (fixed pass pipeline, no RNG, no
  address-dependent choices). If fixpoint breaks under `-O1`, that is a **real
  nondeterminism bug in our codegen** — find it with `with build :fixpoint-diff`
  and fix it. A bug that only appears at `-O1` is also real (latent UB the
  optimizer exposed, or a miscompile); "it works at `-O0`" means "we have a
  UB/codegen bug we are hiding."
- **Dropping to `-O0` to make a red build/test/fixpoint go green is the single
  most forbidden shortcut here** — it hides the bug. The *only* allowed `-O0` use
  is a deliberate, explicitly-approved, temporary local diagnostic, reverted
  before any commit. **Never commit an `-O0` build setting**; `-O0` anywhere in
  `build.w` / `build/*.w` is a regression — restore `-O1`.

---

## Seed Compiler

Resolution order: `WITH=<path>` → `with` on PATH → `src/main`

`src/main` is not checked into git. It is the local seed path fetched from the
`with-darwin-aarch64` GitHub release asset. Run `with build :seed` to fetch it.
After `with build`, `with build :fixpoint`, and `with build :test` pass, run
`with build :test-green` and `with build :last-green`, then update `src/main`
with `with build :update-seed` and the installed compiler with
`with build :install-user`. `:test-green` records evidence from a completed test
run; it is not a substitute for running `:test`.

If the seed, installed compiler, and release binaries are all broken, the
compiler cannot be recovered.

---

## Releases

For release tasks, follow `docs/with-release-runbook.md` — the canonical runbook.

Release work is packaging and verification by default. Do not make compiler,
runtime, stdlib, migrator, build-system, or test changes during a release unless
the maintainer explicitly approves expanding scope. If release prep exposes an
unrelated bug, file an issue with the repro and stop there unless the maintainer
says it blocks the release.

Publish the Darwin arm64 binary as `with-darwin-aarch64`. Do not publish a
release binary asset named `main`; `src/main` is only the local seed path.

---

## The Specification Leads

`docs/with-specification.md` is the bible. For D22, `docs/d22-Eric-Ruling.md` is
the complete controlling ruling: if the spec, requirements, decision summary,
plan, tests, comments, or code omit or conflict with it, those sources are
non-conforming and must be repaired to match it. Two rules are otherwise
absolute:

**The spec leads the implementation.** A spec change is a ruling that the product
is now NON-COMPLIANT until the implementation catches up. No "implement first,
spec after," no "hold the spec text until the code lands," no reverting spec text
to match what the code does. Compliance chases the spec, never the reverse. When
spec and implementation disagree, the implementation is wrong — or the
disagreement is surfaced to Eric for a ruling; it is never resolved by quietly
editing the spec.

**Spec changes are solemn.** Only Eric authors or blesses normative spec text —
the exact words, not just the direction (D16's precedent: "the uniform spec
sentence landing as the ruling itself"). An agent may draft and propose language,
but a general directive, mission statement, or agreed design direction is NOT
approval of specific spec wording. Nothing lands without Eric's explicit blessing
of the words themselves.

### "Do the thing" — the decision procedure

Every spec change, and most decisions surfaced to Eric, go through this. Present
all four parts in one brief, then wait for the ruling:

1. **What the others do.** Compare the reference projects (`.reference/`: go,
   mojo, rust, swift, Vale, zig — plus any that fit), verified in their trees not
   from memory. Name each mechanism and where it diverges.
2. **What the spec currently says.** Quote the exact text. Check whether the spec
   already rules the question (it often does — the implementation may just be
   non-compliant), and whether the proposal duplicates an existing rule (one
   rule, one normative home).
3. **Mission fit.** Relate the choice to `docs/mission.md` and `docs/decisions.md`.
   Say which option is most with-y, not just which is safest.
4. **Predict what Eric would say.** A committed BDFL prediction with confidence,
   derived from his decision record — not a menu of options with no stake. It's
   falsifiable; being wrong and told why improves the record.

Then Eric rules. For spec changes, the blessed wording lands immediately as the
ruling itself, and the implementation is non-compliant until it conforms.

---

## Filing Bugs

If the spec (`docs/with-specification.md`) says something should work and the
compiler disagrees, that is a **compiler bug**. Do not silently work around it.
File an issue with:

- Spec reference (e.g., "§9.7 Pattern Matching")
- Minimal reproduction
- Expected vs actual behavior
- Workaround used (so the fix can remove it)

---

## Decision Log

`docs/decisions.md` records non-obvious design/architecture decisions and **why**
(context, alternatives, reasoning, what would reopen the call). When you make or
reverse a judgment call a future maintainer might re-litigate — an
ownership/safety ruling, a deviation from the reference implementations, a spec
amendment reversing an earlier one — append an entry (newest first) and
cross-link superseded ones. Consult it before reopening a settled question. Keep
it terse; it is reasoning, not a changelog.

---

## Editing Protocol

### Before editing

Read relevant source files. Confirm AST layouts. Verify naming conventions. When
you can't find something, grep `examples/`, `src/`, and
`docs/with-specification.md` before assuming it doesn't exist. Never rely on
memory.

### Code style — write the least ceremony

Match the surrounding code, and follow the mission at the character level:

- **Don't spell types the compiler can infer.** Omit a return type when the body
  makes it obvious (`fn shout(s: str): s ++ "!"`, not `-> str`); omit a local's
  type when the initializer gives it. Annotate only where inference needs it
  (e.g. `var xs: Vec[i32] = Vec.new()`).
- **Inline the colon when the body is very small.** `fn millis(ms: i32): ms` and
  `fn get(): self.n` on one line — do NOT break a one-token/one-expression body
  onto its own indented line. Use a block body only when the body is actually
  multi-statement or long.
- **Boy-scout the style: any time you touch a function, fix its style too** —
  drop inferable types, inline tiny bodies. Leave the whole function
  least-ceremony, not just the lines you came to change.
- **Unnecessary casts and `unsafe` are defects: fix them on sight, anywhere —
  even in code you are not otherwise editing.** The defaults already cover
  them: `v[i]`, `v[i] = x`, and `v.get(i)` take an `i32` index; `i32` widens
  into `i64` arithmetic and comparisons; `for k in 0..n` indexes directly. So
  `.get(i as i64)`, `.set_i32(i as i64, x)`, `v[i as i64]`, and `x as i64`
  where the target already widens are never written — only a narrowing needs
  `as`. `unsafe` is for a raw pointer that must exist (FFI, the allocator, an
  ABI seam), never a stand-in for mutation the language expresses safely: a
  `*mut State` handle mutated through by-value calls is an owned struct with
  `mut fn` methods in disguise; convert it. (Spec §15.1: `&mut T` is not safe
  With; `mut self`, an owned-by-value parameter, or a returned value is.) A
  file full of the legacy idiom is not a style to match; it is a backlog to
  burn down as you pass through, and a mechanical class of it is a `with -p`
  or Lexer-based rewrite, not N hand edits.

### One logical change at a time

Don't batch unrelated changes. Small changes make debugging possible.

### Commit authorship

Every commit is authored by the human contributor who drove the work, under
their own name and email — never anyone else's identity. For Eric that is Eric
Hartford <eric@quixi.ai>. Agent-driven work is committed under the identity of
the human who ran the agent. Never add an AI assistant, model, tool, or vendor
as a commit author, co-author, trailer, or credit line. Do not use
`Co-Authored-By` for AI assistance.

### Rebuild and verify (tiered — see decisions.md D14, D19)

**Iterate tier — the only per-change requirement.** `with check src/main.w`
and/or `with build :dev` (seed → stage1, one self-compile), plus the targeted
tests for what you touched. Never run the full battery per edit.

**Batch tier — the default.** Accumulate related commits; ONE battery blesses
the whole batch:
```
with build              # must pass
with build :fixpoint    # must pass
```
plus `audit:all`, `:test`, `:test-green`, `:last-green` (`audit:all` and `:test`
may run concurrently — they share no outputs), then reseed once. Batteries are
expensive; batching them is the discipline, not a shortcut.

**Isolation rule — blast radius, not ritual.** A change to ownership/drop
scheduling, codegen determinism, or ABI must be ALONE in its batch (and adds
`:move-audit`/`:drop-audit`), so a red battery indicts one change. Docs,
build-layer, and tooling changes batch freely and skip the drop audits.

If a batch's battery fails: bisect within the batch using iterate-tier evidence.
Do not add changes to a red batch.

### Re-read before editing

After 10+ messages in a conversation, re-read any file before editing it. Context
compaction may have silently destroyed your knowledge of file contents. Edit
fails silently when `old_string` doesn't match due to stale context.

---

## Stage Debugging

### Quick repro
```
time ./out/stage/bin/with-stage2 check src/main.w
```

### Deep compiler tools
Use these before edit/compile/trace loops on MIR, ownership, codegen, or fixpoint
bugs:
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
branches, and audits its own marshalling coverage — so an uninstrumented ordinary
call path is a failure, not a blind spot.

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

- `facts` / `snapshot`: stable TSV facts for checked-in fixtures or a text diff.
  Cover all AST function declarations (incl. generic/uninstantiated methods),
  finalized signatures/effects/receiver modes, specializations, MIR
  bodies/locals/places/calls, diagnostic provenance, LLVM parameter shapes,
  caller marshalling, callee binding, and source-file identity with exact byte
  `start`/`end` and resolved owner. MIR call-argument facts join lowered operands
  back to Sema's canonical AST argument nodes (incl. the implicit receiver
  offset).
- `select:<query>`, `summary[:<query>]`, `matrix:<query>`: query the same fact
  database. Queries are comma-separated `field=value`, `field!=value`, or
  `field~substring` predicates; run `with analyze file.w help` for fields.
- `audit:calls|effects|storage|methods|mir|returns|receivers|receiver-surface|phase|codegen|trait-tables|all`:
  hard invariants. `all` covers typed/ownership MIR validators, receiver
  declarations/contracts, fixed-point effects, freeze/eager-cache/specialization,
  frozen-phase mutable-Sema re-entry, LLVM declaration ABI, caller marshalling,
  callee aliasing, instrumentation coverage, AST-indexed storage bounds/key-capacity,
  and codegen trait-table/vtable agreement with canonical AST method records.
  `audit:storage` permanently checks the resolved-call table/key class that once
  overflowed when AST node IDs crossed 32767/65535.
- `path:call` / `closure:call`: operate on the live MIR call graph; use instead
  of source-text call-graph reconstruction whenever the program compiles.
- `lldb:<query>`: emits breakpoints from actual matching facts and refuses to
  invent one when nothing matches.

Also a reducer predicate:

```sh
./out/stage/bin/with-stage2 reduce repro.w --exit-code nonzero -- \
  ./out/stage/bin/with-stage2 analyze {file} audit:all
```

Do not start a full build to test an ABI/ownership hypothesis. First require the
focused repro's `audit:all` to pass and inspect its cross-layer `matrix`; a build
is the final verification that the proven invariant holds repo-wide. There are no
source-scanner semantic fallbacks — if analysis can't reach the needed phase,
reduce the repro or attach LLDB to the compiler branch that stopped it. Source
rewrite tools may use the Lexer to apply byte edits, but selection and contracts
must come from `compiler_analyze_file` facts:

- `tools/annotate_receivers.w`: finalized Sema receiver requirements.
- `tools/migrate_receivers.w`: Sema declaration scope/mode plus lexical splices.
- `tools/relocate_methods.w`: Sema top-level method/owner/mode plus reindentation.
- `tools/migrate_method_arg_moves.w`: structured compiler diagnostics and spans.

The removed receiver/frozen/closure/diagnostic-map tools must not be recreated;
use `select`, `matrix`, `path`, `closure`, `explain:node`, and the audits
instead. See `docs/deep-debugging-tools.md`.

`--dump-abi` prints, per function signature, each parameter's ownership/ABI
classification — effect flags, `value_ref_abi`, and the current physical passing
verdict. It directly answers "is this declared borrow or owned parameter lowered
consistently at caller and callee?" — do NOT infer that from MIR or reasoning;
dump it. Any legacy `SHARE-PLACE` label here is implementation terminology for
`IndirectPlace`, not permission to reinterpret a plain consuming `T` as a borrow.

For drop-exactly-once correctness across (value shape × control flow × ownership
op × receiver mode), run `with build :drop-audit` (tools/drop_audit.w —
candidate = the fresh release binary, baseline = the verified seed) before and
after ANY change to drop scheduling, ownership, or receiver lowering. One bad
cell means the whole region is untested — audit it, don't spot-fix. The auditor
classifies every cell against the baseline so regressions self-identify (a cell
is red only when the verdicts DIFFER; known-shipped findings like #693's enum
cells and the #608 POD-leak pins read as `same`).

### LLDB (preferred)
```
lldb -- ./out/stage/bin/with-stage2 check src/main.w
(lldb) run
(lldb) bt all
```

### Native Debug Allocator
Use before any edit/compile/trace loop for drop, lifetime, double-free,
use-after-free, and leak bugs:
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

If stacks are nonsense, suspect seed corruption. Replace the seed with a
known-good binary.

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

There is **no `NK_VAR_DECL`**. Mutable variables use the mut flag on
`NK_LET_DECL`.

---

## Common Mistakes

- **Misreading AST layouts.** Always confirm field meanings.
- **Guessing APIs.** Read the source.
- **Working around compiler bugs.** Fix the root cause.
- **Writing C when With works.** The runtime is being migrated to With.
  Compiler-owned With code uses modules/private functions, not `@[c_export]`,
  for internal boundaries.
- **Guessing linker flags.** Know which link path you're on (cc vs lld) before
  changing anything.
- **Using `with build` as a debugging tool.** It takes 5 minutes. Use `grep`,
  `nm`, `lldb`, or `with check` for diagnosis.
- **Iterating unordered maps** or using pointer-address ordering. These break
  fixpoint determinism.
- **Never use `git stash`.** It has destroyed uncommitted work multiple times.
  To test against a clean state, use `git worktree` or a separate clone.
  `git stash`, `git stash pop`, and `git stash drop` are all forbidden.

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

### Changes land via pull request
All changes reach `main` through a reviewed PR — no direct pushes. Branch
protection enforces this (one approving review; admins exempt for release and
seed operations). Batch related commits into one PR the way the battery
discipline batches them.

### Every PR must be bootstrappable
Each PR must be green and buildable from a tagged seed release that already
exists in the repo before it merges — if a change needs a newer seed, tag a
release to be that seed first.

### The seed compiler is frozen
The installed compiler at ~/.local/bin/with has its own Link.w, embedded runtime
objects, and codegen baked into the binary. You cannot change its behavior by
editing source files; it keeps its baked-in behavior until you install a new
seed.

### Never run `with build :install` with uncommitted changes
`with build :install` updates the seed, and a broken seed breaks all future
builds. Only install after `with build :fixpoint` passes on committed code.

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
