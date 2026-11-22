//! expect-stdout: ok

use std.collections.Atomic
var counter: Atomic[i32]

async fn marker() -> i32:
    1

fn main:
    counter.store(1, .SeqCst)
    assert(counter.load(.SeqCst) == 1)
    print("ok")
