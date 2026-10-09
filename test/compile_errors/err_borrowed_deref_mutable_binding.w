//! expect-error: cannot take ownership of a non-Copy value through a borrow

// A List, not a str: `*source` of a `&str` copies the str (D111).
fn observe(source: &List[i32]):
    var observed = *source
    print(observed.len())

fn main:
    let v: List[i32] = [1, 2]
    observe(&v)
