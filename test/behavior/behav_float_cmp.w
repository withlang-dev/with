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

fn main:
    test_float_equality()
    println("ok")
