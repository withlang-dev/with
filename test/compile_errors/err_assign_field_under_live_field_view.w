//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// §3.8 / D22 (#1530): assigning the viewed field while its view is live is
// refused — the assignment drops the value `p` views. A sibling write is
// accepted (behav_sibling_field_mutation_under_field_view).
type S { s: str, n: i32 }
fn main:
    var x = S { s: "x" ++ "y", n: 1 }
    let p = x.s
    x.n = 2
    x.s = "z" ++ "w"
    print(p)
