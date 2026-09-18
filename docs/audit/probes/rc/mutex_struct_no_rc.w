// Isolation: struct containing Mutex, NO Rc. If this fails, the trigger
// is struct/Mutex interaction, not Rc.
use std.sync.Mutex
use std.builtins.print

type M { id: i32, link: Mutex[i32] }

fn main:
    let m = M { id: 1, link: Mutex.new(0) }
    assert(m.id == 1)
    m.link.set(7)
    let v: i32 = m.link.enter().exit()
    assert(v == 7)
    print("mutex-struct-no-rc-ok")
