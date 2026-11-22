//! expect-debug-alloc: leak count=0
//! expect-stdout: 3
//! expect-stdout: ok

// A default trait method an impl inherits owns its plain parameters and
// drops them, as any function does. Its body had a lowering of its own in
// codegen that scheduled no drop: the list and its strings leaked.
trait Counter:
    fn base(self: &Self) -> i32
    fn count(self: &Self, names: List[str]) -> i32: self.base() + names.len() as i32

type C { n: i32 }

impl Counter for C:
    fn base(self: &Self) -> i32: self.n

fn main:
    let c = C { n: 1 }
    print(f"{c.count(["a".to_upper(), "b".to_upper()])}")
    print("ok")
