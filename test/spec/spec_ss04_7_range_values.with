// Spec test: Section 4.7 - Range Values.

fn count_range(r: Range[i32]) -> i32:
    var total = 0
    for _ in r:
        total += 1
    total

fn count_inclusive_range(r: RangeInclusive[i32]) -> i32:
    var total = 0
    for _ in r:
        total += 1
    total

fn test_range_values_can_be_stored_and_iterated:
    let window: Range[i32] = 0..4
    assert(count_range(window) == 4)

fn test_range_values_support_membership:
    let window = 0..4
    assert(0 in window)
    assert(3 in window)
    assert(not (4 in window))

fn test_inclusive_range_values:
    let window: RangeInclusive[i32] = 1..=3
    assert(count_inclusive_range(window) == 3)
    assert(1 in window)
    assert(3 in window)
