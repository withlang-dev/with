# D88 — A `const` of unsuffixed numeric literals has no numeric type of its own; each use types it

**Laws:** 2 (docs/mission.md).

**Date:** 2026-10-04. **Status:** BDFL ruling (Eric: "spec words blessed").
Spec v7.20: types.md §4.2.1. Issue #2096. **The compiler is
NON-COMPLIANT**: `const B = 12.0` is `f64`, and `let z: f32 = B` is
rejected as implicit float narrowing.

**Context.** #2096, found writing a raylib game for Wipe, where every
number is `f32`: each float constant had to be annotated
(`const SHIP_SPEED: f32 = 320.0`) or cast at each use, though
`takes32(12.0)` with the literal itself is fine.

**Decision.** A `const` declared without a type, whose initializer is made
only of unsuffixed numeric literals, operators on them, and other such
constants, has no numeric type of its own. Each use is typed as its
initializer would be if written at that use: by the context of the use,
and by the defaults only where the use gives none. A `const` with a
declared type, or whose initializer has a suffixed literal or any other
typed operand, has that type at every use.

**Alternatives.** One type per constant, inferred from all its uses (Rust's
`{float}` variable, widened to module scope): rejected — a constant used as
`f32` in one place and `f64` in another would be an error for no reason the
programmer can see; the literal has no such limit. Leaving it `f64`:
rejected — the programmer writes what the use already determines.

**References.** Go's untyped constants are this rule (go_spec.html,
"An untyped constant has a default type…"). Zig's `comptime_float` is the
same idea for literals and `const` alike. Rust and Swift give the constant
one type at its declaration.

**Reopen if** a constant's value could differ by the type of its use in a
way that surprises (`1.0 / 3.0` is rounded at each use's precision): the
rule is the literal's rule, and the literal has that property today.
