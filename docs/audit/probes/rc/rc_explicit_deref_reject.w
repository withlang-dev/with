// Negative probe: explicit `*rc` must be rejected (unary `*` covers
// &T and raw pointers only; Rc access goes through auto-deref/as_ref).
use std.rc.Rc
use std.builtins.print

fn main:
    let a = Rc.new(42)
    print(*a)
