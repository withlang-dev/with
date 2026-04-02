//! expect-stdout: ok

type Point { x: f64, y: f64 }

async fn make_point(x: f64, y: f64) -> Point:
    Point { x, y }

async fn main:
    let t = make_point(3.0, 4.0)
    let p = t.await
    assert(p.x == 3.0)
    assert(p.y == 4.0)
    print("ok")
