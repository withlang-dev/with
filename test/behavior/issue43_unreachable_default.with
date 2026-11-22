fn maybe(flag: bool) -> Option[i32]:
    if flag:
        Some(7)
    else:
        None

fn main:
    let x = maybe(true) ?? unreachable()
    assert(x == 7)
