//! expect-check-fail: ephemeral values cannot be stored in non-ephemeral structs

use std.alloc

type Holder {
    xs: ArenaVec[i32],
}

fn main:
    0
