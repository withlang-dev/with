//! expect-stdout: ok

// Behavior test: type system
// Tests: struct types, enum types, arrays, function types

type Point {
    x: i32,
    y: i32,
}

enum Color { Red | Green | Blue }

fn make_point(x: i32, y: i32) -> Point:
    Point { x: x, y: y }

fn test_struct:
    let p = Point { x: 42, y: 10 }
    assert(p.x == 42)
    assert(p.y == 10)
    println(int_to_string(p.x))

fn test_struct_from_fn:
    let p = make_point(3, 4)
    assert(p.x == 3)
    assert(p.y == 4)

fn test_enum:
    let c: Color = .Red
    let result = match c
        .Red => "red"
        .Green => "green"
        .Blue => "blue"
    assert(result == "red")

fn test_enum_equality:
    let a: Color = .Green
    let b: Color = .Green
    let c: Color = .Blue
    assert(a == b)
    assert(a != c)

fn test_array:
    let arr = [1, 2, 3]
    assert(arr[0] == 1)
    assert(arr[1] == 2)
    assert(arr[2] == 3)

fn main:
    test_struct()
    test_struct_from_fn()
    test_enum()
    test_enum_equality()
    test_array()
    println("ok")
