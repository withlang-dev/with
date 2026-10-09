//! expect-stdout: array: 7 8
//! expect-stdout: vec: 7
//! expect-stdout: field: 7 7
//! expect-stdout: nested: 7
//! expect-stdout: mut fn: 7
//! expect-stdout: option view: 5

// #1783 (§21.1, D22): a store records view origins only when the stored
// value can hold a view. A Copy read through a reference (`*r`) is an
// independent value: storing it into an array element, a List, a struct
// field or a receiver's field makes nothing view its origin, so the storage
// is still usable after the origin's scope ends.
type Acc { last: i32, total: i32 }
type Bag { xs: List[i32] }
impl Bag:
    mut fn add(x: &i32): self.xs.push(*x)

fn first(xs: &List[i32]) -> Option[&i32]: if xs.len() == 0: None else: Some(&xs[0])

fn main:
    var seen = [0, 0]
    if true:
        let n = 7
        let r = &n
        seen[0] = *r
        seen[1] = *r + 1
    print(f"array: {seen[0]} {seen[1]}")
    var got: List[i32] = List.new()
    if true:
        let n = 7
        let r = &n
        got.push(*r)
    print(f"vec: {got[0]}")
    var a = Acc { last: 0, total: 0 }
    if true:
        let n = 7
        let r = &n
        a.last = *r
        a.total = a.total + *r
    print(f"field: {a.last} {a.total}")
    var b = Bag { xs: List.new() }
    if true:
        let n = 7
        let r = &n
        b.xs.push(*r)
    print(f"nested: {b.xs[0]}")
    var c = Bag { xs: List.new() }
    if true:
        let n = 7
        c.add(&n)
    print(f"mut fn: {c.xs[0]}")
    var picked = [0]
    if true:
        var src: List[i32] = List.new()
        src.push(5)
        if let Some(v) = first(&src): picked[0] = *v
    print(f"option view: {picked[0]}")
