use std.builtins.print_i32
trait Equal2:
    fn eq3(self: &Self, other: Self) -> bool
type Own { v: Vec[i32] }
impl Drop for Own:
    move fn drop(): ()
impl Equal2 for Own:
    fn eq3(self: &Self, other: Self) -> bool: self.v.len() == other.v.len()
fn main:
    let a = Own { v: Vec.new() }
    let b = Own { v: Vec.new() }
    let r = if a.eq3(b): 10 else: 20
    print_i32(r + b.v.len() as i32)
