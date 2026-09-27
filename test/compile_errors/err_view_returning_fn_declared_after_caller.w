//! expect-check-fail: cannot mutate `v` while `r` is a live view into it
// §21.1 Rule 6, §22 (#1473): a call ties its result to the arguments its
// callee's body returns a view of, whatever the declaration order. The
// summary was written when `first`'s body was checked, after `main`'s, so
// `main` read an empty one: the push that may reallocate `v` was accepted
// and `print(r)` read freed memory. Declared above `main`, it was refused.
fn main:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    let r = first(v)
    v.push(2)
    print(f"{r}")
fn first(xs: &Vec[i32]) -> &i32: &xs[0]
