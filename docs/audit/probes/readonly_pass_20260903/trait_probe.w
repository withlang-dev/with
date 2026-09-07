use std.builtins.print_i32
trait Equal:
    fn eq2(self: &Self, other: Self) -> bool
type Box2 { v: i32 }
impl Equal for Box2:
    fn eq2(wrong_arity: i32, extra: i32) -> bool: true
fn main:
    let a = Box2 { v: 1 }
    let b = Box2 { v: 2 }
    print_i32(if a.eq2(b): 1 else: 0)
