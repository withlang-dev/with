//! expect-stdout: wrapped
//! expect-stdout: 5
//! expect-stdout: 3
//! expect-stdout: 7 x
//! expect-stdout: 2 a

// #1562: an instance of a declared generic struct (a user's `Wrap[T]`,
// std's `Box[T]`, `BTreeMap[K, V]`) is a C struct whose fields are the
// instance's; the C backend named the type and never defined it.
use std.box.Box
use std.collections.BTreeMap

type Wrap[T] { value: T }

impl[T] Debug for Wrap[T]:
    fn debug_str() -> str: "wrapped"

impl[T] Wrap[T]:
    fn get() -> &T: self.value

type Node { v: i32, next: Option[Box[Node]] }

type Holder { w: Wrap[i32], tag: Wrap[str] }

fn main:
    let w = Wrap { value: "x" }
    print(w.debug_str())
    let n = Wrap { value: 5 }
    print(n.get())
    let list = Node { v: 1, next: Some(Box.new(Node { v: 2, next: None })) }
    let Node { v, next } = list
    var total = v
    if let Some(b) = next:
        total += b.v
    print(total)
    let h = Holder { w: Wrap { value: 7 }, tag: Wrap { value: "x" } }
    print(f"{h.w.value} {h.tag.value}")
    var m: BTreeMap[i32, str] = BTreeMap.new()
    m.insert(2, "b")
    m.insert(1, "a")
    print(f"{m.len()} {m.get(1).unwrap()}")
