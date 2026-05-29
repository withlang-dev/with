//! expect-stdout: ok

// Tests: struct creation, field access, field mutation, nested structs,
//        struct methods, struct as argument, struct return, default-like patterns

type Point { x: i32, y: i32 }

type Rect { origin: Point, size: Point }

type Color3 { r: f32, g: f32, b: f32 }

fn test_struct_create_and_access:
    let p = Point { x: 10, y: 20 }
    assert(p.x == 10)
    assert(p.y == 20)

fn test_struct_mutation:
    var p = Point { x: 1, y: 2 }
    p.x = 100
    p.y = 200
    assert(p.x == 100)
    assert(p.y == 200)

fn test_nested_struct:
    let r = Rect {
        origin: Point { x: 0, y: 0 },
        size: Point { x: 100, y: 50 }
    }
    assert(r.origin.x == 0)
    assert(r.origin.y == 0)
    assert(r.size.x == 100)
    assert(r.size.y == 50)

fn test_nested_struct_mutation:
    var r = Rect {
        origin: Point { x: 0, y: 0 },
        size: Point { x: 10, y: 10 }
    }
    r.origin.x = 5
    r.size.y = 20
    assert(r.origin.x == 5)
    assert(r.size.y == 20)

fn make_point(x: i32, y: i32) -> Point:
    Point { x: x, y: y }

fn test_struct_return:
    let p = make_point(42, 99)
    assert(p.x == 42)
    assert(p.y == 99)

fn add_points(a: Point, b: Point) -> Point:
    Point { x: a.x + b.x, y: a.y + b.y }

fn test_struct_as_argument:
    let a = Point { x: 1, y: 2 }
    let b = Point { x: 3, y: 4 }
    let c = add_points(a, b)
    assert(c.x == 4)
    assert(c.y == 6)

fn manhattan(p: Point) -> i32:
    let ax = if p.x < 0: -p.x else: p.x
    let ay = if p.y < 0: -p.y else: p.y
    ax + ay

fn test_struct_in_computation:
    let p = Point { x: -3, y: 4 }
    assert(manhattan(p) == 7)

fn test_struct_equality:
    let a = Point { x: 1, y: 2 }
    let b = Point { x: 1, y: 2 }
    assert(a.x == b.x)
    assert(a.y == b.y)

fn test_struct_with_floats:
    let c = Color3 { r: 1.0f32, g: 0.5f32, b: 0.0f32 }
    assert(c.r as i32 == 1)
    assert(c.b as i32 == 0)

type Counter { value: i32 }

fn counter_inc(c: *mut Counter):
    unsafe (*c).value = unsafe (*c).value + 1

fn test_struct_pointer:
    var c = Counter { value: 0 }
    counter_inc(&raw mut c)
    counter_inc(&raw mut c)
    counter_inc(&raw mut c)
    assert(c.value == 3)

type Pair { first: i32, second: i32 }

fn swap_pair(p: Pair) -> Pair:
    Pair { first: p.second, second: p.first }

fn test_struct_swap:
    let p = Pair { first: 10, second: 20 }
    let q = swap_pair(p)
    assert(q.first == 20)
    assert(q.second == 10)

type Mixed { a: i32, b: f64, c: bool }

fn test_struct_mixed_types:
    let m = Mixed { a: 42, b: 3.14, c: true }
    assert(m.a == 42)
    assert(m.b as i64 == 3i64)
    assert(m.c)

fn test_struct_copy:
    let a = Point { x: 5, y: 10 }
    let b = a
    assert(b.x == 5)
    assert(b.y == 10)

fn test_struct_in_array:
    let points = [Point { x: 1, y: 2 }, Point { x: 3, y: 4 }, Point { x: 5, y: 6 }]
    assert(points[0].x == 1)
    assert(points[1].y == 4)
    assert(points[2].x == 5)

fn main:
    test_struct_create_and_access()
    test_struct_mutation()
    test_nested_struct()
    test_nested_struct_mutation()
    test_struct_return()
    test_struct_as_argument()
    test_struct_in_computation()
    test_struct_equality()
    test_struct_with_floats()
    test_struct_pointer()
    test_struct_swap()
    test_struct_mixed_types()
    test_struct_copy()
    test_struct_in_array()
    print("ok")
