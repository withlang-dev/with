// Ordinary arithmetic under --overflow=saturate, at comptime and runtime.

fn id_i8(x: i8): x
fn id_i64(x: i64): x
fn id_u8(x: u8): x
fn id_u64(x: u64): x

const C_ADD: u8 = 255u8 + 1u8
const C_SUB: u8 = 0u8 - 1u8
const C_MUL: u8 = 128u8 * 2u8
const C_NEG: i8 = -(-127i8 - 1i8)
const C_DIV: i8 = (-127i8 - 1i8) / -1i8
const C_MOD: i8 = (-127i8 - 1i8) % -1i8
const C64_ADD: i64 = 9223372036854775807i64 + 1i64
const C64_NEG: i64 = -(-9223372036854775807i64 - 1i64)
const C64_DIV: i64 = (-9223372036854775807i64 - 1i64) / -1i64
const CU64_ADD: u64 = 18446744073709551615u64 + 1u64

fn main:
    assert(C_ADD == 255u8)
    assert(C_SUB == 0u8)
    assert(C_MUL == 255u8)
    assert(C_NEG == 127i8)
    assert(C_DIV == 127i8)
    assert(C_MOD == 0i8)
    assert(C64_ADD == 9223372036854775807i64)
    assert(C64_NEG == 9223372036854775807i64)
    assert(C64_DIV == 9223372036854775807i64)
    assert(CU64_ADD == 18446744073709551615u64)

    let max = id_u8(255)
    let zero = id_u8(0)
    let one = id_u8(1)
    let half = id_u8(128)
    assert(max + one == max)
    assert(zero - one == zero)
    assert(half * id_u8(2) == max)
    let min = id_i8(-128)
    let neg_one = id_i8(-1)
    let signed_max = id_i8(127)
    assert(-min == signed_max)
    assert(min / neg_one == signed_max)
    assert(min % neg_one == id_i8(0))
    let min64 = id_i64(-9223372036854775807 - 1)
    let max64 = id_i64(9223372036854775807)
    assert(max64 + id_i64(1) == max64)
    assert(-min64 == max64)
    assert(min64 / id_i64(-1) == max64)
    let umax64 = id_u64(18446744073709551615u64)
    assert(umax64 + id_u64(1) == umax64)
    print("overflow-policy-saturate: ok")
