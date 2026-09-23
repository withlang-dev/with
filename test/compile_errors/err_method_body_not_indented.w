//! expect-error: expected an indented block after ':'

// #1391 (§29.13 Form 2): a method body sits deeper than the method's line in
// the impl's member list.
type P { n: i32 }

impl P:
    fn get() -> i32:
    self.n

fn main:
    let p = P { n: 3 }
    print(f"{p.get()}")
