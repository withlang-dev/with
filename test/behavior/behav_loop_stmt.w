//! expect-stdout: ok

// Behavior test: loop statement and while-true with break

fn test_loop_break:
    var count = 0
    loop:
        count = count + 1
        if count == 5:
            break
    assert(count == 5)

fn test_loop_accumulate:
    var sum = 0
    var i = 1
    loop:
        sum = sum + i
        i = i + 1
        if i > 10:
            break
    // 1+2+...+10 = 55
    assert(sum == 55)

fn test_while_true_break:
    var count = 0
    while true:
        count = count + 1
        if count == 5:
            break
    assert(count == 5)

fn test_nested_loops:
    var total = 0
    var outer = 0
    loop:
        var inner = 0
        loop:
            total = total + 1
            inner = inner + 1
            if inner == 3:
                break
        outer = outer + 1
        if outer == 4:
            break
    assert(total == 12)

fn main:
    test_loop_break()
    test_loop_accumulate()
    test_while_true_break()
    test_nested_loops()
    print("ok")
