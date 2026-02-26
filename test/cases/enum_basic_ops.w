type Color = Red | Green | Blue

fn to_int(c: Color) -> i32:
    match c
        Red -> 0
        Green -> 1
        Blue -> 2

fn main -> i32:
    println(to_int(Red))
    println(to_int(Green))
    println(to_int(Blue))
