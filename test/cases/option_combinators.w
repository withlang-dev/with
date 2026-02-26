// Test Option combinators: map, unwrap, unwrap_or, is_some, is_none

fn double(x: i32) -> i32 = x * 2

fn main() -> i32 =
    let some_val: ?i32 = Some(21)
    let none_val: ?i32 = None

    // is_some / is_none
    assert(some_val.is_some())
    assert(none_val.is_none())

    // unwrap_or
    assert(some_val.unwrap_or(0) == 21)
    assert(none_val.unwrap_or(99) == 99)

    // unwrap (on Some)
    assert(some_val.unwrap() == 21)

    // map
    let doubled = some_val.map(double)
    assert(doubled.unwrap_or(0) == 42)

    let none_doubled = none_val.map(double)
    assert(none_doubled.is_none())
    0
