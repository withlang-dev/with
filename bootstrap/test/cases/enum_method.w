type Direction = North | South | East | West

fn Direction.opposite(self: Direction) -> Direction:
    match self
        North -> South
        South -> North
        East -> West
        West -> East

fn Direction.value(self: Direction) -> i32:
    match self
        North -> 1
        South -> 2
        East -> 3
        West -> 4

fn main -> i32:
    let d = North
    let opp = d.opposite()
    assert(d.value() + opp.value() + 39 == 42)
