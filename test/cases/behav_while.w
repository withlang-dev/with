//! expect-stdout: ok

// End-to-end test: while loops
// Tests: while, break, continue

fn test_basic_while:
    var x = 0
    while x < 10:
        x += 1
    assert(x == 10)

fn test_while_break:
    var x = 0
    while true:
        x += 1
        if x == 5:
            break
    assert(x == 5)

fn test_while_continue:
    var sum = 0
    var i = 0
    while i < 10:
        i += 1
        if i % 2 == 0:
            continue
        sum += i
    // 1+3+5+7+9 = 25
    assert(sum == 25)

fn test_while_countdown:
    var n = 10
    var steps = 0
    while n > 0:
        n -= 1
        steps += 1
    assert(steps == 10)
    assert(n == 0)

fn test_while_false:
    var ran = false
    while false:
        ran = true
    assert(not ran)

fn test_nested_while:
    var count = 0
    var i = 0
    while i < 3:
        var j = 0
        while j < 4:
            count += 1
            j += 1
        i += 1
    assert(count == 12)

fn test_while_complex_condition:
    var a = 0
    var b = 100
    while a < b:
        a += 10
        b -= 5
    // a=70, b=65 when a >= b
    assert(a >= b)

fn main:
    test_basic_while()
    test_while_break()
    test_while_continue()
    test_while_countdown()
    test_while_false()
    test_nested_while()
    test_while_complex_condition()
    println("ok")
