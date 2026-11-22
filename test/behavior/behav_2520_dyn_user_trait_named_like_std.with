//! expect-stdout: 7
// #2520: `dyn One` names the trait `One` means from this module — the
// program's own — not the most recently registered trait of that name
// (std.traits.One).
trait One:
    fn one(self: &Self) -> i32
type Seven { n: i32 }
impl One for Seven:
    fn one(): self.n

fn main:
    let s = Seven { n: 7 }
    let d: &dyn One = &s
    print(d.one())
