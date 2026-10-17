//! expect-error: wrong argument type in call to 'consume'

// D27 E3: a by-value parameter is an owned demand; &Thing cannot satisfy it.

// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type Thing { vals: List[i32] }

fn consume(t: Thing) -> i64: t.vals.len()

fn main:
    var items: List[Thing] = List.new()
    items.push(Thing { vals: List.new() })
    assert(consume(items[0]) == 0)
