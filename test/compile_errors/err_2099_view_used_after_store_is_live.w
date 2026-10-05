//! expect-error: cannot mutate `rocks` while `last` is a live view into it

// #2099: a view used after the store is still live across it.

type Rock { x: f32 = 0.0 }
impl Copy for Rock

fn main:
    var rocks: Vec[Rock] = Vec.new()
    rocks.push(Rock { x: 1.0 })
    let last = rocks[0]
    rocks[0] = Rock { x: 9.0 }
    print(f"{last.x}")
