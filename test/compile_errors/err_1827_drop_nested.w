//! expect-check-fail: the drop of `h` at the end of its scope mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): the drop of a struct runs its field's Drop impl, which
// writes G at the end of the struct's scope while `r` views G.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

var G: List[str] = List.new()

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        for i in 0..64: G.push(f"item{i}")

type Holder:
    t: Tok

fn main:
    G.push("first" ++ "!")
    let r = G[0]
    {
        let h = Holder { t: Tok { n: 1 } }
        print(f"{h.t.n}")
    }
    print(r)
