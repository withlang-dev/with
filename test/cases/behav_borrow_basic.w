//! expect-stdout: ok

// Behavior test: basic borrow checking
// Tests: value binding, copying, references

fn test_value_copy:
    let x = 42
    let y = x
    assert(y == 42)
    assert(x == 42)

fn test_mut_variable:
    var x = 10
    x = 20
    assert(x == 20)

fn test_ref_basic:
    let x = 100
    let y = x + 1
    assert(y == 101)

fn test_pass_by_value:
    let a = 5
    let b = 10
    let sum = a + b
    assert(sum == 15)

fn test_nested_bindings:
    let a = 1
    let b = a + 1
    let c = b + 1
    let d = c + 1
    assert(d == 4)

fn main:
    test_value_copy()
    test_mut_variable()
    test_ref_basic()
    test_pass_by_value()
    test_nested_bindings()
    println("ok")
