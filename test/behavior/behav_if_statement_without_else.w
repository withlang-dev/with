//! expect-stdout: ok

fn statement_if(flag: bool) -> i32:
    var x = 0
    if flag:
        x = 7
    x

fn guard_with_never(flag: bool) -> i32:
    let _unit = if flag: return 10
    20

fn main:
    assert(statement_if(true) == 7)
    assert(statement_if(false) == 0)
    assert(guard_with_never(true) == 10)
    assert(guard_with_never(false) == 20)
    print("ok")
