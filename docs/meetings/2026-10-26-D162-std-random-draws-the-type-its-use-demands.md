# D162 — `std.random` draws the type its use demands: `next()` and `range(lo, hi)` over a `Random` trait (delegated)

**Laws:** 1, 2, 9 (docs/mission.md).

**Date:** 2026-10-26. **Status:** delegated (D98): implemented on the
agent's prediction; Eric vetoes by revert. **Issue:** #2279.

**Decision.** `std.random` has `next[T: Random]() -> T` and
`range[T: Random](lo: T, hi: T) -> T`. The type is the one the use forces:
a typed binding or parameter (`let b: u8 = next()`, `push_byte(range(97,
123))`), or the bounds (`range(0, hi)` with `hi: i64`). `Random` is a std
trait implemented for every integer type up to 64 bits and for `f32` and
`f64`; another type becomes drawable by implementing it. Integers are
uniform in [lo, hi) (lo when hi <= lo) over the full 64-bit span; floats
are uniform in [0, 1) for `next` and in [lo, hi) for `range`. `seed` takes
a `u64` (D114: a seed is a fixed-width value). `next_i32`, `range_i32` and
`range_isize` are deleted (Law 9); their users (`List.shuffle`, the
one-liner documents) now call `range`.

**Context.** Eric, reviewing the Goose port: the RNG should generate the
requested type instead of every consumer casting an implementation-chosen
`i32` (`range_i32(97, 123) as u8`); an `i64` interval could not be drawn
at all. The brief on #2279 asked for a numeric trait with arithmetic; none
is needed: each impl is concrete and draws through one 64-bit helper, the
mechanism #959's `Parse` uses, and a generic's result type binds from the
demand (Law 2).

**What the others do.** Rust: `rng.gen::<T>()` and `rng.gen_range(lo..hi)`
over the `Standard` / `SampleUniform` traits, typed by inference. Go:
`rand.Intn`, `Int63n`, `Float64` (one function per type). Swift:
`T.random(in: range)` on each numeric type. Rust's and Swift's shape, typed
by the use as With types everything.

**Prediction.** 80% (brief on #2279), raised by the request being Eric's.

**Reopens if** a program needs a distribution other than uniform (then a
distribution parameter, not a second set of functions), or 128-bit draws.
