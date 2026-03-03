fn fallback(flag: bool) -> i32:
    if flag:
        7
    else:
        unreachable()

fn todo_value -> i32:
    todo()

fn main -> i32:
    let x = fallback(true)
    let y: i32 = if true:
        42
    else:
        todo()
    assert(x == 7)
    assert(y == 42)
    0
