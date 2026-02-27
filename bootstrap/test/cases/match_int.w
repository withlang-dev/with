fn classify(x: i32) -> i32:
    match x
        1 -> 10
        2 -> 20
        3 -> 30
        _ -> 0

fn main -> i32:
    assert(classify(1) + classify(2) + classify(99) + 12 == 42)
