//! expect-stdout: caps=12 drops=1
// §9.5/#641a: a mut-self method calling another mut-self method on `self`
// (the Arena.alloc -> add_block shape) — no premature drop anywhere.
var DROPS = 0
type Store { cap: i32, used: i32 }
impl Drop for Store:
    fn drop(move self: Self): DROPS = DROPS + 1
fn Store.grow(mut self: Self):
    self.cap = self.cap * 2
fn Store.take(mut self: Self, n: i32) -> i32:
    if self.used + n > self.cap:
        self.grow()
    self.used = self.used + n
    self.cap
fn run() -> i32:
    var s = Store { cap: 4, used: 0 }
    let c1 = s.take(3)
    let c2 = s.take(3)
    c1 + c2
fn main:
    print(f"caps={run()} drops={DROPS}")
