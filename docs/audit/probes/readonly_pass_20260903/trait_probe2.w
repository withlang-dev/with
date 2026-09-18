use std.builtins.print_i32
type Own { v: i32 }
impl Equal2 for Own:
    fn eq3(self: &Self, other: Self) -> bool: self.v == other.v
trait Equal2:
    fn eq3(self: &Self, other: Self) -> bool
fn main:
    let a = Own { v: 1 }
    let b = Own { v: 1 }
    let r = if a.eq3(b): 10 else: 20
    print_i32(r + b.v)
