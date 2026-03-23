//! expect-stdout: ok

// End-to-end test: for loops
// Tests: for-range, break, continue, nested for

fn test_ranges:
    var sum = 0
    for i in 0..5:
        sum += i
    // 0+1+2+3+4 = 10
    assert(sum == 10)
    // Range with non-zero start
    var sum2 = 0
    for i in 3..6:
        sum2 += i
    // 3+4+5 = 12
    assert(sum2 == 12)
    // Empty range
    var count = 0
    for i in 5..5:
        count += 1
    assert(count == 0)

fn test_break_continue:
    // Break
    var sum = 0
    for i in 0..100:
        if i == 5:
            break
        sum += i
    assert(sum == 10)
    // Continue: skip evens
    var odd_sum = 0
    for i in 0..6:
        if i % 2 == 0:
            continue
        odd_sum += i
    assert(odd_sum == 9)

fn test_nested_and_accumulate:
    var count = 0
    for i in 0..3:
        for j in 0..4:
            count += 1
    assert(count == 12)
    // Factorial via for
    var product = 1
    for i in 1..6:
        product *= i
    assert(product == 120)

fn main:
    test_ranges()
    test_break_continue()
    test_nested_and_accumulate()
    println("ok")
