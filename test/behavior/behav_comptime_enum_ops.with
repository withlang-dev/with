//! expect-stdout: ok

enum Direction: i32:
    North = 0
    East = 1
    South = 2
    West = 3

comptime fn dir_north() -> Direction:
    Direction.North

comptime fn dir_east_val() -> i32:
    Direction.East as i32

comptime fn dir_match() -> i32:
    let d = Direction.South
    match d:
        Direction.North => 10
        Direction.East => 20
        Direction.South => 30
        Direction.West => 40

comptime fn dir_compare() -> bool:
    let a = Direction.North
    let b = Direction.North
    a == b

comptime fn dir_not_equal() -> bool:
    let a = Direction.North
    let b = Direction.South
    a != b

const DN: Direction = comptime dir_north()
const DE_VAL: i32 = comptime dir_east_val()
const D_MATCH: i32 = comptime dir_match()
const D_EQ: bool = comptime dir_compare()
const D_NEQ: bool = comptime dir_not_equal()

fn main:
    assert(DN as i32 == 0)
    assert(DE_VAL == 1)
    assert(D_MATCH == 30)
    assert(D_EQ == true)
    assert(D_NEQ == true)
    print("ok")
