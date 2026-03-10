//! expect-stdout: ok

// End-to-end test: arithmetic operations
// Tests: +, -, *, /, %, unary negate, precedence, compound assignment

fn test_basic_ops:
    assert(1 + 2 == 3)
    assert(10 - 3 == 7)
    assert(4 * 5 == 20)
    assert(10 / 2 == 5)
    assert(7 % 3 == 1)

fn test_unary_negate:
    let x = 5
    let y = -x
    assert(y == -5)
    assert(-1 + 1 == 0)
    assert(-(3 + 4) == -7)

fn test_precedence:
    // * and / bind tighter than + and -
    assert(2 + 3 * 4 == 14)
    assert(10 - 6 / 2 == 7)
    assert(2 * 3 + 4 * 5 == 26)
    // Parentheses override
    assert((2 + 3) * 4 == 20)
    assert(10 / (2 + 3) == 2)

fn test_compound_assign:
    var x = 10
    x += 5
    assert(x == 15)
    x -= 3
    assert(x == 12)
    x *= 2
    assert(x == 24)
    x /= 4
    assert(x == 6)
    x %= 4
    assert(x == 2)

fn test_zero_and_identity:
    assert(0 + 42 == 42)
    assert(42 - 0 == 42)
    assert(1 * 99 == 99)
    assert(0 * 1000 == 0)

fn test_negative_arithmetic:
    assert(-3 + -4 == -7)
    assert(-10 - -3 == -7)
    assert(-2 * 3 == -6)
    assert(-2 * -3 == 6)

fn main:
    test_basic_ops()
    test_unary_negate()
    test_precedence()
    test_compound_assign()
    test_zero_and_identity()
    test_negative_arithmetic()
    println("ok")
