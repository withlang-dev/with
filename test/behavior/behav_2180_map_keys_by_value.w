//! expect-stdout: 1 true
//! expect-stdout: 1 1 1 1
//! expect-stdout: 2 true 7
// §11.7 (D96, #2180): a map or set hashes a key structurally and compares it
// by its `==`, never by its bytes. Two equal keys that hold a `str` are one
// entry; a 16-byte key that is not a `str` is not read as one; a type with a
// key projection is equal, and hashes, by its key.
use std.collections.HashSet
use std.collections.HashMap

type Named { id: i32, name: str }

// Tags compare without regard to case.
type Tag { text: str }

impl Key for Tag:
    fn key(): self.text.to_lower()

fn main:
    var named: HashSet[Named] = HashSet.new()
    named.insert(Named { id: 1, name: "a".to_lower() })
    named.insert(Named { id: 1, name: "A".to_lower() })
    print(f"{named.len()} {named.contains(Named { id: 1, name: "a".to_lower() })}")

    var pairs: HashSet[(i64, str)] = HashSet.new()
    pairs.insert((1, "x".to_lower()))
    pairs.insert((1, "X".to_lower()))
    var wide: HashSet[(i64, i64)] = HashSet.new()
    wide.insert((5, 3))
    wide.insert((5, 3))
    var maybe: HashSet[Option[str]] = HashSet.new()
    maybe.insert(Some("m".to_lower()))
    maybe.insert(Some("M".to_lower()))
    var vecs: HashSet[Vec[i32]] = HashSet.new()
    vecs.insert([1, 2])
    vecs.insert([1, 2])
    print(f"{pairs.len()} {wide.len()} {maybe.len()} {vecs.len()}")

    var tags: HashMap[Tag, i32] = HashMap.new()
    tags.insert(Tag { text: "Red".to_lower() }, 3)
    tags.insert(Tag { text: "RED".to_upper() }, 7)
    tags.insert(Tag { text: "blue".to_lower() }, 1)
    print(f"{tags.len()} {tags.contains(Tag { text: "rEd".clone() })} {tags.get(Tag { text: "red".clone() }) ?? 0}")
