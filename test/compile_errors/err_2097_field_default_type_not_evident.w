//! expect-error: this field's default does not make its type evident here; write it

// D89 (§4.3): a field with a default may omit its type when the default
// says what it is. `Vec.new()` does not say what it holds.

type Bag { items = Vec.new() }

fn main:
    let b = Bag {}
    print(f"{b.items.len()}")
