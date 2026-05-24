//! expect-stdout: ok

type Point {
    x: i32,
    y: i32,
}

type Rect {
    origin: Point,
    width: i32,
    height: i32,
}

comptime fn make_point() -> Point:
    Point { x: 10, y: 20 }

comptime fn point_field_x() -> i32:
    let p = Point { x: 3, y: 7 }
    p.x

comptime fn point_field_y() -> i32:
    let p = Point { x: 3, y: 7 }
    p.y

comptime fn mutate_point() -> Point:
    var p = Point { x: 1, y: 2 }
    p.x = 100
    p.y = 200
    p

comptime fn nested_struct() -> Rect:
    let origin = Point { x: 5, y: 10 }
    Rect { origin: origin, width: 100, height: 50 }

comptime fn nested_field() -> i32:
    let r = Rect { origin: Point { x: 5, y: 10 }, width: 100, height: 50 }
    r.origin.x

comptime fn struct_with_vec() -> i64:
    var v = Vec[i32].new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.len()

const PT: Point = comptime make_point()
const PX: i32 = comptime point_field_x()
const PY: i32 = comptime point_field_y()
const MUT_PT: Point = comptime mutate_point()
const RECT: Rect = comptime nested_struct()
const NESTED_X: i32 = comptime nested_field()
const VEC_LEN: i64 = comptime struct_with_vec()

fn main:
    assert(PT.x == 10)
    assert(PT.y == 20)
    assert(PX == 3)
    assert(PY == 7)
    assert(MUT_PT.x == 100)
    assert(MUT_PT.y == 200)
    assert(RECT.origin.x == 5)
    assert(RECT.origin.y == 10)
    assert(RECT.width == 100)
    assert(RECT.height == 50)
    assert(NESTED_X == 5)
    assert(VEC_LEN == 3)
    print("ok")
