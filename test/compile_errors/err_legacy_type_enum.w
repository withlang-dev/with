//! expect-error: use 'enum' for enum declarations
type Direction = North | South | East | West

fn main:
    let _ = Direction.North
