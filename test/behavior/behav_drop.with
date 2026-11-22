//! expect-stdout: ok

// Behavior test: drop semantics via defer
// Tests: defer does not execute prematurely within scope

fn test_defer_basic:
    var x = 0
    defer: x = 10
    // defer hasn't run yet
    assert(x == 0)

fn test_defer_with_body:
    var x = 5
    defer: x = 99
    x = x + 10
    // Body executed, defer hasn't
    assert(x == 15)

fn test_multiple_defers:
    var x = 0
    defer: x = x + 1
    defer: x = x + 1
    defer: x = x + 1
    assert(x == 0)

fn main:
    test_defer_basic()
    test_defer_with_body()
    test_multiple_defers()
    print("ok")
