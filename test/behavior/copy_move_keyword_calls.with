type Pair { x: i32, y: i32 } with Copy

fn copy(a: i32, b: i32) -> i32:
    a + b

fn move(a: i32, b: i32) -> i32:
    a * b

fn take_pair(p: Pair) -> i32:
    p.x + p.y

fn main:
    assert(copy(2, 3) == 5)
    assert(move(2, 3) == 6)

    let p = Pair { x: 4, y: 5 }
    let q = copy p
    assert(take_pair(q) == 9)
    assert(p.x == 4)
