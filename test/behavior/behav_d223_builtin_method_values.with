//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: true
//! expect-stdout: ABC
//! expect-stdout: HELLO
//! expect-stdout: 2
//! expect-stdout: 2
//! expect-stdout: x
//! expect-stdout: true
//! expect-stdout: 0
//! expect-stdout: 3
//! expect-stdout: end
//! expect-stdout: drop t1
//! expect-stdout: drop t2

// D223 (§9.3a): a method the compiler implements itself is named as a
// value like any other: `List[i32].len`, `List[i32].push` (the receiver is
// `mut`), `List[i32].contains` (its argument observes), `str.to_upper`,
// `HashMap[str, i32].get`, a constructor (`List[i32].new`, no receiver), a
// consuming receiver (`Option[i32].unwrap`). The value is the closure a
// person would write, `(x, a) => x.method(a)`, written by the compiler.
use std.collections.HashMap

type Tag { name: str }
impl Drop for Tag:
    move fn drop(): print(f"drop {self.name}")

fn main:
    let xs = [1, 2, 3]
    let len = List[i32].len
    print(len(xs))
    var ys = [1]
    let push = List[i32].push
    push(ys, 5)
    print(ys.len())
    let has = List[i32].contains
    print(has(ys, 5))
    let up = str.to_upper
    print(up("abc"))
    let a: Option[str] = Some("hello")
    print(a.map(str.to_upper) ?? "none")
    let ls = ["a", "bb"].iter() |> map(str.len) |> collect[List]()
    print(ls[1])
    var tags = [Tag { name: "t1" }]
    let push_tag = List[Tag].push
    push_tag(tags, Tag { name: "t2" })
    let len_tag = List[Tag].len
    print(len_tag(tags))
    let cl = str.clone
    print(cl("x"))
    var h: HashMap[str, i32] = HashMap.new()
    h.insert("a", 1)
    let get = HashMap[str, i32].get
    print(get(h, "a").is_some())
    let mk = List[i32].new
    print(mk().len())
    let unwrap = Option[i32].unwrap
    print(unwrap(Some(3)))
    print("end")
