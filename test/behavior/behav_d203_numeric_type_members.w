//! expect-stdout: -128 127 -32768 32767
//! expect-stdout: -2147483648 2147483647
//! expect-stdout: -9223372036854775808 9223372036854775807
//! expect-stdout: 0 255 65535 4294967295 18446744073709551615
//! expect-stdout: -170141183460469231731687303715884105728 170141183460469231731687303715884105727
//! expect-stdout: 340282366920938463463374607431768211455
//! expect-stdout: sizes ok
//! expect-stdout: floats ok
// §4.1a (D203): every numeric type has `min` and `max`, its least and
// greatest values; a floating-point type's are the finite ones, and it has
// `inf` and `nan` too. Negative infinity is `-f64.inf`.
fn main:
    print(f"{i8.min} {i8.max} {i16.min} {i16.max}")
    print(f"{i32.min} {i32.max}")
    print(f"{i64.min} {i64.max}")
    print(f"{u8.min} {u8.max} {u16.max} {u32.max} {u64.max}")
    print(f"{i128.min} {i128.max}")
    print(f"{u128.max}")
    let wide = sizeof[usize]() == 8
    let sizes = usize.min == 0 and isize.min < 0 and isize.max > 0 and isize.min + isize.max == -1 and (not wide or (usize.max == 18446744073709551615 and isize.max == 9223372036854775807))
    if sizes: print("sizes ok")
    let big: f64 = f64.max
    let small: f32 = f32.max
    let floats = f64.min == -f64.max and f64.max > 1.0e308 and f64.max < f64.inf and f64.min > -f64.inf and f64.max * 2.0 == f64.inf and f64.nan != f64.nan and f32.min == -f32.max and f32.max > 3.0e38 and f32.max < f32.inf and f32.nan != f32.nan and -f32.inf < f32.min and big == f64.max and small == f32.max
    if floats: print("floats ok")
