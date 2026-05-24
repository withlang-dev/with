//! expect-stdout: ok

comptime fn i32_to_i64() -> i64:
    let x: i32 = 42
    x as i64

comptime fn i64_to_i32() -> i32:
    let x: i64 = 100
    x as i32

comptime fn u8_to_i32() -> i32:
    let x: u8 = 200
    x as i32

comptime fn i32_to_u8() -> u8:
    let x: i32 = 100
    x as u8

comptime fn bool_to_i32() -> i32:
    true as i32

comptime fn bool_false_to_i32() -> i32:
    false as i32

comptime fn i32_to_u64() -> u64:
    let x: i32 = 50
    x as u64

const I32_TO_I64: i64 = comptime i32_to_i64()
const I64_TO_I32: i32 = comptime i64_to_i32()
const U8_TO_I32: i32 = comptime u8_to_i32()
const I32_TO_U8: u8 = comptime i32_to_u8()
const BOOL_TRUE: i32 = comptime bool_to_i32()
const BOOL_FALSE: i32 = comptime bool_false_to_i32()
const I32_TO_U64: u64 = comptime i32_to_u64()

fn main:
    assert(I32_TO_I64 == 42)
    assert(I64_TO_I32 == 100)
    assert(U8_TO_I32 == 200)
    assert(I32_TO_U8 == 100)
    assert(BOOL_TRUE == 1)
    assert(BOOL_FALSE == 0)
    assert(I32_TO_U64 == 50)
    print("ok")
