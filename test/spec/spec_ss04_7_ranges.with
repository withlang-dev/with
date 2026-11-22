// Spec test: Section 4.7 - Ranges.

fn classify_status(code: i32) -> str:
    match code:
        200..=299 => "ok"
        400..=499 => "client"
        _ => "other"

fn test_exclusive_range_for_loop:
    var sum = 0
    for i in 0..5:
        sum += i
    assert(sum == 10)

fn test_inclusive_range_for_loop:
    var sum = 0
    for i in 0..=5:
        sum += i
    assert(sum == 15)

fn test_stored_range_iterates_directly:
    let r = 0..5
    var sum = 0
    for i in r:
        sum += i
    assert(sum == 10)

fn test_range_membership_boundaries:
    assert(5 in 1..10)
    assert(not (10 in 1..10))
    assert(10 in 1..=10)
    assert(not (0 in 1..10))

fn test_range_patterns:
    assert(classify_status(204) == "ok")
    assert(classify_status(404) == "client")
    assert(classify_status(500) == "other")
