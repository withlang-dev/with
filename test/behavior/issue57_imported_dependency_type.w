//! expect-stdout: ok

use issue57.type_keys
use issue57.local_distinct_ids

fn main:
    let key = ptr_key(7)
    assert(key.arg0 == 7)
    let wrapped = wrap(9)
    assert(unwrap(wrapped) == 9)
    print("ok")
