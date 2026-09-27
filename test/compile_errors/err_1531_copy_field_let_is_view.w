//! expect-error: cannot mutate `s` while `x` is a live view into it
// #1531 (§3.8, D27): "an unannotated `let` binds the view unchanged ...
// uniform across field projections and collection element access". A Copy
// field binding views the field exactly as `let x = v[0]` views an element,
// so writing the field while the view is live is refused. The copy is
// spelled `let x: i32 = s.n` (behav_1531_copy_field_view_and_copy.w).

type S { n: i32 }

fn main:
    var s = S { n: 1 }
    let x = s.n
    s.n = 5
    print(x)
