# D153 — An unsuffixed numeric literal where a distinct type over a number is demanded takes the distinct type (delegated)

**Laws:** 1, 2 (docs/mission.md).

**Date:** 2026-10-23. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2567.

**Decision.** `type Id = distinct i32`. Where an `Id` is demanded (a
declared return type, an annotated binding, a parameter, a field, an
`Option`/`Result` payload, a `&Id`) an unsuffixed integer literal is an
`Id`, checked at `i32`'s width; a float literal at a distinct float is the
same. An untyped constant (`const ONE = 1`) used at such a demand follows
its literal. The literal's MIR constant carries the distinct type; codegen
lowers it at the representation (§4.5: a distinct type has its underlying
type's representation). Nothing else changes: `Id` arithmetic, casts and
the comparison rule (`x != 0`, which already typed the literal by its
peer) are as they were.

**Context.** `fn none() -> Id: 0` was refused ("return type mismatch"),
and so were `let x: Id = 0`, `S { a: 5 }` and `f(3)`, while `x != 0` was
accepted. `src/CImport.w` carried 690 `0 as CiStmtId` casts, each a
spelling of what the signature already said. Eric (2026-10-22): a declared
return type is exactly the case where the function states the type instead
of the body casting.

**What the others do.** Go: a defined type over an integer (`type Id
int`) takes an untyped constant directly (`var x Id = 0`); the constant is
converted by the context. Zig: a distinct integer is an enum over it, and
`@enumFromInt` is written. Rust/Swift: newtypes are structs, `Id(0)` is
written. Go's rule is the one with no ceremony and no second meaning: the
literal has no type of its own, the demand gives it one.

**Alternatives.** (a) Keep the cast (`0 as Id`): the user writes what the
signature states, Law 1. (b) The constructor `Id(0)`: the same, and it
reads as a conversion of an `isize`. (c) Let every integer convert into a
distinct type implicitly: that erases the distinction the type exists
for; only a literal, which has no type of its own, takes the demand.

**Prediction.** 90%: Eric asked for it in the issue's words.

**Reopens if** a distinct type over a number ever carries an invariant a
raw literal could break (a non-zero id): then the type would want a
constructor that checks, and the literal rule would be the hole.
