// std.math — Math utility functions
//
// No c_import. Transcendental functions declared as extern fn pointing
// to libSystem symbols (same functions LLVM would call for its intrinsics).
// On macOS these are in libSystem. On Linux, link with -lm.

// ── libm function declarations (non-variadic, extern fn is correct) ──

extern fn sqrt(x: f64) -> f64
extern fn pow(base: f64, exp: f64) -> f64
extern fn floor(x: f64) -> f64
extern fn ceil(x: f64) -> f64
extern fn round(x: f64) -> f64
extern fn sin(x: f64) -> f64
extern fn cos(x: f64) -> f64
extern fn tan(x: f64) -> f64
extern fn log(x: f64) -> f64
extern fn log10(x: f64) -> f64
extern fn exp(x: f64) -> f64
extern fn fabs(x: f64) -> f64
extern fn fmod(x: f64, y: f64) -> f64
extern fn asin(x: f64) -> f64
extern fn acos(x: f64) -> f64
extern fn atan(x: f64) -> f64
extern fn atan2(y: f64, x: f64) -> f64

// ── Pure With functions (no dependencies) ────────────────────────

/// Absolute value. Returns `0 - x` if `x < 0`, otherwise `x`.
pub fn abs[T](x: T) -> T:
    if x < 0 then 0 - x else x

/// Absolute value for i64.
pub fn abs64(x: i64) -> i64:
    if x < 0 then 0 - x else x

/// Returns the smaller of two values.
pub fn min[T](a: T, b: T) -> T:
    if a < b then a else b

/// Returns the larger of two values.
pub fn max[T](a: T, b: T) -> T:
    if a > b then a else b

/// Returns the smaller of two i64 values.
pub fn min64(a: i64, b: i64) -> i64:
    if a < b then a else b

/// Returns the larger of two i64 values.
pub fn max64(a: i64, b: i64) -> i64:
    if a > b then a else b

/// Clamp `x` to the range `[lo, hi]`.
pub fn clamp[T](x: T, lo: T, hi: T) -> T:
    if x < lo then lo
    else if x > hi then hi
    else x

// ── Wrappers (stable public API) ────────────────────────────────

/// Square root.
pub fn sqrt_f64(x: f64) -> f64:
    sqrt(x)

/// Power: `base` raised to `exp`.
pub fn pow_f64(base: f64, exp: f64) -> f64:
    pow(base, exp)

/// Floor: largest integer <= x.
pub fn floor_f64(x: f64) -> f64:
    floor(x)

/// Ceiling: smallest integer >= x.
pub fn ceil_f64(x: f64) -> f64:
    ceil(x)

/// Round to nearest integer.
pub fn round_f64(x: f64) -> f64:
    round(x)

/// Sine (argument in radians).
pub fn sin_f64(x: f64) -> f64:
    sin(x)

/// Cosine (argument in radians).
pub fn cos_f64(x: f64) -> f64:
    cos(x)

/// Tangent (argument in radians).
pub fn tan_f64(x: f64) -> f64:
    tan(x)

/// Natural logarithm (base e).
pub fn log_f64(x: f64) -> f64:
    log(x)

/// Base-10 logarithm.
pub fn log10_f64(x: f64) -> f64:
    log10(x)

/// Exponential: e raised to the power x.
pub fn exp_f64(x: f64) -> f64:
    exp(x)

/// Absolute value for f64.
pub fn fabs_f64(x: f64) -> f64:
    fabs(x)

/// Floating-point remainder of x / y.
pub fn fmod_f64(x: f64, y: f64) -> f64:
    fmod(x, y)

/// Arc sine. Returns radians.
pub fn asin_f64(x: f64) -> f64:
    asin(x)

/// Arc cosine. Returns radians.
pub fn acos_f64(x: f64) -> f64:
    acos(x)

/// Arc tangent. Returns radians.
pub fn atan_f64(x: f64) -> f64:
    atan(x)

/// Two-argument arc tangent. Returns angle in radians from (x, y).
pub fn atan2_f64(y: f64, x: f64) -> f64:
    atan2(y, x)

/// Pi: ratio of circumference to diameter.
pub let PI: f64 = 3.14159265358979323846
/// Euler's number: base of natural logarithm.
pub let E: f64 = 2.71828182845904523536
/// Tau: 2 * Pi, a full turn in radians.
pub let TAU: f64 = 6.28318530717958647692
