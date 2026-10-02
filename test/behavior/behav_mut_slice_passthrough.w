//! expect-stdout: ok

// #604 stage 1: a []mut T parameter forwards to another []mut T parameter and
// weakens to []T (imm←mut is sound covariance); same fat-pointer ABI.

fn read_first(xs: []i32) -> i32:
    xs[0]

fn fill(buf: []mut i32, val: i32):
    var i = 0
    while i < buf.len():
        buf[i] = val
        i = i + 1

fn fill_then_read(buf: []mut i32) -> i32:
    fill(buf, 4)
    read_first(buf)

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(0)
    v.push(0)
    assert(fill_then_read(v) == 4)
    assert(v[1] == 4)
    print("ok")
