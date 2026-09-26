//! expect-check-fail: cannot mutate `x` while `p` is a live view into it
// §3.8 / D22 (#1530): a view of `x.inner.s` borrows that path; replacing the
// ancestor `x.inner` drops the value `p` views, so it is refused even though
// `x.inner.s` itself is never named. A sibling write (`x.inner.n`) is accepted
// (behav_sibling_field_mutation_under_field_view).
type Inner { s: str, n: i32 }
type S { inner: Inner, tag: i32 }
fn main:
    var x = S { inner: Inner { s: "x" ++ "y", n: 1 }, tag: 0 }
    let p = x.inner.s
    x.inner.n = 2
    x.tag = 3
    x.inner = Inner { s: "z" ++ "w", n: 4 }
    print(p)
