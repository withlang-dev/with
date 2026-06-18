//! expect-stdout: ok

const C = 2
global G = 3

fn sum -> i32:
    1 + C + G

fn main:
    assert(sum() == 6)
    print("ok")
