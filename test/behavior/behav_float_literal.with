//! expect-stdout: ok

// End-to-end test: decimal float literals are correctly rounded.
// A literal denotes the representable value nearest its decimal text (IEEE 754,
// ties to even). Every expected value here is built from exact operations, so the
// test trusts no other decimal literal: integers below 2^53, powers of two, and
// quotients of them are exact, and IEEE division and multiplication round once.

fn test_float_literal_nearest_f64:
    assert(0.3 == 3.0 / 10.0)
    assert(0.03 == 3.0 / 100.0)
    assert(6.02214076e23 == 602214076.0 * 1000000000000000.0)
    // The smallest subnormal is 2^-1074; halving 1.0 that many times is exact.
    var tiny: f64 = 1.0
    var i = 0
    while i < 1074:
        tiny = tiny / 2.0
        i = i + 1
    assert(tiny > 0.0)
    assert(1.0e-320 == 2024.0 * tiny)

fn test_float_literal_nearest_f32:
    // The nearest f64 to this literal is exactly halfway between two f32 values,
    // so rounding through f64 and then to f32 gives 1 + 2^-22, one ulp too high.
    let x: f32 = 1.0000001788139343261718749
    var ulp: f32 = 1.0
    var i = 0
    while i < 23:
        ulp = ulp / 2.0
        i = i + 1
    assert(x == 1.0 + ulp)

// §29.1: "Separators are ignored for numeric value parsing", and a float may carry
// them: `3.141_592_653`.
fn test_float_literal_digit_separators:
    assert(1_000.5 == 1000.5)
    assert(3.141_592_653 == 3.141592653)
    assert(1.0e1_0 == 1.0e10)
    let s: f32 = 1_0.5
    assert(s == 10.5)

fn main:
    test_float_literal_nearest_f64()
    test_float_literal_nearest_f32()
    test_float_literal_digit_separators()
    print("ok")
