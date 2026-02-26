// Test variant shorthand (.Member) syntax

type Color = Red | Green | Blue

fn main -> i32:
    let c: Color = .Green
    let val = match c
        .Red -> 1
        .Green -> 2
        .Blue -> 3
    assert(val == 2)
