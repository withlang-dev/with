# Problematic Requirements Audit

This file records a methodical audit of all 2,567 generated requirements in
`docs/requirements.md` against the With philosophy and the specification as a
whole.

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

Preferred requirement shape:

- `if condition: expr`
- `if condition: NEWLINE ...`
- `if condition { ... }`
- `else if condition` follows the same body rules.
- `else` also requires a normal body marker: `else: expr`, `else: NEWLINE ...`,
  or `else { ... }`.
- No naked `if condition expr`, no naked `else expr`, and no separate `then`
  body form.

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

## 16. Heuristic C destructor auto-defer is too magical

Affected requirements:

- `16.2.2.11` - destructor detection and auto-defer.
- `16.2.2.12` - functions matching `prefix_destroy`, `prefix_free`, `prefix_close`, `prefix_unref`, or `prefix_release` are considered destructors.
- `16.2.2.13` - when a constructor result is bound to a non-escaping `let`, the compiler inserts `defer prefix_destroy(value)`.
- `16.2.2.14` - auto-defer does not apply when the value escapes.

Argument:

The goal, ergonomic C interop, is right. The mechanism is too dangerous.
Ownership conventions in C are not reliably encoded in names. A `new`-looking
function may return a borrowed pointer, a retained pointer, a reference-counted
object, a singleton, memory freed by another API, or a handle whose close
function has preconditions. Automatically inserting cleanup based on a name
heuristic can introduce double-free, use-after-free, or incorrect reference
counting.

This is especially out of line with With's "do the right thing" philosophy:
the compiler would be guessing a semantic fact it does not actually know.

Preferred requirement shape:

- `c_import` may generate method-style wrappers for C functions.
- It may suggest likely destructor functions in diagnostics or generated
  metadata.
- Automatic cleanup requires explicit ownership metadata, user annotation, or a
  safe With wrapper type that owns the resource and implements `Drop`.
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
The `*mut c_char` rule is worse: a hidden allocation that the caller must free
is not honest ownership.

The `c_void` return coercions are also unsafe. A `void*` is opaque; expected
type context does not prove it points to a NUL-terminated string. Calling
`strlen` on arbitrary `void*` can read invalid memory. Converting null to
`""` erases a semantically important distinction and can hide C API errors.

Preferred requirement shape:

- `str -> *const u8` may pass pointer/length-compatible string bytes only for C
  APIs that do not expect NUL termination and where lifetime is bounded by the
  call.
- `str -> *const c_char` requires `CStr`/`CString`, or an explicit compiler
  temporary whose allocation and lifetime are specified. Prefer explicit
  `.to_cstring()` when allocation matters.
- No implicit `str -> *mut c_char` caller-must-free conversion.
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

## 19. Allocation visibility is overstated

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

Most of these are good With design choices. The problematic part is promising
"no allocation hides" instead of specifying which syntax owns/allocates and
why that cost is considered visible enough.

Preferred requirement shape:

- Allocation should be syntactically or semantically visible through owning
  result types or allocation-oriented constructs.
- The spec should enumerate allocation-producing constructs: `Vec.new`,
  `.to_owned`, comprehensions, f-strings, owned string literals when not
  elided, `async fn` calls, and `async:` blocks.
- Hidden allocation in FFI coercions or cleanup heuristics should not be added
  unless the ownership/lifetime contract is explicit.

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
