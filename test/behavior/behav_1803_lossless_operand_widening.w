//! expect-stdout: 300 5000000003 3.5 10 -130 4294967295

// §4.2.6: an operator's operands meet at the type one widens into
// losslessly — the same signedness at a greater width, unsigned into a
// strictly wider signed type, f32 into f64 — and an unsuffixed literal takes
// its peer's type.
fn main:
    let small: u8 = 200
    let wide: i32 = 100
    let u: u32 = 3
    let big: i64 = 5000000000
    let f: f32 = 1.5
    let d: f64 = 2.0
    let n: u32 = 7
    let neg: i16 = -130
    let bytes: u8 = 255
    let widened: i16 = bytes
    let max: u32 = 4294967295
    print(f"{small + wide} {u + big} {f + d} {n + 3} {neg + widened - widened} {max as i64}")
