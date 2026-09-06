// Minimal: Mutex.set through Rc deref, no Rc-in-Rc recursion.
use std.rc.Rc
use std.sync.Mutex
use std.builtins.print

type M { id: i32, link: Mutex[i32] }

fn main:
    let a = Rc.new(M { id: 1, link: Mutex.new(0) })
    a.link.set(7)
    let v: i32 = a.link.enter().exit()
    assert(v == 7)
    print("rc-mutex-set-ok")
