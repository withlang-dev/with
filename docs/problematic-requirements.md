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

BDFL Response:  Correct.  unsafe is very much a part of With.  Implementation is correct; Spec is stale and needs updated.

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

BDFL Response:
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

  BDFL Response: Yes - if form has evolved since the spec was written.  The Implementation is correct.  The Spec is wrong, please udpate it to match the current compiler implementation.

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

BDFL Response: Accept with stronger clarification.

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

BDFL Response: Modify.

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

BDFL Response:
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

BDFL Response: Accept the flag; modify the rule.

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

BDFL Response: Accept.
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

BDFL Response: Accept.

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

BDFL Response: Accept with clarification.

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

BDFL Response: Accept the flag; modify the rule.

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

BDFL Response: Accept.

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

BDFL Response: Accept.

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
