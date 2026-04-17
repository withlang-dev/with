//! expect-stdout: ok

type Pair {
    left: i32,
    right: i32,
}

error E =
    Bad

fn helper_pair(seed: i32) -> Pair:
    Pair { left: seed, right: seed + 1 }

fn helper_pair_sum(seed: i32) -> i32:
    let pair = helper_pair(seed)
    pair.left + pair.right

fn option_from_if(ok: bool) -> Option[i32]:
    if ok then Some(7) else None

fn result_from_if(ok: bool) -> Result[Pair, E]:
    if ok then Ok(helper_pair(10)) else Err(.Bad)

fn pair_from_match(ok: bool) -> Pair:
    match ok:
        true => Pair { left: 1, right: 2 }
        false => Pair { left: 3, right: 4 }

fn main:
    assert(helper_pair_sum(4) == 9)

    let some = option_from_if(true)
    let some_val = match some:
        Some(v) => v
        None => 0
    assert(some_val == 7)

    let none = option_from_if(false)
    let none_val = match none:
        Some(v) => v
        None => -1
    assert(none_val == -1)

    let ok_pair = match result_from_if(true):
        Ok(v) => v
        Err(_) => Pair { left: 0, right: 0 }
    assert(ok_pair.left == 10)
    assert(ok_pair.right == 11)

    let err_pair = match result_from_if(false):
        Ok(v) => v
        Err(_) => Pair { left: -1, right: -2 }
    assert(err_pair.left == -1)
    assert(err_pair.right == -2)

    let match_true = pair_from_match(true)
    let match_false = pair_from_match(false)
    assert(match_true.left == 1)
    assert(match_true.right == 2)
    assert(match_false.left == 3)
    assert(match_false.right == 4)

    print("ok")
