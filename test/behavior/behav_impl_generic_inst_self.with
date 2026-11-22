//! expect-stdout: ok

// #584: Self inside `impl Trait for Box[i32]` binds to the INSTANTIATION,
// not the generic base. The base's T-typed field tids are 0 (spurious
// "unknown field") and its layout is wrong — the mixed-field shape below
// previously CHECKED GREEN and printed ABI garbage (§11 impls).

trait Tag:
    fn tag(self: &Self) -> i32

type Box[T] { value: T }
type Mixed[T] { value: T, k: i32 }

impl Tag for Box[i32]:
    fn tag(self: &Self) -> i32:
        self.value

impl Tag for Mixed[i32]:
    fn tag(self: &Self) -> i32:
        self.value + self.k

fn main:
    let b: Box[i32] = Box { value: 7 }
    assert(b.tag() == 7)
    let m: Mixed[i32] = Mixed { value: 4, k: 7 }
    assert(m.tag() == 11)
    print("ok")
