//! expect-stdout: ok

// Tests: arithmetic operators, division, modulo, operator precedence,
//        overflow-safe patterns, bitwise operations, shift operations

fn test_basic_arithmetic:
    assert(2 + 3 == 5)
    assert(10 - 7 == 3)
    assert(4 * 5 == 20)
    assert(20 / 4 == 5)
    assert(17 % 5 == 2)

fn test_negative_arithmetic:
    assert(-5 + 3 == -2)
    assert(-5 - 3 == -8)
    assert(-5 * 3 == -15)
    assert(-15 / 3 == -5)
    assert(-17 % 5 == -2)

fn test_precedence:
    // Multiplication before addition
    assert(2 + 3 * 4 == 14)
    assert(10 - 2 * 3 == 4)
    // Parentheses override
    assert((2 + 3) * 4 == 20)
    assert((10 - 2) * 3 == 24)

fn test_associativity:
    // Left-to-right for same precedence
    assert(10 - 3 - 2 == 5)
    assert(100 / 10 / 2 == 5)

fn test_division:
    // Integer division truncates toward zero
    assert(7 / 2 == 3)
    assert(-7 / 2 == -3)
    assert(7 / -2 == -3)
    assert(-7 / -2 == 3)

fn test_modulo:
    assert(10 % 3 == 1)
    assert(10 % 5 == 0)
    assert(10 % 7 == 3)
    // Negative modulo follows truncation division
    assert(-10 % 3 == -1)
    assert(10 % -3 == 1)

fn test_bitwise_and:
    assert((0xFF & 0x0F) == 0x0F)
    assert((0xAB & 0xF0) == 0xA0)
    assert((0 & 0xFF) == 0)

fn test_bitwise_or:
    assert((0xF0 | 0x0F) == 0xFF)
    assert((0 | 0) == 0)
    assert((0xAA | 0x55) == 0xFF)

fn test_bitwise_xor:
    assert((0xFF ^ 0xFF) == 0)
    assert((0xFF ^ 0x00) == 0xFF)
    assert((0xAA ^ 0x55) == 0xFF)

fn test_shift_left:
    assert((1 << 0) == 1)
    assert((1 << 1) == 2)
    assert((1 << 4) == 16)
    assert((1 << 10) == 1024)

fn test_shift_right:
    assert((1024 >> 10) == 1)
    assert((16 >> 4) == 1)
    assert((255 >> 4) == 15)

fn test_combined_ops:
    // (a + b) * (c - d) / e
    let a = 10
    let b = 5
    let c = 20
    let d = 8
    let e = 3
    let result = (a + b) * (c - d) / e
    // (15) * (12) / 3 = 60
    assert(result == 60)

fn power(base: i32, exp: i32) -> i32:
    var result = 1
    var i = 0
    while i < exp:
        result = result * base
        i = i + 1
    result

fn test_power:
    assert(power(2, 0) == 1)
    assert(power(2, 1) == 2)
    assert(power(2, 10) == 1024)
    assert(power(3, 4) == 81)
    assert(power(10, 3) == 1000)

fn is_power_of_two(n: i32) -> bool:
    n > 0 and (n & (n - 1)) == 0

fn test_power_of_two:
    assert(is_power_of_two(1))
    assert(is_power_of_two(2))
    assert(is_power_of_two(4))
    assert(is_power_of_two(1024))
    assert(not is_power_of_two(3))
    assert(not is_power_of_two(6))
    assert(not is_power_of_two(0))

fn test_i64_arithmetic:
    let a: i64 = 1000000000i64
    let b: i64 = 2000000000i64
    let c = a * b
    // 2 * 10^18 — fits in i64
    assert(c == 2000000000000000000i64)

fn main:
    test_basic_arithmetic()
    test_negative_arithmetic()
    test_precedence()
    test_associativity()
    test_division()
    test_modulo()
    test_bitwise_and()
    test_bitwise_or()
    test_bitwise_xor()
    test_shift_left()
    test_shift_right()
    test_combined_ops()
    test_power()
    test_power_of_two()
    test_i64_arithmetic()
    print("ok")
