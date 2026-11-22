//! expect-stdout: ok

// End-to-end test: float comparison
// Tests: float equality with literals and computed values
// Note: float ordering ops (<, >, <=, >=) have known codegen issues

fn test_float_equality:
    // Direct literal comparisons
    assert(1.0 == 1.0)
    assert(0.0 == 0.0)
    // Computed value comparison
    let sum = 2.0 + 1.0
    assert(sum == 3.0)

// IEEE 754: NaN is unordered, so `==` is false and `!=` is true for any NaN operand.
fn test_float_not_equal_nan:
    let zero = 0.0
    let nan = zero / zero
    assert(nan != nan)
    assert(not (nan == nan))
    assert(nan != 1.0)
    assert(1.0 != nan)
    let zero32: f32 = 0.0
    let nan32 = zero32 / zero32
    assert(nan32 != nan32)
    assert(not (nan32 == nan32))
    // ordinary values are unchanged
    assert(1.5 != 2.5)
    assert(not (2.5 != 2.5))

fn main:
    test_float_equality()
    test_float_not_equal_nan()
    print("ok")
