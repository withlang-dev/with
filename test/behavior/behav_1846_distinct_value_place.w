//! expect-stdout: abc
//! expect-stdout: abc
//! expect-stdout: len 3
//! expect-stdout: ref abc
//! expect-stdout: show abc
//! expect-stdout: size 3
//! expect-stdout: vlen 2 v0 4 v1 5
//! expect-stdout: px 7 pl pt
//! expect-stdout: id 9
//! expect-stdout: new
//! expect-stdout: end

// #1846 (§4.5, D32): `.value` of a distinct type is the wrapped value's
// place: a read views it, `let k = n.value` binds a view, a method or an
// index reaches through it, and an assignment replaces it. A distinct type
// is represented as its underlying type, so that place is the value itself.
// On base, codegen indexed the underlying type as if it were the wrapper:
// `print(n.value)` printed "", `let k = n.value; print(k)` segfaulted, and
// `self.value` in an `extend` method aborted codegen.

type Name = distinct str
type Nums = distinct Vec[i32]
type Pt:
    x: i32
    label: str
type Place = distinct Pt
type Id = distinct i32

extend Name:
    fn show(): print(f"show {self.value}")
    fn size() -> i64: self.value.len()

fn by_ref(r: &Name): print(f"ref {r.value}")
fn nums_ref(r: &Nums) -> i32: r.value[1]

fn main:
    let n = Name("abc".clone())
    print(n.value)
    let k = n.value
    print(k)
    print(f"len {n.value.len()}")
    by_ref(&n)
    n.show()
    print(f"size {n.size()}")
    var nums: Vec[i32] = Vec.new()
    nums.push(4)
    nums.push(5)
    let v = Nums(nums)
    print(f"vlen {v.value.len()} v0 {v.value[0]} v1 {nums_ref(&v)}")
    let p = Place(Pt { x: 7, label: "pt".clone() })
    print(f"px {p.value.x} pl {p.value.label}")
    let id = Id(9)
    let raw = id.value
    print(f"id {raw}")
    var m = Name("old".clone())
    m.value = "new".clone()
    print(m.value)
    print("end")
