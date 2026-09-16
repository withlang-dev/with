// std.math — Math utility functions
//
// The transcendental functions — `sqrt`, `sin`, `cos`, `tan`, `exp`, `log`,
// `pow`, `floor`, `ceil`, `round`, `atan2`, and the rest — are compiler
// builtins (specification §17.6a; src/MathBuiltins.w is the one table).
// They are width-generic over f32 and f64, callable as `cos(x)` or `x.cos()`,
// and spelled without a width suffix. Nothing here declares them.

// ── Pure With functions (no dependencies) ────────────────────────

/// Absolute value. Returns `0 - x` if `x < 0`, otherwise `x`.
pub fn abs[T](x: T) -> T:
    if x < 0: 0 - x else: x

/// Absolute value for i64.
pub fn abs64(x: i64) -> i64:
    if x < 0: 0 - x else: x

/// Returns the smaller of two values.
pub fn min[T](a: T, b: T) -> T:
    if a < b: a else: b

/// Returns the larger of two values.
pub fn max[T](a: T, b: T) -> T:
    if a > b: a else: b

/// Returns the smaller of two i64 values.
pub fn min64(a: i64, b: i64) -> i64:
    if a < b: a else: b

/// Returns the larger of two i64 values.
pub fn max64(a: i64, b: i64) -> i64:
    if a > b: a else: b

/// Clamp `x` to the range `[lo, hi]`.
pub fn clamp[T](x: T, lo: T, hi: T) -> T:
    if x < lo: lo
    else if x > hi: hi
    else: x

/// Pi: ratio of circumference to diameter.
pub let PI: f64 = 3.14159265358979323846
/// Euler's number: base of natural logarithm.
pub let E: f64 = 2.71828182845904523536
/// Tau: 2 * Pi, a full turn in radians.
pub let TAU: f64 = 6.28318530717958647692
