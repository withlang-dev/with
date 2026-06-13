# Spec Feedback — High-Level Sweep (v6.9)

Date: 2026-06-09
Scope: `docs/with-specification.md` v6.9, full read.

Evaluation bar: With's mission (`docs/mission.md`) — ergonomics is the
genuine focus; safety must be near-invisible and designed to least
inconvenience the programmer. Items below are flagged only where the
spec contradicts itself, contradicts the mission, or promises behavior
the specified machinery cannot deliver. "Rust would do it differently"
is explicitly not a criterion.

Ranking: items 1, 3, and 6 are the ones where waiting is expensive —
they sit directly under Crux and Weld, and code built on a guessed
answer will calcify. Items 2 and 4 are one-paragraph spec edits that
remove self-contradictions.

**Implementation survey (added 2026-06-09):** each item now carries an
"Implementation status" note recording what the compiler actually does
today, with file:line evidence, and how that differs from the spec
text. Survey method: source inspection of `src/`, `rt/`, `lib/std/`,
and `test/` at commit 1373e453. Headline findings: the implementation
has already resolved several of the contradictions below in one
direction (cancellation is unwinding-only; parameters move by default;
`type X = A | B` enum syntax is rejected), and one new conformance gap
surfaced during the survey: **`pub` visibility is recorded but not
enforced** (see D.11).

Where the implementation and the spec diverge on a fundamental, a
**Ruling opinion** grounded in the mission statement follows the
implementation status (items 1, 3, and D.1): in each case, which of
the two is wrong — or whether both are.

A second-pass reflection (same day) produced revisions, marked
inline: item 1's inferred-borrow salvage is **retracted** (Drop-timing
ambiguity), item 13's default-on warning is **retracted** in favor of
an opt-in lint, and item 4 carries a calibration note (conviction
moderate). All other items stand as written.

---

## A. Decisions that need a ruling now

### 1. The parameter-passing model is unresolved, and the spec contradicts itself about it

**The contradiction:**

- §2.2 says "assignment moves by default," and every reader will extend
  that mental model to calls.
- §3.8 says the default plain call `f(x)` for non-Copy values is
  **share-place**: the callee operates on the caller's place unless the
  caller overrides with `move x`, `copy x`, or `&x`.
- §12.4 extends share-place to closures: `let f = || xs.push(1); f()`
  mutates `xs`.
- §14.15 says `tx.send(msg)` **moves** the value. Container APIs like
  `Vec.push` must consume their element.

**The gap:** the spec only ever shows mode declarations for receivers
(`self: &Self` / `mut self: Self` / `move self: Self`, §9.5). There is
no spelling for an ordinary consuming parameter, and no section defines
the call-mode system: what `fn f(x: Vec[i32])` means, how a callee
declares "I consume this," or how effect summaries surface at call
sites. §4.3a defers to "the normal call-mode and effect rules for the
callee," which are not defined anywhere.

**Evidence it's load-bearing:** §21.1 Rule 6's example
(`fn longest(a: String, b: String) -> &str`) returns views derived from
by-value parameters. Under the §2.2 move narrative this returns
dangling references; it only type-checks under share-place. The spec's
own examples already depend on the unspecified semantics.

Share-place is a defensible, mission-true choice — it is *why*
`alice.update()` and `longest` work without ceremony. But it needs:

1. A real normative section (the call-mode model).
2. §2.2 rewritten so the "moves by default" narrative matches.
3. An answer for consuming non-self parameters (`tx.send`, `Vec.push`).

Everything downstream — borrow checker, Crux API design, the migrator's
calling conventions — hinges on this.

**Implementation status (2026-06-09):** The compiler implements
**move-by-default**, not share-place. Non-Copy call arguments lower as
`OK_MOVE` and invalidate the caller binding (`src/MirLower.w:2308-2323`,
reached from `lower_call_arg` at `:5697`). The call-site annotations
`move x` / `copy x` do parse (`src/Parser.w:3172-3216`,
`NK_MOVE_ARG`/`NK_COPY_ARG`), and there is an inferred effect system:
when a callee parameter carries `EFF_CONSUME`/`EFF_ESCAPE_VALUE`,
passing a non-Copy value *without* an explicit `move x`/`copy x` is a
compile error — "non-Copy argument passed to a function that consumes
or escapes it" (`src/SemaCheck.w:8177-8186`). Auto-ref for `&T`
parameters is implemented (`src/SemaCheck.w:225-248`,
`src/MirLower.w:5713-5726`). So the implementation matches §2.2,
contradicts §3.8/§12.4 — and is actually a *third* model
(move-by-default plus consume-acknowledgement annotations driven by
inferred effects) that no spec section describes. The ruling should
either bless the implemented model and rewrite §3.8/§12.4 to match, or
declare share-place the target and file the migration as a major work
item. As written, §3.8's share-place text has never been implemented,
and §21.1 Rule 6's `longest` example does not type-check under the
shipping semantics.

**Ruling opinion (mission-grounded): the spec is wrong, and the
implementation is half right.**

Share-place as written fails the mission's own standards three ways:

1. **It makes behavior invisible at both the call site and the
   signature.** Whether `f(x)` mutates or invalidates `x` depends on
   inferred effects of the callee's *body*. The spec's own concurrency
   principle (§14.1) is that systems programmers must be able to
   predict behavior from source — that's why suspension is
   compiler-tracked. Mutation through a plain call is the same class
   of invisible behavior, with no diagnostic surface at all.
2. **It contradicts §4.6.** Inference does not cross module
   boundaries, so share-place at `pub` boundaries would require
   *declared* effect signatures — a new annotation burden larger than
   the ceremony it removes.
3. **It has no clean Drop story.** Deterministic destruction (§20.10)
   needs an unambiguous owner at scope exit; "the callee operates on
   the caller's place" makes consumption a matter of inference.

Move-by-default + auto-ref — the implemented skeleton — is the
mission-true core. The 95% case (callee only reads) already has zero
ceremony, because auto-ref erases the `&` and the caller's binding
stays valid. The 5% case (callee consumes) is loud and safe:
use-after-move is a compile error. That is exactly "safety invisible
until it matters."

But the implementation's extra gate — requiring `move x` / `copy x`
when the callee carries `EFF_CONSUME` — fails the mission's central
test. The callee's signature already says the parameter is consuming;
the move checker already catches any use-after-move loudly. The
annotation states something the compiler already knows and prevents no
mistake the compiler doesn't already catch. (Contrast the dropped-Task
rule, which is justified because that consequence is silent and at
runtime; a moved binding has no silent consequence — misuse is a
compile error either way.) Taken to its conclusion, this gate makes
With's most common consuming calls — `vec.push(move item)`,
`tx.send(move msg)` — *more* ceremonial than the languages With means
to improve on. **Cut the acknowledgment; keep the effect inference.**

~~What to salvage from share-place: letting the compiler infer that a
by-value-spelled parameter the callee only *reads* is a borrow, so
naive signatures like `longest(a: String, b: String) -> &str` work as
written.~~

**Revised (2026-06-09, second pass): the inferred-borrow salvage is
retracted.** The inference is unsound as a language rule — not for
safety, but for **Drop timing**. A body that only reads a by-value
`File` parameter is textually indistinguishable from one that
consumes it and disposes it at return; both bodies just read.
Inference cannot distinguish "borrow this" from "consume this and
release it when I'm done," and choosing borrow silently moves
destructor timing to the caller's scope end — locks held longer,
files closed later. That is invisible behavior change driven by body
inference: the exact failure this opinion convicts share-place of.

The honest replacement is simpler and stricter: **the signature
states the mode.** `&T` borrows; plain `T` consumes. This is explicit
exactly once, in the signature — the boundary where §4.6 already
demands explicitness — and never at call sites, because auto-ref
erases the sigil for callers (`longest(s1, s2)` reads identically
either way). Pair it with a directed diagnostic for the classic
mistake: "`longest` consumes `a` but returns a view derived from it;
take `a: &String`." Fix §21.1's example to take `&String`. Keep
§12.4's share-place for **closure captures** only, where the behavior
is lexically visible (the closure body sits next to the variable it
mutates).

Net effect of the revision: the implementation is upgraded from "half
right" to **right, except the `move x`/`copy x` acknowledgment gate**,
which remains ceremony to cut. Rewrite §3.8 and §2.2 to the
signature-states-the-mode model.

### 2. §9.7 declares `Result` a `@[must_use]` type — a Rust remnant contradicting §10.1 and AGENTS.md

§10.1 (and the project constitution) say discarding a `Result` requires
no ceremony. §9.7 then says partial match on "`@[must_use]` types
(e.g. `Result`, `Task`)" is a compile error requiring `_ => {}`.

The incentive gradient this creates is backwards:

```
db.execute("...")                          // ignore everything: legal
match db.execute("..."): Ok(n) => log(n)   // handle more than nothing:
                                           // ERROR without `_ => {}`
```

This punishes the more careful programmer. The rule is right for `Task`
(discard has a consequence — cancellation); for `Result` it is exactly
the must-use ceremony the project forbids.

**Fix:** remove `Result` from the §9.7 `@[must_use]` exhaustiveness
paragraph.

**Implementation status (2026-06-09):** Shipped exactly as §9.7 says:
`Result` and `Task` are **hardcoded** as must_use
(`src/SemaDecl.w:116-122`), and statement-position partial match on
them is a compile error (`src/SemaCheck.w:6072-6080`,
"non-exhaustive match: missing variant" at `:6183`). Meanwhile
discarding an entire `Result` is silently allowed (no diagnostic
exists), and the Task-disposition check E0801 is implemented
(`src/SemaCheck.w:4384-4387`, `test/compile_errors/err_unused_task.w`).
The backwards incentive gradient ships today. The fix is a two-line
change in `SemaDecl.w` (drop the `Result` insertion) plus the spec
edit.

### 3. Cancellation has two contradictory stories in §14.7

§14.7 point 6 says awaiting a cancelled task "triggers cancellation
unwinding — similar to a panic, catchable at `async scope` boundaries."
The same section's examples show `t2.await?` *returning*
`CancelledError`, and `match task.await: Err(e) if e.is_cancelled()` —
an `Err` of the task's own error type `E`, which has no cancelled
variant and no `From` impl ("no error types need to change").

Both cannot be the surface semantics:

- If cancellation unwinds, the `Err(e) if e.is_cancelled()` arm is dead
  code.
- If it returns `Err`, then every `E` is secretly wrapped in a hidden
  sum type — the type-system infection Invariant 3 forbids.

The unwinding story is the one consistent with "no `From[TaskCancelled]`
on every error type." The observation API then needs respec'ing —
e.g. `.is_cancelled()` on the `Task` handle, checked instead of (not
after) `await`. This must be decided before Weld builds on it.

**Implementation status (2026-06-09):** The implementation already
chose unwinding. Cancellation is a per-fiber flag
(`rt/fiber_core_darwin.w:179-189`, set by
`with_runtime_request_cancel` at `:622-627`); awaiting a cancelled
task does **not** produce an `Err` value — the await site runs defers
and drops, sets a cancelled-return flag, and propagates it to the
awaiter (`src/MirLower.w:4847-4925`, `rt/fiber_runtime.w:174-203`,
`src/CodegenDispatch.w:6655-6715`). `CancelledError` does not exist;
`.is_cancelled()` does not exist anywhere; the runtime observation
primitives are `with_fiber_is_cancelled()` and
`with_fiber_was_cancelled_return(fiber_id)`
(`rt/fiber_runtime.w:260-269`), reachable only as MIR intrinsics, not
public API. The §14.7 `Err(e) if e.is_cancelled()` text describes
machinery that has never existed. **Fix the spec to the unwinding
story** and spec a public observation surface over what the runtime
actually has (task-handle-level `was_cancelled` checks).

**Ruling opinion (mission-grounded): the implementation is right;
delete the spec's Err story.**

The mission goal that §14.7 itself states — cancellation must never
force a `Cancelled` variant or a `From` impl into user error types —
is deliverable only by the unwinding model. The Err-value story
requires every `E` to secretly become a sum of `E + Cancelled`: hidden
cost, type-system infection (Invariant 3), and a `match` on errors
that lies about its own type. Unwinding gives the common case zero
ceremony — destructors run, `async scope` absorbs it, user error types
are untouched. Safety stays invisible precisely where the mission
demands it.

The rare case — code that genuinely needs to distinguish cancellation
from failure — should pay explicitly and locally, not tax every error
type in the program. Spec a method on the `Task` handle (the runtime
already maintains exactly this state: `with_fiber_was_cancelled_return`,
`rt/fiber_runtime.w:266-269`), checked instead of — not after —
`await`. Replace §14.7's `CancelledError` / `.is_cancelled()` text
with that surface, and keep the example showing the scope-boundary
catch, which is the part of the section the implementation actually
honors.

### 4. §7.2's builder implicit-return rule dispatches semantics on Unit-ness

Whether `with Config.default() as mut c: ...` returns the builder or
the last expression depends on whether the final statement's type
happens to be `Unit`. Consequences:

- A library adding a return value to a previously-void setter silently
  flips callers from builder mode to extraction mode — a semantic
  change at a distance, in the language's most-used construct.
- The spec's own escape hatch ("just add a trailing statement or use
  `let _ =`") is verbatim the ceremony §10.1 forbids.

**Mission-true fix:** `with expr as mut c:` always returns `c`;
extraction is signaled explicitly (a plain block / Form 3, or an
explicit final keyword). One construct, one meaning.

**Implementation status (2026-06-11):** Superseded by #375. Mutable
plain and tuple `with` builder forms always return the binding;
guarded dispatch via `Scoped`/`ScopedMut` with `with_enter`/`with_exit`
validation remains the body-value path. This was much cheaper to fix
before Smallhold/Crux code started depending on
extraction-mode behavior.

**Calibration note (2026-06-09, second pass):** the silent-flip risk
is partly mitigated by the type system — when a builder block flips
to extraction mode, the changed result type usually fails downstream
as a (confusing, distant) type error rather than corrupting silently.
The recommendation stands, but on teachability and
diagnostic-locality grounds rather than correctness: the most-used
construct in the language should be explainable in one sentence, and
the error for a mode flip should not appear lines away mentioning an
`Option[V]` nobody wrote. Conviction: moderate, not high.

### 5. The "iterators just work" magic is stdlib-only — and the flagship apps all live outside the stdlib

§13.2: the compiler has built-in knowledge that stdlib iterators'
`next()` borrows the *collection*, not the iterator; custom iterators
get "a conservative borrow error." But §11.7's own philosophy is that
library types opt into language behavior through known traits.

Crux tensor views, Weld dataset iterators, Smallhold ECS queries are
all custom iterators. They will all hit the conservative tier where
`let a = it.next(); let b = it.next()` conflicts. User libraries will
permanently feel worse than std — the opposite of the pitch.

The machinery to fix this already exists in spirit: §21.1 Rule 6 tracks
returned-view origins through functions. It needs one more rule —
origins may pass *through* an iterator struct to the collection it
borrows — available to user types by inference, not annotation.

**Implementation status (2026-06-09):** Better news than the spec
admits — the mechanism is an **attribute, not compiler magic**.
For-loops special-case ranges, slices/arrays, Vec, and
`iter()`/`iter_ref()`/`iter_place()`, then fall back to a generic
`next()` protocol (`src/MirLower.w:3760-3890`); user types implementing
`Iter[T]` (`lib/std/traits.w:48-49`) already work in for-loops
(`test/spec/spec_ss13_2_iterator_borrowing.w`). The borrow-origin link
is `@[iter_of_self]` (`lib/std/traits.w:71-73`, per docs/mut.md §15.8):
it registers a shared borrow on the receiver's place root for the
duration of the call, currently applied only to stdlib iterator
constructors (`test/compile_errors/err_iter_of_self_vec_iter.w`). So
the fix for this item is largely *spec and stdlib-policy* work:
document `@[iter_of_self]` (or an inferred equivalent) as part of the
language surface available to any library's iterator constructors, and
add a conformance test on a non-stdlib type. The spec's "built-in
knowledge of stdlib iterators" framing undersells what is actually a
generalizable mechanism.

### 6. `[]mut T` is load-bearing for Crux and has one line of spec

§3.1 stakes the flag on "no `&mut T` in safe code." §4.8a then
introduces `[]mut T`, an exclusive mutable slice — a mutable borrow by
another spelling — with no aliasing rules anywhere:

- Does creating a `[]mut T` invalidate `&T` views (presumably, per
  §21.1 Rule 1)? State it.
- Can one be split into disjoint halves (`split_at_mut` — Crux needs
  this on day one for tensor tiling)?
- How does `[]mut T` interact with the call-mode question (item 1) in
  parameter position?

A tensor/compute library is made of mutable views. This needs a real
subsection before Crux's API hardens around guesses.

**Implementation status (2026-06-09):** Plain slices are real: `[]T`
parses (`src/Parser.w:6698-6739`, `NK_TYPE_SLICE`), slices lower as fat
pointers (`src/TypeLayout.w:295, 340`), indexing goes through place
projection, and slice iteration works (`test/behavior/behav_slice.w`).
The `[]mut T`-specific story is thin: exclusivity is whatever generic
place-based borrow checking provides (touch points at
`src/SemaCheck.w:5789`, `src/Mir.w:1803`), there are no
`split_at`/`split_at_mut` operations anywhere in `lib/std/`, and no
`[]mut`-specific aliasing tests exist. The spec gap and the
implementation gap are the same gap — Crux will hit both at once.

---

## B. Over-optimism — the machinery cannot deliver the promise as written

### 7. Inference-with-no-escape-hatch needs a diagnostics contract

The spec promises "the compiler is smart" (§1.1) and declares false
rejection "compiler precision debt, not user ceremony" (§22). The
no-annotation stance is the product — keep it. But the honest
consequence: when origin inference fails, the diagnostic is the only
thing standing between the user and quitting, because they cannot
annotate their way out.

The precedent already exists: the NLL work spec'd a three-location
diagnostic (§15.6 / P6, May 2026). Promote it to a normative pattern:
every ephemeral/origin rejection must name (a) where the value was
borrowed, (b) where it escapes, (c) the idiomatic fix
(clone / collect / handle / scope). Make diagnostic quality a spec'd
deliverable, not a hope.

**Implementation status (2026-06-09):** The precedent is real and
shipping: the §15.6 view-liveness diagnostic emits three labeled
locations — mutation site (primary), "view created here," "view used
here" (`src/SemaCheck.w:11797-11809`). Caveats the spec should absorb:
NLL is implemented as last-use AST analysis, not CFG dataflow, and
`src/BorrowCfg.w:22-29` documents the uncovered cases
(branch-divergent uses, loop-iteration carry). More importantly,
**returned-view origin tracking (§21.1 Rule 6) is not implemented at
all** — ephemeral checking today is type-level only
(`src/SemaCheck.w:12830-12861`) plus task-specific escape checks.
That means the diagnostics contract can be written *before* the origin
subsystem is built, which is exactly the right order.

### 8. The modeled c_import surface implicitly depends on a curated contracts corpus nothing names as a project

§16.3c's `fopen(path, mode)` example requires the binding to know the
callee does not retain the pointer. Non-retention is unprovable from a
bare prototype; it comes from metadata. So the day-one ergonomics of
"C functions just call when modeled" (§16.1) are gated on someone
writing contract annotations for libc, SQLite, Raylib, etc.

The architecture degrades gracefully (raw surface remains), but the
*experienced* ergonomics for the launch audience equal the size of the
curated corpus. Name it as a deliverable — an annotated libc overlay
alone would carry the flagship demos. Otherwise they will be full of
raw-surface calls that make the §16.1 pitch look aspirational.

**Implementation status (2026-06-09):** The implementation is already
honest — which *proves* the corpus point. Commit 1373e453 implements
safe/raw surfaces: an imported function is classified raw if it is
variadic or its signature contains pointer or function types
(`ci_function_requires_raw_abi`, `src/SemaDecl.w:461-496`, tracked in
`ci_raw_syms`), and calling a raw binding requires `unsafe`
(`test/compile_errors/err_c_import_raw_call_requires_unsafe.w`).
`str` → `*const c_char` coercion is contract-gated — provably
NUL-terminated values only; f-strings are rejected
(`test/compile_errors/err_c_import_str_to_c_char_requires_contract.w`,
`docs/completed/c-import-auto-coercion.md`). The March-era
name-heuristic auto-defer for destructor pairs was **removed**, in
line with §16.2a's ownership-evidence rule. Net consequence: today
essentially every pointer-taking C function — including the spec's own
`fopen(path, mode)` example in §16.3c — is on the raw surface and
requires `unsafe`. The "C functions just call when modeled" experience
currently exists only for value-typed signatures. The contracts corpus
is not an enhancement; it is the entire distance between the shipping
compiler and the §16.1 pitch.

### 9. §14.19's stack story promises two hard things at once

Growable/segmented stacks *plus* §14.13's "semantic stack preservation"
(safe references survive relocation) is GC-grade engineering — precise
stack maps for every frame. Go abandoned segmented stacks over exactly
these cliffs.

The spec already half-allows the sane v1 answer
("implementation-defined"). Make it explicit that fixed-size pooled
stacks with guard pages are a *conforming* implementation, so the
promise users rely on is the conservative one and growth is an upgrade,
not a debt.

**Implementation status (2026-06-09):** Confirms the recommendation
exactly. Fiber stacks are **fixed 64 KB** plus a guard page, mmap'd
(`rt/fiber_core_darwin.w:27` `FIBER_STACK_SIZE = 65536`, allocation at
`:345-352`) and pooled via a free list (`:354-407`, with
`with_fiber_pool_reuses`/`_allocs` counters at `:701-705`). Not
growable; no 8 KB initial allocation; no `with.toml`
`fiber_stack_size` config; no FFI stack switching; no `@[ffi_stack]`;
no `ffi_reachable` analysis. (`docs/feature_plans/async-proposal.md:18-26` floats a
minicoro migration for growable stacks later.) `may_suspend` analysis
and the E0701 guard checks are implemented at compile time
(`src/SemaCheck.w` `fn_symbol_may_suspend`, `src/MirSuspendCheck.w`).
§14.19 currently reads as documentation of features that do not exist;
respec the implemented model as conforming and move growth/FFI
switching to roadmap status.

### 10. Promised-but-absent rules

- §15.3 invokes a "documented deterministic elision rule" for
  string-literal allocation that participates in no-allocation
  checking. The rule itself is never given. Until it is, this is a
  TODO wearing spec clothing.
- §14.11.1's combinators guarantee "cancels and joins losers before
  returning." A loser parked in a long synchronous computation makes
  `await_first` block for the duration of the slowest loser. The
  semantics are fine; the contract should state the latency
  consequence.

**Implementation status (2026-06-09):** String literals lower
uniformly to `CK_STR` constant operands (`src/MirLower.w:1770-1776`);
no elision analysis exists — the promised rule has neither
documentation nor implementation. The await combinators all exist in
`lib/std/task.w` (`await_all` `:22-44`, `await_first` `:61-77`,
`await_any` `:81-105`, `await_settled` `:108-119`) and do implement
cancel-and-join-before-return, so the slowest-loser latency behavior
is live today, not hypothetical. Tuple `.await`
(`FIBER_TUPLE_AWAIT`), `select await` (`FIBER_SELECT`/`_BIASED`), and
`async scope` + `s.track()` (`rt/rt_core.w:2766-2839`) are all
implemented. (Side note from the survey: `docs/feature_plans/async-proposal.md`
records a known bug — `with_scope_track` reallocating its tracking
buffer while the caller holds the old handle.)

---

## C. The mission cuts against these — BDFL's call

### 11. Implicit default return (§4.10), narrowed

A function declared `-> i32` whose body ends in a Unit statement
silently returns `0`. The elided thing here can *matter*: the author
may have computed a value and forgotten to return it; `0` was never
stated. Mission-true refinement: only fire when the body contains no
explicit `return expr` / non-Unit tail anywhere. A function that
visibly produces values elsewhere but falls off the end is far more
likely a forgotten return than a desired default.

**Implementation status (2026-06-09):** Already much narrower than the
spec: implicit default return is implemented for void/bool/integer
returns only (`lower_implicit_default_return`,
`src/MirLower.w:7440-7445`; comptime path
`src/ComptimeEval.w:905-916`) — not for general `Default` types
(`str`, `Option`, `Vec`, user `@[derive(Default)]` types). The spec
promises more than the compiler does. Narrowing the spec (or adding
the "no explicit return anywhere" gate) costs almost nothing because
the general behavior never shipped.

### 12. No-shadowing (§29.8)

The mission says don't make the user write what doesn't matter — and a
shadowing ban makes users invent throwaway names (`s`, `s2`,
`trimmed`) the compiler doesn't need. Pipelines absorb some of it, but
narrowing rebinds (`let x = parse(x)?`) are the most common shadow and
are not pipeline-shaped. If the ban exists to protect generated/AI
code from itself, that is a legitimate reason — but then it is a
lint-level policy, arguably not a language law.

**Implementation status (2026-06-09):** Fully implemented and
uniformly enforced — "shadowing is not allowed for '<name>'" across
let/var bindings, for-loop bindings, match pattern bindings,
with-block bindings, and globals (`src/Sema.w:2513-2574`; check sites
at `src/SemaCheck.w:4505, 5244, 6653+, 7362`), with `let _` exempt as
a discard binding. Demoting to a lint is pure policy; no engineering
blocker.

### 13. Statement-position partial match (§9.7)

Silent no-op for unmatched variants means adding an enum variant later
silently skips existing statement matches — a real mistake-class the
diagnostics philosophy says should be caught. It can be caught without
ceremony: "non-exhaustive statement match" as a default-on *warning*
(not error) costs nothing to those who mean it.

**Implementation status (2026-06-09):** As spec'd — partial
statement-position match compiles silently for non-must_use types
(`test/behavior/partial_match_stmt.w`). The exhaustiveness checker
already computes the position (`match_in_stmt_pos`,
`src/SemaCheck.w:6072-6080`) and the missing-variant analysis already
runs for the must_use case, so a default-on warning is a small
addition at an existing decision point.

**Revised (2026-06-09, second pass): retracted as written.** A
default-on warning fires on every intentional subset-match statement
— the C-switch-without-default pattern is common and legitimate, and
warning fatigue is its own form of suffering. The mission-
proportionate remedy for the added-variant maintenance bug is an
opt-in lint (or a `with check` CI flag), not a default-on diagnostic.
The failure mode stands as documented; the remedy is downgraded.

---

## D. Spec hygiene (cheap fixes; they matter now that the spec is the requirements-traceability source)

1. **Two enum syntaxes coexist in the spec — the compiler accepts only
   one.** The parser accepts `enum` forms only: block, braced inline,
   and discriminant enums (`src/Parser.w:1436-1519, 1752-1877, 2092+`);
   `type X = A | B` is explicitly **rejected** with a "use 'enum'"
   diagnostic (`src/Parser.w:1310-1317`). §10.1's `Result`/`Option`
   definitions and the §30.3 grammar show syntax the compiler
   deliberately rejects. Rewrite the spec to the `enum` forms.

   **Ruling opinion (mission-grounded): the implementation is right;
   the spec text is stale (pre-v6 leftovers — §4.4, the primary enum
   section, already says `enum`).** This is a genuine taste call —
   `type X = A | B` is more uniform with `type` already handling
   structs/aliases/distinct/opaque; `enum` is more learnable — but
   three things tip it decisively to `enum`, all mission-flavored.
   (1) Diagnostics: `enum` gives the parser an anchor token, so errors
   on malformed sum types can be precise; an overloaded `type ... =`
   head forces lookahead and yields mushier messages, and diagnostic
   quality is load-bearing for With (item 7). (2) The discriminant
   form `enum Color: i32:` — which C migration depends on — reads
   naturally under `enum` and awkwardly under `type =`; one keyword
   covering both plain and discriminant sum types beats two-and-a-half
   spellings. (3) The implementation already rejects the old form
   *with a directed error* ("use 'enum'"), which is the correct
   migration behavior; reverting now would churn every existing user
   for a uniformity win nobody feels. Sweep the stragglers: §10.1's
   `Result`/`Option`, §11.7's `ParseResult`, §30.3's grammar. (While
   sweeping, note the stdlib uses an `=` body introducer —
   `pub trait Iter[T] = ...`, `impl Iter[Token] for TokenStream = ...`
   in `lib/std/traits.w` — that §29.13's three body forms never
   mention; either spec it as a fourth form or migrate the stdlib to
   `:`.)
2. **Reserved-word lists are wrong in both directions.** Actual lexer
   keywords (`src/Token.w:167-225`) vs the spec: `is`, `mod`,
   `import`, `sealed`, `struct`, `newaxis` (§30.9) and `implicit`
   (§29.11) are **not** keywords. Conversely `spawn` **is** a live
   keyword with a live AST node — `NK_SPAWN` is exempted from the
   E0801 unused-task check (`src/SemaCheck.w:4384`) — yet the spec's
   concurrency model never defines a `spawn` construct. Either spec it
   or remove it; an undocumented keyword with task-disposition
   semantics is a conformance hole, not just hygiene.
3. **`usize` missing from §4.1; `isize` missing from the spec
   entirely.** Both are implemented as 64-bit types with literal
   suffixes (`src/Sema.w:582-583, 1248-1249, 2156-2162`).
4. There are two §18.7 sections (Freestanding Mode and Package
   Management). Spec-only.
5. **§30.4's `let [ 'mut' ]` grammar is wrong.** The parser explicitly
   errors: "'let mut' is not supported; use 'var' for mutable
   bindings" (`src/Parser.w:2358-2360`).
6. **§14.21's example uses `->` for match arms and does not compile.**
   Match arms require `=>` (`src/Parser.w:5494` expects
   `TK_FAT_ARROW`).
7. §15.4.5's f-string examples use `'hello'` single-quoted strings —
   illegal per the spec's own lexer rules (§29.5a) and the
   implemented lexer (single quote begins a char literal or label).
8. **`impl Iter[T]` opaque return types describe a type form the
   language doesn't have.** Generators are fully implemented as state
   machines (`src/MirLower.w:9034-9258`, codegen at
   `src/Codegen.w:2704-2770`), but the return value is a concrete
   generated state struct with a `next()` method — there is no general
   `impl Trait` feature. Spec the actual mechanism.
9. §14.11 cites "§4.6 tuple arity limits"; §4.6 is Type Inference.
   Spec-only.
10. **Implicit main does not exist as a language feature.** It exists
    only as CLI one-liner source synthesis (`src/main.w:525-559`);
    ordinary modules require `fn main`
    (`src/Parser.w:687`). §18.5b's reference to "the normal
    implicit-main feature" points at a feature that exists nowhere
    else. Either implement top-level statements for normal files or
    reword §18.5b.
11. **Modules: `pub` visibility is recorded but not enforced.**
    `module x.y` parses optionally (`src/Parser.w:693-709`); `use`
    resolution searches the embedded stdlib then filesystem paths
    (`src/Resolve.w:937-997`); but visibility is only cached
    (`src/Sema.w:1323-1349`) — **no error is emitted for accessing a
    private symbol from another module.** This is a conformance gap
    (§18.3 "No `pub` = module-private"), not just thin spec text, and
    it matters before external collaborators start consuming `pub` API
    surfaces as contracts. The module-system section (§18.1–18.3,
    ~10 lines) also still needs real content: file↔module mapping,
    nested visibility, re-exports.
12. §22.1 Rules 4 and 6 state the same restriction twice (ephemeral
    field in non-ephemeral struct). Spec-only.
13. §14.10 `select await`: branch patterns are described as bindings
    (refutable handling pushed into the body via `let ... else`), yet
    the section also says non-matching patterns panic "same as a
    non-exhaustive match" — if patterns are irrefutable bindings, the
    panic clause is dead text. (Implementation note: `select await` is
    implemented via `FIBER_SELECT`/`FIBER_SELECT_BIASED` intrinsics,
    `src/MirLower.w:5945+`, `rt/fiber_runtime.w:156-172`.)
