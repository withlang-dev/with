use c_import("tally.h", link: "tally")
use tally

@[test]
fn a_macro_is_a_constant:
    assert(TALLY_VERSION == "1.2")

@[test]
fn a_struct_crosses_by_value_both_ways:
    let values = [4, -2, 7, 1]
    let range = range_of(values)
    assert(range.low == -2 and range.high == 7)
    let wide = widened(range, 10)
    assert(wide.low == -12 and wide.high == 17)
    // The argument was passed by value: C widened its own copy.
    assert(range.low == -2)

@[test]
fn c_calls_a_with_function_once_per_value:
    let values = [3, 1, 2]
    let seen = visited(values)
    assert(seen.len() == 3 and seen[0] == 3 and seen[1] == 1 and seen[2] == 2)

@[test]
fn c_calls_an_exported_with_function:
    let values = [4, -2, 7, 1]
    // score() squares, and scores a negative as 0: 16 + 0 + 49 + 1.
    assert(total(values) == 66)

@[test]
fn an_empty_slice_reaches_c_as_null_and_zero:
    let none: Vec[i32] = Vec.new()
    assert(visited(none).len() == 0 and total(none) == 0)

@[test]
fn a_c_global_is_readable:
    let before = calls()
    let values = [1]
    total(values)
    assert(calls() == before + 1)
