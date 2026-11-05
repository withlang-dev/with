//! expect-stdout: 2 true 7
//! expect-stdout: 2 true true false
//! expect-stdout: 1 true 99
//! expect-stdout: 1 true 55
// #3011 (§11.7, D96, D97): the C backend hashes and compares a type with a
// key projection (`impl Key`) by calling `key()` — for maps, sets, nested
// aggregates, and `==`/`!=` (including `TotalF64` NaN and signed zero, plus
// owned `str`, borrowed `&str`, and borrowed `&Struct` projections).
use std.collections.HashMap
use std.collections.HashSet
use std.traits.TotalF64

type Tag { text: str }

impl Key for Tag:
    fn key(): self.text.to_lower()

type RefKeyed { id: str, seq: i32 }

impl Key for RefKeyed:
    fn key() -> &str: &self.id

type Inner { a: i32, b: str }
type StructRefKeyed { inner: Inner, note: i32 }

impl Key for StructRefKeyed:
    fn key() -> &Inner: &self.inner

fn main:
    var tags: HashMap[Tag, i32] = HashMap.new()
    tags.insert(Tag { text: "Red".to_lower() }, 3)
    tags.insert(Tag { text: "RED".to_upper() }, 7)
    tags.insert(Tag { text: "blue".to_lower() }, 1)
    print(f"{tags.len()} {tags.contains(Tag { text: \"rEd\" })} {tags.get(Tag { text: \"red\" }) ?? 0}")

    let nan1 = TotalF64(0.0 / 0.0)
    let nan2 = TotalF64(0.0 / 0.0)
    let pz = TotalF64(0.0)
    let nz = TotalF64(-0.0)
    var floats: HashSet[TotalF64] = HashSet.new()
    floats.insert(nan1)
    floats.insert(nan2)
    floats.insert(pz)
    floats.insert(nz)
    print(f"{floats.len()} {nan1 == nan2} {pz == nz} {nan1 != nan2}")

    var pairs: HashMap[(i32, RefKeyed), i32] = HashMap.new()
    pairs.insert((1, RefKeyed { id: "alpha".to_owned(), seq: 10 }), 42)
    pairs.insert((1, RefKeyed { id: "alpha".to_owned(), seq: 20 }), 99)
    let probe = (1, RefKeyed { id: "alpha".to_owned(), seq: 999 })
    print(f"{pairs.len()} {pairs.contains(probe)} {pairs.get(probe) ?? 0}")

    var srefs: HashMap[StructRefKeyed, i32] = HashMap.new()
    srefs.insert(StructRefKeyed { inner: Inner { a: 7, b: "k".to_owned() }, note: 1 }, 11)
    srefs.insert(StructRefKeyed { inner: Inner { a: 7, b: "k".to_owned() }, note: 2 }, 55)
    let sprobe = StructRefKeyed { inner: Inner { a: 7, b: "k".to_owned() }, note: 9 }
    print(f"{srefs.len()} {srefs.contains(sprobe)} {srefs.get(sprobe) ?? 0}")
