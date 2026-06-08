fn main:
    let wrap_x: u8 = 255
    let wrap_y = wrap_x +% 1u8
    assert(wrap_y == 0)

    const CONST_WRAP: i32 = 2147483647 +% 1
    assert(CONST_WRAP == -2147483648)

    let sat_x: u8 = 250
    let sat_y = sat_x +| 20u8
    let max_u8: u8 = 255
    assert(sat_y == max_u8)

    const CONST_SAT: u8 = 250 +| 20u8
    assert(CONST_SAT == max_u8)
