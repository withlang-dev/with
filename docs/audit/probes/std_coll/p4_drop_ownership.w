// Probe p4: T5 drop/ownership in containers — push/move/drop paths.
use std.collections.HashMap
use std.collections.BTreeMap

fn main:
    // Vec[str]: push moves ownership in; remove moves it out exactly once.
    var vs: Vec[str] = Vec.new()
    vs.push("hello")
    vs.push("world")
    let s0: str = vs.remove(0)
    if s0 == "hello":
        print("vec-str-remove-ok")
    if vs.len() == 1:
        print("vec-str-len-ok")
    if vs.get(0) == "world":
        print("vec-str-shift-ok")
    // HashMap[str,str]: insert duplicate replaces value; remove transfers.
    var m: HashMap[str, str] = HashMap.new()
    m.insert("k", "v1")
    m.insert("k", "v2")
    let g: str = m.get("k").unwrap()
    if g == "v2":
        print("map-dup-replace-ok")
    let ro: Option[str] = m.remove("k")
    if ro.is_some():
        print("map-str-remove-some-ok")
    if ro.unwrap() == "v2":
        print("map-str-remove-value-ok")
    // BTreeMap[str,str]: same transfer check.
    var b: BTreeMap[str, str] = BTreeMap.new()
    b.insert("k", "w1")
    b.insert("k", "w2")
    let bg: str = b.get("k").unwrap()
    if bg == "w2":
        print("bmap-dup-replace-ok")
    let br: Option[str] = b.remove("k")
    if br.unwrap() == "w2":
        print("bmap-str-remove-ok")
    print("p4-done")
