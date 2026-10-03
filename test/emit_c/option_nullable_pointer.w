//! expect-stdout: sizes 16 16 8
//! expect-stdout: stride 16 16
//! expect-stdout: list 1 2 3 sum 6
//! expect-stdout: get 20 none true
//! expect-stdout: find 30 missing
//! expect-stdout: unwrap true is_some true is_none false

// #2036: with-abi.md §3 makes an Option of one non-null address (`&T`,
// `*T`, an extern fn, a std Box) that nullable pointer. The C backend
// emitted it as `{int32_t tag; union {...}}`, 16 bytes where TypeLayout says
// 8, so `Node { v: i32, next: Option[Box[Node]] }` was 24 bytes in C and 16
// in the model. #2022's layout _Static_asserts now hold on every record.

use std.collections
use std.box.Box

type Node { v: i32, next: Option[Box[Node]] }
type Holder { r: Option[*const i32], n: i64 }

fn find(xs: &Vec[i32], want: i32) -> Option[&i32]:
    for x in xs:
        if x == want: return Some(x)
    None

fn main:
    print(f"sizes {comptime Node.size()} {comptime Holder.size()} {comptime Option[Box[Node]].size()}")
    let pair = [Node { v: 8, next: None }, Node { v: 9, next: None }]
    let holders = [Holder { r: None, n: 1 }, Holder { r: None, n: 2 }]
    print(f"stride {(&raw const pair[1] as i64) - (&raw const pair[0] as i64)} {(&raw const holders[1] as i64) - (&raw const holders[0] as i64)}")
    let list = Node { v: 1, next: Some(Box.new(Node { v: 2, next: Some(Box.new(Node { v: 3, next: None })) })) }
    var sum = list.v
    var seen = f"{list.v}"
    var cur = &list.next
    while true:
        match cur:
            Some(b) =>
                sum = sum + b.v
                seen = seen ++ f" {b.v}"
                cur = &b.next
            None => break
    print(f"list {seen} sum {sum}")
    let m: HashMap[str, i32] = ["a": 10, "b": 20]
    let got = m.get("b")
    print(f"get {got.unwrap()} none {m.get("z").is_none()}")
    let xs: Vec[i32] = [10, 20, 30]
    let hit = match find(&xs, 30):
        Some(x) => f"{x}"
        None => "none"
    let miss = match find(&xs, 99):
        Some(_) => "found"
        None => "missing"
    print(f"find {hit} {miss}")
    let seven = 7
    let h = Holder { r: Some(&raw const seven), n: 1 }
    print(f"unwrap {h.r.unwrap() as i64 == &raw const seven as i64} is_some {h.r.is_some()} is_none {h.r.is_none()}")
