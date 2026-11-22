//! expect-stdout: r=3 drops=1
// §9.5/#641a: mut-self on a generic struct whose payload is Drop — the
// GENERIC_CALL + monomorphized-callee route shares the borrow discipline.
var DROPS = 0
type Holder { n: i32 }
impl Drop for Holder:
    fn drop(move self: Self): DROPS = DROPS + 1
type BoxLike[T] { v: T, count: i32 }
fn BoxLike.touch[T](mut self: Self) -> i32:
    self.count = self.count + 1
    self.count
fn run() -> i32:
    var b = BoxLike { v: Holder { n: 5 }, count: 0 }
    let a = b.touch()
    let c = b.touch()
    a + c
fn main:
    print(f"r={run()} drops={DROPS}")
