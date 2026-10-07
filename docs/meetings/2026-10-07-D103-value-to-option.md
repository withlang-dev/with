# D103 — A value converts to `Option[T]` where one is demanded

**Laws:** 2, 1 (docs/mission.md).

Ruled by Eric, 2026-10-07 (#2217; deferred from D102).

## Ruling

Where an `Option[T]` is demanded and the expression has type `T`, the
expression is `Some(expression)`. `None` and an existing `Option[T]` pass
unchanged. The conversion applies once, at the demand, and never where
nothing is demanded. It does not participate in inference: it applies only
once the demanded type is known, so it never solves a type variable.

Demand propagates into `if`/`match` arms and block tails as demand already
does; operator operands are not demand sites (`opt == 3` stays an error,
or is a separate ruling). Spec §4.9a.

## Why

One meaning (the mission's test for letting the compiler do it); Swift
(`ValueToOptional`), Zig (payload coerces to the optional) and Mojo
(`@implicit` init) do the same; Rust and Scala do not. The two guardrails
are the words "once" (so `Option[Option[T]]` is never guessed — a bare `T`
becomes `Some(x): Option[T]` and is refused) and "does not participate in
inference" (Swift's promotion-in-solving is where its overload-resolution
cost and surprising picks come from).

## Consequences

The `Some(f)` that D102 introduced at callback sites (`s.zalloc = Some(f)`,
`run(Some(twice), 3)`, std's facade calls into migrated definitions) goes
away once this lands; the migrator may keep emitting `Some` in generated
code. Implementation: Sema's demand sites (argument, field, return, binding
annotation, assignment, struct literal, arms and tails), after inference,
before the mismatch check.
