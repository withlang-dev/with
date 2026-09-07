const FITS_I128: i128 = 9223372036854775807i128 + 1i128

fn main:
    let x: i128 = 9223372036854775807i128
    let y: i128 = x + 1i128
    assert(y == FITS_I128)
    print("overflow-i128-surface: ok")
