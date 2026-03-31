//! expect-stdout: ok

use issue57.local_shadow
use issue57.other_ids

fn main:
    let start = make(41)
    let next_id = next(start)
    assert(to_i32(next_id) == 42)
    assert(plus_one(10) == 11)
    print("ok")
