//! expect-check-fail: returned `move` closure keeps its environment in this call's frame

// #1567: a `move` closure's environment is still a slot of the creating
// frame today, so returning it would read a dead frame. Rejected loudly
// until D63 (a `move ||` closure owns its environment) is implemented.
fn mk(x: i32) -> fn() -> i32: move () => x * 10

fn main:
    let f = mk(2)
    print(f())
