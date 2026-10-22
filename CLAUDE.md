# AGENTS.md — With Compiler

Rules for AI agents in this repo. The With compiler is **self-hosting**:
small mistakes corrupt the stage chain, so strict discipline is required.

---

## Mission

(Summary; canonical: `docs/mission.md`.)

With is an ergonomics-first systems language: close to the machine, native by
default, exactly as safe as Rust, built to remove the suffering. Every
character the program has already determined is a compiler failure if the
programmer still writes it — when one meaning is forced, With infers, imports,
fetches, binds, proves, generates, links, migrates, wraps, or makes it safe;
when two remain, the programmer spells the choice, and that spelling is a
guardrail. Defaults pick representations, never meanings. C interop is
first-class: raw C stays explicit, modeled C becomes humane, and the programmer
never has to become the build system.

Named for the `with` scope: a resource lives in its scope and is released when
the scope ends. Memory is the first resource, proven the same way safety is.
Stricter than Rust: leaking is a defect and must take deliberate, visible
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

**Use the debugger.** One `lldb` breakpoint answers in seconds what
print-and-rebuild takes minutes to. The installed `with` has full debug info:
`~/.local/bin/with.dSYM` beside it (`:install-user` installs stage2's dSYM,
the release's; released assets stay stripped). Any question about what the
installed compiler does — a wrong diagnostic, an ICE, a hang, a bad value in
Sema or MIR — starts with `lldb` on `~/.local/bin/with`, before a trace print
or a rebuild (recipes: Stage Debugging > LLDB). For source you changed, debug
`out/bootstrap/bin/with-stage1` (after `with build :dev`; it has a `.dSYM`
too). A program any compiler builds carries debug info for its own code and
the runtime.

**"Root cause" means the exact line** — the exact function, branch, and
condition producing the wrong state, observed in `lldb` or the debug allocator.
Output tables, run counts, raw `--dump-mir`/`--dump-drop-state` greps, and trace
prints are hypotheses, not proof; never propose a fix or deferral from a
characterization alone. Deferring is valid only after locating the bug at the
instruction level and showing the fix needs foundation work you can point to.

**Every bug has a route, and you state it.** `docs/spec/toolchain/deep-debugging-tools.md`
orders the tools by bug class; every recipe in it was run as written
(2026-10-05). Open it at the start of a hunt and follow the route's recipes as
printed; improvising flags is how a hunt stalls (an unknown flag is refused,
#2198). Before the first edit, name the route and run its first steps:
- drop, free, leak, use-after-free: the debug allocator, `WITH_ALLOC_NO_REUSE`,
  the address trap (`WITH_DEBUG_ALLOC_TRAP_FREE`, under lldb: outside it the
  address changes every run), and the runner's own binary — never `grep` or a
  trace print;
- a wrong variant (wrong arm, `unwrap` of a `Some` panics, `?` takes the error):
  `WITH_DEBUG_PERMUTE_TAGS=1 with-stage1 test test/behavior` and
  `WITH_TRACE_VARIANT_FALLBACK=1`; corpora run under
  `out/bootstrap/bin/with-stage1 test <dirs>`;
- a wrong view origin: `with analyze repro.w 'explain:origin:<fn>[:<binding>]'`
  (works on a failing program), then `WITH_DEBUG_BORROWS=1`;
- a generic-instance `BUG:`: `WITH_TRACE_INST=1`;
- codegen reading a value as the wrong type (wrong formatter, comparison, ABI):
  `with analyze repro.w audit:resolution`, whose operand-type check names the
  expression whose MIR type Sema did not give it.
A fix commit cites the tool output that proves the exact line: the allocator
report and backtrace, the `matrix` row, the validator error, the IR of the
block.

**A tool that stayed silent is a bug.** If a validator said ok, a dump said
skip, an audit passed, or a reducer converged on noise while the bug existed,
the tool is wrong and is fixed or filed in the same batch as the bug
(`validate-all: ok` over a garbage drop is the model: the drop-state driver
joined only lower-numbered predecessors).

**Three-action trip-wire.** If your last three actions were edit, compile,
read output and you cannot name the exact wrong line, stop and switch to the
route's next tool: a breakpoint, an allocator verdict, `with reduce`,
`--trace-place`, `--explain-mir-origin`, `--trace-ownership`,
`--dump-drop-plan`, `--trace-cleanup-edge`, `--validate-all`, `nm`/`otool`,
or a smaller checked repro. Do not start a fourth.

**Tools are products.** When a hunt needs a capability that does not exist
(`--keep-binary`, a first-free site in the ledger, a test-mode reducer), file
it during the hunt and prefer building it over a workaround when the workaround
is a race or a manual lldb session. Before building, grep the runtime and the
doc for the flag that already exists — the address trap sat unmentioned in
`rt_core.w` for a month.

**One owner per fact (D65).** Sema decides *what* (declaration, type,
place/value/view category, origin, effect, capture semantics, call target,
acceptance); MIR decides *where and when* (CFG, storage, path-sensitive move
state, drop points, cleanup edges); codegen decides *how* (layout, `PassMode`,
LLVM representation). A downstream stage may propagate, materialize and verify
a fact; it never reconstructs or overrides it from syntax or representation: no
LLVM-type → passing-mode inference, no MIR-local-lookup → name-meaning
inference, no AST-spelling → callee inference after Sema. MIR that finds Sema's
constraints unrealizable reports the contradiction; it never picks a different
meaning. Post-Sema invalid MIR is a compiler bug: its ICE names the body, and
`--dump-mir` / `--explain-mir-origin` read the refused statement. When you fix
a bug, move its answer to the owner — never add a second derivation. `with
analyze … audit:resolution` (#1647) is the mechanical check; the smell test: if
deleting a downstream heuristic could change which programs are accepted, the
boundary is wrong.

**Deep compiler bugs.** If the repro isn't minimal, run `with reduce` with the
failing command as the predicate. For MIR lowering, ownership and codegen bugs,
reach for the `with check` trace/dump flags (Stage Debugging) before trace
prints. For fixpoint failures, run `with build :fixpoint-diff` first.

**Memory bugs.** Any drop/lifetime/double-free/use-after-free/leak bug starts
with the native debug allocator: `--debug-alloc` or `WITH_DEBUG_ALLOC=1`
(`docs/spec/toolchain/debug-allocator.md`), then `tools/debug_drop.w` /
`tools/debug_drop*.lldb` to turn its verdict into alloc/free sites, the
`--dump-drop-state`/`--trace-ownership`/`--dump-drop-plan` dumps for MIR
ownership state, then `lldb` on the branch that emitted the bad drop. Allocator
= which memory was mishandled; dumps = which places the compiler thinks are
live and scheduled; debugger = why codegen emitted it.

---

## Language Design Philosophy

**Don't make the user write anything the compiler already knows, could figure
out, or that doesn't matter.** The single principle behind With's surface
syntax; apply it pervasively. It is why a function returning `i32` needs no
trailing `0`; you never write `Ok(())` or `Ok(value)` — `?` handles the sad
path; return types are inferred when the body makes them obvious; `fn main:`
not `fn main -> i32:`; enum variants are `.Variant` when the type is known.

**Never force ceremony for something that doesn't matter.** Requiring
`let _ = expr` to discard a value whose discard has no effect is the clearest
violation: a dropped `Result` does nothing, so a "must-use Result" diagnostic is
**forbidden**. (A dropped `Task` *cancels* it, so an explicit choice there is
acceptable.) Before adding any rule, error or required annotation, ask: does
this make the user state something the compiler already knows, can infer, or
that has no consequence? If yes, don't. A diagnostic earns its place only by
catching a real mistake the compiler can't otherwise resolve.

**Vale, not Rust, is the closest reference for the ownership model.** We take
the best of Vale (single ownership, consuming destructors / Higher RAII,
generational references, regions). "Exactly as safe as Rust" is a safety
*bar*, not a design compass — we are allergic to Rust's tiresome syntax. A Rust
idiom we must adopt is confined to the library-maintainer tier. For
ownership/drop/lifetime semantics, check `.reference/Vale` first; reach for Rust
only when Vale can't meet the bar.

**The signature states parameter ownership mode — load-bearing.** For free
functions, `&T` borrows and plain `T` consumes. Auto-referencing removes
call-site ceremony: `peek(x)` when `peek` takes `&T`; `take(x)` when `take`
takes `T`. The signature is authoritative, so a body edit never silently
changes ownership, destructor timing or the calling convention. `move x`,
`copy x`, `&x` remain explicit spellings of intent, but a consuming signature
never requires a redundant call-site `move`. Don't infer a borrow because a
plain-`T` parameter is currently read-only. A function that observes takes
`&T`; one that retains a borrowed input makes the lifetime valid; one that
needs an independent value clones explicitly. The compiler may diagnose a
legacy read-only `T` with an exact `&T` fix-it, but never silently reinterprets
the declared type. See specification §3.8 and
`docs/meetings/2026-07-05-D5-historical-share-place-free-parameter-design-superseded.md`.

**A parameter's mode is what the callee does with it (D110, Eric
2026-10-08).** Stores the argument → ownership transfers; only reads it → the
argument is observed. `get`, `contains`, `remove` take their key as a probe and
observe it; `insert` stores its key and takes it; `increment`/`decrement`
observe the probe and copy the key only on the insert path. Modes come from
signatures, once: builtin container methods have declared signatures (`fn
remove(key: &K) -> Option[V]`), and Sema's move checking, MIR lowering and drop
emission all read them. A builtin never has a second ownership system — no hand
list of "observed" or "consumed" intrinsic arguments in any stage.

**Copy-or-move is decided by identity, not representation (D111, Eric
2026-10-08).** Values have no identity (integers, floats, strings, keys):
passing one copies it. Resources have identity (files, tasks, sockets, handles,
buffers being filled): passing one transfers it. A heap buffer does not make
something a resource. `str` is a value: passing a `str` always copies, code
using `str` never sees "use of moved value" and never needs `.clone()`. The
implementation is an immutable, shared, reference-counted buffer (atomic count
— `str` is `Send`; literals immortal): a copy is a pointer plus a count
increment, the last holder frees, and a variable's last use is a move with no
count traffic (the drop plan's last-use facts). Built or edited text goes
through a builder that produces a `str`.

**Receiver modes are separate.** `fn`/`&self` reads, `mut fn`/`mut self`
mutates the receiver place in place, `move fn`/`move self` consumes it.
Retiring free-parameter SHARE-PLACE doesn't change `mut fn` receiver semantics
or D21's place-threading pipeline rule.

**D22 has one canonical, complete source: `docs/meetings/d22-Eric-Ruling.md`.**
Any document, comment, test, TODO, plan or behavior that conflicts with it is
non-conforming. Don't edit, reinterpret, narrow or broaden it;
`docs/proposals/d22-implementation-plan.md` is a derivative plan that can't
amend it. **D22 map-view and contextual-Copy is implemented.** `HashMap[K,
V].get` and `BTreeMap[K, V].get` uniformly return `Option[&V]`; `remove`
transfers and returns `Option[V]`. Copy-ness never changes a lookup signature.
A `&T` stays a reference during inference and pattern projection, including
when `T: Copy`; it materializes an independent `T` only once an owned-value
demand is established. `Option`, `Result`, patterns, `?`, `??` and eliminators
are transparent to view origins. Don't restore conditional `get` returns, teach
new code that lookup owns/copies, or treat a lost origin through `unwrap` as
precedent. Specification §§3.4, 3.8, 9.7, 10, 13.3, 21.1 and
`docs/meetings/README.md` D22 are conforming projections.

**D27 extends the doctrine to positional collections: element access
observes; `remove` transfers.** `xs[i]` denotes the element place; a positional
collection has no `get` (D71): `xs[i]` is the one spelling and panics
out-of-range (`Option` is for keyed maps); a binding names what's there, an
annotation demands what it says. The element-view campaign is done
(`docs/proposals/d27-implementation-plan.md`); the interim #715 element gate and
the #730 unannotated-let field gate are retired. Serialize/Deserialize
signatures are correct as declared (`JsonView` is a Copy view token); don't
"fix" the threaded sink into a borrow.

**D44 extends it to map traversal: traversal observes; consuming iteration
transfers; nothing makes a second owner.** `for (k, v) in map` is `map.iter()`
and binds `&K`/`&V`; `keys()`, `values()` and `iter()` return ephemeral view
iterators; `remove`, `drain` and `into_iter`/`into_keys`/`into_values`
transfer; an owned collection is `m.keys() |> map(it.clone()) |>
collect[List]()` and a typed binding never collects. §2.3: transport is not
duplication — the compiler never produces a second live value from one unless
the type is `Copy`, intrinsics and runtime helpers included (#1158, #1159,
#1187). Don't add callers of `keys()`/`values()`/`items()` as `List`s or
byte-copy a non-`Copy` element out of a container.

**D51 has one canonical, complete source:
`docs/meetings/Ruling-modeled-C-ownership-effects-conventions-and-foreign-lifetimes.md`.**
Don't edit, reinterpret, narrow or broaden it; the spec and decision log
conform to it and `docs/proposals/modeled-c-implementation-plan.md` can't
amend it. Its test for every C-interop inference: *what happens if this
inference is wrong?* Infer silently only what can at worst remove capability
or reject a valid program (dependency, invalidation, nullable, thread-bound,
coarse domain, presentation sugar); never infer what can create unsafety
(ownership, destruction, consumption, retention, independence, static lifetime,
success, thread crossing) — those come from an explicit `c facade` clause, an
adopted convention profile, or a proof, never from a name. Never half-model: a
safe constructor with no destruction contract is a leak (§65). Ordering (§66):
the SQLite facade is written first and compiles against the real header before
any example, release UAT, blog sample or documentation example is rewritten.
Until the facade language lands the compiler is NON-COMPLIANT: don't add safe
c_import constructors, wrappers or method sugar that grant ownership, and don't
teach new code that a name proves a destructor.

**`FnAbi` is the single ABI source of truth — never re-derive call ABI
per-path.** Every signature has ONE `FnAbi` (per-parameter `PassMode`:
`Direct`/`Indirect`/`IndirectPlace`/`Fat`/`Ignore`), computed ONCE by
`compute_fn_abi(sig)` and read by both the callee prologue
(`declare_function`) and every call site (`push_call_arg`). When adding a
call-lowering path, receiver shape or parameter kind, extend
`compute_fn_abi`/`PassMode` in ONE place — never a fresh per-path "value vs
address vs byval" decision (that is the transparent `T*`/`T**` divergence bug).
`PassMode::IndirectPlace` is a physical mode for compiler-modeled borrowed
places such as in-place receivers; an explicit `&T` is a reference value with
that reference's ABI; a plain consuming `T` is owned even when its ABI is
indirect. See
`docs/meetings/2026-07-06-D6-fnabi-is-the-single-abi-source-of-truth-compute-once-both.md`
and `docs/spec/abi/fn_abi_descriptor_design.md`.

---

## Ceremony is a design defect, not a user error

Code that exists only to satisfy the compiler is evidence the language is
wrong somewhere; your job is to notice and raise it, not write more of it.

**The test.** For any token: *would a person reading this think it means
something?* If it's there because the compiler requires it, it is ceremony.

**Signals that always trigger the test:** `.clone()`, `copy`, `move`, an
explicit `&`, an `as` cast, `Some(...)`, `let _ =`, or a type annotation
written only to compile; an error on code a person would call obviously
correct ("use of moved value" on a lookup key, a cast on `len()` used as an
index); a rule explained by "how X is represented" rather than "what the
program means"; the same fact encoded in two or more places; a comment
explaining a workaround for the language; a fix that leaves something to
remember.

**What to do.** Stop and raise it before writing more in that pattern. A
ceremony report is always welcome, even mid-task. Give: the code as a person
reads it; why it exists (the rule or representation); which law it violates;
how many times the pattern occurs in the tree (count it); what the code would
look like if the language were right and what would have to change. Never copy
a ceremonial pattern from neighboring code because it is local precedent —
precedent measures how long the defect went unraised. Writing the same
workaround a second time is a report.

**Integer width (D114).** No code depends on `isize` being 32 or 64 bits, and a
value whose range isn't bounded by memory is written with a fixed width:
timestamps, file sizes and offsets, hashes, IDs, money, anything serialized or
crossing into a C struct. Supported targets today are 64-bit hosts and wasm32;
other widths must stay possible without a redesign.

**The backstop: the ceremony census.** `tools/ceremony_census.w` counts the
known patterns. The bar is main's own counts (`:install-user` publishes them to
the green store on reseed, so a cleanup lowers the bar once merged). `src/main
build :ceremony-census` (in the gate) measures a tree against the bar: a count
that falls passes; one that rises fails unless the PR grants it in
`build/ceremony-allowances.tsv` (pattern, area, the bar, the new ceiling, why)
and says why in its description. A report that identifies a new pattern adds it
to the census.

## No Silent Fallbacks

When code can't be correctly generated, fail loudly with a diagnostic and exit
non-zero. Forbidden regardless of what tests say: emitting a placeholder body
(`-> Never`, `comptime_error(...)`, `panic("TODO")`, `return 0`); emitting an
`extern fn` to paper over a function the translator couldn't handle; silently
dropping a clause, arm or statement; "simplifying" a construct into something
that behaves differently; adding a `TODO` to emitted output and continuing.
**A migrator that produces 30/30 files with silent stubs is worse than one that
produces 0/30 with a loud error.** Emit a diagnostic naming the function and
location, return non-zero, leave the work visible. If a helper has no
error-return plumbing, wire it. Never invent a placeholder.

---

## "Done" Is a Claim That Requires Evidence

Not done because tests pass, the build succeeds, the commit was accepted or
output files exist. Done when the output is correct (what a human familiar with
the source would expect), the edge cases you noticed have tests or comments
explaining why they're uncovered, and anything unsolved is filed or surfaced as
a loud failure. Gut check: *did I make the success condition true by doing the
work, or by redefining the success condition?* This applies especially to
translation, migration and codegen tasks where "the build is green" says almost
nothing.

---

## Verify by Running, Not by Reasoning

The compiler's half-implemented corners — mutable aliasing, slice mutability,
coercions, which types are spellable — are where reasoning from layout,
signatures or spec text goes wrong.

**Spell it and run it.** Before concluding a type, mechanism or API works, write
the smallest program that uses it and compile it. A type usable-looking from its
layout may be unspellable as a parameter (`ListRange`); a `mut` parameter may
*move*; `&raw place` may need `const`/`mut`.

**Exhaust small answer-spaces in one pass.** When a question has an enumerable
set of answers ("how many ways can a mutable buffer cross a call?"), test all at
once and write the matrix — a verdict from partial evidence flips with the next
case. Concluding-and-patching the same question twice means stop and enumerate.

**Code settles facts; intent is the maintainer's call.** When a spec promise and
an implementation fact disagree, settle the facts by running, then surface the
contradiction rather than assuming which side is canonical. Test the
inconvenient premise first.

**Otherwise, keep moving.** Stop only for a decision genuinely the maintainer's
— intent, scope, or a go/no-go on real risk. When the path is clear and
self-scoped, proceed and report; restraint on a clear path is under-autonomy
wearing discipline's clothes.

---

## Anti-Patterns

**Weakening the check.** If a check fails, make the code pass it, or confirm
with a human that the check is wrong. Never downgrade it, add an exemption, or
route around it.

**Editing a user program to make it pass.** Release UAT fixtures
(`build/release_uat_fixtures/`), `examples/`, and any code on the blog or the
homepage are contracts with Eric and everyone who read them. When a compiler,
spec or stdlib change breaks one, the change is what broke: stop and take it to
Eric; never edit the program (2026-06-17 a c_import rule change broke the
raylib spiral UAT; it was rewritten to `unsafe` to go green without Eric's
knowledge). Ruling (Eric, 2026-09-22): examples track the current spec. A
**spec change** that breaks an example updates the example in the same change,
under the ruling, and says so; a **compiler or stdlib** change that breaks an
example is a defect in the change. Silently rewriting a program to go green is
never either.

**`unsafe` in a user program.** An application developer never writes
`unsafe`. If a UAT fixture or example needs it, the compiler forced it and the
defect is the compiler's: model the C surface, prove the call, or make it safe.
`with build :user-programs-safe` (a gate of `:release-uat`) fails on any
`unsafe` in those programs. `unsafe` belongs to library maintainers and the
runtime.

**"Pre-existing" without evidence.** A failure is pre-existing only if verified
on the previous commit — never with `git stash`; use `git worktree` or a clone.

**"Good enough for now."** A 90%-working translator that silently mishandles
10% is 0% done with a reporting problem. The bar is correctness, not coverage.

---

## Runtime Architecture

**D30 landed (steps 1–4, 2026-10-20;
`docs/meetings/2026-08-09-D30-retire-the-internal-runtime-abi-remaining-boundaries-speak-c.md`).**
The runtime is a bundle: `rt/*.w` compiled as one unit per (compiler
generation, target) at compiler build time into `rt.{o,wi,manifest}`
(`build/rt_bundle.w`), embedded in the compiler's `rt` slot (the host's) and
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
`rt/*.w` are the compiler's own runtime — user source never names one; the
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
`src/` modules still declare their runtime externs (agreeing duplicates of
the interface): they become `use rt.*` once a seed carrying the step-4
resolver rule is pinned, since the pinned seed refuses that import from
`src/`.

---

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
  - `wc -l`, `tail`, sums → `with -e` with a loop over `stdin.lines()`; `-n`
    gains persistent state and `last` with #957
  - `jq -r .a.b` → `with -e 'use std.json` ⏎ `print(JsonDocument.parse(read_all()).root().field("a").field("b").raw())'`
  - `sed -i`, `awk … file` → not yet (#958): `< file` and `with run`
  - Full matrix and open gaps: `docs/spec/toolchain/improve_oneliners.md`.
- **Implicit main** — a `.w` file needs no `fn main`; top-level statements are
  the program, beside helper `fn`s:
  ```
  use std.process
  fn shout(s: str): s ++ "!"
  let argv = args()
  for i in 1..argv.len() as i32: print(shout(argv[i]))
  ```
- **Run without a build step**: `with run tool.w a b` forwards `a b` as argv.
  Reuse the compiler's modules (`use Lexer`, `use Token`) for token-accurate
  source tooling — regex hacks are not acceptable for self-host-critical
  rewrites (see `tools/migrate_receivers.w`).
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

---

## Other hosts

The Mac is the release host. Linux: `ssh eric-5090` (Eric, 2026-09-27).
Windows: make sure the Windows VM on eric-5090 is on, then `ssh win10`. Build
and test there as here (the pinned seed drives the battery; never `git
stash`), and leave nothing running.

---

## Build System

```
with build              # full build (seed → stage1 → stage2 → final)
with build :dev         # dev tier: seed → stage1 only (D14 iterate loop)
with build :stage1 / :stage2
with build :fixpoint    # verify stage2 == stage3 (byte-identical)
with build :test        # run test suite
with build :test-green  # verify/record current test evidence
with build :seed-driver # the driver is the seed pinned in seed.lock (first in :test)
with build :clean
```

Fixpoint invariant: `stage2 == stage3`. If it fails, code generation is
nondeterministic: stop and fix. **If the build breaks, fixing it is the top
priority.**

### Optimization level: ALWAYS `-O1`, NEVER `-O0`

Every stage, runtime object and the release binary are built at `-O1`; there
is no `-O0` in `build.w` / `build/*.w` — an invariant, not a preference. `-O0`
is pathologically slow (a 26k-line module: 31+ min vs seconds), and `-O1` is
fully deterministic: a fixpoint break under `-O1` is a real nondeterminism bug
(`with build :fixpoint-diff`), and a bug only at `-O1` is a real UB or
miscompile. **Dropping to `-O0` to make a red build go green is the single most
forbidden shortcut.** The only allowed `-O0` is an explicitly approved,
temporary local diagnostic, reverted before any commit; `-O0` anywhere in the
build files is a regression.

---

## Seed Compiler

Resolution order: `WITH=<path>` → `with` on PATH → `src/main`. `src/main` is
not in git; it is always the seed pinned in `seed.lock`, fetched from the
`with-darwin-aarch64` release asset by `with build :seed` (a no-op while it
matches the lock). The battery is driven by that seed, exactly as CI is —
never by the installed compiler:

```
with build :seed                      # once per seed.lock bump
export WITH=$PWD/src/main
src/main build
src/main build :test                  # seed-driver first, test-green last
src/main build :last-green
src/main build :release-checks        # seed cut or release only (D131)
src/main build :install-user          # the fresh compiler to ~/.local/bin/with
```

`seed-driver` refuses `:test`, `:test-green` and `:last-green` when the
driver's digest is not the lock's (or an ancestor process is another
compiler). Only `:seed` writes `src/main`; there is no `:update-seed`.
`:test-green` records evidence from a completed run, not a substitute for it.
The iterate tier (`with check`, `with build :dev`) uses the installed compiler.

**A green belongs to the sources, not to the commit or worktree (D49).**
`:last-green` publishes the green keyed on the battery's inputs, the pinned
seed and the host (`~/.local/with-green/green.tsv`). The inputs are the
committed tree without `docs/` and top-level `*.md` (the build measures
software, not documents, Eric 2026-09-21; D50: key on what the output is made
from). `GreenEvidence.w` and `build/retention.w` apply the same rule and must
agree byte for byte. After a squash-merge of a battery-green branch, the
reseed on main is `git pull`, `src/main build`, `out/release/bin/with build
:install-user`: no second `:fixpoint` or `:test`. The gate refuses a dirty
worktree; never re-run a battery over sources that already passed one.

If the seed, installed compiler and release binaries are all broken, the
compiler cannot be recovered.

---

## Releases

Follow `docs/spec/toolchain/with-release-runbook.md`. Release work is packaging
and verification: no compiler, runtime, stdlib, migrator, build-system or test
changes unless the maintainer expands scope. An unrelated bug found in release
prep is filed with its repro, not fixed, unless the maintainer says it blocks.
Publish the Darwin arm64 binary as `with-darwin-aarch64`; never publish an
asset named `main` (`src/main` is only the local seed path).

---

## The Specification Leads

`docs/spec/README.md` is the bible. For D22, `docs/meetings/d22-Eric-Ruling.md`
is the controlling ruling; anything that conflicts with it is repaired to
match. Two absolute rules:

**The spec leads the implementation.** A spec change is a ruling that the
product is NON-COMPLIANT until the implementation catches up. No "implement
first, spec after", no holding spec text until code lands, no reverting spec
text to match code. When they disagree the implementation is wrong — or the
disagreement is surfaced to Eric; never resolved by quietly editing the spec.

**Spec changes are solemn.** Only Eric authors or blesses normative spec text —
the exact words (D16's precedent). An agent may draft and propose; a directive,
mission statement or agreed direction is NOT approval of specific wording.

### "Do the thing" — the decision procedure

Every spec change and most decisions surfaced to Eric go through this; present
all four in one brief, then wait for the ruling:

1. **What the others do.** Compare the reference projects (`.reference/`: go,
   mojo, rust, swift, Vale, zig, plus any that fit), verified in their trees.
2. **What the spec currently says.** Quote it. Check whether the spec already
   rules the question and whether the proposal duplicates an existing rule.
3. **Mission fit.** Relate the choice to `docs/mission.md` and
   `docs/meetings/README.md`; say which option is most with-y.
4. **Predict what Eric would say.** A committed BDFL prediction with
   confidence, derived from his decision record — falsifiable, not a menu.

**An ownership question states two facts first (Eric, 2026-10-08):** what the
callee does with the argument (stores or reads), and whether the type has
identity. If those decide it, it is not a ruling: do the work (D110, D111).

**Never present an option that plainly fails `docs/mission.md`** (writes what
the compiler knows, ceremony with no guardrail, leaks by default, weaker
safety). One clause saying why it was dropped is enough.

Then Eric rules; blessed wording lands immediately as the ruling and the
implementation is non-compliant until it conforms.

**Delegated decisions (D98).** A question that is not about C interop,
ownership or safety, is easy to reverse, and has a prediction of 75% or higher
does not wait: implement the prediction, spec words included, and record the
brief in the decision log as **delegated**. Eric vetoes afterwards; a veto is a
revert. UAT fixtures, examples, published programs, C interop, ownership,
safety and anything hard to reverse stay his.

---

## Filing Bugs

If the spec says something should work and the compiler disagrees, that is a
compiler bug: never silently work around it. File with the spec reference
(e.g. "§9.7 Pattern Matching"), a minimal reproduction, expected vs actual, and
the workaround used (so the fix can remove it).

---

## Decision Log

`docs/meetings/README.md` records non-obvious decisions and **why** (context,
alternatives, reasoning, what would reopen the call). When you make or reverse
a judgment call a future maintainer might re-litigate, append an entry (newest
first) and cross-link superseded ones. Consult it before reopening a settled
question. Terse: reasoning, not a changelog.

---

## Editing Protocol

### Before editing

Read the relevant source. Confirm AST layouts and naming conventions. When you
can't find something, grep `examples/`, `src/` and `docs/spec/README.md`
before assuming it doesn't exist. Never rely on memory.

### Code style — write the least ceremony

Match the surrounding code and the mission at the character level:

- Don't spell types the compiler can infer: omit an obvious return type
  (`fn shout(s: str): s ++ "!"`) and a local's type when the initializer gives
  it; annotate only where inference needs it (`var xs: List[i32] = List.new()`).
- Inline the colon when the body is very small: `fn millis(ms: i32): ms`, `fn
  get(): self.n` on one line. A block body only when it is multi-statement.
- Boy-scout the style: any function you touch leaves least-ceremony.
- Unnecessary casts and `unsafe` are defects: fix them on sight, anywhere. The
  defaults cover them: `v[i]` and `v[i] = x` take an `i32` index; `i32` widens
  into `i64` arithmetic and comparisons; `for k in 0..n` indexes directly. So
  `.get(i as i64)`, `.set_i32(i as i64, x)`, `v[i as i64]`, `x as i64` where the
  target widens are never written — only a narrowing needs `as`. `unsafe` is for
  a raw pointer that must exist (FFI, the allocator, an ABI seam), never a
  stand-in for mutation the language expresses safely: a `*mut State` handle
  mutated through by-value calls is an owned struct with `mut fn` methods in
  disguise (spec §15.1: `&mut T` is not safe With; `mut self`, an owned
  parameter, or a returned value is). A file full of the legacy idiom is a
  backlog to burn down; a mechanical class of it is a `with -p` or Lexer-based
  rewrite, not N hand edits.
- **Never take an idiom from a migrated corpus (D112).** `lib/std/engines/pcre2`,
  `lib/std/engines/zlib`, `lib/std/engines/c_algorithms`, `lib/std/engines/tommyds` (every corpus in
  `build/corpora.w`) and `test/corpora/` are generated by `with migrate` from a
  pinned migrator generation and carry its idioms (hoisted ternary temps, push
  chains, `.clone()` on a str). They prove the migrator and compiler work, not
  how With is written. Never edit them: a corpus moves only by re-promotion.

### One logical change at a time

Don't batch unrelated changes. Small changes make debugging possible.

### Commit authorship

Every commit is authored by the human who drove the work, under their own name
and email — for Eric, `Eric Hartford <eric@quixi.ai>`. Agent-driven work is
committed under the identity of the human who ran the agent. Never add an AI
assistant, model, tool or vendor as author, co-author, trailer or credit; no
`Co-Authored-By` for AI assistance.

### Rebuild and verify (tiered — decisions.md D14, D19, D131)

Each tier runs only what it must prove (D131, Eric 2026-10-14): a fix, that
it does what it says and breaks nothing nearby; a PR, that main stays correct
and buildable; a seed cut or a release, that the toolchain reproduces itself
and the migrated corpora agree with the migrator.

**Iterate tier — the only per-change requirement.** `with check src/main.w`
and/or `with build :dev`, plus the targeted tests for what you touched. Never
the full battery per edit.

**The pre-battery gate is one command:** `src/main build :gate`. It covers the
fixed list (the release build, selfcheck, the build.w check with the fresh
release binary, abi-hash-check, unit-return-review, spec-inventory-check,
examples-tests, benchmarks-check, c-migrator-basic-tests,
deep-debug-tool-tests, user-programs-safe) plus every test target the last
battery measured under 60 s (a fresh worktree runs the fixed list). Every
stack layer runs it before reporting done, and the battery runs it first.

**Batch tier — one stack, one battery.** Work landing in the same window goes
on ONE `gh stack`; ONE battery blesses the whole stack, once, on its top
commit, after every layer is in:
```
with run tools/battery.w
```
It refuses a dirty tree, holds one of two machine-wide battery slots, runs
`src/main build :gate` under the pinned seed (a red gate stops it: `RED
(gate): <targets>`), then `with uat` with the release compiler the gate built
(`uat/*.uat`; `RED (uat): <scenarios>`), then `src/main build
:battery-checks` (the drop and move audits, every PR test target,
user-programs-safe, green evidence) as ONE survey, writing `RED: <target>` to
`out/battery/status.txt` as each fails — read the status file, not the log's
end. `--fail-fast` stops at the first red. Logs land in `out/battery/`. Then
`:install-user` once.

**Seed-cut and release tier.** `src/main build :release-checks`: the fixpoint
(stage2 == stage3), the Sema regression rebuilds (issue61, the invariance
perturbations), the C migrator tests, every corpus migrated afresh and tested
(`corpus-migrator-gate`, the corpora lanes) and wo-drift. A seed is cut, and a
release made, only from a tree whose `:release-checks` is green; `release-uat`
depends on it. A nondeterminism or corpus break that lands on main surfaces
here and is fixed before the cut.

**A red battery:** fix every reported failure on the stack with iterate-tier
evidence, then run the battery once more. Never add new work to a red stack.
Ownership, drop and ABI changes batch like everything else; a red is traced to
its layer locally.

### Working efficiently (agents)

Every agent works at the iterate tier plus the gate. An agent:

- runs `with build :dev` and `with test`/`with run` on the tests it wrote or
  touched, and shows each new test FAILING before its fix;
- in a staging worktree, uses absolute paths for every file it reads or
  edits: relative tool paths resolve to the main checkout, so a relative
  read silently returns main's file while the agent believes it is reading
  the branch's (verify once per session on a file the branch changed);
- after a migrator spelling change, sweeps every textual expectation of the
  old spelling across the tree (never a head-truncated search) and runs
  `src/main build :c-migrator-basic-tests --no-deps` before the battery; new
  code in `src/` also gets `with run tools/ceremony_census.w --diff HEAD`
  at the iterate tier, so ceremony is caught at the desk, not in the gate;
- never runs `tools/battery.w`, `:test`, a corpus target (`:behavior-tests`,
  `:native-*`, `:internals-tests`, …) or `:move-audit` on its own: the
  coordinator runs those once per stack;
- never launches a program outside this repository (a user's game, app or
  project): build it to check it compiles; never run it;
- runs `src/main build :gate` before reporting a layer done, and first the
  checks its files call for: a change under `src/Mir*.w`, `src/MirLower.w`,
  `src/MirValidate*.w` or any validator runs `src/main build
  :deep-debug-tool-tests --no-deps` and `:drop-audit`; a change under `build/`
  or to `build.w` checks `build.w` and `lib/std/build.w` with the fresh
  `out/release/bin/with`;
- before writing a test fixture, reads one existing test of the same kind
  (`test/behavior/behav_*.w`): `type T:`, `impl Drop for T:` with `move fn
  drop()`, `//! expect-stdout:` headers, and statements never sit beside `fn
  main`;
- never wraps commands in an opaque script — `sh -c "…"`, `bash -c`, `nohup
  sh -c`, `eval`, `xargs <cmd>`, or a quoted multi-command script inside `ssh
  host '…'`: the permission checker cannot read inside them, so each stops the
  campaign for Eric's approval. Run a long command as its own background Bash
  call (no `nohup`, no `&`); put loops or multi-step logic in a With script;
- commits locally and does not push unless told. A pushed branch always has a
  PR in the stack (`gh stack link --base main …`).

### Re-read before editing

After 10+ messages, re-read any file before editing it: context compaction may
have destroyed your knowledge of its contents, and Edit fails when
`old_string` no longer matches.

---

## Stage Debugging

`with` below is the installed compiler; it runs every dump, trace, `analyze`,
`reduce` and allocator recipe. For source you changed, use
`out/bootstrap/bin/with-stage1` (`with build :dev`); lldb works on either.
`out/stage/bin/with-stage2` exists only after a full build. The full catalog:
`docs/spec/toolchain/deep-debugging-tools.md`.

### Quick repro
```
out/bootstrap/bin/with-stage1 check src/main.w
```

### Deep compiler tools (before edit/compile/trace loops)
```
with reduce repro.w --contains "diagnostic" -- with check {file}
with check repro.w --trace-place main:_1
with check repro.w --explain-mir-origin main:_1
with check repro.w --trace-ownership main:_1
with check repro.w --dump-drop-plan | --dump-place-map | --dump-abi | --dump-drop-state
with check repro.w --trace-cleanup-edge 'main:bb0->bb1'
with check repro.w --validate-all | --validate-ownership
with build :fixpoint-diff
```

### Integrated compiler analysis (`with analyze`)

Use this **before** standalone scanners, debug prints or a rebuild when a
problem crosses AST/Sema/MIR/ABI/codegen. One compilation joins facts from the
live `Sema`, `MirBody`, diagnostics and real LLVM codegen branches, and audits
its own marshalling coverage — an uninstrumented call path is a failure, not a
blind spot.

```sh
with analyze repro.w audit:all | audit:storage | summary | contract | move-sites
with analyze repro.w 'matrix:name~function_name'
with analyze repro.w 'select:stage=sema,kind=parameter,name~function_name'
with analyze repro.w 'explain:call:function_name' | 'explain:origin:function_name' | 'explain:effect:Type.method:self'
with analyze repro.w 'select:kind=operator,detail~fn:function_name'
with analyze repro.w 'path:call:caller:callee' | 'closure:call:root_function'
with analyze repro.w 'lldb:kind=call,name~function_name'
```

- `facts` / `snapshot`: stable TSV facts for fixtures or a text diff — all AST
  function declarations (incl. generic/uninstantiated methods), finalized
  signatures/effects/receiver modes, specializations, MIR bodies/locals/places
  /calls, diagnostic provenance, LLVM parameter shapes, caller marshalling,
  callee binding, source identity with exact byte `start`/`end`; MIR
  call-argument facts join lowered operands to Sema's canonical AST nodes.
- `select:` / `summary[:]` / `matrix:`: comma-separated `field=value`,
  `field!=value`, `field~substring` predicates (`with analyze file.w help`).
- `contract` / `audit:contract`: the modeled foreign contract of every `c
  facade` (ruling §63) with provenance and the suspicious-configuration audit.
- `audit:resolution`: D65 — every MIR callee and argument count agrees with
  Sema's resolution (#1635; phase 1 of
  `docs/spec/implementation/mir-sema-hardening.md`), and every expression's MIR
  operand has the type Sema gave it (the D97 class).
- `audit:calls|effects|storage|methods|mir|returns|receivers|receiver-surface|phase|pool-views|contract|resolution|codegen|trait-tables|all`:
  hard invariants (`all` covers typed/ownership validators, receiver contracts,
  fixed-point effects, freeze/eager-cache/specialization, frozen-phase
  re-entry, LLVM declaration ABI, marshalling, aliasing, instrumentation
  coverage, AST-indexed storage bounds, trait-table/vtable agreement).
  `audit:storage` permanently checks the resolved-call table that once
  overflowed past 32767/65535 node IDs.
- `path:call` / `closure:call` operate on the live MIR call graph; use them
  instead of source-text reconstruction. `lldb:<query>` emits breakpoints from
  matching facts and refuses to invent one.

Also a reducer predicate: `with reduce repro.w --exit-code nonzero -- with
analyze {file} audit:all`. Do not start a full build to test an ABI/ownership
hypothesis: first require the focused repro's `audit:all` to pass and inspect
its `matrix`; a build is the final repo-wide verification. There are no
source-scanner semantic fallbacks — if analysis can't reach the needed phase,
reduce the repro or attach LLDB. Source rewrite tools may use the Lexer to
apply byte edits, but selection and contracts come from `compiler_analyze_file`
facts: `tools/annotate_receivers.w`, `tools/migrate_receivers.w`, `with
migrate-receivers` (built in, `src/ReceiverMigration.w`; `--report`, `--list`,
`--apply`), `tools/migrate_method_arg_moves.w`. The removed
receiver/frozen/closure/diagnostic-map tools must not be recreated.

`--dump-abi` prints, per signature, each parameter's ownership/ABI
classification — effect flags, `value_ref_abi`, the physical passing verdict.
It answers "is this borrow or owned parameter lowered consistently at caller
and callee?" — dump it, don't infer it. A legacy `SHARE-PLACE` label is
implementation terminology for `IndirectPlace`, not permission to reinterpret
a consuming `T` as a borrow.

For drop-exactly-once across (value shape × control flow × ownership op ×
receiver mode), run `with build :drop-audit` (`tools/drop_audit.w`; candidate =
the fresh release binary, baseline = the verified seed) before and after ANY
change to drop scheduling, ownership or receiver lowering. One bad cell means
the whole region is untested; a cell is red only when the verdicts DIFFER
(#693's enum cells and #608's POD-leak pins read as `same`).

### LLDB (preferred)
The compiler's objects name their sources under `/with-src` (D50), so map it
to a checkout of the commit the binary was built from: for
`~/.local/bin/with`, the tree you reseeded from (`:install-user` prints its
green commit; `~/with` once fast-forwarded). A different checkout lists the
wrong lines.
```
lldb -o "settings set target.source-map /with-src $PWD" -- out/bootstrap/bin/with-stage1 check src/main.w
(lldb) run
(lldb) bt all
```
The installed compiler, scripted (verified 2026-10-19). Breakpoints take
With's dotted names (`Type.method`, or a free function's name);
`frame variable` shows a frame's locals and `source list` its code:
```
lldb --batch -o "settings set target.source-map /with-src $HOME/with" \
  -o "b Sema.source_path_text" -o run -o "bt 8" -o "frame variable" -o kill \
  -- ~/.local/bin/with build repro.w -o repro
lldb --batch -o "image lookup -n Sema.source_path_text -v" -- ~/.local/bin/with   # where a function lives
llvm-dwarfdump --uuid ~/.local/bin/with ~/.local/bin/with.dSYM   # the dSYM is this binary's (UUIDs equal)
```
Everything is built at `-O1`, so some locals read `<variable not
available>`; step to where the value is used, or read the argument in the
caller's frame (`frame select 1`). lldb does not expand `~` in a
source-map path: spell `$HOME`. `llvm-dwarfdump` is the SDK's
(`.deps/llvm-<ver>-<host>/bin`). A hang: `lldb -p <pid>` then `bt all`.

### Native Debug Allocator
```
with run --debug-alloc repro.w
with run --debug-alloc --debug-alloc-filter=non-root repro.w
with check repro.w --dump-drop-state | --dump-drop-plan | --trace-ownership main:_1
with build :debug-alloc-tests
./out/release/bin/with build tools/debug_drop.w -o out/debug-alloc-tests/debug_drop
out/debug-alloc-tests/debug_drop run ./out/release/bin/with repro.w
lldb --batch -o "settings set target.env-vars WITH_DEBUG_ALLOC=1" -o run -- ./bin   # learn the addr (stable only under lldb)
lldb --batch -s tools/debug_drop_sites.lldb \
  -o "settings set target.env-vars WITH_DEBUG_ALLOC=1 WITH_DEBUG_ALLOC_TRAP_FREE=<addr>" \
  -o run -o "bt 24" -o quit -- ./bin                            # backtraces at each trap hit and the double-free reporter
```

### Heap corruption and leaks
The malloc tools see only malloc zones; With's allocator is its own, so without
`WITH_ALLOC_SYSTEM=1` they report a clean heap whatever happened:
```
WITH_ALLOC_SYSTEM=1 MallocScribble=1 MallocGuardEdges=1 out/bootstrap/bin/with-stage1 check src/main.w
WITH_ALLOC_SYSTEM=1 leaks --atExit -- out/bootstrap/bin/with-stage1 check src/main.w
```
First choice for leaks is the debug allocator (`WITH_DEBUG_ALLOC=1`, it names
the block and origin). If stacks are nonsense, suspect seed corruption and
replace the seed with a known-good binary.

---

## Repository Layout

```
src/        compiler source (.w)        lib/std/   standard library (.w)
rt/         runtime + platform backends  runtime/   platform assembly (fiber_asm_*.s)
test/       test suite                   build.w    build system
out/bin/    compiler binaries            out/lib/   compiled runtime objects
docs/       specifications
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

There is **no `NK_VAR_DECL`**: mutable variables use the mut flag on
`NK_LET_DECL`.

---

## Common Mistakes

- Misreading AST layouts; guessing APIs — read the source.
- Working around compiler bugs instead of fixing the root cause.
- Writing C when With works; `@[c_export]` for internal boundaries.
- Guessing linker flags: know which link path you're on (cc vs lld).
- Using `with build` as a debugging tool (5 minutes) instead of `grep`, `nm`,
  `lldb`, `with check`.
- Iterating unordered maps or using pointer-address ordering: breaks fixpoint
  determinism.
- **Never use `git stash`** (it has destroyed uncommitted work; `pop` and
  `drop` too). Use `git worktree` or a clone.

---

## Success Checklist

A change is acceptable only if, driven by the pinned seed
(`WITH=$PWD/src/main`): `src/main build`, `src/main build :test`,
`src/main build :test-green` all pass (the battery), and before a seed cut or
a release, `src/main build :release-checks`. If any fails,
continue debugging until it passes.

---

## Bootstrap Rules

### Changes land via pull request
All changes reach `main` through a PR. Branch protection requires a PR with
zero approvals (Eric, 2026-09-23): the seed-driven battery is the gate (D56).
Batch related commits into one PR as the battery batches them. GitHub lanes are
not a merge signal (a lane takes hours; they run nightly and on dispatch,
post-hoc); a PR is a draft until its seed-driven battery is green and posted,
then marked ready. The SDK is built only on release (`sdk-release.yml`).

**windows-aarch64 is non-gating (D137, Eric 2026-10-19).** Dispatch its jobs
(`selfhost-windows-aarch64`, `seed-windows-aarch64`, its SDK and release
jobs) and move on: never wait for one, never hold a merge, reseed, seed cut,
release, PR or issue for its verdict. A red run seen later is filed as a new
issue (run ID, failing targets, captures) and fixed like any other bug.

### Dependent PRs are a `gh stack`, never hand-chained bases
Dependent PRs are a GitHub stack via the `gh stack` extension (`gh extension
install github/gh-stack`; exit code 9 means stacks are not enabled). Never
stack by hand with `gh pr edit --base` or cumulative branches (that landed five
PRs as one commit, 2026-09-22).
- **Create/update:** `gh stack link --base main <bottom> … <top>` (branch names
  or PR numbers, bottom to top); it pushes, creates missing PRs and fixes each
  base. Each layer holds only its own commits.
- **Draft until green:** link as drafts; `gh stack link --open …` or `gh pr
  ready` only after the battery is green and posted.
- **Merge:** the whole stack or up to one PR, in order, all-or-nothing: `gh
  stack merge <top-pr> --yes --squash`. Never merge a middle layer by hand.
- **Main moved:** `gh stack rebase` from a stack checkout, then `gh stack
  push`; a rebase that resolves conflicts needs a new battery.
- **Independent PRs are not stacked.** A single-PR batch has base `main`.

### Every PR must be bootstrappable
Each PR must be green and buildable from a tagged seed release that exists
before it merges; if a change needs a newer seed, tag one first. The pinned
seed is `seed.lock` (version and per-platform digests); every CI lane and `with
build :seed` read it, and the local battery is driven by it: `build.w`,
`build/*.w` and `lib/std/build.w` are comptime-evaluated by the driver under
the pinned seed's evaluator. `seed-driver` refuses any other driver and any
workflow pin that disagrees with the lock. A language or evaluator feature used
in the build layer raises the minimum seed — never revert the surface to
appease an old seed (Eric, 2026-09-04): cut a newer seed, bump `seed.lock`
(`with run tools/bump_seed_pins.w`, `with build :seed`), then land the change.
(Main was unbuildable by every published seed for two days, 2026-09-02..04;
`seed-driver` red is stop-the-line.)

### The seed compiler is frozen
The installed compiler at `~/.local/bin/with` has its own Link.w, embedded
runtime objects and codegen baked in; editing source files does not change it
until you install a new seed.

### Never run `with build :install` with uncommitted changes
It updates the seed, and a broken seed breaks all future builds. Install only
after `with build :fixpoint` passes on committed code.

### Never change Link.w and runtime files in the same commit
Commit 1: new exports in rt_core.w (old link path still works). Commit 2:
Link.w (new path activates). Each must independently pass `:fixpoint`.

### Bootstrap order for runtime migration
1. Checkout all runtime/link files to the last green state.
2. `with build && with build :fixpoint` (green baseline).
3. Apply rt_core.w changes only (new exports, ABI fixes); build and fixpoint.
4. Apply Link.w changes; stage1 is built with the old seed (old link path),
   stage1 has the new Link.w and builds stage2 with the new path.
5. `with build :fixpoint` (stage2 == stage3 converges); then `with build
   :install` (seed updated).
