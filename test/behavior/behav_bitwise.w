//! expect-stdout: ok

// Behavior test: bitwise operations
// Tests: and (&), or (|), xor (^)

fn test_bit_and:
    assert((0xFF & 0x0F) == 0x0F)
    assert((12 & 10) == 8)
    assert((7 & 0) == 0)
    assert((0 & 0) == 0)

fn test_bit_or:
    assert((0xF0 | 0x0F) == 0xFF)
    assert((4 | 2) == 6)
    assert((0 | 0) == 0)
    assert((1 | 2 | 4) == 7)

fn test_bit_xor:
    assert((0xFF ^ 0x0F) == 0xF0)
    assert((5 ^ 3) == 6)
    assert((7 ^ 7) == 0)
    assert((0 ^ 42) == 42)

fn test_combined_bitops:
    // Use OR to set bits, AND to check them
    var flags = 0
    flags = flags | 1
    assert((flags & 1) == 1)
    flags = flags | 4
    assert((flags & 4) == 4)
    assert((flags & 1) == 1)
    // Clear bit using XOR
    flags = flags ^ 1
    assert((flags & 1) == 0)
    assert((flags & 4) == 4)

fn test_bitwise_identity:
    // a & a == a
    assert((42 & 42) == 42)
    // a | a == a
    assert((42 | 42) == 42)
    // a ^ a == 0
    assert((42 ^ 42) == 0)

fn test_bitwise_with_vars:
    let a = 0xAB
    let b = 0xCD
    let and_result = a & b
    assert(and_result == 0x89)
    let or_result = a | b
    assert(or_result == 0xEF)
    let xor_result = a ^ b
    assert(xor_result == 0x66)

fn test_bitwise_same_signedness_rules:
    let small: u8 = 1
    let wide: u32 = 0xff00
    let combined = small | wide
    assert(combined == 0xff01 as u32)

    let byte: i8 = -1
    let masked = byte & 0xff
    assert(masked == -1)

fn main:
    test_bit_and()
    test_bit_or()
    test_bit_xor()
    test_combined_bitops()
    test_bitwise_identity()
    test_bitwise_with_vars()
    test_bitwise_same_signedness_rules()
    print("ok")
