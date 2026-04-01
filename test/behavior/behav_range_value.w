//! expect-stdout: ok

fn main:
    // Range literals work directly in for loops
    var sum = 0
    for i in 0..5:
        sum = sum + i
    assert(sum == 10)

    // Inclusive range
    var sum2 = 0
    for i in 1..=3:
        sum2 = sum2 + i
    assert(sum2 == 6)

    print("ok")
