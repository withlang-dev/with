// Probe p1: HashMap get/remove — D22 (T10) + missing-key behavior (T23).
use std.collections.HashMap

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("a", 1)
    m.insert("b", 2)
    // get present -> Some, unwrap == value
    let g: Option[&i32] = m.get("a")
    print("get-present-is-some")
    if g.is_some():
        print("get-present-some-ok")
    let v: i32 = g.unwrap()
    if v == 1:
        print("get-present-value-ok")
    // get missing -> None (silent, no panic)
    let gm: Option[&i32] = m.get("zzz")
    if gm.is_none():
        print("get-missing-none-ok")
    // remove present -> Some(owned), key gone after
    let r: Option[i32] = m.remove("a")
    if r.is_some():
        print("remove-present-some-ok")
    let rv: i32 = r.unwrap()
    if rv == 1:
        print("remove-present-value-ok")
    if not m.contains("a"):
        print("remove-present-gone-ok")
    // remove missing -> None (silent)
    let rm: Option[i32] = m.remove("zzz")
    if rm.is_none():
        print("remove-missing-none-ok")
    print("p1-done")
