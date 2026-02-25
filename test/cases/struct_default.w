// Test struct field default values

type Config = {
    width: i32 = 800,
    height: i32 = 600,
    depth: i32 = 32
}

type Point = {
    x: i32 = 0,
    y: i32 = 0
}

fn main() -> i32 =
    // All defaults
    let c1 = Config {}
    assert(c1.width == 800)
    assert(c1.height == 600)
    assert(c1.depth == 32)

    // Override some fields
    let c2 = Config { width: 1920, height: 1080 }
    assert(c2.width == 1920)
    assert(c2.height == 1080)
    assert(c2.depth == 32)

    // Override all fields
    let c3 = Config { width: 320, height: 240, depth: 16 }
    assert(c3.width == 320)
    assert(c3.height == 240)
    assert(c3.depth == 16)

    // Point with defaults
    let p1 = Point {}
    assert(p1.x == 0)
    assert(p1.y == 0)

    let p2 = Point { x: 10 }
    assert(p2.x == 10)
    assert(p2.y == 0)

    0
