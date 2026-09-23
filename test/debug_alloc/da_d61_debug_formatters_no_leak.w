//! expect-debug-alloc: leak count=0

// D61: every `:?` formatter — synthesized struct/enum/Vec/array/tuple/Box
// bodies, a std map's formatter, an explicit impl's debug_str — returns one
// owned str that the buffer copies and the statement drops. Nothing leaks.

use std.collections.HashMap
use std.collections.BTreeMap
use std.box.Box

type Inner { text: str, n: i32 }
type Outer { inner: Inner, tags: Vec[str], pair: (str, i32) }
enum Wire:
    Raw(str)
    Packed(Outer)
    Off
type Custom { text: str }
impl Debug for Custom:
    fn debug_str() -> str: f"custom<{self.text}>"
enum Chain:
    Link(str, Box[Chain])
    End

fn main:
    let tags: Vec[str] = Vec.new()
    tags.push("a")
    tags.push("b")
    let outer = Outer { inner: Inner { text: "in", n: 1 }, tags, pair: ("p", 2) }
    let s1 = f"{outer:?}"
    let wire = Wire.Packed(Outer { inner: Inner { text: "w", n: 2 }, tags: Vec.new(), pair: ("q", 3) })
    let s2 = f"{wire:?} {Wire.Raw("r"):?} {Wire.Off:?}"
    var map: HashMap[str, Vec[Custom]] = HashMap.new()
    let customs: Vec[Custom] = Vec.new()
    customs.push(Custom { text: "c" })
    map.insert("k", customs)
    map.insert("j", Vec.new())
    let s3 = f"{map:?}"
    var tree: BTreeMap[i32, Custom] = BTreeMap.new()
    tree.insert(2, Custom { text: "t" })
    let s4 = f"{tree:?}"
    let chain = Chain.Link("x", Box.new(Chain.Link("y", Box.new(Chain.End))))
    let s5 = f"{chain:?}"
    let arr: [2]str = ["u", "v"]
    let opt: Option[Custom] = Some(Custom { text: "o" })
    let s6 = f"{arr:?} {opt:?}"
    print(f"{s1.len() + s2.len() + s3.len() + s4.len() + s5.len() + s6.len()}")
