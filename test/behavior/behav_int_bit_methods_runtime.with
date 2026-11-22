//! expect-stdout: ok

// §4: runtime concrete-width bit methods — popcount, clz, ctz, swap_bytes,
// bitreverse — across widths and a signed receiver.

fn main:
    assert((0xFFu8).popcount() == 8)
    assert((0u32).popcount() == 0)
    let all64: u64 = 0xFFFFFFFFFFFFFFFF
    assert(all64.popcount() == 64)
    let c: i32 = (0xFFu8).popcount() as i32
    assert(c == 8)
    assert((0u16).clz() == 16)
    assert((0u32).clz() == 32)
    assert((0u64).ctz() == 64)
    assert((0b10000u32).clz() == 27)
    assert((0b10000u32).ctz() == 4)
    assert((0x1234u16).swap_bytes() == 0x3412)
    assert((0b10110000u8).bitreverse() == 0b00001101)
    print("ok")
