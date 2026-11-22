//! only-on: darwin
//! expect-stdout: cos_f4 0 failures
//! expect-stdout: cos_d2 0 failures

// §16.1 (D78, #1874): a vector crosses a real C call in the target's vector
// registers. Apple's libm exports vector cosines compiled by clang
// (<simd/math.h>: `extern simd_float4 _simd_cos_f4(simd_float4)`), so a
// With `f32x4` / `f64x2` must pass and return exactly as C does. (c_import
// skips `_`-prefixed declarations, so the two are declared here.)
extern fn _simd_cos_f4(x: f32x4) -> f32x4
extern fn _simd_cos_d2(x: f64x2) -> f64x2

fn near(a: f64, b: f64) -> bool: (a - b).abs() < 0.0001

fn main:
    let c = unsafe { _simd_cos_f4(f32x4(0, 1, 2, 3)) }
    var fails = 0
    for i in 0..4:
        if not near(c[i] as f64, cos(i as f64)): fails += 1
    print(f"cos_f4 {fails} failures")
    let d = unsafe { _simd_cos_d2(f64x2(0.5, 1.5)) }
    fails = 0
    if not near(d[0], cos(0.5)): fails += 1
    if not near(d[1], cos(1.5)): fails += 1
    print(f"cos_d2 {fails} failures")
