// Test match guard clauses and or-patterns

fn classify(x: i32) -> i32 =
    match x
        0 -> 0
        n if n > 0 -> 1
        _ -> 2

fn categorize(x: i32) -> i32 =
    match x
        1 | 2 | 3 -> 10
        4 | 5 -> 20
        _ -> 30

fn main() -> i32 =
    assert(classify(0) == 0)
    assert(classify(5) == 1)
    assert(classify(-3) == 2)

    assert(categorize(1) == 10)
    assert(categorize(2) == 10)
    assert(categorize(3) == 10)
    assert(categorize(4) == 20)
    assert(categorize(5) == 20)
    assert(categorize(99) == 30)
    0
