// Wave 8: liveness-sensitive conflict after branch join.

type Pair = {
    a: i32,
    b: i32,
}

fn read(x: &i32) -> i32:
    *x

fn main -> i32:
    let mut p = Pair { a: 1, b: 2 }
    let r = &p.a

    if p.b > 0:
        let _ = p.b

    let w = &mut p.a
    *w = 3
    read(r)
