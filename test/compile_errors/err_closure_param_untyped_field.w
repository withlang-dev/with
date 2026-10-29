//! expect-error: the type of closure parameter `x` is not known: nothing passed to the closure or demanded of it types it, and `.text` is not an integer's

// Law 1: nothing types `x`, and a field is not an integer's, so the type is
// the programmer's to state (`(x: T) => …`). It said "unknown field 'text'
// for type 'i32'", naming a type no one chose.
fn main:
    let f = x => x.text
    print(f"{f(1)}")
