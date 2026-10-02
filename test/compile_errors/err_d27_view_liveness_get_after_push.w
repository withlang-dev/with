//! expect-error: cannot mutate `items` while `t` is a live view into it

// D27 E3: `items[0]` seeds its receiver origin; push may reallocate while the
// let-bound view remains live.

type Thing { vals: Vec[i32] }

fn main:
    var items: Vec[Thing] = Vec.new()
    items.push(Thing { vals: Vec.new() })
    let t = items[0]
    items.push(Thing { vals: Vec.new() })
    assert(t.vals.len() == 0)
