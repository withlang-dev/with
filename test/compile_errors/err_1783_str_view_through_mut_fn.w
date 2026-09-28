//! expect-check-fail: view `ns` may originate from `s`, which no longer lives here

// #1783: a `&str` view of a local stored through a `mut fn`.
type Names = ephemeral { v: Vec[&str] }
impl Names:
    mut fn keep(s: &str): self.v.push(s)
fn main:
    var ns = Names { v: Vec.new() }
    if true:
        let s = "hello".clone()
        ns.keep(&s)
    print(ns.v[0])
