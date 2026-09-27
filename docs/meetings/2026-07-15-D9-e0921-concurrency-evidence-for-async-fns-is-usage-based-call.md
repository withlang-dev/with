# D9 — E0921 concurrency evidence for async fns is usage-based (call/reference sites), not declaration-based

**Date:** 2026-07-15
**Status:** Accepted

### The decision

The global-data-race proof (§9.1) treats an `async fn` as concurrency
evidence at the sites where a fiber can actually come from it — direct
calls, generic calls, method calls (plain, generic, dyn-trait), and
references that coerce the fn to a callable value — not at the bare
declaration. Async blocks/scopes, `thread.spawn_os`, `@[c_export]`, and
extern-"C" callback coercions keep their existing evidence points
(`@[c_export]` stays declaration-based: presence *is* the external-caller
hazard).

### Context / why

`check_bodies` recorded evidence for every checked non-generic async fn
declaration. When #489 added `async fn task_cancel_point` to prelude-merged
`std.task`, every ZCU — including the compiler's own stage builds and every
user program with a mutable global — failed E0921 despite never creating a
fiber (offset-proven to lib/std/task.w:27 across the stage2 stderr). The
same defect already shipped: `use std.time` alone (uncalled `async fn
sleep`) poisoned any program with a mutable global. §9.1's obligation is
"the program *uses* no async construct"; its example labels a call site
("program creates fibers here"), and it explicitly classifies precision
improvements as compiler quality work, never a semantic change.

Alternatives weighed: exempting std-implementation decls from evidence
(unsound — `std.time.sleep(d)` called from user code creates concurrency
with zero user-side async decls); making `task_cancel_point` generic or
respelling the cancel edge (dodges the imprecision, leaves the prelude
landmine armed for the next non-generic async std fn).

Coverage was verified by matrix: uncalled decls (own and std) are clean;
direct/generic/method/dyn/fn-value routes, async blocks, and instantiated
combinator internals all still fail the proof. `test/compile_errors/
err_global_*` fixtures now call their async fn so the concurrency they
assert is real. Speculative overload probes (`generic_overload_match_score`)
never run call checking, so discarded candidates record no evidence.

Reopen if: a new fiber-creation route bypasses the hooked resolution
points (e.g. async fn values become spellable through paths other than
`check_ident`'s visible-sig coercion), or the runtime gains a way to start
fibers without any call/block/scope construct.

---
