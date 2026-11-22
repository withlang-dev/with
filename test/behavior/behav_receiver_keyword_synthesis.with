//! expect-stdout: ok

// D7 eliminate-self (P1+P2): a method inside an `impl`/`extend` block synthesizes
// its receiver — `self` and its type are never written. Plain `fn` == read borrow
// (`self: &Self`), `mut fn` == `mut self: Self`, `move fn` == `move self: Self`.
// The explicit `self: &Self` form still parses (transition).

type Counter { n: i32 }

impl Counter:
    fn get(): self.n                     // plain fn = read borrow (implicit self: &Self)
    fn getx(self: &Self): self.n         // explicit read borrow still parses (transition)
    mut fn bump(): self.n = self.n + 1
    mut fn add(k: i32): self.n = self.n + k
    move fn into_n(): self.n

extend Counter:
    move fn take: self.n                 // paren-less move fn form

fn main:
    var c = Counter { n: 5 }
    c.bump()                              // mut fn: 5 -> 6
    c.add(10)                            // mut fn: 6 -> 16
    assert(c.get() == 16)                // plain fn = implicit read borrow (P2)
    assert(c.getx() == 16)               // explicit self: &Self still works
    let d = Counter { n: 42 }
    assert(d.into_n() == 42)             // move fn consumes d
    let e = Counter { n: 7 }
    assert(e.take() == 7)                // paren-less move fn consumes e
    print("ok")
