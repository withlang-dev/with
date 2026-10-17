//! expect-stdout: p 1 2 q 10 2
//! expect-stdout: a.tags 1 b.tags 2 a.name x b.name y
//! expect-stdout: w.items 1 v.items 2
//! expect-stdout: m.len 1 n.len 2
//! expect-stdout: sum 3
//! expect-stdout: ok

// D120 stage 3 (§2.3, §4.3): a struct whose fields are all values is a
// value, with no `impl Copy` written: a struct of integers copies by its
// bits; a struct holding a str and a List copies by sharing their buffers
// under a count (the copy glue retains each field), and the first write
// through one copy leaves the other alone. The same for an instance of a
// generic struct of values, so a BTreeMap of values is a value. Passing a
// value struct copies it, so the caller still has it.
use std.box.Box
use std.collections.BTreeMap

type Point { x: i32, y: i32 }
type Named { name: str, tags: List[str] }
type Wrap[T] { items: List[T], n: i32 }

fn total(p: Point) -> i32: p.x + p.y

fn main:
    let p = Point { x: 1, y: 2 }
    var q = p
    q.x = 10
    print(f"p {p.x} {p.y} q {q.x} {q.y}")
    var a = Named { name: "x", tags: ["t"] }
    var b = a
    b.tags.push("u")
    b.name = "y"
    print(f"a.tags {a.tags.len()} b.tags {b.tags.len()} a.name {a.name} b.name {b.name}")
    var w = Wrap { items: [1], n: 0 }
    var v = w
    v.items.push(2)
    print(f"w.items {w.items.len()} v.items {v.items.len()}")
    var m: BTreeMap[str, i32] = BTreeMap.new()
    m.insert("a", 1)
    var n = m
    n.insert("b", 2)
    print(f"m.len {m.len()} n.len {n.len()}")
    let boxed_drop = Box.new(Named { name: "d" ++ "rop", tags: ["k"] })
    drop(boxed_drop)
    var unboxed = Box.new(Named { name: "i" ++ "n", tags: ["m"] }).into_inner()
    unboxed.tags.push("n")
    print(f"sum {total(p) + 0 * total(p)}")
    print(f"{p.x == 1 and a.tags.len() == 1 and unboxed.tags.len() == 2}".replace("true", "ok"))
