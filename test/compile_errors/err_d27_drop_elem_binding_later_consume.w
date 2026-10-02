//! expect-error: wrong argument type in call to 'consume'

// D27 E3: the unannotated binding preserves &Thing. The later call is the
// independently established owned demand and fails at that site.

type Thing { vals: Vec[i32] }

fn consume(t: Thing) -> i64: t.vals.len()

fn main:
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: Vec.new() })
    let t = items[0]
    assert(consume(t) == 0)
