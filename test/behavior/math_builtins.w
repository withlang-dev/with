//! expect-stdout: math builtins: 0 failures

// Floating-point math builtins (§17.6a, D42): both spellings (`cos(x)` and
// `x.cos()`), both widths (f32 and f64), both arities, and both lowering
// tiers (LLVM intrinsic vs libm-only). Tolerances are loose enough for f32.
fn near(a: f64, b: f64) -> bool: (a - b).abs() < 0.0005
fn near32(a: f32, b: f32) -> bool: (a - b).abs() < 0.001f32

fn main:
    var fails = 0
    // free fn, f64, LLVM-intrinsic tier
    if not near(cos(0.0), 1.0): fails += 1
    if not near(sin(1.5707963), 1.0): fails += 1
    if not near(sqrt(2.0), 1.41421356): fails += 1
    if not near(exp(1.0), 2.71828183): fails += 1
    if not near(log(2.71828183), 1.0): fails += 1
    if not near(log2(8.0), 3.0): fails += 1
    if not near(log10(1000.0), 3.0): fails += 1
    if not near(floor(2.7), 2.0): fails += 1
    if not near(ceil(2.2), 3.0): fails += 1
    if not near(round(2.5), 3.0): fails += 1
    if not near(trunc(-2.7), -2.0): fails += 1
    if not near(fabs(-3.5), 3.5): fails += 1
    // free fn, f64, binary intrinsic
    if not near(pow(2.0, 10.0), 1024.0): fails += 1
    if not near(copysign(3.0, -1.0), -3.0): fails += 1
    // free fn, f64, libm-only tier (no LLVM intrinsic)
    if not near(tan(0.7853981634), 1.0): fails += 1
    if not near(atan(1.0), 0.7853981634): fails += 1
    if not near(asin(1.0), 1.5707963268): fails += 1
    if not near(acos(1.0), 0.0): fails += 1
    if not near(sinh(0.0), 0.0): fails += 1
    if not near(cosh(0.0), 1.0): fails += 1
    if not near(tanh(0.0), 0.0): fails += 1
    if not near(cbrt(27.0), 3.0): fails += 1
    if not near(atan2(1.0, 1.0), 0.7853981634): fails += 1
    if not near(fmod(7.5, 2.0), 1.5): fails += 1
    if not near(hypot(3.0, 4.0), 5.0): fails += 1
    // free fn, f32 — the width the old cos_f64 could never take
    if not near32(cos(0.0f32), 1.0f32): fails += 1
    if not near32(sqrt(9.0f32), 3.0f32): fails += 1
    if not near32(tan(0.7853982f32), 1.0f32): fails += 1
    if not near32(pow(2.0f32, 3.0f32), 8.0f32): fails += 1
    if not near32(atan2(1.0f32, 1.0f32), 0.7853982f32): fails += 1
    // method spelling, both widths, both tiers, both arities
    let t = 1.0
    if not near(t.cos(), 0.5403023059): fails += 1
    if not near((16.0).sqrt(), 4.0): fails += 1
    if not near((0.0).tan(), 0.0): fails += 1
    if not near((2.0).pow(8.0), 256.0): fails += 1
    if not near((1.0).atan2(1.0), 0.7853981634): fails += 1
    let t32 = 0.0f32
    if not near32(t32.cos(), 1.0f32): fails += 1
    if not near32((4.0f32).sqrt(), 2.0f32): fails += 1
    if not near32((0.0f32).tan(), 0.0f32): fails += 1
    // nested math reads as math — the spiral's own shape
    let p = 0.5
    let angle = p * 18.8495559215 + 1.25 * 0.8
    let radius = 28.0 + p * 250.0 + sin(1.25 * 1.4 + p * 6.0) * 18.0
    let x = 450.0 + cos(angle) * radius
    if not near(x, 450.0 + cos(angle) * radius): fails += 1
    // result type is the argument type: f64 in, f64 out; f32 in, f32 out
    let r64: f64 = cos(0.0)
    let r32: f32 = cos(0.0f32)
    if not near(r64, 1.0): fails += 1
    if not near32(r32, 1.0f32): fails += 1
    print(f"math builtins: {fails} failures")
    if fails > 0: return 1
    0
