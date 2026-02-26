// Test exhaustive match on enums
type Direction = Up | Down | Left | Right

fn to_dx(d: Direction) -> i32:
    match d
        Up -> 0
        Down -> 0
        Left -> -1
        Right -> 1

fn to_dy(d: Direction) -> i32:
    match d
        Up -> 1
        Down -> -1
        Left -> 0
        Right -> 0

fn main -> i32:
    println(to_dx(Left))
    println(to_dx(Right))
    println(to_dy(Up))
    println(to_dy(Down))
