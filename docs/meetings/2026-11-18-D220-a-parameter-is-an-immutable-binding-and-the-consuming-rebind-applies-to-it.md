# D220 — A parameter is an immutable binding, and the consuming rebind applies to it

**Laws:** 4 (`mut` on a parameter means one thing: the caller's place), 1.

**Date:** 2026-11-18. **Status:** ruled by Eric.

**Context.** #690: `fn f(x: i32): x = x + 1` is refused ("cannot assign to
immutable variable") and the spec said nothing either way. `mut x: T`
already means exclusive in-place access to the caller's place (§3.8a,
D172), so a mutable parameter cannot also mean a local that may be
reassigned. `var x = x` was refused as shadowing.

**Ruling.**

- Parameters are immutable bindings; §9 says so. The error for assigning
  to one names both real fixes: a local copy, or `mut x: T` when the
  caller's variable is meant to change.
- `var x = x` should already work. §29.8's consuming-rebind exception lets
  a new binding reuse a name when its initializer consumes the old one, and
  a parameter is a local binding. Refusing it there was an inconsistency
  with the existing rule, not a missing exception. It is the local-copy
  spelling.

**Alternatives.** Implicitly rebindable parameters: `x = x + 1` would mean
a local change on `x: T` and a write to the caller on `mut x: T`. A special
exception to no-shadowing for parameters: not needed, since §29.8 already
covers it.
