type Big { a: i64, b: i64, c: i64, d: i64 }

fn bump(value: Big) -> Big:
    Big { a: value.a + 1, b: value.b, c: value.c, d: value.d }

fn apply_raw(f: *const fn(Big) -> Big, value: Big) -> Big: f(value)

fn main:
    let result = apply_raw(&bump, Big { a: 1, b: 2, c: 3, d: 4 })
    assert(result.a == 2)
