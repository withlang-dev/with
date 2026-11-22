//! expect-stdout: ok

fn test_basic:
    var x = 0
    do:
        x += 1
    while x < 5
    assert(x == 5)

fn test_executes_once_when_false:
    var x = 0
    do:
        x += 1
    while false
    assert(x == 1)

fn test_break:
    var x = 0
    do:
        x += 1
        if x == 3:
            break
    while x < 10
    assert(x == 3)

fn test_continue_jumps_to_condition:
    var sum = 0
    var i = 0
    do:
        i += 1
        if i % 2 == 0:
            continue
        sum += i
    while i < 10
    assert(sum == 25)

fn test_condition_side_effects:
    var p = 0
    var count = 0
    do:
        count += 1
    while { p += 1; p < 5 }
    assert(count == 5)
    assert(p == 5)

fn test_braced:
    var x = 0
    do {
        x += 1
    } while x < 3
    assert(x == 3)

fn test_nested:
    var total = 0
    var i = 0
    do:
        var j = 0
        do:
            total += 1
            j += 1
        while j < 3
        i += 1
    while i < 4
    assert(total == 12)

fn test_do_while_in_while:
    var outer = 0
    var inner_total = 0
    while outer < 3:
        var x = 0
        do:
            x += 1
            inner_total += 1
        while x < 2
        outer += 1
    assert(inner_total == 6)

fn main:
    test_basic()
    test_executes_once_when_false()
    test_break()
    test_continue_jumps_to_condition()
    test_condition_side_effects()
    test_braced()
    test_nested()
    test_do_while_in_while()
    print("ok")
