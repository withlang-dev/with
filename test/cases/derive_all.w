// Test @[derive(all)] generates both Eq and Clone

@[derive(all)]
type Vec2 = {
    x: i32,
    y: i32,
}

fn main -> i32:
    let a = Vec2 { x: 1, y: 2 }
    let b = Vec2 { x: 1, y: 2 }
    let c = Vec2 { x: 3, y: 4 }

    // Eq (derived)
    assert(a == b)
    assert(not (a == c))

    // Clone (derived)
    let d = a.clone()
    assert(d.x == 1)
    assert(d.y == 2)
