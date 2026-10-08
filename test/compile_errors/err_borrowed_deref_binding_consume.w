//! expect-error: cannot consume read-only view binding `observed`

// A Vec, not a str: `*source` of a `&str` copies the str (D111).
fn consume(value: Vec[i32]): print(value.len())
fn observe(source: &Vec[i32]):
    let observed = *source
    consume(observed)

fn main:
    let v: Vec[i32] = [1, 2]
    observe(&v)
