# D104 — Comptime-callability is inferred; `comptime fn` is a checked promise

**Laws:** 4, 1 (docs/mission.md).

Ruled by Eric, 2026-10-07 (#2213).

## Ruling

A function is comptime-callable when nothing it calls, transitively, does
what §17.1 forbids (ambient I/O, directories, environment, clock, network,
processes, FFI, capabilities, host-global state, the runtime heap
allocator). The verdict is a hybrid, chosen rather than inherited from the
implementation:

- `comptime fn` is checked statically at the declaration; its body must
  resolve every callee, so a call through a trait object or a function
  value is refused there;
- a plain function is judged by the evaluator when a compile-time call
  reaches it, where the actual callee of each indirect call is known.

A compile-time call that reaches a forbidden operation reports the chain of
calls to it. The witness chain is a hard requirement: it is what makes
Zig's model livable.

Stated plainly: a plain function called at compile time is still broken by
an upstream `print` added three calls deep. That is Zig's hole, intact for
the common case, and an accepted trade; `comptime fn` is the spelling a
library author uses to promise otherwise, and the diagnostic names the
upstream culprit.

## Why

The doctrine fit is exact: `may_suspend` is already a transitive body
property, and "reaches I/O, C, a capability, the clock or the heap" is the
same fixed-point computation. Making the programmer declare it is writing
what the compiler knows. Zig marks parameters and call sites, never
functions; Rust's `const fn` is explicit and viral; Mojo evaluates ordinary
functions in parameter expressions.

## Consequences

With the heap allocator forbidden, the set of comptime-callable plain
functions is smaller than it sounds (anything touching a `Vec` is out).
Correct as the initial ruling; a comptime allocator (Zig has one) is filed
as the next request rather than awaited as a complaint.
