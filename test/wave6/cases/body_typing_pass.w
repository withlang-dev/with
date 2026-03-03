// Wave 6 unit test: body checking and expression typing
// Covers: arithmetic, comparisons, field access, let bindings, calls

type Vec2 = {
    x: i32,
    y: i32,
}

fn add(a: i32, b: i32) -> i32:
    a + b

// field_access appears in dump when it is the direct return value
fn get_x(v: Vec2) -> i32:
    v.x

// call appears in dump when it is the direct return value
fn do_add(a: i32, b: i32) -> i32:
    add(a, b)

fn main -> i32:
    let x: i32 = 10
    let y: i32 = 20
    let sum = add(x, y)
    let ok = sum > 0
    let v = Vec2 { x: 1, y: 2 }
    let vx = v.x
    vx + sum
