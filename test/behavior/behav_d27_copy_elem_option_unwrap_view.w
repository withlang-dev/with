//! expect-exit: 0

// D27 E3 / D22 §5.1: exact-payload eliminators observe through borrowed
// Option/Result carriers. Unannotated bindings retain &i32; typed bindings
// materialize the Copy pointee while each carrier stays vec-owned.

fn main:
    var values: Vec[Option[i32]] = Vec.new()
    values.push(Some(5))
    let option_view = values[0].unwrap()
    let option_value: i32 = option_view
    assert(option_value == 5)

    var expected: Vec[Option[i32]] = Vec.new()
    expected.push(Some(6))
    let expected_view = expected[0].expect("present")
    let expected_value: i32 = expected_view
    assert(expected_value == 6)

    var results: Vec[Result[i32, str]] = Vec.new()
    results.push(Ok(7))
    let result_view = results[0].unwrap()
    let result_value: i32 = result_view
    assert(result_value == 7)

    var result_expected: Vec[Result[i32, str]] = Vec.new()
    result_expected.push(Ok(8))
    let result_expected_view = result_expected[0].expect("present")
    let result_expected_value: i32 = result_expected_view
    assert(result_expected_value == 8)
