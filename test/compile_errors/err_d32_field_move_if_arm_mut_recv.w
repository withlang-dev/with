//! expect-check-fail: a field never moves out implicitly (§2.2, D32)

// #1395: an `if` arm joined with an owned arm (`""`) is an owned demand on
// that arm (§3.8 join rules 2 and 5), so a bare non-Copy field there is an
// implicit field move. Before the fix it passed check and the `mut fn`
// vacated `self.p` (reset-on-move), so the caller read an empty field.
type S { p: str }
impl S:
    mut fn f():
        let path = if self.p.len() > 0: self.p else: ""
        print(path)
fn main:
    var s = S { p: "abc" }
    s.f()
    print(f"after=[{s.p}]")
