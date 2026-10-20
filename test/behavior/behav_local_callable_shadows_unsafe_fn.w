//! expect-stdout: 2
//! expect-stdout: 4
//! expect-stdout: 10

// #2235's declaration-time unsafe check reads a generic body by spelling.
// A local callable named like an `unsafe fn` is the local, as a parameter
// is: `danger(1)` calls the closure, which needs no unsafe context. (The
// in-unit runtime's `let release = transmute(...)`, `release(0)` read as a
// c_import's raw `release`, D30.)
unsafe fn danger(x: i32): x

fn apply[T](v: T) -> i32:
    let danger = (x: i32) => x + 1
    danger(1)

fn nested[T](v: T) -> i32:
    let danger = (x: i32) => x * 2
    if true:
        return danger(2)
    0

fn plain() -> i32:
    let danger = (x: i32) => x * 10
    danger(1)

fn main:
    print(f"{apply(3)}")
    print(f"{nested(3)}")
    print(f"{plain()}")
