//! expect-stdout: 2147483647 -2147483648 0 255 0 3 -3 16777216 true

// D125 (§4.2.6): a float to an integer truncates toward zero, saturates out
// of range, and NaN gives 0; an integer to a float rounds to nearest, ties to
// even; a float too large for a narrower float becomes infinity. The values
// live in variables so the conversions run, not fold.
fn main:
    let big: f64 = 1e20
    let neg: f64 = -1e20
    let zero: f64 = 0.0
    let nan = zero / zero
    let over: f64 = 300.0
    let under: f64 = -5.0
    let up: f64 = 3.7
    let down: f64 = -3.7
    let odd: i32 = 16777217
    let huge: f64 = 1e300
    let narrowed = huge as f32
    print(f"{big as i32} {neg as i32} {nan as i32} {over as u8} {under as u8} {up as i32} {down as i32} {odd as f32 as i64} {narrowed > 3.0e38}")
