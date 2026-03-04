// Wave 8: predecessor/successor sensitive borrow release across branches.

type Pair = {
    a: i32,
    b: i32,
}

fn read(x: &i32) -> i32:
    *x

fn write(x: &mut i32, v: i32):
    *x = v

fn main -> i32:
    let mut p = Pair { a: 1, b: 2 }
    let mut total = 0

    if p.a > 0:
        let ra = &p.a
        total = total + read(ra)
    else
        let rb = &p.b
        total = total + read(rb)

    write(&mut p.a, total)
    assert(p.a == 1)
    0
