//! expect-check-fail: wrong argument type in call to 'takes_exclusive'

fn takes_exclusive(r: Range[i32]) -> i32:
    var total = 0
    for _ in r:
        total += 1
    total

fn bad_range_kind:
    takes_exclusive(0..=3)
