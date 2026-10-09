//! expect-stdout: v1
//! expect-stdout: some v2
//! expect-stdout: none
//! expect-stdout: dflt
//! expect-stdout: Some(v1)
//! expect-stdout: None
//! expect-stdout: first a
//! expect-stdout: opt b
//! expect-stdout: some-ref ok
//! expect-stdout: iterref one two
//! expect-stdout: iter one two
//! expect-stdout: lens 1 2 3
//! expect-stdout: filtered bb
//! expect-stdout: map a=x
//! expect-stdout: joined p-q

// #1810: an `Option[&str]` holds the view itself, so it is a tagged enum,
// not D22's nullable pointer: a map lookup, an `iter_ref` step and a map
// traversal read the view out of the slot they find. A `&str` separator
// crosses to the runtime's join as a view (it crashed while `&str` was a
// pointer the join stored into a header slot).

use std.collections.HashMap

fn find_first(xs: &List[str]) -> Option[&str]:
    if xs.len() == 0: return None
    Some(xs[0])

fn maybe(c: bool, s: &str) -> Option[&str]: if c: Some(s) else: None

fn first_some(o: &Option[&str]) -> str:
    match o:
        Some(s) => s.clone()
        None => "none"

fn main:
    var m: HashMap[i32, str] = HashMap.new()
    m.insert(1, "v1")
    m.insert(2, "v2")
    print(m.get(1).unwrap())
    match m.get(2):
        Some(s) => print("some " ++ s)
        None => print("none")
    match m.get(3):
        Some(s) => print("some " ++ s)
        None => print("none")
    let d: &str = "dflt"
    print(m.get(9) ?? d)
    print(f"{m.get(1)}")
    print(f"{m.get(5)}")
    var xs: List[str] = List.new()
    xs.push("a")
    print("first " ++ find_first(&xs).unwrap())
    if let Some(v) = maybe(true, "b"): print("opt " ++ v)
    let o: Option[&str] = Some("ok")
    print("some-ref " ++ first_some(&o))
    var ys: List[str] = List.new()
    ys.push("one")
    ys.push("two")
    var acc = "iterref"
    for y in ys.iter_ref(): acc = acc ++ " " ++ y
    print(acc)
    var acc2 = "iter"
    for y in ys.iter(): acc2 = acc2 ++ " " ++ y
    print(acc2)
    var zs: List[str] = List.new()
    zs.push("a")
    zs.push("bb")
    zs.push("ccc")
    let lens: List[i64] = zs.iter() |> map(it.len()) |> collect[List]()
    print(f"lens {lens[0]} {lens[1]} {lens[2]}")
    let two: List[str] = zs.iter() |> filter(it.len() == 2) |> map(it.clone()) |> collect[List]()
    print("filtered " ++ two[0])
    var kv: HashMap[str, str] = HashMap.new()
    kv.insert("a", "x")
    for (k, v) in kv: print(f"map {k}={v}")
    var parts: List[str] = List.new()
    parts.push("p")
    parts.push("q")
    let sep: &str = "-"
    print("joined " ++ parts.join(sep))
