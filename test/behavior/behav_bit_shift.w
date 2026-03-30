//! expect-stdout: ok

// Tests: left shift, right shift, shift by zero, shift chain,
//        shift with unsigned types, shift in expressions

fn test_left_shift:
    assert((1 << 0) == 1)
    assert((1 << 1) == 2)
    assert((1 << 2) == 4)
    assert((1 << 3) == 8)
    assert((1 << 8) == 256)
    assert((1 << 16) == 65536)

fn test_right_shift:
    assert((256 >> 8) == 1)
    assert((255 >> 4) == 15)
    assert((1024 >> 10) == 1)
    assert((100 >> 0) == 100)

fn test_shift_by_zero:
    let x = 42
    assert((x << 0) == 42)
    assert((x >> 0) == 42)

fn test_shift_chain:
    let x = 1
    let y = x << 4
    let z = y >> 2
    assert(z == 4)

fn test_shift_powers_of_two:
    var i = 0
    var val = 1
    while i < 10:
        assert(val == (1 << i))
        val = val * 2
        i = i + 1

fn test_shift_mask_pattern:
    // Extract bits using shift + mask
    let x = 0xABCD
    let low_byte = x & 0xFF
    let high_byte = (x >> 8) & 0xFF
    assert(low_byte == 0xCD)
    assert(high_byte == 0xAB)

fn test_u32_shift:
    let a: u32 = 1u32
    assert((a << 31u32) == 0x80000000u32)
    let b: u32 = 0x80000000u32
    assert((b >> 31u32) == 1u32)

fn test_shift_in_expression:
    let flags = (1 << 0) | (1 << 2) | (1 << 4)
    // flags = 0b10101 = 21
    assert(flags == 21)
    assert((flags & (1 << 0)) != 0)
    assert((flags & (1 << 1)) == 0)
    assert((flags & (1 << 2)) != 0)

fn set_bit(val: i32, bit: i32) -> i32:
    val | (1 << bit)

fn clear_bit(val: i32, bit: i32) -> i32:
    val & ~(1 << bit)

fn test_bit_set_clear:
    var x = 0
    x = set_bit(x, 0)
    assert(x == 1)
    x = set_bit(x, 3)
    assert(x == 9)
    x = clear_bit(x, 0)
    assert(x == 8)

fn main:
    test_left_shift()
    test_right_shift()
    test_shift_by_zero()
    test_shift_chain()
    test_shift_powers_of_two()
    test_shift_mask_pattern()
    test_u32_shift()
    test_shift_in_expression()
    test_bit_set_clear()
    print("ok")
