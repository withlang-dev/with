//! expect-check-fail: cannot infer return type

// #1196: a function with no annotation is typed before the first declaration
// that calls it, so declaration order does not matter — except in a cycle,
// where neither body can be typed first: the one checked first sees the other
// as untyped, and is told to write its return type.
fn ping(n: i32): pong(n - 1) + 1

fn pong(n: i32): if n <= 0: 0 else: ping(n - 1)

fn main:
    let n: i32 = ping(3)
    print(f"{n}")
