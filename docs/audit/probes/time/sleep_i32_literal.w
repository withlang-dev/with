//! time probe 4 (refutation): is pub async sleep() still callable with a
//! raw i32 literal, given Duration is just `type Duration = i32`?
use std.time
use std.builtins.print_i64

async fn main:
    let t0 = now_ns()
    let rc = sleep(100).await
    let dt = now_ns() - t0
    print_i64(dt)
    assert(rc == 0)
    assert(dt >= 90000000)
    assert(dt <= 5000000000)
    print("ok")
