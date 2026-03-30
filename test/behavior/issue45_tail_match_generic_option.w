//! expect-stdout: ok

fn choose_then_some(ok: bool) -> i32:
    match if ok then Some(7) else None
        Some(v) => v
        None => 0

fn choose_then_none(ok: bool) -> i32:
    match if ok then None else Some(9)
        Some(v) => v
        None => 0

fn choose_all_none(ok: bool) -> Option[i32]:
    if ok then None else None

fn main:
    let direct = Some(5)
    let direct_val = match direct
        Some(v) => v
        None => 0
    assert(direct_val == 5)

    assert(choose_then_some(true) == 7)
    assert(choose_then_some(false) == 0)
    assert(choose_then_none(true) == 0)
    assert(choose_then_none(false) == 9)

    let missing = choose_all_none(true)
    let missing_val = match missing
        Some(v) => v
        None => -1
    assert(missing_val == -1)

    print("ok")
