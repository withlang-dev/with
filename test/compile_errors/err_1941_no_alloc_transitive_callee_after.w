//! expect-check-fail: allocating callee allocates here

// #1941: allocation reaches the @[no_alloc] caller through a callee that
// only calls an allocating function declared after both.
@[no_alloc]
fn main:
    let n = relay()
    n

fn relay -> i32:
    make_message().len() as i32

fn make_message -> str:
    f"value={1}"
