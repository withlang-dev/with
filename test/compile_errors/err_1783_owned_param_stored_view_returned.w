//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6): `add` stores `x` into the container it returns, so
// the result views what `x` views; the caller's `h` then dies with `n`.
type H = ephemeral { v: List[&i32] }
fn add(h: H, x: &i32) -> H:
    var out = h
    out.v.push(x)
    out
fn main:
    var h = H { v: List.new() }
    if true:
        let n = 5
        h = add(h, &n)
    print(h.v[0])
