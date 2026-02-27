// Test auto-dereferencing: accessing fields through references

type Point = {
    x: i32,
    y: i32,
}

fn main -> i32:
    let p = Point { x: 10, y: 20 }
    let r = &p
    // Auto-deref: r.x should auto-deref through the reference
    assert(r.x == 10)
    assert(r.y == 20)
