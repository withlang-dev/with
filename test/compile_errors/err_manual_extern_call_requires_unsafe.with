//! expect-error: manual extern function call requires unsafe context

extern "C" fn atoi(s: *const u8) -> i32

fn main:
    let x = atoi(c"42".ptr)
