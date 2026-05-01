//! expect-stdout: 30
type Vec2 { x: i32, y: i32 }

fn add_refs(a: &i32, b: &i32) -> i32: *a + *b

fn main:
    var v = Vec2 { x: 10, y: 20 }
    let rx = &v.x
    let ry = &v.y
    let sum = *rx + *ry
    print(int_to_string(sum) ++ "\n")
