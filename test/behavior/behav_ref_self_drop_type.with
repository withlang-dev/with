//! expect-stdout: r=18 drops=1
// §9.5: `self: &Self` borrows — a Drop-typed receiver drops once at scope end.
var DROPS = 0
type Probe { n: i32 }
impl Drop for Probe:
    fn drop(move self: Self): DROPS = DROPS + 1
fn Probe.peek(self: &Self) -> i32: self.n
fn run() -> i32:
    let p = Probe { n: 9 }
    p.peek() + p.peek()
fn main:
    print(f"r={run()} drops={DROPS}")
