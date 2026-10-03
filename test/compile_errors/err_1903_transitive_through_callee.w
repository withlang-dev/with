//! expect-check-fail: call to `grow` mutates global `HIDDEN` while `r` is a live view into it

// #1903 (§21.1 rule 6): a global origin travels through a callee's returned
// view: `outer` returns what `first` returns, a view of HIDDEN.

var HIDDEN: Vec[i32] = Vec.new()

fn grow():
    for i in 0..1000: HIDDEN.push(i)

fn main:
    HIDDEN.push(41)
    let x: Vec[i32] = Vec.new()
    let r = outer(&x)
    grow()
    print(*r)

fn outer(p: &Vec[i32]) -> &i32: first(p)

fn first(p: &Vec[i32]) -> &i32: &HIDDEN[0]
