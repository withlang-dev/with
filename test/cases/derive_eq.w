// Test @[derive(Eq)] generates equality comparison

@[derive(Eq)]
type Color = {
    r: i32,
    g: i32,
    b: i32,
}

fn main() -> i32 =
    let a = Color { r: 255, g: 0, b: 0 }
    let b = Color { r: 255, g: 0, b: 0 }
    let c = Color { r: 0, g: 255, b: 0 }

    assert(a == b)
    assert(not (a == c))
    0
