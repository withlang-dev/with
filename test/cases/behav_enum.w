//! expect-stdout: ok

// Behavior test: enums
// Tests: simple enums, discriminant enums, match on enums, variant shorthand

type Direction = North | South | East | West

type Color: i32 = Red = 1 | Green = 2 | Blue = 4

fn test_enum_shorthand:
    // Use shorthand syntax with type annotation for simple enums
    let d: Direction = .South
    let result = match d
        .North => "north"
        .South => "south"
        .East => "east"
        .West => "west"
    assert(result == "south")

fn test_enum_match_wildcard:
    let d: Direction = .East
    let result = match d
        .North => "north"
        _ => "other"
    assert(result == "other")

fn test_enum_equality:
    let a: Direction = .West
    let b: Direction = .West
    let c: Direction = .East
    assert(a == b)
    assert(a != c)
    assert(a == .West)
    assert(c != .West)

fn accept_direction(d: Direction) -> bool:
    let _ = d
    true

fn test_enum_call_arg:
    assert(accept_direction(Direction.North))
    assert(accept_direction(.South))

fn test_discriminant_enum:
    let c = Color.Green
    let result = match c
        .Red => "red"
        .Green => "green"
        .Blue => "blue"
        _ => "unknown"
    assert(result == "green")

fn test_discriminant_cast:
    let n: i32 = Color.Green as i32
    assert(n == 2)
    let n2: i32 = Color.Blue as i32
    assert(n2 == 4)

fn test_discriminant_shorthand:
    let c: Color = .Blue
    let r = match c
        .Red => "r"
        .Green => "g"
        .Blue => "b"
        _ => "?"
    assert(r == "b")

fn main:
    test_enum_shorthand()
    test_enum_match_wildcard()
    test_enum_equality()
    test_enum_call_arg()
    test_discriminant_enum()
    test_discriminant_cast()
    test_discriminant_shorthand()
    println("ok")
