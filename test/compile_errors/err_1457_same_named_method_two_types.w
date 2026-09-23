//! expect-error: is declared for two different types named 'Item'

// #1457 (method half): the two `Item.total` declarations share one method
// symbol. The later one shadowed the earlier and its body was skipped, which
// surfaced as invalid MIR ("body index map mismatch for fn symbol"). Until a
// method symbol carries its declaration, the collision is a located error.
use issue1457.ma
use issue1457.mb

fn main:
    let a = new_a()
    let b = new_b()
    print(f"{a.total()} {b.total()}")
