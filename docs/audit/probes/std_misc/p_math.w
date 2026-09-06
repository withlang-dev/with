use std.math

fn expect(label: str, ok: bool):
    if ok:
        print(f"PASS: {label}\n")
    else:
        print(f"FAIL: {label}\n")

fn main():
    expect("abs neg", abs(-3) == 3)
    expect("abs pos", abs(4) == 4)
    expect("abs zero", abs(0) == 0)
    expect("abs64", abs64(-99 as i64) == 99)
    expect("min", min(2, 5) == 2)
    expect("max", max(2, 5) == 5)
    expect("min64", min64(9 as i64, 3 as i64) == 3)
    expect("max64", max64(9 as i64, 3 as i64) == 9)
    expect("clamp lo", clamp(-5, 0, 10) == 0)
    expect("clamp hi", clamp(99, 0, 10) == 10)
    expect("clamp mid", clamp(5, 0, 10) == 5)
    expect("sqrt", sqrt_f64(9.0) == 3.0)
    expect("pow", pow_f64(2.0, 10.0) == 1024.0)
    expect("floor", floor_f64(2.7) == 2.0)
    expect("ceil", ceil_f64(2.2) == 3.0)
    expect("fabs", fabs_f64(-1.5) == 1.5)
    expect("fmod", fmod_f64(5.5, 2.0) == 1.5)
    expect("sin0", sin_f64(0.0) == 0.0)
    expect("cos0", cos_f64(0.0) == 1.0)
    expect("exp0", exp_f64(0.0) == 1.0)
    expect("log1", log_f64(1.0) == 0.0)
    expect("PI", PI > 3.14159 and PI < 3.14160)
    expect("E", E > 2.71828 and E < 2.71829)
    expect("TAU", TAU > 6.28318 and TAU < 6.28319)
    // edge: sqrt(-1) is NaN (NaN != NaN)
    let nan = sqrt_f64(-1.0)
    expect("sqrt neg is NaN", not (nan == nan))
    // edge: i32 min abs overflow wraps (documents, not asserts fix)
    let m: i32 = -2147483648
    print(f"abs(i32min) = {abs(m)}\n")
