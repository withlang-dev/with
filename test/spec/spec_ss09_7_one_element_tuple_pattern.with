//! expect-stdout: ok

// §9.7.1.23: a one-element tuple pattern `(x,)` binds the single element;
// `(x)` without the comma is a grouping, not a tuple.

fn main:
    match (7,):
        (x,) => assert(x == 7)
    let g = match 5:
        (v) => v
    assert(g == 5)
    print("ok")
