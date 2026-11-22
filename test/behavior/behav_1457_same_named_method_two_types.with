//! expect-stdout: 1 2

// #1457 (method half): two modules each declare `pub type Item` with a method
// `total`. The two methods once shared one symbol — the later shadowed the
// earlier and its body was skipped (invalid MIR), then the collision became a
// located error. A method is now its declaration's own, so both run.
use issue1457.ma
use issue1457.mb

fn main:
    let a = new_a()
    let b = new_b()
    print(f"{a.total()} {b.total()}")
