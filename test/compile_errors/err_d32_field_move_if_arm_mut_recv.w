//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: an `if` arm joined with an owned arm is an owned demand on that
// arm (§3.8 join rules 2 and 5), so a bare non-Copy field there is an
// implicit field move. Before the fix it passed check and the `mut fn`
// vacated `self.p` (reset-on-move), so the caller read an empty field.
// A List field, not a str: a str field read copies (D111).
type S { p: List[i32] }
impl S:
    mut fn f():
        let path: List[i32] = if self.p.len() > 0: self.p else: List.new()
        print(path.len())
fn main:
    var s = S { p: [1, 2] }
    s.f()
    print(f"after=[{s.p.len()}]")
