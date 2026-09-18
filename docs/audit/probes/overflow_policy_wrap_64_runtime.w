fn id_i64(x: i64): x
fn id_u64(x: u64): x

fn main:
    let min = id_i64(-9223372036854775807 - 1)
    assert(id_i64(9223372036854775807) + id_i64(1) == min)
    assert(-min == min)
    assert(min / id_i64(-1) == min)
    assert(min % id_i64(-1) == id_i64(0))
    assert(id_u64(18446744073709551615u64) + id_u64(1) == id_u64(0))
    print("overflow-policy-wrap-64-runtime: ok")
