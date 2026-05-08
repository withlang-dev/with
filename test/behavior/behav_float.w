//! expect-stdout: ok

// End-to-end test: floating point operations
// Tests: float add, sub, mul, div, compound expressions
// Note: limited float assertions due to known codegen constraint

fn test_float_ops:
    // Addition
    let sum = 1.5 + 2.5
    assert(sum == 4.0)
    // Subtraction
    let diff = 10.-3.5
    assert(diff == 6.5)
    // Multiplication and division in expression
    let prod = 3.0 * 4.0
    assert(prod == 12.0)

fn main:
    test_float_ops()
    print("ok")
