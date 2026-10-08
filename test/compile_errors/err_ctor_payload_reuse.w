//! expect-check-fail: use of moved value

// #764: an enum constructor owns its payload; reusing the moved binding
// in a second constructor is a use-of-moved-value error, not a silent
// read of the blanked slot. A Vec, not a str: a str is a value and is
// copied (D111).
enum CtorReuseTok { Items(Vec[i32]) | End }
error CtorReuseErr =
    Bad(items: Vec[i32])
    Empty

fn main:
    let label: Vec[i32] = [1]
    let t = CtorReuseTok.Items(label)
    let e = CtorReuseErr.Bad(label)
    let _ = t
    let _ = e
