//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: an unannotated fn's tail is a return position (D43 infers `str`).
// The D32 tail check keyed on the signature's return type, which still read
// Unit while the body was checked, so the check never ran for inferred
// returns and this vacated the receiver's field.
type S { p: str }
impl S:
    mut fn r(c: bool):
        if c: self.p else: ""
fn main:
    var s = S { p: "abc" }
    print(s.r(true))
    print(s.p)
