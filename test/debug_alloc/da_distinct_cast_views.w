//! expect-debug-alloc: leak count=0
//! expect-stdout: abc
//! expect-stdout: abc
//! expect-stdout: abc
//! expect-stdout: 3
//! expect-stdout: abc
//! expect-stdout: 3
//! expect-stdout: 3
//! expect-stdout: rec
//! expect-stdout: rec
//! expect-stdout: 3
//! expect-stdout: abc

// §4.5 (D75, #1802): a cast whose target is a view (`n as &str`), or any
// cast through a reference (`r as str` with `r: &Name`), borrows and yields
// a view — the owner keeps its value and frees it once. Before, a cast
// through a reference read the value into an owned temporary that was freed
// again (a double free, an invalid free for a List), and `s as &Name` cast
// the string header to a pointer (printed garbage).
type Name = distinct str
type Bag = distinct List[i32]
type Rec { s: str }
type RecD = distinct Rec

fn show(n: &Name): print(n as str)
fn bag_len(b: &Bag): print((b as List[i32]).len())
fn rec_show(r: &RecD): print((r as Rec).s)

fn vec3() -> List[i32]:
    var v: List[i32] = List.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v

fn main:
    let n = "abc" as Name
    show(n)
    show(n)
    let v = n as &str
    print(v)
    print((n as []u8).len())
    let s = "abc"
    let as_name = s as &Name
    show(as_name)
    let b = vec3() as Bag
    bag_len(b)
    let bv = b as &List[i32]
    print(bv.len())
    let d = Rec { s: "rec" } as RecD
    rec_show(d)
    rec_show(d)
    let bytes = s as []u8
    print(bytes.len())
    print(s)
