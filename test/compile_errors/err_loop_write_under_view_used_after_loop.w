//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// §21.1 Rules 1 and 4, §3.8 / D22 (#1722): a view used after a loop is live
// while the loop body writes the viewed field. Liveness scanned only the
// block holding the write (the `if` body inside the `while`), found no use
// of `p` there, dropped the borrow and accepted the write; `print(p)` then
// read the replacement string after the one it viewed was freed.
type S { s: str, n: i32 }
fn main:
    var x = S { s: "ab" ++ "cd", n: 0 }
    let p = x.s
    var k = 0
    while k < 2:
        if k == 1:
            x.s = "zz" ++ "zz"
        k += 1
    print(p)
