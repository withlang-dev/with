use std.builtins.print
type Both { v: i32 }
impl Copy for Both:
    fn copy(self: &Self) -> Self: Both { v: self.v }
impl Drop for Both:
    move fn drop(): ()
fn main:
    let a = Both { v: 1 }
    let b = a
    print("done")
