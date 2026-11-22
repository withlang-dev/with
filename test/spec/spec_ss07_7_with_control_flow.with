//! expect-stdout: found=42 rel1=1 miss=-1 rel2=1
// §7.7: `return` from a match arm inside a `with` block returns from the
// enclosing function (the canonical find_value shape); the guard is released.
var REL = 0
type Store { v: i32 }
impl Scoped[i32] for Store:
    fn with_enter(self: &Self) -> i32: self.v
    fn with_exit(self: &Self) -> Unit: REL = REL + 1

fn find_value(present: bool) -> i32:
    let s = Store { v: 42 }
    with s as data:
        match present:
            true => return data
            false => ()
    -1

fn main:
    REL = 0
    let a = find_value(true)
    let r1 = REL
    REL = 0
    let b = find_value(false)
    let r2 = REL
    print(f"found={a} rel1={r1} miss={b} rel2={r2}")
