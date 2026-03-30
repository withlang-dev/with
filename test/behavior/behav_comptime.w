//! expect-stdout: ok

// Behavior test: comptime constant evaluation
// Tests: const declarations with comptime evaluation

const ANSWER: i32 = 42
const DOUBLED: i32 = ANSWER * 2

fn main:
    assert(ANSWER == 42)
    assert(DOUBLED == 84)
    print("ok")
