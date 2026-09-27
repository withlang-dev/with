//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// §21.1 Rules 1 and 4 (#1722): a loop runs its body again, so a view declared
// before the loop and used anywhere in it is live after a write later in the
// same body — the next iteration's `print(p)` read the freed string.
type S { s: str, n: i32 }
fn main:
    var x = S { s: "ab" ++ "cd", n: 0 }
    let p = x.s
    for i in 0..2:
        print(p)
        x.s = "zz" ++ "zz"
