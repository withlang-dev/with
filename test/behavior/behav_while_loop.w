//! expect-stdout: ok

// Tests: while basic, while with break, while with continue,
//        nested while, while true + break, countdown, do-while pattern

fn test_while_basic:
    var i = 0
    while i < 5:
        i = i + 1
    assert(i == 5)

fn test_while_sum:
    var sum = 0
    var i = 1
    while i <= 100:
        sum = sum + i
        i = i + 1
    assert(sum == 5050)

fn test_while_break:
    var i = 0
    while true:
        if i == 10:
            break
        i = i + 1
    assert(i == 10)

fn test_while_continue:
    // Sum only odd numbers from 1 to 10
    var sum = 0
    var i = 0
    while i < 10:
        i = i + 1
        if i % 2 == 0:
            continue
        sum = sum + i
    // 1+3+5+7+9 = 25
    assert(sum == 25)

fn test_while_false:
    var executed = false
    while false:
        executed = true
    assert(not executed)

fn test_nested_while:
    var count = 0
    var i = 0
    while i < 3:
        var j = 0
        while j < 4:
            count = count + 1
            j = j + 1
        i = i + 1
    assert(count == 12)

fn test_while_countdown:
    var n = 10
    while n > 0:
        n = n - 1
    assert(n == 0)

fn test_while_break_value:
    // Pattern: use while true + break for do-while
    var i = 0
    var sum = 0
    while true:
        sum = sum + i
        i = i + 1
        if i > 5:
            break
    // 0+1+2+3+4+5 = 15
    assert(sum == 15)

fn test_while_multiple_conditions:
    var a = 0
    var b = 100
    while a < b:
        a = a + 1
        b = b - 1
    assert(a == 50)
    assert(b == 50)

fn test_while_nested_break:
    var outer_count = 0
    var i = 0
    while i < 5:
        var j = 0
        while j < 5:
            if j == 2:
                break
            j = j + 1
        outer_count = outer_count + 1
        i = i + 1
    assert(outer_count == 5)

fn collatz_steps(n: i32) -> i32:
    var val = n
    var steps = 0
    while val != 1:
        if val % 2 == 0:
            val = val / 2
        else:
            val = val * 3 + 1
        steps = steps + 1
    steps

fn test_while_collatz:
    assert(collatz_steps(1) == 0)
    assert(collatz_steps(2) == 1)
    assert(collatz_steps(4) == 2)
    // 3 → 10 → 5 → 16 → 8 → 4 → 2 → 1 = 7 steps
    assert(collatz_steps(3) == 7)

fn main:
    test_while_basic()
    test_while_sum()
    test_while_break()
    test_while_continue()
    test_while_false()
    test_nested_while()
    test_while_countdown()
    test_while_break_value()
    test_while_multiple_conditions()
    test_while_nested_break()
    test_while_collatz()
    print("ok")
