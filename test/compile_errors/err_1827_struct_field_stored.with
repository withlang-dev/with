//! expect-check-fail: call to `h.f` mutates global `G` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rules 1 and 7): a struct global with a `List` field, viewed by
// a field view `let r = G.name`, written by a function stored in a field and called through it
// while the view is live.
// A call writes every global its callee writes, and a drop every global
// its Drop impls write (§2.4).

type S:
    name: List[i32]    // a str field would take the value (#3026, D111); the view rule needs a List
    n: i32

var G = S { name: [1, 2], n: 1 }

type H:
    f: fn() -> Unit

fn grow_g():
    G.name = [9, 9]

fn main:
    let h = H { f: grow_g }
    let r = G.name
    h.f()
    print(r.len())
