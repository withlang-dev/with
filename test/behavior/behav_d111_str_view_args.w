//! expect-stdout: a
//! expect-stdout: hi b! 1
//! expect-stdout: hi b! 2
//! expect-stdout: 1 1 1 1
//! expect-stdout: a b a b

// D111: a `&str` (here an element of a Vec) passed where a str is owned
// is copied with its own hold: a plain parameter, a generic method whose T
// the receiver fixed, a library map's key, an implicit fill. The callee
// drops its copy and the element stays (the debug allocator run reports a
// double free or a leak).
use std.collections.BTreeMap

type Bag[T]:
    items: Vec[T]
impl[T] Bag[T]:
    mut fn put(x: T): self.items.push(x)

fn take(s: str): print(s)
fn greet(n: i32, who: implicit str): print(f"hi {who} {n}")

fn main:
    let parts = "a b".split(" ")
    take(parts[0])
    with who(parts[1] ++ "!"):
        greet(1)
        greet(2)
    var bag: Bag[str] = Bag { items: Vec.new() }
    bag.put(parts[1])
    var tree: BTreeMap[str, i32] = BTreeMap.new()
    tree.insert(parts[0], 1)
    var hash: HashMap[str, i32] = HashMap.new()
    hash.insert(parts[1], 2)
    var vec: Vec[str] = Vec.new()
    vec.push(parts[0])
    print(f"{bag.items.len()} {tree.len()} {hash.len()} {vec.len()}")
    print(f"{parts[0]} {parts[1]} {vec[0]} {bag.items[0]}")
