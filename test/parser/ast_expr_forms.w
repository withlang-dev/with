//! expect-exit: 11

fn score(v: i32) -> i32:
    match v:
        0 => 1
        n => n

fn main:
    let xs = [1, 2, 3]
    var acc = 0
    for i in 0..3:
        acc = acc + i
    while acc < 10:
        acc = acc + 1
    score(xs[0] + acc)
