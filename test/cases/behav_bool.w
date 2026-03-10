//! expect-stdout: ok

// End-to-end test: boolean operations
// Tests: and, or, not, short-circuit, comparisons

fn test_bool_literals:
    assert(true)
    assert(not false)

fn test_and:
    assert(true and true)
    assert(not (true and false))
    assert(not (false and true))
    assert(not (false and false))

fn test_or:
    assert(true or true)
    assert(true or false)
    assert(false or true)
    assert(not (false or false))

fn test_not:
    assert(not false)
    assert(not not true)
    assert(not (1 == 2))
    assert(not (5 < 3))

fn test_comparisons:
    assert(1 == 1)
    assert(1 != 2)
    assert(3 < 5)
    assert(5 > 3)
    assert(3 <= 3)
    assert(3 <= 5)
    assert(5 >= 5)
    assert(5 >= 3)

fn test_compound_bool:
    let x = 5
    assert(x > 0 and x < 10)
    assert(x == 5 or x == 6)
    assert(not (x > 10 or x < 0))

fn test_bool_in_if:
    let a = true
    let b = false
    let result = if a and not b then 1 else 0
    assert(result == 1)

fn test_equality_of_bools:
    assert(true == true)
    assert(false == false)
    assert(true != false)

fn main:
    test_bool_literals()
    test_and()
    test_or()
    test_not()
    test_comparisons()
    test_compound_bool()
    test_bool_in_if()
    test_equality_of_bools()
    println("ok")
