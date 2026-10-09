//! expect-error: type mismatch in binding

// D27 E3: a typed binding demands owned Thing; the exact element type is
// &Thing and a non-Copy pointee cannot materialize.

type Thing { vals: List[i32] }

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    let t: Thing = items[0]
    assert(t.vals.len() == 0)
