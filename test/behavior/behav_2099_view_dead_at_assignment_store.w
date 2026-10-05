//! expect-stdout: 2
//! expect-stdout: 2 2

// #2099: a view whose last use is inside an assignment is dead when the
// place is written: the right-hand side is evaluated before the store, and
// an owned demand materializes a Copy value where it is read (D22). Naming
// `rocks[n]` first and assigning the name is the inline form with a name.

type Rock { x: f32 = 0.0 }
impl Copy for Rock

fn main:
    var rocks: Vec[Rock] = Vec.new()
    rocks.push(Rock { x: 1.0 })
    rocks.push(Rock { x: 2.0 })
    let last = rocks[rocks.len() as i32 - 1]
    rocks[0] = last
    print(f"{rocks[0].x}")
    let same = rocks[1]
    rocks[1] = same
    print(f"{rocks[1].x} {rocks.len()}")
