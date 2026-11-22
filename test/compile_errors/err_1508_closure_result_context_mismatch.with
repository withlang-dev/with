//! expect-check-fail: closure declares `-> i64` where a closure returning `i32` is expected

// D71 / §12 (#1508): a closure's `-> T` is its result type, never dropped.
// Passed where a closure returning another type is expected, it is a
// mismatch. The parser dropped the `-> i64`, so this compiled as a closure
// returning i32. The check is the closure's own: fn types are otherwise
// never compared (#1772), and the closure would reach `apply` returning an
// i64 that `apply` reads as an i32.

fn apply(f: fn(i32) -> i32, v: i32) -> i32: f(v)

fn main:
    print(apply((x: i32) -> i64 => x, -3))
