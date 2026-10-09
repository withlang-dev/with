//! expect-check-fail: call to `f` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rule 1): `apply` runs the
// callable its caller passes for `f`; the caller passes one read out of a
// field, which may be any callable value of its type — `grow` among them,
// which reallocates `G` while `r` views its first element.
var G: List[str] = List.new()

type H:
    f: fn() -> Unit

fn grow():
    for i in 0..64: G.push(f"item{i}")

fn apply(f: fn() -> Unit):
    let r = G[0]
    f()
    print(r)

fn main:
    G.push("first" ++ "!")
    let h = H { f: grow }
    apply(h.f.clone())
