//! expect-stdout: ok

// Tests: compound wrapping assignment operators (+%=, -%=, *%=)

fn test_add_wrap_assign:
    var x: u32 = 4294967290u32  // u32::MAX - 5
    x +%= 10u32
    assert(x == 4u32)  // wraps around

fn test_add_wrap_assign_no_overflow:
    var x: u32 = 100u32
    x +%= 50u32
    assert(x == 150u32)

fn test_sub_wrap_assign:
    var x: u32 = 5u32
    x -%= 10u32
    assert(x == 4294967291u32)  // wraps to u32::MAX - 4

fn test_mul_wrap_assign:
    var x: u32 = 0x80000000 as u32  // 2^31
    x *%= 2u32
    assert(x == 0u32)  // wraps to 0

fn test_wrap_assign_loop:
    // Simulate crypto-style accumulation
    var state: u32 = 0x6a09e667 as u32
    var i = 0
    while i < 10:
        state +%= 0x10000000 as u32
        i = i + 1
    // Should have wrapped around
    assert(state != 0u32)  // just verify no crash

fn main:
    test_add_wrap_assign()
    test_add_wrap_assign_no_overflow()
    test_sub_wrap_assign()
    test_mul_wrap_assign()
    test_wrap_assign_loop()
    println("ok")
