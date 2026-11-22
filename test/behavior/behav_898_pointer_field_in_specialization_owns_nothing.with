//! expect-stdout: 1
//! expect-stdout: 1
//! expect-stdout: end
//! expect-stdout: drop one

// #898: a raw pointer field owns nothing, whatever its pointee is. In a
// specialization of a generic body the pointee's Drop impl was read as the
// pointer's (get_type_name names the pointee), so `type_needs_drop(*mut T)`
// answered true there. Reading the field twice copies it; the pointee is
// dropped once, by its owner.
type Loud { name: str }
impl Drop for Loud:
    move fn drop(): print(f"drop {self.name}")

type Holder[T] { target: *mut Loud, value: T }
unsafe fn peek[T](h: *mut Holder[T]) -> i32:
    let a = (*h).target
    let b = (*h).target
    if a == b: 1 else: 0

fn main:
    var loud = Loud { name: "one" }
    var h = Holder { target: &raw mut loud, value: 7 }
    print(unsafe { peek(&raw mut h) })
    var hs = Holder { target: &raw mut loud, value: "text" }
    print(unsafe { peek(&raw mut hs) })
    print("end")
