//! expect-stdout: ok

// #604 stage 1: a plain array argument coerces to a []mut T parameter; writes
// through the view are visible in the caller's array after the call.

fn fill(buf: []mut i32, val: i32):
    var i = 0
    while i < buf.len():
        buf[i] = val
        i = i + 1

fn main:
    var a: List[i32] = [0, 0, 0]
    fill(a, 7)
    assert(a[0] + a[1] + a[2] == 21)
    print("ok")
