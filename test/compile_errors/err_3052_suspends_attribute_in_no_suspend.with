//! expect-error: E0702

// #3052: whether a method may suspend the current fiber is its
// declaration's fact — `@[suspends]` — not a list of std names in the
// compiler; a program's own `@[suspends]` method is refused inside
// `no_suspend` as `Barrier.wait` is.
type Gate { n: i32 }

@[suspends]
fn Gate.pass(self: &Self): self.n

fn main:
    let g = Gate { n: 1 }
    no_suspend:
        let _ = g.pass()
