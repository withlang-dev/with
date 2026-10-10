//! expect-stdout: 2147483647 -2147483648 255 0 3 44 16777216

// D125 (§4.2.6): a cast evaluated at compile time converts exactly as at run
// time: float to integer truncates and saturates (NaN 0), integer to integer
// keeps the low bits, integer to float rounds to nearest, ties to even.
fn to_i32(x: f64) -> i32: x as i32
fn to_u8(x: f64) -> u8: x as u8
fn low_bits(x: i32) -> u8: x as u8
fn to_f32(x: i32) -> f32: x as f32

const BIG = comptime to_i32(1e20)
const NEG = comptime to_i32(-1e20)
const OVER = comptime to_u8(300.0)
const UNDER = comptime to_u8(-5.0)
const TRUNC = comptime to_i32(3.7)
const WRAPPED = comptime low_bits(300)
const ROUNDED = comptime to_f32(16777217)

fn main:
    print(f"{BIG} {NEG} {OVER} {UNDER} {TRUNC} {WRAPPED} {ROUNDED as i64}")
