//! expect-stdout: ok

// §4.8: []mut T as a parameter type — the callee receives a writable view of
// the caller's collection; the call site passes the collection itself, with
// no annotation (#604 stage 1).

fn zero(buf: []mut i32):
    var i = 0
    while i < buf.len():
        buf[i] = 0
        i = i + 1

fn sum(xs: []i32) -> i32:
    var s = 0
    for x in xs:
        s = s + x
    s

fn main:
    var a = [3, 4, 5]
    assert(sum(a) == 12)
    zero(a)
    assert(sum(a) == 0)
    print("ok")
