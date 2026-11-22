//! expect-check-fail: allocating callee allocates here

fn make_message -> str:
    f"value={1}"

@[no_alloc]
fn main:
    let msg = make_message()
    msg.len()

