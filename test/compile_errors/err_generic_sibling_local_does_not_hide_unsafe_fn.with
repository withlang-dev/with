//! expect-check-fail: unsafe function call requires unsafe context

// A local shadows a function only within its own block: one bound in a
// sibling block leaves a later call naming the `unsafe fn` (#2235).
unsafe fn danger(x: i32): x

fn apply[T](v: T) -> i32:
    if true:
        let danger = (x: i32) => x + 1
        print(f"{danger(0)}")
    danger(1)

fn main:
    print(f"{apply(3)}")
