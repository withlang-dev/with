//! expect-stdout: a 7
//! expect-stdout: s -1
// #3340 (§4.3c, D110, D111): where two uses' demands are joined, a view of
// a value is the value at every position, also one where every use has the
// view: the list stores what it is given, and a value copies. Joined to
// `List[(str, &str)]`, the tuple was no Copy type, so `for (caller, callee)
// in edges` bound a view of the view and `index.get(callee)` was refused
// (`&&str` where `&str` is expected).
use std.collections.HashMap

type Sym { name: str, callees: List[str] }

fn main:
    let index: HashMap[str, isize] = HashMap.new()
    index.insert("b", 7)
    let syms = [Sym { name: "a", callees: ["b"] }]
    let names = ["s"]
    let edges = []
    for symbol in syms:
        for callee in symbol.callees: edges.push((symbol.name, callee))
    for name in names: edges.push((name, name))
    for (caller, callee) in edges:
        var at = -1
        match index.get(callee):
            Some(i) => at = *i
            None => {}
        print(f"{caller} {at}")
