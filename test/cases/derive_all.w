@[derive(all)]
type Vec2 = { x: i32, y: i32 }

@[derive(all)]
type Name = { first: str, last: str }

fn main() -> i32 =
    let a = Vec2 { x: 1, y: 2 }
    let b = a
    assert(a.x == b.x)

    let n = Name { first: "A", last: "B" }
    let m = n.clone()
    assert(m.first == "A")
    0
