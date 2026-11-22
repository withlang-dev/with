//! expect-stdout: ok

fn add64(a: i64, b: i64) -> i64:
    a + b

fn call_it(f: *const fn(i64, i64) -> i64, x: i64, y: i64) -> i64:
    f(x, y)

fn main:
    let fp: *const fn(i64, i64) -> i64 = &add64

    assert(call_it(&add64, 1, 2) == 3)
    assert(call_it(fp, 4, 5) == 9)
    assert(fp(10, 20) == 30)
    assert((fp)(30, 40) == 70)

    print("ok")
