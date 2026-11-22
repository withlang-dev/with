//! expect-error: the initializer of global `x` reads its own value
// D175: an initializer may read a global through a function it calls, and
// `bump` reads `x` itself, before `x` has a value.
let x: i64 = bump()

fn bump() -> i64: x + 1

fn main:
    print(f"{x}")
