//! expect-stdout: ok

// Behavior test: infinite loops with while true and break
// TODO: loop: keyword as distinct from while true: not yet parsed.

fn test_while_true_break:
    var count = 0
    while true:
        count += 1
        if count == 5:
            break
    assert(count == 5)

fn test_while_true_accumulate:
    var sum = 0
    var i = 1
    while true:
        sum += i
        i += 1
        if i > 10:
            break
    // 1+2+...+10 = 55
    assert(sum == 55)

fn test_nested_while_true:
    var total = 0
    var outer = 0
    while true:
        var inner = 0
        while true:
            total += 1
            inner += 1
            if inner == 3:
                break
        outer += 1
        if outer == 4:
            break
    assert(total == 12)

fn main:
    test_while_true_break()
    test_while_true_accumulate()
    test_nested_while_true()
    println("ok")
