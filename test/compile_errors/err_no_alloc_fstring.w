//! expect-check-fail: f-string allocates here

@[no_alloc]
fn main:
    let _s = f"value={1}"

