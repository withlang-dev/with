// Test match with or-patterns and wildcards
type Dir = North | South | East | West

fn is_vertical(d: Dir) -> bool:
    match d
        North | South -> true
        _ -> false

fn to_num(d: Dir) -> i32:
    match d
        North -> 0
        South -> 1
        East -> 2
        West -> 3

fn main -> i32:
    println(is_vertical(North))
    println(is_vertical(East))
    println(to_num(West))
