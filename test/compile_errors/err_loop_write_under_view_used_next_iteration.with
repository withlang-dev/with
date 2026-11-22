//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// §21.1 Rules 1 and 4 (#1722): a loop runs its body again, so a view declared
// before the loop and used anywhere in it is live after a write later in the
// same body — the next iteration's `print(p)` read the freed value. The field
// is a List: a str field's binding takes the str (#3026, D179) and views
// nothing.
type S { s: List[i32], n: i32 }
fn main:
    var x = S { s: [1, 2], n: 0 }
    let p = x.s
    for i in 0..2:
        print(p.len())
        x.s = [9, 9]
