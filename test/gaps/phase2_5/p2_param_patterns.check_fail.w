type Point = {
    x: i32,
    y: i32,
}

fn sum_point({ x: x1, y: y1 }: Point) -> i32 =
    x1 + y1

fn swap((a, b): (i32, i32)) -> (i32, i32) =
    (b, a)

fn main() -> i32 =
    let a = sum_point(Point { x: 20, y: 22 })
    let s = swap((1, 2))
    if a == 42 and s.0 == 2 and s.1 == 1 then 0 else 1
