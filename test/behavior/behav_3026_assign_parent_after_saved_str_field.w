//! expect-stdout: xy
// #3026 (D111, D179): `let p = x.inner.s` takes the str, so replacing the
// ancestor `x.inner` afterwards is fine and `p` keeps the old value. This
// was err_assign_parent_under_live_field_view (#1530), which pinned the
// view rule on a str field; the rule stays for a non-str field.
type Inner { s: str, n: i32 }
type S { inner: Inner, tag: i32 }
fn main:
    var x = S { inner: Inner { s: "x" ++ "y", n: 1 }, tag: 0 }
    let p = x.inner.s
    x.inner.n = 2
    x.tag = 3
    x.inner = Inner { s: "z" ++ "w", n: 4 }
    print(p)
