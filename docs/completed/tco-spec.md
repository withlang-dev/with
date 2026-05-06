# Tail Call Optimization Specification

This document specifies the intended Tail Call Optimization (TCO)
semantics for With, including the `@[tailrec]` guarantee, mutual tail
recursion, implementation requirements, diagnostics, ABI constraints,
and C migrator implications.

This document specifies the intended Tail Call Optimization (TCO)
contract for With and records the guaranteed subset implemented by the
compiler today.

---

## 1. Goals

TCO has two roles in With:

1. Optimization for ordinary tail calls, where the compiler may remove
   stack growth when it is safe and profitable.
2. A correctness guarantee for `@[tailrec]`, where the compiler must
   either prove stack-constant execution for recursive cycles or reject
   the program.

The guarantee matters because With uses recursion in places where C
would use `goto`, loops, or dispatcher state machines. If a source
program relies on TCO for bounded stack use, the compiler must not
silently emit stack-growing code.

The central rule is:

> `@[tailrec]` is a source-level contract, not an optimization hint.

If the compiler cannot satisfy the contract, compilation must fail.

---

## 2. Terminology

**Tail position** is a position where evaluating an expression
immediately determines the result of the current function, with no
remaining computation, cleanup, coercion, wrapping, storage, or
post-call work.

**Tail call** is a call expression in tail position.

**Self tail recursion** is a tail call from a function to itself.

**Mutual tail recursion** is a strongly connected component (SCC) of
two or more functions where control cycles through tail calls.

**Recursive edge** is a call from one function in a recursive SCC to
another function in the same SCC, including a self-call.

**Guaranteed TCO** means stack usage is bounded by a constant for
unbounded recursion depth through the annotated recursive path.

**Opportunistic TCO** means the compiler or backend may optimize a tail
call, but source correctness must not depend on that optimization.

**Trampoline lowering** is an explicit compiler transformation that
turns recursive control flow into a loop, usually with a dispatch tag
and a frame containing the active function's arguments.

**Backend tail call** means a target backend tail-call facility such as
LLVM `tail` or `musttail`.

---

## 3. User Model

Ordinary functions may contain tail calls. The compiler may optimize
them, but this is not a source-level guarantee.

`@[tailrec]` upgrades recursive tail-call optimization from an
optimization to a contract:

```with
@[tailrec]
fn factorial(n: i64, acc: i64) -> i64:
    if n <= 1:
        acc
    else:
        factorial(n - 1, acc * n)
```

If a `@[tailrec]` function participates in a recursive cycle and the
compiler cannot prove that every recursive step is stack-constant, the
compiler must emit a diagnostic and reject the program.

No silent fallback is allowed. Emitting normal calls for an annotated
recursive cycle is incorrect.

`@[tailrec]` does not mean every call in the function must be a tail
call. It applies only to recursive calls in the function's recursive
SCC.

A `@[tailrec]` function with no recursive calls is permitted, but the
compiler may warn that the annotation is unnecessary.

---

## 4. Tail Position Rules

The following are tail position:

* The final expression of a function body.
* The final expression of a block that is itself in tail position.
* Both branches of an `if`/`else` expression that is in tail position.
* Every arm body of a `match` expression that is in tail position.
* The value expression of `return expr`, but only when returning the
  value requires no post-call conversion, cleanup, wrapping, storage, or
  return-slot adjustment.

A call inside `return expr` is tail position if and only if the call's
result can be returned directly as the enclosing function's result.

For `return f(x)` to be a tail call:

* The return value of `f(x)` must match the enclosing function's return
  type exactly after type checking.
* No coercion, cast, narrowing, widening, boxing, wrapping, or
  destructuring may be required after the call returns.
* No `Drop`, `defer`, `errdefer`, borrow cleanup, or other cleanup may
  be required between the call and the return.
* The call's return ABI must be compatible with the enclosing function's
  return ABI, including aggregate and sret return-slot behavior.
* The call result must not need to be written into a different return
  slot after the call returns.

The following are not tail position:

* A call whose result is used by another operation, such as
  `1 + f(x)`, `f(x).field`, `f(x)?`, `g(f(x))`, or `Some(f(x))`.
* A call followed by any statement in the same control-flow path.
* A call in a loop body, unless the loop body itself is structurally
  proven to exit only by that tail call. The baseline rule is that loop
  bodies are not tail position.
* A call with active `defer` or `errdefer` cleanup.
* A call that must run `Drop` cleanup after the call returns.
* A call that must write, copy, coerce, box, wrap, destructure, or store
  its result after return.
* A call through an unknown function pointer unless the compiler can
  prove it is part of the annotated recursive SCC and can lower it with
  stack-constant semantics.

Examples:

```with
@[tailrec]
fn good(n: i64) -> i64:
    if n == 0:
        0
    else:
        good(n - 1)

@[tailrec]
fn also_good(n: i64) -> i64:
    if n == 0:
        return 0
    else:
        return also_good(n - 1) // tail call: exact return type, no post-call work

@[tailrec]
fn bad(n: i64) -> i64:
    if n == 0:
        0
    else:
        1 + bad(n - 1)  // error: recursive call is not in tail position
```

Examples of calls that may look like tail calls but are not:

```with
fn compute_i64() -> i64:
    ...

fn returns_i32() -> i32:
    return compute_i64() as i32
    // not a tail call: the i64 result must be coerced to i32 after the call

fn inner() -> i32:
    ...

fn wraps() -> Option[i32]:
    return Some(inner())
    // not a tail call on inner: the result must be wrapped in Some(...) after inner returns
```

For `@[tailrec]`, these cases must be rejected if the non-tail call is a
recursive edge in the annotated SCC.

---

## 5. `@[tailrec]` Semantics

`@[tailrec]` may be applied to a function declaration.

For a self-recursive `@[tailrec]` function:

* Every self-recursive call must be in tail position.
* The compiler must lower the recursion to stack-constant control flow,
  such as parameter reassignment plus a jump to the function entry.
* If the lowering cannot be performed, the compiler must reject the
  program.

For mutually recursive `@[tailrec]` functions:

* Every function in the recursive SCC must be annotated `@[tailrec]`.
* Every call from one function in the SCC to another function in the
  same SCC must be in tail position.
* All recursive edges in the SCC must lower to stack-constant control
  flow.
* If any function in the SCC is not annotated, or any recursive edge is
  not in tail position, the compiler must reject the program.
* If the compiler cannot lower the SCC to stack-constant control flow,
  it must reject the program.

A recursive SCC may be lowered by:

1. Explicit MIR-level self-loop lowering for self recursion.
2. Explicit SCC trampoline lowering for mutual recursion.
3. A verified backend `musttail` lowering, but only when all ABI and
   target requirements are proven.

The compiler must not use non-guaranteed backend tail-call optimization
to satisfy `@[tailrec]`.

---

## 6. Ordinary Tail Calls

For non-annotated functions, the compiler may optimize tail calls when
safe. It may use backend tail-call hints, sibling-call optimization, or
MIR-level rewrites.

The compiler must not rely on opportunistic backend behavior to satisfy
the `@[tailrec]` contract.

If a non-annotated recursive function grows the stack, that is allowed.
If an annotated recursive function grows the stack along an annotated
recursive path, that is a compiler bug.

---

## 7. Lowering Requirements

### 7.1 Self Tail Recursion

Self tail recursion should lower before code generation:

```with
@[tailrec]
fn sum(n: i64, acc: i64) -> i64:
    if n == 0:
        acc
    else:
        sum(n - 1, acc + n)
```

Desired MIR shape:

```text
entry:
    goto loop

loop:
    if n == 0:
        return acc
    tmp0 = n - 1
    tmp1 = acc + n
    n = tmp0
    acc = tmp1
    goto loop
```

Argument evaluation must use temporaries before parameter assignment so
aliasing and evaluation order match a normal call.

### 7.2 Mutual Tail Recursion

Mutual tail recursion must be lowered explicitly unless the backend can
provide a verified no-stack-growth primitive with equivalent semantics.

Preferred lowering is an SCC trampoline:

```with
@[tailrec]
fn even(n: i64) -> bool:
    if n == 0: true else: odd(n - 1)

@[tailrec]
fn odd(n: i64) -> bool:
    if n == 0: false else: even(n - 1)
```

Desired conceptual lowering:

```text
type TailTag { even, odd }

entry_even:
    tag = even
    goto loop

entry_odd:
    tag = odd
    goto loop

loop:
    match tag:
        even =>
            if n == 0:
                return true
            tmp_n = n - 1
            n = tmp_n
            tag = odd
            goto loop
        odd =>
            if n == 0:
                return false
            tmp_n = n - 1
            n = tmp_n
            tag = even
            goto loop
```

The actual implementation may share one trampoline body, clone bodies
per public entry point, or introduce an internal dispatcher. The
observable behavior must be unchanged.

### 7.3 Heterogeneous Mutual SCCs

Mutually recursive functions in an SCC may have different parameter
lists, parameter types, local state, or entry signatures.

The compiler must choose one of the following strategies:

1. **Tagged frame lowering.** Build an internal tagged frame with one
   variant per function in the SCC. Each recursive edge evaluates
   arguments into temporaries, writes the target variant fields, updates
   the dispatch tag, and jumps to the trampoline loop.
2. **Shared normalized frame lowering.** When signatures are compatible
   or can be represented by a common frame, normalize parameters into a
   shared frame and dispatch by tag.
3. **Per-entry trampoline lowering.** Clone or specialize trampoline
   bodies per public entry point while preserving stack-constant SCC
   transitions.
4. **Rejection.** Reject only when the compiler cannot preserve the
   observable call semantics with a verified stack-constant lowering.

For hand-written With code, heterogeneous SCC support is expected to be
important. Users may reasonably write mutually recursive functions with
different parameter types or local state.

Migrator-generated SCCs, however, can usually be made homogeneous by
construction. A C migrator can place all state live across labels into a
single shared state record and generate label functions with a common
signature such as:

```with
@[tailrec]
fn label_NAME(s: &mut MatchState) -> c_int:
    ...
```

Under this design, every function in the SCC takes the same shared state
parameter and returns the same result type. Therefore, heterogeneous SCC
support is not required for the initial TCO-based migrator path, as long
as the migrator commits to a shared-state-per-SCC representation.

A v1 implementation may reject heterogeneous SCCs, but if it does so,
the diagnostic must say that mutual `@[tailrec]` with differing
signatures is not yet supported. This is an implementation limitation,
not a semantic restriction of the language design.

Example:

```with
@[tailrec]
fn foo(x: i32) -> R:
    bar("hello")

@[tailrec]
fn bar(s: str) -> R:
    foo(42)
```

Conceptual tagged-frame lowering:

```text
type TailTag { foo, bar }

type TailFrame {
    tag: TailTag,
    foo: { x: i32 },
    bar: { s: str },
}

loop:
    match frame.tag:
        foo =>
            x = frame.foo.x
            ...
            tmp_s = "hello"
            frame.bar.s = tmp_s
            frame.tag = bar
            goto loop
        bar =>
            s = frame.bar.s
            ...
            tmp_x = 42
            frame.foo.x = tmp_x
            frame.tag = foo
            goto loop
```

### 7.4 Backend Tail Calls

Backend `tail` hints are insufficient for `@[tailrec]` because they are
optimization requests, not portable guarantees.

Backend `musttail` is acceptable only when all target ABI requirements
are satisfied and the compiler can verify that the backend is required
to emit a no-stack-growth transfer.

If `musttail` cannot be emitted for a recursive edge, the compiler must
use an explicit trampoline or reject the program.

### 7.5 Return ABI Constraints

Guaranteed TCO must account for return ABI shape, calling convention,
parameter ABI, varargs, generic instantiations, imported functions,
async lowering, and target-specific constraints.

The compiler must use a concrete decision procedure rather than a vague
"try tail call" policy.

Baseline decision table:

| Case                                                                    |      Guaranteed `@[tailrec]` allowed? | Required behavior                                                                    |
| ----------------------------------------------------------------------- | ------------------------------------: | ------------------------------------------------------------------------------------ |
| Self recursion with same function ABI                                   |                                   Yes | Lower to loop or verified `musttail`                                                 |
| Mutual recursion with identical calling convention and compatible frame |                                   Yes | Lower to trampoline or verified `musttail`                                           |
| Mutual recursion with differing parameter types                         | Yes, if frame lowering is implemented | Use tagged or normalized frame; otherwise reject as unsupported                      |
| Different calling conventions across recursive edge                     |                            Usually no | Reject unless explicit trampoline erases the boundary safely                         |
| Scalar return with identical return ABI                                 |                                   Yes | Preserve normal return semantics                                                     |
| Aggregate return by value                                               |                           Conditional | Allow only if lowering preserves aggregate return ABI                                |
| sret or hidden return slot                                              |                           Conditional | Allow only if caller and callee return-slot semantics are preserved                  |
| Different return ABI shapes inside an SCC                               |                            Usually no | Reject unless trampoline normalizes return representation safely                     |
| Varargs recursive edge                                                  |         No in baseline implementation | Reject                                                                               |
| Generic instantiations with identical monomorphized ABI                 |                                   Yes | Treat as normal compiled functions after monomorphization                            |
| Generic instantiations with incompatible ABI                            |                                    No | Reject                                                                               |
| Imported or external recursive edge                                     |                                    No | Reject; compiler cannot rewrite external body                                        |
| Function-pointer recursive edge                                         |                           Conditional | Allow only if target SCC is statically proven and lowerable                          |
| Async function recursive edge                                           |         No in baseline implementation | Reject unless async lowering provides an explicit stack-constant state-machine proof |
| Fiber-spawning or scheduler-mediated call                               |                      No as normal TCO | Reject unless semantics are explicitly modeled as stack-constant transfer            |

The implementation may expand the "conditional" cases over time, but
it must never silently fall back to stack-growing calls for `@[tailrec]`.

### 7.6 Argument Evaluation And Assignment

For every recursive edge, argument evaluation must preserve normal call
semantics:

* Evaluate arguments in the language-defined order.
* Store evaluated arguments in temporaries before overwriting source
  parameters or frame fields.
* Run any required pre-call drops before the tail transfer.
* Reject if any required cleanup must happen after the call returns.
* Preserve aliasing, borrowing, lifetime, and mutation semantics.

Example:

```with
@[tailrec]
fn rotate(a: i64, b: i64) -> i64:
    rotate(b, a)
```

The lowering must behave like:

```text
tmp0 = b
tmp1 = a
a = tmp0
b = tmp1
goto loop
```

not:

```text
a = b
b = a   // wrong: original a has been lost
```

---

## 8. Ownership, Drops, And Defers

A tail call is not valid if any work must run after it returns.

The compiler must reject `@[tailrec]` recursive edges when:

* A `defer` or `errdefer` is active.
* A live local with `Drop` must be dropped after the call.
* A borrow or lifetime rule requires post-call cleanup.
* The call result needs conversion, wrapping, destructuring, storage, or
  return-slot adjustment after return.

If a value can be proven dead before the tail call, it may be dropped
before the call and the call may remain tail-position.

Example:

```with
@[tailrec]
fn bad(n: i64) -> i64:
    let resource = acquire()
    if n == 0:
        0
    else:
        bad(n - 1) // error if resource must be dropped after the call
```

Possible accepted form if the drop is explicit and complete before the
recursive edge:

```with
@[tailrec]
fn good(n: i64) -> i64:
    let resource = acquire()
    release(resource)
    if n == 0:
        0
    else:
        good(n - 1)
```

---

## 9. Diagnostics

Diagnostics must name the exact recursive edge that violates the
contract.

Required diagnostic classes:

* Recursive call is not in tail position.
* Recursive call has active `defer` or `errdefer`.
* Recursive call leaves a `Drop` local live across the call.
* Recursive call requires post-call conversion, wrapping, storage, or
  destructuring.
* Mutual recursive SCC contains an unannotated function.
* Mutual recursive SCC cannot be lowered with stack-constant control
  flow.
* Recursive edge requires an unsupported ABI shape.
* Recursive edge crosses unsupported calling conventions.
* Recursive edge uses varargs or an unsupported external/imported
  target.
* Mutual recursive SCC has heterogeneous signatures unsupported by the
  current implementation.

Example:

```text
error: recursive call is not in tail position
  --> foo.w:12:16
   |
12 |     1 + fact(n - 1)
   |         ^^^^^^^^^^^ call result is used by `+`
note: function is annotated `@[tailrec]`
```

Example for mutual recursion:

```text
error: mutual tail-recursive cycle cannot be guaranteed stack-constant
  --> parser.w:44:20
   |
44 |     parse_expr(ctx)
   |     ^^^^^^^^^^^^^^^ recursive edge enters `parse_expr`
note: `parse_expr` is in the same recursive SCC as `parse_stmt`
note: `parse_expr` is not annotated `@[tailrec]`
help: annotate every function in the SCC, or break the recursive cycle
```

Example for unsupported ABI:

```text
error: recursive edge requires unsupported return ABI for `@[tailrec]`
  --> foo.w:31:12
   |
31 |     return bar(x)
   |            ^^^^^^ recursive edge returns through an incompatible sret slot
note: `@[tailrec]` requires verified stack-constant lowering
help: use an explicit loop/state machine, or change the functions to share a compatible return ABI
```

Example for heterogeneous SCC support not implemented:

```text
error: mutual `@[tailrec]` cycle has differing function signatures
  --> control.w:88:16
   |
88 |     return next_label(state, code)
   |            ^^^^^^^^^^^^^^^^^^^^^^^ recursive edge changes active SCC frame shape
note: the language permits this with tagged-frame trampoline lowering
note: this compiler version does not yet implement heterogeneous SCC lowering
```

---

## 10. C Migrator Implications

The C migrator may use guaranteed TCO as an alternative lowering for
`goto`-heavy functions only when mutual `@[tailrec]` is actually
guaranteed by the compiler.

A label-to-function lowering would translate each label and synthetic
continuation into a `@[tailrec]` helper over a shared state record:

```with
type MatchState {
    // Original parameters.
    start_eptr: PCRE2_SPTR,
    start_ecode: PCRE2_SPTR,
    top_bracket: c_uint,
    frame_size: c_ulong,
    match_data: *mut pcre2_real_match_data_8,
    mb: *mut match_block_8,

    // Locals live across gotos.
    F: *mut heapframe,
    P: *mut heapframe,
    rrc: c_int,
    Freturn_id: c_int,
}

@[tailrec]
fn match_LABEL(s: &mut MatchState) -> c_int:
    ...
```

Control-flow mapping:

* `goto LABEL` becomes `return match_LABEL(s)`.
* `continue` becomes `return loop_top(s)`.
* `break` from a switch becomes `return after_switch(s)`.
* `break` from a loop becomes `return after_loop(s)`.
* Switch fallthrough becomes `return next_case(s)`.
* C label fallthrough becomes a direct tail call to the next block.

This approach is only safe if mutual `@[tailrec]` is guaranteed. If it
depends on optional backend tail-call optimization, it is not acceptable
for migration correctness.

Therefore, the migrator has three possible strategies:

1. **State machine lowering.** Translate C control flow into an explicit
   dispatcher/state machine. This is the safe near-term path and does
   not depend on TCO.
2. **TCO-based lowering with opportunistic backend tail calls.** This is
   not acceptable for correctness-sensitive migrations, because it can
   silently grow the stack.
3. **TCO-based lowering after mutual trampoline support.** This is
   acceptable only after the compiler implements verified stack-constant
   mutual `@[tailrec]` lowering.

For PCRE2-style migrations, the TCO-based approach must not be treated
as viable until mutual-TCO Phase 3 is implemented and tested. Until
then, explicit state machine lowering remains the correctness-preserving
path.

A TCO-based migrator does not need heterogeneous mutual SCC support if
it uses a shared state record per SCC. In that design, label functions
are signature-homogeneous even if the original C labels had different
live local-variable sets. Heterogeneous SCC support remains valuable for
hand-written With code, but v1 may reject heterogeneous SCCs without
blocking the shared-state migrator design.

---

## 11. Implementation Plan

### Phase 1: Tighten Verification

* Build the recursive SCC graph for all functions.
* For every `@[tailrec]` function, identify its SCC.
* Require every function in a recursive SCC to be annotated.
* Verify every recursive SCC edge is in tail position.
* Track active `defer`, `errdefer`, and `Drop` obligations.
* Detect post-call conversion, wrapping, storage, destructuring, and
  return-slot adjustment.
* Reject unsupported ABI edges using the decision table in Section 7.5.
* Add diagnostics that identify the exact recursive edge.

### Phase 2: Self-TCO Lowering

* Keep MIR-level parameter reassignment plus jump-to-entry lowering.
* Preserve call evaluation order with temporaries.
* Add tests for aliasing-sensitive parameter reassignment.
* Add tests for active cleanup rejection.
* Add tests for result coercion/wrapping rejection.

### Phase 3: Mutual-TCO Lowering

* Implement explicit SCC trampoline lowering.
* Represent the active function with a dispatch tag.
* For identical signatures, reuse one shared parameter vector where
  possible.
* For differing signatures, use a tagged frame or normalized shared
  frame.
* Replace recursive edges with:

  * argument evaluation into temporaries,
  * frame writes,
  * tag update,
  * jump back to the trampoline loop.
* Preserve entry-point behavior for each public function in the SCC.
* Add tests for two-function, three-function, and heterogeneous SCCs.

Phase 3 is the gating phase for any correctness-preserving TCO-based C
`goto` lowering.

### Phase 4: Backend Integration

* Emit `musttail` only when ABI constraints are proven for the entire
  recursive SCC.
* Never use non-guaranteed backend `tail` hints to satisfy
  `@[tailrec]`.
* Keep backend hints available for ordinary opportunistic TCO.
* Add target-specific tests proving no stack growth where `musttail` is
  used.

---

## 12. Current Implementation Status

As of this document:

* Self-recursive `@[tailrec]` lowering exists in MIR as parameter
  reassignment plus `goto` to entry.
* Mutual `@[tailrec]` SCCs are guaranteed only when every member is a
  compiler-visible local function, every member is explicitly
  annotated, all signatures and calling conventions match, every
  recursive edge is in verified tail position, and no active
  `defer`/`errdefer` cleanup remains across the recursive edge.
* For that guaranteed subset, the backend emits LLVM `musttail` on the
  recursive SCC edges rather than relying on opportunistic `tail`
  optimization.
* When the guarantee cannot be proven, the compiler rejects the
  program with a diagnostic. This includes unannotated SCC members,
  incompatible signatures/calling conventions, and recursive edges that
  are not in guaranteed tail position.

The current implementation is therefore sufficient for language-level
`@[tailrec]` guarantees on homogeneous local recursive SCCs, including
two-function and three-function cycles that lower to direct tail-edge
forwarding in MIR.

The current implementation does not attempt heterogeneous trampoline
lowering. Cycles that require differing parameter layouts or calling
conventions are rejected rather than lowered through a tagged frame.

---

## 13. Test Requirements

Minimum tests:

* Self-tail recursion runs with large depth and constant stack usage.
* Non-tail self recursion under `@[tailrec]` is rejected.
* Tail recursion with active `defer` is rejected.
* Tail recursion with active `errdefer` is rejected.
* Tail recursion with live `Drop` local is rejected.
* Tail recursion requiring post-call result wrapping is rejected.
* Tail recursion requiring post-call result coercion is rejected.
* Aliasing-sensitive parameter reassignment preserves normal call
  semantics.
* Mutual two-function recursion is stack-constant.
* Mutual three-function recursion is stack-constant.
* Mutual recursion with one unannotated function is rejected.
* Mutual recursion with a non-tail edge is rejected.
* Mutual recursion with incompatible ABI is rejected.
* Mutual recursion with differing signatures either lowers through a
  tagged frame or produces the required unsupported diagnostic.
* Mutual recursion through varargs is rejected.
* Mutual recursion through imported/external functions is rejected.
* Ordinary unannotated tail calls compile without requiring TCO.

Migrator-specific tests:

* Label-to-function lowering for simple `goto`.
* Label-to-function lowering for loops with `break` and `continue`.
* Label-to-function lowering for switch fallthrough.
* RMATCH/RRETURN-style macro-expanded labels.
* PCRE2 `match_()`-style dispatch must not grow stack through label
  transitions.
* TCO-based migrator lowering is disabled or rejected when mutual
  `@[tailrec]` cannot be guaranteed.

---

## 14. Non-Goals And Open Questions

### Non-goals

* Guaranteed TCO for arbitrary non-recursive calls.
* Guaranteed TCO through unknown function pointers.
* Guaranteed TCO for ordinary unannotated recursion.
* Reliance on backend optimization levels for language correctness.
* Treating LLVM `tail` as sufficient for `@[tailrec]`.

### Open questions

* Should heterogeneous mutual SCC lowering be required in the first
  implementation of Phase 3, or may v1 reject it with a targeted
  diagnostic?
* Should the compiler prefer tagged-frame trampolines or per-entry
  trampoline specialization for heterogeneous SCCs?
* How should debug info represent trampoline-lowered mutual recursion?
* Should the language expose any control over trampoline lowering, or
  should `@[tailrec]` remain the only user-facing annotation?
* Which target ABIs support verified `musttail` strongly enough to use
  it instead of explicit trampoline lowering?

The default answer should remain conservative: if the compiler cannot
prove stack-constant behavior, it must reject `@[tailrec]` rather than
silently emitting stack-growing code.
