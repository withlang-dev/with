//! expect-stdout: ok

type Point { x: i32, y: i32 }

fn Point.new(x: i32, y: i32) -> Self:
    Self { x: x, y: y }

fn Point.origin() -> Self:
    Self { x: 0, y: 0 }

fn Point.sum(self: Point) -> i32:
    self.x + self.y

fn Point.translate(self: Point, dx: i32, dy: i32) -> Self:
    Self { x: self.x + dx, y: self.y + dy }

fn main:
    let p = Point.new(1, 2)
    assert(p.x == 1)
    assert(p.y == 2)
    assert(p.sum() == 3)

    let o = Point.origin()
    assert(o.x == 0)
    assert(o.y == 0)

    let q = p.translate(10, 20)
    assert(q.x == 11)
    assert(q.y == 22)

    println("ok")
