//! expect-check-fail: a `for` binds one pattern; a second name is not an index
//! expect-check-fail: write `for (i, x) in <collection>.enumerate():`

// #2152 (§13.5): an indexed loop is spelled with `enumerate()`. The
// two-name form was parsed and typed and then failed to lower with no
// diagnostic.
fn main:
    let xs: Vec[i32] = [1, 2, 3]
    for x, i in xs: print(x + i as i32)
