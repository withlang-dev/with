type A = Same | OnlyA
type B = Same | OnlyB

fn score_a(v: A) -> i32:
    match v
        Same -> 1
        _ -> 0

fn main -> i32:
    let _bad_a: A = .OnlyB
    let _bad_call = score_a(.OnlyB)
