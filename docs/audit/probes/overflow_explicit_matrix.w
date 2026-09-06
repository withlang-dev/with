// Explicit wrapping/saturating operator matrix for src/Overflow.w consumers.

fn id_i8(x: i8): x
fn id_i16(x: i16): x
fn id_i32(x: i32): x
fn id_i64(x: i64): x
fn id_u8(x: u8): x
fn id_u16(x: u16): x
fn id_u32(x: u32): x
fn id_u64(x: u64): x

const CU8_ADD_WRAP: u8 = 255u8 +% 1u8
const CU8_SUB_WRAP: u8 = 0u8 -% 1u8
const CU8_MUL_WRAP: u8 = 128u8 *% 2u8
const CI8_ADD_SAT: i8 = 127i8 +| 1i8
const CI8_SUB_SAT: i8 = (-127i8 - 1i8) -| 1i8
const CI8_MUL_SAT: i8 = (-127i8 - 1i8) *| -1i8

fn main:
    assert(CU8_ADD_WRAP == 0u8)
    assert(CU8_SUB_WRAP == 255u8)
    assert(CU8_MUL_WRAP == 0u8)
    assert(CI8_ADD_SAT == 127i8)
    assert(CI8_SUB_SAT == (-127i8 - 1i8))
    assert(CI8_MUL_SAT == 127i8)

    let i8_max = id_i8(127)
    let i8_min = id_i8(-128)
    let i8_one = id_i8(1)
    let i8_neg_one = id_i8(-1)
    assert(i8_max +% i8_one == i8_min)
    assert(i8_min -% i8_one == i8_max)
    assert(id_i8(64) *% id_i8(2) == i8_min)
    assert(i8_max +| i8_one == i8_max)
    assert(i8_min +| i8_neg_one == i8_min)
    assert(i8_max -| i8_neg_one == i8_max)
    assert(i8_min -| i8_one == i8_min)
    assert(id_i8(64) *| id_i8(2) == i8_max)
    assert(i8_min *| i8_neg_one == i8_max)
    assert(i8_min *| id_i8(2) == i8_min)

    let u8_max = id_u8(255)
    let u8_zero = id_u8(0)
    let u8_one = id_u8(1)
    assert(u8_max +% u8_one == u8_zero)
    assert(u8_zero -% u8_one == u8_max)
    assert(id_u8(128) *% id_u8(2) == u8_zero)
    assert(u8_max +| u8_one == u8_max)
    assert(u8_zero -| u8_one == u8_zero)
    assert(id_u8(128) *| id_u8(2) == u8_max)

    let i16_max = id_i16(32767)
    let i16_min = id_i16(-32768)
    assert(i16_max +% id_i16(1) == i16_min)
    assert(i16_min *| id_i16(-1) == i16_max)
    let u16_max = id_u16(65535)
    assert(u16_max +% id_u16(1) == id_u16(0))
    assert(u16_max +| id_u16(1) == u16_max)

    let i32_max = id_i32(2147483647)
    let i32_min = id_i32(-2147483647 - 1)
    assert(i32_max +% id_i32(1) == i32_min)
    assert(i32_min *| id_i32(-1) == i32_max)
    let u32_max = id_u32(4294967295u32)
    assert(u32_max +% id_u32(1) == id_u32(0))
    assert(u32_max +| id_u32(1) == u32_max)

    let i64_max = id_i64(9223372036854775807)
    let i64_min = id_i64(-9223372036854775807 - 1)
    assert(i64_max +% id_i64(1) == i64_min)
    assert(i64_min *| id_i64(-1) == i64_max)
    let u64_max = id_u64(18446744073709551615u64)
    assert(u64_max +% id_u64(1) == id_u64(0))
    assert(u64_max +| id_u64(1) == u64_max)

    print("overflow-explicit-matrix: ok")
