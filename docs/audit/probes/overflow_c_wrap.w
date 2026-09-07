fn add_wrap_i64(a: i64, b: i64): a +% b
fn sub_wrap_i64(a: i64, b: i64): a -% b
fn mul_wrap_i64(a: i64, b: i64): a *% b

fn main:
    let max: i64 = 9223372036854775807
    assert(add_wrap_i64(max, 1) == (-9223372036854775807 - 1))
    assert(sub_wrap_i64((-9223372036854775807 - 1), 1) == max)
    assert(mul_wrap_i64(max, 2) == -2)
    print("overflow-c-wrap: ok")
