//! expect-check-fail: call to `h.f` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rule 1): a call through a callable
// stored in a field runs whatever callable reached the field. Sema tracks no
// value flow into a field, so the call runs any callable value of its type
// in this compilation — `grow` among them, which reallocates `G` while `r`
// views its first element.
var G: List[str] = List.new()

type H:
    f: fn() -> Unit

fn grow():
    for i in 0..64: G.push(f"item{i}")

fn main:
    G.push("first" ++ "!")
    let h = H { f: grow }
    let r = G[0]
    h.f()
    print(r)
