//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: an unannotated fn's tail is a return position (D43 infers the
// type). The D32 tail check keyed on the signature's return type, which
// still read Unit while the body was checked, so the check never ran for
// inferred returns and this vacated the receiver's field.
// A List field, not a str: a str field read copies (D111).
type S { p: List[i32] }
impl S:
    mut fn r(c: bool):
        if c: self.p else: List[i32].new()
fn main:
    var s = S { p: [1, 2] }
    print(s.r(true).len())
    print(s.p.len())
