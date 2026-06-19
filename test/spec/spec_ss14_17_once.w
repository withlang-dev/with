//! expect-stdout: ok

use std.sync

extern fn with_runtime_run_one_step() -> Unit

var ONCE_COUNT = 0

fn init_once:
    unsafe:
        ONCE_COUNT = ONCE_COUNT + 1

async fn run_once(once: &Once) -> i32:
    once.call_once(init_once)
    0

fn drive_pair(a: &Task[i32], b: &Task[i32]):
    var steps = 0
    while (not a.is_done() or not b.is_done()) and steps < 64:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1

fn main:
    unsafe { ONCE_COUNT = 0 }
    let once = Once.new()
    let a = run_once(&once)
    let b = run_once(&once)
    drive_pair(&a, &b)
    assert(a.await == 0)
    assert(b.await == 0)
    once.call_once(init_once)
    unsafe { assert(ONCE_COUNT == 1) }
    print("ok")
