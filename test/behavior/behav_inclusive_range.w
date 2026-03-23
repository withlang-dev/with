//! expect-stdout: ok

// Behavior test: inclusive range ..= in for loops and match patterns

fn test_inclusive_for:
    // ..= includes the upper bound
    var sum = 0
    for i in 0..=4:
        sum += i
    // 0+1+2+3+4 = 10
    assert(sum == 10)

fn test_exclusive_for:
    // .. excludes the upper bound
    var sum = 0
    for i in 0..4:
        sum += i
    // 0+1+2+3 = 6
    assert(sum == 6)

fn test_inclusive_vs_exclusive:
    var inclusive_count = 0
    for i in 1..=5:
        inclusive_count += 1
    assert(inclusive_count == 5)

    var exclusive_count = 0
    for i in 1..5:
        exclusive_count += 1
    assert(exclusive_count == 4)

fn test_inclusive_range_in_match:
    let x = 5
    let result = match x
        1..=3 => "low"
        4..=6 => "mid"
        _ => "high"
    assert(result == "mid")

fn main:
    test_inclusive_for()
    test_exclusive_for()
    test_inclusive_vs_exclusive()
    test_inclusive_range_in_match()
    println("ok")
