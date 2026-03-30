//! expect-stdout: ok

// Behavior test: tuple patterns in match expressions

fn classify(pair: (i32, i32)) -> str:
    match pair
        (0, 0) => "origin"
        (0, _) => "y-axis"
        (_, 0) => "x-axis"
        _ => "other"

fn main:
    assert(classify((0, 0)) == "origin")
    assert(classify((0, 5)) == "y-axis")
    assert(classify((3, 0)) == "x-axis")
    assert(classify((1, 2)) == "other")
    print("ok")
