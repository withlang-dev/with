// Probe: Rc clones alias the same heap value (as_ref/deref agree).
use std.rc.Rc
use std.builtins.print

type Point { x: i32, y: i32 }

fn main:
    let a = Rc.new(Point { x: 3, y: 4 })
    let b = a.clone()
    assert(b.x == 3)
    assert(b.y == 4)
    assert(a.as_ref().x == b.as_ref().x)
    assert(a.deref().y == b.deref().y)
    print("rc-alias-ok")
