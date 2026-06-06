# Problematic Requirements Audit

This file records a first-pass targeted audit of requirements from
`docs/requirements.md` that I do not agree with as written after checking
them against the With philosophy and the specification as a whole.

This is not a complete requirement-by-requirement approval pass over all
2,567 generated requirements. Absence from this file means only that this
targeted pass did not flag the requirement; it is not a claim that the
requirement is correct, normative, or philosophically aligned.

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
- Raw pointer dereference, pointer indexing, pointer arithmetic, transmutes,
  and other unsafe operations remain unsafe even when the pointer came from a
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
