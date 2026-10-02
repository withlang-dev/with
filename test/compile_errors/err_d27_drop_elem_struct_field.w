//! expect-error: type mismatch in struct literal field

// D27 E3: a known owned field is a demand; &Thing remains a view.

type Thing { vals: Vec[i32] }
type Holder { t: Thing }

fn main:
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: Vec.new() })
    let h = Holder { t: items[0] }
    assert(h.t.vals.len() == 0)
