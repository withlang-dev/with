//! expect-debug-alloc: leak count=0
//! expect-stdout: a,b
//! expect-stdout: a,b,c
//! expect-stdout: 2 1
//! expect-stdout: k1=v1,v2
//! expect-stdout: true
//! expect-stdout: 0

// #983, D111/D120: a copy of a str or a List of values is one more holder
// (a retain); a mutation of a shared List copies it first, the copy's
// elements taking their holds; the last holder frees. Maps and sets hold
// and release their tables the same way.
use std.collections.HashMap
use std.collections.HashSet

fn join(xs: &List[str]) -> str:
    var out = ""
    for i in 0..xs.len():
        if i > 0: out = out ++ ","
        out = out ++ xs[i]
    out

fn main:
    let base = ["a" ++ "", "b" ++ ""]
    var grown = base
    grown.push("c" ++ "")
    print(join(&base))
    print(join(&grown))
    var m: HashMap[str, List[str]] = HashMap.new()
    m.insert("k1" ++ "", ["v1" ++ ""])
    m.insert("k2" ++ "", ["w" ++ ""])
    let snapshot = m
    var v1 = m.remove("k1").unwrap()
    v1.push("v2" ++ "")
    m.insert("k1" ++ "", v1)
    print(f"{m.len()} {snapshot.get("k1").unwrap().len()}")
    print("k1=" ++ join(m.get("k1").unwrap()))
    var seen: HashSet[str] = HashSet.new()
    seen.insert("x" ++ "y")
    print(seen.contains("xy"))
    var cleared = grown
    cleared.clear()
    print(cleared.len())
