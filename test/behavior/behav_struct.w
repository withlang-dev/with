//! expect-stdout: ok

// End-to-end test: struct definition, construction, field access
// Tests: struct type, construction, field access, methods

type Point {
    x: i32,
    y: i32,
}

fn make_point(x: i32, y: i32) -> Point:
    Point { x: x, y: y }

fn test_struct_construction:
    let p = Point { x: 10, y: 20 }
    assert(p.x == 10)
    assert(p.y == 20)

fn test_struct_from_fn:
    let p = make_point(3, 4)
    assert(p.x == 3)
    assert(p.y == 4)

fn test_struct_field_arithmetic:
    let p = Point { x: 5, y: 7 }
    let sum = p.x + p.y
    assert(sum == 12)

type Rect {
    width: i32,
    height: i32,
}

fn area(r: Rect) -> i32:
    r.width * r.height

fn test_struct_pass_to_fn:
    let r = Rect { width: 3, height: 4 }
    assert(area(r) == 12)

fn test_two_structs:
    let p = Point { x: 1, y: 2 }
    let r = Rect { width: 10, height: 20 }
    assert(p.x + r.width == 11)

fn test_nested_field_expression:
    let r = Rect { width: 6, height: 7 }
    let double_area = area(r) * 2
    assert(double_area == 84)

fn main:
    test_struct_construction()
    test_struct_from_fn()
    test_struct_field_arithmetic()
    test_struct_pass_to_fn()
    test_two_structs()
    test_nested_field_expression()
    print("ok")
