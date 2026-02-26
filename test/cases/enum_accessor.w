// Test: Auto-generated enum accessors (.is_X, .as_X)
type Shape = Circle(i32) | Rectangle(i32, i32) | Point

fn main -> i32:
    // .is_X() tests
    let c = Circle(5)
    assert(c.is_Circle())
    assert(not c.is_Rectangle())
    assert(not c.is_Point())

    let r = Rectangle(3, 4)
    assert(r.is_Rectangle())
    assert(not r.is_Circle())

    let p: Shape = Point
    assert(p.is_Point())
    assert(not p.is_Circle())

    // .as_X() tests — returns Option
    let c2 = Circle(42)
    let maybe_radius = c2.as_Circle()
    assert(maybe_radius.is_some())
    assert(maybe_radius.unwrap() == 42)

    // .as_X() on wrong variant returns None
    let r2 = Rectangle(3, 4)
    let not_circle = r2.as_Circle()
    assert(not_circle.is_none())

    println("all enum accessor tests passed")
