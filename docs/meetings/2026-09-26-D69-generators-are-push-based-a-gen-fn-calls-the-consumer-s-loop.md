# D69 — Generators are push-based: a `gen fn` calls the consumer's loop body at each `yield`

**Laws:** 9, 1 (docs/mission.md).

**Date:** 2026-09-26. **Status:** BDFL ruling (Eric: "blessed. proceed",
after the Go/Rust comparison and the mission reading below).

§13.4 had specified pull generators compiled to a state machine: the
caller calls `next()`, and the generator's locals become fields of a
struct. That model has three defects in With. The state must carry
every local live across a `yield`, which Sema cannot know (#1534: every
`for` in a generator lost its counter). It could not yield a view of
its own locals (a self-referential struct), so §13.4 sent users to
hand-written ephemeral iterator structs. And a generator abandoned
mid-loop held its resources in a frame no scope released.

References (verified in `.reference/`): Rust's `gen` blocks are
coroutines whose layout comes from MIR liveness
(`rustc_mir_transform/src/coroutine/layout.rs`,
`locals_live_across_suspend_points`). Go 1.23's range-over-func is
push: `iter.Seq[V]` is `func(yield func(V) bool)`, and
`cmd/compile/internal/rangefunc` rewrites the loop body into the
closure; `iter.Pull` adds pull on a runtime coroutine. Zig, Swift,
Mojo and Vale have no user generators (hand-written `next()` structs).

Ruling: push. The mission names the language for the `with` scope, "a
resource lives in its scope and is released when the scope ends"; a
push generator is an ordinary function, so its resources are released
by its own scopes, including on an early `break`. The consumer's stop
leaves the generator at its `yield` as if by `return`; a generator
cannot observe or ignore it (Go's run-time "continued after false"
panic cannot occur). Views of the generator's own locals are valid for
the run of the consumer's body. Pull is spelled `g.pull()` because it
allocates a fiber stack; a generator that yields views of its own
locals or may suspend cannot be pulled.

Retired: the state-machine compilation model, the
no-references-across-`yield` rule, and the `.await` prohibition in
generator bodies. #1534's liveness campaign is moot. The compiler is
NON-COMPLIANT until generators lower as calls.

---
