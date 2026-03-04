// Wave 6: break-with-value join typing.

fn choose(flag: bool) -> i32:
    let out = loop:
        if flag:
            break 10
        else:
            break 20
    out

fn main -> i32:
    assert(choose(true) == 10)
    assert(choose(false) == 20)
    0
