//! expect-stdout: ok

// Behavior test: variable scoping
// Tests: let/var, nested scopes, mutation

fn test_let_immutable:
    let x = 42
    assert(x == 42)

fn test_var_mutable:
    var x = 10
    assert(x == 10)
    x = 20
    assert(x == 20)
    x = x + 5
    assert(x == 25)

fn test_nested_scope:
    let x = 10
    var result = 0
    if true:
        let y = 20
        result = x + y
    assert(result == 30)

fn test_block_scope_var:
    var total = 0
    for i in 0..5:
        let contrib = i * 2
        total = total + contrib
    // contrib is not visible here, total is 0+2+4+6+8 = 20
    assert(total == 20)

fn test_nested_if_scope:
    var result = 0
    let a = 5
    if a > 0:
        let b = 10
        if b > 5:
            let c = 20
            result = a + b + c
    assert(result == 35)

fn test_for_loop_scope:
    var last = 0
    for i in 0..10:
        last = i
    assert(last == 9)

fn main:
    test_let_immutable()
    test_var_mutable()
    test_nested_scope()
    test_block_scope_var()
    test_nested_if_scope()
    test_for_loop_scope()
    print("ok")
