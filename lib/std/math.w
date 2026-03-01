// std.math — Math utility functions
//
// Provides common math operations wrapping C libm functions.

use c_import("math.h")

// Absolute value (numeric)
pub fn abs[T](x: T) -> T:
    if x < 0 then 0 - x else x

// Absolute value (i64)
pub fn abs64(x: i64) -> i64:
    if x < 0 then 0 - x else x

// Min of two values
pub fn min[T](a: T, b: T) -> T:
    if a < b then a else b

// Max of two values
pub fn max[T](a: T, b: T) -> T:
    if a > b then a else b

// Min of two i64s
pub fn min64(a: i64, b: i64) -> i64:
    if a < b then a else b

// Max of two i64s
pub fn max64(a: i64, b: i64) -> i64:
    if a > b then a else b

// Clamp a value between lo and hi
pub fn clamp[T](x: T, lo: T, hi: T) -> T:
    if x < lo then lo
    else if x > hi then hi
    else x

// Square root (f64)
pub fn sqrt_f64(x: f64) -> f64:
    sqrt(x)

// Power (f64)
pub fn pow_f64(base: f64, exp: f64) -> f64:
    pow(base, exp)

// Floor (f64 -> f64)
pub fn floor_f64(x: f64) -> f64:
    floor(x)

// Ceil (f64 -> f64)
pub fn ceil_f64(x: f64) -> f64:
    ceil(x)

// Round (f64 -> f64)
pub fn round_f64(x: f64) -> f64:
    round(x)

// Sine (radians)
pub fn sin_f64(x: f64) -> f64:
    sin(x)

// Cosine (radians)
pub fn cos_f64(x: f64) -> f64:
    cos(x)

// Tangent (radians)
pub fn tan_f64(x: f64) -> f64:
    tan(x)

// Natural logarithm
pub fn log_f64(x: f64) -> f64:
    log(x)

// Base-10 logarithm
pub fn log10_f64(x: f64) -> f64:
    log10(x)

// Exponential (e^x)
pub fn exp_f64(x: f64) -> f64:
    exp(x)

// Absolute value (f64)
pub fn fabs_f64(x: f64) -> f64:
    fabs(x)

// Float modulo
pub fn fmod_f64(x: f64, y: f64) -> f64:
    fmod(x, y)

// Arc sine
pub fn asin_f64(x: f64) -> f64:
    asin(x)

// Arc cosine
pub fn acos_f64(x: f64) -> f64:
    acos(x)

// Arc tangent
pub fn atan_f64(x: f64) -> f64:
    atan(x)

// Two-argument arc tangent
pub fn atan2_f64(y: f64, x: f64) -> f64:
    atan2(y, x)

// Constants
pub let PI: f64 = 3.14159265358979323846
pub let E: f64 = 2.71828182845904523536
pub let TAU: f64 = 6.28318530717958647692
