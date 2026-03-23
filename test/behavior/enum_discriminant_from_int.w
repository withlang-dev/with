//! expect-stdout: ok
extern fn print(s: str) -> void

type Direction: i32 = North = 0 | East = 1 | South = 2 | West = 3

fn main:
    // Verify construction and cast
    let south = Direction.South
    assert(south as i32 == 2)

    // Verify from_int produces Some for valid values
    let d0 = Direction.from_int(0)
    assert(d0.is_some())
    assert(d0.unwrap() == 0)

    let d1 = Direction.from_int(1)
    assert(d1.is_some())
    assert(d1.unwrap() == 1)

    let d3 = Direction.from_int(3)
    assert(d3.is_some())
    assert(d3.unwrap() == 3)

    // Verify from_int produces None for invalid values
    let bad = Direction.from_int(99)
    assert(bad.is_none())

    let bad2 = Direction.from_int(-1)
    assert(bad2.is_none())

    print("ok")
