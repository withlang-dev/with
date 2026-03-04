// Wave 10: aggregate pass/return ABI smoke coverage.

type Pair = {
    x: i32,
    y: i32,
}

fn make_pair(x: i32, y: i32) -> Pair:
    Pair { x: x, y: y }

fn bounce(p: Pair) -> Pair:
    p

fn sum_pair(p: Pair) -> i32:
    p.x + p.y

fn main -> i32:
    let p = make_pair(4, 5)
    let q = bounce(p)
    assert(sum_pair(q) == 9)
    0
