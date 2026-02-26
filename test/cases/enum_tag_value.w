type Direction = North | South | East | West

fn to_str(d: Direction) -> str =
    match d
        North -> "N"
        South -> "S"
        East -> "E"
        West -> "W"

fn main() -> i32 =
    println(to_str(North))
    println(to_str(South))
    println(to_str(East))
    println(to_str(West))
    0
