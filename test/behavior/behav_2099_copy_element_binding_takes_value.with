//! expect-stdout: 1
// #2099 under D144: a binding from a place of plain bits takes the value,
// an element as a field. `Rock` is a plain struct of an f32, so `last` is
// the element's value when bound and the store after it is fine; it
// was a view of the element, refused as live across the store.

type Rock { x: f32 = 0.0 }
impl Copy for Rock

fn main:
    var rocks: List[Rock] = List.new()
    rocks.push(Rock { x: 1.0 })
    let last = rocks[0]
    rocks[0] = Rock { x: 9.0 }
    print(f"{last.x}")
