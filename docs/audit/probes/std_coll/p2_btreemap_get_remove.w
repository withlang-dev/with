// Probe p2: BTreeMap get/remove — D22 (T10) + missing-key behavior (T23).
use std.collections.BTreeMap

fn main:
    var m: BTreeMap[str, i32] = BTreeMap.new()
    m.insert("a", 10)
    m.insert("b", 20)
    let g: Option[&i32] = m.get("a")
    if g.is_some():
        print("bget-present-some-ok")
    let v: i32 = g.unwrap()
    if v == 10:
        print("bget-present-value-ok")
    let gm: Option[&i32] = m.get("zzz")
    if gm.is_none():
        print("bget-missing-none-ok")
    let r: Option[i32] = m.remove("a")
    if r.is_some():
        print("bremove-present-some-ok")
    if r.unwrap() == 10:
        print("bremove-present-value-ok")
    if not m.contains("a"):
        print("bremove-present-gone-ok")
    let rm: Option[i32] = m.remove("zzz")
    if rm.is_none():
        print("bremove-missing-none-ok")
    print("p2-done")
