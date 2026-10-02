//! expect-error: type mismatch in binding

// D27 E3: a typed binding demands owned Thing; the exact element type is
// &Thing and a non-Copy pointee cannot materialize.

type Thing { vals: Vec[i32] }

fn main:
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: Vec.new() })
    let t: Thing = items[0]
    assert(t.vals.len() == 0)
