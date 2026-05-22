//! expect-stdout: ok

use std.thread

fn worker() -> i32:
    37

fn main:
    let handle = spawn_os(worker)
    assert(join(handle) == 37)
    print("ok")
