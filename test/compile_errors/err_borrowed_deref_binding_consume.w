//! expect-error: cannot consume read-only view binding `observed`

// A List, not a str: `*source` of a `&str` copies the str (D111).
fn consume(value: List[i32]): print(value.len())
fn observe(source: &List[i32]):
    let observed = *source
    consume(observed)

fn main:
    let v: List[i32] = [1, 2]
    observe(&v)
