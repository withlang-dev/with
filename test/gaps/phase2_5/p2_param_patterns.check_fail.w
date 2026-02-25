// Phase 2 gap: parameter patterns not implemented
type Point = {
    x: i32,
    y: i32,
}

fn sum_point({ x, y }: Point) -> i32 =
    x + y

fn main() -> i32 =
    if sum_point(Point { x: 20, y: 22 }) == 42 then 0 else 1
