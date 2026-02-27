type Point = {
    x: i32,
    y: i32,
}

fn sum_point({ x, y }: Point) -> i32:
    x + y

fn dist2({ x: x1, y: y1 }: Point, { x: x2, y: y2 }: Point) -> i32:
    let dx = x2 - x1
    let dy = y2 - y1
    dx * dx + dy * dy

fn swap((a, b): (i32, i32)) -> (i32, i32):
    (b, a)

fn main -> i32:
    let a = sum_point(Point { x: 20, y: 22 })
    let b = dist2(Point { x: 0, y: 0 }, Point { x: 3, y: 4 })
    let s = swap((1, 2))
    if a == 42 and b == 25 and s.0 == 2 and s.1 == 1 then 0 else 1
