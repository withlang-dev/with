//! expect-check-fail: the drop of `g` at the end of its scope mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a generic type's Drop impl, specialized for `Guard[i32]`,
// writes G when the value drops at the end of its scope while `r` views G.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: Vec[str] = Vec.new()

type Guard[T]:
    v: T

impl[T] Drop for Guard[T]:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    {
        let g = Guard { v: 1 }
        print(f"{g.v}")
    }
    print(r)
