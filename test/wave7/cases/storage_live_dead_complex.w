// Wave 7: storage live/dead style coverage over branch joins.

fn compute(a: i32, b: i32) -> i32:
    let mut x = a
    if b > 0:
        let y = x + b
        x = y
    else
        let z = x - b
        x = z
    let w = x * 2
    w

fn main -> i32:
    assert(compute(2, 3) == 10)
    assert(compute(2, -3) == 10)
    0
