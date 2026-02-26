// Test: Iterator patterns - for loops over various ranges
fn main -> i32:
    // Exclusive range
    var sum = 0
    for i in 0..5:
        sum = sum + i
    assert(sum == 10)

    // Inclusive range
    var sum2 = 0
    for i in 1..=4:
        sum2 = sum2 + i
    assert(sum2 == 10)

    // Array iteration
    let arr = [10, 20, 30]
    var total = 0
    for x in arr:
        total = total + x
    assert(total == 60)

