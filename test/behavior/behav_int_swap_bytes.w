//! expect-stdout: ok

// Tests: swap_bytes() intrinsic on integer types

fn test_swap_u32:
    let x: u32 = 0x12345678 as u32
    let swapped = x.swap_bytes()
    assert(swapped == 0x78563412 as u32)

fn test_swap_u16:
    let x: u16 = 0x1234 as u16
    let swapped = x.swap_bytes()
    assert(swapped == 0x3412 as u16)

fn test_swap_u32_roundtrip:
    let x: u32 = 0xDEADBEEF as u32
    assert(x.swap_bytes().swap_bytes() == x)

fn test_swap_zero:
    let x: u32 = 0 as u32
    assert(x.swap_bytes() == 0 as u32)

fn main:
    test_swap_u32()
    test_swap_u16()
    test_swap_u32_roundtrip()
    test_swap_zero()
    println("ok")
