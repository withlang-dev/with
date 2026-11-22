//! expect-stdout: ok

fn choose(ok: bool) -> i32:
    match ok:
        true => 7
        false =>
            assert(true)
            9

fn classify(n: i32) -> i32:
    match n:
        0 =>
            assert(true)
            1
        _ => 2

fn main:
    assert(choose(true) == 7)
    assert(choose(false) == 9)
    assert(classify(0) == 1)
    assert(classify(3) == 2)
    print("ok")
