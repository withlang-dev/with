//! expect-check-fail: use of moved value

// #782 arm 2: `let (a, b) = t` consumes the tuple (MIR moves every
// element), so a later projection reads blanked storage and must be
// rejected. A List element, not a str: a str is a value and is copied (D111).

fn pair() -> (i32, List[i32]): (42, [1, 2])

fn main:
    let t = pair()
    let (a, b) = t
    print(t.1.len())
    let _ = a
    print(b.len())
