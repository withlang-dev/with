// Wave 8: branch+loop NLL stress with disjoint field borrows.

type Pair = {
    a: i32,
    b: i32,
}

fn main -> i32:
    let mut p = Pair { a: 2, b: 1 }
    let mut i = 0

    while i < 3:
        let ra = &p.a
        let rb = &mut p.b
        *rb = *rb + *ra
        i = i + 1

    assert(p.b == 7)
    0
