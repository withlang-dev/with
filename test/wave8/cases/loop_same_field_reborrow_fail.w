// Wave 8: same-field reborrow conflict baseline in loop-shaped flow.

type Pair = {
    a: i32,
    b: i32,
}

fn main -> i32:
    let mut p = Pair { a: 1, b: 2 }
    let ra = &p.a
    let wa = &mut p.a
    *wa = 3
    *ra
