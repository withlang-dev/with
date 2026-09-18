fn id_i64(x: i64): x
fn id_u64(x: u64): x

fn main:
    let min = id_i64(-9223372036854775807 - 1)
    let max = id_i64(9223372036854775807)
    assert(max + id_i64(1) == max)
    assert(-min == max)
    assert(min / id_i64(-1) == max)
    assert(min % id_i64(-1) == id_i64(0))
    let umax = id_u64(18446744073709551615u64)
    assert(umax + id_u64(1) == umax)
    print("overflow-policy-saturate-64-runtime: ok")
