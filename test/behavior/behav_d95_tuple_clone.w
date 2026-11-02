//! expect-stdout: true
//! expect-stdout: 1 a
//! expect-stdout: 2 3
//! expect-stdout: Some((1, 2))
//! expect-stdout: 1 b
// §11.8 (D95, #2945): a tuple implements Clone when its elements do; the
// clone is element by element, a Copy element copied, an owning element
// (a List) cloned; Option and Result of a tuple clone through it.
fn main:
    let t = (1, "a")
    let u = t.clone()
    print(t == u)
    print(f"{u.0} {u.1}")
    let xs: List[i32] = [2, 3]
    let w = (xs, 9)
    let w2 = w.clone()
    print(f"{w2.0[0]} {w2.0[1]}")
    let o: Option[(i32, i32)] = Some((1, 2))
    let o2 = o.clone()
    print(f"{o2:?}")
    let v = &t
    let c = v.clone()
    print(f"{c.0} {"b"}")
