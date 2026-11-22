//! expect-error: return type mismatch

// D27: fixed-array indexing observes just like List indexing. A declared owned
// return cannot materialize a non-Copy element view.

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Thing { vals: List[i32] }

fn take_first(items: &[2]Thing) -> Thing: items[0]

fn main:
    let items = [Thing { vals: List.new() }, Thing { vals: List.new() }]
    let first = take_first(items)
    assert(first.vals.len() == 0)
