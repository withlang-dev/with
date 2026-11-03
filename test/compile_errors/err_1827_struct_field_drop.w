//! expect-check-fail: the drop of `t` at the end of its scope mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a struct global with a `List` field, viewed by
// a field view `let r = G.name`, written by the Drop impl of a value dropped at the end of an inner scope
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

type S:
    name: List[i32]    // a str field would take the value (#3026, D111); the view rule needs a List
    n: i32

var G = S { name: [1, 2], n: 1 }

type Tok:
    n: i32

impl Drop for Tok:
    move fn drop():
        G.name = [9, 9]

fn main:
    let r = G.name
    {
        let t = Tok { n: 1 }
        print(f"{t.n}")
    }
    print(r.len())
