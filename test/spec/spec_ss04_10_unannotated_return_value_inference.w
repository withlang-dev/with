//! expect-stdout: ok

fn one:
    return 1

fn main:
    assert(one() == 1)
    print("ok")
