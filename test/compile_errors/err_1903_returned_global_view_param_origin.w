//! expect-check-fail: call to `grow` mutates global `HIDDEN` while `r` is a live view into it

// #1903 (§21.1 rule 6): a returned view's origins are every parameter it
// derives from and every global the body returns a view of. `first` takes
// `p` but returns a view of HIDDEN, so `r` views HIDDEN and `grow`, which
// writes HIDDEN, may not run while `r` is live (§21.1 rule 1). It compiled,
// and the read after `grow` saw the buffer `grow` freed.

var HIDDEN: Vec[i32] = Vec.new()

fn grow():
    for i in 0..1000: HIDDEN.push(i)

fn first(p: &Vec[i32]) -> &i32: &HIDDEN[0]

fn main:
    HIDDEN.push(41)
    let x: Vec[i32] = Vec.new()
    let r = first(&x)
    grow()
    print(*r)
