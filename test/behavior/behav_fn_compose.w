//! expect-stdout: ok

// Behavior test: Section 9.6 uses explicit closures for function composition.

fn double(x: i32) -> i32:
    x * 2

fn add1(x: i32) -> i32:
    x + 1

fn main:
    let composed = x => add1(double(x))
    assert(composed(5) == 11)

    let x = 1 << 3
    assert(x == 8)

    let y = 16 >> 2
    assert(y == 4)

    print("ok")
