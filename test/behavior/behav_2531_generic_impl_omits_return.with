//! expect-stdout: 6

// #2531 (D140, D103): a generic trait impl's method with its return type
// omitted takes the trait's, instantiated for the impl (`Option[&T]`), and
// its tail converts at that demand. The instance's body once compiled with
// no return demand and ICEd in MIR.
use std.traits.Iter

type Count[T] ephemeral { items: &List[T], idx: isize }

impl[T] Iter[&T] for Count[T]:
    mut fn next():
        if self.idx >= self.items.len(): return None
        let i = self.idx
        self.idx += 1
        &self.items[i]

fn main:
    let xs: List[i32] = [1, 2, 3]
    var c = Count { items: xs, idx: 0 }
    var total = 0
    while true:
        match c.next():
            None => break
            Some(x) => total = total + x
    print(f"{total}")
