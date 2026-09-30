//! expect-check-fail: allocating callee allocates here

// #1941: the callee is declared after the @[no_alloc] caller; whether it
// allocates is known only once every body is checked.
@[no_alloc]
fn main:
    let msg = make_message()
    msg.len()

fn make_message -> str:
    f"value={1}"
