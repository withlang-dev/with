//! expect-stdout: 1 5

// D144 (amends #1531 for plain bits): a binding from a place of a
// plain-bits type takes the value — `let x = s.n` snapshots the i32, so
// writing the field afterward is fine and `x` keeps what it read. The
// compile-error fixture that pinned the view (err_1531_copy_field_let_is_
// view.w) gave way to this ruling.
type S { n: i32 }

fn main:
    var s = S { n: 1 }
    let x = s.n
    s.n = 5
    print(f"{x} {s.n}")
