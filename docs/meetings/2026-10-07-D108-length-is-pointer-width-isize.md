# D108 — Length is pointer-width: `len()` returns `isize`

**Laws:** 1, 4 (docs/mission.md).

Ruled by Eric, 2026-10-07. Extends D11, which ruled signedness and left
the width to what the runtime already stored.

## Ruling (verbatim)

> Rule `isize`. The C-interop argument is decisive and it's the right kind
> of argument — a structural one about the boundary, not a taste one about
> width.
>
> With is a C-first language whose length is already signed by ruling. C's
> signed length type is `ssize_t`/`ptrdiff_t`: pointer-width. Put those
> together and `isize` is simply "D11's signedness at C's width." The payoff
> is that the shape of the boundary becomes target-invariant: a `len()`
> meeting a `size_t` is a sign change on every target, nothing more. With
> `i64`, the boundary is a sign change on 64-bit hosts and a sign change
> plus a narrowing on wasm32 — which means every migrated corpus has a cast
> that exists on one target and not another. Don't make the migrator's
> output depend on target width.
>
> "Never platform-dependent" is a real value: with `isize`, `len() * 4` can
> overflow at ~537M elements on wasm32 where it wouldn't on i64. But With
> traps on overflow rather than wrapping — so the failure is a loud trap on
> the one target whose address space can't hold the result anyway, which is
> strictly better than C's silent `size_t` wrap on 32-bit. The value
> survives for `Int`, which stays the fixed 64-bit alias for programs that
> want one width for serialization or protocol fields. Lengths don't need
> to be `Int`; they need to be the machine's.
>
> Cost: zero on every 64-bit target — a type-name change. Real on wasm32,
> where the runtime's 64-bit length fields become 32 — and #2131 is the
> wasm32 campaign, so this is the cheapest moment it will ever be.

## Spec words (blessed)

§18.6: `len()`, `count()` and `position()` return `isize`, the signed
pointer-width integer: 64 bits on every supported target but wasm32,
where it is 32. `Int` stays the fixed 64-bit alias.

§4.2: `usize` and `isize` are pointer-width: 64 bits on every supported
target but wasm32, where they are 32. (The previous sentence, "64-bit on
all supported targets", predated the wasm32 target and was wrong.)

## The brief

**What the others do** (verified in `.reference/`): Go `len` returns
`int`, pointer-width (`builtin.go:179`); Swift `count` is `Int`,
pointer-width (`Array.swift:821`); Rust and Zig return `usize`,
pointer-width unsigned; Vale `len` is a fixed `int` (`str.vale:24`). Four
of five track the machine. C, the primary interop target: `size_t`
unsigned and `ssize_t`/`ptrdiff_t` signed, all pointer-width; `c_import`
already maps them per target.

**What the spec said.** `types.md`: "`Int` is an alias for `i64`. Always
64-bit, never platform-dependent"; "Pointer-sized integers: `usize`,
`isize` (64-bit on all supported targets)". §18.6: "`.len()` returning
`Int` (i64)". D11 chose `Int` because the runtime stored lengths as `i64`
and did not weigh the width.

**Mission fit.** Law 1: the width of a length is a representation, and a
default picks representations per target. Law 4, read at the C boundary:
the boundary's shape must not depend on the target, or a cast exists on
one target and not another and every tool reasoning about the boundary
gains a second axis. The fixed width stays available as `Int`.

**Prediction** (recorded as made at the time it was asked for, with the
process note below): `isize`, 75%.

## Process note

The prediction before this one went 70% `i64`, then 60% `isize`, then 75%
`isize`, each flip tracking the question that preceded it. Eric: "That
isn't evidence updating; that's the brief steering toward the questioner.
The right move at 'why 64 bits?' was the width brief immediately, with one
prediction, rather than a defense of i64 followed by a reversal. A
prediction that follows the asker's lead is worth nothing as a check on
the ruling." The rule for briefs: when a question reveals an unruled
choice, write the brief at once with one prediction, and change it only
for evidence, saying what the evidence was.

## Implementation

#2262: Sema sizes `isize`/`usize` by the target (today they are registered
at 64 bits whatever the target, so `let c: isize = b` with `b: i64` is
accepted implicitly and would be a silent narrowing on wasm32); the six
`fn len() -> i64` declarations in `lib/std` and `rt` and the iterator
`count()`/`position()` family flip to `isize`; `len64()` stays an alias.
The 5223 `.len() as i32` sites across the tree are legacy cast ceremony
and a separate mechanical sweep. Follow-on #2261: a `length param N`
facade clause for the sign change at the C boundary, the shape of D102's
`nullable param N`.

**What would reopen this:** a 32-bit target where lengths beyond the
address space are a real program's need (none exists), or a ruling that
`Int` itself becomes pointer-width (which would make this entry moot).
