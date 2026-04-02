//! expect-stdout: ok

type Point { x: i32, y: i32 }

async fn make_point(x: i32, y: i32) -> Point:
    Point { x, y }

async fn main:
    let t = make_point(3, 4)
    let p = t.await
    assert(p.x == 3)
    assert(p.y == 4)
    print("ok")
