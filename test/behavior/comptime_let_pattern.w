//! expect-stdout: 42
//! expect-stdout: 7
//! expect-stdout: 2
//! expect-stdout: -1

// #2026: the comptime evaluator runs a pattern let (§9.7) — a tuple
// destructure, a mutable one, and a refutable pattern with its `else` —
// as the compiled program does. build.w's `let (rc, audit) = …` reached
// "expression kind 62 is not comptime-evaluable yet" when an action ran in
// the evaluator instead of the native runner.

comptime fn pair() -> (i32, i32):
    (40, 2)

comptime fn sum_pair() -> i32:
    let (a, b) = pair()
    a + b

comptime fn bump_pair() -> i32:
    var (a, b) = pair()
    a = a / 8
    b = b + a
    b

comptime fn second_if_first(first: i32) -> i32:
    let (40, x) = pair() else:
        return -1
    x + first - first

const SUM: i32 = comptime sum_pair()
const BUMP: i32 = comptime bump_pair()
const HIT: i32 = comptime second_if_first(1)
const MISS: i32 = comptime miss()

comptime fn miss() -> i32:
    let (0, x) = pair() else:
        return -1
    x

fn main:
    print(SUM)
    print(BUMP)
    print(HIT)
    print(MISS)
