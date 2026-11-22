//! expect-stdout: xy
// #3026 (D111, D179): `let p = x.s` takes the str (a count increment), so
// assigning the field afterwards is fine and `p` keeps the old value. This
// was err_assign_field_under_live_field_view (#1530), which pinned the view
// rule on a str field; the rule stays for a field whose value is not a str.
type S { s: str, n: i32 }
fn main:
    var x = S { s: "x" ++ "y", n: 1 }
    let p = x.s
    x.n = 2
    x.s = "z" ++ "w"
    print(p)
