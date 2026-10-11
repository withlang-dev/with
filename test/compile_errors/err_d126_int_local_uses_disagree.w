//! expect-check-fail: a local's uses must agree on its type

// D126 (§4.2.1): two uses that demand different narrow types of one
// literal-typed local disagree; the error names both uses.
fn narrow(x: i32): ()
fn narrower(x: u8): ()

fn main:
    var n = 7
    narrow(n)
    narrower(n)
