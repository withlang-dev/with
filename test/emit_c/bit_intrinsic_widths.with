//! expect-stdout: ok

// #1006: emit-C lowers swap_bytes, popcount, clz, ctz and bitreverse at the
// operand's own width. Each was 32-bit text whatever the operand: a 64-bit
// swap_bytes swapped the low word, popcount lost the high word, and a
// zero's count was 32 at every width.
fn main:
    let all64: u64 = 0xFFFFFFFFFFFFFFFF
    assert(all64.popcount() == 64)
    let high: u64 = 0x8000000000000000
    assert(high.popcount() == 1)
    assert(high.clz() == 0)
    assert(high.ctz() == 63)
    assert((0u64).clz() == 64)
    assert((0u64).ctz() == 64)
    let wide: i64 = 256
    assert(wide.swap_bytes() == 281474976710656)
    let one64: u64 = 1
    assert(one64.bitreverse() == high)
    assert((0xFFu8).popcount() == 8)
    assert((0u8).clz() == 8)
    assert((1u8).clz() == 7)
    assert((0u16).clz() == 16)
    assert((0u16).ctz() == 16)
    assert((0b10000u32).clz() == 27)
    assert((0b10000u32).ctz() == 4)
    assert((0x1234u16).swap_bytes() == 0x3412)
    assert((0b10110000u8).bitreverse() == 0b00001101)
    assert((0x12u8).swap_bytes() == 0x12)
    print("ok")
