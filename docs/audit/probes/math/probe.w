use std.math
use std.builtins.int_to_string

// Audit probe: pure fns + libm wrappers + constants.
// f64 values printed scaled by 1e9 as i64 (truncation); oracle = python3 math.

fn ps(scaled: i64):
    print(int_to_string(scaled) ++ "\n")

fn pf(x: f64):
    ps((x * 1000000000.0) as i64)

fn main():
    // ── Pure With fns ──
    print(int_to_string(abs(5) as i64) ++ "\n")
    print(int_to_string(abs(0 - 5) as i64) ++ "\n")
    print(int_to_string(abs(0) as i64) ++ "\n")
    print(int_to_string(abs64(5000000000i64)) ++ "\n")
    print(int_to_string(abs64(0i64 - 5000000000i64)) ++ "\n")
    print(int_to_string(min(3, 7) as i64) ++ "\n")
    print(int_to_string(max(3, 7) as i64) ++ "\n")
    print(int_to_string(min(4, 4) as i64) ++ "\n")
    print(int_to_string(min64(100i64, 200i64)) ++ "\n")
    print(int_to_string(max64(100i64, 200i64)) ++ "\n")
    print(int_to_string(clamp(5, 1, 10) as i64) ++ "\n")
    print(int_to_string(clamp(0 - 5, 1, 10) as i64) ++ "\n")
    print(int_to_string(clamp(50, 1, 10) as i64) ++ "\n")
    print(int_to_string(clamp(1, 1, 10) as i64) ++ "\n")
    print(int_to_string(clamp(10, 1, 10) as i64) ++ "\n")

    // ── libm wrappers (scaled) ──
    pf(sqrt_f64(2.0))
    pf(pow_f64(2.0, 10.0))
    pf(floor_f64(2.7))
    pf(ceil_f64(2.1))
    pf(round_f64(2.5))
    pf(sin_f64(0.5))
    pf(cos_f64(0.5))
    pf(tan_f64(0.5))
    pf(log_f64(E))
    pf(log10_f64(100.0))
    pf(exp_f64(1.0))
    pf(fabs_f64(0.0 - 3.5))
    pf(fmod_f64(5.5, 2.0))
    pf(asin_f64(0.5))
    pf(acos_f64(0.5))
    pf(atan_f64(1.0))
    pf(atan2_f64(1.0, 1.0))

    // ── Constants (scaled) ──
    pf(PI)
    pf(E)
    pf(TAU)
