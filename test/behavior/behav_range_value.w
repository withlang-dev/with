//! expect-stdout: ok

fn main:
    // Range literals in for loops
    var sum = 0
    for i in 0..5:
        sum = sum + i
    assert(sum == 10)

    // Inclusive range literal
    var sum2 = 0
    for i in 1..=3:
        sum2 = sum2 + i
    assert(sum2 == 6)

    // Range stored in variable
    let r = 0..5
    var sum3 = 0
    for i in r:
        sum3 = sum3 + i
    assert(sum3 == 10)

    // Inclusive range in variable
    let r2 = 1..=3
    var sum4 = 0
    for i in r2:
        sum4 = sum4 + i
    assert(sum4 == 6)

    print("ok")
