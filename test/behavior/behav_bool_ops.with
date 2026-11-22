//! expect-stdout: ok

// Tests: bool literals, bool-to-int cast, bool comparison,
//        compile-time bool not, short-circuit evaluation

fn test_bool_literals:
    assert(true)
    assert(not false)
    assert(true == true)
    assert(false == false)
    assert(true != false)

fn test_cast_bool_to_int:
    let t = true
    let f = false
    assert(t as i32 == 1)
    assert(f as i32 == 0)
    // Non-const path
    assert(cast_bool(true) == 1)
    assert(cast_bool(false) == 0)

fn cast_bool(b: bool) -> i32:
    b as i32

fn test_bool_cmp:
    assert(bool_cmp(true, true))
    assert(bool_cmp(false, false))
    assert(not bool_cmp(true, false))
    assert(not bool_cmp(false, true))

fn bool_cmp(a: bool, b: bool) -> bool:
    a == b

fn test_short_circuit_or:
    // `or` short-circuits: if LHS is true, RHS not evaluated
    var evaluated_rhs = false
    let result = true or unsafe { side_effect(&raw mut evaluated_rhs) }
    assert(result)
    assert(not evaluated_rhs)  // RHS was NOT evaluated
    // When LHS is false, RHS IS evaluated
    var evaluated_rhs2 = false
    let result2 = false or unsafe { side_effect(&raw mut evaluated_rhs2) }
    assert(result2)
    assert(evaluated_rhs2)

fn test_short_circuit_and:
    // `and` short-circuits: if LHS is false, RHS not evaluated
    var evaluated_rhs = false
    let result = false and unsafe { side_effect(&raw mut evaluated_rhs) }
    assert(not result)
    assert(not evaluated_rhs)  // RHS was NOT evaluated
    // When LHS is true, RHS IS evaluated
    var evaluated_rhs2 = false
    let result2 = true and unsafe { side_effect(&raw mut evaluated_rhs2) }
    assert(result2)
    assert(evaluated_rhs2)

unsafe fn side_effect(flag: *mut bool) -> bool:
    *flag = true
    true

fn test_bool_not:
    assert(not false)
    assert(not not true)
    let x = true
    assert(not not x)
    let y = false
    assert(not y)

fn main:
    test_bool_literals()
    test_cast_bool_to_int()
    test_bool_cmp()
    test_short_circuit_or()
    test_short_circuit_and()
    test_bool_not()
    print("ok")
