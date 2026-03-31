//! expect-stdout: ok

use issue57.vector_user

fn main:
    assert(sum_pair(19, 23) == 42)
    print("ok")
