// std.math — Math utility functions
//
// Provides common math operations wrapping C libm functions.

use c_import("#include <math.h>")

// Absolute value (integer)
pub fn abs(x: i32) -> i32 =
    if x < 0 then 0 - x else x

// Absolute value (i64)
pub fn abs64(x: i64) -> i64 =
    if x < 0 then 0 - x else x

// Min of two integers
pub fn min(a: i32, b: i32) -> i32 =
    if a < b then a else b

// Max of two integers
pub fn max(a: i32, b: i32) -> i32 =
    if a > b then a else b

// Min of two i64s
pub fn min64(a: i64, b: i64) -> i64 =
    if a < b then a else b

// Max of two i64s
pub fn max64(a: i64, b: i64) -> i64 =
    if a > b then a else b

// Clamp a value between min and max
pub fn clamp(x: i32, lo: i32, hi: i32) -> i32 =
    if x < lo then lo
    else if x > hi then hi
    else x

// Square root (f64)
pub fn sqrt_f64(x: f64) -> f64 =
    sqrt(x)

// Power (f64)
pub fn pow_f64(base: f64, exp: f64) -> f64 =
    pow(base, exp)

// Floor (f64 -> f64)
pub fn floor_f64(x: f64) -> f64 =
    floor(x)

// Ceil (f64 -> f64)
pub fn ceil_f64(x: f64) -> f64 =
    ceil(x)
