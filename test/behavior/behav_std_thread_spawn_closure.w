//! expect-stdout: ok

use std.thread

fn main:
    let base = 5
    let handle = spawn_os(() => base + 2)
    assert(join(handle) == 7)
    print("ok")
