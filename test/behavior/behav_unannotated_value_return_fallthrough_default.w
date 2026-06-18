//! expect-stdout: ok

fn maybe(flag: bool):
    if flag:
        return 7
    let _ = 0

fn main:
    assert(maybe(true) == 7)
    assert(maybe(false) == 0)
    print("ok")
