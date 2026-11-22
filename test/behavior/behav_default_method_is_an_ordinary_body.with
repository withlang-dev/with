//! expect-stdout: drop 7
//! expect-stdout: 8
//! expect-stdout: deferred
//! expect-stdout: 5
//! expect-stdout: drop 1
//! expect-stdout: end
// A default trait method an impl inherits is lowered as any function's body
// is (lower_fn_shape). Its own lowering scheduled no drop for an owned
// parameter (the destructor never ran and a List leaked) and ran no `defer` at
// return. (The implicit `Ok` of §4.9 in a default method is #3360: Sema's
// side.)
type Res { id: i32 }

impl Drop for Res:
    move fn drop(): print(f"drop {self.id}")


trait Sink:
    fn tag(self: &Self) -> i32
    fn swallow(self: &Self, r: Res) -> i32: self.tag() + r.id
    fn later(self: &Self) -> i32:
        defer: print("deferred")
        self.tag() + 4

type S { t: i32 }

impl Sink for S:
    fn tag(self: &Self) -> i32: self.t

fn main:
    let s = S { t: 1 }
    print(f"{s.swallow(Res { id: 7 })}")
    print(f"{s.later()}")
    let kept = Res { id: 1 }
    let seen = s.swallow(kept)
    assert(seen == 2)
    print("end")
