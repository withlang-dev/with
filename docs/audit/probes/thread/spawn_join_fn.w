//! thread probe 1: named-fn worker, join returns its value.
use std.thread

fn worker() -> i32:
    37

fn main:
    let handle = spawn_os(worker)
    assert(join(handle) == 37)
    print("ok")
