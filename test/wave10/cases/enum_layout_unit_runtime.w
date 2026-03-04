type Traffic = Red | Yellow | Green

fn score(t: Traffic) -> i32:
    match t
        Red -> 1
        Yellow -> 2
        Green -> 3

fn main -> i32:
    assert(score(Red) == 1)
    assert(score(Yellow) == 2)
    assert(score(Green) == 3)
