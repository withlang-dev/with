//! expect-stdout: 1 3 2 3 -1
// #2386 (D117): first(), last() and rest() of a fixed array evaluate at
// compile time, as List's do. They are compiler-declared, with no std body
// for the evaluator to run, and were refused: "method 'first' is not
// comptime-evaluable yet".
const A: [i32; 3] = [1, 2, 3]
const F: i32 = comptime A.first() ?? &-1
const L: i32 = comptime A.last() ?? &-1
const R: i32 = comptime A.rest().first() ?? &-1
const RL: i32 = comptime A.rest().last() ?? &-1
const E: i32 = comptime A.rest().rest().rest().first() ?? &-1

fn main:
    print(f"{F} {L} {R} {RL} {E}")
