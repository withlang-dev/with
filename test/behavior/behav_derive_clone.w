//! expect-stdout: ok

@[derive(Clone)]
type Point { x: i32, y: i32 }

const HAS_CLONE: bool = comptime Point.implements(Clone)

fn main:
    let p = Point { x: 10, y: 20 }
    let q = p.clone()
    assert(HAS_CLONE)
    assert(p.x == 10)
    assert(p.y == 20)
    assert(q.x == 10)
    assert(q.y == 20)
    print("ok")
