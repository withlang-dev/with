type Big { a: i64, b: i64, c: i64 }

fn make_big() -> Big:
    Big { a: 1, b: 2, c: 3 }

fn sum_big(v: Big) -> i64:
    v.a + v.b + v.c

fn main -> i32:
    let b = make_big()
    if sum_big(b) == 6:
        0
    else:
        1
