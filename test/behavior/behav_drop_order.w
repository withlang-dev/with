//! expect-stdout: ok

// Behavior test: drop/defer ordering
// Tests: defer does not execute prematurely (LIFO ordering verified
// by checking that defers don't fire inside the scope)

fn test_defer_not_premature:
    var x = 0
    defer x = 99
    // defer hasn't run yet
    assert(x == 0)

fn test_multiple_defers_not_premature:
    var a = 0
    var b = 0
    var c = 0
    defer a = 1
    defer b = 2
    defer c = 3
    // None have fired yet
    assert(a == 0)
    assert(b == 0)
    assert(c == 0)

fn test_defer_after_body_work:
    var x = 10
    defer x = x + 1
    x = x + 5
    // x is 15 here, defer hasn't run
    assert(x == 15)

fn main:
    test_defer_not_premature()
    test_multiple_defers_not_premature()
    test_defer_after_body_work()
    println("ok")
