//! expect-stdout: ok

// Behavior test: traits — declaration, impl, method dispatch

trait HasValue =
    fn value(self: Self) -> i32

type Box { val: i32 }
type Pair { a: i32, b: i32 }

impl HasValue for Box =
    fn value(self: Box) -> i32:
        self.val

impl HasValue for Pair =
    fn value(self: Pair) -> i32:
        self.a + self.b

fn test_basic_trait:
    let b = Box { val: 42 }
    assert(b.value() == 42)

fn test_trait_dispatch:
    let b = Box { val: 10 }
    let p = Pair { a: 3, b: 7 }
    assert(b.value() == 10)
    assert(p.value() == 10)

fn test_trait_with_computation:
    let p = Pair { a: 20, b: 22 }
    let v = p.value()
    assert(v == 42)

fn main:
    test_basic_trait()
    test_trait_dispatch()
    test_trait_with_computation()
    print("ok")
