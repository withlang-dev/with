//! expect-error: call to unsafe function pointer requires unsafe context

// §16.11 (#1829): an `unsafe fn` used as a value keeps its unsafety. The
// unannotated binding took the fn's own safe type, so the call through it
// needed no `unsafe`.

unsafe fn danger(x: i32) -> i32: x + 1

fn main:
    let f = danger
    print(f(1))
