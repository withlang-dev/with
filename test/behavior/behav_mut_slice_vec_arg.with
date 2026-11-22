//! expect-stdout: ok

// #604 stage 1: a plain List argument coerces to a []mut T parameter with zero
// annotation at the call site; the callee's writes land in the caller's List.

fn fill(buf: []mut i32, val: i32):
    var i = 0
    while i < buf.len():
        buf[i] = val
        i = i + 1

fn main:
    let v: List[i32] = List.new()
    v.push(1)
    v.push(2)
    v.push(3)
    fill(v, 5)
    assert(v[0] == 5 and v[1] == 5 and v[2] == 5)
    print("ok")
