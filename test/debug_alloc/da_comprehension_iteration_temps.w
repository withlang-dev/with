//! expect-debug-alloc: leak count=0
//! expect-stdout: fstr a0|a1|a2
//! expect-stdout: map 3 k0=0 k1=10 k2=20
//! expect-stdout: filter 0|2|3
//! expect-stdout: keys aa|c
//! expect-stdout: ref 3 w1!|w3!|w4!
//! expect-stdout: try 2 w1!|w3!
//! expect-stdout: try err w2
//! expect-stdout: ok

// §13.6, §2.5, #1736: a comprehension drops what each iteration creates in
// that iteration, moves what it stores into the output exactly once, and
// traverses a sequence reached through a reference like the sequence.
// - `[f"a{i}" for i in 0..3]`: each iteration's formatted `i` was
//   registered in the enclosing statement's frame; all but the last leaked.
// - `[f"k{i}": i * 10 for ...]` into a HashMap: the key moved into the map
//   was never registered as moved, so the last key was dropped again at the
//   comprehension's end (DOUBLE FREE).
// - a filter's temporaries (`f"{i}" != "1"`) leaked the same way.
// - `[check(w)? for w in ws]` and `[f(w) for w in ws]` over `ws: &List[str]`
//   failed MIR lowering.

use std.collections.{HashMap}

fn check(w: &str) -> Result[str, str]:
    if w == "w2": return Err(w)
    Ok(w ++ "!")

fn all_checked(ws: &List[str]) -> Result[List[str], str]:
    let v = [check(w)? for w in ws]
    Ok(v)

fn shouted(ws: &List[str]) -> List[str]: [w ++ "!" for w in ws]

fn words(csv: &str) -> List[str]:
    var ws: List[str] = List.new()
    for n in csv.split(","): ws.push(n)
    ws

fn main:
    let a = [f"a{i}" for i in 0..3]
    print(f"fstr {a.join("|")}")

    let hm: HashMap[str, i32] = [f"k{i}": i * 10 for i in 0..3]
    print(f"map {hm.len()} k0={hm.get("k0") ?? -1} k1={hm.get("k1") ?? -1} k2={hm.get("k2") ?? -1}")

    let kept = [i for i in 0..4 if f"{i}" != "1"]
    print(f"filter {kept[0]}|{kept[1]}|{kept[2]}")

    let src = words("aa,b,c")
    let keys = [s for s in src if f"{s}!" != "b!"]
    print(f"keys {keys.join("|")}")

    let ws = words("w1,w3,w4")
    let loud = shouted(ws)
    print(f"ref {loud.len()} {loud.join("|")}")

    match all_checked(words("w1,w3")):
        Ok(v) => print(f"try {v.len()} {v.join("|")}")
        Err(e) => print(f"try err {e}")
    match all_checked(words("w1,w2,w3")):
        Ok(v) => print(f"try {v.len()} {v.join("|")}")
        Err(e) => print(f"try err {e}")
    print("ok")
