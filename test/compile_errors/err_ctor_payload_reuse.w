//! expect-check-fail: use of moved value

// #764: an enum constructor owns its payload; reusing the moved binding
// in a second constructor is a use-of-moved-value error, not a silent
// read of the blanked slot. A List, not a str: a str is a value and is
// copied (D111).
type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
enum CtorReuseTok { Items(List[Tok]) | End }
error CtorReuseErr =
    Bad(items: List[Tok])
    Empty

fn main:
    let label: List[Tok] = [Tok { id: 1 }]
    let t = CtorReuseTok.Items(label)
    let e = CtorReuseErr.Bad(label)
    let _ = t
    let _ = e
