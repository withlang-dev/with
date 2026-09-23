//! expect-stdout: local 42
//! expect-stdout: local bool true
//! expect-stdout: local option 3
//! expect-stdout: global 7 7
//! expect-stdout: global bool true
//! expect-stdout: global option 11
//! expect-stdout: global point 5 6
//! expect-stdout: local field 7
//! expect-stdout: element 20
//! expect-stdout: element compound 12
//! expect-stdout: array element 9
//! expect-stdout: self field 11 11
//! expect-stdout: self flag true
//! expect-stdout: deref 77 77
//! expect-stdout: widened 8
//! expect-stdout: grouped 4
//! expect-stdout: copy receiver 7 7

// §9.1 / D60: the tail assignment of a body whose declared return type is
// not `Unit` yields a read of its place after the store. A Copy place of
// every kind — local, global, field of a local, field of `self` in a
// `mut fn`, element, pointee — reads back what the store left there.

type Pt { x: i32, y: i32 }
impl Copy for Pt

type Holder { n: i32, flag: bool, name: str }

type Counter { n: i32 }
impl Copy for Counter

extend Counter:
    // The whole receiver is a place too; a Copy one reads back.
    mut fn reset -> Counter: self = Counter { n: 7 }

extend Holder:
    mut fn bump -> i32: self.n += 10
    mut fn flip -> bool: self.flag = not self.flag

var gi: i32 = 1
var gb: bool = false
var go: Option[i32] = None
var gp: Pt = Pt { x: 0, y: 0 }

fn local_i32 -> i32:
    var n = 40
    n += 2
fn local_bool -> bool:
    var b = false
    b = true
fn local_opt -> Option[i32]:
    var o: Option[i32] = None
    o = Some(3)
fn global_i32 -> i32: gi *= 7
fn global_bool -> bool: gb = true
fn global_opt -> Option[i32]: go = Some(11)
fn global_point -> Pt: gp = Pt { x: 5, y: 6 }
fn local_field -> i32:
    var p = Pt { x: 1, y: 2 }
    p.y += 5
fn element -> i32:
    var v: Vec[i32] = Vec.new()
    v.push(1)
    v.push(2)
    v[1] = 20
fn element_compound -> i32:
    var v: Vec[i32] = Vec.new()
    v.push(4)
    v[0] *= 3
fn array_element -> i32:
    var a: [i32; 3] = [1, 2, 3]
    a[2] = 9
unsafe fn deref(p: *mut i32) -> i32: *p = 77
fn widened -> i64: gi += 1
fn grouped -> i32:
    var n = 3
    (n += 1)

fn main:
    print(f"local {local_i32()}")
    print(f"local bool {local_bool()}")
    print(f"local option {local_opt() ?? -1}")
    print(f"global {global_i32()} {gi}")
    print(f"global bool {global_bool()}")
    print(f"global option {global_opt() ?? -1}")
    let p = global_point()
    print(f"global point {p.x} {p.y}")
    print(f"local field {local_field()}")
    print(f"element {element()}")
    print(f"element compound {element_compound()}")
    print(f"array element {array_element()}")
    var h = Holder { n: 1, flag: false, name: "h" }
    print(f"self field {h.bump()} {h.n}")
    print(f"self flag {h.flip()}")
    var cell: i32 = 0
    let got = unsafe { deref(&raw mut cell) }
    print(f"deref {got} {cell}")
    print(f"widened {widened()}")
    print(f"grouped {grouped()}")
    var c = Counter { n: 1 }
    let r = c.reset()
    print(f"copy receiver {r.n} {c.n}")
