//! expect-stdout: ok

fn test_left_shift:
    let x: u8 = 1
    assert((x << 7u32) == 128u8)
    assert((x << 8) == 0u8)
    assert((x << 16) == 0u8)
    let n_u32: u32 = 10
    assert((x << n_u32) == 0u8)
    let y: i32 = 5
    assert((x << (y as u32)) == 32u8)

fn test_right_shift:
    let ux: u8 = 255
    assert((ux >> 8) == 0u8)
    let neg: i8 = -1i8
    assert((neg >> 8) == -1i8)
    let pos: i8 = 100i8
    assert((pos >> 8) == 0i8)

fn test_narrow_count_wide_lhs:
    let x: u128 = 1u128
    let small: u7 = 1
    assert((x << small) == 2u128)

    let near_width: u7 = 127
    assert((x << near_width) == (1u128 << 127))

    let over_width: u8 = 128
    assert((x << over_width) == 0u128)

    let neg: i128 = -8i128
    assert((neg >> small) == -4i128)
    assert((neg >> over_width) == -1i128)

fn main:
    test_left_shift()
    test_right_shift()
    test_narrow_count_wide_lhs()
    print("ok")
