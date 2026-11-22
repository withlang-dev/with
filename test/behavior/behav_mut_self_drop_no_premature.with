//! expect-stdout: r=3 drops=1
// §9.5/#641a: a `mut self: Self` method mutably BORROWS the receiver — it must
// not consume or drop it. A Drop-typed receiver survives its mut-self calls
// and drops exactly once at the caller's scope end.
var DROPS = 0
type Counter { n: i32 }
impl Drop for Counter:
    fn drop(move self: Self): DROPS = DROPS + 1
fn Counter.bump(mut self: Self) -> i32:
    self.n = self.n + 1
    self.n
fn run() -> i32:
    var c = Counter { n: 0 }
    let a = c.bump()
    let b = c.bump()
    a + b
fn main:
    print(f"r={run()} drops={DROPS}")
