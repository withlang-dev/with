//! expect-debug-alloc: leak count=0
//! expect-stdout: abc
//! expect-stdout: abc
//! expect-stdout: mk
//! expect-stdout: 3
//! expect-stdout: 3
//! expect-stdout: rec
//! expect-stdout: rec
//! expect-stdout: xyz

// §4.5 (D75, #1802): casting an owned value into or out of its distinct type
// moves it, and the distinct type has its underlying type's destructor —
// every buffer below is freed exactly once. Before, `s as Name` left the
// buffer with `s` (a `Name` drop freed nothing) and `n as str` made a second
// owner: a double free for str, an invalid free for Vec, a leak for a struct.
type Name = distinct str
type Bag = distinct Vec[i32]
type Rec { s: str }
type RecD = distinct Rec

fn vec3() -> Vec[i32]:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v

fn mk_name() -> Name: "mk" as Name

fn main:
    // into, from a binding: `s` moves into `n`
    let s = "abc"
    let n = s as Name
    // out, to a binding: `n` moves into `t`
    let t = n as str
    print(t)
    // out of a temporary into a statement temporary, dropped at the `;`
    let m = "abc" as Name
    print(m as str)
    print(mk_name() as str)
    // a Vec
    let v = vec3()
    let b = v as Bag
    let w = b as Vec[i32]
    print(w.len())
    let b2 = vec3() as Bag
    print((b2 as Vec[i32]).len())
    // a struct holding an owned str
    let r = Rec { s: "rec" }
    let d = r as RecD
    let back = d as Rec
    print(back.s)
    let d2 = Rec { s: "rec" } as RecD
    print((d2 as Rec).s)
    // the same type: a relabel that moves
    let x = "xyz"
    let y = x as str
    print(y)
