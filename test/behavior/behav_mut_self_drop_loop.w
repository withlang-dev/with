//! expect-stdout: total=6 drops=1
// §9.5/#641a: mut-self calls in a loop — receiver state persists across
// iterations; exactly one drop at scope end.
var DROPS = 0
type Acc { total: i32 }
impl Drop for Acc:
    fn drop(move self: Self): DROPS = DROPS + 1
fn Acc.add(mut self: Self, x: i32):
    self.total = self.total + x
fn run() -> i32:
    var a = Acc { total: 0 }
    for i in 1i32..4:
        a.add(i)
    a.total
fn main:
    print(f"total={run()} drops={DROPS}")
