# Problematic Requirements Audit

This file records a methodical audit of all 2,567 generated requirements in
`docs/requirements.md` against the With philosophy and the specification as a
whole.

This audit was rechecked against `docs/mission.md`. An objection does not
belong here if it merely preserves ceremony, makes the user spell something the
compiler can safely infer, or weakens the core `with init` / `with get c.*` /
`with migrate` experience. The entries below survive that check because they
either preserve safety, remove stale architecture claims, or ask the compiler
to prove more instead of asking the user to write more.

Absence from this file means the requirement was not flagged by this audit.
It is not a permanent proof that the requirement can never be revised, but it
does mean this pass did not find a true contradiction, stale architecture
claim, unsafe broad wording, or philosophical mismatch worth listing.

"Problematic" means one of:

- the requirement contradicts another normative part of the spec
- the requirement is stale relative to the compiler architecture
- the requirement captures an example, slogan, heading, or informative note
  as if it were normative
- the requirement is directionally right but too broad to implement safely

## 1. Absolute "no unsafe" / "zero explicit memory management"

Affected requirements:

- `1.1.1.23` - `No unsafe.`
- `1.1.1.24` - `Zero explicit memory management, fully statically typed, native-compiled, memory-safe.`

Argument:

These are good marketing shorthand for the common-case user experience, but
they are not valid global requirements. The same section says that when users
hit a genuine edge case, `unsafe` is available. Later sections explicitly
define unsafe contexts, raw pointers, inline assembly, intrusive structures,
manual memory management beyond allocators, and unsafe functions.

The With philosophy is not "unsafe does not exist." It is: hide unsafe and
explicit resource machinery from the 90% path, keep it available for the 10%
path, and make the boundary visible when the operation is actually dangerous.
Turning these slogans into absolute requirements would remove exactly the
systems-programming escape hatch the language promises.

Preferred requirement shape:

- Safe code should not require `unsafe` or explicit memory-management ceremony
  for ordinary application code.
- Unsafe operations remain available behind explicit unsafe boundaries.
- Allocation should be ergonomic, but allocator-aware and manual-memory APIs
  remain part of the systems surface.

BDFL Ruling:  Correct.  unsafe is very much a part of With.  Implementation is correct; Spec is stale and needs updated.

## 2. "Warnings, not blocking" as a global compiler rule

Affected requirement:

- `1.1.1.14` - `Trust the programmer. If you write something weird, the compiler warns you. It doesn't block you. You're an adult.`

Argument:

This is the right posture for weird-but-safe code. It is not the right global
rule for a language that promises memory safety, no data races, visible
suspension, and loud failure when code cannot be generated correctly.

The spec repeatedly requires hard errors: use-after-free, double-free, data
races, unsafe operations outside unsafe contexts, non-exhaustive
expression-position matches, invalid `@[tailrec]`, escaping ephemeral values,
no-await guards across suspension, unused `Task`, and many others. Those are
not violations of "trust the programmer"; they are the compiler keeping the
semantic contract.

Preferred requirement shape:

- Warn for unusual code when the program remains safe and the compiler can
  preserve the programmer's meaning.
- Reject code when accepting it would violate safety, ownership, concurrency,
  determinism, or code-generation correctness.

BDFL Ruling:
This is not a rule but rather a rule-of-thumb.  We DO want to be EXACTLY AS SAFE as Rust - but we do so by automatically choosing sensible DEFAULTS instead of FORCING the user to specify everything up front.  I am ok if we update the spec to reflect this.  The spec is pontificating here.


## 3. `if then` and unmarked `else expr` bodies

Affected requirements:

- `9.1.1.7` - `if supports four body forms.`
- `9.1.1.9` - `The then form is strictly an expression form: if cond then expr.`
- `9.1.1.10` - `The body after then is a single expression (not a block), and the else clause is else expr with no body introducer.`
- `29.11.1.9` - `then; Inline if body introducer (expression form)`
- `29.13.1.6` - `if additionally supports the then expression shorthand; see Section 9.1 for the full if syntax.`
- `29.13.1.23` - `For if, then is also a valid body introducer (see Section 9.1).`
- `30.8.1.2` - `if and else if additionally accept then EXPR.`

Argument:

These requirements conflict with the cleaner direction for With block syntax:
every branch body should have an explicit body marker. The body marker can be
`:` for inline or indented colon bodies, or `{` for brace bodies. A naked
`else expr` exception makes `else` behave unlike every other block arm and
reintroduces a grammar/readability problem the block system otherwise solves.

`then` also creates a fourth spelling that is specific to `if`, while the rest
of the language has converged on the three universal body forms. That is extra
surface area for the 90% path without adding capability. It also weakens the
relationship between `if` and `match`: both should make the boundary between
condition/pattern and result visible.

This is not an argument for extra ceremony. The mission argues against making
users write unnecessary characters, but it also argues for a coherent surface
where the compiler pays complexity so users do not have to remember special
cases. `:` and `{` already provide the explicit consequent marker for all block
forms. A separate `then` spelling and a naked `else expr` exception make the
common path larger, not smaller.

Preferred requirement shape:

- `if condition: expr`
- `if condition: NEWLINE ...`
- `if condition { ... }`
- `else if condition` follows the same body rules.
- `else` also requires a normal body marker: `else: expr`, `else: NEWLINE ...`,
  or `else { ... }`.
- No naked `if condition expr`, no naked `else expr`, and no separate `then`
  body form.

  BDFL Ruling: Yes - if form has evolved since the spec was written.  The Implementation is correct.  The Spec is wrong, please udpate it to match the current compiler implementation.

## 4. FFI unsafe boundary stated too broadly

Affected requirements:

- `1.7.1.17` - `C functions just call - c_import functions are callable directly. No unsafe {} wrapper on every FFI call.`
- `16.1.1.14` - `Why no unsafe on every call?`
- `16.1.1.17` - `Wrapping every call in unsafe {} is ceremony without safety.`
- `16.1.1.20` - `But calling an imported C function that takes normal arguments is just a function call.`
- `19.2.1.3` - `FFI function calls`

Argument:

The intended design is good, but the requirements need sharper boundaries.
The `c_import` section says calls generated by `c_import` are callable
directly because the import itself is the opt-in and With's C-interop
ergonomics matter. That is consistent with the language philosophy.

But Section 16.3 and Section 19 also say extern/FFI calls require `unsafe`.
As written, `19.2.1.3` reads as "all FFI function calls require unsafe",
while Section 16.1 says `c_import` calls do not. The broad wording also hides
the important distinction between calling a generated binding and performing
raw pointer operations around it.

Preferred requirement shape:

- Calls through `c_import` bindings are direct calls by default.
- Manual `extern "C"` declarations and calls remain unsafe unless explicitly
  modeled otherwise.
- Raw pointer dereference, pointer indexing, transmutes, and other unsafe
  memory-touching operations remain unsafe even when the pointer came from a
  `c_import` function.
- The unsafe boundary for C interop is the wrapper API and the operations that
  actually perform unsafe memory effects, not a blanket wrapper around every
  imported call.

BDFL Ruling: Accept with stronger clarification.

The statement “all FFI calls are unsafe” is wrong for With.

I do not want normal `c_import` functions to be marked unsafe. That would recreate Rust’s FFI ceremony and directly violate With’s purpose. `c_import` exists so that C libraries can feel like ordinary With libraries whenever the compiler can model their contracts.

The correct boundary is not “foreign call = unsafe.” The correct boundary is “unmodeled memory, ownership, or lifetime contract = unsafe or unavailable as a safe surface.”

For `c_import`, the compiler has three jobs:

1. Import the raw ABI accurately.
2. Model every contract it can infer, import, or prove into a safe With surface.
3. Refuse to present unmodeled danger as ordinary safe code.

A generated `c_import` binding should be directly callable by default when the importer has modeled the call sufficiently: value parameters, value returns, safe handle wrappers, slice parameters for buffers, `Option` for nullable returns, owned resource wrappers with `Drop`, `CStr`/`CString` for C string contracts, and so on.

For C APIs such as `memcpy`, `strcpy`, `free`, out-parameter fills, borrowed pointer returns, ownership transfers, or mutable buffers, the unsafe effect may occur at the call boundary. The answer is still not to mark all C calls unsafe. The answer is for the importer to generate a safe wrapper when it can model the contract, and to keep the raw ABI surface explicit when it cannot.

So `memcpy(dst, src, n)` should not become a casually safe raw pointer call. It should become a safe slice-oriented wrapper if the contract is known, or remain part of the raw/low-level/migration surface when the contract is not modeled.

Unsafe remains available for the cases With must support: raw pointer dereference, raw pointer indexing, transmutes, inline assembly, manual extern declarations, unmodeled ownership/lifetime assumptions, and low-level migration code that cannot yet be expressed safely.

Spec update: remove blanket “FFI calls require unsafe.” `c_import` calls are safe and direct when the generated binding models the contract. Unmodeled raw ABI calls remain available for systems work and migration, but they are not the normal safe `c_import` surface.


## 5. Stale `c_import` toolchain dependency requirements

Affected requirements:

- `16.1.1.25` - `The C toolchain is a dependency.`
- `16.1.1.26` - `c_import invokes the system C compiler's preprocessor ...`
- `16.1.1.27` - `The With compiler then parses the preprocessed output.`
- `16.1.1.28` - `Cross-compilation limitation: Unlike Zig (which embeds Clang), With's Phase 0 c_import depends on the host system's C toolchain.`
- `16.1.1.29` - `Cross-compiling for a different target requires a cross-compiler ... configured in with.toml.`
- `16.1.1.30` - `Phase 2+ may embed a C header parser to eliminate this dependency and enable self-contained cross-compilation.`

Argument:

These requirements describe an older Phase 0 architecture. They now conflict
with the repository's self-contained toolchain invariant: With builds and
embeds its own static LLVM/Clang/lld SDK resources, and normal compiler
operation must not depend on a system LLVM or a system Clang resource
directory. The spec should not require `cc -E` as the core `c_import` path or
frame embedded parsing as a future possibility when the compiler architecture
has already moved in that direction.

There may still be host-target realities for C interop, such as system libc
headers, SDK/sysroot discovery, and target platform headers. That is different
from saying the compiler depends on the host system C compiler as its
preprocessor or that cross-compilation fundamentally requires an external
cross-compiler.

Preferred requirement shape:

- `c_import` uses the compiler-owned Clang/header parsing path and embedded
  compiler resources.
- Target C headers and platform SDKs are target inputs, not a dependency on a
  random system LLVM/Clang installation.
- Any remaining shell-out to host tools must be called out as a temporary
  implementation gap, not a language requirement.


BDFL Ruling:
Correct.  The spec is stale.  c_import is now fully implemented, please make the spec reflect the current implementation

## 6. Task discard severity is internally inconsistent

Affected requirements:

- `14.1.1.5` - compiler emits a warning when an ephemeral `Task` is implicitly dropped without await/cancel.
- `14.7.1.21` - compiler emits a warning for `let _ = <Task expression>`.
- `20.2.2.4` - compiler warns about `let _ = send_analytics(...)`.

Related requirement I agree with:

- `14.7.1.11` - dropping a `Task` without awaiting or explicitly cancelling it is a compile error.

Argument:

The spec has two incompatible severity models. One model says unused `Task` is
a compile error because dropping a task cancels work and is a common source of
concurrency bugs. The other model says some forms of dropping a task only
warn.

The stricter model fits With's philosophy better. A dropped `Result` does
nothing, so requiring ceremony to discard it would be wrong. A dropped `Task`
cancels work, and an ephemeral task may even yield during cleanup to preserve
memory safety. That behavior matters. The language should require an explicit
semantic choice: await it, spawn it, or cancel it.

Preferred requirement shape:

- An unused `Task` expression is a compile error.
- `let _ = <Task expression>` should not be the blessed discard form for
  cancellation. Use `cancel(task)` or another explicit cancellation/discard
  primitive.
- If `let _ = <Task expression>` remains legal, the spec must clearly explain
  why it is sufficient explicit cancellation and how that differs from the
  compile-error case. Right now the distinction is not coherent.

BDFL Ruling: Modify.

The "every unawaited task is an error" model is too strict for With, and it
fails the mission for the same reason the audit's other fixes succeed: it
removes a hazard that isn't there at the cost of ceremony that is.

Starting work without observing its completion is a legitimate program.
Logging, analytics, telemetry, cache warming, and best-effort background writes
are real. With must not force `let _ = task` or `.detach()` to say what a bare
statement already says.

The organizing principle is intent, expressed by position:

- A task in **statement position** is a declaration of intent to detach,
  subject to the must-observe and detach-safety checks below.
  `send_analytics(event)` means: start the work, do not await it, discard
  interest in its result or failure. That is the ordinary meaning of
  expression-statement position applied to a task-producing expression. It is
  not an accidental drop, and the programmer should not write an extra character
  to confirm it.
- A task **bound to a name** is a declaration of intent to observe. `let t =
  send_analytics(event)` says "I will use this," so losing `t` unused is a bug
  signal, not a detach. The same call is therefore legal as a bare statement and
  illegal as an unused binding — not arbitrarily, but because binding and
  statement position declare opposite intents.

What makes bare detachment safe rather than a footgun is the combination of two
independent checks, both of which must permit it:

1. **must-observe**, decided by the API author: may completion and failure be
   ignored?
2. **detach-safety**, proven by the compiler: may the task safely outlive the
   current scope?

The author decides observability because the caller often cannot know whether
ignoring a result or a failure is valid, while the function's author can. A task
left unmarked is, by its author's choice, best-effort with respect to
completion and failure. The compiler independently decides lifetime safety: a
task may be detached only if it does not carry borrowed stack data, ephemeral
captures, or scope-bound resources out of the scope that owns them. Author
intent never substitutes for the lifetime proof, and the lifetime proof never
overrides author intent. Both gates must clear.

A bare task statement is therefore the detach spelling — there is no separate
`detach()` and no `let _ =` — permitted exactly when both checks pass. When
either fails, the bare statement is a compile error, and the diagnostic must
name which check failed, because the remedy differs:

- A must-observe failure is fixed by awaiting, cancelling, propagating, or
  otherwise handling the task. Detachment was structurally possible; the author
  forbade it.
- A detach-safety failure means detachment is unsafe: the task captures
  borrowed stack data, an allocator-borrowed or scope-bound resource, depends on
  structured-concurrency scope cleanup, or cannot be proven to outlive the
  scope. The fix is to await, cancel, return, or restructure so the task no
  longer carries scope-bound state out of scope.

So the rule is not "unawaited tasks are errors." The rule is:

- A task in statement position is intentional fire-and-forget, allowed when both
  the must-observe and detach-safety checks permit it; otherwise it is a compile
  error.
- A task bound to a name must eventually be awaited, cancelled, returned, stored
  (when non-ephemeral), or otherwise given a valid disposition. An unused bound
  task handle is a compile error.
- `let _ = <Task expression>` is not required and is not the canonical spelling
  for fire-and-forget. Statement position already expresses it.

This narrows requirement `14.7.1.11`. "Dropping a `Task` without awaiting or
cancelling is a compile error" is correct for a *bound* handle lost unused, and
for any task that fails either detachment check. It is not correct for a bare
statement that clears both checks — that is not "dropping" in the bug sense, and
treating it as an error is precisely the ceremony this ruling removes.
`14.7.1.11` must be reworded to apply to bound-handle loss and to failed
detachment checks, not to all unawaited tasks.

Spec update: replace the warning-only task-discard rules (`14.1.1.5`,
`14.7.1.21`, `20.2.2.4`) and narrow the blanket error rule (`14.7.1.11`) with a
single task-disposition rule governed by two checks. A bare task statement is
fire-and-forget when the author has not marked it must-observe and the compiler
proves it safe to detach. An unused bound task handle is a compile error.
Ephemeral, scope-bound, must-observe, or otherwise unprovable tasks cannot be
detached and must be awaited, cancelled, returned, or handled within their valid
scope.

This is the With philosophy applied to concurrency, and it preserves both
mission clauses:

**No ceremony to discard what statement position already discards.**
**No silent loss of work the compiler — or its author — knows must complete.**

## 7. Informative grammar appendix treated as normative requirements

Affected requirements:

- `30.1.1.1` through `30.1.1.9`
- `30.2.1.1` through `30.2.1.4`
- `30.5.1.1` through `30.5.1.14`
- `30.8.1.1` through `30.8.1.3`
- `30.9.1.1`

Argument:

Section 30 explicitly says it is informative and that normative definitions
remain in their respective sections. The requirements matrix should not treat
that appendix as an independent source of normative requirements.

This matters because the appendix can duplicate, summarize, or drift from the
real normative sections. For example, the appendix repeats the `then EXPR`
conditional form that is already problematic above. If Section 30 is kept as
a convenience index, traceability can cite it as related context, but it should
not create standalone requirements.

Preferred requirement shape:

- Exclude Section 30 from normative requirement extraction, or mark all Section
  30 entries as informative trace links only.
- For grammar requirements, point to the normative sections that define the
  construct.

BDFL Ruling:
Agreed.  Update the spec and requirements.

## 8. Mixed-width bitwise promotion bypasses numeric conversion rules

Affected requirement:

- `4.2.4.2` - `Mixed-width operands are promoted to the wider type.`

Related requirements I agree with:

- `4.2.6.1` - implicit widening is only allowed for lossless numeric conversions.
- `4.2.6.6` - no other implicit numeric conversion is allowed.
- `4.2.6.9` - signed/unsigned conversions require `as`, even at the same width.

Argument:

The bitwise requirement is too broad. "Promoted to the wider type" is harmless
for `u8 | u32` and `i8 & i32`, but it becomes wrong for mixed signedness and
same-width signed/unsigned cases. The numeric conversion section is explicit:
With does not inherit C's silent integer-conversion traps, and signed/unsigned
conversion requires intent.

Preferred requirement shape:

- Bitwise operands may be implicitly widened only when the conversion is
  permitted by the ordinary lossless numeric-conversion rules.
- Mixed signedness that cannot be converted losslessly requires an explicit
  `as`.
- The result type is the common type selected by those rules.

BDFL Ruling: Accept the flag; modify the rule.

`4.2.4.2` ("mixed-width operands are promoted to the wider type") is too broad,
as the audit says. But the fix is neither the arithmetic common-type rule nor
third-type widening (`u32 | i32 -> i64`). Both import a value-preserving
invariant into an operation that is not about values.

The principle: **a bitwise operator preserves bit patterns, not numeric
values.** `+ - * /` produce a number, and value-preserving widening is exactly
right for them. `& | ^` produce a bit pattern, and the only widening that does
not silently change which bits participate is widening within a single
signedness — zero-extension for unsigned, sign-extension for signed. Those are
the type's own definition of "the same value in more bits," and within one
signedness there is no ambiguity about what the high bits mean.

Across signedness there is no bit-pattern-preserving common type, because the
operands disagree about the meaning of the high bit. Widening `u32 | i32` to
`i64` does not reconcile them; it zero-extends the `u32` and sign-extends the
`i32`, so whenever the `i32` is negative the result's upper 32 bits fill with
ones the programmer's 32-bit idiom never intended. That is the C
integer-promotion trap in a lossless costume: the operand *values* are
preserved and the operation's *meaning* is not. It also silently doubles a
32-bit operation to 64-bit — a hidden cost a systems programmer would not
expect from `|`.

This is settled by With's own rule about casts. A cast in a bitwise expression
is meaningful: it says "interpret these bits as signed or unsigned at this
width," which is information the compiler does not have. Mixed signedness in a
bitwise op *is* exactly that missing information. So the cast is required, not
ceremony — forcing `(a as i32) | b` is clause one working correctly, because
the compiler genuinely does not know the intended interpretation, and
auto-widening to `i64` would be a clause-two failure: a silent representation
choice that reinterprets bits. The proposal removes a cast that was carrying
real information and replaces it with a guess.

The rule for `& | ^`:

1. An untyped integer literal adopts the other operand's type and is valid iff
   its bit pattern fits that operand's WIDTH, not iff its signed value fits the
   operand's range.
       `u32 | 0xff` -> `u32`        `i8 & 0xff` -> `i8`
       `i8 & 0x1ff` -> error (9-bit pattern in an 8-bit operand)
   (`i8 & 0xff` is the canonical low-byte mask. Asking "does 255 fit in i8?" is
   the value question; for a bitwise op the bit pattern is what matters, and an
   8-bit pattern fits an 8-bit operand. It must compile.)
2. Two typed operands of the SAME signedness, different widths: widen to the
   wider type (zero-extend unsigned, sign-extend signed).
       `u8 | u32` -> `u32`         `i8 & i32` -> `i32`
3. Two typed operands of DIFFERENT signedness: require an explicit `as`. No
   third-type widening. The cast supplies the interpretation the compiler does
   not have.
       `u32 | i32` -> error; write `(a as i32) | b`, `a | (b as u32)`, or
       `(a as i64) | (b as i64)` per intent.
4. Result type = the common type from rule 2, or the cast-to type from rule 3.

Shift operators `<<` and `>>` are governed separately: the result type is the
left operand's type and the right operand is a count, so the common-type
question does not arise. This rule applies only to `& | ^`.

This keeps the requirements the audit endorsed intact. `4.2.6.1` (lossless
widening only), `4.2.6.6` (no other implicit conversion), and `4.2.6.9`
(signed/unsigned needs `as`, even at the same width) all stand; mixed-signedness
bitwise requiring `as` is exactly what `4.2.6.9` already implies for the
same-width case, now extended consistently to mixed-width.

Spec update: narrow `4.2.4.2`. Mixed-WIDTH promotion to the wider type holds
only within a single signedness. Bitwise `& | ^` preserve bit patterns:
same-signedness operands widen to the wider type; mixed-signedness operands
require an explicit `as`; untyped literals adopt the operand type by width-fit.
No implicit third-type widening for bitwise operators.

Note for separate ruling: whether *arithmetic* permits value-preserving
cross-signedness widening (`u32 + i32 -> i64`) is a distinct question with its
own cost and clarity tradeoffs. It must be decided on its own — bitwise must not
inherit that answer either way, because the bit-pattern argument above is
specific to `& | ^`.

This preserves both mission clauses:

**Same signedness widens freely — the bits are already determined.**
**Mixed signedness needs `as` — the bits are a choice the compiler cannot make.**

## 9. Fixed-size arrays are not always copied on assignment

Affected requirement:

- `4.3.2.4` - `Passed by value (copied on assignment). For large arrays, pass by reference.`

Related requirement I agree with:

- `4.3.2.6` - fixed arrays are `Copy` if the element type is `Copy`.

Argument:

This contradicts the ownership model. Assignment moves by default, and copying
requires `Copy`. A fixed-size array is a value type, but `[T; N]` cannot be
implicitly copied when `T` is not `Copy`. Otherwise arrays would become a
backdoor around move semantics for owning elements.

Preferred requirement shape:

- Fixed-size arrays are value types.
- Assignment and argument passing follow normal ownership rules.
- `[T; N]` is `Copy` only when `T` is `Copy`; otherwise assignment moves.
- Large arrays should generally be passed by reference for performance.

BDFL Ruling: Accept.
The spec is wrong as written. Fixed-size arrays are value types, but
they are not unconditionally copied on assignment. Arrays follow normal ownership
semantics: [T; N] is Copy only when T is Copy; otherwise assignment moves the
array. Large arrays should generally be passed by reference for performance, but
that is guidance, not a semantic exception. This preserves With’s rule: the
compiler eliminates ceremony only when the semantics are already known and safe.

## 10. `const` declarations require redundant type annotations

Affected requirements:

- `9.1.3.2` - `Syntax: const NAME: TYPE = EXPR`
- `9.1.3.3` - `The type annotation is required.`

Argument:

Requiring a type annotation for every `const` is out of line with With's core
ergonomic rule: do not make the user write what the compiler already knows.
The initializer often fully determines the type, especially for local and
private constants.

There are good reasons to require explicit types at public API boundaries or
when the initializer is ambiguous. That does not justify requiring ceremony in
all const declarations.

Preferred requirement shape:

- Allow `const NAME = EXPR` when the type is unambiguous from the initializer
  and context.
- Require or strongly prefer explicit types for public exported constants and
  cases where the literal/default type would be surprising.
- Keep `const NAME: TYPE = EXPR` available for API clarity and disambiguation.

BDFL Ruling: Accept.

## 11. Suspension points are described too narrowly

Affected requirements:

- `14.3.1.34` - a function is `may_suspend` if it directly contains `.await`, or calls any function whose body is `may_suspend`.
- `14.5.1.6` - `.await` is the only point where a fiber can suspend.
- `14.5.1.7` - suspension is always visible in the source code.
- `20.1.1.5` - suspension is always marked with `await`.

Related requirements I agree with:

- `14.3.1.39` - calling any `may_suspend` function while a `@[no_await_guard]` guard is live is a compile error.
- `14.3.1.48` through `14.3.1.52` - `no_suspend` rejects `.await`, calls to `may_suspend` functions, async-scope await-all, and implicit cleanup await.
- `14.17.1.6` - contended fiber-aware locks yield the fiber, not the OS thread.

Argument:

The visibility goal is right, but the absolute wording is wrong. The spec
itself defines scheduler-yielding operations beyond a syntactic `.await`:
calls to functions whose execution may suspend in the current fiber, async
scope await-all, implicit cleanup await for ephemeral tasks, and contended
fiber-aware lock operations.

The `may_suspend` rule also needs to distinguish "calling an async function"
from "calling a function that suspends in the current fiber." Calling an
`async fn` eagerly creates a `Task` and does not suspend the caller unless the
caller awaits or otherwise joins it. Treating every call to an async function
as a current-fiber suspension would contradict the no-colored-functions model.

Preferred requirement shape:

- `.await` is the primary explicit suspension operator and the only way to
  extract a `Task[T]` result.
- A current fiber may also suspend at operations the compiler classifies as
  `may_suspend`: calls to non-async functions that suspend in the current
  fiber, select/collection await, fiber-aware blocking primitives, and
  implicit cleanup await.
- Calling an `async fn` without awaiting the returned `Task` is not itself a
  current-fiber suspension.
- Diagnostics should name the operation that may yield, even when it is buried
  behind a call.

BDFL Ruling: Accept with clarification.

The audit is correct, but the issue is not merely that the wording around
`.await` is too absolute. This settles a real design fork, and the resolution
is forced by no-colored-functions.

**With does not choose syntactic suspension visibility. It chooses compiler
suspension visibility.** Requiring every possible suspension to be marked at the
call site is function coloring, which With rejects. In With, an ordinary-looking
same-fiber call may suspend if the callee is `may_suspend`; the programmer does
not mark that at the call site. The compiler already knows the transitive
suspension property, so making the programmer spell it everywhere would be
ceremony. "Suspension is always visible in the source" was never compatible with
no-colored-functions — not because of a few exotic operations, but structurally,
the moment an ordinary call is allowed to suspend.

The safety guarantee is therefore not carried by human visual inspection. It is
carried by compiler enforcement. `may_suspend` participates in hard errors: a
`no_suspend` function cannot perform a current-fiber suspension, and a
`@[no_await_guard]` guard cannot be live across any operation that may suspend.
Hidden suspension is acceptable precisely — and only — because the compiler
refuses the dangerous combinations.

The core rule:

**`may_suspend` is a current-fiber property, and fiber creation is the
firewall.** A same-fiber call through a callable whose type is `may_suspend`
propagates `may_suspend` to the caller. Calling an `async fn` does not: it
creates/starts a separate fiber and returns a `Task`, so suspensions inside that
task occur on the task's fiber, not the caller's current fiber. The caller
suspends later only if it awaits, joins, performs async-scope cleanup, or
otherwise invokes a current-fiber suspension operation.

Formally, a function is `may_suspend` if it directly performs a primitive
current-fiber suspension, or if it makes a same-fiber call through a callable
whose type is `may_suspend`. Fiber-creation boundaries do not propagate
`may_suspend` to the caller.

The primitive suspension set must be closed and deterministic. It is:

- `.await`;
- collection / select await;
- explicit yield primitives;
- async-scope await-all and other structured-concurrency joins;
- implicit cleanup await at scope exit for a live ephemeral task;
- **fiber-aware runtime operations that yield the current fiber when they cannot
  complete immediately** — lock acquire when unavailable, channel send when full,
  channel receive when empty, timer/sleep until deadline, and socket/file read
  or write when not ready.

The last category replaces the earlier "contended blocking primitives" wording,
which was wrong: a lock yields under contention, but I/O and timers yield on
external-event wait, not contention. A closed set that omits fiber-aware I/O is
not closed. The spec must also state explicitly whether fiber-aware I/O is direct
fiber-yielding (in which case it is a leaf, as above) or is modeled as a `Task`
that suspends only at `.await` (in which case it reduces to the `.await` leaf).
It may not leave this ambiguous.

`may_suspend` is part of callable **type** information — for function pointers,
closures, trait/`dyn` callables, callbacks, and every other indirect-call
surface. Without this, `no_suspend` and `@[no_await_guard]` have a hole: a
`no_suspend` function that calls through `cb: fn()` cannot be checked unless the
type of `cb` carries whether it may suspend. This does not reintroduce
coloring: ordinary calls remain unannotated, and the typing burden appears only
when a function becomes a value, which is real semantic information the compiler
must track. The surface spelling may be inferred in most cases, but the type
system has to know it.

`.await` is the primary explicit result-observing suspension operator for a
single `Task`. It is not the only result-observing suspension form if the
language has collection / select await. The spec must not state that `.await` is
the only result-extraction mechanism.

Requirement `14.3.1.34` is wrong in two directions and must be fixed in both:

- too narrow: "directly contains `.await`" must become "directly performs a
  primitive current-fiber suspension" (from the closed set above);
- too broad: "calls any `may_suspend` function" must become "makes a same-fiber
  call through a `may_suspend` callable," with fiber-creation boundaries
  stopping propagation.

Spec update: replace "suspension is always marked with `await`" (`20.1.1.5`) and
"`.await` is the only point where a fiber can suspend" (`14.5.1.6`) with a
compiler-visible suspension rule. Suspension need not be syntactically marked at
every call site. It must be known to the compiler, deterministic from the closed
primitive set, carried on callable types so indirect calls are checkable,
propagated only through same-fiber calls, stopped at fiber-creation boundaries,
and enforced through `no_suspend` and `@[no_await_guard]` hard errors. Reword
`14.5.1.7` ("always visible in source") accordingly: suspension is always known
to the compiler and surfaced in diagnostics, not necessarily spelled at the call
site.

The doctrine: no syntactic call-site coloring; a closed primitive suspension
set; same-fiber transitive closure; fiber-creation firewall; `may_suspend` on
callable types; guard safety enforced by compile errors.

This preserves both mission clauses:

**Suspension is never spelled at the call site — the compiler already knows it.**
**Suspension is never hidden from the compiler — and the dangerous combinations never compile.**

## 12. Ephemeral return rules are inconsistent

Affected requirements:

- `4.8.2.4` - slices are ephemeral and cannot be returned from functions.
- `8.3.1.8` - containers borrowing an allocator can only be local and cannot be returned.
- `14.7.1.8` - ephemeral tasks cannot be returned.
- `22.1.1.14` - an ephemeral `Vec` can be local but cannot be returned.

Related requirements I agree with:

- `3.4.1.1` - a function may return a reference or type containing a reference.
- `3.4.1.2` - the returned value is ephemeral and restricted at the call site.
- `5.1.1.3` - ephemeral values may be returned from functions with propagation.
- `22.1.1.10` - functions returning ephemeral types make callers inherit the restriction.
- `14.22.1.14` - ephemeral tasks can be returned from functions and remain ephemeral at the call site.

Argument:

Several specific sections accidentally restate "ephemeral" as "local only."
That is too restrictive and contradicts the core model. With intentionally
allows borrowed/reference-bearing values to cross a function boundary when the
ephemeral restriction propagates to the caller. That is how the language avoids
lifetime annotations without banning useful APIs like `first(xs) -> Option[&T]`.

The forbidden operation is not "returning an ephemeral value." The forbidden
operation is allowing that value to outlive the origin it borrows from, or
erasing the ephemerality behind storage, threads, escaping closures, opaque
trait objects, or non-ephemeral containers.

Preferred requirement shape:

- Ephemeral values may be returned when the return type/binding remains
  ephemeral and the compiler can track the origin.
- Ephemeral values may not be stored in non-ephemeral structs, globals,
  long-lived containers, detached tasks, channels, or escaping closures.
- Specific sections for slices, allocator-backed containers, `Task`, and
  `Vec` should refer back to the general propagation rule instead of saying
  "cannot be returned" categorically.

BDFL Ruling: Accept the flag; modify the rule.

The categorical “cannot be returned” requirements are wrong. Ephemeral values
may be returned when their origin is reachable from the function’s inputs or
program-lifetime storage, and the return remains ephemeral so the caller
inherits the restriction. An ephemeral whose origin is function-local may not
be returned. The compiler infers and carries the origin set; the programmer
does not write lifetime annotations. The invariant is that an ephemeral may
not be used after its origin dies or placed anywhere that erases origin
tracking.

## 13. Ephemeral escape diagnostics are too weak

Affected requirements:

- `14.22.1.10` - compiler tracks ephemerality and warns if a value might escape its safe scope.
- `14.22.1.11` - compiler catches clear bugs.
- `14.22.1.12` - ambiguous cases warn rather than block.
- `14.22.1.13` - users can read a warning.

Argument:

For ordinary weird-but-safe code, warning is fine. For ephemeral escape, a
warning is not enough. If the compiler cannot prove that an ephemeral value
stays within its valid scope, accepting the program risks dangling references,
cross-thread borrowed data, or a task outliving captured stack state.

This is the same mistake as the global "warn, don't block" slogan: it is good
as a social posture, but not as a safety rule.

Preferred requirement shape:

- Clear ephemeral escapes are hard errors.
- Unknown or ambiguous ephemeral escape cases are also hard errors unless the
  program crosses an explicit `unsafe` boundary or converts/copies into owned
  data.
- Warnings are appropriate for performance or style guidance, not for cases
  where accepting the code could violate memory safety.

BDFL Ruling: Accept.

The warning model is wrong for ephemeral escape.

Ephemerality is part of With’s safety contract. It is how the compiler carries lifetime/origin information without making the programmer write lifetime annotations. If an ephemeral value might escape its valid scope and the compiler cannot prove otherwise, the program is not safe With code.

Clear ephemeral escapes are hard errors. Ambiguous ephemeral escapes are also hard errors, because ambiguity means the compiler cannot prove the origin outlives every use. The user may resolve the error by keeping the value within scope, returning it with propagated ephemerality, converting/copying into owned data, or crossing an explicit `unsafe` boundary.

Warnings are appropriate for weird-but-safe code, performance guidance, style, or suspicious but semantically valid patterns. They are not appropriate when accepting the program could produce a dangling reference, cross-thread borrowed value, detached ephemeral task, or erased origin.

Spec update: replace `14.22.1.10` through `14.22.1.13` with a proof-based rule. Ephemeral values may be used only where the compiler can prove their origin outlives every use and the ephemerality/origin information is not erased. Proven escape is a compile error. Unproven safety is a compile error. Warnings are not sufficient for possible ephemeral escape.

## 14. `Task[T]` storability contradicts task ephemerality

Affected requirement:

- `14.20.1.9` - `Task[T] is always storable`.

Related requirements I agree with:

- `14.7.1.4` - `Task[T]` is `Send` when `T: Send` and the task is not ephemeral.
- `14.7.1.7` - a `Task[T]` that captures references is ephemeral.
- `14.22.1.3` - a task is ephemeral if its spawned fiber environment contains ephemeral values.

Argument:

The table entry is wrong as written. The type spelling `Task[T]` is the same
for storable and ephemeral tasks, but storability is a per-binding property.
A task that captures references or other ephemeral values cannot be stored in
long-lived data structures or sent to other threads.

Preferred requirement shape:

- `Task[T]` has one type spelling.
- A `Task[T]` value is storable only when its captured environment contains no
  ephemeral values and its result satisfies the relevant `Send`/storage rules.
- Tables comparing generators and async should say "Task handle; storable only
  when non-ephemeral."

BDFL Ruling: Accept.

`Task[T] is always storable` is wrong as written.

`Task[T]` has one type spelling. The programmer should not write a different
task type just because the compiler knows the task captured an ephemeral value —
that would be ceremony for a fact the compiler already infers. But storability
is not a property of the spelling. It is a property of the task value and its
binding, inferred from what the task captures and returns.

Storability and sendability are separate axes, and the requirement conflated
them. There are three properties, in a hierarchy:

- **Ephemeral vs non-ephemeral** — the lifetime gate. A task is ephemeral if its
  captured environment (or, transitively, its result) contains references,
  allocator-borrowed values, scope-bound resources, or any other ephemeral
  value.
- **Storable** — may be placed in long-lived data. A task is storable iff it is
  **non-ephemeral**. Storage alone does not require `Send`: a non-`Send` task may
  be stored in a same-thread container; the only consequence is that the
  container is then itself non-`Send`.
- **Sendable** — may cross a thread boundary. A task is sendable iff it is
  non-ephemeral **and** `T: Send` **and** its captured environment is `Send`.

This is exactly the ladder `14.7.1.4` already implies: `Task[T]` is `Send` when
`T: Send` and the task is not ephemeral, so `Send` is the stronger property
sitting on top of non-ephemeral. Requiring `Send` for mere storage would forbid
the legitimate non-ephemeral-but-not-`Send` rung — storing a task that holds a
non-`Send` resource in same-thread data.

An ephemeral task is neither storable nor sendable. It may be awaited,
cancelled, returned with propagated ephemerality, or otherwise handled within
its valid scope. It may not escape its origin — and "escape" is the general
ephemeral-escape property from #12/#13, not a fresh list: any operation after
which the compiler can no longer prove the task's origin outlives every use of
it. Storing it in long-lived data, sending it across a thread, placing it in a
channel, and hiding it behind type erasure that loses the origin are all
instances of that one property; *detaching* it (bare fire-and-forget, per #6) is
the task-specific instance. Attempting any of them is ephemeral escape, which
per #13 is a **hard error**, not a warning — the storability verdict is
enforced, not advisory.

So the table should not say "`Task[T]` is always storable." It should say:

> `Task[T]` is a task handle; storable only when non-ephemeral, sendable only
> when additionally `Send`.

Spec update: replace `14.20.1.9` with one `Task[T]` spelling whose storability
and sendability are binding properties inferred from the captured environment
and result.
- Ephemeral (captures or returns an ephemeral value): not storable, not
  sendable; must be awaited, cancelled, returned with propagated ephemerality,
  or handled in scope; may not escape its origin (hard error, per #12/#13).
- Non-ephemeral: storable in long-lived data on the same thread regardless of
  `Send`.
- Non-ephemeral and `Send` (with a `Send` environment): additionally sendable
  across threads.

This preserves both mission clauses:

**One `Task` type — the compiler infers storability from the captures; the user
never spells it.**
**An ephemeral task never escapes its origin — storing, sending, or detaching it
is a hard error, not a warning.**

## 15. `c_import` must not emit `comptime_error` stubs for failed translation

Affected requirements:

- `16.2.1.10` - untranslatable macros emit a stub with `comptime_error`.
- `16.2.1.14` - untranslatable constructs produce a diagnostic or a loud `comptime_error` stub.
- `17.5.1.8` - `c_import` uses `comptime_error` for untranslatable C constructs.

Argument:

This conflicts with the repository's no-silent-fallback rule. A generated
binding that contains a placeholder body, even a loud `comptime_error`, still
lets translation appear to succeed and pushes failure to a later use site. For
C migration/import tooling, that lies about completeness.

`comptime_error` is a valid language feature for user-authored concept checks.
It is not an acceptable fallback for compiler-generated bindings when the
translator could not produce correct output.

Preferred requirement shape:

- If `c_import` encounters an untranslatable construct outside an explicit
  allow-list, it emits a diagnostic naming the construct and source location
  and exits non-zero.
- Explicitly allow-listed omissions may be omitted from the generated binding
  surface or represented as intentionally unavailable metadata, but not as
  callable placeholder APIs.
- Generated bindings must never contain stubs that pretend an untranslatable C
  construct is part of the usable With surface.

BDFL Ruling: Accept with clarification.

`comptime_error` is a valid With feature for user-authored compile-time checks.
It is not a valid fallback for compiler-generated `c_import` bindings when the
importer failed to translate a C construct.

A generated binding is a promise: this name is part of the usable With surface.
If the importer emits a callable function, constant, macro wrapper, or type
placeholder whose body merely fails later with `comptime_error`, the import has
lied about what it successfully modeled and pushed the failure to a use-site
landmine. That violates the C-interop mission: interop must be first-class, not
a delayed error minefield.

The surface a `c_import` may expose is exactly the two tiers from #4, not one:

* safely modeled bindings — the safe surface; and
* ABI-expressible-but-not-safely-modeled bindings — the raw surface, available
  through the #4 escape hatch but not blessed as safe.

"Untranslatable," for the purpose of this rule, means **inexpressible even as a
raw binding** — not a callable or value at the ABI level at all: a token-paste
macro with no stable value or type meaning, a compiler extension With cannot
represent, or a type that cannot be expressed in either the safe or raw surface.

This is the bottom tier of the #4 hierarchy, not a parallel rule. A construct
that is merely hard to model safely — a variadic function, a raw buffer
contract, an out-parameter, or an ownership-transfer API — is not
untranslatable. It belongs on the raw surface, per #4, and must not be omitted
on the grounds that it is unsafe. #15 and #4 must give the same answer for the
same construct.

The rule:

* A generated `c_import` surface contains only valid bindings: safely modeled
  bindings, or raw bindings per #4. It never contains a `comptime_error`
  placeholder or any stub that pretends an inexpressible construct is part of
  the usable surface.

* A genuinely inexpressible construct is omitted from the generated surface and
  recorded in an import manifest: name, source location, and reason. It is never
  emitted as a callable API.

* Omission is allowed, but never silent. A construct may be omitted when it is
  inexpressible, outside the requested surface, inactive under the selected
  preprocessor/platform configuration, or explicitly allow-listed as
  unavailable. Dependent bindings that require an omitted inexpressible
  construct are also omitted and recorded with the same reason chain.

* The requested surface of a bare `use c_import("h")` is the available surface
  of that header under the selected platform/preprocessor configuration.
  Inexpressible constructs in that surface are omitted and reported; they do not
  brick the import merely by existing.

* Routine failure is gated on reference or explicit completeness. Referencing an
  omitted/inexpressible symbol produces a directional diagnostic: the name, why
  it could not be translated, and the alternative — the raw surface if it is a
  #4 case, or "this C construct has no With representation" if it is genuinely
  inexpressible.

* Whole-import non-zero exit is reserved for: an explicit selective request
  (`use c_import("h").{a, b}`) that names something inexpressible; completeness
  mode (`with migrate`, or an explicit strict flag) where incomplete translation
  is itself the error; and could-not-import-at-all failures such as a missing
  header, parse failure, unsupported target configuration, or toolchain crash.
  Ordinary `use c_import` is partial-but-honest. `with migrate` is
  complete-or-fail.

* `comptime_error` remains available for user-authored APIs and concept checks,
  never as a compiler-generated placeholder for failed C translation.

Spec update: replace the `comptime_error` stub requirements (`16.2.1.10`,
`16.2.1.14`, `17.5.1.8`) with an honest-surface rule. Generated `c_import`
output contains only valid bindings — safely modeled or raw per #4.
Inexpressible constructs are omitted and recorded as manifest metadata, never
emitted as callable stubs. Referencing one is a directional compile error.
Ordinary import is partial-but-honest and reports all gaps; `migrate`, strict
mode, and explicit selective requests fail on incompleteness; parse/host
failures exit non-zero.

This preserves both mission clauses:

**The compiler reports every translation gap by name — you never sort through C
failures by hand, and never hit one as a later landmine.**

**Every generated binding is a real one — no stub ever pretends an unmodeled C
construct is safely available.**


## 16. Heuristic-only C destructor auto-defer is unsafe

Affected requirements:

- `16.2.2.11` - destructor detection and auto-defer.
- `16.2.2.12` - functions matching `prefix_destroy`, `prefix_free`, `prefix_close`, `prefix_unref`, or `prefix_release` are considered destructors.
- `16.2.2.13` - when a constructor result is bound to a non-escaping `let`, the compiler inserts `defer prefix_destroy(value)`.
- `16.2.2.14` - auto-defer does not apply when the value escapes.

Argument:

The goal, ergonomic C interop, is exactly right. The mission says the compiler
should infer, import, generate, and make code safe when it can. Automatic C
resource cleanup is a good With feature when the compiler has enough ownership
evidence to own the cleanup decision.

The problematic part is the heuristic-only rule. Ownership conventions in C are
not reliably encoded in names. A `new`-looking function may return a borrowed
pointer, a retained pointer, a reference-counted object, a singleton, memory
freed by another API, or a handle whose close function has preconditions.
Automatically inserting cleanup based only on a name heuristic can introduce
double-free, use-after-free, or incorrect reference counting.

This is the boundary the mission itself implies: the compiler should eliminate
ceremony when it can prove the fact or safely synthesize the mechanism. It
should not guess ownership it does not know.

Preferred requirement shape:

- `c_import` may generate method-style wrappers for C functions.
- It may infer or generate automatic cleanup when ownership is known from
  trusted metadata, source analysis, annotations, a known-safe C convention
  database, or a safe With wrapper type that owns the resource and implements
  `Drop`.
- It may suggest likely destructor functions in diagnostics or generated
  metadata when ownership is plausible but unproven.
- Name heuristics alone must not insert `defer` calls.

BDFL Ruling: Accept.

The ergonomic goal is right: With should make C resource management humane. When
the compiler knows the ownership contract, it should generate cleanup so the
programmer never writes boilerplate `defer foo_destroy(x)`. But name heuristics
are not ownership knowledge — they are at most a hint, and acting on a hint here
produces memory-safety bugs.

C does not reliably encode ownership in names. A constructor-looking function may
return a borrowed handle, a retained reference, a singleton, an arena-owned
pointer, a resource freed by another API, or a handle with thread/state
preconditions. A `free`/`destroy`/`close`/`unref`/`release`-looking function may
be the correct cleanup for some values and catastrophic for others. Inserting
cleanup from names alone manufactures double-frees, use-after-free, refcount
underflow, and invalid close/release calls. That fails the mission: the compiler
removes ceremony only when it can carry the information, and it must never guess
information the programmer or API author has not supplied.

The rule has two distinct steps that the earlier requirement conflated:
establishing the ownership fact, and expressing it. They are not the same, and
the second is not a matter of evidence at all.

**Establishing ownership (the evidence).** `c_import` may treat a resource as
owned only when ownership is known from a source that proves or asserts it:

* an explicit annotation;
* author-supplied or imported metadata;
* source/header analysis strong enough to *prove* the contract (conservative,
  not speculative — analysis that merely raises confidence does not qualify);
* a curated, library-specific convention (asserting facts about a known library,
  e.g. Core Foundation's Create/Copy/Get rule — not a generic
  "any `_free` frees its argument" pattern, which is just the name heuristic
  renamed);
* a hand-written owning wrapper, whose existence is a human assertion of
  ownership.

Name heuristics, generic conventions, and speculative source analysis are not in
this set. They are guesses.

**Expressing cleanup (the mechanism).** When ownership is established, cleanup is
expressed only one way: a generated owning wrapper type whose `Drop` calls the
correct C destructor. The compiler does **not** insert scope-local `defer`.

Scope-local `defer` is unsound even with proven ownership, because it does not
compose with the ownership model. `defer foo_destroy(x)` at a non-escaping `let`
cannot handle the value being *stored* in a struct — there is no local scope-exit
to fire at, so cleanup never runs or runs while the struct still holds the
pointer. The original "skip auto-defer when the value escapes" patch only proves
the point: it means a proven-owned resource that is returned or stored gets no
cleanup help at all. A `Drop`-owning wrapper handles every case uniformly —
local, moved to a caller, or stored in a struct that is later dropped — because
cleanup is tied to the value's life, not a lexical scope. So `Drop` does not
merely improve on scope-local `defer`; it removes any reason to keep it.

This is the #4 safe surface applied to resources. A raw pointer or raw handle has
no ownership semantics, so it stays raw — manual `foo_destroy`, in `unsafe`, the
programmer's responsibility — unless it is wrapped by a proven ownership model.
The "make it safe" path is always: model the contract into an owning `Drop`
wrapper, or leave it raw. Never bolt cleanup onto a raw pointer by a guess.

Reference counting is a distinct contract and must be modeled as one. A `Drop`
that calls `unref` is correct only for a wrapper built from an *owning*
constructor (a `retain`/`copy`/`create` that returns a +1 reference). A function
that returns a *borrowed* reference must become a handle with **no** `Drop`, or
the count underflows into a use-after-free. Owned-versus-borrowed is the
distinction the core ownership model already makes, and exactly the one names
cannot encode — which is why even Core Foundation needed a naming *convention*
to state it.

Name heuristics retain a real but bounded role: they may produce candidates,
import-manifest notes, and a directional diagnostic suggesting the likely
constructor/destructor pairing and recommending an annotation or wrapper. They
may not, by themselves, insert cleanup, call a destructor, generate an owning
wrapper, or mark a raw C value as owned.

Spec update: replace heuristic-only destructor auto-defer (`16.2.2.11`–
`16.2.2.14`) with a two-step proven-ownership rule. Ownership is established only
from annotations, metadata, conservative proving analysis, curated
library-specific conventions, or a hand-written owning wrapper. When established,
cleanup is expressed only as a generated `Drop`-owning wrapper — never as
scope-local `defer`. Raw pointers stay raw unless wrapped by a proven model.
Reference-counted resources get a `Drop`-as-`unref` wrapper only when built from
an owning constructor; borrowing accessors get a handle with no `Drop`. Name
heuristics may suggest, never generate.

This preserves both mission clauses:

**The compiler removes cleanup ceremony whenever it actually knows the ownership
contract — inferred, annotated, or modeled, never spelled by hand.**
**The compiler never guesses ownership, and never lets C-interop ergonomics
manufacture a memory-safety bug — unproven resources stay raw, and cleanup is
only ever real.**

## 17. `str`/`c_char`/`c_void` auto-coercions are unsound as written

Affected requirements:

- `16.3.4.10` - `str` to `*const u8` passes a pointer to string data.
- `16.3.4.11` - `str` to `*const c_char` passes a null-terminated pointer to string data.
- `16.3.4.12` - `str` to `*mut c_char` passes a copy that the caller must free.
- `16.3.4.20` - `*mut c_void` / `*const c_void` returns can be coerced based on expected type.
- `16.3.4.21` and `16.3.4.23` - `*void` to `str` uses null-check plus `strlen` to produce a string view.
- `16.3.4.28` - `*mut c_void` to `str` always inserts a null check.
- `16.3.4.29` - null becomes `""`.

Argument:

These conversions cross from ergonomic into unsound.

`str` is not inherently a C string. It may not be NUL-terminated, and it may
contain interior NUL bytes. Passing a raw pointer to string data as
`*const c_char` is only valid if the compiler has produced a NUL-terminated
temporary with a correct lifetime, or the value is already `CStr`/`CString`.
That compiler-generated temporary is a mission-aligned feature when the
lifetime is bounded and the compiler owns the allocation/free path. The
problem is not automatic conversion; the problem is an underspecified
conversion that pretends ordinary `str` storage is already a C string.

The `*mut c_char` rule is worse as written: a hidden allocation that the caller
must free is not honest ownership. If the compiler generates a writable buffer,
it must also own the lifetime contract and define how mutated contents flow
back, if they do at all.

The `c_void` return coercions are also unsafe. A `void*` is opaque; expected
type context does not prove it points to a NUL-terminated string. Calling
`strlen` on arbitrary `void*` can read invalid memory. Converting null to
`""` erases a semantically important distinction and can hide C API errors.

Preferred requirement shape:

- `str -> *const u8` may pass pointer/length-compatible string bytes only for C
  APIs that do not expect NUL termination and where lifetime is bounded by the
  call.
- `str -> *const c_char` may use a compiler-generated call-scoped
  NUL-terminated temporary when allocation, interior-NUL behavior, and lifetime
  are specified. `CStr`/`CString` remain available when the user needs stable
  storage or explicit control.
- No implicit `str -> *mut c_char` caller-must-free conversion. A compiler
  generated mutable temporary is acceptable only when the binding contract
  specifies ownership, lifetime, size, and whether mutations are copied back.
- `void*` return values remain typed as `*mut c_void` / `*const c_void` unless
  the user explicitly casts or a binding has trustworthy metadata.
- Null pointer results should map to `Option`, not `""`.

BDFL Ruling: Accept with clarification.

The ergonomic goal is right, and protecting it is the first job. With should make
C string, buffer, and opaque-pointer interop feel natural. The programmer should
not write `CString::new(path)?`, manual length plumbing, scratch buffers, or
pointer casts at every ordinary C call when the compiler can model the contract
and generate the correct bridge. So the fix is *not* "make all conversions
explicit." That would reintroduce the exact ceremony that makes C interop
miserable everywhere else, and it would fail the mission's first clause.

The requirements are unsound because they confuse automatic conversion with
unchecked reinterpretation. A With `str` is not inherently a C string — it need
not be NUL-terminated and may contain interior NULs. A `void*` is not evidence of
its pointee's type. A null pointer is not an empty string. None of these are
ceremony; they are information the compiler does not have unless a contract
supplies it.

This is the #4 doctrine applied to strings, buffers, and opaque pointers:

> Model the C contract into a safe surface, or leave the operation raw. Never
> fake it.

An automatic conversion is allowed exactly when the compiler or binding models
the *full* contract relevant to it: sentinel, length, lifetime (including whether
the pointer is retained past the call), nullability, mutability, ownership,
allocation, cleanup, and copy-back. Anything less stays raw.

### `str` to a C input string (`*const c_char`)

A `str` may be passed automatically to a `*const c_char` parameter when the
binding establishes three facts, not two:

1. the parameter is a read-only, NUL-terminated input string;
2. the value has no interior NUL (or the conversion handles one loudly); and
3. the pointer is **not retained past the call**.

Given those, the compiler satisfies the contract the cheapest correct way:

* If the argument is a string literal or other value the compiler can prove is
  already valid NUL-terminated storage, it passes it directly — zero copy, zero
  allocation. This is the common case and it must be free.
* Otherwise it generates a call-scoped NUL-terminated temporary and frees it when
  the call returns.

The interior-NUL rule is not negotiable: the conversion must fail loudly, never
silently truncate. `"safe.txt\0.evil"` must not become `"safe.txt"` by accident —
that is a poison-NUL vulnerability, not a "specified behavior." If the compiler
can prove the NUL at compile time (a literal, statically-known data), it is a
compile error. If the value is dynamic, the generated wrapper checks at runtime
and reports failure per the binding's error model. A `str` with an interior NUL
may still be passed as bytes to a pointer-plus-length API; it simply cannot be a
faithful NUL-terminated C string.

The non-retention requirement is the lifetime half of the contract, and it is the
one easiest to forget. A call-scoped temporary is freed when the call returns,
which is sound only if C does not keep the pointer. `putenv(char*)` is the
textbook counterexample: it stores the pointer into the environment rather than
copying, so a call-scoped temporary leaves the environment holding freed memory.
Registration and config APIs that retain a `const char*` are the same hazard.
When the binding cannot establish non-retention — or knows the pointer *is*
retained — the call-scoped temporary is unsound, and the conversion must instead
require caller-managed storage (`CStr`/`CString`, whose lifetime the caller
controls) or fall to the raw surface. This is #12's ephemeral-escape rule
projected across the FFI boundary: the generated temporary is ephemeral, "C
retains it" is the escape, and since C cannot be inspected, the binding must
carry the non-retention fact the way it carries the sentinel and the length.

The conversion passes the `str`'s bytes unchanged. It does not silently transcode.
A With `str` is UTF-8; a C function may expect a locale or other encoding, but
that mismatch is the binding's or programmer's concern, not something the
compiler papers over by re-encoding behind the call — silent transcoding would be
exactly the hidden behavior this ruling forbids. Pass the bytes (plus the NUL),
honestly.

`CStr`/`CString` and generated wrapper types remain available whenever the user
needs storage that outlives the call.

### `str` to a byte buffer (`*const u8`)

`str -> *const u8` is not a safe conversion to a naked pointer. A `str` carries a
pointer *and* a length, and a safe buffer binding must convey both to C: the data
pointer and its paired length/capacity parameter, or an equivalent
wrapper-modeled bound. `write(fd, data)` may be ergonomic when the binding knows
to pass `data.ptr` and `data.len` together. Passing `data.ptr` alone to an
unbounded C reader is not inference; it is raw pointer interop and belongs on the
raw surface. A bare pointer with no modeled bound is unsafe regardless of NUL
expectations.

### `str` to a mutable C string or writable buffer (`*mut c_char`)

There is no implicit `str -> *mut c_char` conversion with a hidden
caller-must-free obligation. A hidden allocation the caller must later free is
not humane — it is invisible ownership transfer, and it manufactures leaks,
double-frees, and copy-back ambiguity.

A writable C buffer requires a modeled buffer contract. The safe surface may
expose:

* a caller-provided `mut` slice or buffer with known capacity;
* a generated owned buffer type whose `Drop` handles cleanup (per #16, so cleanup
  composes with moves, returns, and storage rather than relying on a remembered
  manual `free`);
* a generated wrapper defining allocation, capacity, initialized length, mutation
  behavior, and whether contents are copied back into With.

Absent those facts, the API stays raw.

### `c_void` and opaque pointers

`*mut c_void` and `*const c_void` are opaque. Expected-type context proves nothing
about the pointee's type, lifetime, ownership, nullability, or validity. A `void*`
may be converted automatically only when trusted binding metadata or a generated
wrapper proves what it represents. Otherwise it remains `*c_void`, and using it
requires the raw surface or an explicit cast.

In particular, `void* -> str` must never be generated merely because the expected
type is `str`. Calling `strlen` on an arbitrary `void*` is an unsafe memory read
based on a guess. It is allowed only when the binding proves the pointer is a
valid NUL-terminated string with known lifetime and nullability — at which point
it is a modeled conversion, not a coercion from context.

### Nullability

Null is information and must not collapse to `""`. A nullable C string or pointer
return is modeled as `Option[str]` (or an equivalent generated wrapper). `None`
and `Some("")` are different values and remain different unless the C contract
explicitly states that null means empty — an explicit modeled assertion by
someone who knows the API, never a silent default.

### Spec update

Replace the automatic `str`/`c_char`/`c_void` coercion rules with a
contract-driven conversion rule. The safe `c_import` surface may generate:

* zero-copy direct passing for literals and values proven already-valid C strings;
* call-scoped C-string temporaries for `str -> *const c_char`, only when the
  pointer is not retained past the call;
* interior-NUL checks (compile-time where provable, runtime otherwise) for dynamic
  `str` values;
* pointer-plus-length adapters for byte-buffer APIs;
* owned writable-buffer wrappers with `Drop`, or caller-provided `mut` buffers;
* `Option` for nullable C string or pointer returns;
* typed wrappers for trusted `void*` contracts.

The raw surface remains for explicit casts, unmodeled pointer behavior, arbitrary
`void*`, retained or unknown-lifetime string pointers, mutable C buffers without a
modeled contract, and any API whose lifetime, ownership, or nullability cannot be
proven.

No safe conversion may silently truncate at an interior NUL, allocate hidden
caller-owned memory, pass a call-scoped temporary to an API that retains it,
silently transcode string bytes, erase nullability, call `strlen` on an unproven
pointer, or reinterpret a `void*` from expected type alone.

This preserves both mission clauses:

**C interop stays ergonomic — `fopen(path, mode)` remains beautiful wherever the
binding can model the C-string contract, and the literal case costs nothing.**

**No guardrail is removed by pretending bytes, sentinels, lifetimes, nullability,
mutability, ownership, or `void*` pointee type are facts the compiler has not
proven.**

## 18. Pure comptime and capability-bearing comptime are conflated

Affected requirements:

- `17.1.1.7` - comptime is deterministic and side-effect-free.
- `17.1.1.9` - comptime cannot perform I/O, allocate heap memory that persists to runtime, or call FFI functions.
- `17.6.2.2` - `embed_file(path)` reads a file at compile time.
- `17.7.1.3` - comptime code cannot read files, make network calls, or access the environment.
- `18.5.2.22` - `build.w` runs as capability-bearing comptime, not ordinary pure comptime.

Argument:

The safety boundary is right, but the wording is inconsistent. Pure comptime
should be deterministic and effect-limited. But the spec also defines
`embed_file`, which reads source-relative files at compile time, and
capability-bearing comptime for build orchestration, which intentionally
performs controlled filesystem/process effects through driver-minted
capabilities.

Preferred requirement shape:

- Pure comptime is deterministic and cannot perform ambient I/O, access the
  environment, call FFI, or mint capabilities.
- Deterministic compiler-owned intrinsics such as `embed_file` are explicit
  compile-time inputs and participate in dependency tracking.
- Capability-bearing comptime is a separate mode whose effects are explicit in
  the required capability set and mediated by driver-provided values.
- Build-system effects belong only in capability-bearing comptime, never in
  ordinary pure comptime.

BDFL Ruling: Accept with clarification.

The contradiction is real, and it guards the fixpoint, so it cannot stand.

The spec currently uses “comptime” for several different execution modes, then applies the purity rule for one of them to all of them. Pure comptime should be deterministic and effect-limited. But `embed_file` reads a file, `c_import` parses C headers with the compiler’s C toolchain, and `build.w` intentionally performs filesystem, process, package, and toolchain effects. Those are not mistakes. They are part of With’s promise. The mistake is pretending they are all the same kind of comptime.

The invariant that matters is not “no effects.” The invariant is:

> No build output may depend on undeclared, untracked, ambient state.

With self-hosts and must pass the byte-identical fixpoint. If compile-time execution can silently read the clock, the environment, the network, the host filesystem, an ambient compiler, or untracked process output, then two builds of the same source tree can produce different binaries. That breaks determinism, reproducibility, and the compiler’s own correctness contract.

So the governing rule is:

> Comptime may use information only when that information is declared, authorized, and tracked.

There are two independent axes:

1. **Determinism:** is the result a deterministic function of declared, tracked inputs?
2. **Access authority:** is the operation allowed to touch the thing it wants to touch?

These axes do not move together. `embed_file("logo.png")` inside the package root is deterministic and covered by the compiler’s implicit authority over declared package inputs. `embed_file("/outside/root/logo.png")` may still be deterministic, but it needs explicit access authority. A `build.w` package fetch needs authority and must also be made deterministic through pinning and content addressing.

A capability answers what code may touch. It does not grant permission to produce nondeterministic output.

### Pure comptime

Pure comptime computes values. It does not perform ambient effects.

It may evaluate expressions, instantiate types, fold constants, run pure user code, and produce program data. Producing program data is the point of comptime; it is not an effect in the forbidden sense.

Pure comptime may not:

* read the filesystem;
* inspect directories;
* access the environment;
* read the clock;
* make network calls;
* spawn processes;
* call FFI;
* mint capabilities;
* depend on host-global state;
* call the runtime heap allocator or carry runtime allocator identity across the compile/runtime boundary.

The current wording “cannot allocate heap memory that persists to runtime” should be corrected. Pure comptime may produce static program data: constants, tables, generated bytes, and embedded assets. What it may not do is allocate runtime heap objects or smuggle runtime heap identity across the phase boundary. The ban is on runtime allocation and ambient effects, not on persistence of compiler-produced data.

### Tracked-input comptime

Some comptime operations read external inputs and still remain deterministic because the input is explicitly named, authorized, and tracked.

`embed_file("logo.png")` is the canonical example. It is not general file I/O. It is a declaration that `logo.png` is a compile-time input. The compiler reads it, records it as a dependency, and rebuilds when it changes.

This permission is a property, not a magic list of blessed intrinsics. A tracked-input operation is allowed when:

* the input is resolved by pure comptime before it is read;
* the resolved input is inside an authorized package/source root, or access is granted by an explicit capability;
* the operation is deterministic over that resolved input;
* the input is recorded in the build graph before or as it is read.

The decisive distinction is declared input versus discovered input.

Reading `embed_file("logo.png")` is allowed because the file is named and tracked. Computing `"assets/" ++ name ++ ".png"` from pure comptime constants is also allowed if the resolved path is registered before the read. But globbing `assets/*.png`, listing a directory, reading `$HOME`, consulting the environment, or inspecting the filesystem to decide what to read is input discovery. Discovery makes the input set depend on ambient state, so it does not belong in pure comptime.

If discovery is needed, it belongs in capability-bearing comptime, where the discovery itself becomes part of the build graph, manifest, or reproducibility record.

The model may be extended beyond `embed_file`, but only through compiler-recognized APIs that declare their inputs to the build graph before reading them. Ordinary user comptime does not get ambient file I/O by promising to be deterministic.

### Capability-bearing comptime

Capability-bearing comptime is a separate mode for build orchestration, package integration, C interop, migration, code generation, and tool execution.

This is where `build.w`, `with get`, package fetching, C library integration, generated binding workflows, and build-time tool invocations live.

Capability-bearing comptime may perform effects only through driver-minted capabilities. A capability is an unforgeable value granting specific authority: filesystem access, process execution, package/network access, environment access, output writing, tool invocation, or similar.

Capabilities have three roles.

First, they are an access-control boundary:

> What may this code touch?

A dependency’s `build.w` does not receive ambient access to the user’s machine merely because the package was fetched. The driver chooses what capabilities to mint. Untrusted fetched build code gets only the authority it was granted, so compiling a project does not automatically let a dependency read credentials, phone home, or write outside its sandbox.

Second, they are not a determinism waiver.

> What may this code touch?
> is not the same question as:
> May this output become nondeterministic?

Anything that affects the compiled output must still be deterministic over declared, tracked, or pinned inputs. A package fetch must be pinned and content-addressed. A code generator must run hermetically or record its inputs. A process invocation that affects output must track its command, inputs, outputs, environment, and relevant tool identity. An environment variable that affects output must be declared as a build input.

If an effect is genuinely nondeterministic, that nondeterminism must be visible: recorded, marked non-reproducible, or rejected in strict mode. It must never silently enter the build output while the compiler pretends the build is deterministic.

Third, capabilities are the way build effects become auditable. They give the build graph a place to record what was read, written, fetched, invoked, or depended on.

### Foreign code and FFI

Pure comptime may not call FFI.

Capability-bearing comptime may invoke foreign tools only through explicit capabilities, and the safe default is subprocess execution. A subprocess can be sandboxed, given explicit inputs, denied ambient access, and recorded as a build action.

In-process FFI is sharper. It loads foreign code into the compiler’s own address space; a crash or exploit compromises the compiler process itself. It cannot be sandboxed like a subprocess. Therefore in-process FFI during comptime is not an ordinary user/dependency capability. It is disallowed for untrusted fetched code by default and is acceptable only for trusted, pinned compiler/toolchain integrations or for explicitly trusted local build code under the strongest capability.

FFI must not become ambient effects through the side door.

### `c_import` as the canonical cross-case

`c_import` is the most important example of this model.

It reads C headers, which are declared and tracked inputs. But it also uses a C parser/toolchain, which is an effect requiring authority and a toolchain whose identity matters. For the fixpoint to hold, the same headers plus the same toolchain must produce the same bindings. Therefore the toolchain itself is a tracked input.

This is why With’s embedded LLVM/Clang SDK matters for reproducibility, not merely for dependency-freeness. A pinned Clang is part of the declared input set. An ambient system Clang is not. If `c_import` depends on whichever Clang happens to be installed, two machines can generate different bindings from the same With source.

`c_import`’s use of libclang is not ordinary user comptime FFI. It is compiler-owned integration with the pinned With toolchain. That is acceptable because the compiler owns and tracks the toolchain. General dependency-supplied in-process FFI remains disallowed by default.

The no-deps compiler work and the comptime determinism rule are the same concern from two directions: the build output must depend only on declared, authorized, tracked inputs — toolchain included.

### `with migrate`

`with migrate` is capability-bearing tooling. Its output is normally reviewable source that the user commits, so nondeterminism there is a quality and trust concern before it is a fixpoint concern.

But if migration or code generation is invoked as part of a build action, the normal capability-bearing rules apply: inputs, tool identity, environment, and outputs must be tracked when they affect the binary.

The compiler’s own self-hosting build has no escape hatch. The fixpoint requires full determinism. For that build, nondeterminism cannot merely be visible; it must be absent.

### Spec update

Replace the blanket purity wording in `17.1.1.7`, `17.1.1.9`, and `17.7.1.3`, and reconcile `embed_file` and `build.w` in `17.6.2.2` and `18.5.2.22`, with a comptime model organized around two axes: determinism over declared/tracked inputs, and access authority.

* **Pure comptime:** deterministic computation over values. No ambient I/O, filesystem inspection, environment access, clock reads, network, FFI, process execution, capability minting, runtime allocation, or host-global state. It may produce static program data.

* **Tracked-input comptime:** deterministic reads of explicitly named or purely-computed authorized inputs, each recorded as a build dependency. `embed_file` belongs here. This tier reads declared inputs; it does not discover inputs from ambient state. Access beyond the package/source root requires an explicit capability without changing the determinism requirement.

* **Capability-bearing comptime:** build, package, C interop, migration, and tool effects mediated by driver-minted capabilities. Capabilities grant authority, not nondeterminism, and bound the authority of untrusted fetched build code. Output-affecting effects must be deterministic over declared, tracked, or pinned inputs — including toolchain identity — or be explicitly recorded as nondeterministic. Strict and self-hosting builds reject nondeterminism.

The blanket FFI ban narrows accordingly: pure comptime still may not call FFI; capability-bearing comptime may invoke trusted, tracked foreign tools, preferring sandboxable subprocesses. In-process FFI is restricted to compiler-owned pinned toolchain integrations or explicitly trusted local build code, never ambient dependency code.

No comptime mode may let undeclared ambient state affect the build output silently. No mode may let untrusted fetched code exceed the authority the driver granted it. Determinism relative to declared, authorized, tracked inputs is a whole-pipeline invariant, not a property of one syntax form.

This preserves both mission clauses:

**The compiler removes ceremony: embedding files, importing C, fetching native packages, generating code, and running build logic are first-class instead of hand-written build-system suffering.**

**The compiler preserves the guardrail: every output is a deterministic function of declared, authorized, tracked inputs — toolchain included — so the self-hosting fixpoint survives. Untrusted build code receives only the authority the driver grants, so compiling a project cannot compromise the machine.**


## 19. Allocation visibility wording is too absolute

Affected requirement:

- `20.1.1.1` - allocations are obvious; no allocation hides behind innocent syntax.

Related requirements:

- `14.4.1.2` - calling an async function allocates a fiber with its own stack.
- `14.6.1.2` - `async:` allocates a fiber.
- `15.3.1.1` through `15.3.1.4` - string literals default to owned `str`, with allocation sometimes elided.
- `15.4.1.17` - f-strings always allocate.

Argument:

The intended performance principle is excellent, but the absolute wording is
false. Some allocations are intentionally hidden behind ergonomic constructs:
owned string literals may allocate, `async fn` calls allocate fibers, `async:`
allocates a fiber, comprehensions allocate collections, and f-strings allocate
strings.

Most of these are good With design choices. The mission explicitly says the
compiler should generate and link what it can instead of forcing users to spell
mechanical details. That means "no allocation hides behind innocent syntax" is
not the right absolute. The better promise is that allocation-producing
constructs have a clear semantic shape, documented cost model, and safe
ownership/lifetime behavior.

Preferred requirement shape:

- Allocation should be syntactically or semantically visible through owning
  result types, allocation-oriented constructs, or well-documented
  compiler-generated temporaries whose lifetime the compiler owns.
- The spec should enumerate allocation-producing constructs: `Vec.new`,
  `.to_owned`, comprehensions, f-strings, owned string literals when not
  elided, `async fn` calls, and `async:` blocks.
- Compiler-generated allocation in FFI coercions is acceptable when the
  compiler owns the allocation/free path or the binding contract makes
  ownership explicit. It should not create caller-must-free obligations
  invisibly.

BDFL Ruling: Accept the flag; modify the rule.

`20.1.1.1` is wrong as an absolute. “No allocation hides behind innocent syntax” conflicts with the language the spec already describes: f-strings allocate, comprehensions allocate, owned string literals may allocate when not elided, `async fn` calls allocate fibers, and `async:` allocates a fiber. The spec bans what it defines.

But the fix is not to make every allocation explicit. This is the rare ruling where the ergonomics clause pushes toward hiding implementation machinery. F-strings, comprehensions, owned literals, and async fibers exist precisely so the programmer does not hand-write string builders, collection allocation, `malloc`, or fiber setup. Making that machinery explicit would reintroduce the suffering With exists to automate.

The old wording conflates two concerns:

* **Cost legibility:** can a systems programmer identify where allocation may happen?
* **Obligation legibility:** does an allocation create ownership, cleanup, lifetime, or caller responsibility the code does not show?

Those are different rules. Cost legibility is about performance predictability. Obligation legibility is about safety and correctness. The first can tolerate compiler-owned hidden machinery when the construct makes the cost attributable. The second cannot tolerate hidden responsibility at all.

The replacement rule is:

> Allocation need not be spelled, but it must be attributable, documented, checkable, and must never create an invisible obligation.

### Cost legibility

Allocation has a cost, and systems programmers must be able to find that cost. But finding it does not require seeing `malloc`.

An allocation is legible when it is attributable to a visible construct, owning type, explicit allocation API, or compiler-owned adapter whose cost model is documented and diagnosable. The construct or type is the signal.

Examples of allocation-producing constructs include:

* explicit allocation APIs: allocator calls, `Vec.new`, owned buffer constructors, `.to_owned`;
* collection-producing constructs: comprehensions;
* string-producing constructs: f-strings and owned string literals when not elided;
* concurrency constructs: `async fn` calls and `async:` blocks, which allocate fibers/tasks;
* compiler-owned adapters: call-scoped C-string temporaries, ABI buffers, and other modeled FFI bridges whose lifetime the compiler owns.

An f-string signals “build a string.” A comprehension signals “build a collection.” A `Task` signals async work and its fiber/task representation. A generated C-string adapter is attributable to a modeled FFI conversion.

Each allocation-producing construct must have a documented cost model: what may allocate, which allocator or allocation policy is used, whether allocation may be elided, what happens on allocation failure, and what owns the result. In-code legibility is primary; documentation supplements it.

Two cases need special precision.

First, owned string literal elision must be deterministic and documented. “Sometimes allocated, sometimes elided, depending on compiler mood” is not legible, and it is bad for the fixpoint. The spec must say when a literal is static, when it is copied, and when allocation is elided. The rule must be predictable.

Second, async allocation is legible through type, not call-site coloring. Per the no-colored-functions design, an async call should not require extra syntax at every call site just to say “this allocates a fiber.” The allocation is type-attributable through `Task` and compiler-visible to allocation analysis, diagnostics, and no-allocation checking. That is consistent with no-colored-functions, not an exception to it.

### Obligation legibility

This is the hard rule.

An allocation must never create an invisible ownership, lifetime, cleanup, or caller responsibility.

Compiler-generated allocation is acceptable when the compiler owns the entire lifetime: allocate, use, free. A call-scoped FFI temporary is fine when it cannot escape and the compiler frees it. A generated owned wrapper is fine when its `Drop` owns cleanup. A comprehension returning an owned collection is fine because the owning type carries the responsibility.

The forbidden cases are hidden responsibilities:

* a hidden allocation the caller must later free;
* a call-scoped temporary passed to a C function that retains it past the call;
* a raw pointer returned with an unstated ownership obligation;
* an allocation whose cleanup depends on a convention the type does not express;
* a compiler-generated buffer whose mutation, copy-back, or lifetime contract is not modeled.

This is the same rule as #16 and #17 viewed from the allocation angle. The implicit `str -> *mut c_char` conversion was not wrong merely because it allocated. It was wrong because it created an invisible caller-must-free obligation with undefined copy-back. The correct forms are compiler-owned temporary storage, a caller-provided `mut` buffer, or an owned wrapper with `Drop`.

The sin is not hidden allocation machinery. The sin is hidden allocation responsibility.

### No-allocation contexts

Because With is close to the machine, allocation legibility must be enforceable.

The language should support contexts where allocation is forbidden or restricted: freestanding code, interrupt/signal-critical regions, allocator-constrained scopes, `no_alloc` regions, or equivalent mechanisms. This should be co-designed with the tier and allocator model, not invented as a separate one-off rule.

In such contexts, allocation-producing constructs are rejected unless the compiler proves the allocation is elided or the allocation is routed through an explicitly allowed arena, allocator, or capability. The explicit arena/capability is the visible allocation intent: it says where allocation is allowed and who owns the resulting lifetime.

This rule depends on deterministic elision. A `no_alloc` region cannot be meaningful if whether an f-string allocates depends on an unstable compiler choice. Elision rules must be deterministic so allocation checking is deterministic.

This also inherits the usual precision discipline: if a `no_alloc` region rejects code whose allocation is actually elidable, that is a compiler-precision bug to fix, not a user ceremony requirement. The user may supply real information through an explicit arena or allocator capability, but they should not restructure code merely to appease a weak checker.

### Spec update

Replace `20.1.1.1` with two rules.

**Cost legibility:** allocation need not be syntactically spelled, but every allocation must be attributable to a visible construct, owning type, explicit allocation API, or compiler-owned adapter. Allocation-producing constructs must be enumerated and documented: allocator calls, `Vec.new`, `.to_owned`, comprehensions, f-strings, owned literals under deterministic elision rules, `async fn`/`Task` fiber allocation, `async:` fiber allocation, and modeled FFI temporaries. Each must specify allocator policy, failure behavior, lifetime, and elision rules where relevant. Fiber allocation is legible through `Task` and compiler-visible, not call-site-spelled.

**Obligation legibility:** no allocation may create an invisible ownership, lifetime, cleanup, or caller-must-free obligation. Compiler-generated allocations must be compiler-owned with a non-escaping lifetime, or represented by a visible owning type whose `Drop` handles cleanup. Hidden caller obligations are forbidden. This is the same rule as #16 and #17.

Allocation-producing constructs must be visible to compiler diagnostics and no-allocation checking. No-allocation contexts, co-designed with the tier and allocator model, reject allocating constructs unless the allocation is proven elided or routed through an explicit arena, allocator, or capability. Conservative rejection inherits the compiler-precision discipline: false rejections are compiler work, not user ceremony.

This preserves both mission clauses:

**The compiler removes ceremony: programmers do not spell allocation machinery when f-strings, comprehensions, fibers, owning types, and FFI adapters already express the work.**

**The compiler preserves the guardrail: every allocation is attributable, documented, and checkable, and no allocation ever hides an ownership or cleanup obligation.**


## 20. Ephemerality is not purely structural and dataflow-free

Affected requirement:

- `22.1.1.2` - no dataflow required; ephemerality is determined structurally by types.

Related requirements:

- `3.4.1.7` and `3.4.1.8` - returned ephemeral origin sets are inferred from function bodies and enforced at call sites.
- `14.22.1.5` through `14.22.1.8` - task ephemerality is a per-binding property inferred at creation and propagated through assignments and calls.
- `21.1.1.9` - returned-view origin tracking is part of borrow checking.

Argument:

Base ephemerality is structural, but the whole system is not. With needs
provenance/origin tracking for returned references, binding-level task
ephemerality, propagation through assignments and function calls, and escape
checks at use sites. Calling this "no dataflow required" is misleading and
would push an implementer toward an unsound or incomplete checker.

Preferred requirement shape:

- Type-level ephemerality is determined structurally: references, declared
  ephemeral types, and generic containers of ephemeral types are ephemeral.
- Binding-level ephemerality and origin/provenance require local dataflow or
  equivalent analysis.
- The implementation should keep this analysis simple and deterministic, but
  the spec should not claim it does not exist.

BDFL Ruling: Accept the flag; reframe the rule.

`22.1.1.2` is wrong as written. “No dataflow required; ephemerality is determined structurally by types” contradicts the rest of the spec.

Returned-origin inference, returned-view origin tracking, task ephemerality propagation, assignment propagation, call-site enforcement, and escape checks are all dataflow-shaped. The requirement describes a simpler system than the one With actually needs, and that simpler system is not sound.

The underlying intent is right: the user should not write lifetime or ephemerality annotations. With must not become Rust with different punctuation. The mistake is confusing **no user ceremony** with **no compiler analysis**.

The mission says With pays compiler complexity to eliminate user ceremony. Ephemerality analysis is exactly that payment. The simplicity is user-facing, not implementation-facing.

No annotations does not mean no information. Origins, captures, lifetimes, and escape constraints exist. The compiler carries them so the programmer does not have to spell them out.

### Structural ephemerality versus provenance

The correct split is:

> Type-level ephemerality is structural.
> Value-level ephemerality is provenance-tracked.

Type-level ephemerality answers:

> Can this type carry an ephemeral value?

That can be structural. References carry origin constraints. Declared-ephemeral types are ephemeral by declaration. Aggregates and generic containers whose type structurally contains an ephemeral component are ephemeral by structure: `Vec[&T]` is ephemeral-shaped because the type itself contains `&T`.

No dataflow is needed to classify that type shape.

Value-level ephemerality answers a different question:

> Where did this value come from, and where may it go?

That cannot be answered from the type alone.

A returned `&T` does not merely have type `&T`; it has an origin set: parameter `a`, parameter `b`, receiver field `self.x`, captured environment, static storage, or some combination.

A `Task[T]` is not ephemeral by structure. Per the task model, there is one `Task[T]` spelling whether the task is ephemeral or not. A particular task binding becomes ephemeral because that task captured a borrowed stack value, an ephemeral resource, a scope-bound allocator, or another non-escaping origin. Task ephemerality is therefore value-level, not structural.

Closures follow the same principle. An implementation may encode captures structurally in anonymous closure types, but the spec guarantee should be compiler-carried closure/callable summaries, not source-visible lifetime structure. A closure that captures an ephemeral value carries that provenance in its callable summary. If the closure escapes, the summary must be checked.

Assignment may transfer an origin. A call may return a value whose origin is summarized by the callee. An escape check must know which origin would escape. These are properties of values flowing through the program, not just of types.

### Modular dataflow, not global lifetime ceremony

The analysis must be bounded and modular. This is not a license for an inscrutable whole-program lifetime solver, and it is not a reason to make the user annotate lifetimes.

The shape is:

* intra-procedural dataflow inside each function body;
* compiler-carried summaries at function and callable boundaries;
* call-site enforcement using those summaries.

Function summaries record which returned values may originate from which parameters, receiver, captures, globals, static storage, or local ephemeral sources.

Callable summaries carry the same facts for function pointers, closures, trait objects, generated wrappers, and other indirect-call surfaces.

Task summaries carry capture ephemerality, detachment eligibility, and `may_suspend` facts.

Returned-view summaries carry origin sets.

These summaries are real compiler metadata. They are not user-written lifetime syntax.

This is the same pattern as the rest of With: infer the facts, carry them across interfaces, and reject escapes when the facts prove a value cannot safely outlive its origin.

That is also the shared principle behind the callable `may_suspend` model and returned-origin summaries: inferred to spare the user, carried on interfaces so the analysis stays modular and sound across boundaries.

### Why the old wording is dangerous

The danger of “no dataflow required” is not merely over-rejection. It is unsoundness.

A structural-only checker can see that `&T` is reference-shaped, but it cannot know whether a returned reference came from a local temporary, a parameter, a receiver field, a capture, or static storage. It cannot know which task binding captured a borrowed value. It cannot know whether an assignment moved an ephemeral origin into a stored value. It cannot soundly check returned views, detached tasks, or closures that escape their capture scope.

So it accepts programs it should reject: dangling references, escaped borrows, invalid returned views, and tasks or closures that outlive captured stack data.

This is a clause-two issue. The quiet half of the mission requires the compiler to track the information that keeps no-ceremony safe.

### Determinism and precision

The analysis must be deterministic. Its hard-error boundary cannot depend on optimization level, analysis budget, hash iteration order, or build accident. The same program must receive the same ephemerality verdict across builds.

That is required for user trust, for hard-error diagnostics, and for the self-hosting fixpoint.

The analysis may be conservative for soundness. If the compiler cannot prove that an ephemeral value does not escape, it must reject.

But avoidable false rejection is compiler precision debt, not user responsibility. If safe code is rejected only because the analysis is too weak, the long-term answer is to improve the compiler, not to make the programmer write lifetime annotations or restructure obvious code to appease the checker.

The user may supply real information through explicit constructs when needed: choosing an owning type, returning an owned value instead of a view, using a safe wrapper, or otherwise changing the program’s ownership shape. That is information, not ceremony. But the default burden belongs to the compiler.

### Spec update

Replace `22.1.1.2` with the following rule:

**Type-level ephemerality is structural.**
References carry origin constraints. Declared-ephemeral types are ephemeral by declaration. Aggregates and containers whose type structurally contains an ephemeral component are ephemeral by structure, such as `Vec[&T]`. This determines which type shapes can carry ephemeral constraints.

**Value-level ephemerality is provenance-tracked.**
Binding-level ephemerality, returned-origin sets, task capture ephemerality, closure capture ephemerality, assignment propagation, call propagation, returned-view checking, and escape checks require deterministic provenance analysis.

**Tasks are value-level.**
`Task[T]` has one spelling whether ephemeral or non-ephemeral. A task binding is ephemeral when the task captures or depends on an ephemeral origin. That fact is inferred and propagated, not determined from the structural type alone.

**Closures and callable values carry summaries.**
An implementation may encode captures structurally in anonymous closure types, but the spec guarantee is a compiler-carried callable summary: captures, origin sets, ephemerality, and `may_suspend` facts are carried across closure, function pointer, trait object, and wrapper boundaries.

**The analysis is modular.**
The compiler performs intra-procedural dataflow and carries inferred summaries across interfaces: returned-origin sets, task ephemerality, closure capture provenance, callable provenance, and `may_suspend` facts.

**The analysis is inferred.**
The user writes no lifetime or ephemerality annotations. The compiler infers and carries the facts.

**The analysis is deterministic and conservative.**
Verdicts are reproducible. Rejection is required when safety cannot be proven. False rejection of actually-safe code is compiler precision debt.

The spec must not claim the analysis does not exist. The claim With should make is stronger and more honest:

> The programmer writes no ephemerality annotations because the compiler performs the provenance analysis.

This preserves both mission clauses:

**The user writes no lifetime or ephemerality ceremony — origins, captures, and escape constraints are inferred and carried by the compiler.**

**The compiler preserves the guardrail with sound, modular, deterministic provenance analysis, so references, returned views, tasks, closures, and ephemeral values cannot escape the origins that make them safe.**


## 21. `with` dispatch is underspecified in the later semantics section

Affected requirements:

- `23.1.1.1` - compiler desugars `with` based on the `mut` keyword.
- `23.1.1.2` - `with e as mut x` desugars to scoped mutation.
- `23.1.1.3` - `with e as x` desugars to scoped binding.

Related requirement I agree with:

- `7.5.1.1` - the `with` block form is determined by the type of the expression.

Argument:

Section 23 only describes the non-guarded binding forms, but it is titled as
the `with` dispatch rule. That conflicts with Section 7, where `with` has
guarded access, scoped mutation, scoped binding, implicit context, and record
update forms. For guarded access, the type/protocol of the expression matters;
`mut` is not the whole dispatch rule.

Preferred requirement shape:

- Section 23 should say it is specifying the desugaring for non-guarded
  binding forms only, or it should restate the complete dispatch order.
- Full `with` dispatch should first distinguish syntax/form and guard
  protocol, then use `mut` to choose scoped mutation versus immutable scoped
  binding for the plain binding forms.

BDFL Ruling: Accept the flag; subordinate Section 23.

`23.1.1.1`–`23.1.1.3` are wrong as a complete `with` dispatch rule.

They say the compiler desugars `with` based on the `mut` keyword. That is only true for one narrow family: the plain, non-guarded binding forms. It is not true for `with` as a whole.

Section 7 is the controlling rule: the `with` block form is determined by syntax and by the type/protocol of the expression. Section 23 currently describes only `with e as x` and `with e as mut x`, then presents `mut` as if it were the global dispatcher. That inverts the hierarchy.

The correct rule is:

> `with` dispatch is syntax-first, type/protocol-driven, and `mut`-refined.

The syntactic shape narrows the candidates. The expression’s type and protocol determine whether the form is guarded access, plain scoped binding, implicit context, or record update. `mut` only refines mutability within the selected path.

This matters because `with` is not just binding sugar. Guarded `with` carries real safety machinery: acquire on entry, release on scope exit, and no-await-while-guarded enforcement. If an implementer follows Section 23 literally and treats all `with as` forms as plain bindings selected by `mut`, guarded access is silently miscompiled. The guard protocol is skipped, cleanup does not run, and the no-await-guard check is lost. That is a clause-two failure, not a wording nit.

### Dispatch order

Full `with` dispatch is:

1. **Syntactic form first.**
   The parser distinguishes the gross shape:

   * `with e`
   * `with e as x`
   * `with e as mut x`
   * record-update forms
   * implicit-context forms, if syntactically distinct

2. **Type/protocol next.**
   For forms that can be either plain binding or guarded access, the expression’s type decides. If the expression implements the guarded-access protocol — for example `Scoped` / `ScopedMut`, or whatever the final protocol names are — then the form is guarded. Otherwise it is a plain scoped binding.

3. **`mut` last.**
   `mut` is information, not ceremony. The compiler generally cannot infer whether the user intends to mutate a bound name, so the user supplies that fact. But `mut` is a refinement, not the dispatcher.

   In the plain binding path:

   * `with e as x` introduces an immutable scoped binding.
   * `with e as mut x` introduces a mutable scoped binding.

   In the guarded path:

   * the guard protocol determines whether mutable access is available;
   * `mut` requests mutable access to the guarded value;
   * `mut` must be checked against the selected guard capability.

   For example, `with lock.read() as mut x` is invalid if `lock.read()` produces only an immutable guard. The keyword does not select the mutable protocol. It requests mutability, and the type must support it.

### Section 23’s role

Section 23 must not stand as a global `with` dispatch rule. It should either be narrowed or replaced.

Preferred fix:

* Section 7 owns the full `with` dispatch rule.
* Section 23 is retitled and scoped to the non-guarded binding desugarings only.

For example:

> Section 23 specifies the desugaring of plain, non-guarded `with e as x` and `with e as mut x` forms after full `with` dispatch has already selected the plain binding path. It does not define guarded access, implicit context, record update, or the global `with` dispatch order.

If Section 23 restates the full rule instead, it must use the order above: syntactic shape, then type/protocol, then `mut` as a path-dependent mutability refinement.

### Spec update

Replace `23.1.1.1`–`23.1.1.3` with a rule that subordinates Section 23 to Section 7:

* Full `with` dispatch is syntax-first and type/protocol-driven.
* Guarded access is selected by the expression’s guard protocol, not by `mut`.
* Plain scoped binding is selected only when no guarded/context/record-update form applies.
* `mut` refines mutability within the selected form.
* In the guarded path, `mut` requires a mutable guard capability; it does not choose the protocol.
* Section 23 describes only the desugaring of plain, non-guarded binding forms unless it explicitly restates the full dispatch order.

This preserves both mission clauses:

**The user does not spell “guarded” versus “plain” when the type/protocol already determines it. The compiler reads the form from syntax and type.**

**The guardrail remains intact: type-first dispatch preserves guarded acquire/release behavior and no-await-guard enforcement, while keyword-first dispatch would silently drop them.**


## 22. Raw pointer arithmetic has conflicting unsafe requirements

Affected requirement:

- `16.1.1.19` - unsafe is required for raw pointer operations including pointer arithmetic.

Related requirements I agree with:

- `16.11.1.12` - some raw pointer operations are safe and do not require unsafe.
- `16.11.1.13` - raw pointer arithmetic is safe.
- `16.11.1.23` - computing a pointer value cannot by itself read or write invalid memory.
- `16.11.1.24` - unsafe is required at the access site, not every intermediate computation.
- `16.11.1.25` - unsafe is required when touching memory through a raw pointer, not merely computing one.

Argument:

Section 16.1 uses the older broad phrase "raw pointer operations" and includes
pointer arithmetic in the unsafe list. Section 16.11 gives the better, more
precise rule: computing raw pointer values is allowed in safe code; touching
memory through them requires unsafe.

The precise rule fits With's philosophy. It keeps the real danger visible
without forcing unsafe ceremony around address calculation.

Preferred requirement shape:

- Raw pointer dereference, raw pointer indexing, transmute, and unsafe calls
  require unsafe.
- Raw pointer arithmetic and comparison are safe computations, provided the
  compiler lowers them without introducing backend undefined behavior.
- Any later memory access through the computed pointer requires unsafe.

BDFL Ruling: Accept; adopt §16.11 as normative.

`16.1.1.19` is stale and over-broad. It says `unsafe` is required for raw pointer operations, including pointer arithmetic. That contradicts §16.11, which gives the correct operation-specific rule: computing a raw pointer value is not the dangerous operation. Touching memory through it, or asserting that it is valid to touch, is.

Adopt §16.11 and delete pointer arithmetic from the §16.1 unsafe list.

This is the #4 doctrine applied to pointers. `unsafe` is not a tax on foreignness, and it is not a tax on pointers either. It marks the operation whose safety the compiler cannot prove.

Pointer arithmetic computes an address. Pointer comparison compares addresses. Neither reads memory, writes memory, creates a reference, or proves bounds, alignment, liveness, initialization, ownership, or provenance. Requiring `unsafe` around `p + 1` or `p == end` is ceremony that buys no safety.

The boundary is:

> Address computation and comparison are safe. Memory access or validity assertion is unsafe.

The second half matters as much as the first. The unsafe point is not only where the program touches memory. It is also where the program launders a raw pointer into a safe abstraction.

Converting a raw pointer into `&T`, a slice, a view, or any other safe memory abstraction asserts facts the safe type system will trust afterward: validity, bounds, alignment, lifetime, initialization, and, if With’s memory model carries it, provenance. That assertion must be unsafe at the conversion site. It cannot be deferred until downstream safe code dereferences the now-safe value.

For example:

```with
let q = p + n          // safe: computes a raw pointer value
let at_end = q == end  // safe: compares raw pointer values

unsafe:
    let x = *q             // unsafe: reads through a raw pointer
    *q = 42                // unsafe: writes through a raw pointer
    let r = q as &T        // unsafe: asserts reference validity
    let s = slice(q, len)  // unsafe: asserts bounds, lifetime, validity
```

Indexing splits along the same line. Address-only indexing is safe; access indexing is unsafe.

```with
let q = p + i      // safe: address calculation
let q2 = &p[i]     // safe only if this is specified as address calculation

unsafe:
    let x = p[i]   // unsafe if this reads memory
    p[i] = value   // unsafe if this writes memory
```

The spec must not use one word, “indexing,” for both address calculation and memory access without saying which is meant.

### Backend obligation

This is not only a surface-syntax rule. It is a backend contract.

If With says raw pointer arithmetic is safe address computation, the compiler must lower it in a way that remains defined for arbitrary raw pointer values. The backend must not turn a safe raw address calculation into a hidden assertion that the pointer is in-bounds, dereferenceable, aligned, live, initialized, or attached to a particular allocation.

Safe raw pointer arithmetic and comparison must not be lowered with — nor given metadata implying — any of the following unless the corresponding fact is proven:

* in-bounds or in-range assumptions;
* dereferenceability assumptions;
* alignment assumptions;
* no-overflow assumptions;
* provenance or allocation-membership assumptions;
* lifetime assumptions.

For LLVM, this means ordinary raw pointer arithmetic must not use `inbounds` or `inrange` GEP, or equivalent assumptions, unless the compiler has proved the corresponding facts. Otherwise an out-of-range address calculation can become poison or otherwise give the optimizer facts With did not establish. Safe raw arithmetic must remain raw address computation.

This does not forbid optimization. If the compiler has proved the offset is in-bounds — for example, from a checked slice index — it may use the stronger lowering. The rule forbids assuming those facts for unproven raw arithmetic.

Pointer comparison carries the same obligation. It must lower to address-value comparison without range, provenance, allocation-membership, dereferenceability, or lifetime assumptions. LLVM pointer `icmp` or explicit integer-address comparison may be acceptable depending on the target model; C relational pointer comparison is not an acceptable lowering for arbitrary raw addresses, because C gives it validity constraints between unrelated objects. The With operation is raw address comparison, not a hidden allocation-membership assertion.

If With’s memory model carries provenance, the split survives unchanged. Arithmetic computes a raw address value. The unsafe dereference or raw-to-safe conversion is where the programmer asserts that the pointer has the required validity, provenance, alignment, lifetime, initialization, and bounds. Provenance does not move the unsafe boundary to arithmetic; it is part of what the unsafe access or conversion asserts.

### Spec update

Replace the broad rule in `16.1.1.19` with §16.11’s operation-specific boundary:

* **Safe in safe code:** raw pointer arithmetic, offset calculation, null checks, equality checks, and raw address comparison. These produce or compare raw pointer values only and touch no memory.
* **`unsafe` required:** raw pointer dereference; raw pointer indexing that reads or writes; raw-pointer-to-reference conversion; raw-pointer-to-slice/view conversion; transmute; `unsafe` calls; and any operation whose correctness depends on a pointer’s validity, provenance, bounds, alignment, initialization, liveness, ownership, or lifetime.
* **Backend obligation:** the compiler lowers safe raw pointer arithmetic and comparison without introducing undefined behavior, poison, or optimizer assumptions — in-bounds, range, dereferenceability, alignment, no-overflow, provenance, ownership, or lifetime — unless those facts are proven.

`16.1.1.19`’s inclusion of arithmetic in the unsafe list is deleted. §16.11’s operation-specific rule is normative.

This preserves both mission clauses:

**No `unsafe` around address arithmetic or comparison — computing or comparing a pointer touches nothing, so demanding the marker is ceremony that buys no safety.**

**`unsafe` stays exactly where the guardrail belongs: the first operation that touches memory or asserts that a raw pointer is valid to use.**
