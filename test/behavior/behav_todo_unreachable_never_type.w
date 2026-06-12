//! expect-stdout: ok

fn choose(flag: bool) -> i32:
    if flag:
        42
    else:
        todo("not reached")

fn label(flag: bool) -> str:
    match flag:
        true => "ok"
        false => unreachable("not reached")

fn main:
    assert(choose(true) == 42)
    assert(label(true) == "ok")
    print("ok")
