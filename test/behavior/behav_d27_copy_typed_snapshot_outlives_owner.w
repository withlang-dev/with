//! expect-exit: 0

// D27: an owned annotation materializes a Copy element and clears its view
// origin, so the snapshot may survive both mutation and the owner's scope.

fn snapshot() -> i32:
    var values: Vec[i32] = Vec.new()
    values.push(41)
    let value: i32 = values[0]
    values.push(42)
    value

fn main:
    assert(snapshot() == 41)
