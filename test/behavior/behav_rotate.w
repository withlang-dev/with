//! expect-stdout: ok

// Tests: rotate_left and rotate_right intrinsics on integer types

fn test_rotate_right_u32:
    let x: u32 = 0x12345678 as u32
    assert(x.rotate_right(8) == 0x78123456 as u32)

fn test_rotate_left_u32:
    let x: u32 = 0x12345678 as u32
    assert(x.rotate_left(4) == 0x23456781 as u32)

fn test_rotate_roundtrip:
    let x: u32 = 0xDEADBEEF as u32
    assert(x.rotate_left(13).rotate_right(13) == x)

fn test_rotate_full_width:
    let x: u32 = 0xABCD1234 as u32
    assert(x.rotate_left(32) == x)
    assert(x.rotate_right(32) == x)

fn test_rotate_zero:
    let x: u32 = 0xFF00FF00 as u32
    assert(x.rotate_left(0) == x)
    assert(x.rotate_right(0) == x)

fn test_rotate_left_right_inverse:
    let x: u32 = 0x87654321 as u32
    let n = 7
    assert(x.rotate_left(n).rotate_right(n) == x)

fn test_rotate_u16:
    let x: u16 = 0x1234 as u16
    assert(x.rotate_right(8) == 0x3412 as u16)

fn main:
    test_rotate_right_u32()
    test_rotate_left_u32()
    test_rotate_roundtrip()
    test_rotate_full_width()
    test_rotate_zero()
    test_rotate_left_right_inverse()
    test_rotate_u16()
    print("ok")
