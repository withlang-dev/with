//! expect-stdout: a b
//! expect-stdout: x z
//! expect-stdout: y z
//! expect-stdout: 3 2 2
// #3340 (§4.3c, D111, D22): two uses of one untyped list that demand
// `List[(str, &str)]` and `List[(&str, str)]` demand one type, `List[(str,
// str)]`: a view of a value and the value are one demand, and each use
// supplies the owned demand the other lacks. It was "this use demands … of
// a binding another use demands …" until the binding's type was written.
type S { name: str, callees: List[str] }

fn main:
    let names = ["x", "y"]
    let s = S { name: "a", callees: ["b"] }
    let edges = []
    for callee in s.callees: edges.push((s.name, callee))
    for name in names: edges.push((name, "z"))
    for (a, b) in edges: print(f"{a} {b}")
    // A view and a value at the top, and through three uses.
    let words = []
    for name in names: words.push(name)
    words.push(s.name)
    let counts = []
    let n = 7
    let ns = [1, 2]
    for k in ns: counts.push((k, n))
    counts.push((n, n))
    for k in ns: counts.push((n, k))
    print(f"{edges.len()} {words.len() - 1} {counts.len() - 3}")
