//! expect-stdout: ok

// #659: early `return <comparison>` must infer bool.
fn check(v: i32):
    if v > 100:
        return v == 200
    v == 3

fn main:
    assert(check(3))
    assert(not check(4))
    assert(check(200))
    assert(not check(201))
    print("ok")
